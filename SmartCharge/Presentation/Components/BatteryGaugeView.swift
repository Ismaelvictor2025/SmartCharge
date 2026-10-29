//
//  BatteryGaugeView.swift
//  SmartCharge
//

import SwiftUI

public struct BatteryGaugeView: View {
    public let batteryPercentage: Double // 0.0 to 1.0
    public let safetyReservePercentage: Double // 0.0 to 1.0
    public let currentRangeKm: Double
    public let safeRangeKm: Double

    public init(
        batteryPercentage: Double,
        safetyReservePercentage: Double = 0.15,
        currentRangeKm: Double,
        safeRangeKm: Double
    ) {
        self.batteryPercentage = batteryPercentage
        self.safetyReservePercentage = safetyReservePercentage
        self.currentRangeKm = currentRangeKm
        self.safeRangeKm = safeRangeKm
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Battery Status", systemImage: batteryIconName)
                    .font(.headline)
                    .foregroundColor(AppTheme.adaptiveTextPrimary)

                Spacer()

                Text("\(Int(batteryPercentage * 100))%")
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundColor(batteryColor)
            }

            // Visual bar indicating safe planning vs reserve
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Empty background
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.elevatedNavy.opacity(0.35))

                    // Safe planning range fill
                    let totalWidth = geo.size.width * CGFloat(batteryPercentage)
                    let reserveWidth = totalWidth * CGFloat(safetyReservePercentage)
                    let safeWidth = max(0, totalWidth - reserveWidth)

                    HStack(spacing: 0) {
                        // Safe range portion
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.electricTurquoise, AppTheme.electricBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: safeWidth)

                        // Reserve buffer portion
                        Rectangle()
                            .fill(AppTheme.warningAmber)
                            .frame(width: reserveWidth)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .frame(height: 18)

            // Legend and metrics
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.electricTurquoise)
                        .frame(width: 8, height: 8)
                    Text("Safe: \(Int(safeRangeKm)) km")
                        .font(.caption)
                        .foregroundColor(AppTheme.adaptiveTextSecondary)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.warningAmber)
                        .frame(width: 8, height: 8)
                    Text("Reserve: \(Int(safetyReservePercentage * 100))%")
                        .font(.caption)
                        .foregroundColor(AppTheme.adaptiveTextSecondary)
                }

                Spacer()

                Text("Est. Total: \(Int(currentRangeKm)) km")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.adaptiveTextPrimary)
            }
        }
        .smartCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Battery Gauge: \(Int(batteryPercentage * 100)) percent. Estimated physical range \(Int(currentRangeKm)) kilometres. Safe planning range \(Int(safeRangeKm)) kilometres with \(Int(safetyReservePercentage * 100)) percent reserve.")
    }

    private var batteryIconName: String {
        if batteryPercentage >= 0.75 {
            return "battery.100"
        } else if batteryPercentage >= 0.50 {
            return "battery.75"
        } else if batteryPercentage >= 0.25 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }

    private var batteryColor: Color {
        if batteryPercentage > 0.40 {
            return AppTheme.electricTurquoise
        } else if batteryPercentage > 0.20 {
            return AppTheme.warningAmber
        } else {
            return AppTheme.criticalRed
        }
    }
}
