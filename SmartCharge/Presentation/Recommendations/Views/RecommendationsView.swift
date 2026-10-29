//
//  RecommendationsView.swift
//  SmartCharge
//

import SwiftUI
import CoreLocation

public struct RecommendationsView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var journey: JourneyViewModel

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Reactive trip controls
                    controlHeaderCard

                    if journey.isRouting {
                        ProgressView("Evaluating optimal charging hubs along route...")
                            .padding()
                    } else if let result = journey.recommendationResult {
                        // Reachability Status Invariant Banner
                        reachabilityBanner(status: result.reachabilityStatus)

                        // If multi-stop required, show full planned stop breakdown
                        if !journey.plannedChargingStops.isEmpty {
                            multiStopBreakdownCard
                        } else if let best = result.bestStation {
                            bestStationCard(station: best, result: result)
                        }

                        // Score Breakdown Card
                        if let breakdown = result.scoreBreakdown {
                            scoringBreakdownCard(breakdown: breakdown)
                        }

                        // Alternative Station Option
                        if let alt = result.alternativeStation {
                            alternativeStationCard(station: alt, reachability: result.alternativeReachability)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 32))
                                .foregroundColor(AppTheme.safeGreen)
                            Text("Direct Journey Achievable")
                                .font(.headline)
                                .foregroundColor(AppTheme.adaptiveTextPrimary)
                            Text("Your journey (\(Int(journey.mappedRouteDistanceKm)) km) is within safe planning range (\(Int(journey.safePlanningRangeKm)) km). No intermediate charging stops required.")
                                .font(.caption)
                                .foregroundColor(AppTheme.adaptiveTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .smartCard()
                    }
                }
                .padding()
            }
            .background(AppTheme.adaptiveBackground.ignoresSafeArea())
            .navigationTitle("Smart Recommendations")
        }
    }

    private var controlHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("STRATEGY & BATTERY PARAMETERS")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.electricTurquoise)
                Spacer()
                Picker("Strategy", selection: $journey.routePreference) {
                    ForEach(RoutePreference.allCases) { pref in
                        Text(pref.rawValue).tag(pref)
                    }
                }
                .sensoryFeedback(.selection, trigger: journey.routePreference)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Battery: \(Int(journey.batteryPercentage * 100))% • Reserve: \(Int(journey.safetyReservePercentage * 100))%")
                        .font(.subheadline.bold())
                    Text("Safe: \(String(format: "%.1f", journey.safePlanningRangeKm)) km • Physical: \(String(format: "%.1f", journey.currentEstimatedRangeKm)) km • Route: \(String(format: "%.1f", journey.mappedRouteDistanceKm)) km")
                        .font(.caption2)
                        .foregroundColor(AppTheme.adaptiveTextSecondary)
                }
                Spacer()
            }

            Slider(value: $journey.batteryPercentage, in: 0.10...1.0, step: 0.05)
                .tint(AppTheme.electricTurquoise)
        }
        .smartCard()
    }

    private func reachabilityBanner(status: ReachabilityStatus) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: bannerIcon(for: status))
                .font(.title2)
                .foregroundColor(bannerColor(for: status))

            VStack(alignment: .leading, spacing: 4) {
                Text(status.badgeTitle)
                    .font(.subheadline.bold())
                    .foregroundColor(bannerColor(for: status))
                Text(status.advisoryMessage)
                    .font(.caption)
                    .foregroundColor(AppTheme.adaptiveTextPrimary)
            }
            Spacer()
        }
        .padding()
        .background(bannerColor(for: status).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(bannerColor(for: status).opacity(0.3), lineWidth: 1)
        )
    }

    private var multiStopBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("RECOMMENDED CHARGING STOPS (\(journey.plannedChargingStops.count))", systemImage: "bolt.badge.clock.fill")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.electricTurquoise)
                Spacer()
                Text("\(journey.routePreference.rawValue) Mode")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.elevatedNavy.opacity(0.2))
                    .clipShape(Capsule())
            }

            ForEach(journey.plannedChargingStops) { stop in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Stop \(stop.legNumber): \(stop.station.name)")
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.adaptiveTextPrimary)
                        Spacer()
                        Text("\(Int(stop.station.maxPowerKW)) kW DC")
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.electricTurquoise)
                    }

                    Text("\(stop.station.operatorName) • km \(Int(stop.distanceFromOriginKm)) along corridor")
                        .font(.caption)
                        .foregroundColor(AppTheme.adaptiveTextSecondary)

                    HStack {
                        Text("Arrive: \(Int(stop.arrivalBatteryPercent * 100))% → Charge to \(Int(stop.departureBatteryPercent * 100))% (~\(stop.estimatedChargeTimeMinutes) min)")
                            .font(.caption2)
                            .foregroundColor(AppTheme.adaptiveTextSecondary)
                        Spacer()
                        Text(stop.reachabilityStatus.badgeTitle)
                            .font(.caption2.bold())
                            .foregroundColor(stop.reachabilityStatus.isSafelyReachable ? AppTheme.safeGreen : AppTheme.warningAmber)
                    }
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
        .smartCard()
    }

    private func bestStationCard(station: ChargingStation, result: RecommendationResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("TOP RECOMMENDED STOP", systemImage: "star.fill")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.electricTurquoise)
                Spacer()
                Text("\(Int(station.maxPowerKW)) kW DC")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.electricBlue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }

            Text(station.name)
                .font(.title3.bold())
                .foregroundColor(AppTheme.adaptiveTextPrimary)

            Text("\(station.operatorName) • \(station.address)")
                .font(.caption)
                .foregroundColor(AppTheme.adaptiveTextSecondary)

            Divider()

            Text(result.whyRecommended)
                .font(.footnote)
                .foregroundColor(AppTheme.adaptiveTextPrimary)

            HStack {
                Label("\(Int(station.distanceKm ?? 0)) km away", systemImage: "location.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.adaptiveTextSecondary)

                Spacer()

                Text(station.availabilityStatus.displayText)
                    .font(.caption.bold())
                    .foregroundColor(station.isOperational ? AppTheme.safeGreen : AppTheme.criticalRed)
            }
        }
        .smartCard()
    }

    private func scoringBreakdownCard(breakdown: ScoreBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recommendation Scoring Matrix")
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.adaptiveTextPrimary)

            scoreRow(title: "Distance Optimization (25%)", score: breakdown.distanceScore)
            scoreRow(title: "Wait Time & Queuing (25%)", score: breakdown.waitTimeScore)
            scoreRow(title: "Charger Availability (20%)", score: breakdown.availabilityScore)
            scoreRow(title: "Charging Power Speed (20%)", score: breakdown.speedScore)
            scoreRow(title: "Charging Cost (10%)", score: breakdown.costScore)

            Divider()

            HStack {
                Text("Overall Composite Score:")
                    .font(.footnote.bold())
                Spacer()
                Text("\(Int(breakdown.compositeScore))/100")
                    .font(.footnote.bold())
                    .foregroundColor(AppTheme.electricTurquoise)
            }
        }
        .smartCard()
    }

    private func scoreRow(title: String, score: Double) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.adaptiveTextSecondary)
            Spacer()
            Text("\(Int(score))")
                .font(.caption.bold())
                .foregroundColor(AppTheme.adaptiveTextPrimary)
        }
    }

    private func alternativeStationCard(station: ChargingStation, reachability: ReachabilityStatus?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("ALTERNATIVE CHARGING STOP", systemImage: "arrow.triangle.branch")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.adaptiveTextSecondary)
                Spacer()
                if let r = reachability {
                    Text(r.badgeTitle)
                        .font(.caption2.bold())
                        .foregroundColor(bannerColor(for: r))
                }
            }

            Text(station.name)
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.adaptiveTextPrimary)

            Text("\(station.operatorName) • \(Int(station.distanceKm ?? 0)) km away • \(Int(station.maxPowerKW)) kW")
                .font(.caption)
                .foregroundColor(AppTheme.adaptiveTextSecondary)
        }
        .smartCard()
    }

    private func bannerColor(for status: ReachabilityStatus) -> Color {
        switch status {
        case .reachableWithinSafeRange: return AppTheme.safeGreen
        case .reachableCautionBeyondReserve: return AppTheme.warningAmber
        case .unreachableExceedsPhysicalRange: return AppTheme.criticalRed
        }
    }

    private func bannerIcon(for status: ReachabilityStatus) -> String {
        switch status {
        case .reachableWithinSafeRange: return "checkmark.shield.fill"
        case .reachableCautionBeyondReserve: return "exclamationmark.triangle.fill"
        case .unreachableExceedsPhysicalRange: return "xmark.octagon.fill"
        }
    }
}
