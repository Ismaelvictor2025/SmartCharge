//
//  MultiStopRoutePlanner.swift
//  SmartCharge
//

import Foundation

public struct PlannedChargingStop: Identifiable, Hashable, Sendable {
    public let id: String
    public let station: ChargingStation
    public let legNumber: Int
    public let distanceFromOriginKm: Double
    public let legDistanceKm: Double
    public let arrivalBatteryPercent: Double
    public let departureBatteryPercent: Double
    public let estimatedChargeTimeMinutes: Int
    public let reachabilityStatus: ReachabilityStatus
    public let rationale: String

    public init(
        station: ChargingStation,
        legNumber: Int,
        distanceFromOriginKm: Double,
        legDistanceKm: Double,
        arrivalBatteryPercent: Double,
        departureBatteryPercent: Double = 0.85,
        estimatedChargeTimeMinutes: Int,
        reachabilityStatus: ReachabilityStatus,
        rationale: String
    ) {
        self.id = "\(station.id)_leg_\(legNumber)"
        self.station = station
        self.legNumber = legNumber
        self.distanceFromOriginKm = distanceFromOriginKm
        self.legDistanceKm = legDistanceKm
        self.arrivalBatteryPercent = max(0.0, arrivalBatteryPercent)
        self.departureBatteryPercent = departureBatteryPercent
        self.estimatedChargeTimeMinutes = max(10, estimatedChargeTimeMinutes)
        self.reachabilityStatus = reachabilityStatus
        self.rationale = rationale
    }
}

public struct InfrastructureGap: Equatable, Sendable {
    public let fromLocationName: String
    public let toLocationName: String
    public let gapDistanceKm: Double
    public let maxVehicleRangeKm: Double
    public let deficitKm: Double
    public let explanation: String

    public init(
        fromLocationName: String,
        toLocationName: String,
        gapDistanceKm: Double,
        maxVehicleRangeKm: Double,
        explanation: String
    ) {
        self.fromLocationName = fromLocationName
        self.toLocationName = toLocationName
        self.gapDistanceKm = gapDistanceKm
        self.maxVehicleRangeKm = maxVehicleRangeKm
        self.deficitKm = max(0.0, gapDistanceKm - maxVehicleRangeKm)
        self.explanation = explanation
    }
}

public struct MultiStopPlanResult: Equatable, Sendable {
    public let isFeasible: Bool
    public let plannedStops: [PlannedChargingStop]
    public let totalChargingTimeMinutes: Int
    public let infrastructureGaps: [InfrastructureGap]
    public let routeSegments: [RouteSegment]
    public let summary: String

    public init(
        isFeasible: Bool,
        plannedStops: [PlannedChargingStop],
        totalChargingTimeMinutes: Int,
        infrastructureGaps: [InfrastructureGap],
        routeSegments: [RouteSegment],
        summary: String
    ) {
        self.isFeasible = isFeasible
        self.plannedStops = plannedStops
        self.totalChargingTimeMinutes = totalChargingTimeMinutes
        self.infrastructureGaps = infrastructureGaps
        self.routeSegments = routeSegments
        self.summary = summary
    }
}

public protocol MultiStopRoutePlannerProtocol: Sendable {
    func planChargingStops(
        totalDistanceKm: Double,
        originName: String,
        destinationName: String,
        vehicle: Vehicle,
        initialBatteryPercent: Double,
        safetyReservePercent: Double,
        targetRechargePercent: Double,
        preference: RoutePreference,
        stationsAlongRoute: [ChargingStation]
    ) -> MultiStopPlanResult
}

public struct MultiStopRoutePlanner: MultiStopRoutePlannerProtocol {
    private let recommendUseCase: RecommendChargingStopUseCaseProtocol

    public init(recommendUseCase: RecommendChargingStopUseCaseProtocol = RecommendChargingStopUseCase()) {
        self.recommendUseCase = recommendUseCase
    }

