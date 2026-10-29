//
//  RecommendChargingStopUseCase.swift
//  SmartCharge
//

import Foundation

public protocol RecommendChargingStopUseCaseProtocol: Sendable {
    func evaluateReachability(
        stationDistanceKm: Double,
        estimate: BatteryEstimate
    ) -> ReachabilityStatus

    func recommend(
        stations: [ChargingStation],
        for vehicle: Vehicle,
        estimate: BatteryEstimate,
        preference: RoutePreference
    ) -> RecommendationResult
}

public struct RecommendChargingStopUseCase: RecommendChargingStopUseCaseProtocol {
    public init() {}

    /// Evaluates the reachability invariant:
    /// - distance > currentEstimatedRange -> unreachableExceedsPhysicalRange
    /// - safeRange < distance <= currentEstimatedRange -> reachableCautionBeyondReserve
    /// - distance <= safeRange -> reachableWithinSafeRange
    public func evaluateReachability(
        stationDistanceKm: Double,
        estimate: BatteryEstimate
    ) -> ReachabilityStatus {
        let currentRange = estimate.currentEstimatedRangeKm
        let safeRange = estimate.safePlanningRangeKm

        if stationDistanceKm > currentRange {
            let deficit = stationDistanceKm - currentRange
            return .unreachableExceedsPhysicalRange(deficitKm: deficit)
        } else if stationDistanceKm > safeRange {
            let excess = stationDistanceKm - safeRange
            let remainingPhysicalBuffer = currentRange - stationDistanceKm
            return .reachableCautionBeyondReserve(
                excessOverSafeKm: excess,
                remainingPhysicalBufferKm: remainingPhysicalBuffer
            )
        } else {
            let margin = safeRange - stationDistanceKm
            return .reachableWithinSafeRange(marginRemainingKm: margin)
        }
    }

