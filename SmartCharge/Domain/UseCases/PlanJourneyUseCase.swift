//
//  PlanJourneyUseCase.swift
//  SmartCharge
//

import Foundation
import CoreLocation

public protocol PlanJourneyUseCaseProtocol: Sendable {
    func execute(
        originName: String,
        destinationName: String,
        originCoordinate: CLLocationCoordinate2D?,
        destinationCoordinate: CLLocationCoordinate2D?,
        totalDistanceKm: Double,
        vehicle: Vehicle,
        initialBatteryPercent: Double,
        safetyReservePercent: Double,
        preference: RoutePreference,
        availableStations: [ChargingStation]
    ) throws -> Journey
}

public struct PlanJourneyUseCase: PlanJourneyUseCaseProtocol {
    private let calculateRangeUseCase: CalculateVehicleRangeUseCaseProtocol
    private let findCompatibleStationsUseCase: FindCompatibleStationsUseCaseProtocol
    private let recommendStopUseCase: RecommendChargingStopUseCaseProtocol
    private let analyseRiskUseCase: AnalyseRouteRiskUseCaseProtocol

    public init(
        calculateRangeUseCase: CalculateVehicleRangeUseCaseProtocol = CalculateVehicleRangeUseCase(),
        findCompatibleStationsUseCase: FindCompatibleStationsUseCaseProtocol = FindCompatibleStationsUseCase(),
        recommendStopUseCase: RecommendChargingStopUseCaseProtocol = RecommendChargingStopUseCase(),
        analyseRiskUseCase: AnalyseRouteRiskUseCaseProtocol = AnalyseRouteRiskUseCase()
    ) {
        self.calculateRangeUseCase = calculateRangeUseCase
        self.findCompatibleStationsUseCase = findCompatibleStationsUseCase
        self.recommendStopUseCase = recommendStopUseCase
        self.analyseRiskUseCase = analyseRiskUseCase
    }

    public func execute(
        originName: String,
        destinationName: String,
        originCoordinate: CLLocationCoordinate2D?,
        destinationCoordinate: CLLocationCoordinate2D?,
        totalDistanceKm: Double,
        vehicle: Vehicle,
        initialBatteryPercent: Double,
        safetyReservePercent: Double,
        preference: RoutePreference,
        availableStations: [ChargingStation]
    ) throws -> Journey {
        let cleanOrigin = originName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDestination = destinationName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanOrigin.isEmpty else {
            throw JourneyPlanError.missingOrigin
        }
        guard !cleanDestination.isEmpty else {
            throw JourneyPlanError.missingDestination
        }
        guard cleanOrigin.caseInsensitiveCompare(cleanDestination) != .orderedSame else {
            throw JourneyPlanError.sameOriginAndDestination
        }

        let estimate = try calculateRangeUseCase.execute(
            theoreticalRangeKm: vehicle.theoreticalRangeKm,
            batteryPercentage: initialBatteryPercent,
            safetyReservePercentage: safetyReservePercent,
            batteryCapacityKWh: vehicle.batteryCapacityKWh
        )

        let compatible = findCompatibleStationsUseCase.execute(
            stations: availableStations,
            for: vehicle,
            minPowerKW: nil,
            requireOperational: true
        )

        // Generate preliminary recommendation if distance exceeds safe range
        var plannedStops: [ChargingStation] = []
        if totalDistanceKm > estimate.safePlanningRangeKm {
            let recommendation = recommendStopUseCase.recommend(
                stations: compatible,
                for: vehicle,
                estimate: estimate,
                preference: preference
            )
            if let best = recommendation.bestStation {
                plannedStops.append(best)
            }
        }

        // Build route segments for risk analysis
        let segments: [RouteSegment]
        if let stop = plannedStops.first, let stopDistance = stop.distanceKm {
            let remainingDistance = max(0, totalDistanceKm - stopDistance)
            segments = [
                RouteSegment(
                    startLocationName: cleanOrigin,
                    endLocationName: stop.name,
                    distanceKm: stopDistance,
                    availableChargingCount: 1,
                    maxPowerAlongSegmentKW: stop.maxPowerKW
                ),
                RouteSegment(
                    startLocationName: stop.name,
                    endLocationName: cleanDestination,
                    distanceKm: remainingDistance,
                    availableChargingCount: compatible.count - 1,
                    maxPowerAlongSegmentKW: 50.0
                )
            ]
        } else {
            segments = [
                RouteSegment(
                    startLocationName: cleanOrigin,
                    endLocationName: cleanDestination,
                    distanceKm: totalDistanceKm,
                    availableChargingCount: compatible.count,
                    maxPowerAlongSegmentKW: compatible.map(\.maxPowerKW).max() ?? 0
                )
            ]
        }

        let riskResult = analyseRiskUseCase.execute(
            totalDistanceKm: totalDistanceKm,
            estimate: estimate,
            segments: segments,
            compatibleStationsAlongRoute: compatible
        )

        return Journey(
            id: UUID(),
            originName: cleanOrigin,
            destinationName: cleanDestination,
            originCoordinate: originCoordinate,
            destinationCoordinate: destinationCoordinate,
            totalDistanceKm: totalDistanceKm,
            vehicle: vehicle,
            initialBatteryPercent: initialBatteryPercent,
            safetyReservePercent: safetyReservePercent,
            routePreference: preference,
            plannedChargingStops: plannedStops,
            riskResult: riskResult,
            createdAt: Date()
        )
    }
}
