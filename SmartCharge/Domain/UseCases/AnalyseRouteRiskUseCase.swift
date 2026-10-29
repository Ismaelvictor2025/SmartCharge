//
//  AnalyseRouteRiskUseCase.swift
//  SmartCharge
//

import Foundation

public protocol AnalyseRouteRiskUseCaseProtocol: Sendable {
    func execute(
        totalDistanceKm: Double,
        estimate: BatteryEstimate,
        segments: [RouteSegment],
        compatibleStationsAlongRoute: [ChargingStation]
    ) -> RouteRiskResult
}

public struct AnalyseRouteRiskUseCase: AnalyseRouteRiskUseCaseProtocol {
    public init() {}

    public func execute(
        totalDistanceKm: Double,
        estimate: BatteryEstimate,
        segments: [RouteSegment],
        compatibleStationsAlongRoute: [ChargingStation]
    ) -> RouteRiskResult {
        var warnings: [String] = []
        var criticalCount = 0
        var highCount = 0
        var gapCount = 0

        let safeRange = estimate.safePlanningRangeKm
        let physicalRange = estimate.currentEstimatedRangeKm

        // Check overall total trip distance vs battery
        var tripExceedsPhysical = false
        var tripExceedsSafe = false

        if totalDistanceKm > physicalRange && compatibleStationsAlongRoute.isEmpty {
            tripExceedsPhysical = true
            warnings.append("Total distance (\(Int(totalDistanceKm)) km) exceeds physical range (\(Int(physicalRange)) km) with no compatible chargers found along route.")
        } else if totalDistanceKm > safeRange && compatibleStationsAlongRoute.isEmpty {
            tripExceedsSafe = true
            warnings.append("Total distance (\(Int(totalDistanceKm)) km) exceeds safe planning range (\(Int(safeRange)) km). Intermediate charging is advised.")
        }

        // Analyze individual route segments
        for segment in segments {
            if segment.distanceKm > physicalRange {
                criticalCount += 1
                warnings.append("Segment '\(segment.startLocationName) → \(segment.endLocationName)' (\(Int(segment.distanceKm)) km) exceeds physical battery range.")
            } else if segment.distanceKm > safeRange {
                highCount += 1
                warnings.append("Segment '\(segment.startLocationName) → \(segment.endLocationName)' (\(Int(segment.distanceKm)) km) consumes into your safety reserve buffer.")
            }

            // Infrastructure gaps: segment > 50% of safe range with zero charging backups
            if segment.distanceKm > (safeRange * 0.5) && segment.availableChargingCount == 0 {
                gapCount += 1
                warnings.append("Charging gap detected on '\(segment.startLocationName) → \(segment.endLocationName)': zero backup chargers within \(Int(segment.distanceKm)) km.")
            }
        }

        // Determine deterministic risk level
        let overallLevel: RiskLevel
        let baseScore: Double

        if criticalCount > 0 || tripExceedsPhysical {
            overallLevel = .critical
            baseScore = min(100.0, 75.0 + Double(criticalCount * 10) + Double(highCount * 5))
        } else if highCount > 0 || tripExceedsSafe {
            overallLevel = .high
            baseScore = min(74.0, 50.0 + Double(highCount * 10) + Double(gapCount * 4))
        } else if gapCount > 0 || totalDistanceKm > safeRange {
            overallLevel = .medium
            baseScore = min(49.0, 25.0 + Double(gapCount * 8))
        } else {
            overallLevel = .low
            baseScore = max(5.0, 15.0 - Double(compatibleStationsAlongRoute.count))
        }

        let summaryText: String
        switch overallLevel {
        case .low:
            summaryText = "Route is well within safe planning range with adequate charging availability."
        case .medium:
            summaryText = "Moderate charging density. Keep an eye on consumption and monitor nearby chargers."
        case .high:
            summaryText = "Route segment exceeds safe planning buffer. A planned charging stop is strongly recommended."
        case .critical:
            summaryText = "Route contains critical distance gaps exceeding physical battery range. Charging is mandatory."
        }

        return RouteRiskResult(
            overallRiskLevel: overallLevel,
            riskScore: baseScore,
            highRiskSegmentsCount: highCount,
            criticalSegmentsCount: criticalCount,
            infrastructureGapsCount: gapCount,
            warnings: warnings,
            summary: summaryText
        )
    }
}
