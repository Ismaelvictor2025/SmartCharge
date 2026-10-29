//
//  CoreDataPreferencesRepository.swift
//  SmartCharge
//

import Foundation
import CoreData

public final class CoreDataPreferencesRepository: PreferencesRepositoryProtocol, @unchecked Sendable {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    public func fetchPreferences() async throws -> UserPreferences {
        try await context.perform {
            let request = NSFetchRequest<UserPreferencesEntity>(entityName: "UserPreferencesEntity")
            request.fetchLimit = 1
            if let entity = try self.context.fetch(request).first {
                return self.toDomain(entity)
            } else {
                let newEntity = UserPreferencesEntity(context: self.context)
                newEntity.defaultSafetyReserve = 0.15
                newEntity.defaultRoutePreference = "Safest"
                newEntity.selectedVehicleId = nil
                try self.context.save()
                return self.toDomain(newEntity)
            }
        }
    }

    public func savePreferences(_ preferences: UserPreferences) async throws {
        try await context.perform {
            let request = NSFetchRequest<UserPreferencesEntity>(entityName: "UserPreferencesEntity")
            request.fetchLimit = 1
            let entity = try self.context.fetch(request).first ?? UserPreferencesEntity(context: self.context)
            entity.defaultSafetyReserve = preferences.defaultSafetyReserve
            entity.defaultRoutePreference = preferences.defaultRoutePreference.rawValue
            entity.selectedVehicleId = preferences.selectedVehicleId
            try self.context.save()
        }
    }

    public func resetToDefaults() async throws -> UserPreferences {
        let defaults = UserPreferences.default
        try await savePreferences(defaults)
        return defaults
    }

    private func toDomain(_ entity: UserPreferencesEntity) -> UserPreferences {
        let prefString = entity.defaultRoutePreference ?? "Safest"
        let preference = RoutePreference(rawValue: prefString) ?? .safest
        return UserPreferences(
            selectedVehicleId: entity.selectedVehicleId,
            defaultSafetyReserve: entity.defaultSafetyReserve,
            defaultRoutePreference: preference
        )
    }
}