    public func planChargingStops(
        totalDistanceKm: Double,
        originName: String,
        destinationName: String,
        vehicle: Vehicle,
        initialBatteryPercent: Double,
        safetyReservePercent: Double = 0.15,
        targetRechargePercent: Double = 0.85,
        preference: RoutePreference = .safest,
        stationsAlongRoute: [ChargingStation]
    ) -> MultiStopPlanResult {
        // Step 1: Filter to compatible & operational stations
        let compatible = stationsAlongRoute.filter { station in
            station.isOperational && station.supportsAny(of: vehicle.supportedConnectors)
        }.sorted { ($0.distanceKm ?? 0) < ($1.distanceKm ?? 0) }

        // Initial ranges
        let initialPhysicalRange = vehicle.theoreticalRangeKm * initialBatteryPercent
        let initialSafeRange = initialPhysicalRange * (1.0 - safetyReservePercent)

        // Case 1: Direct route without stops
        if totalDistanceKm <= initialSafeRange {
            let singleSegment = RouteSegment(
                startLocationName: originName,
                endLocationName: destinationName,
                distanceKm: totalDistanceKm,
                availableChargingCount: compatible.count,
                maxPowerAlongSegmentKW: compatible.map(\.maxPowerKW).max() ?? 0
            )
            let margin = Int(initialSafeRange - totalDistanceKm)
            return MultiStopPlanResult(
                isFeasible: true,
                plannedStops: [],
                totalChargingTimeMinutes: 0,
                infrastructureGaps: [],
                routeSegments: [singleSegment],
                summary: "Direct route achievable on starting battery with ~\(margin) km safety buffer remaining."
            )
        }

        // Case 2: Multi-stop iterative planning
        var plannedStops: [PlannedChargingStop] = []
        var segments: [RouteSegment] = []
        var gaps: [InfrastructureGap] = []
        var visitedIds: Set<String> = []

        var currentPositionKm = 0.0
        var currentLegStartName = originName
        var currentBattery = initialBatteryPercent
        var legNumber = 1
        var totalChargeTime = 0

        while (currentPositionKm + (vehicle.theoreticalRangeKm * currentBattery * (1.0 - safetyReservePercent))) < totalDistanceKm {
            let availablePhysicalRange = vehicle.theoreticalRangeKm * currentBattery
            let availableSafeRange = availablePhysicalRange * (1.0 - safetyReservePercent)
            let remainingDistance = totalDistanceKm - currentPositionKm

            // Check if destination is reachable directly from current position
            if remainingDistance <= availableSafeRange {
                segments.append(RouteSegment(
                    startLocationName: currentLegStartName,
                    endLocationName: destinationName,
                    distanceKm: remainingDistance,
                    availableChargingCount: 1,
                    maxPowerAlongSegmentKW: 150.0
                ))
                break
            }

            // Find stations ahead of current position and reachable
            let candidateStations = compatible.filter { station in
                guard let dist = station.distanceKm else { return false }
                guard dist > currentPositionKm + 15.0 else { return false } // Must be ahead by at least 15km
                guard !visitedIds.contains(station.id) else { return false }
                let legDist = dist - currentPositionKm
                return legDist <= availablePhysicalRange // Physically reachable
            }

            guard !candidateStations.isEmpty else {
                // Infrastructure gap detected!
                let nextStationAhead = compatible.first(where: { ($0.distanceKm ?? 0) > currentPositionKm })
                let gapEndName = nextStationAhead?.name ?? destinationName
                let gapDistance = (nextStationAhead?.distanceKm ?? totalDistanceKm) - currentPositionKm

                let gap = InfrastructureGap(
                    fromLocationName: currentLegStartName,
                    toLocationName: gapEndName,
                    gapDistanceKm: gapDistance,
                    maxVehicleRangeKm: availablePhysicalRange,
                    explanation: "Route segment between '\(currentLegStartName)' and '\(gapEndName)' (\(Int(gapDistance)) km) exceeds maximum battery range (\(Int(availablePhysicalRange)) km) with no compatible charging infrastructure."
                )
                gaps.append(gap)

                segments.append(RouteSegment(
                    startLocationName: currentLegStartName,
                    endLocationName: gapEndName,
                    distanceKm: gapDistance,
                    availableChargingCount: 0,
                    maxPowerAlongSegmentKW: 0
                ))
                break
            }

            // Evaluate reachability & best station in candidate window
            // Prioritise stations within safe range; fallback to caution stations if none in safe range
            let safeCandidates = candidateStations.filter { ($0.distanceKm! - currentPositionKm) <= availableSafeRange }
            let pool = safeCandidates.isEmpty ? candidateStations : safeCandidates

            // Score candidate stations in pool
            let bestCandidate = pool.max { s1, s2 in
                let d1 = s1.distanceKm! - currentPositionKm
                let d2 = s2.distanceKm! - currentPositionKm
                let p1 = s1.maxPowerKW
                let p2 = s2.maxPowerKW

                switch preference {
                case .safest:
                    // Prefer stations with verified live status and solid safety buffer
                    let statusScore1 = s1.isOperational ? 50.0 : 0.0
                    let statusScore2 = s2.isOperational ? 50.0 : 0.0
                    return (d1 * 0.4 + p1 * 0.2 + statusScore1) < (d2 * 0.4 + p2 * 0.2 + statusScore2)
                case .fastestCharging:
                    // Strongly prefer higher kW charging speed
                    return (p1 * 0.7 + d1 * 0.3) < (p2 * 0.7 + d2 * 0.3)
                case .balanced:
                    // Balance distance coverage and charging power
                    return (d1 * 0.5 + p1 * 0.5) < (d2 * 0.5 + p2 * 0.5)
                }
            }!

            let stationDist = bestCandidate.distanceKm!
            let legDistance = stationDist - currentPositionKm

            // Arrival battery percentage
            let fractionUsed = legDistance / vehicle.theoreticalRangeKm
            let arrivalBattery = max(0.05, currentBattery - fractionUsed)

            // Charging time calculation:
            // Energy needed to go from arrivalBattery to targetRechargePercent (e.g. 85%)
            let targetRecharge = max(targetRechargePercent, arrivalBattery + 0.20)
            let energyNeededKWh = vehicle.batteryCapacityKWh * (targetRecharge - arrivalBattery)
            let effectivePowerKW = min(bestCandidate.maxPowerKW, 200.0) * 0.85 // Realistic taper factor
            let chargeMinutes = Int(ceil((energyNeededKWh / max(effectivePowerKW, 20.0)) * 60.0))

            // Reachability status
            let reachability: ReachabilityStatus
            if legDistance <= availableSafeRange {
                reachability = .reachableWithinSafeRange(marginRemainingKm: availableSafeRange - legDistance)
            } else {
                reachability = .reachableCautionBeyondReserve(
                    excessOverSafeKm: legDistance - availableSafeRange,
                    remainingPhysicalBufferKm: availablePhysicalRange - legDistance
                )
            }

            let stop = PlannedChargingStop(
                station: bestCandidate,
                legNumber: legNumber,
                distanceFromOriginKm: stationDist,
                legDistanceKm: legDistance,
                arrivalBatteryPercent: arrivalBattery,
                departureBatteryPercent: targetRecharge,
                estimatedChargeTimeMinutes: chargeMinutes,
                reachabilityStatus: reachability,
                rationale: "\(Int(bestCandidate.maxPowerKW)) kW \(bestCandidate.operatorName) hub selected under \(preference.rawValue) strategy. Arrive with ~\(Int(arrivalBattery * 100))% charge."
            )

            plannedStops.append(stop)
            visitedIds.insert(bestCandidate.id)
            totalChargeTime += chargeMinutes

            segments.append(RouteSegment(
                startLocationName: currentLegStartName,
                endLocationName: bestCandidate.name,
                distanceKm: legDistance,
                availableChargingCount: pool.count,
                maxPowerAlongSegmentKW: bestCandidate.maxPowerKW
            ))

            // Advance state
            currentPositionKm = stationDist
            currentLegStartName = bestCandidate.name
            currentBattery = targetRecharge
            legNumber += 1

            // Safeguard against infinite loops
            if legNumber > 8 {
                break
            }
        }

        // Final segment if successfully reached destination
        if gaps.isEmpty && currentPositionKm < totalDistanceKm {
            let finalLegDistance = totalDistanceKm - currentPositionKm
            segments.append(RouteSegment(
                startLocationName: currentLegStartName,
                endLocationName: destinationName,
                distanceKm: finalLegDistance,
                availableChargingCount: 1,
                maxPowerAlongSegmentKW: 150.0
            ))
        }

        let isFeasible = gaps.isEmpty
        let summary: String
        if isFeasible {
            summary = "Route planned with \(plannedStops.count) charging stop\(plannedStops.count == 1 ? "" : "s") (~\(totalChargeTime) min total charge time). All legs within reachable limits."
        } else {
            summary = "Route cannot be completed safely: detected \(gaps.count) infrastructure gap\(gaps.count == 1 ? "" : "s") where distance between fast chargers exceeds vehicle range."
        }

        return MultiStopPlanResult(
            isFeasible: isFeasible,
            plannedStops: plannedStops,
            totalChargingTimeMinutes: totalChargeTime,
            infrastructureGaps: gaps,
            routeSegments: segments,
            summary: summary
        )
    }
}
