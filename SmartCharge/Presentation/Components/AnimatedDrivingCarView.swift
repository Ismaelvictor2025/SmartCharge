//
//  AnimatedDrivingCarView.swift
//  SmartCharge
//

import SwiftUI

public enum DrivingAnimationState: String, CaseIterable, Sendable {
    case driving
    case idle
    case reducedMotion

    public var title: String {
        switch self {
        case .driving: return "Driving"
        case .idle: return "Idle"
        case .reducedMotion: return "Static"
        }
    }
}

public struct AnimatedDrivingCarView: View {
    public var isDriving: Bool
    public var showToggle: Bool

    @State private var isAnimating: Bool = false
    @State private var roadOffset: CGFloat = 0.0
    @State private var suspensionY: CGFloat = 0.0
    @State private var wheelAngle: Double = 0.0
    @State private var energyPulse: CGFloat = 0.35

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    public init(isDriving: Bool = true, showToggle: Bool = false) {
        self.isDriving = isDriving
        self.showToggle = showToggle
    }

    private var currentState: DrivingAnimationState {
        if reduceMotion {
            return .reducedMotion
        } else if isDriving && isAnimating && scenePhase == .active {
            return .driving
        } else {
            return .idle
        }
    }

    public var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                // Background road layer
                roadLayer
                    .frame(height: 14)
                    .offset(y: 4)

                // Energy aura under battery pack
                if currentState == .driving {
                    batteryUnderglow
                }

                // Car body & suspension
                carBodyWithWheels
                    .offset(y: currentState == .driving ? suspensionY : 0)
            }
            .frame(width: 124, height: 56)
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture {
                if showToggle || isDriving {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isAnimating.toggle()
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Active Electric Vehicle: \(currentState.title). Tap to \(isAnimating ? "pause" : "resume") driving animation.")
            .accessibilityAddTraits(.isButton)

            if showToggle {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isAnimating.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isAnimating ? "pause.fill" : "play.fill")
                            .font(.system(size: 9))
                        Text(isAnimating ? "Driving" : "Paused")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.iceCyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.elevatedNavy.opacity(0.4))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            if isDriving && !reduceMotion {
                isAnimating = true
                startContinuousAnimations()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && isDriving && !reduceMotion {
                startContinuousAnimations()
            }
        }
    }

    // MARK: - Car Body & Wheels
    private var carBodyWithWheels: some View {
        ZStack {
            // Forward Headlight Beam
            if currentState == .driving {
                headlightBeam
            }

            // Chassis silhouette
            EVSilhouetteShape()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.electricTurquoise,
                            AppTheme.electricBlue
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 86, height: 32)
                .overlay(
                    // Window glass
                    EVWindowsShape()
                        .fill(AppTheme.midnight.opacity(0.85))
                        .overlay(
                            EVWindowsShape()
                                .stroke(AppTheme.iceCyan.opacity(0.5), lineWidth: 0.5)
                        )
                )
                .overlay(
                    // LED Headlight strip (front is pointing Right)
                    Circle()
                        .fill(AppTheme.iceCyan)
                        .frame(width: 3.5, height: 3.5)
                        .blur(radius: 0.6)
                        .offset(x: 41, y: 3),
                    alignment: .center
                )
                .overlay(
                    // Rear Taillight strip (back is pointing Left)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(AppTheme.criticalRed)
                        .frame(width: 2.5, height: 7)
                        .offset(x: -41.5, y: -2),
                    alignment: .center
                )
                .shadow(color: AppTheme.electricTurquoise.opacity(0.3), radius: 4, x: 0, y: 2)

            // Front & Rear Wheels
            HStack(spacing: 36) {
                // Rear wheel
                WheelView(isSpinning: currentState == .driving, angle: wheelAngle)
                // Front wheel
                WheelView(isSpinning: currentState == .driving, angle: wheelAngle)
            }
            .offset(y: 12)
        }
    }

    // MARK: - Headlight Beam
    private var headlightBeam: some View {
        PolygonShape(points: [
            CGPoint(x: 42, y: 3),
            CGPoint(x: 80, y: -4),
            CGPoint(x: 80, y: 14),
            CGPoint(x: 42, y: 7)
        ])
        .fill(
            LinearGradient(
                colors: [
                    AppTheme.iceCyan.opacity(0.4),
                    AppTheme.iceCyan.opacity(0.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .blur(radius: 2)
    }

    // MARK: - Battery Pack Underglow
    private var batteryUnderglow: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                RadialGradient(
                    colors: [
                        AppTheme.electricTurquoise.opacity(energyPulse),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 2,
                    endRadius: 28
                )
            )
            .frame(width: 74, height: 12)
            .offset(y: 8)
    }

    // MARK: - Moving Road Layer
    private var roadLayer: some View {
        ZStack(alignment: .center) {
            // Dark asphalt road bed
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.deepNavy,
                            AppTheme.elevatedNavy.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Moving dashed center markings traveling backwards (Right to Left)
            GeometryReader { geo in
                let dashWidth: CGFloat = 10
                let dashGap: CGFloat = 8
                let totalPattern = dashWidth + dashGap
                let count = Int(geo.size.width / totalPattern) + 4

                HStack(spacing: dashGap) {
                    ForEach(0..<count, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(AppTheme.iceCyan.opacity(0.45))
                            .frame(width: dashWidth, height: 2)
                    }
                }
                .offset(x: -roadOffset)
            }
            .frame(height: 2)
        }
    }

    // MARK: - Animation Engine
    private func startContinuousAnimations() {
        guard !reduceMotion else { return }

        // 1. Wheel rotation: continuous 360-degree spin
        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
            wheelAngle = 360.0
        }

        // 2. Road dash movement: linear translation matching forward speed
        withAnimation(.linear(duration: 0.6).repeatForever(autoreverses: false)) {
            roadOffset = 18.0
        }

        // 3. Subtle suspension dampening: gentle vertical breathing (1.2pt)
        withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
            suspensionY = -1.2
        }

        // 4. Energy pulse under chassis
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            energyPulse = 0.55
        }
    }
}

