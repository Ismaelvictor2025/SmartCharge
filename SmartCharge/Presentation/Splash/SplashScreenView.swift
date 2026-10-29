//
//  SplashScreenView.swift
//  SmartCharge
//
//  Created by Vicky Neves Rohr on 21/10/2026.
//

import SwiftUI

public struct SplashScreenView: View {
    @Binding public var isShowing: Bool

    @State private var emblemScale: CGFloat = 0.65
    @State private var emblemOpacity: Double = 0.0
    @State private var titleOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 18
    @State private var progress: CGFloat = 0.0
    @State private var pulseScale: CGFloat = 0.9
    @State private var pulseOpacity: Double = 0.6
    @State private var statusText: String = "INITIALISING ECOSYSTEM..."

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
        ProcessInfo.processInfo.arguments.contains("-uitesting") ||
        NSClassFromString("XCTestCase") != nil
    }

    public init(isShowing: Binding<Bool>) {
        self._isShowing = isShowing
    }

    public var body: some View {
        ZStack {
            // Ambient Electric Ocean Deep Background
            backgroundLayer

            VStack(spacing: 28) {
                Spacer()

                // Animated Glowing Emblem
                emblemView

                // Typography: Title & Tagline
                brandingView

                Spacer()

                // Bottom Energy Progress & Status
                footerStatusView
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, 32)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismissSplash()
        }
        .onAppear {
            startAnimationSequence()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("SmartCharge Splash Screen. Tap anywhere to skip.")
    }

    // MARK: - Subviews

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.midnight,
                    AppTheme.deepNavy,
                    AppTheme.midnight
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle electric turquoise central glow aura
            RadialGradient(
                colors: [
                    AppTheme.electricTurquoise.opacity(0.18),
                    AppTheme.iceCyan.opacity(0.06),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 240
            )
            .ignoresSafeArea()

            // Decorative background circuit dots / faint stars
            GeometryReader { proxy in
                Path { path in
                    let step: CGFloat = 40
                    for x in stride(from: 20, to: proxy.size.width, by: step) {
                        for y in stride(from: 40, to: proxy.size.height, by: step) {
                            path.addEllipse(in: CGRect(x: x, y: y, width: 1.5, height: 1.5))
                        }
                    }
                }
                .fill(AppTheme.iceCyan.opacity(0.08))
            }
            .ignoresSafeArea()
        }
    }

    private var emblemView: some View {
        ZStack {
            // Concentric Expanding Energy Ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            AppTheme.electricTurquoise.opacity(pulseOpacity),
                            AppTheme.iceCyan.opacity(pulseOpacity * 0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 140, height: 140)
                .scaleEffect(pulseScale)

            // Outer Dashed Accent Ring
            Circle()
                .stroke(
                    AppTheme.electricBlue.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 6])
                )
                .frame(width: 116, height: 116)

            // Center Glowing Core Shield / Disc
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.elevatedNavy,
                            AppTheme.deepNavy
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 96)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppTheme.iceCyan,
                                    AppTheme.electricTurquoise
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                )
                .shadow(color: AppTheme.electricTurquoise.opacity(0.45), radius: 18, x: 0, y: 0)

            // Lightning Car/Bolt Glyph
            Image(systemName: "bolt.car.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            AppTheme.iceCyan,
                            AppTheme.electricTurquoise
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: AppTheme.iceCyan.opacity(0.8), radius: 8, x: 0, y: 0)
        }
        .scaleEffect(emblemScale)
        .opacity(emblemOpacity)
    }

    private var brandingView: some View {
        VStack(spacing: 8) {
            Text("SmartCharge")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundColor(.white)
                .shadow(color: AppTheme.iceCyan.opacity(0.6), radius: 10, x: 0, y: 0)

            Text("PLAN SMARTER • CHARGE SAFER")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .tracking(2.2)
                .foregroundColor(AppTheme.slateText)
        }
        .offset(y: titleOffset)
        .opacity(titleOpacity)
    }

    private var footerStatusView: some View {
        VStack(spacing: 12) {
            // Sleek Capsule Progress Bar
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.elevatedNavy.opacity(0.8))
                    .frame(width: 180, height: 4)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.electricBlue,
                                AppTheme.electricTurquoise,
                                AppTheme.iceCyan
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 180 * progress, height: 4)
                    .shadow(color: AppTheme.electricTurquoise.opacity(0.7), radius: 6, x: 0, y: 0)
            }

            // System Readiness Status
            HStack(spacing: 6) {
                Circle()
                    .fill(progress >= 1.0 ? AppTheme.safeGreen : AppTheme.electricTurquoise)
                    .frame(width: 6, height: 6)
                    .shadow(color: (progress >= 1.0 ? AppTheme.safeGreen : AppTheme.electricTurquoise).opacity(0.8), radius: 4)

                Text(statusText)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(1.4)
                    .foregroundColor(AppTheme.slateText)
            }
        }
        .opacity(titleOpacity)
    }

    // MARK: - Animation Logic

    private func startAnimationSequence() {
        if reduceMotion {
            // Immediate presentation for reduced motion preference
            emblemScale = 1.0
            emblemOpacity = 1.0
            titleOffset = 0
            titleOpacity = 1.0
            progress = 1.0
            statusText = "SYSTEMS OPTIMAL"

            let delay: Double = isRunningTests ? 0.3 : 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                dismissSplash()
            }
            return
        }

        // Phase 1: Emblem Spring In
        withAnimation(.spring(response: 0.6, dampingFraction: 0.72, blendDuration: 0)) {
            emblemScale = 1.0
            emblemOpacity = 1.0
        }

        // Continuous soft energy pulse ring
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.22
            pulseOpacity = 0.15
        }

        // Phase 2: Title & Tagline Slide Up
        withAnimation(.easeOut(duration: 0.55).delay(0.2)) {
            titleOffset = 0
            titleOpacity = 1.0
        }

        // Phase 3: Energy Bar Progress Filling
        let fillDuration: Double = isRunningTests ? 0.35 : 1.0
        withAnimation(.easeInOut(duration: fillDuration).delay(0.25)) {
            progress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (isRunningTests ? 0.3 : 0.75)) {
            statusText = "SYSTEMS OPTIMAL"
        }

        // Phase 4: Smooth Auto-Dismiss into Main App
        let dismissDelay: Double = isRunningTests ? 0.55 : 1.6
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
            dismissSplash()
        }
    }

    private func dismissSplash() {
        guard isShowing else { return }
        withAnimation(.easeInOut(duration: 0.45)) {
            isShowing = false
        }
    }
}

#Preview {
    SplashScreenView(isShowing: .constant(true))
}
