//
//  NotificationPreferences.swift
//  SmartCharge
//
//  Created by Vicky Neves Rohr on 29/10/2026.
//

import Foundation

public struct NotificationPreferences: Codable, Equatable, Sendable {
    public var departureReminderEnabled: Bool
    public var departureReminderMinutesBefore: Int
    public var batteryWarningEnabled: Bool
    public var criticalRiskAlertEnabled: Bool
    public var chargingStopReminderEnabled: Bool

    public init(
        departureReminderEnabled: Bool = true,
        departureReminderMinutesBefore: Int = 30,
        batteryWarningEnabled: Bool = true,
        criticalRiskAlertEnabled: Bool = true,
        chargingStopReminderEnabled: Bool = true
    ) {
        self.departureReminderEnabled = departureReminderEnabled
        self.departureReminderMinutesBefore = departureReminderMinutesBefore
        self.batteryWarningEnabled = batteryWarningEnabled
        self.criticalRiskAlertEnabled = criticalRiskAlertEnabled
        self.chargingStopReminderEnabled = chargingStopReminderEnabled
    }

    public static var `default`: NotificationPreferences {
        NotificationPreferences()
    }
}
