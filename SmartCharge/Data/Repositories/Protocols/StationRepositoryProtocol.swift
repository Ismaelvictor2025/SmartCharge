//
//  StationRepositoryProtocol.swift
//  SmartCharge
//

import Foundation
import CoreLocation

public protocol StationRepositoryProtocol: Sendable {
    func fetchNearbyStations(
        near coordinate: CLLocationCoordinate2D,
        radiusKm: Double
    ) async throws -> [ChargingStation]

    func searchStations(query: String) async throws -> [ChargingStation]

    func fetchStationsAlongRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        corridorRadiusKm: Double
    ) async throws -> [ChargingStation]

    func fetchStationsAlongPolyline(
        polylineCoordinates: [CLLocationCoordinate2D],
        totalRouteDistanceKm: Double,
        corridorRadiusKm: Double
    ) async throws -> [ChargingStation]

    func toggleFavourite(stationId: String) async throws
    func fetchFavourites() async throws -> Set<String>
}
