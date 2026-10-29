//
//  Persistence.swift
//  SmartCharge
//
//  Created by Vicky Neves Rohr on 20/10/2026.
//

import CoreData

public struct PersistenceController {
    public static let shared = PersistenceController()

    @MainActor
    public static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        let sampleVehicle = VehicleEntity(context: viewContext)
        sampleVehicle.id = UUID()
        sampleVehicle.name = "Long Range Polestar"
        sampleVehicle.make = "Polestar"
        sampleVehicle.model = "2 Long Range Dual Motor"
        sampleVehicle.theoreticalRangeKm = 500.0
        sampleVehicle.batteryCapacityKWh = 78.0
        sampleVehicle.supportedConnectorsRaw = "CCS2,Type2"
        sampleVehicle.isDefault = true
        sampleVehicle.createdAt = Date()

        let sampleJourney = SavedJourneyEntity(context: viewContext)
        sampleJourney.id = UUID()
        sampleJourney.originName = "Sydney CBD"
        sampleJourney.destinationName = "Canberra Civic"
        sampleJourney.totalDistanceKm = 286.0
        sampleJourney.initialBatteryPercent = 0.85
        sampleJourney.safetyReservePercent = 0.15
        sampleJourney.routePreference = "Safest"
        sampleJourney.riskLevel = "LOW"
        sampleJourney.createdAt = Date()
        sampleJourney.vehicle = sampleVehicle

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            assertionFailure("Failed to seed preview context: \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    public let container: NSPersistentContainer

    public init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SmartCharge")
        if inMemory {
            if let firstDescription = container.persistentStoreDescriptions.first {
                firstDescription.url = URL(fileURLWithPath: "/dev/null")
            }
        }
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                // In production, handle failure defensively without crashing where possible
                NSLog("Unresolved Core Data error: \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
