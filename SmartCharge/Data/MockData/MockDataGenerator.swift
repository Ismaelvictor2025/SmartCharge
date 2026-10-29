//
//  MockDataGenerator.swift
//  SmartCharge
//

import Foundation

public struct MockDataGenerator {
    public static let sampleVehicles: [Vehicle] = [
        Vehicle(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            name: "Polestar 2 Long Range",
            make: "Polestar",
            model: "2 Long Range Dual Motor",
            theoreticalRangeKm: 500.0,
            batteryCapacityKWh: 78.0,
            supportedConnectors: [.ccs2, .type2],
            isDefault: true
        ),
        Vehicle(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            name: "Tesla Model Y RWD",
            make: "Tesla",
            model: "Model Y Rear-Wheel Drive",
            theoreticalRangeKm: 455.0,
            batteryCapacityKWh: 60.0,
            supportedConnectors: [.ccs2, .type2, .tesla],
            isDefault: false
        ),
        Vehicle(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            name: "Hyundai Ioniq 5 AWD",
            make: "Hyundai",
            model: "Ioniq 5 AWD Long Range",
            theoreticalRangeKm: 430.0,
            batteryCapacityKWh: 72.6,
            supportedConnectors: [.ccs2, .type2],
            isDefault: false
        ),
        Vehicle(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            name: "Nissan Leaf e+",
            make: "Nissan",
            model: "Leaf e+ 62kWh",
            theoreticalRangeKm: 385.0,
            batteryCapacityKWh: 62.0,
            supportedConnectors: [.chademo, .type2],
            isDefault: false
        )
    ]

