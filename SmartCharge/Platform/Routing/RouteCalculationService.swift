//
//  RouteCalculationService.swift
//  SmartCharge
//

import Foundation
import MapKit

public struct DrivingRouteResult: Sendable {
    public let totalDistanceKm: Double
    public let expectedTravelTimeSeconds: TimeInterval
    public let polylineCoordinates: [CLLocationCoordinate2D]
    public let boundingMapRect: MKMapRect?

    public init(
        totalDistanceKm: Double,
        expectedTravelTimeSeconds: TimeInterval,
        polylineCoordinates: [CLLocationCoordinate2D],
        boundingMapRect: MKMapRect? = nil
    ) {
        self.totalDistanceKm = totalDistanceKm
        self.expectedTravelTimeSeconds = expectedTravelTimeSeconds
        self.polylineCoordinates = polylineCoordinates
        self.boundingMapRect = boundingMapRect
    }

    public var formattedDuration: String {
        let hours = Int(expectedTravelTimeSeconds) / 3600
        let minutes = (Int(expectedTravelTimeSeconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

public protocol RouteCalculationServiceProtocol: Sendable {
    func calculateRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> DrivingRouteResult
}

public final class MKDirectionsRouteService: RouteCalculationServiceProtocol, @unchecked Sendable {
    public init() {}

    public func calculateRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> DrivingRouteResult {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

        do {
            let response = try await directions.calculate()
            guard let route = response.routes.first else {
                throw RouteCalculationError.noRouteFound
            }

            let distanceKm = route.distance / 1000.0

            // Extract polyline coordinates
            let pointCount = route.polyline.pointCount
            var coords = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
            route.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))

            // Subsample coordinates if very large to prevent memory overhead while preserving road accuracy
            let sampledCoords: [CLLocationCoordinate2D]
            if coords.count > 500 {
                let step = max(1, coords.count / 300)
                var reduced: [CLLocationCoordinate2D] = []
                for i in stride(from: 0, to: coords.count, by: step) {
                    reduced.append(coords[i])
                }
                if let last = coords.last, reduced.last?.latitude != last.latitude {
                    reduced.append(last)
                }
                sampledCoords = reduced
            } else {
                sampledCoords = coords
            }

            return DrivingRouteResult(
                totalDistanceKm: distanceKm,
                expectedTravelTimeSeconds: route.expectedTravelTime,
                polylineCoordinates: sampledCoords,
                boundingMapRect: route.polyline.boundingMapRect
            )
        } catch {
            throw RouteCalculationError.calculationFailed(error.localizedDescription)
        }
    }
}

public enum RouteCalculationError: LocalizedError, Equatable {
    case noRouteFound
    case calculationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noRouteFound:
            return "No viable driving route could be calculated by MapKit between these locations."
        case .calculationFailed(let reason):
            return "MapKit route calculation failed: \(reason)"
        }
    }
}
