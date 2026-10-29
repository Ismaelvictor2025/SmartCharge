//
//  CoreDataVehicleRepository.swift
//  SmartCharge
//

import Foundation
import CoreData

public final class CoreDataVehicleRepository: VehicleRepositoryProtocol, @unchecked Sendable {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    public func fetchVehicles() async throws -> [Vehicle] {
        try await context.perform {
            let request = NSFetchRequest<VehicleEntity>(entityName: "VehicleEntity")
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \VehicleEntity.isDefault, ascending: false),
                NSSortDescriptor(keyPath: \VehicleEntity.createdAt, ascending: true)
            ]
            let entities = try self.context.fetch(request)

            // If empty, auto-seed with initial sample vehicles
            if entities.isEmpty {
                for sample in MockDataGenerator.sampleVehicles {
                    let entity = VehicleEntity(context: self.context)
                    entity.id = sample.id
                    entity.name = sample.name
                    entity.make = sample.make
                    entity.model = sample.model
                    entity.theoreticalRangeKm = sample.theoreticalRangeKm
                    entity.batteryCapacityKWh = sample.batteryCapacityKWh
                    entity.supportedConnectorsRaw = sample.supportedConnectors.map(\.rawValue).joined(separator: ",")
                    entity.isDefault = sample.isDefault
                    entity.createdAt = sample.createdAt
                }
                try self.context.save()

                let reloaded = try self.context.fetch(request)
                return reloaded.map { self.toDomain($0) }
            }

            return entities.map { self.toDomain($0) }
        }
    }

    public func fetchDefaultVehicle() async throws -> Vehicle? {
        let vehicles = try await fetchVehicles()
        return vehicles.first(where: { $0.isDefault }) ?? vehicles.first
    }

    public func saveVehicle(_ vehicle: Vehicle) async throws {
        try await context.perform {
            let request = NSFetchRequest<VehicleEntity>(entityName: "VehicleEntity")
            request.predicate = NSPredicate(format: "id == %@", vehicle.id as CVarArg)
            let existing = try self.context.fetch(request).first

            let entity = existing ?? VehicleEntity(context: self.context)
            entity.id = vehicle.id
            entity.name = vehicle.name
            entity.make = vehicle.make
            entity.model = vehicle.model
            entity.theoreticalRangeKm = vehicle.theoreticalRangeKm
            entity.batteryCapacityKWh = vehicle.batteryCapacityKWh
            entity.supportedConnectorsRaw = vehicle.supportedConnectors.map(\.rawValue).joined(separator: ",")
            entity.isDefault = vehicle.isDefault
            entity.createdAt = vehicle.createdAt

            if vehicle.isDefault {
                // Remove default flag from all other vehicles
                let allRequest = NSFetchRequest<VehicleEntity>(entityName: "VehicleEntity")
                allRequest.predicate = NSPredicate(format: "id != %@", vehicle.id as CVarArg)
                let others = try self.context.fetch(allRequest)
                for other in others {
                    other.isDefault = false
                }
            }

            try self.context.save()
        }
    }

    public func deleteVehicle(id: UUID) async throws {
        try await context.perform {
            let request = NSFetchRequest<VehicleEntity>(entityName: "VehicleEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let entity = try self.context.fetch(request).first {
                self.context.delete(entity)
                try self.context.save()
            }
        }
    }

    public func setDefaultVehicle(id: UUID) async throws {
        try await context.perform {
            let request = NSFetchRequest<VehicleEntity>(entityName: "VehicleEntity")
            let all = try self.context.fetch(request)
            for entity in all {
                entity.isDefault = (entity.id == id)
            }
            try self.context.save()
        }
    }

    private func toDomain(_ entity: VehicleEntity) -> Vehicle {
        let rawConnectors = entity.supportedConnectorsRaw ?? "CCS2"
        let connectors = ConnectorType.parseCommaSeparated(rawConnectors)

        return Vehicle(
            id: entity.id ?? UUID(),
            name: entity.name ?? "Vehicle",
            make: entity.make ?? "Unknown",
            model: entity.model ?? "Model",
            theoreticalRangeKm: entity.theoreticalRangeKm,
            batteryCapacityKWh: entity.batteryCapacityKWh,
            supportedConnectors: connectors,
            isDefault: entity.isDefault,
            createdAt: entity.createdAt ?? Date()
        )
    }
}
