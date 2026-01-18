//  Player.swift
//  FittnessRPG
//

import Foundation

struct Skill: Codable, Identifiable {
    var id: UUID = UUID()
    let name: String
    var unlocked: Bool
}

enum PlayerClass: String, Codable, CaseIterable {
    case Wizard, Knight, Jester
}

enum Species: String, Codable, CaseIterable {
    case Human, Elf, Gnome, Orc
}

// MARK: - Quest Persistence

struct QuestAreaProgress: Codable {
    var currentEnemyIndex: Int = 0
    var currentEnemyHP: Int? = nil

    /// NEW: Persist enemy armor between sessions (so it doesn't auto-refill).
    /// Optional for backward-compatible decoding of existing saves.
    var currentEnemyArmor: [Armor]? = nil

    var completed: Bool = false
    var rewardClaimed: Bool = false
}

struct Player: Codable {
    var name: String = ""
    var species: Species = .Human
    var playerClass: PlayerClass = .Knight

    var level: Int = 1
    var experience: Double = 0
    var distanceProgress: Double = 0

    var appliedWorkoutIDs: [UUID] = []
    var skills: [Skill] = []

    // MARK: - Efforts (Stats)
    /// Earned from workouts. Never consumed; used as persistent stats to gate attacks.
    var efforts: [Effort] = []

    // MARK: - Attacks (Legacy fields retained to minimize schema churn)
    /// Deprecated for logic. Attacks are now unlocked by level (requiredLevel <= level).
    var ownedAttackIDs: Set<String> = []

    /// Deprecated for combat logic (no loadouts). Retained to avoid save churn.
    var equippedAttackIDs: [String] = []

    /// Stored pool + compatibility fields.
    var manaByAttackID: [String: Int] = [:]
    var equippedLimit: Int = 4

    /// Tracks which attacks have already been shown in the “newly usable attacks” notification.
    var notifiedUsableAttackIDs: Set<String> = []

    // MARK: - Quests (Phase 2)
    /// Keyed by quest area name (e.g. "Field", "Cave", "Seaside")
    var questProgressByAreaName: [String: QuestAreaProgress] = [:]

    // MARK: - Trophy Room
    /// Enemy IDs the player has defeated at least once.
    var defeatedEnemyIDs: Set<String> = []
    
    // MARK: - Computed properties
    var xpForNextLevel: Double {
        Double(LevelRules.xpToNextLevel(from: level))
    }

    var xpProgress: Double {
        let req = xpForNextLevel
        if req == 0 || req == Double(Int.max) { return 1 }   // handles max level (and any zero edge)
        return min(experience / req, 1)
    }

    // MARK: - Character Mana Pool (stored in manaByAttackID to avoid schema churn)
    private static let manaPoolKey = "__mana_pool"

    var manaPool: Int {
        get { manaByAttackID[Self.manaPoolKey] ?? 0 }
        set { manaByAttackID[Self.manaPoolKey] = max(0, newValue) }
    }

    // MARK: - Skills
    mutating func initializeSkills() {
        switch playerClass {
        case .Wizard:
            skills = [Skill(name: "Fireball", unlocked: true),
                      Skill(name: "Ice Shard", unlocked: false)]
        case .Knight:
            skills = [Skill(name: "Shield Block", unlocked: true),
                      Skill(name: "Sword Slash", unlocked: false)]
        case .Jester:
            skills = [Skill(name: "Taunt", unlocked: true),
                      Skill(name: "Trick Attack", unlocked: false)]
        }
    }

    mutating func unlockNextSkill() {
        if let index = skills.firstIndex(where: { !$0.unlocked }) {
            skills[index].unlocked = true
        }
    }

    // MARK: - Effort helpers (Stats)

    mutating func addEffort(_ effort: Effort, maxStored: Int = 500) {
        efforts.append(effort)
        if efforts.count > maxStored {
            efforts = Array(efforts.suffix(maxStored))
        }
    }

    /// Count of qualifying efforts for a given affinity, optionally requiring a minimum tier.
    func effortCount(affinity: Affinity, minTier: EffortTier?) -> Int {
        efforts
            .filter { $0.affinity == affinity }
            .filter { minTier == nil ? true : ($0.tier >= minTier!) }
            .count
    }

    // MARK: - Progression / Workouts

    mutating func applyWorkout(_ id: UUID, calories: Double, distance: Double) -> Int {
        guard !appliedWorkoutIDs.contains(id) else { return 0 }

        appliedWorkoutIDs.append(id)
        experience += calories
        distanceProgress += distance

        return levelUpIfNeeded()
    }

    mutating func addXP(_ amount: Int) -> Int {
        experience += Double(amount)
        return levelUpIfNeeded()
    }

    @discardableResult
    mutating func levelUpIfNeeded() -> Int {
        var levelUps = 0

        while level < LevelRules.maxLevel {
            let req = Double(LevelRules.xpToNextLevel(from: level))
            if req == 0 { break }                // defensive (shouldn't happen with your table)
            if experience < req { break }

            experience -= req
            level += 1
            levelUps += 1

            unlockNextSkill()
        }

        // If at max level, you can optionally clamp XP:
        if level >= LevelRules.maxLevel {
            // Keep experience as “overflow XP” if you want, or clamp to 0.
            // experience = 0
        }

        return levelUps
    }
}
