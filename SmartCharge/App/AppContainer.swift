//
//  AppContainer.swift
//  SmartCharge
//

import Foundation
import CoreData
import Combine
import SwiftUI

@MainActor
public final class AppContainer: ObservableObject {
    public static let shared = AppContainer()

    // Repositories & Services
    public let vehicleRepository: VehicleRepositoryProtocol
    public let journeyRepository: JourneyRepositoryProtocol
    public let stationRepository: StationRepositoryProtocol
    public let preferencesRepository: PreferencesRepositoryProtocol
    public let favouriteStationRepository: FavouriteStationRepositoryProtocol
    public let routeService: RouteCalculationServiceProtocol
    public let locationSearchService: LocationSearchService
    public let notificationService: SmartChargeNotificationServiceProtocol

    // Use Cases
    public let calculateRangeUseCase: CalculateVehicleRangeUseCaseProtocol
    public let findCompatibleStationsUseCase: FindCompatibleStationsUseCaseProtocol
    public let recommendStopUseCase: RecommendChargingStopUseCaseProtocol
    public let analyseRiskUseCase: AnalyseRouteRiskUseCaseProtocol
    public let planJourneyUseCase: PlanJourneyUseCaseProtocol
    public let saveJourneyUseCase: SaveJourneyUseCaseProtocol
    public let multiStopPlanner: MultiStopRoutePlannerProtocol

    // Central Shared Journey State
    @Published public var journeyViewModel: JourneyViewModel

    public init(
        persistenceController: PersistenceController = .shared,
        stationRepository: StationRepositoryProtocol? = nil,
        routeService: RouteCalculationServiceProtocol? = nil,
        notificationService: SmartChargeNotificationServiceProtocol? = nil
    ) {
        let viewContext = persistenceController.container.viewContext
        let vehicleRepo = CoreDataVehicleRepository(context: viewContext)
        let journeyRepo = CoreDataJourneyRepository(context: viewContext)
        let prefsRepo = CoreDataPreferencesRepository(context: viewContext)
        let favsRepo = CoreDataFavouriteStationRepository(context: viewContext)
        let stationRepo = stationRepository ?? MockStationRepository()
        let routing = routeService ?? MKDirectionsRouteService()
        let locationService = LocationSearchService()
        let notifications = notificationService ?? SmartChargeNotificationService.shared

        self.vehicleRepository = vehicleRepo
        self.journeyRepository = journeyRepo
        self.stationRepository = stationRepo
        self.preferencesRepository = prefsRepo
        self.favouriteStationRepository = favsRepo
        self.routeService = routing
        self.locationSearchService = locationService
        self.notificationService = notifications

        let rangeUseCase = CalculateVehicleRangeUseCase()
        let compatibleUseCase = FindCompatibleStationsUseCase()
        let recommendUseCase = RecommendChargingStopUseCase()
        let riskUseCase = AnalyseRouteRiskUseCase()
        let multiStop = MultiStopRoutePlanner(recommendUseCase: recommendUseCase)

        self.calculateRangeUseCase = rangeUseCase
        self.findCompatibleStationsUseCase = compatibleUseCase
        self.recommendStopUseCase = recommendUseCase
        self.analyseRiskUseCase = riskUseCase
        self.multiStopPlanner = multiStop

        self.planJourneyUseCase = PlanJourneyUseCase(
            calculateRangeUseCase: rangeUseCase,
            findCompatibleStationsUseCase: compatibleUseCase,
            recommendStopUseCase: recommendUseCase,
            analyseRiskUseCase: riskUseCase
        )

        self.saveJourneyUseCase = SaveJourneyUseCase(repository: journeyRepo)

        self.journeyViewModel = JourneyViewModel(
            initialVehicle: MockDataGenerator.sampleVehicles.first!,
            routeService: routing,
            stationRepository: stationRepo,
            calculateRangeUseCase: rangeUseCase,
            multiStopPlanner: multiStop,
            recommendUseCase: recommendUseCase,
            analyseRiskUseCase: riskUseCase,
            notificationService: notifications
        )
    }

    public static var preview: AppContainer {
        AppContainer(
            persistenceController: .preview,
            stationRepository: MockStationRepository(),
            routeService: MKDirectionsRouteService()
        )
    }
}
