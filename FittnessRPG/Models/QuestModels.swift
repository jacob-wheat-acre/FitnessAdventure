
//
//  QuestModels.swift
//  FittnessRPG
//
//  Created by Jacob Whitaker on 12/25/25.
//

import Foundation

// MARK: - Combat / Attacks

enum DamageType: String, Codable, CaseIterable {
    case physical
    case magical
    case trick
}

struct AttackDefinition: Identifiable, Codable, Hashable {
    let id: String                 // stable ID for persistence (e.g. "knight.punch")
    let name: String               // display
    let damageType: DamageType
    let requiredLevel: Int
    let power: Int                 // damage dealt
    let maxMana: Int               // max uses (mana cap)
}

enum AttackCatalog {
    static func attacks(for cls: PlayerClass) -> [AttackDefinition] {
        switch cls {
        case .Wizard:
            return [
                AttackDefinition(id: "wizard.spark", name: "Spark", damageType: .magical, requiredLevel: 1, power: 8, maxMana: 6),
                AttackDefinition(id: "wizard.firebolt", name: "Firebolt", damageType: .magical, requiredLevel: 2, power: 14, maxMana: 6),
                AttackDefinition(id: "wizard.ice_shard", name: "Ice Shard", damageType: .magical, requiredLevel: 4, power: 22, maxMana: 5),
                AttackDefinition(id: "wizard.arc_blast", name: "Arc Blast", damageType: .magical, requiredLevel: 6, power: 32, maxMana: 4),
                AttackDefinition(id: "wizard.meteor", name: "Meteor", damageType: .magical, requiredLevel: 9, power: 50, maxMana: 3)
            ]

        case .Knight:
            return [
                AttackDefinition(id: "knight.punch", name: "Punch", damageType: .physical, requiredLevel: 1, power: 10, maxMana: 7),
                AttackDefinition(id: "knight.kick", name: "Kick", damageType: .physical, requiredLevel: 2, power: 16, maxMana: 6),
                AttackDefinition(id: "knight.power_strike", name: "Power Strike", damageType: .physical, requiredLevel: 4, power: 26, maxMana: 5),
                AttackDefinition(id: "knight.shield_bash", name: "Shield Bash", damageType: .physical, requiredLevel: 6, power: 36, maxMana: 4),
                AttackDefinition(id: "knight.execution", name: "Execution", damageType: .physical, requiredLevel: 9, power: 55, maxMana: 3)
            ]

        case .Jester:
            return [
                AttackDefinition(id: "jester.jab", name: "Jab", damageType: .trick, requiredLevel: 1, power: 9, maxMana: 7),
                AttackDefinition(id: "jester.taunt_slash", name: "Taunt Slash", damageType: .trick, requiredLevel: 2, power: 13, maxMana: 6),
                AttackDefinition(id: "jester.pocket_sand", name: "Pocket Sand", damageType: .trick, requiredLevel: 4, power: 21, maxMana: 5),
                AttackDefinition(id: "jester.pratfall", name: "Pratfall", damageType: .trick, requiredLevel: 6, power: 31, maxMana: 4),
                AttackDefinition(id: "jester.grand_gag", name: "Grand Gag", damageType: .trick, requiredLevel: 9, power: 52, maxMana: 3)
            ]
        }
    }

    static func starterAttackID(for cls: PlayerClass) -> String {
        switch cls {
        case .Wizard: return "wizard.spark"
        case .Knight: return "knight.punch"
        case .Jester: return "jester.jab"
        }
    }

    static func attack(for cls: PlayerClass, id: String) -> AttackDefinition? {
        attacks(for: cls).first(where: { $0.id == id })
    }

    static func learnableAttacks(for cls: PlayerClass, atLevel level: Int, excluding ownedIDs: Set<String>) -> [AttackDefinition] {
        attacks(for: cls)
            .filter { $0.requiredLevel <= level }
            .filter { !ownedIDs.contains($0.id) }
            .sorted { a, b in
                if a.requiredLevel != b.requiredLevel { return a.requiredLevel < b.requiredLevel }
                return a.power < b.power
            }
    }
}

// MARK: - Quests

struct Enemy: Identifiable, Codable {
    var id: UUID = UUID()
    let name: String

    /// Temporary, display-only hint. (Phase 2 will remove this entirely.)
    let requiredAttackHint: String

    /// Current model is HP-based.
    let HP: Int

    let mockingLine: String
}

struct QuestArea: Identifiable, Codable {
    var id = UUID()
    let name: String
    let unlockMiles: Double
    var enemies: [Enemy]
    var rewardsXP: Int
}
