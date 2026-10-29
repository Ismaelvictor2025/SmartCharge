//
//  RouteAnalyticsView.swift
//  SmartCharge
//

import SwiftUI
import Charts

public struct RouteAnalyticsView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var journey: JourneyViewModel

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Risk Summary Banner
                    overallRiskCard(risk: journey.routeRiskResult)

                    // Swift Chart: Range vs Segments
                    chartCard

                    // Key Metrics Grid
                    metricsGrid(risk: journey.routeRiskResult)

                    // Segment Analysis Breakdown
                    segmentsCard

                    // Infrastructure Gap Alerts
                    infrastructureAlertsCard(risk: journey.routeRiskResult)
                }
                .padding()
            }
            .background(AppTheme.adaptiveBackground.ignoresSafeArea())
            .navigationTitle("Route Analytics")
        }
    }

    private func overallRiskCard(risk: RouteRiskResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ROUTE RISK CLASSIFICATION")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.electricTurquoise)
                    Text("\(journey.originName) → \(journey.destinationName)")
                        .font(.title3.bold())
                        .foregroundColor(AppTheme.adaptiveTextPrimary)
                }
                Spacer()
                RiskBadgeView(riskLevel: risk.overallRiskLevel)
            }

            Text(risk.summary)
                .font(.footnote)
                .foregroundColor(AppTheme.adaptiveTextSecondary)

            Divider()

            HStack {
                Text("Deterministic Route Risk Score:")
                    .font(.caption)
                    .foregroundColor(AppTheme.adaptiveTextSecondary)
                Spacer()
                Text("\(Int(risk.riskScore)) / 100")
                    .font(.subheadline.bold())
                    .foregroundColor(riskColor(for: risk.overallRiskLevel))
            }
        }
        .smartCard()
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Range Buffer vs Driving Distance")
                .font(.headline)
                .foregroundColor(AppTheme.adaptiveTextPrimary)

            Chart {
                BarMark(
                    x: .value("Category", "Safe Range"),
                    y: .value("Distance (km)", journey.safePlanningRangeKm)
                )
                .foregroundStyle(AppTheme.safeGreen)

                BarMark(
                    x: .value("Category", "Physical Range"),
                    y: .value("Distance (km)", journey.currentEstimatedRangeKm)
                )
                .foregroundStyle(AppTheme.electricTurquoise)

                BarMark(
                    x: .value("Category", "Total Route"),
                    y: .value("Distance (km)", journey.mappedRouteDistanceKm)
                )
                .foregroundStyle(AppTheme.electricBlue)
            }
            .frame(height: 180)
            .padding(.vertical, 8)

            Text("Safe planning range (\(String(format: "%.1f", journey.safePlanningRangeKm)) km) vs total driving distance (\(String(format: "%.1f", journey.mappedRouteDistanceKm)) km). \(journey.plannedChargingStops.count) planned charging stop\(journey.plannedChargingStops.count == 1 ? "" : "s") along route.")
                .font(.caption2)
                .foregroundColor(AppTheme.adaptiveTextSecondary)
        }
        .smartCard()
    }

    private func metricsGrid(risk: RouteRiskResult) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCardView(
                title: "High-Risk Segments",
                value: "\(risk.highRiskSegmentsCount)",
                subtitle: "Exceeds safe margin",
                systemImage: "exclamationmark.triangle.fill",
                tintColor: AppTheme.warningAmber
            )
            MetricCardView(
                title: "Critical Segments",
                value: "\(risk.criticalSegmentsCount)",
                subtitle: "Exceeds physical range",
                systemImage: "xmark.octagon.fill",
                tintColor: AppTheme.criticalRed
            )
            MetricCardView(
                title: "Infrastructure Gaps",
                value: "\(journey.infrastructureGaps.count)",
                subtitle: "Zero backup corridors",
                systemImage: "bolt.slash.fill",
                tintColor: AppTheme.warningAmber
            )
            MetricCardView(
                title: "Charging Dwell Time",
                value: "\(journey.plannedChargingStops.map(\.estimatedChargeTimeMinutes).reduce(0, +)) min",
                subtitle: "\(journey.plannedChargingStops.count) planned stop\(journey.plannedChargingStops.count == 1 ? "" : "s")",
                systemImage: "clock.badge.checkmark.fill",
                tintColor: AppTheme.electricTurquoise
            )
        }
    }

    private var segmentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leg-by-Leg Route Segments")
                .font(.headline)
                .foregroundColor(AppTheme.adaptiveTextPrimary)

            if journey.plannedChargingStops.isEmpty {
                segmentRow(
                    from: journey.originName,
                    to: journey.destinationName,
                    distance: journey.mappedRouteDistanceKm,
                    status: "Direct Safe Leg",
                    color: AppTheme.safeGreen
                )
            } else {
                var prevName = journey.originName
                ForEach(journey.plannedChargingStops) { stop in
                    segmentRow(
                        from: prevName,
                        to: stop.station.name,
                        distance: stop.legDistanceKm,
                        status: "Stop \(stop.legNumber) • \(stop.estimatedChargeTimeMinutes)m charge",
                        color: stop.reachabilityStatus.isSafelyReachable ? AppTheme.electricTurquoise : AppTheme.warningAmber
                    )
                    Divider()
                    let _ = { prevName = stop.station.name }()
                }

                // Final leg to destination
                if let lastStop = journey.plannedChargingStops.last {
                    let finalLegDist = max(0, journey.mappedRouteDistanceKm - lastStop.distanceFromOriginKm)
                    segmentRow(
                        from: lastStop.station.name,
                        to: journey.destinationName,
                        distance: finalLegDist,
                        status: "Final Arrival Leg",
                        color: AppTheme.safeGreen
                    )
                }
            }
        }
        .smartCard()
    }

    private func segmentRow(from: String, to: String, distance: Double, status: String, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(from) → \(to)")
                    .font(.subheadline.bold())
                Text(status)
                    .font(.caption2)
                    .foregroundColor(color)
            }
            Spacer()
            Text("\(String(format: "%.1f", distance)) km")
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.adaptiveTextPrimary)
        }
    }

    private func infrastructureAlertsCard(risk: RouteRiskResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Infrastructure & Route Notices", systemImage: "bell.badge.fill")
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.warningAmber)

            if journey.infrastructureGaps.isEmpty && risk.warnings.isEmpty {
                Text("No critical charging bottlenecks detected along this route.")
                    .font(.caption)
                    .foregroundColor(AppTheme.adaptiveTextSecondary)
            } else {
                ForEach(journey.infrastructureGaps, id: \.explanation) { gap in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .foregroundColor(AppTheme.criticalRed)
                            .font(.caption)
                        Text(gap.explanation)
                            .font(.caption)
                            .foregroundColor(AppTheme.criticalRed)
                    }
                    .padding(.vertical, 2)
                }

                ForEach(risk.warnings, id: \.self) { warning in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(AppTheme.warningAmber)
                            .font(.caption)
                        Text(warning)
                            .font(.caption)
                            .foregroundColor(AppTheme.adaptiveTextPrimary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .smartCard()
    }

    private func riskColor(for level: RiskLevel) -> Color {
        switch level {
        case .low: return AppTheme.safeGreen
        case .medium: return AppTheme.warningAmber
        case .high: return Color.orange
        case .critical: return AppTheme.criticalRed
        }
    }
}
