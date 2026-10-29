//
//  FavouriteStationRepositoryProtocol.swift
//  SmartCharge
//

import Foundation

public protocol FavouriteStationRepositoryProtocol: Sendable {
    func fetchFavourites() async throws -> [FavouriteStation]
    func saveFavourite(_ station: FavouriteStation) async throws
    func deleteFavourite(id: String) async throws
    func isFavourite(id: String) async throws -> Bool
}
