//
//  DashboardView.swift
//  SmartCharge
//

import SwiftUI

public struct DashboardView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var journey: JourneyViewModel
    @State private var isShowingSettings = false

    public init() {
        UserDefaults.standard.register(defaults: [
            "userName": "Vicky"
        ])
    }

    private var greetingText: String {
        let storedName = UserDefaults.standard.string(forKey: "userName")?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? UserDefaults.standard.string(forKey: "user_name")?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? UserDefaults.standard.string(forKey: "driverName")?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let name = storedName, !name.isEmpty {
            return "Welcome back, \(name)!"
        } else {
            return "Welcome back!"
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Personalised Dashboard Header
                    dashboardHeader

                    // Vehicle Header Card
                    vehicleHeaderCard

                    // Reactive Battery Gauge View
                    BatteryGaugeView(
                        batteryPercentage: journey.batteryPercentage,
                        safetyReservePercentage: journey.safetyReservePercentage,
                        currentRangeKm: journey.currentEstimatedRangeKm,
                        safeRangeKm: journey.safePlanningRangeKm
                    )

                    // Key Metrics Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        MetricCardView(
                            title: "Theoretical Range",
                            value: "\(Int(journey.selectedVehicle.theoreticalRangeKm)) km",
                            subtitle: "100% WLTP Benchmark",
                            systemImage: "bolt.car.fill",
                            tintColor: AppTheme.electricBlue
                        )
                        MetricCardView(
                            title: "Current Est. Range",
                            value: "\(String(format: "%.1f", journey.currentEstimatedRangeKm)) km",
                            subtitle: "At \(Int(journey.batteryPercentage * 100))% state of charge",
                            systemImage: "gauge.with.needle.fill",
                            tintColor: AppTheme.electricTurquoise
                        )
                        MetricCardView(
                            title: "Safe Planning Range",
                            value: "\(String(format: "%.1f", journey.safePlanningRangeKm)) km",
                            subtitle: "\(Int(journey.safetyReservePercentage * 100))% safety margin buffer",
                            systemImage: "shield.lefthalf.filled",
                            tintColor: AppTheme.safeGreen
                        )
                        MetricCardView(
                            title: "Safety Buffer",
                            value: "\(String(format: "%.1f", journey.safetyBufferKm)) km",
                            subtitle: "Emergency reserve",
                            systemImage: "exclamationmark.shield.fill",
                            tintColor: AppTheme.warningAmber
                        )
                    }

                    // Active Journey Readiness Card
                    activeJourneyCard

                    // Infrastructure Alerts (if any gaps exist)
                    if !journey.infrastructureGaps.isEmpty {
                        infrastructureGapBanner
                    }

                    // Transparent Planning Disclaimer
                    disclaimerBanner
                }
                .padding()
            }
            .background(AppTheme.adaptiveBackground.ignoresSafeArea())
            .navigationTitle("Journey Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Settings and Notifications")
                }
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        journey.requestRouteRecalculation()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Recalculate route and range")
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsSheetView()
                    .environmentObject(container)
                    .environmentObject(journey)
            }
        }
    }

    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppTheme.electricTurquoise)

            Text("Journey Dashboard")
                .font(.largeTitle.bold())
                .foregroundColor(AppTheme.adaptiveTextPrimary)

            Text("Your next journey starts here.")
                .font(.subheadline)
                .foregroundColor(AppTheme.adaptiveTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }

    private var vehicleHeaderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACTIVE EV PROFILE")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.electricTurquoise)
                    Text(journey.selectedVehicle.title)
                        .font(.title3.bold())
                        .foregroundColor(AppTheme.adaptiveTextPrimary)
                    Text(journey.selectedVehicle.subtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.adaptiveTextSecondary)
                }
                Spacer()
                AnimatedDrivingCarView(isDriving: true, showToggle: false)
            }

            HStack(spacing: 8) {
                ForEach(Array(journey.selectedVehicle.supportedConnectors), id: \.self) { conn in
                    Text(conn.displayName)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.elevatedNavy.opacity(0.3))
                        .foregroundColor(AppTheme.iceCyan)
                        .clipShape(Capsule())
                }
            }
        }
        .smartCard()
    }

    private var activeJourneyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Active Journey Status", systemImage: "point.topleft.down.to.point.bottomright.curvepath.fill")
                    .font(.headline)
                    .foregroundColor(AppTheme.adaptiveTextPrimary)
                Spacer()
                RiskBadgeView(riskLevel: journey.routeRiskResult.overallRiskLevel)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("\(journey.originName) → \(journey.destinationName)")
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.adaptiveTextPrimary)

                if journey.isRouting {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Calculating MapKit driving route...")
                            .font(.caption)
                            .foregroundColor(AppTheme.electricTurquoise)
                    }
                } else {
                    Text("\(String(format: "%.1f", journey.mappedRouteDistanceKm)) km road distance • \(journey.formattedTravelTime)")
                        .font(.caption)
                        .foregroundColor(AppTheme.adaptiveTextSecondary)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Planned Charging Stops:")
                        .font(.caption2)
                        .foregroundColor(AppTheme.adaptiveTextSecondary)
                    Text("\(journey.plannedChargingStops.count) stop\(journey.plannedChargingStops.count == 1 ? "" : "s") required")
                        .font(.footnote.bold())
                        .foregroundColor(AppTheme.electricBlue)
                }
                Spacer()

                if journey.mappedRouteDistanceKm <= journey.safePlanningRangeKm {
                    Label("Direct Safe Trip", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.safeGreen)
                } else if journey.infrastructureGaps.isEmpty {
                    Label("Viable Multi-Stop", systemImage: "bolt.fill")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.electricTurquoise)
                } else {
                    Label("Gap Detected", systemImage: "exclamationmark.octagon.fill")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.criticalRed)
                }
            }
        }
        .smartCard()
    }

    private var infrastructureGapBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.octagon.fill")
                .foregroundColor(AppTheme.criticalRed)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text("Charging Infrastructure Warning")
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.criticalRed)
                Text(journey.infrastructureGaps.first?.explanation ?? "Distance between fast chargers exceeds vehicle range.")
                    .font(.caption)
                    .foregroundColor(AppTheme.adaptiveTextPrimary)
            }
            Spacer()
        }
        .padding()
        .background(AppTheme.criticalRed.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14).stroke(AppTheme.criticalRed.opacity(0.3), lineWidth: 1)
        )
    }

    private var disclaimerBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(AppTheme.slateText)
                .font(.caption)
            Text("Range and stops are planning estimates derived from MapKit driving routes and theoretical battery margins. Weather, speed, terrain, and driving style will affect physical range.")
                .font(.caption2)
                .foregroundColor(AppTheme.adaptiveTextSecondary)
        }
        .padding(.horizontal, 4)
    }
}
