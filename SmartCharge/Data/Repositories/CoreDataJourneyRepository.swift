//
//  CoreDataJourneyRepository.swift
//  SmartCharge
//

import Foundation
import CoreData

public final class CoreDataJourneyRepository: JourneyRepositoryProtocol, @unchecked Sendable {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    public func fetchSavedJourneys() async throws -> [Journey] {
        try await context.perform {
            let request = NSFetchRequest<SavedJourneyEntity>(entityName: "SavedJourneyEntity")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedJourneyEntity.createdAt, ascending: false)]
            let entities = try self.context.fetch(request)

            return entities.compactMap { self.toDomain($0) }
        }
    }

    public func saveJourney(_ journey: Journey) async throws {
        try await context.perform {
            let request = NSFetchRequest<SavedJourneyEntity>(entityName: "SavedJourneyEntity")
            request.predicate = NSPredicate(format: "id == %@", journey.id as CVarArg)
            let existing = try self.context.fetch(request).first

            let entity = existing ?? SavedJourneyEntity(context: self.context)
            entity.id = journey.id
            entity.originName = journey.originName
            entity.destinationName = journey.destinationName
            entity.totalDistanceKm = journey.totalDistanceKm
            entity.initialBatteryPercent = journey.initialBatteryPercent
            entity.safetyReservePercent = journey.safetyReservePercent
            entity.routePreference = journey.routePreference.rawValue
            entity.riskLevel = journey.riskResult?.overallRiskLevel.rawValue ?? RiskLevel.low.rawValue
            entity.createdAt = journey.createdAt

            // Link vehicle if exists
            let vRequest = NSFetchRequest<VehicleEntity>(entityName: "VehicleEntity")
            vRequest.predicate = NSPredicate(format: "id == %@", journey.vehicle.id as CVarArg)
            if let vEntity = try self.context.fetch(vRequest).first {
                entity.vehicle = vEntity
            }

            try self.context.save()
        }
    }

    public func deleteJourney(id: UUID) async throws {
        try await context.perform {
            let request = NSFetchRequest<SavedJourneyEntity>(entityName: "SavedJourneyEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let entity = try self.context.fetch(request).first {
                self.context.delete(entity)
                try self.context.save()
            }
        }
    }

    private func toDomain(_ entity: SavedJourneyEntity) -> Journey? {
        guard let id = entity.id,
              let origin = entity.originName,
              let dest = entity.destinationName else {
            return nil
        }

        let vehicle: Vehicle
        if let vEntity = entity.vehicle {
            let connectors = ConnectorType.parseCommaSeparated(vEntity.supportedConnectorsRaw ?? "CCS2")
            vehicle = Vehicle(
                id: vEntity.id ?? UUID(),
                name: vEntity.name ?? "Vehicle",
                make: vEntity.make ?? "Unknown",
                model: vEntity.model ?? "Model",
                theoreticalRangeKm: vEntity.theoreticalRangeKm,
                batteryCapacityKWh: vEntity.batteryCapacityKWh,
                supportedConnectors: connectors,
                isDefault: vEntity.isDefault,
                createdAt: vEntity.createdAt ?? Date()
            )
        } else {
            vehicle = MockDataGenerator.sampleVehicles.first!
        }

        let pref = RoutePreference(rawValue: entity.routePreference ?? "Safest") ?? .safest
        let risk = RiskLevel(rawValue: entity.riskLevel ?? "LOW") ?? .low

        return Journey(
            id: id,
            originName: origin,
            destinationName: dest,
            totalDistanceKm: entity.totalDistanceKm,
            vehicle: vehicle,
            initialBatteryPercent: entity.initialBatteryPercent,
            safetyReservePercent: entity.safetyReservePercent,
            routePreference: pref,
            plannedChargingStops: [],
            riskResult: RouteRiskResult(
                overallRiskLevel: risk,
                riskScore: 20.0,
                highRiskSegmentsCount: 0,
                criticalSegmentsCount: 0,
                infrastructureGapsCount: 0,
                warnings: [],
                summary: "Saved journey loaded from local storage."
            ),
            createdAt: entity.createdAt ?? Date()
        )
    }
}
