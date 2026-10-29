//
//  StationFinderView.swift
//  SmartCharge
//

import SwiftUI
import MapKit

public struct StationFinderView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var journey: JourneyViewModel

    @State private var allStations: [ChargingStation] = []
    @State private var searchQuery: String = ""
    @State private var selectedConnectorFilter: ConnectorType? = nil
    @State private var minPowerFilter: Double = 0.0
    @State private var selectedStation: ChargingStation?
    @State private var viewMode: ViewMode = .list
    @State private var scopeMode: ScopeMode = .alongRoute
    @State private var cameraPosition: MapCameraPosition = .automatic

    public enum ViewMode: String, CaseIterable {
        case list = "List"
        case map = "Map"
    }

    public enum ScopeMode: String, CaseIterable {
        case alongRoute = "Along Route"
        case allAustralia = "All Stations"
    }

    public init() {}

    private var activeSourceStations: [ChargingStation] {
        if scopeMode == .alongRoute && !journey.stationsAlongRoute.isEmpty {
            return journey.stationsAlongRoute
        } else {
            return allStations
        }
    }

    private var filteredStations: [ChargingStation] {
        activeSourceStations.filter { station in
            // Search query filter
            if !searchQuery.isEmpty {
                let clean = searchQuery.lowercased()
                let matches = station.name.lowercased().contains(clean) ||
                              station.operatorName.lowercased().contains(clean) ||
                              station.address.lowercased().contains(clean)
                guard matches else { return false }
            }

            // Connector filter
            if let conn = selectedConnectorFilter {
                guard station.supports(connector: conn) else { return false }
            }

            // Power filter
            if minPowerFilter > 0 {
                guard station.maxPowerKW >= minPowerFilter else { return false }
            }

            return true
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scope picker (Along Route vs All Stations)
                Picker("Scope", selection: $scopeMode) {
                    ForEach(ScopeMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 6)

                // Search & Filter Bar
                filterBar

                if viewMode == .list {
                    listView
                } else {
                    mapView
                }
            }
            .background(AppTheme.adaptiveBackground.ignoresSafeArea())
            .navigationTitle("Station Finder")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
            }
            .sheet(item: $selectedStation) { station in
                StationDetailSheet(station: station)
            }
            .task {
                await loadAllStations()
            }
        }
    }

    private var filterBar: some View {
        VStack(spacing: 8) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.slateText)
                TextField("Search station, city, or operator...", text: $searchQuery)
                    .textFieldStyle(.plain)
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.slateText)
                    }
                }
            }
            .padding(10)
            .background(AppTheme.adaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.adaptiveCardBorder, lineWidth: 1)
            )

            // Horizontal Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Power Filter Menu
                    Menu {
                        Button("All Power Levels") { minPowerFilter = 0.0 }
                        Button("Fast Charging (50 kW+)") { minPowerFilter = 50.0 }
                        Button("Ultra-Rapid (150 kW+)") { minPowerFilter = 150.0 }
                        Button("High Power (250 kW+)") { minPowerFilter = 250.0 }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                            Text(minPowerFilter == 0 ? "Power" : "\(Int(minPowerFilter)) kW+")
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(minPowerFilter > 0 ? AppTheme.electricBlue : AppTheme.adaptiveCard)
                        .foregroundColor(minPowerFilter > 0 ? .white : AppTheme.adaptiveTextPrimary)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.adaptiveCardBorder, lineWidth: 1))
                    }

                    // Connector Filter Chips
                    ForEach(ConnectorType.allCases) { conn in
                        let isSelected = selectedConnectorFilter == conn
                        Button {
                            selectedConnectorFilter = isSelected ? nil : conn
                        } label: {
                            Text(conn.displayName)
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isSelected ? AppTheme.electricTurquoise : AppTheme.adaptiveCard)
                                .foregroundColor(isSelected ? .black : AppTheme.adaptiveTextPrimary)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(AppTheme.adaptiveCardBorder, lineWidth: 1))
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.horizontal)
        .padding(.top, 6)
    }

    private var listView: some View {
        List {
            if filteredStations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bolt.slash")
                        .font(.largeTitle)
                        .foregroundColor(AppTheme.slateText)
                    Text("No charging stations match your criteria.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.adaptiveTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 40)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(filteredStations) { station in
                    Button {
                        selectedStation = station
                    } label: {
                        stationRow(station: station)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(AppTheme.adaptiveBackground)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
    }

    private func stationRow(station: ChargingStation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(station.name)
                        .font(.headline)
                        .foregroundColor(AppTheme.adaptiveTextPrimary)
                    Text("\(station.operatorName) • \(station.address)")
                        .font(.caption)
                        .foregroundColor(AppTheme.adaptiveTextSecondary)
                }
                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(station.maxPowerKW)) kW")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.electricTurquoise)
                    if let dist = station.distanceKm {
                        Text(scopeMode == .alongRoute ? "km \(Int(dist)) on route" : "\(Int(dist)) km away")
                            .font(.caption2)
                            .foregroundColor(AppTheme.adaptiveTextSecondary)
                    }
                }
            }

            // Status and availability pills
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(station.isOperational ? AppTheme.safeGreen : AppTheme.criticalRed)
                        .frame(width: 6, height: 6)
                    Text(station.isOperational ? "Operational" : "Offline")
                        .font(.caption2.bold())
                }
                .foregroundColor(station.isOperational ? AppTheme.safeGreen : AppTheme.criticalRed)

                Text("•")
                    .foregroundColor(AppTheme.adaptiveTextSecondary)

                Text(station.availabilityStatus.displayText)
                    .font(.caption2)
                    .foregroundColor(AppTheme.adaptiveTextSecondary)

                Spacer()

                HStack(spacing: 4) {
                    ForEach(station.connectors.map(\.type), id: \.self) { c in
                        Image(systemName: c.iconName)
                            .font(.caption2)
                            .foregroundColor(AppTheme.electricBlue)
                    }
                }
            }
        }
        .smartCard()
        .padding(.vertical, 2)
    }

    private var mapView: some View {
        Map(position: $cameraPosition) {
            if scopeMode == .alongRoute && !journey.routePolylineCoordinates.isEmpty {
                MapPolyline(coordinates: journey.routePolylineCoordinates)
                    .stroke(AppTheme.electricTurquoise, lineWidth: 3)
            }

            ForEach(filteredStations) { station in
                Annotation(station.name, coordinate: station.coordinate) {
                    Button {
                        selectedStation = station
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "bolt.fill")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(8)
                                .background(station.isOperational ? AppTheme.electricBlue : AppTheme.criticalRed)
                                .clipShape(Circle())
                                .shadow(radius: 4)

                            Text("\(Int(station.maxPowerKW))kW")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 4)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private func loadAllStations() async {
        do {
            let loaded = try await container.stationRepository.searchStations(query: "")
            allStations = loaded
        } catch {
            allStations = MockDataGenerator.sampleStations
        }
    }
}