    public static let sampleStations: [ChargingStation] = [
        // MARK: - Sydney Metropolitan
        ChargingStation(
            id: "ocm-syd-01",
            name: "Sydney CBD Fast Hub",
            operatorName: "Chargefox",
            latitude: -33.8688,
            longitude: 151.2093,
            address: "Kent St, Sydney NSW 2000",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast"),
                StationConnector(type: .type2, powerKW: 22.0, currentType: "AC")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 3, totalCount: 4),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.65,
            dataSource: "Chargefox Live API"
        ),
        ChargingStation(
            id: "ocm-syd-02",
            name: "NRMA Campbelltown Hub",
            operatorName: "NRMA Electric",
            latitude: -34.0650,
            longitude: 150.8140,
            address: "Kellicar Rd, Campbelltown NSW 2560",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 50.0, currentType: "DC Fast"),
                StationConnector(type: .chademo, powerKW: 50.0, currentType: "DC Fast")
            ],
            totalChargers: 2,
            isOperational: true,
            maxPowerKW: 50.0,
            availabilityStatus: .unconfirmed,
            waitTimeStatus: .unavailable,
            pricePerKWh: 0.54,
            dataSource: "Open Charge Map"
        ),

        // MARK: - Hume Corridor (Sydney -> Canberra -> Melbourne)
        ChargingStation(
            id: "ocm-hume-01",
            name: "AmpCharge Mittagong Fast Charger",
            operatorName: "Ampol AmpCharge",
            latitude: -34.4518,
            longitude: 150.4532,
            address: "Main St, Mittagong NSW 2575",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast"),
                StationConnector(type: .type2, powerKW: 22.0, currentType: "AC")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .estimated(availableCount: 2, totalCount: 4),
            waitTimeStatus: .estimatedMinutes(5),
            pricePerKWh: 0.69,
            dataSource: "Open Charge Map (Cached)"
        ),
        ChargingStation(
            id: "ocm-hume-02",
            name: "BP Pulse Sutton Forest",
            operatorName: "BP Pulse",
            latitude: -34.6120,
            longitude: 150.2840,
            address: "Hume Hwy, Sutton Forest NSW 2577",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast")
            ],
            totalChargers: 2,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 1, totalCount: 2),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.65,
            dataSource: "BP Pulse Feed"
        ),
        ChargingStation(
            id: "ocm-hume-03",
            name: "Evie Networks Marulan South",
            operatorName: "Evie Networks",
            latitude: -34.7180,
            longitude: 150.0211,
            address: "Hume Hwy Service Centre, Marulan NSW 2579",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 350.0, currentType: "DC Ultra-Rapid")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 350.0,
            availabilityStatus: .unconfirmed,
            waitTimeStatus: .unavailable,
            pricePerKWh: 0.68,
            dataSource: "Open Charge Map"
        ),
        ChargingStation(
            id: "ocm-hume-04",
            name: "Chargefox Goulburn Ultra-Rapid Hub",
            operatorName: "Chargefox",
            latitude: -34.7523,
            longitude: 149.7214,
            address: "Hume Hwy & Sydney Rd, Goulburn NSW 2580",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 350.0, currentType: "DC Ultra-Rapid"),
                StationConnector(type: .chademo, powerKW: 50.0, currentType: "DC Fast"),
                StationConnector(type: .type2, powerKW: 22.0, currentType: "AC")
            ],
            totalChargers: 6,
            isOperational: true,
            maxPowerKW: 350.0,
            availabilityStatus: .liveConfirmed(availableCount: 4, totalCount: 6),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.65,
            dataSource: "Chargefox Live Network"
        ),
        ChargingStation(
            id: "ocm-hume-05",
            name: "Tesla Supercharger Goulburn",
            operatorName: "Tesla",
            latitude: -34.7550,
            longitude: 149.7280,
            address: "100 Clinton St, Goulburn NSW 2580",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 250.0, currentType: "DC Supercharger"),
                StationConnector(type: .tesla, powerKW: 250.0, currentType: "DC Supercharger")
            ],
            totalChargers: 8,
            isOperational: true,
            maxPowerKW: 250.0,
            availabilityStatus: .liveConfirmed(availableCount: 5, totalCount: 8),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.72,
            dataSource: "Tesla Supercharger Feed"
        ),
        ChargingStation(
            id: "ocm-act-01",
            name: "Evie Canberra Civic Hub",
            operatorName: "Evie Networks",
            latitude: -35.2809,
            longitude: 149.1300,
            address: "London Cct, Canberra ACT 2601",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast"),
                StationConnector(type: .chademo, powerKW: 50.0, currentType: "DC Fast")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 3, totalCount: 4),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.67,
            dataSource: "Evie Live Network"
        ),
        ChargingStation(
            id: "ocm-hume-06",
            name: "Evie Yass Valley Fast Charger",
            operatorName: "Evie Networks",
            latitude: -34.8250,
            longitude: 148.9140,
            address: "Lead St, Yass NSW 2582",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast")
            ],
            totalChargers: 2,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .unconfirmed,
            waitTimeStatus: .unavailable,
            pricePerKWh: 0.68,
            dataSource: "Open Charge Map"
        ),
        ChargingStation(
            id: "ocm-hume-07",
            name: "NRMA Gundagai Fast Charger",
            operatorName: "NRMA Electric",
            latitude: -35.0640,
            longitude: 148.1090,
            address: "Sheridan St, Gundagai NSW 2722",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast"),
                StationConnector(type: .chademo, powerKW: 50.0, currentType: "DC Fast")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 2, totalCount: 4),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.64,
            dataSource: "NRMA Live Feed"
        ),
        ChargingStation(
            id: "ocm-hume-08",
            name: "Holbrook Submarine Hub",
            operatorName: "Chargefox",
            latitude: -35.7220,
            longitude: 147.3150,
            address: "Albury St, Holbrook NSW 2644",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 350.0, currentType: "DC Ultra-Rapid"),
                StationConnector(type: .chademo, powerKW: 50.0, currentType: "DC Fast")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 350.0,
            availabilityStatus: .liveConfirmed(availableCount: 3, totalCount: 4),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.65,
            dataSource: "Chargefox Live Network"
        ),
        ChargingStation(
            id: "ocm-hume-09",
            name: "Evie Albury Gateway",
            operatorName: "Evie Networks",
            latitude: -36.0800,
            longitude: 146.9160,
            address: "Hume Hwy & Riverina Hwy, Albury NSW 2640",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 350.0, currentType: "DC Ultra-Rapid"),
                StationConnector(type: .type2, powerKW: 22.0, currentType: "AC")
            ],
            totalChargers: 6,
            isOperational: true,
            maxPowerKW: 350.0,
            availabilityStatus: .liveConfirmed(availableCount: 4, totalCount: 6),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.68,
            dataSource: "Evie Live Network"
        ),
        ChargingStation(
            id: "ocm-hume-10",
            name: "Chargefox Euroa Ultra-Rapid Hub",
            operatorName: "Chargefox",
            latitude: -36.7500,
            longitude: 145.5700,
            address: "Clifton St, Euroa VIC 3666",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 350.0, currentType: "DC Ultra-Rapid"),
                StationConnector(type: .chademo, powerKW: 50.0, currentType: "DC Fast")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 350.0,
            availabilityStatus: .liveConfirmed(availableCount: 2, totalCount: 4),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.65,
            dataSource: "Chargefox Live Network"
        ),
        ChargingStation(
            id: "ocm-hume-11",
            name: "BP Pulse Seymour",
            operatorName: "BP Pulse",
            latitude: -37.0270,
            longitude: 145.1320,
            address: "Hume Fwy Service Centre, Seymour VIC 3660",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 3, totalCount: 4),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.65,
            dataSource: "BP Pulse Live Feed"
        ),
        ChargingStation(
            id: "ocm-mel-01",
            name: "Melbourne North Fast Hub",
            operatorName: "Evie Networks",
            latitude: -37.6680,
            longitude: 144.9570,
            address: "Sydney Rd, Campbellfield VIC 3061",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 350.0, currentType: "DC Ultra-Rapid")
            ],
            totalChargers: 6,
            isOperational: true,
            maxPowerKW: 350.0,
            availabilityStatus: .liveConfirmed(availableCount: 5, totalCount: 6),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.68,
            dataSource: "Evie Live Network"
        ),

        // MARK: - Pacific Corridor (Sydney -> Brisbane)
        ChargingStation(
            id: "ocm-pac-01",
            name: "AmpCharge Tuggerah SuperHub",
            operatorName: "Ampol AmpCharge",
            latitude: -33.3080,
            longitude: 151.4160,
            address: "Pacific Hwy, Tuggerah NSW 2259",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 3, totalCount: 4),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.69,
            dataSource: "Ampol Live Feed"
        ),
        ChargingStation(
            id: "ocm-pac-02",
            name: "Evie Heatherbrae Gateway",
            operatorName: "Evie Networks",
            latitude: -32.7840,
            longitude: 151.7240,
            address: "Pacific Hwy, Heatherbrae NSW 2324",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 350.0, currentType: "DC Ultra-Rapid")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 350.0,
            availabilityStatus: .liveConfirmed(availableCount: 2, totalCount: 4),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.68,
            dataSource: "Evie Live Network"
        ),
        ChargingStation(
            id: "ocm-pac-03",
            name: "Chargefox Taree Service Centre",
            operatorName: "Chargefox",
            latitude: -31.9080,
            longitude: 152.4570,
            address: "Pacific Hwy, Taree NSW 2430",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 350.0, currentType: "DC Ultra-Rapid"),
                StationConnector(type: .chademo, powerKW: 50.0, currentType: "DC Fast")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 350.0,
            availabilityStatus: .liveConfirmed(availableCount: 3, totalCount: 4),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.65,
            dataSource: "Chargefox Live Network"
        ),
        ChargingStation(
            id: "ocm-pac-04",
            name: "Evie Port Macquarie Hub",
            operatorName: "Evie Networks",
            latitude: -31.4330,
            longitude: 152.9080,
            address: "Pacific Hwy, Port Macquarie NSW 2444",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 350.0, currentType: "DC Ultra-Rapid")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 350.0,
            availabilityStatus: .liveConfirmed(availableCount: 2, totalCount: 4),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.68,
            dataSource: "Evie Live Network"
        ),
        ChargingStation(
            id: "ocm-pac-05",
            name: "Chargefox Coffs Harbour Hub",
            operatorName: "Chargefox",
            latitude: -30.2960,
            longitude: 153.1140,
            address: "Pacific Hwy, Coffs Harbour NSW 2450",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 350.0, currentType: "DC Ultra-Rapid")
            ],
            totalChargers: 6,
            isOperational: true,
            maxPowerKW: 350.0,
            availabilityStatus: .liveConfirmed(availableCount: 4, totalCount: 6),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.65,
            dataSource: "Chargefox Live Network"
        ),
        ChargingStation(
            id: "ocm-pac-06",
            name: "Chargefox Ballina Hub",
            operatorName: "Chargefox",
            latitude: -28.8680,
            longitude: 153.5350,
            address: "Pacific Hwy & Tamarind Dr, Ballina NSW 2478",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 350.0, currentType: "DC Ultra-Rapid")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 350.0,
            availabilityStatus: .liveConfirmed(availableCount: 3, totalCount: 4),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.65,
            dataSource: "Chargefox Live Network"
        ),
        ChargingStation(
            id: "ocm-bne-01",
            name: "Brisbane Gateway Ultra-Rapid",
            operatorName: "Evie Networks",
            latitude: -27.4690,
            longitude: 153.0250,
            address: "Pacific Mwy, Brisbane QLD 4000",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 350.0, currentType: "DC Ultra-Rapid")
            ],
            totalChargers: 6,
            isOperational: true,
            maxPowerKW: 350.0,
            availabilityStatus: .liveConfirmed(availableCount: 4, totalCount: 6),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.68,
            dataSource: "Evie Live Network"
        ),

        // MARK: - Sturt / Western Corridor (Sydney / Melbourne -> Adelaide)
        ChargingStation(
            id: "ocm-adl-01",
            name: "NRMA Wagga Wagga Hub",
            operatorName: "NRMA Electric",
            latitude: -35.1150,
            longitude: 147.3670,
            address: "Tarcutta St, Wagga Wagga NSW 2650",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast"),
                StationConnector(type: .chademo, powerKW: 50.0, currentType: "DC Fast")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 2, totalCount: 4),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.64,
            dataSource: "NRMA Live Feed"
        ),
        ChargingStation(
            id: "ocm-adl-02",
            name: "NRMA Hay Fast Charger",
            operatorName: "NRMA Electric",
            latitude: -34.5080,
            longitude: 144.8430,
            address: "Lachlan St, Hay NSW 2711",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast"),
                StationConnector(type: .chademo, powerKW: 50.0, currentType: "DC Fast")
            ],
            totalChargers: 2,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 1, totalCount: 2),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.64,
            dataSource: "NRMA Live Feed"
        ),
        ChargingStation(
            id: "ocm-adl-03",
            name: "Evie Mildura Hub",
            operatorName: "Evie Networks",
            latitude: -34.1850,
            longitude: 142.1620,
            address: "Fifteenth St, Mildura VIC 3500",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 3, totalCount: 4),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.68,
            dataSource: "Evie Live Network"
        ),
        ChargingStation(
            id: "ocm-adl-04",
            name: "RAA Renmark Fast Charger",
            operatorName: "RAA Charge",
            latitude: -34.1740,
            longitude: 140.7480,
            address: "Ral Ral Ave, Renmark SA 5341",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast")
            ],
            totalChargers: 2,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 2, totalCount: 2),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.65,
            dataSource: "RAA Charge Live"
        ),
        ChargingStation(
            id: "ocm-adl-05",
            name: "RAA Tailem Bend Hub",
            operatorName: "RAA Charge",
            latitude: -35.2570,
            longitude: 139.4580,
            address: "Princes Hwy, Tailem Bend SA 5260",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 200.0, currentType: "DC Ultra-Rapid")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 200.0,
            availabilityStatus: .liveConfirmed(availableCount: 3, totalCount: 4),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.65,
            dataSource: "RAA Charge Live"
        ),
        ChargingStation(
            id: "ocm-adl-06",
            name: "Adelaide CBD Central Supercharger",
            operatorName: "Tesla",
            latitude: -34.9285,
            longitude: 138.6007,
            address: "Franklin St, Adelaide SA 5000",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 250.0, currentType: "DC Supercharger"),
                StationConnector(type: .tesla, powerKW: 250.0, currentType: "DC Supercharger")
            ],
            totalChargers: 6,
            isOperational: true,
            maxPowerKW: 250.0,
            availabilityStatus: .liveConfirmed(availableCount: 4, totalCount: 6),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.72,
            dataSource: "Tesla Supercharger Feed"
        ),

        // MARK: - Eyre Corridor & Nullarbor (Adelaide -> Perth)
        ChargingStation(
            id: "ocm-perth-01",
            name: "RAA Port Augusta Fast Hub",
            operatorName: "RAA Charge",
            latitude: -32.4930,
            longitude: 137.7630,
            address: "Victoria Pde, Port Augusta SA 5700",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast"),
                StationConnector(type: .chademo, powerKW: 50.0, currentType: "DC Fast")
            ],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 2, totalCount: 4),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.67,
            dataSource: "RAA Charge Live"
        ),
        ChargingStation(
            id: "ocm-perth-02",
            name: "RAA Kimba Charger",
            operatorName: "RAA Charge",
            latitude: -33.1380,
            longitude: 136.4170,
            address: "Eyre Hwy, Kimba SA 5641",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast")
            ],
            totalChargers: 2,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 2, totalCount: 2),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.67,
            dataSource: "RAA Charge Live"
        ),
        ChargingStation(
            id: "ocm-perth-03",
            name: "RAA Ceduna Gateway",
            operatorName: "RAA Charge",
            latitude: -32.1280,
            longitude: 133.6760,
            address: "Eyre Hwy & Poynton St, Ceduna SA 5690",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast")
            ],
            totalChargers: 2,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 1, totalCount: 2),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.69,
            dataSource: "RAA Charge Live"
        ),
        ChargingStation(
            id: "ocm-perth-04",
            name: "Nullarbor Roadhouse Fast Station",
            operatorName: "Nullarbor Links Network",
            latitude: -31.4550,
            longitude: 130.9020,
            address: "Eyre Hwy, Nullarbor SA 5690",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 50.0, currentType: "DC Fast")
            ],
            totalChargers: 2,
            isOperational: true,
            maxPowerKW: 50.0,
            availabilityStatus: .unconfirmed,
            waitTimeStatus: .unavailable,
            pricePerKWh: 0.95,
            dataSource: "Open Charge Map (Remote)"
        ),
        ChargingStation(
            id: "ocm-perth-05",
            name: "Border Village SA/WA Post",
            operatorName: "Eyre Highway Network",
            latitude: -31.6420,
            longitude: 129.0010,
            address: "Eyre Hwy, Border Village SA 5690",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 50.0, currentType: "DC Fast")
            ],
            totalChargers: 1,
            isOperational: true,
            maxPowerKW: 50.0,
            availabilityStatus: .unconfirmed,
            waitTimeStatus: .unavailable,
            pricePerKWh: 0.95,
            dataSource: "Open Charge Map (Remote)"
        ),
        ChargingStation(
            id: "ocm-perth-06",
            name: "Madura Pass Roadhouse",
            operatorName: "WA EV Network",
            latitude: -31.9160,
            longitude: 127.0090,
            address: "Eyre Hwy, Madura WA 6443",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast")
            ],
            totalChargers: 2,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 2, totalCount: 2),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.85,
            dataSource: "Synergy / Horizon Power Feed"
        ),
        ChargingStation(
            id: "ocm-perth-07",
            name: "Caiguna Roadhouse Charger",
            operatorName: "WA EV Network",
            latitude: -32.2820,
            longitude: 125.4830,
            address: "Eyre Hwy, Caiguna WA 6443",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast")
            ],
            totalChargers: 2,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 1, totalCount: 2),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.85,
            dataSource: "Synergy / Horizon Power Feed"
        ),
        ChargingStation(
            id: "ocm-perth-08",
            name: "Norseman Gateway Fast Charger",
            operatorName: "WA EV Network",
            latitude: -32.1970,
            longitude: 121.7800,
            address: "Prinsep St, Norseman WA 6443",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast")
            ],
            totalChargers: 2,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 2, totalCount: 2),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.70,
            dataSource: "Synergy / Horizon Power Feed"
        ),
        ChargingStation(
            id: "ocm-perth-09",
            name: "Kalgoorlie Goldfields Hub",
            operatorName: "WA EV Network",
            latitude: -30.7490,
            longitude: 121.4660,
            address: "Forrest St, Kalgoorlie WA 6430",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast")
            ],
            totalChargers: 2,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 2, totalCount: 2),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.65,
            dataSource: "Synergy / Horizon Power Feed"
        ),
        ChargingStation(
            id: "ocm-perth-10",
            name: "Southern Cross Fast Hub",
            operatorName: "WA EV Network",
            latitude: -31.2980,
            longitude: 119.3270,
            address: "Antares St, Southern Cross WA 6426",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast")
            ],
            totalChargers: 2,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 2, totalCount: 2),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.65,
            dataSource: "Synergy / Horizon Power Feed"
        ),
        ChargingStation(
            id: "ocm-perth-11",
            name: "Northam Avon Valley Hub",
            operatorName: "WA EV Network",
            latitude: -31.6530,
            longitude: 116.6660,
            address: "Fitzgerald St, Northam WA 6401",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 150.0, currentType: "DC Fast")
            ],
            totalChargers: 2,
            isOperational: true,
            maxPowerKW: 150.0,
            availabilityStatus: .liveConfirmed(availableCount: 2, totalCount: 2),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.60,
            dataSource: "Synergy / Horizon Power Feed"
        ),
        ChargingStation(
            id: "ocm-perth-12",
            name: "Perth CBD Kings Square Hub",
            operatorName: "Chargefox",
            latitude: -31.9505,
            longitude: 115.8605,
            address: "Wellington St, Perth WA 6000",
            connectors: [
                StationConnector(type: .ccs2, powerKW: 350.0, currentType: "DC Ultra-Rapid")
            ],
            totalChargers: 6,
            isOperational: true,
            maxPowerKW: 350.0,
            availabilityStatus: .liveConfirmed(availableCount: 4, totalCount: 6),
            waitTimeStatus: .confirmedMinutes(0),
            pricePerKWh: 0.65,
            dataSource: "Chargefox Live Network"
        )
    ]
}
