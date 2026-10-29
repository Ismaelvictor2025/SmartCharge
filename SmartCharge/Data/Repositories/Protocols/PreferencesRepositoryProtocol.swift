//
//  PreferencesRepositoryProtocol.swift
//  SmartCharge
//

import Foundation

public protocol PreferencesRepositoryProtocol: Sendable {
    func fetchPreferences() async throws -> UserPreferences
    func savePreferences(_ preferences: UserPreferences) async throws
    func resetToDefaults() async throws -> UserPreferences
}
