//
//  JourneyPlannerView.swift
//  SmartCharge
//

import SwiftUI
import CoreLocation
import MapKit

public struct JourneyPlannerView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var journey: JourneyViewModel

    @State private var availableVehicles: [Vehicle] = []
    @State private var activeSearchTarget: LocationSearchSheet.TargetField? = nil
    @State private var showSavedAlert: Bool = false
    @State private var showReminderAlert: Bool = false
    @State private var reminderMessage: String = ""
    @State private var cameraPosition: MapCameraPosition = .automatic

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Section 1: Route Setup & Swap Button
                Section(header: Text("Journey Route & Driving Distance").font(.caption.bold())) {
                    // Origin row
                    Button {
                        activeSearchTarget = .origin
                    } label: {
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(AppTheme.electricTurquoise)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Departure Origin")
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.adaptiveTextSecondary)
                                Text(journey.originName)
                                    .font(.subheadline.bold())
                                    .foregroundColor(AppTheme.adaptiveTextPrimary)
                            }
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .font(.caption)
                                .foregroundColor(AppTheme.slateText)
                        }
                    }

                    // Swap button
                    HStack {
                        Spacer()
                        Button {
                            journey.swapOriginAndDestination()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.arrow.down")
                                Text("Swap Origin & Destination")
                                    .font(.caption.bold())
                            }
                            .foregroundColor(AppTheme.electricBlue)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(AppTheme.elevatedNavy.opacity(0.15))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }

                    // Destination row
                    Button {
                        activeSearchTarget = .destination
                    } label: {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.criticalRed)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Arrival Destination")
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.adaptiveTextSecondary)
                                Text(journey.destinationName)
                                    .font(.subheadline.bold())
                                    .foregroundColor(AppTheme.adaptiveTextPrimary)
                            }
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .font(.caption)
                                .foregroundColor(AppTheme.slateText)
                        }
                    }

                    // MapKit Route Distance Indicator
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MapKit Driving Distance:")
                                .font(.caption)
                                .foregroundColor(AppTheme.adaptiveTextSecondary)
                            if journey.isRouting {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Calculating driving route...")
                                        .font(.caption.italic())
                                        .foregroundColor(AppTheme.electricTurquoise)
                                }
                            } else if let err = journey.routingError {
                                Text("Route Unavailable: \(err)")
                                    .font(.caption.bold())
                                    .foregroundColor(AppTheme.criticalRed)
                            } else {
                                Text("\(String(format: "%.1f", journey.mappedRouteDistanceKm)) km • \(journey.formattedTravelTime)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(AppTheme.adaptiveTextPrimary)
                            }
                        }
                        Spacer()

                        Button {
                            journey.requestRouteRecalculation()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.electricBlue)
                        }
                        .buttonStyle(.plain)
                    }

                    // Map Preview with polyline
                    if !journey.routePolylineCoordinates.isEmpty {
                        Map(position: $cameraPosition) {
                            Marker("Origin", coordinate: journey.originCoordinate)
                                .tint(AppTheme.electricTurquoise)
                            Marker("Destination", coordinate: journey.destinationCoordinate)
                                .tint(AppTheme.criticalRed)

                            ForEach(journey.plannedChargingStops) { stop in
                                Marker(stop.station.name, coordinate: stop.station.coordinate)
                                    .tint(AppTheme.electricBlue)
                            }

                            MapPolyline(coordinates: journey.routePolylineCoordinates)
                                .stroke(AppTheme.electricTurquoise, lineWidth: 4)
                        }
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    }
                }

                // MARK: - Section 2: Vehicle & Connectors
                Section(header: Text("Vehicle Profile").font(.caption.bold())) {
                    Picker("Active Vehicle", selection: Binding(
                        get: { journey.selectedVehicle.id },
                        set: { newId in
                            if let found = availableVehicles.first(where: { $0.id == newId }) {
                                journey.selectVehicle(found)
                            }
                        }
                    )) {
                        ForEach(availableVehicles) { veh in
                            Text(veh.title).tag(veh.id)
                        }
                    }

                    HStack {
                        Text("Theoretical Range (100%):")
                        Spacer()
                        Text("\(Int(journey.selectedVehicle.theoreticalRangeKm)) km WLTP")
                            .foregroundColor(AppTheme.adaptiveTextSecondary)
                    }

                    HStack {
                        Text("Battery Capacity:")
                        Spacer()
                        Text("\(Int(journey.selectedVehicle.batteryCapacityKWh)) kWh")
                            .foregroundColor(AppTheme.adaptiveTextSecondary)
                    }

                    HStack {
                        Text("Supported Connectors:")
                        Spacer()
                        Text(journey.selectedVehicle.supportedConnectors.map(\.displayName).joined(separator: ", "))
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.electricBlue)
                    }
                }

                // MARK: - Section 3: Battery & Safety Reserve
                Section(header: Text("Battery State of Charge & Safety Reserve").font(.caption.bold())) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Starting Battery:")
                            Spacer()
                            Text("\(Int(journey.batteryPercentage * 100))%")
                                .font(.subheadline.bold())
                                .foregroundColor(AppTheme.electricTurquoise)
                        }
                        Slider(value: $journey.batteryPercentage, in: 0.05...1.0, step: 0.05)
                            .tint(AppTheme.electricTurquoise)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Safety Reserve Buffer:")
                            Spacer()
                            Text("\(Int(journey.safetyReservePercentage * 100))%")
                                .font(.subheadline.bold())
                                .foregroundColor(AppTheme.warningAmber)
                        }

                        Picker("Reserve Option", selection: $journey.safetyReservePercentage) {
                            Text("10%").tag(0.10)
                            Text("15%").tag(0.15)
                            Text("20%").tag(0.20)
                            Text("25%").tag(0.25)
                        }
                        .pickerStyle(.segmented)
                    }

                    // Live Blueprint Calculations
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Estimated Physical Range (R × B):")
                            Spacer()
                            Text("\(String(format: "%.1f", journey.currentEstimatedRangeKm)) km")
                                .bold()
                        }
                        .font(.footnote)

                        HStack {
                            Text("Safe Planning Range (current × (1 - S)):")
                            Spacer()
                            Text("\(String(format: "%.1f", journey.safePlanningRangeKm)) km")
                                .bold()
                                .foregroundColor(AppTheme.safeGreen)
                        }
                        .font(.footnote)

                        HStack {
                            Text("Dedicated Reserve Margin:")
                            Spacer()
                            Text("\(String(format: "%.1f", journey.safetyBufferKm)) km")
                                .foregroundColor(AppTheme.warningAmber)
                        }
                        .font(.caption2)
                    }
                    .padding(.vertical, 4)
                }

                // MARK: - Section 4: Routing Strategy
                Section(header: Text("Routing Strategy").font(.caption.bold())) {
                    Picker("Strategy Mode", selection: $journey.routePreference) {
                        ForEach(RoutePreference.allCases) { pref in
                            Text(pref.rawValue).tag(pref)
                        }
                    }

                    Text(journey.routePreference.description)
                        .font(.caption2)
                        .foregroundColor(AppTheme.adaptiveTextSecondary)
                }

                // MARK: - Section 5: Multi-Stop Planned Itinerary
                Section(header: Text("Planned Charging Itinerary").font(.caption.bold())) {
                    if !journey.infrastructureGaps.isEmpty {
                        ForEach(journey.infrastructureGaps, id: \.explanation) { gap in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "exclamationmark.octagon.fill")
                                        .foregroundColor(AppTheme.criticalRed)
                                    Text("Infrastructure Gap Detected")
                                        .font(.subheadline.bold())
                                        .foregroundColor(AppTheme.criticalRed)
                                }
                                Text(gap.explanation)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.adaptiveTextPrimary)
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    if journey.plannedChargingStops.isEmpty && journey.infrastructureGaps.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.safeGreen)
                                Text("Direct Route Reachable")
                                    .font(.subheadline.bold())
                                    .foregroundColor(AppTheme.safeGreen)
                            }
                            Text("Total distance (\(Int(journey.mappedRouteDistanceKm)) km) is within your safe planning range (\(Int(journey.safePlanningRangeKm)) km). No intermediate charging stops required.")
                                .font(.caption)
                                .foregroundColor(AppTheme.adaptiveTextSecondary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        ForEach(journey.plannedChargingStops) { stop in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("STOP \(stop.legNumber):")
                                        .font(.caption.bold())
                                        .foregroundColor(AppTheme.electricTurquoise)
                                    Text(stop.station.name)
                                        .font(.subheadline.bold())
                                        .foregroundColor(AppTheme.adaptiveTextPrimary)
                                    Spacer()
                                    Text("\(stop.estimatedChargeTimeMinutes) min")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AppTheme.electricBlue)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }

                                Text("\(stop.station.operatorName) • \(Int(stop.station.maxPowerKW)) kW • km \(Int(stop.distanceFromOriginKm)) along route")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.adaptiveTextSecondary)

                                HStack {
                                    Text("Arrive: \(Int(stop.arrivalBatteryPercent * 100))%")
                                        .font(.caption2.bold())
                                        .foregroundColor(AppTheme.warningAmber)
                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                    Text("Depart: \(Int(stop.departureBatteryPercent * 100))%")
                                        .font(.caption2.bold())
                                        .foregroundColor(AppTheme.safeGreen)

                                    Spacer()

                                    Text(stop.reachabilityStatus.badgeTitle)
                                        .font(.caption2.bold())
                                        .foregroundColor(stop.reachabilityStatus.isSafelyReachable ? AppTheme.safeGreen : AppTheme.warningAmber)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // Save Journey Button
                    Button {
                        saveCurrentJourney()
                    } label: {
                        Label("Save Journey to Database", systemImage: "square.and.arrow.down")
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.electricBlue)
                    }

                    // Schedule Departure Reminder
                    Button {
                        scheduleDepartureReminder()
                    } label: {
                        Label("Schedule Departure Reminder", systemImage: "bell.badge.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.electricTurquoise)
                    }
                }
            }
            .navigationTitle("Journey Planner")
            .sheet(item: $activeSearchTarget) { target in
                LocationSearchSheet(targetField: target) { selectedName, coordinate in
                    if target == .origin {
                        journey.setOrigin(name: selectedName, coordinate: coordinate)
                    } else {
                        journey.setDestination(name: selectedName, coordinate: coordinate)
                    }
                }
            }
            .alert("Journey Saved", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your planned journey between \(journey.originName) and \(journey.destinationName) was persisted to Core Data.")
            }
            .alert("Departure Reminder Scheduled", isPresented: $showReminderAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(reminderMessage)
            }
            .sensoryFeedback(.success, trigger: showSavedAlert)
            .sensoryFeedback(.selection, trigger: journey.routePreference)
            .task {
                do {
                    availableVehicles = try await container.vehicleRepository.fetchVehicles()
                } catch {
                    availableVehicles = MockDataGenerator.sampleVehicles
                }
            }
        }
    }

    private func saveCurrentJourney() {
        let domainJourney = Journey(
            id: UUID(),
            originName: journey.originName,
            destinationName: journey.destinationName,
            originCoordinate: journey.originCoordinate,
            destinationCoordinate: journey.destinationCoordinate,
            totalDistanceKm: journey.mappedRouteDistanceKm,
            vehicle: journey.selectedVehicle,
            initialBatteryPercent: journey.batteryPercentage,
            safetyReservePercent: journey.safetyReservePercentage,
            routePreference: journey.routePreference,
            plannedChargingStops: journey.plannedChargingStops.map(\.station),
            riskResult: journey.routeRiskResult,
            createdAt: Date()
        )

        Task {
            try? await container.saveJourneyUseCase.execute(domainJourney)
            showSavedAlert = true
        }
    }

    private func scheduleDepartureReminder() {
        Task {
            // Schedule reminder for 30 minutes before an upcoming departure (e.g. 1 hour from now)
            let plannedDeparture = Date().addingTimeInterval(3600)
            do {
                _ = try await journey.scheduleDepartureReminder(
                    departureDate: plannedDeparture,
                    minutesBefore: 30
                )
                await MainActor.run {
                    reminderMessage = "Reminder scheduled for your journey to \(journey.destinationName). You will receive an alert 30 minutes before departure."
                    showReminderAlert = true
                }
            } catch {
                await MainActor.run {
                    reminderMessage = "Could not schedule reminder: \(error.localizedDescription)"
                    showReminderAlert = true
                }
            }
        }
    }
}

extension LocationSearchSheet.TargetField: Identifiable {
    public var id: String { rawValue }
}
