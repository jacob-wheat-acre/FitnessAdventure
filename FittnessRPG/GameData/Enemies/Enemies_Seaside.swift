//
//  Enemies_Seaside.swift
//  FittnessRPG
//

import Foundation

struct EnemiesSeaside {
    static let all: [RPGEnemy] = [
        EnemyBuild.e(
            "sea_iron_crab",
            "Iron Crab",
            weakness: .force,
            hp: 4,
            armor: [EnemyBuild.a(.structural, 2)],
            narrative: EnemyBuild.n(
                "A crab plated in iron scrapes across the rocks.",
                "The iron shell splits and the crab retreats into the surf.",
                "A living shield. Force breaks its shell before anything else matters."
            )
        ),

        EnemyBuild.e(
            "sea_merfolk_guard",
            "Merfolk Guard",
            weakness: .precision,
            hp: 5,
            armor: [EnemyBuild.a(.stability, 1), EnemyBuild.a(.pattern, 1)],
            narrative: EnemyBuild.n(
                "A merfolk guard stands poised, moving with practiced discipline.",
                "The guard salutes solemnly and dissolves back into the tide.",
                "A disciplined opponent protected by layers. Precision creates the opening.",
                phases: ["The guard’s stance shifts—every opening feels like a trap."]
            )
        ),

        EnemyBuild.e(
            "sea_leviathan",
            "Leviathan",
            weakness: .endurance,
            hp: 7,
            armor: [EnemyBuild.a(.structural, 2), EnemyBuild.a(.stability, 1)],
            narrative: EnemyBuild.n(
                "The sea darkens. Something immense rises beneath the waves.",
                "The ocean stills as the Leviathan sinks back into the deep.",
                "A force of nature that demands endurance. Survive the pressure and keep going.",
                phases: ["The Leviathan’s wake becomes a storm."]
            )
        )
    ]
}

