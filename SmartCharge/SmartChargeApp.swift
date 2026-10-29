//
//  SmartChargeApp.swift
//  SmartCharge
//
//  Created by Vicky Neves Rohr on 20/10/2026.
//

import SwiftUI
import CoreData

@main
struct SmartChargeApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var container = AppContainer.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(container)
                .environmentObject(container.journeyViewModel)
        }
    }
}
