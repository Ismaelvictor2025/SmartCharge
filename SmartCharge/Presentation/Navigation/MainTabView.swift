//
//  MainTabView.swift
//  SmartCharge
//

import SwiftUI

public struct MainTabView: View {
    @Binding var selectedTab: Int

    public init(selectedTab: Binding<Int> = .constant(0)) {
        self._selectedTab = selectedTab
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.needle.fill")
                }
                .tag(0)

            JourneyPlannerView()
                .tabItem {
                    Label("Planner", systemImage: "point.topleft.down.to.point.bottomright.curvepath.fill")
                }
                .tag(1)

            StationFinderView()
                .tabItem {
                    Label("Stations", systemImage: "bolt.car.fill")
                }
                .tag(2)

            RecommendationsView()
                .tabItem {
                    Label("Recommend", systemImage: "sparkles")
                }
                .tag(3)

            RouteAnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.xaxis")
                }
                .tag(4)
        }
        .tint(AppTheme.electricTurquoise)
    }
}
