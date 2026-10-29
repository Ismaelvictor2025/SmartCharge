//
//  ContentView.swift
//  SmartCharge
//
//  Created by Vicky Neves Rohr on 20/10/2026.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var isShowingSplash = true
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
            MainTabView(selectedTab: $selectedTab)

            if isShowingSplash {
                SplashScreenView(isShowing: $isShowingSplash)
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
                    .zIndex(1)
            }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SmartChargeNavigateTab"))) { notif in
            if let tabIndex = notif.object as? Int {
                selectedTab = tabIndex
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "smartcharge" else { return }
        switch url.host?.lowercased() {
        case "dashboard":
            selectedTab = 0
        case "planner":
            selectedTab = 1
        case "stations":
            selectedTab = 2
        case "recommend":
            selectedTab = 3
        case "analytics":
            selectedTab = 4
        default:
            break
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppContainer.preview)
        .environmentObject(AppContainer.preview.journeyViewModel)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