    public func recommend(
        stations: [ChargingStation],
        for vehicle: Vehicle,
        estimate: BatteryEstimate,
        preference: RoutePreference = .safest
    ) -> RecommendationResult {
        // Step 1: Filter to compatible and operational stations
        let compatible = stations.filter { station in
            station.isOperational && station.supportsAny(of: vehicle.supportedConnectors)
        }

        guard !compatible.isEmpty else {
            return RecommendationResult(
                bestStation: nil,
                reachabilityStatus: .unreachableExceedsPhysicalRange(deficitKm: 0),
                whyRecommended: "No operational charging stations with compatible connectors (\(vehicle.supportedConnectors.map(\.displayName).joined(separator: ", "))) were found."
            )
        }

        // Step 2: Calculate reachability and scored candidates
        struct ScoredCandidate {
            let station: ChargingStation
            let reachability: ReachabilityStatus
            let breakdown: ScoreBreakdown
        }

        var candidates: [ScoredCandidate] = []

        for station in compatible {
            let distance = station.distanceKm ?? 0.0
            let reachability = evaluateReachability(stationDistanceKm: distance, estimate: estimate)

            // Calculate deterministic weighted score (0.0 to 100.0)
            // Factors:
            // 1. Distance (25%): Closer to optimal stopping point (around 70-85% of safe range) is better than too close or unreachable
            let targetDistance = estimate.safePlanningRangeKm * 0.75
            let distanceDelta = abs(distance - targetDistance)
            let distanceScore: Double
            if distance > estimate.currentEstimatedRangeKm {
                distanceScore = 0.0 // Strictly zero if physically unreachable
            } else {
                distanceScore = max(0.0, 100.0 - (distanceDelta / max(targetDistance, 1.0)) * 100.0)
            }

            // 2. Waiting Time (25%): Known short wait is best; missing wait receives neutral-to-low penalty (40%)
            let waitScore: Double
            switch station.waitTimeStatus {
            case .confirmedMinutes(let min):
                waitScore = max(0.0, 100.0 - Double(min) * 3.0)
            case .estimatedMinutes(let min):
                waitScore = max(0.0, 85.0 - Double(min) * 3.0)
            case .unavailable:
                waitScore = 40.0 // Penalized for lack of freshness/data
            }

            // 3. Availability (20%): Confirmed live availability gets high score; unconfirmed gets conservative score
            let availScore: Double
            switch station.availabilityStatus {
            case .liveConfirmed(let available, let total):
                availScore = total > 0 ? (Double(available) / Double(total)) * 100.0 : 0.0
            case .estimated(let available, let total):
                availScore = total > 0 ? (Double(available) / Double(total)) * 80.0 : 0.0
            case .unconfirmed:
                availScore = 45.0 // Conservative penalty
            case .outOfService:
                availScore = 0.0
            }

            // 4. Charging Speed (20%): Max power in kW (normalized against 350kW ultra-rapid)
            let speedRatio = min(1.0, station.maxPowerKW / 350.0)
            let speedScore = speedRatio * 100.0

            // 5. Cost (10%): Lower price per kWh is better; if unknown, moderate default
            let costScore: Double
            if let price = station.pricePerKWh {
                // assume reasonable baseline 0.35 to 0.90 $/kWh
                costScore = max(0.0, 100.0 - (price - 0.30) * 120.0)
            } else {
                costScore = 50.0
            }

            // Preference adjustments
            var wDistance = 0.25
            var wWait = 0.25
            var wAvail = 0.20
            var wSpeed = 0.20
            var wCost = 0.10

            switch preference {
            case .safest:
                wDistance = 0.35
                wAvail = 0.30
                wWait = 0.15
                wSpeed = 0.15
                wCost = 0.05
            case .fastestCharging:
                wSpeed = 0.45
                wWait = 0.25
                wDistance = 0.15
                wAvail = 0.10
                wCost = 0.05
            case .balanced:
                break
            }

            // Invariant: Unreachable stations receive composite score 0
            let rawComposite = (distanceScore * wDistance) + (waitScore * wWait) + (availScore * wAvail) + (speedScore * wSpeed) + (costScore * wCost)
            let finalComposite: Double
            switch reachability {
            case .unreachableExceedsPhysicalRange:
                finalComposite = 0.0
            case .reachableCautionBeyondReserve:
                finalComposite = rawComposite * 0.6 // Penalize for cutting into reserve
            case .reachableWithinSafeRange:
                finalComposite = rawComposite
            }

            let breakdown = ScoreBreakdown(
                distanceScore: distanceScore,
                waitTimeScore: waitScore,
                availabilityScore: availScore,
                speedScore: speedScore,
                costScore: costScore,
                compositeScore: finalComposite
            )

            candidates.append(ScoredCandidate(
                station: station,
                reachability: reachability,
                breakdown: breakdown
            ))
        }

        // Sort candidates:
        // 1. Safe reachability first, then caution, then unreachable
        // 2. Composite score descending
        let sorted = candidates.sorted { lhs, rhs in
            if lhs.reachability.isSafelyReachable != rhs.reachability.isSafelyReachable {
                return lhs.reachability.isSafelyReachable && !rhs.reachability.isSafelyReachable
            }
            if lhs.reachability.isReachable != rhs.reachability.isReachable {
                return lhs.reachability.isReachable && !rhs.reachability.isReachable
            }
            return lhs.breakdown.compositeScore > rhs.breakdown.compositeScore
        }

        guard let topCandidate = sorted.first else {
            return RecommendationResult(
                bestStation: nil,
                reachabilityStatus: .unreachableExceedsPhysicalRange(deficitKm: 0),
                whyRecommended: "No suitable station could be evaluated."
            )
        }

        let best = topCandidate.station
        let reachability = topCandidate.reachability
        let alternative = sorted.dropFirst().first?.station
        let altReachability = sorted.dropFirst().first?.reachability

        let whyText: String
        switch reachability {
        case .reachableWithinSafeRange(let margin):
            whyText = "Recommended based on \(preference.rawValue) mode: \(Int(best.maxPowerKW)) kW charging, reliable compatibility, and \(Int(margin)) km safety buffer remaining."
        case .reachableCautionBeyondReserve(let excess, let remaining):
            whyText = "Caution: Reachable within estimated physical battery (\(Int(remaining)) km buffer), but extends \(Int(excess)) km beyond your preferred safety reserve."
        case .unreachableExceedsPhysicalRange(let deficit):
            whyText = "Warning: Closest candidate is \(Int(deficit)) km beyond current physical range. Requires an earlier intermediate charging stop."
        }

        return RecommendationResult(
            bestStation: best,
            reachabilityStatus: reachability,
            whyRecommended: whyText,
            alternativeStation: alternative,
            alternativeReachability: altReachability,
            scoreBreakdown: topCandidate.breakdown
        )
    }
}
