//
//  EnemyNarrative.swift
//  FitnessAdventure
//

import Foundation

struct EnemyNarrative: Codable, Hashable {
    /// Shown once at encounter start
    let opening: String

    /// Optional phase text (future use)
    let phaseShifts: [String]

    /// Shown once when defeated
    let defeat: String

    /// Persistent compendium text (2–3 sentences; third-person recommended)
    let trophy: String
}
