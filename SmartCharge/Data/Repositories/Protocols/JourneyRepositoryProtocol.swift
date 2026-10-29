//
//  JourneyRepositoryProtocol.swift
//  SmartCharge
//

import Foundation

public protocol JourneyRepositoryProtocol: Sendable {
    func fetchSavedJourneys() async throws -> [Journey]
    func saveJourney(_ journey: Journey) async throws
    func deleteJourney(id: UUID) async throws
}