// MARK: - Wheel Component with Alloy Spokes
public struct WheelView: View {
    public let isSpinning: Bool
    public let angle: Double

    public var body: some View {
        ZStack {
            // Tire outer rubber
            Circle()
                .fill(Color(hex: "#1E293B"))
                .frame(width: 17, height: 17)

            // Dark rim outer edge
            Circle()
                .stroke(AppTheme.elevatedNavy, lineWidth: 1.5)
                .frame(width: 15, height: 15)

            // Alloy rim face with 4 spokes
            ZStack {
                Rectangle()
                    .fill(AppTheme.iceCyan)
                    .frame(width: 1.5, height: 10)

                Rectangle()
                    .fill(AppTheme.iceCyan)
                    .frame(width: 10, height: 1.5)

                Circle()
                    .fill(AppTheme.electricTurquoise)
                    .frame(width: 4, height: 4)
            }
            .rotationEffect(.degrees(isSpinning ? angle : 0))
        }
        .frame(width: 17, height: 17)
    }
}

// MARK: - Sleek EV Fastback Silhouette
struct EVSilhouetteShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Facing Right
        // Start at rear bumper bottom (left)
        path.move(to: CGPoint(x: w * 0.04, y: h * 0.78))

        // Rear fascia & lightbar
        path.addLine(to: CGPoint(x: w * 0.02, y: h * 0.45))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.12, y: h * 0.35),
            control: CGPoint(x: w * 0.04, y: h * 0.36)
        )

        // Trunk & fastback roofline
        path.addLine(to: CGPoint(x: w * 0.28, y: h * 0.28))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.65, y: h * 0.08),
            control: CGPoint(x: w * 0.42, y: h * 0.06)
        )

        // Windshield slope
        path.addQuadCurve(
            to: CGPoint(x: w * 0.78, y: h * 0.38),
            control: CGPoint(x: w * 0.74, y: h * 0.24)
        )

        // Low EV hood slope
        path.addLine(to: CGPoint(x: w * 0.94, y: h * 0.46))

        // Front nose / aerodynamic bumper
        path.addQuadCurve(
            to: CGPoint(x: w * 0.98, y: h * 0.64),
            control: CGPoint(x: w * 0.99, y: h * 0.52)
        )
        path.addLine(to: CGPoint(x: w * 0.94, y: h * 0.78))

        // Front wheel arch cutaway
        path.addLine(to: CGPoint(x: w * 0.84, y: h * 0.78))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.64, y: h * 0.78),
            control: CGPoint(x: w * 0.74, y: h * 0.52)
        )

        // Underbody battery pack tray
        path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.78))

        // Rear wheel arch cutaway
        path.addQuadCurve(
            to: CGPoint(x: w * 0.18, y: h * 0.78),
            control: CGPoint(x: w * 0.28, y: h * 0.52)
        )

        // Underbody rear diffuser
        path.addLine(to: CGPoint(x: w * 0.04, y: h * 0.78))
        path.closeSubpath()

        return path
    }
}

// MARK: - Dark Glass Window Shape
struct EVWindowsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Rear side window + Front side window profile
        path.move(to: CGPoint(x: w * 0.32, y: h * 0.35))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.64, y: h * 0.18),
            control: CGPoint(x: w * 0.46, y: h * 0.16)
        )
        path.addLine(to: CGPoint(x: w * 0.74, y: h * 0.40))
        path.addLine(to: CGPoint(x: w * 0.32, y: h * 0.40))
        path.closeSubpath()

        return path
    }
}

// MARK: - Arbitrary Polygon Helper Shape
struct PolygonShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for pt in points.dropFirst() {
            path.addLine(to: pt)
        }
        path.closeSubpath()
        return path
    }
}
