//
//  NotificationServiceTests.swift
//  SmartChargeTests
//
//  Created by Vicky Neves Rohr on 29/10/2026.
//

import Testing
import Foundation
import UserNotifications
@testable import SmartCharge

@Suite("SmartCharge Notification Service Tests", .serialized)
@MainActor
struct NotificationServiceTests {

    @Test("Initializes with valid default preferences")
    func defaultPreferences() {
        let prefs = NotificationPreferences.default
        #expect(prefs.departureReminderEnabled == true)
        #expect(prefs.batteryWarningEnabled == true)
        #expect(prefs.criticalRiskAlertEnabled == true)
        #expect(prefs.chargingStopReminderEnabled == true)
        #expect(prefs.departureReminderMinutesBefore == 30)
    }

    @Test("Preferences persistence encoding and decoding")
    func preferencesEncodingDecoding() throws {
        var prefs = NotificationPreferences()
        prefs.departureReminderMinutesBefore = 60
        prefs.batteryWarningEnabled = false

        let encoded = try JSONEncoder().encode(prefs)
        let decoded = try JSONDecoder().decode(NotificationPreferences.self, from: encoded)

        #expect(decoded.departureReminderMinutesBefore == 60)
        #expect(decoded.batteryWarningEnabled == false)
        #expect(decoded.criticalRiskAlertEnabled == true)
    }

    @Test("Departure reminder scheduling and cancellation")
    func departureReminderLifecycle() async throws {
        let service = SmartChargeNotificationService()
        service.preferences.departureReminderEnabled = true

        let futureDeparture = Date().addingTimeInterval(3600) // 1 hour from now
        let id = try await service.scheduleDepartureReminder(
            journeyName: "Sydney to Canberra",
            destinationName: "Canberra Civic",
            departureDate: futureDeparture,
            minutesBefore: 30
        )

        #expect(id == SmartChargeNotificationService.departureReminderId)

        // Cancel departure reminder
        await service.cancelDepartureReminder()
        let pending = await service.getPendingNotifications()
        let hasDeparture = pending.contains { $0.identifier == SmartChargeNotificationService.departureReminderId }
        #expect(!hasDeparture)
    }

    @Test("Departure reminder respect disabled preference")
    func departureReminderDisabled() async throws {
        let service = SmartChargeNotificationService()
        service.preferences.departureReminderEnabled = false

        let id = try await service.scheduleDepartureReminder(
            journeyName: "Sydney to Goulburn",
            destinationName: "Goulburn",
            departureDate: Date().addingTimeInterval(7200),
            minutesBefore: 15
        )

        #expect(id.isEmpty)
    }

    @Test("Battery warning triggers when route exceeds safe planning range")
    func batteryWarningTrigger() async throws {
        let service = SmartChargeNotificationService()
        service.preferences.batteryWarningEnabled = true

        // Route distance 400 km, safe range 361 km -> exceeds safe range
        let triggered = try await service.evaluateBatteryWarning(
            batteryPercentage: 0.85,
            safeRangeKm: 361.25,
            routeDistanceKm: 400.0,
            originName: "Sydney CBD",
            destinationName: "Canberra"
        )

        #expect(triggered == true)
        #expect(service.lastTriggeredNotificationTitle == "Battery Range Warning")

        // Duplicate prevention: same parameters should NOT trigger a duplicate alert
        let duplicateTriggered = try await service.evaluateBatteryWarning(
            batteryPercentage: 0.85,
            safeRangeKm: 361.25,
            routeDistanceKm: 400.0,
            originName: "Sydney CBD",
            destinationName: "Canberra"
        )
        #expect(duplicateTriggered == false)
    }

    @Test("Battery warning does not trigger when route is within safe range")
    func batteryWarningWithinSafeRange() async throws {
        let service = SmartChargeNotificationService()
        service.preferences.batteryWarningEnabled = true

        // Route distance 200 km, safe range 361 km -> safe
        let triggered = try await service.evaluateBatteryWarning(
            batteryPercentage: 0.85,
            safeRangeKm: 361.25,
            routeDistanceKm: 200.0,
            originName: "Sydney CBD",
            destinationName: "Goulburn"
        )

        #expect(triggered == false)
    }

    @Test("Critical route risk alert triggers on critical risk and deduplicates")
    func criticalRouteRiskAlert() async throws {
        let service = SmartChargeNotificationService()
        service.preferences.criticalRiskAlertEnabled = true

        let criticalResult = RouteRiskResult(
            overallRiskLevel: .critical,
            riskScore: 90.0,
            highRiskSegmentsCount: 1,
            criticalSegmentsCount: 1,
            infrastructureGapsCount: 1,
            warnings: ["Segment exceeds physical range."],
            summary: "Route contains critical distance gaps."
        )

        let triggered = try await service.evaluateCriticalRiskAlert(
            riskResult: criticalResult,
            originName: "Sydney",
            destinationName: "Melbourne"
        )

        #expect(triggered == true)
        #expect(service.lastTriggeredNotificationTitle == "Critical Journey Risk")

        // Deduplication test
        let duplicate = try await service.evaluateCriticalRiskAlert(
            riskResult: criticalResult,
            originName: "Sydney",
            destinationName: "Melbourne"
        )
        #expect(duplicate == false)
    }

    @Test("Critical route risk alert ignores low and medium risks")
    func criticalRiskIgnoresLowRisk() async throws {
        let service = SmartChargeNotificationService()
        service.preferences.criticalRiskAlertEnabled = true

        let triggered = try await service.evaluateCriticalRiskAlert(
            riskResult: RouteRiskResult.optimal,
            originName: "Sydney",
            destinationName: "Canberra"
        )

        #expect(triggered == false)
    }

    @Test("Charging stop reminder scheduling")
    func chargingStopReminder() async throws {
        let service = SmartChargeNotificationService()
        service.preferences.chargingStopReminderEnabled = true

        let reminderDate = Date().addingTimeInterval(1800)
        let id = try await service.scheduleChargingStopReminder(
            stationName: "Evie Sutton Forest",
            stopIndex: 0,
            reminderDate: reminderDate
        )

        #expect(id == "\(SmartChargeNotificationService.chargingStopPrefix)0")
        await service.cancelNotification(withId: id)
    }

    @Test("Test notification 5-second scheduling")
    func testNotificationScheduling() async throws {
        let service = SmartChargeNotificationService()
        let id = try await service.scheduleTestNotification(afterSeconds: 5.0)
        #expect(id == SmartChargeNotificationService.testNotificationId)
        #expect(service.lastTriggeredNotificationTitle == "SmartCharge Notification Verified")
        await service.cancelNotification(withId: id)
    }
}
