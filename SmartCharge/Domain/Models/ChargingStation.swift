//
//  ChargingStation.swift
//  SmartCharge
//

import Foundation
import CoreLocation

public enum AvailabilityStatus: Equatable, Hashable, Codable, Sendable {
    case liveConfirmed(availableCount: Int, totalCount: Int)
    case estimated(availableCount: Int, totalCount: Int)
    case unconfirmed
    case outOfService

    public var displayText: String {
        switch self {
        case .liveConfirmed(let available, let total):
            return "\(available)/\(total) available (live)"
        case .estimated(let available, let total):
            return "Est. \(available)/\(total) available"
        case .unconfirmed:
            return "Live availability not confirmed"
        case .outOfService:
            return "Temporarily out of service"
        }
    }

    public var isAvailable: Bool {
        switch self {
        case .liveConfirmed(let available, _): return available > 0
        case .estimated(let available, _): return available > 0
        case .unconfirmed: return true // treat as potentially usable with warning
        case .outOfService: return false
        }
    }
}

public enum WaitTimeStatus: Equatable, Hashable, Codable, Sendable {
    case confirmedMinutes(Int)
    case estimatedMinutes(Int)
    case unavailable

    public var displayText: String {
        switch self {
        case .confirmedMinutes(let min): return "\(min) min wait"
        case .estimatedMinutes(let min): return "Estimated wait: \(min) min"
        case .unavailable: return "Waiting time unavailable"
        }
    }
}

public struct StationConnector: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let type: ConnectorType
    public let powerKW: Double
    public let currentType: String // e.g. "DC Fast", "AC Slow"

    public init(id: String = UUID().uuidString, type: ConnectorType, powerKW: Double, currentType: String? = nil) {
        self.id = id
        self.type = type
        self.powerKW = powerKW
        self.currentType = currentType ?? (powerKW >= 43.0 ? "DC Fast" : "AC")
    }
}

public struct ChargingStation: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let operatorName: String
    public let latitude: Double
    public let longitude: Double
    public let address: String
    public let connectors: [StationConnector]
    public let totalChargers: Int
    public let isOperational: Bool
    public let maxPowerKW: Double
    public let availabilityStatus: AvailabilityStatus
    public let waitTimeStatus: WaitTimeStatus
    public let pricePerKWh: Double?
    public let dataSource: String
    public let dataFreshnessDate: Date?
    public var distanceKm: Double?

    public init(
        id: String,
        name: String,
        operatorName: String,
        latitude: Double,
        longitude: Double,
        address: String,
        connectors: [StationConnector],
        totalChargers: Int,
        isOperational: Bool = true,
        maxPowerKW: Double? = nil,
        availabilityStatus: AvailabilityStatus = .unconfirmed,
        waitTimeStatus: WaitTimeStatus = .unavailable,
        pricePerKWh: Double? = nil,
        dataSource: String = "Open Charge Map (Cached)",
        dataFreshnessDate: Date? = nil,
        distanceKm: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.operatorName = operatorName
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.connectors = connectors
        self.totalChargers = totalChargers
        self.isOperational = isOperational
        self.maxPowerKW = maxPowerKW ?? connectors.map(\.powerKW).max() ?? 50.0
        self.availabilityStatus = availabilityStatus
        self.waitTimeStatus = waitTimeStatus
        self.pricePerKWh = pricePerKWh
        self.dataSource = dataSource
        self.dataFreshnessDate = dataFreshnessDate
        self.distanceKm = distanceKm
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public func supports(connector: ConnectorType) -> Bool {
        connectors.contains(where: { $0.type == connector })
    }

    public func supportsAny(of connectorsSet: Set<ConnectorType>) -> Bool {
        connectors.contains(where: { connectorsSet.contains($0.type) })
    }
}
