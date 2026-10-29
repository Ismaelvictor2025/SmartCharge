//
//  WidgetJourneySnapshot.swift
//  SmartChargeWidgetExtension
//
//  Created by Vicky Neves Rohr on 29/10/2026.
//

import Foundation

public struct WidgetJourneySnapshot: Codable, Equatable, Sendable {
    public let vehicleName: String
    public let batteryPercentage: Double
    public let currentEstimatedRangeKm: Double
    public let safePlanningRangeKm: Double
    public let safetyBufferKm: Double
    public let safetyReservePercentage: Double
    public let originName: String
    public let destinationName: String
    public let routeDistanceKm: Double
    public let isDirectSafeTrip: Bool
    public let readinessStatusText: String
    public let overallRiskLevel: String
    public let plannedStopsCount: Int
    public let lastUpdated: Date

    public init(
        vehicleName: String,
        batteryPercentage: Double,
        currentEstimatedRangeKm: Double,
        safePlanningRangeKm: Double,
        safetyBufferKm: Double,
        safetyReservePercentage: Double,
        originName: String,
        destinationName: String,
        routeDistanceKm: Double,
        isDirectSafeTrip: Bool,
        readinessStatusText: String,
        overallRiskLevel: String,
        plannedStopsCount: Int,
        lastUpdated: Date = Date()
    ) {
        self.vehicleName = vehicleName
        self.batteryPercentage = batteryPercentage
        self.currentEstimatedRangeKm = currentEstimatedRangeKm
        self.safePlanningRangeKm = safePlanningRangeKm
        self.safetyBufferKm = safetyBufferKm
        self.safetyReservePercentage = safetyReservePercentage
        self.originName = originName
        self.destinationName = destinationName
        self.routeDistanceKm = routeDistanceKm
        self.isDirectSafeTrip = isDirectSafeTrip
        self.readinessStatusText = readinessStatusText
        self.overallRiskLevel = overallRiskLevel
        self.plannedStopsCount = plannedStopsCount
        self.lastUpdated = lastUpdated
    }

    public static var defaultSample: WidgetJourneySnapshot {
        WidgetJourneySnapshot(
            vehicleName: "Polestar 2 Long Range",
            batteryPercentage: 0.85,
            currentEstimatedRangeKm: 425.0,
            safePlanningRangeKm: 361.25,
            safetyBufferKm: 63.75,
            safetyReservePercentage: 0.15,
            originName: "Sydney CBD",
            destinationName: "Canberra Civic",
            routeDistanceKm: 286.0,
            isDirectSafeTrip: true,
            readinessStatusText: "Direct Safe Trip",
            overallRiskLevel: "LOW",
            plannedStopsCount: 0,
            lastUpdated: Date()
        )
    }

    public static var emptyPlaceholder: WidgetJourneySnapshot {
        WidgetJourneySnapshot(
            vehicleName: "Electric Vehicle",
            batteryPercentage: 0.80,
            currentEstimatedRangeKm: 400.0,
            safePlanningRangeKm: 340.0,
            safetyBufferKm: 60.0,
            safetyReservePercentage: 0.15,
            originName: "Departure Point",
            destinationName: "Arrival Point",
            routeDistanceKm: 0.0,
            isDirectSafeTrip: true,
            readinessStatusText: "Ready to Plan",
            overallRiskLevel: "LOW",
            plannedStopsCount: 0,
            lastUpdated: Date()
        )
    }
}
