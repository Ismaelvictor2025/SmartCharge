//
//  MetricCardView.swift
//  SmartCharge
//

import SwiftUI

public struct MetricCardView: View {
    public let title: String
    public let value: String
    public let subtitle: String?
    public let systemImage: String
    public let tintColor: Color

    public init(
        title: String,
        value: String,
        subtitle: String? = nil,
        systemImage: String,
        tintColor: Color = AppTheme.electricTurquoise
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tintColor = tintColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(tintColor)
                    .font(.subheadline)
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppTheme.adaptiveTextSecondary)
                Spacer()
            }

            Text(value)
                .font(.system(.title3, design: .rounded).bold())
                .foregroundColor(AppTheme.adaptiveTextPrimary)

            if let sub = subtitle {
                Text(sub)
                    .font(.caption2)
                    .foregroundColor(AppTheme.adaptiveTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .smartCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)\(subtitle != nil ? ", \(subtitle!)" : "")")
    }
}
