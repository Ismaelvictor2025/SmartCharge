//
//  CalculateVehicleRangeUseCase.swift
//  SmartCharge
//

import Foundation

public protocol CalculateVehicleRangeUseCaseProtocol: Sendable {
    func execute(
        theoreticalRangeKm: Double,
        batteryPercentage: Double,
        safetyReservePercentage: Double,
        batteryCapacityKWh: Double?
    ) throws -> BatteryEstimate
}

public struct CalculateVehicleRangeUseCase: CalculateVehicleRangeUseCaseProtocol {
    public init() {}

    public func execute(
        theoreticalRangeKm: Double,
        batteryPercentage: Double,
        safetyReservePercentage: Double = 0.15,
        batteryCapacityKWh: Double? = nil
    ) throws -> BatteryEstimate {
        guard theoreticalRangeKm > 0 else {
            throw RangeCalculationError.invalidTheoreticalRange(theoreticalRangeKm)
        }
        guard batteryPercentage >= 0.0 && batteryPercentage <= 1.0 else {
            throw RangeCalculationError.invalidBatteryPercentage(batteryPercentage)
        }
        guard safetyReservePercentage >= 0.0 && safetyReservePercentage <= 0.9 else {
            throw RangeCalculationError.invalidSafetyReserve(safetyReservePercentage)
        }

        return BatteryEstimate(
            theoreticalRangeKm: theoreticalRangeKm,
            batteryPercentage: batteryPercentage,
            safetyReservePercentage: safetyReservePercentage,
            batteryCapacityKWh: batteryCapacityKWh
        )
    }
}
