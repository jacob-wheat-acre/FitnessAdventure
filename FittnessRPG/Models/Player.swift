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

    // MARK: - Attacks (Phase 1)
    var ownedAttackIDs: Set<String> = []
    var equippedAttackIDs: [String] = []
    var manaByAttackID: [String: Int] = [:]
    var equippedLimit: Int = 4

    // MARK: - Quests (Phase 2)
    /// Keyed by quest area name (e.g. "Field", "Cave", "Seaside")
    var questProgressByAreaName: [String: QuestAreaProgress] = [:]

    // MARK: - Computed properties
    var xpForNextLevel: Double { Double(level * 1000) }
    var xpProgress: Double { min(experience / xpForNextLevel, 1) }

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

    // MARK: - Attacks helpers
    mutating func grantStarterAttackIfNeeded() {
        let starterID = AttackCatalog.starterAttackID(for: playerClass)

        // Ensure starter is owned
        if !ownedAttackIDs.contains(starterID) {
            ownedAttackIDs.insert(starterID)
        }

        // First, clean up invalid/foreign-class attacks
        ensureAttackStateIsValid()

        // Ensure starter is equipped if loadout is empty OR contains no valid attacks
        if equippedAttackIDs.isEmpty {
            equippedAttackIDs = [starterID]
        } else if !equippedAttackIDs.contains(starterID) {
            // Optional policy: always ensure starter is present in loadout
            // If loadout has space, append; otherwise replace first slot
            if equippedAttackIDs.count < equippedLimit {
                equippedAttackIDs.append(starterID)
            } else {
                equippedAttackIDs[0] = starterID
            }
        }

        // Ensure starter has mana
        if manaByAttackID[starterID] == nil,
           let def = AttackCatalog.attack(for: playerClass, id: starterID) {
            manaByAttackID[starterID] = def.maxMana
        }

        ensureAttackStateIsValid()
    }

    mutating func ensureAttackStateIsValid() {
        let validIDs = Set(AttackCatalog.attacks(for: playerClass).map { $0.id })

        // Drop any attacks that don't belong to this class
        ownedAttackIDs = ownedAttackIDs.intersection(validIDs)
        equippedAttackIDs = equippedAttackIDs.filter { validIDs.contains($0) }

        // Ensure equipped attacks are owned
        equippedAttackIDs = equippedAttackIDs.filter { ownedAttackIDs.contains($0) }

        // Enforce max equipped limit
        if equippedAttackIDs.count > equippedLimit {
            equippedAttackIDs = Array(equippedAttackIDs.prefix(equippedLimit))
        }

        // Ensure mana exists for owned attacks
        for id in ownedAttackIDs {
            if manaByAttackID[id] == nil {
                if let def = AttackCatalog.attack(for: playerClass, id: id) {
                    manaByAttackID[id] = def.maxMana
                } else {
                    manaByAttackID[id] = 0
                }
            }
        }

        // Remove mana entries for attacks no longer owned
        manaByAttackID = manaByAttackID.filter { ownedAttackIDs.contains($0.key) }
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
        while experience >= xpForNextLevel {
            experience -= xpForNextLevel
            level += 1
            levelUps += 1

            unlockNextSkill()
            // Attacks are chosen via UI (do not auto-unlock)
        }
        return levelUps
    }
}
