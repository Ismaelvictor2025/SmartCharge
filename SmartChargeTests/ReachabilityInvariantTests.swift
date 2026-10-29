//
//  ReachabilityInvariantTests.swift
//  SmartChargeTests
//

import Testing
@testable import SmartCharge

@Suite("Reachability Invariant & Safety Safeguards Tests")
struct ReachabilityInvariantTests {
    let useCase = RecommendChargingStopUseCase()

    // 500 km WLTP, 85% battery, 15% reserve -> physical 425 km, safe 361.25 km
    let estimate = BatteryEstimate(
        theoreticalRangeKm: 500.0,
        batteryPercentage: 0.85,
        safetyReservePercentage: 0.15
    )

    let vehicle = Vehicle(
        name: "Test Vehicle",
        make: "Polestar",
        model: "2",
        theoreticalRangeKm: 500.0,
        batteryCapacityKWh: 78.0,
        supportedConnectors: [.ccs2]
    )

    @Test("Mandatory Invariant: Station exceeding physical range is NEVER labeled reachable")
    func stationExceedingPhysicalRangeNeverReachable() {
        let stationDistance = 450.0 // 450 > 425 km physical range

        let status = useCase.evaluateReachability(
            stationDistanceKm: stationDistance,
            estimate: estimate
        )

        switch status {
        case .unreachableExceedsPhysicalRange(let deficit):
            #expect(deficit == 25.0) // 450 - 425 = 25 km
            #expect(status.isReachable == false)
            #expect(status.isSafelyReachable == false)
        default:
            Issue.record("Expected unreachableExceedsPhysicalRange, got \(status)")
        }
    }

    @Test("Station within physical range but outside safety reserve returns caution")
    func stationWithinPhysicalRangeExceedingSafeMarginReturnsCaution() {
        let stationDistance = 380.0 // 361.25 < 380 <= 425

        let status = useCase.evaluateReachability(
            stationDistanceKm: stationDistance,
            estimate: estimate
        )

        switch status {
        case .reachableCautionBeyondReserve(let excess, let remaining):
            #expect(excess == 18.75) // 380 - 361.25 = 18.75 km
            #expect(remaining == 45.0) // 425 - 380 = 45 km buffer
            #expect(status.isReachable == true)
            #expect(status.isSafelyReachable == false)
        default:
            Issue.record("Expected reachableCautionBeyondReserve, got \(status)")
        }
    }

    @Test("Station within safe planning range returns safely reachable")
    func stationWithinSafePlanningRangeReturnsSafe() {
        let stationDistance = 250.0 // 250 <= 361.25

        let status = useCase.evaluateReachability(
            stationDistanceKm: stationDistance,
            estimate: estimate
        )

        switch status {
        case .reachableWithinSafeRange(let margin):
            #expect(margin == 111.25) // 361.25 - 250 = 111.25 km
            #expect(status.isReachable == true)
            #expect(status.isSafelyReachable == true)
        default:
            Issue.record("Expected reachableWithinSafeRange, got \(status)")
        }
    }

    @Test("Recommendation ranking never overrides physical reachability")
    func rankingNeverOverridesReachability() {
        // High power 350kW station that is physically unreachable
        let distantUltraFast = ChargingStation(
            id: "distant-hub",
            name: "Distant 350kW Hub",
            operatorName: "Ultra",
            latitude: -35.0,
            longitude: 148.0,
            address: "Far Away",
            connectors: [StationConnector(type: .ccs2, powerKW: 350)],
            totalChargers: 8,
            isOperational: true,
            maxPowerKW: 350,
            availabilityStatus: .liveConfirmed(availableCount: 8, totalCount: 8),
            waitTimeStatus: .confirmedMinutes(0),
            distanceKm: 480.0 // 480 > 425 physical
        )

        // Moderate 150kW station that is safely reachable
        let safeFast = ChargingStation(
            id: "safe-hub",
            name: "Safe 150kW Hub",
            operatorName: "SafeNet",
            latitude: -34.5,
            longitude: 149.5,
            address: "Near Way",
            connectors: [StationConnector(type: .ccs2, powerKW: 150)],
            totalChargers: 4,
            isOperational: true,
            maxPowerKW: 150,
            availabilityStatus: .liveConfirmed(availableCount: 3, totalCount: 4),
            waitTimeStatus: .confirmedMinutes(0),
            distanceKm: 220.0 // 220 <= 361.25 safe
        )

        let result = useCase.recommend(
            stations: [distantUltraFast, safeFast],
            for: vehicle,
            estimate: estimate,
            preference: .fastestCharging // Even in fastest charging mode!
        )

        // The safe station MUST be chosen as best station
        #expect(result.bestStation?.id == "safe-hub")
        #expect(result.reachabilityStatus.isSafelyReachable == true)
    }

    @Test("Unconfirmed availability does not receive full score")
    func unconfirmedAvailabilityIsPenalized() {
        let unconfirmedStation = ChargingStation(
            id: "unconfirmed-hub",
            name: "Unconfirmed Hub",
            operatorName: "Test",
            latitude: -34.5,
            longitude: 149.5,
            address: "Test",
            connectors: [StationConnector(type: .ccs2, powerKW: 150)],
            totalChargers: 2,
            isOperational: true,
            maxPowerKW: 150,
            availabilityStatus: .unconfirmed,
            waitTimeStatus: .unavailable,
            distanceKm: 200.0
        )

        let result = useCase.recommend(
            stations: [unconfirmedStation],
            for: vehicle,
            estimate: estimate,
            preference: .safest
        )

        if let breakdown = result.scoreBreakdown {
            // Unconfirmed availability should be conservatively capped
            #expect(breakdown.availabilityScore < 50.0)
            #expect(breakdown.waitTimeScore <= 40.0)
        } else {
            Issue.record("Expected score breakdown")
        }
    }
}
