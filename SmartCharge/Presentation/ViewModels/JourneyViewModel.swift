//
//  JourneyViewModel.swift
//  SmartCharge
//

import Foundation
import SwiftUI
import MapKit
import Combine

@MainActor
public final class JourneyViewModel: ObservableObject {
    // MARK: - Core Journey Inputs (Reactive)
    @Published public var selectedVehicle: Vehicle
    @Published public var batteryPercentage: Double = 0.85 {
        didSet { recalculateEstimatesAndPlan() }
    }
    @Published public var safetyReservePercentage: Double = 0.15 {
        didSet { recalculateEstimatesAndPlan() }
    }
    @Published public var targetRechargePercentage: Double = 0.85 {
        didSet { recalculateEstimatesAndPlan() }
    }
    @Published public var routePreference: RoutePreference = .safest {
        didSet { recalculateEstimatesAndPlan() }
    }

    // Locations
    @Published public var originName: String = "Sydney CBD, NSW"
    @Published public var destinationName: String = "Canberra Civic, ACT"
    @Published public var originCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
    @Published public var destinationCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: -35.2809, longitude: 149.1300)

    // MARK: - Calculated & Mapped Route State
    @Published public private(set) var mappedRouteDistanceKm: Double = 286.0
    @Published public private(set) var formattedTravelTime: String = "3h 10m"
    @Published public private(set) var routePolylineCoordinates: [CLLocationCoordinate2D] = []
    @Published public private(set) var isRouting: Bool = false
    @Published public private(set) var routingError: String? = nil

    // Battery Range Math (Exact Blueprint Formulas)
    // currentRange = theoreticalRange * batteryPercentage
    // safeRange = currentRange * (1 - safetyReservePercentage)
    @Published public private(set) var currentEstimatedRangeKm: Double = 425.0
    @Published public private(set) var safePlanningRangeKm: Double = 361.25
    @Published public private(set) var safetyBufferKm: Double = 63.75

    // Multi-Stop Charging Plan & Corridor Stations
    @Published public private(set) var stationsAlongRoute: [ChargingStation] = []
    @Published public private(set) var plannedChargingStops: [PlannedChargingStop] = []
    @Published public private(set) var infrastructureGaps: [InfrastructureGap] = []
    @Published public private(set) var routeRiskResult: RouteRiskResult = RouteRiskResult.optimal
    @Published public private(set) var recommendationResult: RecommendationResult?

    // Dependencies
    private let routeService: RouteCalculationServiceProtocol
    private let stationRepository: StationRepositoryProtocol
    private let calculateRangeUseCase: CalculateVehicleRangeUseCaseProtocol
    private let multiStopPlanner: MultiStopRoutePlannerProtocol
    private let recommendUseCase: RecommendChargingStopUseCaseProtocol
    private let analyseRiskUseCase: AnalyseRouteRiskUseCaseProtocol
    private let notificationService: SmartChargeNotificationServiceProtocol?

    // Concurrency Request Safety
    private var currentRouteTask: Task<Void, Never>?
    private var requestGeneration: Int = 0

    public init(
        initialVehicle: Vehicle = MockDataGenerator.sampleVehicles.first!,
        routeService: RouteCalculationServiceProtocol = MKDirectionsRouteService(),
        stationRepository: StationRepositoryProtocol = MockStationRepository(),
        calculateRangeUseCase: CalculateVehicleRangeUseCaseProtocol = CalculateVehicleRangeUseCase(),
        multiStopPlanner: MultiStopRoutePlannerProtocol = MultiStopRoutePlanner(),
        recommendUseCase: RecommendChargingStopUseCaseProtocol = RecommendChargingStopUseCase(),
        analyseRiskUseCase: AnalyseRouteRiskUseCaseProtocol = AnalyseRouteRiskUseCase(),
        notificationService: SmartChargeNotificationServiceProtocol? = nil
    ) {
        self.selectedVehicle = initialVehicle
        self.routeService = routeService
        self.stationRepository = stationRepository
        self.calculateRangeUseCase = calculateRangeUseCase
        self.multiStopPlanner = multiStopPlanner
        self.recommendUseCase = recommendUseCase
        self.analyseRiskUseCase = analyseRiskUseCase
        self.notificationService = notificationService

        // Perform initial calculation
        updateBatteryEstimates()
        requestRouteRecalculation()
    }

    // MARK: - User Actions

    public func selectVehicle(_ vehicle: Vehicle) {
        self.selectedVehicle = vehicle
        updateBatteryEstimates()
        recalculateEstimatesAndPlan()
    }

    public func setOrigin(name: String, coordinate: CLLocationCoordinate2D) {
        self.originName = name
        self.originCoordinate = coordinate
        requestRouteRecalculation()
    }

    public func setDestination(name: String, coordinate: CLLocationCoordinate2D) {
        self.destinationName = name
        self.destinationCoordinate = coordinate
        requestRouteRecalculation()
    }

    public func swapOriginAndDestination() {
        let tempName = originName
        let tempCoord = originCoordinate

        originName = destinationName
        originCoordinate = destinationCoordinate

        destinationName = tempName
        destinationCoordinate = tempCoord

        requestRouteRecalculation()
    }

    // MARK: - Reactive Range Mathematics
    private func updateBatteryEstimates() {
        let theoretical = selectedVehicle.theoreticalRangeKm
        let rEstimate = (try? calculateRangeUseCase.execute(
            theoreticalRangeKm: theoretical,
            batteryPercentage: batteryPercentage,
            safetyReservePercentage: safetyReservePercentage,
            batteryCapacityKWh: selectedVehicle.batteryCapacityKWh
        )) ?? BatteryEstimate(
            theoreticalRangeKm: theoretical,
            batteryPercentage: batteryPercentage,
            safetyReservePercentage: safetyReservePercentage
        )

        self.currentEstimatedRangeKm = rEstimate.currentEstimatedRangeKm
        self.safePlanningRangeKm = rEstimate.safePlanningRangeKm
        self.safetyBufferKm = rEstimate.safetyBufferKm
    }

    // MARK: - Real MapKit Road Routing
    public func requestRouteRecalculation() {
        updateBatteryEstimates()

        // Cancel any pending routing task to avoid race conditions
        currentRouteTask?.cancel()
        requestGeneration += 1
        let thisGeneration = requestGeneration

        isRouting = true
        routingError = nil

        currentRouteTask = Task { [weak self] in
            guard let self = self else { return }

            do {
                // Request genuine driving route from MapKit
                let routeResult = try await self.routeService.calculateRoute(
                    from: self.originCoordinate,
                    to: self.destinationCoordinate
                )

                // Discard if newer request was launched
                guard !Task.isCancelled, thisGeneration == self.requestGeneration else { return }

                self.mappedRouteDistanceKm = routeResult.totalDistanceKm
                self.formattedTravelTime = routeResult.formattedDuration
                self.routePolylineCoordinates = routeResult.polylineCoordinates
                self.isRouting = false

                // Fetch stations along real corridor
                let corridorStations = try await self.stationRepository.fetchStationsAlongPolyline(
                    polylineCoordinates: routeResult.polylineCoordinates,
                    totalRouteDistanceKm: routeResult.totalDistanceKm,
                    corridorRadiusKm: 40.0
                )

                guard !Task.isCancelled, thisGeneration == self.requestGeneration else { return }

                self.stationsAlongRoute = corridorStations

                // Re-evaluate multi-stop plans, recommendations and analytics
                self.executeRoutePlanning(stations: corridorStations)

            } catch {
                guard !Task.isCancelled, thisGeneration == self.requestGeneration else { return }

                self.isRouting = false
                self.routingError = error.localizedDescription
                // Reset outdated results defensively
                self.plannedChargingStops = []
                self.infrastructureGaps = []
                self.recommendationResult = nil
            }
        }
    }

    // Re-evaluates charging stops and recommendations without refetching MapKit route
    private func recalculateEstimatesAndPlan() {
        updateBatteryEstimates()
        executeRoutePlanning(stations: stationsAlongRoute)
    }

    private func executeRoutePlanning(stations: [ChargingStation]) {
        // Multi-stop planning
        let plan = multiStopPlanner.planChargingStops(
            totalDistanceKm: mappedRouteDistanceKm,
            originName: originName,
            destinationName: destinationName,
            vehicle: selectedVehicle,
            initialBatteryPercent: batteryPercentage,
            safetyReservePercent: safetyReservePercentage,
            targetRechargePercent: targetRechargePercentage,
            preference: routePreference,
            stationsAlongRoute: stations
        )

        self.plannedChargingStops = plan.plannedStops
        self.infrastructureGaps = plan.infrastructureGaps

        // Battery estimate object
        let estimate = BatteryEstimate(
            theoreticalRangeKm: selectedVehicle.theoreticalRangeKm,
            batteryPercentage: batteryPercentage,
            safetyReservePercentage: safetyReservePercentage,
            batteryCapacityKWh: selectedVehicle.batteryCapacityKWh
        )

        // Route Risk Analysis
        self.routeRiskResult = analyseRiskUseCase.execute(
            totalDistanceKm: mappedRouteDistanceKm,
            estimate: estimate,
            segments: plan.routeSegments,
            compatibleStationsAlongRoute: stations
        )

        // Single best stop recommendation
        self.recommendationResult = recommendUseCase.recommend(
            stations: stations,
            for: selectedVehicle,
            estimate: estimate,
            preference: routePreference
        )

        // Sync state to WidgetKit snapshot store
        let isDirect = mappedRouteDistanceKm <= safePlanningRangeKm
        let statusText: String
        if isDirect {
            statusText = "Direct Safe Trip"
        } else if infrastructureGaps.isEmpty {
            statusText = "Viable Multi-Stop"
        } else {
            statusText = "Gap Detected"
        }

        let widgetSnapshot = WidgetJourneySnapshot(
            vehicleName: selectedVehicle.title,
            batteryPercentage: batteryPercentage,
            currentEstimatedRangeKm: currentEstimatedRangeKm,
            safePlanningRangeKm: safePlanningRangeKm,
            safetyBufferKm: safetyBufferKm,
            safetyReservePercentage: safetyReservePercentage,
            originName: originName,
            destinationName: destinationName,
            routeDistanceKm: mappedRouteDistanceKm,
            isDirectSafeTrip: isDirect,
            readinessStatusText: statusText,
            overallRiskLevel: routeRiskResult.overallRiskLevel.rawValue,
            plannedStopsCount: plannedChargingStops.count,
            lastUpdated: Date()
        )
        WidgetSnapshotStore.shared.saveSnapshot(widgetSnapshot)

        // Trigger Notification alerts if configured
        if let notif = notificationService {
            let batt = batteryPercentage
            let safeRange = safePlanningRangeKm
            let distance = mappedRouteDistanceKm
            let orig = originName
            let dest = destinationName
            let risk = self.routeRiskResult

            Task {
                _ = try? await notif.evaluateBatteryWarning(
                    batteryPercentage: batt,
                    safeRangeKm: safeRange,
                    routeDistanceKm: distance,
                    originName: orig,
                    destinationName: dest
                )
                _ = try? await notif.evaluateCriticalRiskAlert(
                    riskResult: risk,
                    originName: orig,
                    destinationName: dest
                )
            }
        }
    }

    // MARK: - Departure Reminder Scheduling Helper
    public func scheduleDepartureReminder(departureDate: Date, minutesBefore: Int = 30) async throws -> String {
        guard let notif = notificationService else { return "" }
        return try await notif.scheduleDepartureReminder(
            journeyName: "\(originName) to \(destinationName)",
            destinationName: destinationName,
            departureDate: departureDate,
            minutesBefore: minutesBefore
        )
    }
}
