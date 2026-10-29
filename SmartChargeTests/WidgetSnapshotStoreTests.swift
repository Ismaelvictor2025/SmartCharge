//
//  WidgetSnapshotStoreTests.swift
//  SmartChargeTests
//
//  Created by Vicky Neves Rohr on 29/10/2026.
//

import Testing
import Foundation
@testable import SmartCharge

@Suite("SmartCharge WidgetKit Snapshot Store Tests", .serialized)
@MainActor
struct WidgetSnapshotStoreTests {

    @Test("Default sample snapshot maintains valid domain values")
    func defaultSampleSnapshot() {
        let sample = WidgetJourneySnapshot.defaultSample
        #expect(sample.vehicleName == "Polestar 2 Long Range")
        #expect(sample.batteryPercentage == 0.85)
        #expect(sample.currentEstimatedRangeKm == 425.0)
        #expect(sample.safePlanningRangeKm == 361.25)
        #expect(sample.safetyBufferKm == 63.75)
        #expect(sample.safetyReservePercentage == 0.15)
        #expect(sample.originName == "Sydney CBD")
        #expect(sample.destinationName == "Canberra Civic")
        #expect(sample.routeDistanceKm == 286.0)
        #expect(sample.isDirectSafeTrip == true)
        #expect(sample.readinessStatusText == "Direct Safe Trip")
    }

    @Test("Snapshot JSON serialization and deserialization roundtrip")
    func snapshotSerialization() throws {
        let original = WidgetJourneySnapshot(
            vehicleName: "Tesla Model 3 Long Range",
            batteryPercentage: 0.60,
            currentEstimatedRangeKm: 330.0,
            safePlanningRangeKm: 280.5,
            safetyBufferKm: 49.5,
            safetyReservePercentage: 0.15,
            originName: "Sydney",
            destinationName: "Goulburn",
            routeDistanceKm: 195.0,
            isDirectSafeTrip: true,
            readinessStatusText: "Direct Safe Trip",
            overallRiskLevel: "LOW",
            plannedStopsCount: 0,
            lastUpdated: Date()
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WidgetJourneySnapshot.self, from: encoded)

        #expect(decoded.vehicleName == original.vehicleName)
        #expect(decoded.batteryPercentage == original.batteryPercentage)
        #expect(decoded.currentEstimatedRangeKm == original.currentEstimatedRangeKm)
        #expect(decoded.safePlanningRangeKm == original.safePlanningRangeKm)
        #expect(decoded.safetyBufferKm == original.safetyBufferKm)
        #expect(decoded.destinationName == original.destinationName)
        #expect(decoded.routeDistanceKm == original.routeDistanceKm)
    }

    @Test("WidgetSnapshotStore saves and retrieves custom snapshot")
    func snapshotStoreSaveAndLoad() {
        let store = WidgetSnapshotStore(suiteName: "group.com.vicky.SmartCharge.test")
        let custom = WidgetJourneySnapshot(
            vehicleName: "Hyundai Ioniq 6",
            batteryPercentage: 0.90,
            currentEstimatedRangeKm: 450.0,
            safePlanningRangeKm: 360.0,
            safetyBufferKm: 90.0,
            safetyReservePercentage: 0.20,
            originName: "Sydney",
            destinationName: "Melbourne",
            routeDistanceKm: 880.0,
            isDirectSafeTrip: false,
            readinessStatusText: "Viable Multi-Stop",
            overallRiskLevel: "MEDIUM",
            plannedStopsCount: 2,
            lastUpdated: Date()
        )

        store.saveSnapshot(custom)
        let loaded = store.loadSnapshot()

        #expect(loaded.vehicleName == "Hyundai Ioniq 6")
        #expect(loaded.batteryPercentage == 0.90)
        #expect(loaded.isDirectSafeTrip == false)
        #expect(loaded.plannedStopsCount == 2)
        #expect(loaded.readinessStatusText == "Viable Multi-Stop")

        store.clearSnapshot()
    }

    @Test("Widget deep-link URLs are valid and well-formed")
    func deepLinkURLs() {
        let dashboardURL = URL(string: "smartcharge://dashboard")
        let plannerURL = URL(string: "smartcharge://planner")
        let analyticsURL = URL(string: "smartcharge://analytics")

        #expect(dashboardURL?.scheme == "smartcharge")
        #expect(dashboardURL?.host == "dashboard")

        #expect(plannerURL?.scheme == "smartcharge")
        #expect(plannerURL?.host == "planner")

        #expect(analyticsURL?.scheme == "smartcharge")
        #expect(analyticsURL?.host == "analytics")
    }

    @Test("Empty placeholder snapshot provides sensible defaults")
    func emptyPlaceholderSnapshot() {
        let empty = WidgetJourneySnapshot.emptyPlaceholder
        #expect(empty.batteryPercentage == 0.80)
        #expect(empty.routeDistanceKm == 0.0)
        #expect(empty.readinessStatusText == "Ready to Plan")
    }
}
