//
//  FavouriteStation.swift
//  SmartCharge
//

import Foundation
import CoreLocation

public struct FavouriteStation: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let operatorName: String
    public let coordinate: CLLocationCoordinate2D
    public let powerKW: Double
    public let supportedConnectors: Set<ConnectorType>
    public let savedAt: Date

    public init(
        id: String,
        name: String,
        operatorName: String,
        coordinate: CLLocationCoordinate2D,
        powerKW: Double = 50.0,
        supportedConnectors: Set<ConnectorType> = [.ccs2],
        savedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.operatorName = operatorName
        self.coordinate = coordinate
        self.powerKW = powerKW
        self.supportedConnectors = supportedConnectors
        self.savedAt = savedAt
    }

    public static func == (lhs: FavouriteStation, rhs: FavouriteStation) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
