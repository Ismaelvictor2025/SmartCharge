//
//  DomainErrors.swift
//  SmartCharge
//

import Foundation

public enum RangeCalculationError: LocalizedError, Equatable {
    case invalidTheoreticalRange(Double)
    case invalidBatteryPercentage(Double)
    case invalidSafetyReserve(Double)

    public var errorDescription: String? {
        switch self {
        case .invalidTheoreticalRange(let val):
            return "Theoretical range must be greater than 0 km (entered: \(val) km)."
        case .invalidBatteryPercentage(let val):
            return "Battery percentage must be between 0% and 100% (entered: \(Int(val * 100))%)."
        case .invalidSafetyReserve(let val):
            return "Safety reserve must be between 0% and 90% (entered: \(Int(val * 100))%)."
        }
    }
}

public enum JourneyPlanError: LocalizedError, Equatable {
    case missingOrigin
    case missingDestination
    case sameOriginAndDestination
    case vehicleNotSelected
    case unreachableWithoutCharging(deficitKm: Double)
    case routingUnavailable(String)

    public var errorDescription: String? {
        switch self {
        case .missingOrigin:
            return "Please enter a departure origin."
        case .missingDestination:
            return "Please enter an arrival destination."
        case .sameOriginAndDestination:
            return "Origin and destination cannot be identical."
        case .vehicleNotSelected:
            return "Please select an electric vehicle profile before planning."
        case .unreachableWithoutCharging(let deficitKm):
            return "Destination is \(Int(deficitKm)) km beyond safe range. A charging stop is required."
        case .routingUnavailable(let reason):
            return "Road routing is temporarily unavailable: \(reason)"
        }
    }
}

public enum StationSearchError: LocalizedError, Equatable {
    case networkUnavailable
    case apiRateLimited
    case invalidResponse
    case noStationsFound(query: String)
    case noCompatibleConnector(required: String)

    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Internet connection offline. Showing cached station information."
        case .apiRateLimited:
            return "Station directory rate limit exceeded. Please retry in a few moments."
        case .invalidResponse:
            return "Received an unexpected response from the station directory."
        case .noStationsFound(let query):
            return "No charging stations found matching '\(query)'."
        case .noCompatibleConnector(let req):
            return "No charging stations found supporting your vehicle's connector (\(req))."
        }
    }
}

public enum StorageError: LocalizedError, Equatable {
    case notFound
    case saveFailed(String)
    case deleteFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notFound:
            return "Requested item was not found in local storage."
        case .saveFailed(let details):
            return "Failed to save to local database: \(details)"
        case .deleteFailed(let details):
            return "Failed to delete from local database: \(details)"
        }
    }
}
