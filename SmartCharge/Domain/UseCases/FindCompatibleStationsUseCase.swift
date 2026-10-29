//
//  FindCompatibleStationsUseCase.swift
//  SmartCharge
//

import Foundation

public protocol FindCompatibleStationsUseCaseProtocol: Sendable {
    func execute(
        stations: [ChargingStation],
        for vehicle: Vehicle,
        minPowerKW: Double?,
        requireOperational: Bool
    ) -> [ChargingStation]
}

public struct FindCompatibleStationsUseCase: FindCompatibleStationsUseCaseProtocol {
    public init() {}

    public func execute(
        stations: [ChargingStation],
        for vehicle: Vehicle,
        minPowerKW: Double? = nil,
        requireOperational: Bool = true
    ) -> [ChargingStation] {
        stations.filter { station in
            // Filter operational status
            if requireOperational && !station.isOperational {
                return false
            }

            // Filter connector compatibility
            let isCompatible = station.supportsAny(of: vehicle.supportedConnectors)
            guard isCompatible else { return false }

            // Filter minimum power if specified
            if let minPower = minPowerKW, station.maxPowerKW < minPower {
                return false
            }

            return true
        }
    }
}
