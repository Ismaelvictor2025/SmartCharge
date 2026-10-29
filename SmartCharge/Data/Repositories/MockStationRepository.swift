//
//  MockStationRepository.swift
//  SmartCharge
//

import Foundation
import CoreLocation

public actor MockStationRepository: StationRepositoryProtocol {
    private var stations: [ChargingStation]
    private var favourites: Set<String> = []

    public init(stations: [ChargingStation] = MockDataGenerator.sampleStations) {
        self.stations = stations
    }

    public func fetchNearbyStations(
        near coordinate: CLLocationCoordinate2D,
        radiusKm: Double
    ) async throws -> [ChargingStation] {
        return stations.compactMap { station in
            var copy = station
            let locA = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let locB = CLLocation(latitude: station.latitude, longitude: station.longitude)
            let distanceInKm = locA.distance(from: locB) / 1000.0
            guard distanceInKm <= radiusKm else { return nil }
            copy.distanceKm = distanceInKm
            return copy
        }.sorted { ($0.distanceKm ?? 0) < ($1.distanceKm ?? 0) }
    }

    public func searchStations(query: String) async throws -> [ChargingStation] {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return stations }
        return stations.filter {
            $0.name.lowercased().contains(clean) ||
            $0.operatorName.lowercased().contains(clean) ||
            $0.address.lowercased().contains(clean)
        }
    }

    public func fetchStationsAlongRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        corridorRadiusKm: Double
    ) async throws -> [ChargingStation] {
        // Fallback: simple interpolation between origin and destination
        let coords = [origin, destination]
        let locA = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let locB = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        let approxDist = locA.distance(from: locB) / 1000.0
        return try await fetchStationsAlongPolyline(
            polylineCoordinates: coords,
            totalRouteDistanceKm: approxDist,
            corridorRadiusKm: corridorRadiusKm
        )
    }

    public func fetchStationsAlongPolyline(
        polylineCoordinates: [CLLocationCoordinate2D],
        totalRouteDistanceKm: Double,
        corridorRadiusKm: Double = 40.0
    ) async throws -> [ChargingStation] {
        guard !polylineCoordinates.isEmpty else { return [] }

        // Compute cumulative distances along polyline
        var cumulativeDistancesKm: [Double] = [0.0]
        for i in 1..<polylineCoordinates.count {
            let prev = CLLocation(latitude: polylineCoordinates[i - 1].latitude, longitude: polylineCoordinates[i - 1].longitude)
            let curr = CLLocation(latitude: polylineCoordinates[i].latitude, longitude: polylineCoordinates[i].longitude)
            let leg = prev.distance(from: curr) / 1000.0
            cumulativeDistancesKm.append(cumulativeDistancesKm.last! + leg)
        }
        let polylineTotalKm = max(cumulativeDistancesKm.last ?? 1.0, 1.0)
        let scaleFactor = totalRouteDistanceKm > 0 ? (totalRouteDistanceKm / polylineTotalKm) : 1.0

        var matched: [ChargingStation] = []

        for station in stations {
            let stationLoc = CLLocation(latitude: station.latitude, longitude: station.longitude)

            // Find closest polyline point
            var minDetourKm = Double.infinity
            var bestIndex = 0

            for (idx, coord) in polylineCoordinates.enumerated() {
                let pLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                let d = stationLoc.distance(from: pLoc) / 1000.0
                if d < minDetourKm {
                    minDetourKm = d
                    bestIndex = idx
                }
            }

            if minDetourKm <= corridorRadiusKm {
                var copy = station
                // Estimated road distance along journey from origin to this station
                let distanceAlongPolyline = cumulativeDistancesKm[bestIndex] * scaleFactor
                copy.distanceKm = max(1.0, distanceAlongPolyline)
                matched.append(copy)
            }
        }

        // Sort by distance from origin along route
        return matched.sorted { ($0.distanceKm ?? 0) < ($1.distanceKm ?? 0) }
    }

    public func toggleFavourite(stationId: String) async throws {
        if favourites.contains(stationId) {
            favourites.remove(stationId)
        } else {
            favourites.insert(stationId)
        }
    }

    public func fetchFavourites() async throws -> Set<String> {
        return favourites
    }
}
