//
//  Vehicle.swift
//  SmartCharge
//

import Foundation

public struct Vehicle: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var make: String
    public var model: String
    public var theoreticalRangeKm: Double
    public var batteryCapacityKWh: Double
    public var supportedConnectors: Set<ConnectorType>
    public var isDefault: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        make: String,
        model: String,
        theoreticalRangeKm: Double,
        batteryCapacityKWh: Double,
        supportedConnectors: Set<ConnectorType> = [.ccs2, .type2],
        isDefault: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.make = make
        self.model = model
        self.theoreticalRangeKm = theoreticalRangeKm
        self.batteryCapacityKWh = batteryCapacityKWh
        self.supportedConnectors = supportedConnectors
        self.isDefault = isDefault
        self.createdAt = createdAt
    }

    public var title: String {
        name.isEmpty ? "\(make) \(model)" : name
    }

    public var subtitle: String {
        "\(make) \(model) • \(Int(theoreticalRangeKm)) km WLTP"
    }

    public func calculateEstimate(
        batteryPercentage: Double,
        safetyReserve: Double = 0.15
    ) -> BatteryEstimate {
        BatteryEstimate(
            theoreticalRangeKm: theoreticalRangeKm,
            batteryPercentage: batteryPercentage,
            safetyReservePercentage: safetyReserve,
            batteryCapacityKWh: batteryCapacityKWh
        )
    }
}
