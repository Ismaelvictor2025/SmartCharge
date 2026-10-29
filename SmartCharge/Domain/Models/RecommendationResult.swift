//
//  RecommendationResult.swift
//  SmartCharge
//

import Foundation

public enum ReachabilityStatus: Equatable, Hashable, Sendable {
    /// Station is within the vehicle's safe planning range (currentEstimatedRange * (1 - S)).
    case reachableWithinSafeRange(marginRemainingKm: Double)

    /// Station is physically reachable on current estimated battery, but cuts into the safety reserve.
    case reachableCautionBeyondReserve(excessOverSafeKm: Double, remainingPhysicalBufferKm: Double)

    /// Station distance strictly exceeds the physical estimated battery range (distance > currentEstimatedRange).
    /// Invariant: MUST NEVER be labeled reachable or recommended without intermediate charging.
    case unreachableExceedsPhysicalRange(deficitKm: Double)

    public var isReachable: Bool {
        switch self {
        case .reachableWithinSafeRange, .reachableCautionBeyondReserve:
            return true
        case .unreachableExceedsPhysicalRange:
            return false
        }
    }

    public var isSafelyReachable: Bool {
        if case .reachableWithinSafeRange = self { return true }
        return false
    }

    public var badgeTitle: String {
        switch self {
        case .reachableWithinSafeRange:
            return "Safely Reachable"
        case .reachableCautionBeyondReserve:
            return "Within Range • Low Margin"
        case .unreachableExceedsPhysicalRange:
            return "Unreachable"
        }
    }

    public var advisoryMessage: String {
        switch self {
        case .reachableWithinSafeRange(let margin):
            return "Reachable with approximately \(Int(margin)) km safety buffer remaining upon arrival."
        case .reachableCautionBeyondReserve(let excess, _):
            return "This station may be within estimated physical range but consumes \(Int(excess)) km into your preferred safety margin."
        case .unreachableExceedsPhysicalRange(let deficit):
            return "This station is approximately \(Int(deficit)) km beyond your estimated current range. Additional charging or route adjustment is required."
        }
    }
}

public struct ScoreBreakdown: Equatable, Sendable {
    public let distanceScore: Double    // Weight 25%
    public let waitTimeScore: Double    // Weight 25%
    public let availabilityScore: Double// Weight 20%
    public let speedScore: Double       // Weight 20%
    public let costScore: Double        // Weight 10%
    public let compositeScore: Double

    public init(
        distanceScore: Double,
        waitTimeScore: Double,
        availabilityScore: Double,
        speedScore: Double,
        costScore: Double,
        compositeScore: Double
    ) {
        self.distanceScore = distanceScore
        self.waitTimeScore = waitTimeScore
        self.availabilityScore = availabilityScore
        self.speedScore = speedScore
        self.costScore = costScore
        self.compositeScore = compositeScore
    }
}

public struct RecommendationResult: Equatable, Sendable {
    public let bestStation: ChargingStation?
    public let reachabilityStatus: ReachabilityStatus
    public let whyRecommended: String
    public let alternativeStation: ChargingStation?
    public let alternativeReachability: ReachabilityStatus?
    public let scoreBreakdown: ScoreBreakdown?

    public init(
        bestStation: ChargingStation?,
        reachabilityStatus: ReachabilityStatus,
        whyRecommended: String,
        alternativeStation: ChargingStation? = nil,
        alternativeReachability: ReachabilityStatus? = nil,
        scoreBreakdown: ScoreBreakdown? = nil
    ) {
        self.bestStation = bestStation
        self.reachabilityStatus = reachabilityStatus
        self.whyRecommended = whyRecommended
        self.alternativeStation = alternativeStation
        self.alternativeReachability = alternativeReachability
        self.scoreBreakdown = scoreBreakdown
    }
}
