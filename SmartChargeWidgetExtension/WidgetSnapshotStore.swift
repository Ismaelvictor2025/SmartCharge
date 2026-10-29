//
//  WidgetSnapshotStore.swift
//  SmartChargeWidgetExtension
//
//  Created by Vicky Neves Rohr on 29/10/2026.
//

import Foundation
import WidgetKit

public protocol WidgetSnapshotStoreProtocol: Sendable {
    func saveSnapshot(_ snapshot: WidgetJourneySnapshot)
    func loadSnapshot() -> WidgetJourneySnapshot
    func clearSnapshot()
}

public final class WidgetSnapshotStore: WidgetSnapshotStoreProtocol, @unchecked Sendable {
    public static let shared = WidgetSnapshotStore()

    public static let appGroupSuiteName = "group.com.vicky.SmartCharge"
    public static let snapshotKey = "smartcharge.widget.journeySnapshot"

    private let userDefaults: UserDefaults

    public init(suiteName: String? = appGroupSuiteName) {
        if let suite = suiteName, let defaults = UserDefaults(suiteName: suite) {
            self.userDefaults = defaults
        } else {
            self.userDefaults = UserDefaults.standard
        }
    }

    public func saveSnapshot(_ snapshot: WidgetJourneySnapshot) {
        do {
            let data = try JSONEncoder().encode(snapshot)
            userDefaults.set(data, forKey: Self.snapshotKey)
            userDefaults.synchronize()

            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("WidgetSnapshotStore: Failed to encode snapshot - \(error)")
        }
    }

    public func loadSnapshot() -> WidgetJourneySnapshot {
        guard let data = userDefaults.data(forKey: Self.snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetJourneySnapshot.self, from: data) else {
            return .defaultSample
        }
        return snapshot
    }

    public func clearSnapshot() {
        userDefaults.removeObject(forKey: Self.snapshotKey)
        userDefaults.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
