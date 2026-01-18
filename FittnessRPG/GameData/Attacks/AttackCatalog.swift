//
//  AttackCatalog.swift
//  FitnessRPG
//
//  9 attacks per class. Multi-effort requirements supported.
//  Effort requirements are based on TOTAL Effort units (no tier gating).
//

import Foundation

struct AttackCatalog {
    
    static func attacks(for cls: PlayerClass) -> [Attack] {
        switch cls {
        case .Knight: return knightAttacks
        case .Wizard: return wizardAttacks
        case .Jester: return jesterAttacks
        }
    }
    
    static func attack(for cls: PlayerClass, id: String) -> Attack? {
        attacks(for: cls).first { $0.id == id }
    }
    
    // MARK: - Wizard (Bias: Rhythm + Precision)
    
    private static let wizardAttacks: [Attack] = [
        Attack(
            id: "wz_sacred_ritual",
            name: "Sacred Ritual",
            requiredLevel: 1,
            manaCost: 3,
            modifiers: [
                .manaDiscountWeeklyEffort(affinity: .rhythm, every: 7, minCost: 1)
            ],
            effects: [
                .removeArmor(amount: 2),
                .removeHP(amount: 2)
            ]
        ),
        
        Attack(
            id: "wz_arcane_knowledge",
            name: "Arcane Knowledge",
            requiredLevel: 1,
            manaCost: 3,
            modifiers: [
                .addArmorPerWeeklyEffort(affinity: .precision, perEffort: 3)
            ],
            effects: [
                .removeArmor(amount: 2),
                .removeHP(amount: 1)
            ]
        ),
        
        Attack(
            id: "wz_staff_strike",
            name: "Staff Strike",
            requiredLevel: 1,
            manaCost: 3,
            modifiers: [
                .addHPPerWeeklyEffort(affinity: .force, perEffort: 3)
            ],
            effects: [
                .removeArmor(amount: 1),
                .removeHP(amount: 2)
            ]
        ),
        
        Attack(
            id: "wz_unleash_energy",
            name: "Unleash Energy",
            requiredLevel: 1,
            manaCost: 4,
            modifiers: [
                .manaDiscountWeeklyEffort(affinity: .endurance, every: 3, minCost: 1)
            ],
            effects: [
                .removeArmor(amount: 4),
                .removeHP(amount: 4)
            ]
        )
    ]
    
    // MARK: - Knight (Bias: Force + Endurance)
    
    private static let knightAttacks: [Attack] = [
        Attack(
            id: "kn_spear_rush",
            name: "Spear Rush",
            requiredLevel: 1,
            manaCost: 4,
            modifiers: [
                .manaDiscountWeeklyEffort(affinity: .endurance, every: 6, minCost: 1)
            ],
            effects: [
                .removeArmor(amount: 2),
                .removeHP(amount: 3)
            ]
        ),
        
        Attack(
            id: "kn_sword_slash",
            name: "Sword Slash",
            requiredLevel: 1,
            manaCost: 3,
            modifiers: [
                .addHPPerWeeklyEffort(affinity: .force, perEffort: 3)
            ],
            effects: [
                .removeArmor(amount: 1),
                .removeHP(amount: 2)
            ]
        ),
        
        Attack(
            id: "kn_targeted_strike",
            name: "Targeted Strike",
            requiredLevel: 1,
            manaCost: 3,
            modifiers: [
                .addArmorPerWeeklyEffort(affinity: .precision, perEffort: 3)
            ],
            effects: [
                .removeArmor(amount: 2),
                .removeHP(amount: 1)
            ]
        ),
        
        Attack(
            id: "kn_commend_oneself",
            name: "Commend Oneself",
            requiredLevel: 1,
            manaCost: 3,
            modifiers: [
                .manaDiscountWeeklyEffort(affinity: .rhythm, every: 5, minCost: 1)
            ],
            effects: [
                .removeArmor(amount: 3),
                .removeHP(amount: 3)]
        )
    ]
    
    // MARK: - Jester (Bias: Rhythm + Endurance)
    
    private static let jesterAttacks: [Attack] = [
        Attack(
            id: "js_taunting_chant",
            name: "Taunting Chant",
            requiredLevel: 1,
            manaCost: 3,
            modifiers: [
                .manaDiscountWeeklyEffort(affinity: .rhythm, every: 7, minCost: 1)
            ],
            effects: [
                .removeArmor(amount: 2),
                .removeHP(amount: 2)
            ]
        ),
        
        Attack(
            id: "js_running_gag",
            name: "Running Gag",
            requiredLevel: 1,
            manaCost: 4,
            modifiers: [
                .manaDiscountWeeklyEffort(affinity: .endurance, every: 3, minCost: 1)
            ],
            effects: [
                .removeArmor(amount: 4),
                .removeHP(amount: 4)
            ]
        ),

        Attack(
            id: "js_cutting_remark",
            name: "Cutting Remark",
            requiredLevel: 1,
            manaCost: 3,
            modifiers: [
                .addArmorPerWeeklyEffort(affinity: .precision, perEffort: 3)
            ],
            effects: [
                .removeArmor(amount: 2),
                .removeHP(amount: 1)
            ]
        ),
        
        Attack(
            id: "js_scepter_smack",
            name: "Scepter Smack",
            requiredLevel: 1,
            manaCost: 3,
            modifiers: [
                .addHPPerWeeklyEffort(affinity: .force, perEffort: 3)
            ],
            effects: [
                .removeArmor(amount: 1),
                .removeHP(amount: 2)
            ]
        )
    ]
}
