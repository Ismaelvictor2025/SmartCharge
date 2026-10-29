//
//  RouteRiskTests.swift
//  SmartChargeTests
//

import Testing
@testable import SmartCharge

@Suite("Route Risk Analysis & Classification Tests")
struct RouteRiskTests {
    let useCase = AnalyseRouteRiskUseCase()

    // 500 km WLTP, 85% battery, 15% reserve -> physical 425 km, safe 361.25 km
    let estimate = BatteryEstimate(
        theoreticalRangeKm: 500.0,
        batteryPercentage: 0.85,
        safetyReservePercentage: 0.15
    )

    @Test("Optimal trip well within safe range returns LOW risk")
    func optimalTripReturnsLowRisk() {
        let segments = [
            RouteSegment(
                startLocationName: "A",
                endLocationName: "B",
                distanceKm: 150.0,
                availableChargingCount: 3,
                maxPowerAlongSegmentKW: 150.0
            )
        ]

        let result = useCase.execute(
            totalDistanceKm: 150.0,
            estimate: estimate,
            segments: segments,
            compatibleStationsAlongRoute: MockDataGenerator.sampleStations
        )

        #expect(result.overallRiskLevel == .low)
        #expect(result.riskScore < 30.0)
        #expect(result.criticalSegmentsCount == 0)
        #expect(result.highRiskSegmentsCount == 0)
    }

    @Test("Route with segment consuming into safety buffer triggers HIGH risk")
    func segmentConsumingReserveTriggersHighRisk() {
        // Safe range is 361.25 km. Segment is 390 km (under 425 km physical range).
        let segments = [
            RouteSegment(
                startLocationName: "Origin",
                endLocationName: "Charger",
                distanceKm: 390.0,
                availableChargingCount: 1,
                maxPowerAlongSegmentKW: 150.0
            )
        ]

        let result = useCase.execute(
            totalDistanceKm: 390.0,
            estimate: estimate,
            segments: segments,
            compatibleStationsAlongRoute: []
        )

        #expect(result.overallRiskLevel == .high)
        #expect(result.highRiskSegmentsCount == 1)
        #expect(result.criticalSegmentsCount == 0)
    }

    @Test("Route with segment exceeding physical range triggers CRITICAL risk")
    func segmentExceedingPhysicalRangeTriggersCriticalRisk() {
        // Physical range is 425 km. Segment is 480 km.
        let segments = [
            RouteSegment(
                startLocationName: "Origin",
                endLocationName: "Charger",
                distanceKm: 480.0,
                availableChargingCount: 0,
                maxPowerAlongSegmentKW: 0
            )
        ]

        let result = useCase.execute(
            totalDistanceKm: 480.0,
            estimate: estimate,
            segments: segments,
            compatibleStationsAlongRoute: []
        )

        #expect(result.overallRiskLevel == .critical)
        #expect(result.criticalSegmentsCount >= 1)
        #expect(result.riskScore >= 75.0)
    }

    @Test("Infrastructure gap on long route triggers gap count")
    func infrastructureGapDetection() {
        // Safe range is 361.25 km. 50% is ~180 km.
        // A segment of 220 km with 0 charging count.
        let segments = [
            RouteSegment(
                startLocationName: "Town A",
                endLocationName: "Town B",
                distanceKm: 220.0,
                availableChargingCount: 0,
                maxPowerAlongSegmentKW: 0
            )
        ]

        let result = useCase.execute(
            totalDistanceKm: 220.0,
            estimate: estimate,
            segments: segments,
            compatibleStationsAlongRoute: []
        )

        #expect(result.infrastructureGapsCount >= 1)
    }
}
