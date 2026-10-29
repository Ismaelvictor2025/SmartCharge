//
//  LocationSearchService.swift
//  SmartCharge
//

import Foundation
import MapKit
import Combine

public struct LocationSearchResult: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public var coordinate: CLLocationCoordinate2D?

    public init(id: String = UUID().uuidString, title: String, subtitle: String, coordinate: CLLocationCoordinate2D? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }

    public static func == (lhs: LocationSearchResult, rhs: LocationSearchResult) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@MainActor
public protocol LocationSearchServiceProtocol: ObservableObject {
    var completions: [LocationSearchResult] { get }
    var isSearching: Bool { get }
    func updateQuery(_ query: String)
    func resolveLocation(for result: LocationSearchResult) async throws -> LocationSearchResult
    func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D
}

@MainActor
public final class LocationSearchService: NSObject, LocationSearchServiceProtocol, MKLocalSearchCompleterDelegate {
    @Published public private(set) var completions: [LocationSearchResult] = []
    @Published public private(set) var isSearching: Bool = false

    private let completer: MKLocalSearchCompleter

    public override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        self.completer.delegate = self
        self.completer.resultTypes = [.address, .pointOfInterest]
        // Prioritise Australian region by default
        self.completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -28.0, longitude: 133.0),
            span: MKCoordinateSpan(latitudeDelta: 35.0, longitudeDelta: 40.0)
        )
    }

    public func updateQuery(_ query: String) {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            completions = []
            isSearching = false
            completer.queryFragment = ""
            return
        }
        isSearching = true
        completer.queryFragment = clean
    }

    public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.completions = completer.results.map {
            LocationSearchResult(
                id: "\($0.title)_\($0.subtitle)",
                title: $0.title,
                subtitle: $0.subtitle
            )
        }
        self.isSearching = false
    }

    public func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        self.isSearching = false
    }

    public func resolveLocation(for result: LocationSearchResult) async throws -> LocationSearchResult {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = "\(result.title) \(result.subtitle)".trimmingCharacters(in: .whitespaces)

        let search = MKLocalSearch(request: searchRequest)
        let response = try await search.start()

        guard let item = response.mapItems.first else {
            throw DomainLocationError.locationNotFound(result.title)
        }

        var resolved = result
        resolved.coordinate = item.placemark.coordinate
        return resolved
    }

    public func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = address
        let search = MKLocalSearch(request: searchRequest)
        let response = try await search.start()

        guard let item = response.mapItems.first else {
            throw DomainLocationError.locationNotFound(address)
        }
        return item.placemark.coordinate
    }
}

public enum DomainLocationError: LocalizedError {
    case locationNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .locationNotFound(let name):
            return "Could not resolve geographic coordinates for '\(name)'."
        }
    }
}
