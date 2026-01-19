//
//  Enemies_Builders.swift
//  FittnessRPG
//
//  Small helpers to make enemy definitions concise and consistent.
//

import Foundation

enum EnemyBuild {
    // Armor builder
    static func a(_ type: ArmorType, _ value: Int) -> Armor {
        Armor(type: type, value: value)
    }

    // Narrative builder (phase shifts optional)
    static func n(
        _ opening: String,
        _ defeat: String,
        _ trophy: String,
        phases: [String] = []
    ) -> EnemyNarrative {
        EnemyNarrative(
            opening: opening,
            phaseShifts: phases,
            defeat: defeat,
            trophy: trophy
        )
    }

    // Enemy builder
    static func e(
        _ id: String,
        _ name: String,
        weakness: Affinity? = nil,
        hp: Int,
        armor: [Armor] = [],
        narrative: EnemyNarrative
    ) -> RPGEnemy {
        RPGEnemy(
            id: id,
            name: name,
            weakness: weakness,
            hp: hp,
            armor: armor,
            narrative: narrative
        )
    }
}

