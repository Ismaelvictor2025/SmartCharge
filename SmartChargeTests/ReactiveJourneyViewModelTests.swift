//
//  ReactiveJourneyViewModelTests.swift
//  SmartChargeTests
//

import Testing
import CoreLocation
@testable import SmartCharge

// Mock route service for deterministic unit testing
final class MockRouteService: RouteCalculationServiceProtocol, @unchecked Sendable {
    var stubbedDistanceKm: Double = 286.0
    var shouldFail: Bool = false

    func calculateRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> DrivingRouteResult {
        if shouldFail {
            throw RouteCalculationError.calculationFailed("Simulated network outage")
        }
        return DrivingRouteResult(
            totalDistanceKm: stubbedDistanceKm,
            expectedTravelTimeSeconds: (stubbedDistanceKm / 90.0) * 3600.0,
            polylineCoordinates: [origin, destination]
        )
    }
}

@Suite("Reactive JourneyViewModel Dynamic State Tests")
struct ReactiveJourneyViewModelTests {

    @Test("Changing battery percentage dynamically recalculates range instantly")
    @MainActor
    func batteryPercentageChangeUpdatesRange() async {
        let mockRouter = MockRouteService()
        let vm = JourneyViewModel(
            initialVehicle: MockDataGenerator.sampleVehicles.first!, // 500 km WLTP
            routeService: mockRouter
        )

        // 85% battery, 15% reserve: 500 * 0.85 = 425 km, safe = 425 * 0.85 = 361.25 km
        vm.batteryPercentage = 0.85
        vm.safetyReservePercentage = 0.15

        #expect(vm.currentEstimatedRangeKm == 425.0)
        #expect(vm.safePlanningRangeKm == 361.25)

        // Change battery from 85% to 45% (Section 11 mandatory scenario)
        vm.batteryPercentage = 0.45

        // Expected: 500 * 0.45 = 225.0 km, safe = 225 * 0.85 = 191.25 km
        #expect(vm.currentEstimatedRangeKm == 225.0)
        #expect(vm.safePlanningRangeKm == 191.25)
    }

    @Test("Changing safety reserve dynamically updates safe planning range")
    @MainActor
    func safetyReserveChangeUpdatesRange() async {
        let mockRouter = MockRouteService()
        let vm = JourneyViewModel(
            initialVehicle: MockDataGenerator.sampleVehicles.first!, // 500 km WLTP
            routeService: mockRouter
        )

        vm.batteryPercentage = 0.85 // 425 km physical
        vm.safetyReservePercentage = 0.15
        #expect(vm.safePlanningRangeKm == 361.25)

        // Change reserve from 15% to 20% (Section 11 mandatory scenario)
        vm.safetyReservePercentage = 0.20
        // Expected: 425 * (1 - 0.20) = 340.0 km
        #expect(vm.safePlanningRangeKm == 340.0)
    }

    @Test("Changing vehicle updates range and connector compatibility")
    @MainActor
    func vehicleSelectionUpdatesState() async {
        let mockRouter = MockRouteService()
        let vm = JourneyViewModel(
            initialVehicle: MockDataGenerator.sampleVehicles.first!,
            routeService: mockRouter
        )

        let leaf = MockDataGenerator.sampleVehicles.first(where: { $0.make == "Nissan" })! // 385 km WLTP, CHAdeMO
        vm.selectVehicle(leaf)

        #expect(vm.selectedVehicle.make == "Nissan")
        #expect(vm.selectedVehicle.theoreticalRangeKm == 385.0)
        #expect(vm.selectedVehicle.supportedConnectors.contains(.chademo))
    }

    @Test("Swapping origin and destination inverts coordinates")
    @MainActor
    func swappingOriginAndDestination() async {
        let mockRouter = MockRouteService()
        let vm = JourneyViewModel(routeService: mockRouter)

        let origName = "Sydney"
        let origCoord = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
        let destName = "Melbourne"
        let destCoord = CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631)

        vm.setOrigin(name: origName, coordinate: origCoord)
        vm.setDestination(name: destName, coordinate: destCoord)

        #expect(vm.originName == origName)
        #expect(vm.destinationName == destName)

        vm.swapOriginAndDestination()

        #expect(vm.originName == destName)
        #expect(vm.destinationName == origName)
        #expect(vm.originCoordinate.latitude == destCoord.latitude)
        #expect(vm.destinationCoordinate.latitude == origCoord.latitude)
    }

    @Test("Routing failure defensively clears stale results and sets routing error")
    @MainActor
    func routingFailureSetsDefensiveState() async {
        let mockRouter = MockRouteService()
        mockRouter.shouldFail = true

        let vm = JourneyViewModel(routeService: mockRouter)
        vm.requestRouteRecalculation()

        // Give async task small moment to complete
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(vm.isRouting == false)
        #expect(vm.routingError != nil)
        #expect(vm.plannedChargingStops.isEmpty)
    }
}
