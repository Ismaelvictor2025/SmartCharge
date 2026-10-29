//
//  ConnectorCompatibilityTests.swift
//  SmartChargeTests
//

import Testing
@testable import SmartCharge

@Suite("Connector Compatibility & Station Filtering Tests")
struct ConnectorCompatibilityTests {
    let useCase = FindCompatibleStationsUseCase()

    let ccsVehicle = Vehicle(
        name: "Test CCS EV",
        make: "Polestar",
        model: "2",
        theoreticalRangeKm: 500,
        batteryCapacityKWh: 78,
        supportedConnectors: [.ccs2, .type2]
    )

    let chademoVehicle = Vehicle(
        name: "Test CHAdeMO EV",
        make: "Nissan",
        model: "Leaf",
        theoreticalRangeKm: 300,
        batteryCapacityKWh: 40,
        supportedConnectors: [.chademo, .type2]
    )

    let ccsOnlyStation = ChargingStation(
        id: "s1",
        name: "CCS Station",
        operatorName: "Chargefox",
        latitude: -34.0,
        longitude: 150.0,
        address: "Test St",
        connectors: [StationConnector(type: .ccs2, powerKW: 150)],
        totalChargers: 2,
        isOperational: true,
        maxPowerKW: 150
    )

    let chademoOnlyStation = ChargingStation(
        id: "s2",
        name: "CHAdeMO Station",
        operatorName: "NRMA",
        latitude: -34.1,
        longitude: 150.1,
        address: "Test St 2",
        connectors: [StationConnector(type: .chademo, powerKW: 50)],
        totalChargers: 1,
        isOperational: true,
        maxPowerKW: 50
    )

    let offlineCcsStation = ChargingStation(
        id: "s3",
        name: "Offline CCS Station",
        operatorName: "BP",
        latitude: -34.2,
        longitude: 150.2,
        address: "Test St 3",
        connectors: [StationConnector(type: .ccs2, powerKW: 150)],
        totalChargers: 2,
        isOperational: false,
        maxPowerKW: 150
    )

    @Test("CCS2 vehicle matches CCS2 station and excludes CHAdeMO-only station")
    func ccsVehicleFiltering() {
        let allStations = [ccsOnlyStation, chademoOnlyStation]
        let compatible = useCase.execute(stations: allStations, for: ccsVehicle, minPowerKW: nil, requireOperational: true)

        #expect(compatible.count == 1)
        #expect(compatible.first?.id == "s1")
    }

    @Test("CHAdeMO vehicle matches CHAdeMO station and excludes CCS2-only station")
    func chademoVehicleFiltering() {
        let allStations = [ccsOnlyStation, chademoOnlyStation]
        let compatible = useCase.execute(stations: allStations, for: chademoVehicle, minPowerKW: nil, requireOperational: true)

        #expect(compatible.count == 1)
        #expect(compatible.first?.id == "s2")
    }

    @Test("Non-operational station is excluded when requireOperational is true")
    func nonOperationalExclusion() {
        let allStations = [ccsOnlyStation, offlineCcsStation]
        let compatible = useCase.execute(stations: allStations, for: ccsVehicle, minPowerKW: nil, requireOperational: true)

        #expect(compatible.count == 1)
        #expect(compatible.first?.id == "s1")

        // If requireOperational is false, offline is included
        let includingOffline = useCase.execute(stations: allStations, for: ccsVehicle, minPowerKW: nil, requireOperational: false)
        #expect(includingOffline.count == 2)
    }

    @Test("Minimum power threshold filters out slow chargers")
    func minimumPowerFiltering() {
        let dualPowerStations = [
            ccsOnlyStation, // 150 kW
            ChargingStation(
                id: "s4",
                name: "AC Slow Station",
                operatorName: "Dest",
                latitude: -34.3,
                longitude: 150.3,
                address: "Test St 4",
                connectors: [StationConnector(type: .type2, powerKW: 22)],
                totalChargers: 2,
                isOperational: true,
                maxPowerKW: 22
            )
        ]

        let fastOnly = useCase.execute(stations: dualPowerStations, for: ccsVehicle, minPowerKW: 50.0, requireOperational: true)
        #expect(fastOnly.count == 1)
        #expect(fastOnly.first?.id == "s1")
    }
}
