//
//  SaveJourneyUseCase.swift
//  SmartCharge
//

import Foundation

public protocol SaveJourneyUseCaseProtocol: Sendable {
    func execute(_ journey: Journey) async throws
}

public struct SaveJourneyUseCase: SaveJourneyUseCaseProtocol {
    private let repository: JourneyRepositoryProtocol

    public init(repository: JourneyRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ journey: Journey) async throws {
        try await repository.saveJourney(journey)
    }
}
