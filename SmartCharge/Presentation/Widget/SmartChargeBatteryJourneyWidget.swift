//
//  SmartChargeBatteryJourneyWidget.swift
//  SmartCharge
//
//  Created by Vicky Neves Rohr on 29/10/2026.
//

import SwiftUI
import WidgetKit

// MARK: - Timeline Entry
public struct SmartChargeWidgetEntry: TimelineEntry {
    public let date: Date
    public let snapshot: WidgetJourneySnapshot

    public init(date: Date = Date(), snapshot: WidgetJourneySnapshot) {
        self.date = date
        self.snapshot = snapshot
    }
}

// MARK: - Timeline Provider
public struct SmartChargeTimelineProvider: TimelineProvider {
    private let store: WidgetSnapshotStoreProtocol

    public init(store: WidgetSnapshotStoreProtocol = WidgetSnapshotStore.shared) {
        self.store = store
    }

    public func placeholder(in context: Context) -> SmartChargeWidgetEntry {
        SmartChargeWidgetEntry(date: Date(), snapshot: .defaultSample)
    }

    public func getSnapshot(in context: Context, completion: @escaping (SmartChargeWidgetEntry) -> Void) {
        let snapshot = store.loadSnapshot()
        let entry = SmartChargeWidgetEntry(date: Date(), snapshot: snapshot)
        completion(entry)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<SmartChargeWidgetEntry>) -> Void) {
        let snapshot = store.loadSnapshot()
        let currentEntry = SmartChargeWidgetEntry(date: Date(), snapshot: snapshot)

        // Refresh timeline every 15 minutes or when application state changes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Small Widget View
public struct SmartChargeSmallWidgetView: View {
    public let snapshot: WidgetJourneySnapshot

    public init(snapshot: WidgetJourneySnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Image(systemName: "bolt.car.fill")
                    .foregroundColor(AppTheme.electricTurquoise)
                    .font(.caption.bold())
                Text("SmartCharge")
                    .font(.caption2.bold())
                    .foregroundColor(AppTheme.adaptiveTextSecondary)
                Spacer()
                Text("\(Int(snapshot.batteryPercentage * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.electricTurquoise)
            }

            Spacer(minLength: 0)

            // Safe Range Value
            VStack(alignment: .leading, spacing: 2) {
                Text("SAFE RANGE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(AppTheme.slateText)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(String(format: "%.0f", snapshot.safePlanningRangeKm))")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(AppTheme.safeGreen)
                    Text("km")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.safeGreen)
                }
            }

            // Dual-Tier Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Total track
                    Capsule()
                        .fill(AppTheme.elevatedNavy.opacity(0.35))

                    // Safe planning portion
                    Capsule()
                        .fill(AppTheme.safeGreen)
                        .frame(width: max(0, geo.size.width * snapshot.batteryPercentage * (1.0 - snapshot.safetyReservePercentage)))

                    // Emergency buffer portion
                    HStack(spacing: 0) {
                        Spacer()
                            .frame(width: max(0, geo.size.width * snapshot.batteryPercentage * (1.0 - snapshot.safetyReservePercentage)))
                        Capsule()
                            .fill(AppTheme.warningAmber)
                            .frame(width: max(0, geo.size.width * snapshot.batteryPercentage * snapshot.safetyReservePercentage))
                    }
                }
            }
            .frame(height: 6)

            Spacer(minLength: 0)

            // Readiness Badge
            HStack {
                Text(snapshot.readinessStatusText)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(snapshot.isDirectSafeTrip ? AppTheme.safeGreen.opacity(0.2) : AppTheme.warningAmber.opacity(0.2))
                    .foregroundColor(snapshot.isDirectSafeTrip ? AppTheme.safeGreen : AppTheme.warningAmber)
                    .clipShape(Capsule())
                Spacer()
            }
        }
        .padding(12)
        .background(AppTheme.adaptiveCard)
        .widgetURL(URL(string: "smartcharge://dashboard"))
    }
}

// MARK: - Medium Widget View
public struct SmartChargeMediumWidgetView: View {
    public let snapshot: WidgetJourneySnapshot

    public init(snapshot: WidgetJourneySnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Left Column: Battery & Safe Range
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "gauge.with.needle.fill")
                        .foregroundColor(AppTheme.electricTurquoise)
                        .font(.caption)
                    Text(snapshot.vehicleName)
                        .font(.caption2.bold())
                        .foregroundColor(AppTheme.adaptiveTextPrimary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 2) {
                    Text("SAFE PLANNING RANGE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AppTheme.slateText)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(String(format: "%.0f", snapshot.safePlanningRangeKm))")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(AppTheme.safeGreen)
                        Text("km")
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.safeGreen)
                    }

                    Text("Est: \(String(format: "%.0f", snapshot.currentEstimatedRangeKm)) km • \(Int(snapshot.batteryPercentage * 100))% SoC")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.adaptiveTextSecondary)
                }

                Spacer(minLength: 0)

                // Buffer pill
                HStack(spacing: 4) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 9))
                    Text("\(String(format: "%.0f", snapshot.safetyBufferKm)) km (\(Int(snapshot.safetyReservePercentage * 100))% buffer)")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(AppTheme.warningAmber)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppTheme.warningAmber.opacity(0.15))
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Right Column: Active Journey Status
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                        .foregroundColor(AppTheme.electricBlue)
                        .font(.caption)
                    Text("ACTIVE TRIP")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AppTheme.slateText)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(snapshot.originName)")
                        .font(.caption2)
                        .foregroundColor(AppTheme.adaptiveTextSecondary)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 8))
                            .foregroundColor(AppTheme.electricTurquoise)
                        Text("\(snapshot.destinationName)")
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.adaptiveTextPrimary)
                            .lineLimit(1)
                    }
                }

                if snapshot.routeDistanceKm > 0 {
                    Text("\(String(format: "%.0f", snapshot.routeDistanceKm)) km road • \(snapshot.plannedStopsCount) stop\(snapshot.plannedStopsCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(AppTheme.adaptiveTextSecondary)
                }

                Spacer(minLength: 0)

                HStack {
                    Text(snapshot.readinessStatusText)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(snapshot.isDirectSafeTrip ? AppTheme.safeGreen.opacity(0.2) : AppTheme.electricTurquoise.opacity(0.2))
                        .foregroundColor(snapshot.isDirectSafeTrip ? AppTheme.safeGreen : AppTheme.electricTurquoise)
                        .clipShape(Capsule())
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(AppTheme.adaptiveCard)
        .widgetURL(URL(string: "smartcharge://planner"))
    }
}

// MARK: - Combined Entry View
public struct SmartChargeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    public let entry: SmartChargeWidgetEntry

    public init(entry: SmartChargeWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        switch family {
        case .systemSmall:
            SmartChargeSmallWidgetView(snapshot: entry.snapshot)
        case .systemMedium:
            SmartChargeMediumWidgetView(snapshot: entry.snapshot)
        default:
            SmartChargeMediumWidgetView(snapshot: entry.snapshot)
        }
    }
}

// MARK: - WidgetKit Widget Declaration
public struct SmartChargeBatteryJourneyWidget: Widget {
    public let kind: String = "SmartChargeBatteryJourneyWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SmartChargeTimelineProvider()) { entry in
            SmartChargeWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    AppTheme.adaptiveCard
                }
        }
        .configurationDisplayName("Battery & Journey Status")
        .description("Track your safe EV planning range, battery percentage, and journey readiness.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
