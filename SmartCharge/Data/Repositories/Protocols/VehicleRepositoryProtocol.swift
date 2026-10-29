//
//  VehicleRepositoryProtocol.swift
//  SmartCharge
//

import Foundation

public protocol VehicleRepositoryProtocol: Sendable {
    func fetchVehicles() async throws -> [Vehicle]
    func fetchDefaultVehicle() async throws -> Vehicle?
    func saveVehicle(_ vehicle: Vehicle) async throws
    func deleteVehicle(id: UUID) async throws
    func setDefaultVehicle(id: UUID) async throws
}
