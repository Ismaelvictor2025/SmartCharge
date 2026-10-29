//
//  SmartChargeNotificationService.swift
//  SmartCharge
//
//  Created by Vicky Neves Rohr on 29/10/2026.
//

import Foundation
import UserNotifications
import Combine
import UIKit

@MainActor
public protocol SmartChargeNotificationServiceProtocol: AnyObject, Sendable {
    var authorizationStatus: UNAuthorizationStatus { get }
    var preferences: NotificationPreferences { get set }
    var lastTriggeredNotificationTitle: String? { get }
    
    func checkAuthorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func scheduleDepartureReminder(
        journeyName: String,
        destinationName: String,
        departureDate: Date,
        minutesBefore: Int
    ) async throws -> String
    func evaluateBatteryWarning(
        batteryPercentage: Double,
        safeRangeKm: Double,
        routeDistanceKm: Double,
        originName: String,
        destinationName: String
    ) async throws -> Bool
    func evaluateCriticalRiskAlert(
        riskResult: RouteRiskResult,
        originName: String,
        destinationName: String
    ) async throws -> Bool
    func scheduleChargingStopReminder(
        stationName: String,
        stopIndex: Int,
        reminderDate: Date
    ) async throws -> String
    func scheduleTestNotification(afterSeconds seconds: TimeInterval) async throws -> String
    func cancelDepartureReminder() async
    func cancelNotification(withId identifier: String) async
    func cancelAllPendingNotifications() async
    func getPendingNotifications() async -> [UNNotificationRequest]
}

@MainActor
public final class SmartChargeNotificationService: NSObject, ObservableObject, SmartChargeNotificationServiceProtocol, UNUserNotificationCenterDelegate {
    public static let shared = SmartChargeNotificationService()

    // Published State
    @Published public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published public var preferences: NotificationPreferences {
        didSet {
            savePreferences()
        }
    }
    @Published public private(set) var lastTriggeredNotificationTitle: String? = nil
    @Published public private(set) var pendingRequestsCount: Int = 0

    // Callback for Deep-Linking Navigation
    public var onNotificationNavigate: ((String) -> Void)?

    // Notification Identifiers
    public static let departureReminderId = "com.vicky.SmartCharge.reminder.departure"
    public static let batteryWarningId = "com.vicky.SmartCharge.warning.battery"
    public static let criticalRiskId = "com.vicky.SmartCharge.alert.criticalRisk"
    public static let chargingStopPrefix = "com.vicky.SmartCharge.reminder.stop."
    public static let testNotificationId = "com.vicky.SmartCharge.test.notification"

    // Deduplication caches to prevent duplicate alerts
    private var lastBatteryWarningHash: String? = nil
    private var lastCriticalRiskHash: String? = nil
    private let notificationCenter: UNUserNotificationCenter

    public init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
        
