//
//  RangeCalculationTests.swift
//  SmartChargeTests
//

import Testing
@testable import SmartCharge

@Suite("Battery Range Calculation Tests")
struct RangeCalculationTests {
    let useCase = CalculateVehicleRangeUseCase()

    @Test("Blueprint Exact Example: 500 km at 85% battery with 15% safety reserve")
    func blueprintExampleCalculation() throws {
        // Given
        let theoreticalRange = 500.0
        let battery = 0.85
        let reserve = 0.15

        // When
        let estimate = try useCase.execute(
            theoreticalRangeKm: theoreticalRange,
            batteryPercentage: battery,
            safetyReservePercentage: reserve,
            batteryCapacityKWh: 78.0
        )

        // Then
        // Step 1: currentRange = 500 * 0.85 = 425.0 km
        #expect(estimate.currentEstimatedRangeKm == 425.0)

        // Step 2: safeRange = 425 * (1 - 0.15) = 361.25 km
        #expect(estimate.safePlanningRangeKm == 361.25)

        // Step 3: safetyBuffer = 425 * 0.15 = 63.75 km
        #expect(estimate.safetyBufferKm == 63.75)
    }

    @Test("Blueprint Example: 400 km theoretical at 100% battery with 15% safety margin")
    func fullyCharged400KmWith15PercentMargin() throws {
        // Given
        let theoreticalRange = 400.0
        let battery = 1.0
        let reserve = 0.15

        // When
        let estimate = try useCase.execute(
            theoreticalRangeKm: theoreticalRange,
            batteryPercentage: battery,
            safetyReservePercentage: reserve
        )

        // Then: 400 * 1.0 = 400 km physical, safe = 400 * 0.85 = 340 km
        #expect(estimate.currentEstimatedRangeKm == 400.0)
        #expect(estimate.safePlanningRangeKm == 340.0)
        #expect(estimate.safetyBufferKm == 60.0)
    }

    @Test("Zero battery handling yields zero estimated and safe range")
    func zeroBatteryHandling() throws {
        let estimate = try useCase.execute(
            theoreticalRangeKm: 450.0,
            batteryPercentage: 0.0,
            safetyReservePercentage: 0.15
        )

        #expect(estimate.currentEstimatedRangeKm == 0.0)
        #expect(estimate.safePlanningRangeKm == 0.0)
        #expect(estimate.safetyBufferKm == 0.0)
    }

    @Test("Negative or zero theoretical range throws RangeCalculationError")
    func invalidTheoreticalRange() {
        #expect(throws: RangeCalculationError.self) {
            _ = try useCase.execute(
                theoreticalRangeKm: 0.0,
                batteryPercentage: 0.80,
                safetyReservePercentage: 0.15
            )
        }

        #expect(throws: RangeCalculationError.self) {
            _ = try useCase.execute(
                theoreticalRangeKm: -100.0,
                batteryPercentage: 0.80,
                safetyReservePercentage: 0.15
            )
        }
    }

    @Test("Battery percentage outside [0.0, 1.0] throws RangeCalculationError")
    func invalidBatteryPercentage() {
        #expect(throws: RangeCalculationError.self) {
            _ = try useCase.execute(
                theoreticalRangeKm: 400.0,
                batteryPercentage: 1.5,
                safetyReservePercentage: 0.15
            )
        }

        #expect(throws: RangeCalculationError.self) {
            _ = try useCase.execute(
                theoreticalRangeKm: 400.0,
                batteryPercentage: -0.1,
                safetyReservePercentage: 0.15
            )
        }
    }

    @Test("Configurable safety reserve options: 10%, 15%, 20%, 25%")
    func configurableReserveOptions() throws {
        let theoretical = 500.0
        let battery = 0.80 // 400 km physical

        let est10 = try useCase.execute(theoreticalRangeKm: theoretical, batteryPercentage: battery, safetyReservePercentage: 0.10)
        let est15 = try useCase.execute(theoreticalRangeKm: theoretical, batteryPercentage: battery, safetyReservePercentage: 0.15)
        let est20 = try useCase.execute(theoreticalRangeKm: theoretical, batteryPercentage: battery, safetyReservePercentage: 0.20)
        let est25 = try useCase.execute(theoreticalRangeKm: theoretical, batteryPercentage: battery, safetyReservePercentage: 0.25)

        #expect(est10.safePlanningRangeKm == 360.0) // 400 * 0.90
        #expect(est15.safePlanningRangeKm == 340.0) // 400 * 0.85
        #expect(est20.safePlanningRangeKm == 320.0) // 400 * 0.80
        #expect(est25.safePlanningRangeKm == 300.0) // 400 * 0.75
    }
}
