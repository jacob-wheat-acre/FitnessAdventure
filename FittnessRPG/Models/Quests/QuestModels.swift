//
//  QuestModels.swift
//  FittnessRPG
//

import Foundation

// MARK: - Legacy (kept to avoid breaking any old references)

struct Enemy: Identifiable, Codable {
    var id: UUID = UUID()
    let name: String
    let requiredAttackHint: String
    let HP: Int
    let mockingLine: String
}

// MARK: - Quests (now use RPGEnemy)

struct QuestArea: Identifiable, Codable {
    var id = UUID()
    let name: String
    let unlockMiles: Double
    var enemies: [RPGEnemy]     // <-- migrated
    var rewardsXP: Int
}
