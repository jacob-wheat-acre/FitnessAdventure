//
//  Enemy.swift
//  FitnessAdventure
//

import Foundation

struct RPGEnemy: Codable, Identifiable, Hashable {
    let id: String                 // stable key for trophies, e.g. "bureaucratic_slime"
    let name: String

    var weakness: Affinity?
    var hp: Int                    // HP remaining
    var armor: [Armor]             // armor points (each Armor.value is a point bucket)

    var narrative: EnemyNarrative

    init(
        id: String,
        name: String,
        weakness: Affinity?,
        hp: Int,
        armor: [Armor] = [],
        narrative: EnemyNarrative
    ) {
        self.id = id
        self.name = name
        self.weakness = weakness
        self.hp = max(0, hp)
        self.armor = armor
        self.narrative = narrative
    }

    /// Total remaining armor points (sum of active armor values).
    var armorPointsRemaining: Int {
        armor.map { max(0, $0.value) }.reduce(0, +)
    }
}
