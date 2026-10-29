//
//  AppTheme.swift
//  SmartCharge
//

import SwiftUI

public enum AppTheme {
    // Brand Palette Hex Definitions
    public static let midnightHex = "#080F20"
    public static let deepNavyHex = "#0E1B33"
    public static let elevatedNavyHex = "#142546"
    public static let electricTurquoiseHex = "#15D9D2"
    public static let electricBlueHex = "#125BCE"
    public static let iceCyanHex = "#85F4FF"
    public static let safeGreenHex = "#22C55E"
    public static let warningAmberHex = "#F59E0B"
    public static let criticalRedHex = "#EF4444"
    public static let slateTextHex = "#94A3B8"

    // Semantic Colors with Adaptive Dark / Light Mode Support
    public static var background: Color {
        Color("AppBackground", bundle: nil)
    }

    public static var cardBackground: Color {
        Color("CardBackground", bundle: nil)
    }

    public static var elevatedCardBackground: Color {
        Color("ElevatedCardBackground", bundle: nil)
    }

    // Direct color helpers
    public static let electricTurquoise = Color(hex: electricTurquoiseHex)
    public static let electricBlue = Color(hex: electricBlueHex)
    public static let iceCyan = Color(hex: iceCyanHex)
    public static let safeGreen = Color(hex: safeGreenHex)
    public static let warningAmber = Color(hex: warningAmberHex)
    public static let criticalRed = Color(hex: criticalRedHex)
    public static let slateText = Color(hex: slateTextHex)
    public static let midnight = Color(hex: midnightHex)
    public static let deepNavy = Color(hex: deepNavyHex)
    public static let elevatedNavy = Color(hex: elevatedNavyHex)
}

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    public static func adaptive(dark: Color, light: Color) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        return dark
        #endif
    }
}

// Adaptive dynamic colors
extension AppTheme {
    public static var adaptiveBackground: Color {
        Color.adaptive(
            dark: Color(hex: midnightHex),
            light: Color(hex: "#F8FAFC")
        )
    }

    public static var adaptiveCard: Color {
        Color.adaptive(
            dark: Color(hex: deepNavyHex),
            light: Color.white
        )
    }

    public static var adaptiveCardBorder: Color {
        Color.adaptive(
            dark: Color(hex: elevatedNavyHex),
            light: Color(hex: "#E2E8F0")
        )
    }

    public static var adaptiveTextPrimary: Color {
        Color.adaptive(
            dark: .white,
            light: Color(hex: "#0F172A")
        )
    }

    public static var adaptiveTextSecondary: Color {
        Color.adaptive(
            dark: Color(hex: slateTextHex),
            light: Color(hex: "#64748B")
        )
    }
}

// View Modifiers
public struct SmartCardModifier: ViewModifier {
    public var cornerRadius: CGFloat = 16

    public func body(content: Content) -> some View {
        content
            .padding()
            .background(AppTheme.adaptiveCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.adaptiveCardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

extension View {
    public func smartCard(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(SmartCardModifier(cornerRadius: cornerRadius))
    }
}
