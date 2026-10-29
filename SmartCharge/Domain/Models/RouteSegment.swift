//
//  RouteSegment.swift
//  SmartCharge
//

import Foundation

public struct RouteSegment: Identifiable, Hashable, Sendable {
    public let id: String
    public let startLocationName: String
    public let endLocationName: String
    public let distanceKm: Double
    public let availableChargingCount: Int
    public let maxPowerAlongSegmentKW: Double

    public init(
        id: String = UUID().uuidString,
        startLocationName: String,
        endLocationName: String,
        distanceKm: Double,
        availableChargingCount: Int,
        maxPowerAlongSegmentKW: Double
    ) {
        self.id = id
        self.startLocationName = startLocationName
        self.endLocationName = endLocationName
        self.distanceKm = distanceKm
        self.availableChargingCount = availableChargingCount
        self.maxPowerAlongSegmentKW = maxPowerAlongSegmentKW
    }
}

public enum RiskLevel: String, CaseIterable, Codable, Comparable, Sendable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case critical = "CRITICAL"

    public var title: String {
        rawValue
    }

    public var description: String {
        switch self {
        case .low: return "Route is well covered with charging opportunities within safe planning range."
        case .medium: return "Moderate distance between chargers. Monitor battery reserve closely."
        case .high: return "Long distance segment exceeds safe buffer. Charging stop required."
        case .critical: return "Route gap exceeds current estimated physical range. Additional stops essential."
        }
    }

    private var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .critical: return 3
        }
    }

    public static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

public struct RouteRiskResult: Equatable, Sendable {
    public let overallRiskLevel: RiskLevel
    public let riskScore: Double // 0 (safest) to 100 (most critical)
    public let highRiskSegmentsCount: Int
    public let criticalSegmentsCount: Int
    public let infrastructureGapsCount: Int
    public let warnings: [String]
    public let summary: String

    public init(
        overallRiskLevel: RiskLevel,
        riskScore: Double,
        highRiskSegmentsCount: Int,
        criticalSegmentsCount: Int,
        infrastructureGapsCount: Int,
        warnings: [String],
        summary: String
    ) {
        self.overallRiskLevel = overallRiskLevel
        self.riskScore = min(max(0, riskScore), 100)
        self.highRiskSegmentsCount = highRiskSegmentsCount
        self.criticalSegmentsCount = criticalSegmentsCount
        self.infrastructureGapsCount = infrastructureGapsCount
        self.warnings = warnings
        self.summary = summary
    }

    public static var optimal: RouteRiskResult {
        RouteRiskResult(
            overallRiskLevel: .low,
            riskScore: 12.0,
            highRiskSegmentsCount: 0,
            criticalSegmentsCount: 0,
            infrastructureGapsCount: 0,
            warnings: [],
            summary: "Route is within safe planning range with abundant compatible fast chargers."
        )
    }
}
