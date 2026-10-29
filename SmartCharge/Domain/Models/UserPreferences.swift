//
//  UserPreferences.swift
//  SmartCharge
//

import Foundation

public struct UserPreferences: Equatable, Sendable {
    public var selectedVehicleId: UUID?
    public var defaultSafetyReserve: Double
    public var defaultRoutePreference: RoutePreference
    public var preferredConnectors: Set<ConnectorType>
    public var preferredMinChargingPowerKW: Double
    public var alertOnLowMargin: Bool

    public init(
        selectedVehicleId: UUID? = nil,
        defaultSafetyReserve: Double = 0.15,
        defaultRoutePreference: RoutePreference = .safest,
        preferredConnectors: Set<ConnectorType> = [.ccs2, .type2],
        preferredMinChargingPowerKW: Double = 50.0,
        alertOnLowMargin: Bool = true
    ) {
        self.selectedVehicleId = selectedVehicleId
        self.defaultSafetyReserve = defaultSafetyReserve
        self.defaultRoutePreference = defaultRoutePreference
        self.preferredConnectors = preferredConnectors
        self.preferredMinChargingPowerKW = preferredMinChargingPowerKW
        self.alertOnLowMargin = alertOnLowMargin
    }

    public static var `default`: UserPreferences {
        UserPreferences()
    }
}
