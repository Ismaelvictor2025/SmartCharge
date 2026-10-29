//
//  Journey.swift
//  SmartCharge
//

import Foundation
import CoreLocation

public enum RoutePreference: String, CaseIterable, Identifiable, Codable, Sendable {
    case safest = "Safest"
    case balanced = "Balanced"
    case fastestCharging = "Fastest Charging"

    public var id: String { rawValue }

    public var description: String {
        switch self {
        case .safest:
            return "Prioritises remaining battery buffer, reliable ultra-rapid chargers, and minimal risk of range depletion."
        case .balanced:
            return "Balances detour distance, charging speed, and healthy safety margins."
        case .fastestCharging:
            return "Targets highest kW charging hubs (150kW+) to minimise total dwell time."
        }
    }
}

public struct Journey: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var originName: String
    public var destinationName: String
    public var originCoordinate: CLLocationCoordinate2D?
    public var destinationCoordinate: CLLocationCoordinate2D?
    public var totalDistanceKm: Double
    public var vehicle: Vehicle
    public var initialBatteryPercent: Double
    public var safetyReservePercent: Double
    public var routePreference: RoutePreference
    public var plannedChargingStops: [ChargingStation]
    public var riskResult: RouteRiskResult?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        originName: String,
        destinationName: String,
        originCoordinate: CLLocationCoordinate2D? = nil,
        destinationCoordinate: CLLocationCoordinate2D? = nil,
        totalDistanceKm: Double,
        vehicle: Vehicle,
        initialBatteryPercent: Double = 0.85,
        safetyReservePercent: Double = 0.15,
        routePreference: RoutePreference = .safest,
        plannedChargingStops: [ChargingStation] = [],
        riskResult: RouteRiskResult? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.originName = originName
        self.destinationName = destinationName
        self.originCoordinate = originCoordinate
        self.destinationCoordinate = destinationCoordinate
        self.totalDistanceKm = totalDistanceKm
        self.vehicle = vehicle
        self.initialBatteryPercent = initialBatteryPercent
        self.safetyReservePercent = safetyReservePercent
        self.routePreference = routePreference
        self.plannedChargingStops = plannedChargingStops
        self.riskResult = riskResult
        self.createdAt = createdAt
    }

    public var batteryEstimate: BatteryEstimate {
        vehicle.calculateEstimate(
            batteryPercentage: initialBatteryPercent,
            safetyReserve: safetyReservePercent
        )
    }

    public static func == (lhs: Journey, rhs: Journey) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
