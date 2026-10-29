//
//  PreferencesRepositoryTests.swift
//  SmartChargeTests
//

import Testing
import CoreData
@testable import SmartCharge

@Suite("User Preferences Repository Tests")
@MainActor
struct PreferencesRepositoryTests {
    let persistenceController: PersistenceController
    let preferencesRepo: CoreDataPreferencesRepository

    init() {
        self.persistenceController = PersistenceController(inMemory: true)
        self.preferencesRepo = CoreDataPreferencesRepository(context: persistenceController.container.viewContext)
    }

    @Test("Fetch default preferences when database is empty")
    func fetchDefaultWhenEmpty() async throws {
        let prefs = try await preferencesRepo.fetchPreferences()
        #expect(prefs.defaultSafetyReserve == 0.15)
        #expect(prefs.defaultRoutePreference == .safest)
        #expect(prefs.selectedVehicleId == nil)
    }

    @Test("Save and re-fetch updated user preferences")
    func saveAndRefetchPreferences() async throws {
        let testVehicleId = UUID()
        var updated = UserPreferences()
        updated.selectedVehicleId = testVehicleId
        updated.defaultSafetyReserve = 0.20
        updated.defaultRoutePreference = .fastestCharging

        try await preferencesRepo.savePreferences(updated)

        let reloaded = try await preferencesRepo.fetchPreferences()
        #expect(reloaded.selectedVehicleId == testVehicleId)
        #expect(reloaded.defaultSafetyReserve == 0.20)
        #expect(reloaded.defaultRoutePreference == .fastestCharging)
    }

    @Test("Reset preferences restores default baseline")
    func resetToDefaultsRestoresBaseline() async throws {
        var modified = UserPreferences()
        modified.defaultSafetyReserve = 0.25
        modified.defaultRoutePreference = .balanced

        try await preferencesRepo.savePreferences(modified)
        let resetResult = try await preferencesRepo.resetToDefaults()

        #expect(resetResult.defaultSafetyReserve == 0.15)
        #expect(resetResult.defaultRoutePreference == .safest)

        let reloaded = try await preferencesRepo.fetchPreferences()
        #expect(reloaded.defaultSafetyReserve == 0.15)
    }
}
