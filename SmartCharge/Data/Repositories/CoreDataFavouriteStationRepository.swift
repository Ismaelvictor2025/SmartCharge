//
//  CoreDataFavouriteStationRepository.swift
//  SmartCharge
//

import Foundation
import CoreData
import CoreLocation

public final class CoreDataFavouriteStationRepository: FavouriteStationRepositoryProtocol, @unchecked Sendable {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    public func fetchFavourites() async throws -> [FavouriteStation] {
        try await context.perform {
            let request = NSFetchRequest<FavouriteStationEntity>(entityName: "FavouriteStationEntity")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \FavouriteStationEntity.savedAt, ascending: false)]
            let entities = try self.context.fetch(request)
            return entities.compactMap { self.toDomain($0) }
        }
    }

    public func saveFavourite(_ station: FavouriteStation) async throws {
        try await context.perform {
            let request = NSFetchRequest<FavouriteStationEntity>(entityName: "FavouriteStationEntity")
            request.predicate = NSPredicate(format: "id == %@", station.id as CVarArg)
            let entity = try self.context.fetch(request).first ?? FavouriteStationEntity(context: self.context)

            entity.id = station.id
            entity.name = station.name
            entity.operatorName = station.operatorName
            entity.latitude = station.coordinate.latitude
            entity.longitude = station.coordinate.longitude
            entity.powerKW = station.powerKW
            entity.connectorsRaw = station.supportedConnectors.map(\.rawValue).joined(separator: ",")
            entity.savedAt = station.savedAt

            try self.context.save()
        }
    }

    public func deleteFavourite(id: String) async throws {
        try await context.perform {
            let request = NSFetchRequest<FavouriteStationEntity>(entityName: "FavouriteStationEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let entity = try self.context.fetch(request).first {
                self.context.delete(entity)
                try self.context.save()
            }
        }
    }

    public func isFavourite(id: String) async throws -> Bool {
        try await context.perform {
            let request = NSFetchRequest<FavouriteStationEntity>(entityName: "FavouriteStationEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            return try self.context.count(for: request) > 0
        }
    }

    private func toDomain(_ entity: FavouriteStationEntity) -> FavouriteStation? {
        guard let id = entity.id,
              let name = entity.name else {
            return nil
        }

        let connectors = ConnectorType.parseCommaSeparated(entity.connectorsRaw ?? "CCS2")
        let coord = CLLocationCoordinate2D(latitude: entity.latitude, longitude: entity.longitude)

        return FavouriteStation(
            id: id,
            name: name,
            operatorName: entity.operatorName ?? "Unknown Operator",
            coordinate: coord,
            powerKW: entity.powerKW,
            supportedConnectors: connectors,
            savedAt: entity.savedAt ?? Date()
        )
    }
}
