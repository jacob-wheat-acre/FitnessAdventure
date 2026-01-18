import SwiftUI

struct SkillTreeView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        let cls = vm.player.playerClass
        let all = AttackCatalog.attacks(for: cls).sorted { a, b in
            if a.requiredLevel != b.requiredLevel { return a.requiredLevel < b.requiredLevel }
            return a.name < b.name
        }

        let unlocked = all.filter { $0.requiredLevel <= vm.player.level }
        let locked = all.filter { $0.requiredLevel > vm.player.level }

        return List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            ClassIcon(playerClass: cls, size: 16)
                            Text("\(cls.displayName) Attack Tree")
                                .font(.headline)
                        }
                        Text("Unlocked: \(unlocked.count) • Locked: \(locked.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            if !unlocked.isEmpty {
                Section("Unlocked") {
                    ForEach(unlocked) { atk in
                        AttackDetailRow(vm: vm, attack: atk, isUnlocked: true)
                    }
                }
            }

            if !locked.isEmpty {
                Section("Locked") {
                    ForEach(locked) { atk in
                        AttackDetailRow(vm: vm, attack: atk, isUnlocked: false)
                    }
                }
            }
        }
        .navigationTitle("Attack Tree")
    }
}

private struct AttackDetailRow: View {
    @ObservedObject var vm: GameViewModel
    let attack: Attack
    let isUnlocked: Bool

    var body: some View {
        let accent = (attack.primaryStylingAffinity?.uiColor ?? RPGColors.neutral)
        let snap = vm.effectiveAttack(for: attack)
        let hints = modifierHints(for: attack)

        VStack(alignment: .leading, spacing: 8) {

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                if let a = attack.primaryStylingAffinity {
                    AffinityIcon(affinity: a, size: 16)
                }

                Text(attack.name)
                    .font(.headline)

                Spacer()
                Tag(text: isUnlocked ? "Unlocked" : "Locked", tint: accent)
            }

            // Effective combat outputs + effective mana
            HStack(spacing: 10) {
                statChip(label: "HP", value: snap.hpRemoved)
                statChip(label: "Armor", value: snap.armorRemoved)
                statChip(label: "Mana", value: snap.manaCost)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Level: \(attack.requiredLevel)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)


            }

            if !hints.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(hints, id: \.self) { line in
                        Text("• \(line)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .opacity(isUnlocked ? 1.0 : 0.55)
    }

    private func statChip(label: String, value: Int) -> some View {
        HStack(spacing: 6) {
            Text("\(label):")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(max(0, value))")
                .monospacedDigit()
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.10))
        .clipShape(Capsule())
    }

    private func modifierHints(for attack: Attack) -> [String] {
        var out: [String] = []

        for m in attack.modifiers {
            switch m {
            case .manaDiscountWeeklyEffort(let affinity, _, _):
                switch affinity {
                case .rhythm:
                    out.append("More Rhythm lowers mana cost.")
                case .endurance:
                    out.append("More Endurance lowers mana cost.")
                default:
                    out.append("More \(affinity.displayName) lowers mana cost.")
                }

            case .addHPPerWeeklyEffort(let affinity, _):
                if affinity == .force {
                    out.append("More Strength increases HP damage.")
                } else {
                    out.append("More \(affinity.displayName) increases HP damage.")
                }

            case .addArmorPerWeeklyEffort(let affinity, _):
                if affinity == .precision {
                    out.append("More Precision increases armor removal.")
                } else {
                    out.append("More \(affinity.displayName) increases armor removal.")
                }
            }
        }

        var seen: Set<String> = []
        return out.filter { seen.insert($0).inserted }
    }
}

private struct Tag: View {
    let text: String
    var tint: Color = .gray

    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial)
            .overlay(
                Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}
