//
//  RiskBadgeView.swift
//  SmartCharge
//

import SwiftUI

public struct RiskBadgeView: View {
    public let riskLevel: RiskLevel

    public init(riskLevel: RiskLevel) {
        self.riskLevel = riskLevel
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.caption.bold())
            Text(riskLevel.title)
                .font(.caption.bold())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .foregroundColor(badgeForegroundColor)
        .background(badgeBackgroundColor)
        .clipShape(Capsule())
        .accessibilityLabel("Route risk level: \(riskLevel.title)")
    }

    private var iconName: String {
        switch riskLevel {
        case .low: return "checkmark.shield.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }

    private var badgeForegroundColor: Color {
        switch riskLevel {
        case .low: return AppTheme.safeGreen
        case .medium: return AppTheme.warningAmber
        case .high: return Color.orange
        case .critical: return AppTheme.criticalRed
        }
    }

    private var badgeBackgroundColor: Color {
        badgeForegroundColor.opacity(0.18)
    }
}
