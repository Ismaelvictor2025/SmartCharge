//
//  MultiStopRoutePlannerTests.swift
//  SmartChargeTests
//

import Testing
@testable import SmartCharge

@Suite("Multi-Stop Route Planning & Infrastructure Gap Tests")
struct MultiStopRoutePlannerTests {
    let planner = MultiStopRoutePlanner()

    let testVehicle = Vehicle(
        name: "Polestar 2 LR",
        make: "Polestar",
        model: "2",
        theoreticalRangeKm: 500.0,
        batteryCapacityKWh: 78.0,
        supportedConnectors: [.ccs2, .type2]
    )

    @Test("Direct route within safe range requires 0 charging stops")
    func directRouteRequiresZeroStops() {
        // Distance 280 km with 500km WLTP @ 85% battery, 15% reserve -> safe range = 361.25 km
        let result = planner.planChargingStops(
            totalDistanceKm: 280.0,
            originName: "Sydney",
            destinationName: "Canberra",
            vehicle: testVehicle,
            initialBatteryPercent: 0.85,
            safetyReservePercent: 0.15,
            targetRechargePercent: 0.85,
            preference: .safest,
            stationsAlongRoute: MockDataGenerator.sampleStations
        )

        #expect(result.isFeasible == true)
        #expect(result.plannedStops.isEmpty == true)
        #expect(result.infrastructureGaps.isEmpty == true)
        #expect(result.totalChargingTimeMinutes == 0)
    }

    @Test("Long distance Sydney to Melbourne (880 km) generates multi-stop feasible plan")
    func longDistanceGeneratesMultiStopPlan() {
        // Highway stations spaced along the 880km Hume corridor
        let humeStations: [ChargingStation] = [
            ChargingStation(
                id: "hume-mittagong",
                name: "Mittagong Fast Hub",
                operatorName: "AmpCharge",
                latitude: -34.45,
                longitude: 150.45,
                address: "Mittagong NSW",
                connectors: [StationConnector(type: .ccs2, powerKW: 150)],
                totalChargers: 4,
                isOperational: true,
                maxPowerKW: 150,
                distanceKm: 112.0
            ),
            ChargingStation(
                id: "hume-goulburn",
                name: "Goulburn Ultra-Rapid Hub",
                operatorName: "Chargefox",
                latitude: -34.75,
                longitude: 149.72,
                address: "Goulburn NSW",
                connectors: [StationConnector(type: .ccs2, powerKW: 350)],
                totalChargers: 6,
                isOperational: true,
                maxPowerKW: 350,
                distanceKm: 195.0
            ),
            ChargingStation(
                id: "hume-gundagai",
                name: "Gundagai Fast Charger",
                operatorName: "NRMA",
                latitude: -35.06,
                longitude: 148.10,
                address: "Gundagai NSW",
                connectors: [StationConnector(type: .ccs2, powerKW: 150)],
                totalChargers: 4,
                isOperational: true,
                maxPowerKW: 150,
                distanceKm: 375.0
            ),
            ChargingStation(
                id: "hume-albury",
                name: "Albury Gateway Ultra-Rapid",
                operatorName: "Evie Networks",
                latitude: -36.08,
                longitude: 146.91,
                address: "Albury NSW",
                connectors: [StationConnector(type: .ccs2, powerKW: 350)],
                totalChargers: 6,
                isOperational: true,
                maxPowerKW: 350,
                distanceKm: 550.0
            ),
            ChargingStation(
                id: "hume-euroa",
                name: "Euroa Ultra-Rapid Hub",
                operatorName: "Chargefox",
                latitude: -36.75,
                longitude: 145.57,
                address: "Euroa VIC",
                connectors: [StationConnector(type: .ccs2, powerKW: 350)],
                totalChargers: 4,
                isOperational: true,
                maxPowerKW: 350,
                distanceKm: 720.0
            )
        ]

        let result = planner.planChargingStops(
            totalDistanceKm: 880.0,
            originName: "Sydney",
            destinationName: "Melbourne",
            vehicle: testVehicle,
            initialBatteryPercent: 0.85, // 361.25 km safe
            safetyReservePercent: 0.15,
            targetRechargePercent: 0.85,
            preference: .safest,
            stationsAlongRoute: humeStations
        )

        #expect(result.isFeasible == true)
        #expect(result.plannedStops.count >= 2) // At least 2 intermediate stops for ~880km with ~360km range
        #expect(result.infrastructureGaps.isEmpty == true)
        #expect(result.totalChargingTimeMinutes > 0)

        // Verify sequential leg reachability
        for stop in result.plannedStops {
            #expect(stop.arrivalBatteryPercent > 0.0)
            #expect(stop.departureBatteryPercent >= 0.80)
            #expect(stop.reachabilityStatus.isReachable == true)
        }
    }