        // Load saved preferences or baseline defaults
        if let data = UserDefaults.standard.data(forKey: "smartcharge.notification.preferences"),
           let decoded = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            self.preferences = decoded
        } else {
            self.preferences = .default
        }

        super.init()
        self.notificationCenter.delegate = self
        
        Task {
            await self.checkAuthorizationStatus()
            await self.refreshPendingCount()
        }
    }

    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "smartcharge.notification.preferences")
        }
    }

    // MARK: - Permission Lifecycle
    @discardableResult
    public func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
        return settings.authorizationStatus
    }

    public func requestAuthorization() async throws -> Bool {
        let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        await checkAuthorizationStatus()
        return granted
    }

    public func openSettingsURL() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }

    // MARK: - Notification A: Journey Departure Reminder
    @discardableResult
    public func scheduleDepartureReminder(
        journeyName: String,
        destinationName: String,
        departureDate: Date,
        minutesBefore: Int
    ) async throws -> String {
        guard preferences.departureReminderEnabled else { return "" }

        // Remove any prior pending departure reminder to prevent duplicates
        await cancelDepartureReminder()

        let reminderDate = departureDate.addingTimeInterval(-Double(minutesBefore * 60))
        guard reminderDate > Date() else {
            // If reminder date is already in the past, schedule immediately for testing/readiness
            let content = UNMutableNotificationContent()
            content.title = "Your SmartCharge Journey Is Coming Up"
            content.body = "Review your battery range, charging stops, and route conditions before departure to \(destinationName)."
            content.sound = .default
            content.categoryIdentifier = "JOURNEY_REMINDER"
            content.userInfo = ["targetTab": "Planner", "type": "departure"]

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: Self.departureReminderId, content: content, trigger: trigger)
            try await notificationCenter.add(request)
            await refreshPendingCount()
            return Self.departureReminderId
        }

        let content = UNMutableNotificationContent()
        content.title = "Your SmartCharge Journey Is Coming Up"
        content.body = "Departure to \(destinationName) scheduled in \(minutesBefore) minutes. Review your battery range and charging stops."
        content.sound = .default
        content.categoryIdentifier = "JOURNEY_REMINDER"
        content.userInfo = ["targetTab": "Planner", "type": "departure"]

        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(identifier: Self.departureReminderId, content: content, trigger: trigger)
        try await notificationCenter.add(request)
        await refreshPendingCount()
        return Self.departureReminderId
    }

    public func cancelDepartureReminder() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [Self.departureReminderId])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [Self.departureReminderId])
        await refreshPendingCount()
    }

    // MARK: - Notification B: Battery Planning Warning
    @discardableResult
    public func evaluateBatteryWarning(
        batteryPercentage: Double,
        safeRangeKm: Double,
        routeDistanceKm: Double,
        originName: String,
        destinationName: String
    ) async throws -> Bool {
        guard preferences.batteryWarningEnabled else { return false }
        guard routeDistanceKm > 0 else { return false }

        // Check if route distance strictly exceeds safe planning range
        let exceedsSafeRange = routeDistanceKm > safeRangeKm
        guard exceedsSafeRange else {
            // Cleared condition
            lastBatteryWarningHash = nil
            return false
        }

        // Deduplication hash to prevent multiple identical alerts during slider adjustments
        let currentHash = "\(Int(batteryPercentage * 100))_\(Int(safeRangeKm))_\(Int(routeDistanceKm))_\(originName)_\(destinationName)"
        guard currentHash != lastBatteryWarningHash else {
            return false
        }
        lastBatteryWarningHash = currentHash

        let content = UNMutableNotificationContent()
        content.title = "Battery Range Warning"
        content.body = "Your planned journey (\(String(format: "%.0f", routeDistanceKm)) km) exceeds your safe driving range (\(String(format: "%.0f", safeRangeKm)) km). Review your charging options before departure. (Estimate based on configured reserve, not live telemetry)."
        content.sound = .default
        content.categoryIdentifier = "BATTERY_WARNING"
        content.userInfo = ["targetTab": "Planner", "type": "battery_warning"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.5, repeats: false)
        let request = UNNotificationRequest(identifier: Self.batteryWarningId, content: content, trigger: trigger)

        try await notificationCenter.add(request)
        self.lastTriggeredNotificationTitle = content.title
        await refreshPendingCount()
        return true
    }

    // MARK: - Notification C: Critical Route Risk Alert
    @discardableResult
    public func evaluateCriticalRiskAlert(
        riskResult: RouteRiskResult,
        originName: String,
        destinationName: String
    ) async throws -> Bool {
        guard preferences.criticalRiskAlertEnabled else { return false }
        guard riskResult.overallRiskLevel == .critical else {
            lastCriticalRiskHash = nil
            return false
        }

        // Deduplication hash
        let currentHash = "\(riskResult.overallRiskLevel.rawValue)_\(riskResult.criticalSegmentsCount)_\(originName)_\(destinationName)"
        guard currentHash != lastCriticalRiskHash else {
            return false
        }
        lastCriticalRiskHash = currentHash

        let content = UNMutableNotificationContent()
        content.title = "Critical Journey Risk"
        content.body = "Your route contains charging gaps or distance segments exceeding physical battery range. Mandatory charging review required."
        content.sound = .default
        content.categoryIdentifier = "CRITICAL_RISK"
        content.userInfo = ["targetTab": "Analytics", "type": "critical_risk"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.5, repeats: false)
        let request = UNNotificationRequest(identifier: Self.criticalRiskId, content: content, trigger: trigger)

        try await notificationCenter.add(request)
        self.lastTriggeredNotificationTitle = content.title
        await refreshPendingCount()
        return true
    }

    // MARK: - Notification D: Charging Stop Reminder
    @discardableResult
    public func scheduleChargingStopReminder(
        stationName: String,
        stopIndex: Int,
        reminderDate: Date
    ) async throws -> String {
        guard preferences.chargingStopReminderEnabled else { return "" }

        let identifier = "\(Self.chargingStopPrefix)\(stopIndex)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Charging Stop Reminder"
        content.body = "Stop #\(stopIndex + 1): Review planned charging stop at \(stationName) and verify plug compatibility before departing."
        content.sound = .default
        content.userInfo = ["targetTab": "Stations", "stationName": stationName]

        let interval = max(1.0, reminderDate.timeIntervalSince(Date()))
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await notificationCenter.add(request)
        await refreshPendingCount()
        return identifier
    }

    // MARK: - In-App Test Feature: Test Notification — 5 Seconds
    @discardableResult
    public func scheduleTestNotification(afterSeconds seconds: TimeInterval = 5.0) async throws -> String {
        let content = UNMutableNotificationContent()
        content.title = "SmartCharge Notification Verified"
        content.body = "Local notifications are fully active! Scheduled safely for your next EV road trip."
        content.sound = .default
        content.badge = 1
        content.userInfo = ["targetTab": "Dashboard", "isTest": true]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1.0, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: Self.testNotificationId, content: content, trigger: trigger)

        try await notificationCenter.add(request)
        self.lastTriggeredNotificationTitle = content.title
        await refreshPendingCount()
        return Self.testNotificationId
    }

    // MARK: - Cancellation & Inspection
    public func cancelNotification(withId identifier: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
        await refreshPendingCount()
    }

    public func cancelAllPendingNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        await refreshPendingCount()
    }

    public func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }

    private func refreshPendingCount() async {
        let pending = await notificationCenter.pendingNotificationRequests()
        self.pendingRequestsCount = pending.count
    }

    // MARK: - UNUserNotificationCenterDelegate
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Foreground presentation ensures notification displays while app is open
        return [.banner, .sound, .badge, .list]
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        if let targetTab = userInfo["targetTab"] as? String {
            self.onNotificationNavigate?(targetTab)

            let tabIndex: Int
            switch targetTab.lowercased() {
            case "dashboard": tabIndex = 0
            case "planner": tabIndex = 1
            case "stations": tabIndex = 2
            case "recommend": tabIndex = 3
            case "analytics": tabIndex = 4
            default: tabIndex = 0
            }
            NotificationCenter.default.post(name: NSNotification.Name("SmartChargeNavigateTab"), object: tabIndex)
        }
    }
}
