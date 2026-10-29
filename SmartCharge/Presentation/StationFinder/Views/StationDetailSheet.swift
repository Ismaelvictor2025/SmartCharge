//
//  StationDetailSheet.swift
//  SmartCharge
//

import SwiftUI

public struct StationDetailSheet: View {
    public let station: ChargingStation
    @Environment(\.dismiss) private var dismiss
    @State private var isReminderScheduled: Bool = false

    public init(station: ChargingStation) {
        self.station = station
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header card
                    VStack(alignment: .leading, spacing: 6) {
                        Text(station.operatorName.uppercased())
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.electricTurquoise)
                        Text(station.name)
                            .font(.title2.bold())
                            .foregroundColor(AppTheme.adaptiveTextPrimary)
                        Text(station.address)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.adaptiveTextSecondary)
                    }
                    .smartCard()

                    // Capabilities Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCardView(
                            title: "Max Power",
                            value: "\(Int(station.maxPowerKW)) kW",
                            subtitle: "DC Fast / Ultra-Rapid",
                            systemImage: "bolt.badge.automatic.fill",
                            tintColor: AppTheme.electricTurquoise
                        )
                        MetricCardView(
                            title: "Total Chargers",
                            value: "\(station.totalChargers)",
                            subtitle: "\(station.connectors.count) connector types",
                            systemImage: "ev.plug.dc.fill",
                            tintColor: AppTheme.electricBlue
                        )
                        MetricCardView(
                            title: "Reported State",
                            value: station.availabilityStatus.displayText,
                            subtitle: "Operational status",
                            systemImage: "antenna.radiowaves.left.and.right",
                            tintColor: station.isOperational ? AppTheme.safeGreen : AppTheme.criticalRed
                        )
                        MetricCardView(
                            title: "Wait Time",
                            value: station.waitTimeStatus.displayText,
                            subtitle: "Queue estimate",
                            systemImage: "clock.fill",
                            tintColor: AppTheme.warningAmber
                        )
                    }

                    // Connector List
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Connectors Available")
                            .font(.headline)
                            .foregroundColor(AppTheme.adaptiveTextPrimary)

                        ForEach(station.connectors) { conn in
                            HStack {
                                Image(systemName: conn.type.iconName)
                                    .foregroundColor(AppTheme.electricTurquoise)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(conn.type.displayName)
                                        .font(.subheadline.bold())
                                    Text(conn.currentType)
                                        .font(.caption2)
                                        .foregroundColor(AppTheme.adaptiveTextSecondary)
                                }
                                Spacer()
                                Text("\(Int(conn.powerKW)) kW")
                                    .font(.subheadline.bold())
                                    .foregroundColor(AppTheme.electricTurquoise)
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                    .smartCard()

                    // Charging Stop Planning Reminder Button
                    Button {
                        Task {
                            _ = try? await SmartChargeNotificationService.shared.scheduleChargingStopReminder(
                                stationName: station.name,
                                stopIndex: 0,
                                reminderDate: Date().addingTimeInterval(1800)
                            )
                            isReminderScheduled = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: isReminderScheduled ? "checkmark.circle.fill" : "bell.badge.fill")
                            Text(isReminderScheduled ? "Reminder Scheduled (In 30m)" : "Schedule Stop Review Reminder")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isReminderScheduled ? AppTheme.safeGreen.opacity(0.2) : AppTheme.electricTurquoise.opacity(0.15))
                        .foregroundColor(isReminderScheduled ? AppTheme.safeGreen : AppTheme.electricTurquoise)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Data Freshness & Transparency Disclosures
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Data Source & Freshness Disclosures", systemImage: "info.circle")
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.adaptiveTextSecondary)
                        Text("Data Source: \(station.dataSource)")
                            .font(.caption2)
                            .foregroundColor(AppTheme.adaptiveTextSecondary)
                        if let freshness = station.dataFreshnessDate {
                            Text("Last Updated: \(freshness.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                                .foregroundColor(AppTheme.adaptiveTextSecondary)
                        } else {
                            Text("Last Updated: Freshness timestamp unavailable")
                                .font(.caption2)
                                .foregroundColor(AppTheme.adaptiveTextSecondary)
                        }
                        Text("Note: Charger availability is simulated for demonstration. MapKit routes are authentic driving distances.")
                            .font(.caption2.italic())
                            .foregroundColor(AppTheme.warningAmber)
                    }
                    .padding(.horizontal, 8)
                }
                .padding()
            }
            .background(AppTheme.adaptiveBackground.ignoresSafeArea())
            .navigationTitle("Station Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
