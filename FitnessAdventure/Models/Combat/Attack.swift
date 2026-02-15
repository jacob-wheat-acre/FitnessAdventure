import Foundation

enum AttackEffect: Codable, Hashable {
    case removeHP(amount: Int)
    case removeArmor(amount: Int)
}

/// General-purpose modifiers you can extend over time.
/// These are applied in GameViewModel to produce an EffectiveAttack snapshot.
enum AttackModifier: Codable, Hashable {

    /// Mana = max(minCost, baseMana - floor(weeklyCount(affinity)/every))
    case manaDiscountWeeklyEffort(affinity: Affinity, every: Int, minCost: Int)

    /// HP = baseHP + weeklyCount(affinity) * perEffort
    case addHPPerWeeklyEffort(affinity: Affinity, perEffort: Int)

    /// Armor = baseArmor + weeklyCount(affinity) * perEffort
    case addArmorPerWeeklyEffort(affinity: Affinity, perEffort: Int)
}

struct EffortGate: Codable, Hashable {
    let affinity: Affinity
    let minCount: Int

    init(affinity: Affinity, minCount: Int = 1) {
        self.affinity = affinity
        self.minCount = max(1, minCount)
    }

    func displayText() -> String {
        "\(minCount) \(affinity.displayName)"
    }
}

struct AttackRequirement: Codable, Hashable {
    let gates: [EffortGate]

    static func effort(_ gates: [EffortGate]) -> AttackRequirement {
        .init(gates: gates)
    }

    func displayText() -> String {
        if gates.isEmpty { return "None" }
        return gates.map { $0.displayText() }.joined(separator: " + ")
    }

    var primaryAffinity: Affinity? { gates.first?.affinity }
}

struct Attack: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let requiredLevel: Int

    /// Base (static) mana. Modifiers may adjust.
    let manaCost: Int

    /// Optional modifiers (boosters/discounts/scaling).
    let modifiers: [AttackModifier]

    /// Kept for backward-compat / future expansion (even if not used for gating today).
    let requirement: AttackRequirement?

    let effects: [AttackEffect]

    init(
        id: String,
        name: String,
        requiredLevel: Int,
        manaCost: Int,
        modifiers: [AttackModifier] = [],
        requirement: AttackRequirement? = nil,
        effects: [AttackEffect]
    ) {
        self.id = id
        self.name = name
        self.requiredLevel = max(1, requiredLevel)
        self.manaCost = max(0, manaCost)
        self.modifiers = modifiers
        self.requirement = requirement
        self.effects = effects
    }

    // MARK: - Flavor inference (for UI icon/color and optional weakness logic)

    /// Affinities implied by modifiers (deduped, stable order).
    /// This is your “attack type flavor” source of truth.
    var flavorAffinities: [Affinity] {
        var seen = Set<Affinity>()
        var out: [Affinity] = []

        for m in modifiers {
            let a: Affinity
            switch m {
            case .manaDiscountWeeklyEffort(let affinity, _, _):
                a = affinity
            case .addHPPerWeeklyEffort(let affinity, _):
                a = affinity
            case .addArmorPerWeeklyEffort(let affinity, _):
                a = affinity
            }

            if seen.insert(a).inserted {
                out.append(a)
            }
        }
        return out
    }

    /// Single “primary” affinity for simple displays.
    /// For mixed attacks later, use `flavorAffinities` to show multiple icons.
    var primaryStylingAffinity: Affinity? {
        flavorAffinities.first
    }
}
