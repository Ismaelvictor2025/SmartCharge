//
//  SettingsSheetView.swift
//  SmartCharge
//
//  Created by Vicky Neves Rohr on 29/10/2026.
//

import SwiftUI
import UserNotifications

public struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var journey: JourneyViewModel
    @StateObject private var notificationService = SmartChargeNotificationService.shared

    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? "Vicky"
    @State private var testScheduledMessage: String? = nil
    @State private var isSchedulingTest: Bool = false
    @State private var showResetAlert: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Notifications & Alerts Section
                    notificationsSection

                    // MARK: - Safety Reserves & Driver Profile
                    driverProfileSection

                    // MARK: - WidgetKit Home Screen Widgets Preview
                    widgetPreviewSection

                    // MARK: - System, Architecture & Transparency
                    systemArchitectureSection

                    // MARK: - Data Management
                    dataManagementSection
                }
                .padding()
            }
            .background(AppTheme.adaptiveBackground.ignoresSafeArea())
            .navigationTitle("Settings & Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.electricTurquoise)
                    .bold()
                }
            }
            .task {
                await notificationService.checkAuthorizationStatus()
            }
        }
    }

    // MARK: - Notifications & Alerts Section
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Notifications & Trip Alerts", systemImage: "bell.badge.fill")
                .font(.headline)
                .foregroundColor(AppTheme.electricTurquoise)

            // Permission Status Handling
            switch notificationService.authorizationStatus {
            case .notDetermined:
                permissionExplainerCard
            case .denied:
                permissionDeniedCard
            case .authorized, .provisional, .ephemeral:
                permissionActiveCard
            @unknown default:
                EmptyView()
            }

            Divider()

            // Reminder Toggles
            VStack(spacing: 12) {
                Toggle(isOn: $notificationService.preferences.departureReminderEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Journey Departure Reminder")
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.adaptiveTextPrimary)
                        Text("Alert before planned trip to review range and stops")
                            .font(.caption)
                            .foregroundColor(AppTheme.adaptiveTextSecondary)
                    }
                }
                .tint(AppTheme.electricTurquoise)

                if notificationService.preferences.departureReminderEnabled {
                    HStack {
                        Text("Remind me before departure:")
                            .font(.caption)
                            .foregroundColor(AppTheme.adaptiveTextSecondary)
                        Spacer()
                        Picker("Reminder Interval", selection: $notificationService.preferences.departureReminderMinutesBefore) {
                            Text("15 mins").tag(15)
                            Text("30 mins").tag(30)
                            Text("1 hour").tag(60)
                            Text("2 hours").tag(120)
                        }
                        .pickerStyle(.menu)
                        .tint(AppTheme.electricTurquoise)
                    }
                    .padding(.leading, 8)
                }

                Toggle(isOn: $notificationService.preferences.batteryWarningEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Battery Planning Warning")
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.adaptiveTextPrimary)
                        Text("Alert if trip distance exceeds safe planning range")
                            .font(.caption)
                            .foregroundColor(AppTheme.adaptiveTextSecondary)
                    }
                }
                .tint(AppTheme.electricTurquoise)

                Toggle(isOn: $notificationService.preferences.criticalRiskAlertEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Critical Route Risk Alerts")
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.adaptiveTextPrimary)
                        Text("Warn when charging gaps exceed physical range")
                            .font(.caption)
                            .foregroundColor(AppTheme.adaptiveTextSecondary)
                    }
                }
                .tint(AppTheme.electricTurquoise)

                Toggle(isOn: $notificationService.preferences.chargingStopReminderEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Charging Stop Reminders")
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.adaptiveTextPrimary)
                        Text("Reminders to verify plug type and stall power")
                            .font(.caption)
                            .foregroundColor(AppTheme.adaptiveTextSecondary)
                    }
                }
                .tint(AppTheme.electricTurquoise)
            }

            Divider()

            // In-App Test Feature: Test Notification — 5 Seconds
            VStack(alignment: .leading, spacing: 8) {
                Text("Verification & Simulator Testing")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.electricBlue)

                Button {
                    scheduleTestNotification()
                } label: {
                    HStack {
                        Image(systemName: "timer")
                        Text("Test Notification — 5 Seconds")
                            .bold()
                        Spacer()
                        if isSchedulingTest {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                        }
                    }
                    .padding()
                    .background(AppTheme.elevatedNavy.opacity(0.35))
                    .foregroundColor(AppTheme.iceCyan)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isSchedulingTest)
                .accessibilityLabel("Schedule test notification in 5 seconds")

                if let msg = testScheduledMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.safeGreen)
                        Text(msg)
                            .font(.caption)
                            .foregroundColor(AppTheme.safeGreen)
                    }
                    .transition(.opacity)
                }
            }
        }
        .smartCard()
    }

    private var permissionExplainerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(AppTheme.electricTurquoise)
                Text("Notification Permission Needed")
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.adaptiveTextPrimary)
            }
            Text("SmartCharge delivers essential planning notifications before departure, including battery margin alerts and charging reminders.")
                .font(.caption)
                .foregroundColor(AppTheme.adaptiveTextSecondary)

            Button {
                Task {
                    _ = try? await notificationService.requestAuthorization()
                }
            } label: {
                Text("Enable Smart Notifications")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppTheme.electricTurquoise)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(10)
        .background(AppTheme.electricTurquoise.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var permissionDeniedCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.warningAmber)
                Text("Notifications Disabled in iOS Settings")
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.warningAmber)
            }
            Text("To receive departure reminders and battery warnings, enable notifications in iOS Settings.")
                .font(.caption)
                .foregroundColor(AppTheme.adaptiveTextPrimary)

            Button {
                notificationService.openSettingsURL()
            } label: {
                Text("Open iOS Settings")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppTheme.warningAmber)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(10)
        .background(AppTheme.warningAmber.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var permissionActiveCard: some View {
        HStack {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(AppTheme.safeGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text("Notifications Authorised")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.safeGreen)
                Text("Foreground & background delivery enabled")
                    .font(.caption2)
                    .foregroundColor(AppTheme.adaptiveTextSecondary)
            }
            Spacer()
        }
        .padding(8)
        .background(AppTheme.safeGreen.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Driver Profile Section
    private var driverProfileSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Driver Profile & Reserve Buffer", systemImage: "person.crop.circle.fill")
                .font(.headline)
                .foregroundColor(AppTheme.electricBlue)

            VStack(alignment: .leading, spacing: 6) {
                Text("Driver Name")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.adaptiveTextSecondary)
                TextField("Enter your name", text: $userName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: userName) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "userName")
                    }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Default Safety Reserve")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.adaptiveTextPrimary)
                    Spacer()
                    Text("\(Int(journey.safetyReservePercentage * 100))%")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.warningAmber)
                }
                Text("Buffer retained to protect against headwinds, detour needs, and cold temperatures.")
                    .font(.caption2)
                    .foregroundColor(AppTheme.adaptiveTextSecondary)

                Picker("Safety Reserve", selection: $journey.safetyReservePercentage) {
                    Text("10% Buffer").tag(0.10)
                    Text("15% Standard").tag(0.15)
                    Text("20% Cautious").tag(0.20)
                    Text("25% Maximum").tag(0.25)
                }
                .pickerStyle(.segmented)
            }
        }
        .smartCard()
    }

    // MARK: - WidgetKit Preview Section
    private var widgetPreviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("WidgetKit Home Screen Widgets", systemImage: "square.grid.2x2.fill")
                .font(.headline)
                .foregroundColor(AppTheme.electricTurquoise)

            Text("SmartCharge synchronises your live battery state and safe planning range to Home Screen widgets via App Groups.")
                .font(.caption)
                .foregroundColor(AppTheme.adaptiveTextSecondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Medium Widget Preview (348 × 157 pt)")
                    .font(.caption2.bold())
                    .foregroundColor(AppTheme.slateText)

                SmartChargeMediumWidgetView(snapshot: WidgetSnapshotStore.shared.loadSnapshot())
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(AppTheme.elevatedNavy.opacity(0.4), lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Small Widget Preview (158 × 158 pt)")
                    .font(.caption2.bold())
                    .foregroundColor(AppTheme.slateText)

                HStack {
                    SmartChargeSmallWidgetView(snapshot: WidgetSnapshotStore.shared.loadSnapshot())
                        .frame(width: 158, height: 158)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(AppTheme.elevatedNavy.opacity(0.4), lineWidth: 1)
                        )
                    Spacer()
                }
            }
        }
        .smartCard()
    }

    // MARK: - System & Architecture Section
    private var systemArchitectureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("System Architecture & Data", systemImage: "cpu.fill")
                .font(.headline)
                .foregroundColor(AppTheme.iceCyan)

            VStack(spacing: 8) {
                systemInfoRow(title: "Architecture", value: "Clean Architecture + MVVM")
                systemInfoRow(title: "Persistence", value: "Core Data (Encrypted SQLite)")
                systemInfoRow(title: "Routing Engine", value: "Apple MapKit (MKDirections)")
                systemInfoRow(title: "Visual Analytics", value: "Apple Swift Charts")
                systemInfoRow(title: "Notification System", value: "UserNotifications (Local)")
                systemInfoRow(title: "System Extension", value: "WidgetKit & App Groups")
                systemInfoRow(title: "Build Target", value: "iOS 17.0+ (Swift 6 Safe)")
            }

            Divider()

            HStack {
                Text("Data Disclosure:")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.adaptiveTextSecondary)
                Text("Station availability is simulated. MapKit routes are authentic driving distances.")
                    .font(.caption2)
                    .foregroundColor(AppTheme.slateText)
            }
        }
        .smartCard()
    }

    private func systemInfoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.adaptiveTextSecondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundColor(AppTheme.adaptiveTextPrimary)
        }
    }

    // MARK: - Data Management Section
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Clear Pending Notification Requests")
                    Spacer()
                }
                .font(.footnote.bold())
                .foregroundColor(AppTheme.criticalRed)
            }
        }
        .smartCard()
        .alert("Clear Notifications?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                Task {
                    await notificationService.cancelAllPendingNotifications()
                    testScheduledMessage = "All pending notifications cleared."
                }
            }
        } message: {
            Text("This will remove any scheduled departure reminders and test notifications.")
        }
    }

    // MARK: - Test Notification Trigger
    private func scheduleTestNotification() {
        isSchedulingTest = true
        testScheduledMessage = nil

        Task {
            // Ensure permission requested
            if notificationService.authorizationStatus == .notDetermined {
                _ = try? await notificationService.requestAuthorization()
            }

            do {
                _ = try await notificationService.scheduleTestNotification(afterSeconds: 5.0)
                await MainActor.run {
                    self.isSchedulingTest = false
                    self.testScheduledMessage = "Test alert scheduled in 5 seconds! Keep app open or lock screen."
                }
            } catch {
                await MainActor.run {
                    self.isSchedulingTest = false
                    self.testScheduledMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
