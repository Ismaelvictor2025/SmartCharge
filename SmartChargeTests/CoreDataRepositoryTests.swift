//
//  CoreDataRepositoryTests.swift
//  SmartChargeTests
//

import Testing
import CoreData
@testable import SmartCharge

@Suite("Core Data Repository Tests")
@MainActor
struct CoreDataRepositoryTests {
    let persistenceController: PersistenceController
    let vehicleRepo: CoreDataVehicleRepository
    let journeyRepo: CoreDataJourneyRepository

    init() {
        self.persistenceController = PersistenceController(inMemory: true)
        self.vehicleRepo = CoreDataVehicleRepository(context: persistenceController.container.viewContext)
        self.journeyRepo = CoreDataJourneyRepository(context: persistenceController.container.viewContext)
    }

    @Test("Vehicle save, fetch, and default selection")
    func vehiclePersistence() async throws {
        let newVehicle = Vehicle(
            id: UUID(),
            name: "Test Porsche Taycan",
            make: "Porsche",
            model: "Taycan 4S",
            theoreticalRangeKm: 512.0,
            batteryCapacityKWh: 93.4,
            supportedConnectors: [.ccs2, .type2],
            isDefault: true
        )

        try await vehicleRepo.saveVehicle(newVehicle)

        let allVehicles = try await vehicleRepo.fetchVehicles()
        #expect(allVehicles.contains(where: { $0.id == newVehicle.id }))

        let defaultVeh = try await vehicleRepo.fetchDefaultVehicle()
        #expect(defaultVeh?.id == newVehicle.id)
    }

    @Test("Saved journey persistence and vehicle linkage")
    func journeyPersistence() async throws {
        let vehicle = Vehicle(
            id: UUID(),
            name: "Test EV",
            make: "Polestar",
            model: "2",
            theoreticalRangeKm: 470.0,
            batteryCapacityKWh: 75.0,
            supportedConnectors: [.ccs2]
        )
        try await vehicleRepo.saveVehicle(vehicle)

        let journey = Journey(
            id: UUID(),
            originName: "Sydney",
            destinationName: "Canberra",
            totalDistanceKm: 286.0,
            vehicle: vehicle,
            initialBatteryPercent: 0.85,
            safetyReservePercent: 0.15,
            routePreference: .safest
        )

        try await journeyRepo.saveJourney(journey)

        let saved = try await journeyRepo.fetchSavedJourneys()
        #expect(saved.contains(where: { $0.id == journey.id }))
        let fetched = saved.first(where: { $0.id == journey.id })
        #expect(fetched?.originName == "Sydney")
        #expect(fetched?.destinationName == "Canberra")
        #expect(fetched?.totalDistanceKm == 286.0)
    }
}
