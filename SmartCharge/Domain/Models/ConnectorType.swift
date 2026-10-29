//
//  ConnectorType.swift
//  SmartCharge
//

import Foundation

public enum ConnectorType: String, CaseIterable, Codable, Identifiable, Sendable {
    case ccs2 = "CCS2"
    case type2 = "Type 2"
    case chademo = "CHAdeMO"
    case tesla = "Tesla (NACS/Proprietary)"
    case j1772 = "Type 1 (J1772)"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .ccs2: return "CCS2 (Combo 2)"
        case .type2: return "Type 2 (Mennekes)"
        case .chademo: return "CHAdeMO"
        case .tesla: return "Tesla Supercharger"
        case .j1772: return "Type 1 (J1772)"
        }
    }

    public var iconName: String {
        switch self {
        case .ccs2, .type2: return "bolt.car.fill"
        case .tesla: return "bolt.shield.fill"
        case .chademo: return "battery.100.bolt"
        case .j1772: return "powerplug.fill"
        }
    }

    public static func parseCommaSeparated(_ string: String) -> Set<ConnectorType> {
        let parts = string.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var set: Set<ConnectorType> = []
        for part in parts {
            if let matched = ConnectorType.allCases.first(where: {
                $0.rawValue.caseInsensitiveCompare(part) == .orderedSame ||
                $0.id.caseInsensitiveCompare(part) == .orderedSame ||
                ($0 == .ccs2 && part.uppercased().contains("CCS")) ||
                ($0 == .type2 && (part.uppercased().contains("TYPE 2") || part.uppercased().contains("TYPE2"))) ||
                ($0 == .chademo && part.uppercased().contains("CHADEMO")) ||
                ($0 == .tesla && part.uppercased().contains("TESLA"))
            }) {
                set.insert(matched)
            }
        }
        return set.isEmpty ? [.ccs2] : set
    }
}
