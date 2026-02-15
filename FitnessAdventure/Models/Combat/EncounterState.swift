//
//  EncounterState.swift
//  FitnessAdventure
//

import Foundation

struct EncounterState: Codable, Hashable {
    var enemy: RPGEnemy
    var isDefeated: Bool

    init(enemy: RPGEnemy) {
        self.enemy = enemy
        self.isDefeated = false
    }
}
