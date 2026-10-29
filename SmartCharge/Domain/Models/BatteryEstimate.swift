//
//  BatteryEstimate.swift
//  SmartCharge
//

import Foundation

/// Encapsulates EV battery range calculations based on theoretical range, current charge level,
/// and a user-selected safety reserve.
///
/// Blueprint Model:
/// - currentEstimatedRange = theoreticalRange * batteryFraction
/// - safePlanningRange = currentEstimatedRange * (1.0 - safetyReserveFraction)
///
/// Note: Real-world vehicle range varies with temperature, elevation, speed, terrain, and driving style.
/// All distances are estimates for trip-planning margins rather than guaranteed physical metrics.
public struct BatteryEstimate: Equatable, Sendable {
    /// Nominal WLTP or manufacturer range in kilometres at 100% state of charge.
    public let theoreticalRangeKm: Double

    /// Current battery charge percentage (value between 0.0 and 1.0, e.g. 0.85 for 85%).
    public let batteryPercentage: Double

    /// Configurable safety buffer percentage (value between 0.0 and 1.0, e.g. 0.15 for 15%).
    public let safetyReservePercentage: Double

    /// Theoretical maximum energy capacity in kilowatt-hours (optional if unknown).
    public let batteryCapacityKWh: Double?

    public init(
        theoreticalRangeKm: Double,
        batteryPercentage: Double,
        safetyReservePercentage: Double = 0.15,
        batteryCapacityKWh: Double? = nil
    ) {
        self.theoreticalRangeKm = max(0, theoreticalRangeKm)
        self.batteryPercentage = min(max(0.0, batteryPercentage), 1.0)
        self.safetyReservePercentage = min(max(0.0, safetyReservePercentage), 0.9)
        self.batteryCapacityKWh = batteryCapacityKWh
    }

    /// Current estimated reachable range before hitting 0% battery.
    /// Formula: R * B
    public var currentEstimatedRangeKm: Double {
        theoreticalRangeKm * batteryPercentage
    }

    /// Safe planning range that preserves the user's chosen safety margin buffer.
    /// Formula: currentEstimatedRange * (1 - S)
    public var safePlanningRangeKm: Double {
        currentEstimatedRangeKm * (1.0 - safetyReservePercentage)
    }

    /// The distance buffer dedicated to the safety reserve.
    public var safetyBufferKm: Double {
        currentEstimatedRangeKm * safetyReservePercentage
    }

    /// Estimated usable energy in kWh based on current state of charge and battery capacity.
    public var estimatedUsableEnergyKWh: Double? {
        guard let capacity = batteryCapacityKWh else { return nil }
        return capacity * batteryPercentage * (1.0 - safetyReservePercentage)
    }
}
