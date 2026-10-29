//
//  LocationSearchSheet.swift
//  SmartCharge
//

import SwiftUI
import MapKit

public struct LocationSearchSheet: View {
    public enum TargetField: String {
        case origin = "Departure Origin"
        case destination = "Arrival Destination"
    }

    public let targetField: TargetField
    public let onSelect: (String, CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchService = LocationSearchService()
    @State private var query: String = ""
    @State private var isResolving: Bool = false
    @State private var errorMessage: String? = nil

    // Australian Major Hub Presets for instant tap
    private let popularLocations: [(name: String, coord: CLLocationCoordinate2D)] = [
        ("Sydney CBD, NSW", CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)),
        ("Canberra Civic, ACT", CLLocationCoordinate2D(latitude: -35.2809, longitude: 149.1300)),
        ("Melbourne CBD, VIC", CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631)),
        ("Brisbane CBD, QLD", CLLocationCoordinate2D(latitude: -27.4698, longitude: 153.0251)),
        ("Adelaide CBD, SA", CLLocationCoordinate2D(latitude: -34.9285, longitude: 138.6007)),
        ("Perth CBD, WA", CLLocationCoordinate2D(latitude: -31.9505, longitude: 115.8605)),
        ("Goulburn, NSW", CLLocationCoordinate2D(latitude: -34.7523, longitude: 149.7214)),
        ("Albury, NSW", CLLocationCoordinate2D(latitude: -36.0800, longitude: 146.9160))
    ]

    public init(targetField: TargetField, onSelect: @escaping (String, CLLocationCoordinate2D) -> Void) {
        self.targetField = targetField
        self.onSelect = onSelect
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Input Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.slateText)
                    TextField("Search Australian city, town, or address...", text: $query)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .onChange(of: query) { newQuery in
                            searchService.updateQuery(newQuery)
                        }

                    if !query.isEmpty {
                        Button {
                            query = ""
                            searchService.updateQuery("")
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.slateText)
                        }
                    }
                }
                .padding()
                .background(AppTheme.adaptiveCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.adaptiveCardBorder, lineWidth: 1)
                )
                .padding()

                if isResolving {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Resolving geographic coordinates...")
                            .font(.caption)
                            .foregroundColor(AppTheme.adaptiveTextSecondary)
                    }
                    .padding()
                }

                if let err = errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(AppTheme.criticalRed)
                        .padding(.horizontal)
                }

                List {
                    if query.isEmpty {
                        Section(header: Text("Major Australian Hubs").font(.caption.bold())) {
                            ForEach(popularLocations, id: \.name) { loc in
                                Button {
                                    onSelect(loc.name, loc.coord)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(AppTheme.electricTurquoise)
                                        Text(loc.name)
                                            .foregroundColor(AppTheme.adaptiveTextPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(AppTheme.slateText)
                                    }
                                }
                            }
                        }
                    } else {
                        Section(header: Text("Search Suggestions").font(.caption.bold())) {
                            if searchService.completions.isEmpty && !searchService.isSearching {
                                Text("No locations found matching '\(query)'")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.adaptiveTextSecondary)
                            }

                            ForEach(searchService.completions) { item in
                                Button {
                                    selectResult(item)
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.subheadline.bold())
                                            .foregroundColor(AppTheme.adaptiveTextPrimary)
                                        if !item.subtitle.isEmpty {
                                            Text(item.subtitle)
                                                .font(.caption2)
                                                .foregroundColor(AppTheme.adaptiveTextSecondary)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .background(AppTheme.adaptiveBackground.ignoresSafeArea())
            .navigationTitle("Select \(targetField.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func selectResult(_ item: LocationSearchResult) {
        isResolving = true
        errorMessage = nil

        Task {
            do {
                let resolved = try await searchService.resolveLocation(for: item)
                if let coord = resolved.coordinate {
                    await MainActor.run {
                        let displayName = item.subtitle.isEmpty ? item.title : "\(item.title), \(item.subtitle)"
                        onSelect(displayName, coord)
                        isResolving = false
                        dismiss()
                    }
                } else {
                    throw DomainLocationError.locationNotFound(item.title)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Could not resolve coordinate for \(item.title). Please select another."
                    self.isResolving = false
                }
            }
        }
    }
}
