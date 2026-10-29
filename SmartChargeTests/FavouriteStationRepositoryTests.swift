//
//  FavouriteStationRepositoryTests.swift
//  SmartChargeTests
//

import Testing
import CoreData
import CoreLocation
@testable import SmartCharge

@Suite("Favourite Station Repository Tests")
@MainActor
struct FavouriteStationRepositoryTests {
    let persistenceController: PersistenceController
    let favouriteRepo: CoreDataFavouriteStationRepository

    init() {
        self.persistenceController = PersistenceController(inMemory: true)
        self.favouriteRepo = CoreDataFavouriteStationRepository(context: persistenceController.container.viewContext)
    }

    @Test("Save favourite station, verify existence and fetch")
    func saveAndFetchFavourite() async throws {
        let station = FavouriteStation(
            id: "station_tesla_goulburn",
            name: "Tesla Supercharger Goulburn",
            operatorName: "Tesla",
            coordinate: CLLocationCoordinate2D(latitude: -34.7523, longitude: 149.7212),
            powerKW: 250.0,
            supportedConnectors: [.ccs2, .type2]
        )

        let initialCheck = try await favouriteRepo.isFavourite(id: station.id)
        #expect(initialCheck == false)

        try await favouriteRepo.saveFavourite(station)

        let isFav = try await favouriteRepo.isFavourite(id: station.id)
        #expect(isFav == true)

        let allFavs = try await favouriteRepo.fetchFavourites()
        #expect(allFavs.count == 1)
        #expect(allFavs.first?.name == "Tesla Supercharger Goulburn")
        #expect(allFavs.first?.powerKW == 250.0)
    }

    @Test("Upsert duplicate favourite updates details without creating duplicate rows")
    func upsertDuplicateUpdatesWithoutDuplication() async throws {
        let station1 = FavouriteStation(
            id: "evie_pheasants_nest",
            name: "Evie Pheasants Nest North",
            operatorName: "Evie Networks",
            coordinate: CLLocationCoordinate2D(latitude: -34.2501, longitude: 150.6012),
            powerKW: 350.0
        )
        try await favouriteRepo.saveFavourite(station1)

        let station1Updated = FavouriteStation(
            id: "evie_pheasants_nest",
            name: "Evie Pheasants Nest North (Upgraded)",
            operatorName: "Evie Networks",
            coordinate: CLLocationCoordinate2D(latitude: -34.2501, longitude: 150.6012),
            powerKW: 400.0
        )
        try await favouriteRepo.saveFavourite(station1Updated)

        let allFavs = try await favouriteRepo.fetchFavourites()
        #expect(allFavs.count == 1)
        #expect(allFavs.first?.name == "Evie Pheasants Nest North (Upgraded)")
        #expect(allFavs.first?.powerKW == 400.0)
    }

    @Test("Delete favourite removes record cleanly")
    func deleteFavouriteRemovesRecord() async throws {
        let station = FavouriteStation(
            id: "bp_pulse_marulan",
            name: "BP Pulse Marulan South",
            operatorName: "BP Pulse",
            coordinate: CLLocationCoordinate2D(latitude: -34.7200, longitude: 150.0100),
            powerKW: 150.0
        )

        try await favouriteRepo.saveFavourite(station)
        #expect(try await favouriteRepo.isFavourite(id: station.id) == true)

        try await favouriteRepo.deleteFavourite(id: station.id)
        #expect(try await favouriteRepo.isFavourite(id: station.id) == false)

        let remaining = try await favouriteRepo.fetchFavourites()
        #expect(remaining.isEmpty)
    }
}