    @Test("Route with remote gap exceeding vehicle battery identifies Infrastructure Gap")
    func routeWithRemoteGapIdentifiesInfrastructureGap() {
        // Create an isolated corridor with a huge 600km gap where vehicle physical range is only 425km
        let sparseStations = [
            ChargingStation(
                id: "gap-station-1",
                name: "Starting Outpost Hub",
                operatorName: "RemoteNet",
                latitude: -32.0,
                longitude: 133.0,
                address: "Outback Hwy",
                connectors: [StationConnector(type: .ccs2, powerKW: 150)],
                totalChargers: 2,
                isOperational: true,
                maxPowerKW: 150,
                distanceKm: 150.0 // Reachable on leg 1
            ),
            ChargingStation(
                id: "gap-station-2",
                name: "Distant Desert Hub",
                operatorName: "RemoteNet",
                latitude: -32.0,
                longitude: 125.0,
                address: "Outback Hwy",
                connectors: [StationConnector(type: .ccs2, powerKW: 150)],
                totalChargers: 2,
                isOperational: true,
                maxPowerKW: 150,
                distanceKm: 850.0 // 700km after station 1 -> exceeds 425km physical range!
            )
        ]

        let result = planner.planChargingStops(
            totalDistanceKm: 1200.0,
            originName: "Ceduna",
            destinationName: "Kalgoorlie",
            vehicle: testVehicle,
            initialBatteryPercent: 0.85,
            safetyReservePercent: 0.15,
            targetRechargePercent: 0.85,
            preference: .safest,
            stationsAlongRoute: sparseStations
        )

        #expect(result.isFeasible == false)
        #expect(!result.infrastructureGaps.isEmpty)
        let gap = result.infrastructureGaps.first
        #expect(gap?.deficitKm ?? 0 > 0)
    }

    @Test("Fastest Charging preference prioritises higher kW charging hubs")
    func fastestChargingPreferenceFavoursHighPower() {
        let dualStations = [
            ChargingStation(
                id: "slow-50",
                name: "Slow 50kW Charger",
                operatorName: "Local",
                latitude: -34.75,
                longitude: 149.72,
                address: "Hwy",
                connectors: [StationConnector(type: .ccs2, powerKW: 50)],
                totalChargers: 2,
                isOperational: true,
                maxPowerKW: 50,
                distanceKm: 180.0
            ),
            ChargingStation(
                id: "fast-350",
                name: "Ultra 350kW Hub",
                operatorName: "Chargefox",
                latitude: -34.75,
                longitude: 149.72,
                address: "Hwy",
                connectors: [StationConnector(type: .ccs2, powerKW: 350)],
                totalChargers: 4,
                isOperational: true,
                maxPowerKW: 350,
                distanceKm: 195.0
            )
        ]

        let result = planner.planChargingStops(
            totalDistanceKm: 400.0,
            originName: "Sydney",
            destinationName: "Gundagai",
            vehicle: testVehicle,
            initialBatteryPercent: 0.80, // Safe range 340 km
            safetyReservePercent: 0.15,
            targetRechargePercent: 0.85,
            preference: .fastestCharging,
            stationsAlongRoute: dualStations
        )

        #expect(result.plannedStops.first?.station.id == "fast-350")
    }
}
