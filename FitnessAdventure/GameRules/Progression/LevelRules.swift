import Foundation

/// Single source of truth for level-based progression rules:
/// - mana gained per workout
/// - mana cap
/// - XP required to REACH a given level
///
/// Interpretation of your table:
/// - Row "Level N, XP required to level = X" means: total XP required to advance INTO Level N.
///   So Level 1 requires 0 XP (starting level), Level 2 requires 1500 XP, etc.
struct LevelRules {

    struct Row: Codable, Hashable {
        let level: Int
        let manaPerWorkout: Int
        let manaCap: Int
        let xpToReachLevel: Int
    }

    // MARK: - Authoritative table (edit here later)
    static let table: [Row] = [
        .init(level: 1,  manaPerWorkout: 4, manaCap: 20, xpToReachLevel: 0),
        .init(level: 2,  manaPerWorkout: 4, manaCap: 24, xpToReachLevel: 1500),
        .init(level: 3,  manaPerWorkout: 5, manaCap: 30, xpToReachLevel: 1500),
        .init(level: 4,  manaPerWorkout: 5, manaCap: 30, xpToReachLevel: 1500),
        .init(level: 5,  manaPerWorkout: 5, manaCap: 35, xpToReachLevel: 1500),
        .init(level: 6,  manaPerWorkout: 6, manaCap: 42, xpToReachLevel: 3000),
        .init(level: 7,  manaPerWorkout: 6, manaCap: 42, xpToReachLevel: 3000),
        .init(level: 8,  manaPerWorkout: 6, manaCap: 42, xpToReachLevel: 3000),
        .init(level: 9,  manaPerWorkout: 7, manaCap: 50, xpToReachLevel: 3000),
        .init(level: 10, manaPerWorkout: 7, manaCap: 50, xpToReachLevel: 3000),
        .init(level: 11, manaPerWorkout: 8, manaCap: 50, xpToReachLevel: 6000)
    ]

    static var maxLevel: Int { table.map(\.level).max() ?? 1 }

    // MARK: - Lookups

    static func row(for level: Int) -> Row {
        // Clamp to supported range
        let lv = min(max(level, 1), maxLevel)
        return table.first(where: { $0.level == lv }) ?? table[0]
    }

    static func manaPerWorkout(for level: Int) -> Int {
        max(0, row(for: level).manaPerWorkout)
    }

    static func manaCap(for level: Int) -> Int {
        max(0, row(for: level).manaCap)
    }

    /// XP required to advance from `currentLevel` to `currentLevel + 1`.
    /// Returns Int.max at max level to effectively stop leveling.
    static func xpToNextLevel(from currentLevel: Int) -> Int {
        let next = currentLevel + 1
        guard next <= maxLevel else { return Int.max }
        return max(0, row(for: next).xpToReachLevel)
    }
}
