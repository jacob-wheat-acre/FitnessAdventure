import Foundation

enum EncounterResult {
    case noEffect(reason: String)
    case applied(messages: [String])
    case enemyDefeated(message: String)
}

struct EncounterEngine {

    static func apply(
        manaCost: Int,
        effects: [AttackEffect],
        combatAffinity: Affinity?,   // currently unused (weakness system removed)
        manaAvailable: Int,
        state: inout EncounterState
    ) -> (manaSpent: Int, result: EncounterResult) {

        guard !state.isDefeated else {
            return (0, .noEffect(reason: "Enemy already defeated."))
        }

        let cost = max(0, manaCost)

        guard manaAvailable >= cost else {
            return (0, .noEffect(reason: "Not enough mana."))
        }

        var messages: [String] = []

        // Weakness is no longer a concept. (combatAffinity reserved for future systems.)
        _ = combatAffinity

        // ---------------------------------------------------------------------
        // 1) Apply armor removal effects ONLY to armor.
        // ---------------------------------------------------------------------
        let totalArmorRemoval = effects.reduce(0) { total, effect in
            if case .removeArmor(let amount) = effect { return total + max(0, amount) }
            return total
        }

        if totalArmorRemoval > 0 {
            let removed = removeAnyArmor(amount: totalArmorRemoval, from: &state.enemy.armor)
            if removed > 0 { messages.append("Removed \(removed) armor.") }
            else { messages.append("No armor to remove.") }
        }

        // ---------------------------------------------------------------------
        // 2) Apply HP removal effects ONLY if ALL armor is gone.
        //    If any armor remains, HP removal does nothing (no spillover).
        // ---------------------------------------------------------------------
        let totalHPRemoval = effects.reduce(0) { total, effect in
            if case .removeHP(let amount) = effect { return total + max(0, amount) }
            return total
        }

        let armorRemaining = totalArmorRemaining(in: state.enemy.armor)

        if totalHPRemoval > 0 {
            if armorRemaining == 0 {
                let removedHP = min(totalHPRemoval, state.enemy.hp)
                state.enemy.hp -= removedHP
                messages.append("Removed \(removedHP) HP.")
            } else {
                messages.append("Armor remains—HP damage is blocked.")
            }
        }

        // Defeat at 0 HP.
        if state.enemy.hp == 0 && !state.isDefeated {
            state.isDefeated = true
            return (cost, .enemyDefeated(message: state.enemy.narrative.defeat))
        }

        return (cost, .applied(messages: messages))
    }

    // MARK: - Armor helpers

    private static func totalArmorRemaining(in armors: [Armor]) -> Int {
        armors.map { max(0, $0.value) }.reduce(0, +)
    }

    private static func removeAnyArmor(amount: Int, from armors: inout [Armor]) -> Int {
        var remaining = max(0, amount)
        guard remaining > 0 else { return 0 }

        for i in armors.indices {
            guard remaining > 0 else { break }
            if armors[i].value > 0 {
                let delta = min(armors[i].value, remaining)
                armors[i].value -= delta
                remaining -= delta
            }
        }
        return amount - remaining
    }
}
