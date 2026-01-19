import SwiftUI

struct AttackChoiceView: View {
    @ObservedObject var vm: GameViewModel
    let choices: [Attack]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("New Attacks Ready")
                        .font(.headline)

                    Text("May these attacks help you on your adventure.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }

            Section("Now Available") {
                ForEach(choices) { atk in
                    AttackChoiceDetailRow(vm: vm, attack: atk)
                }
            }

            Section {
                Button("Continue") {
                    vm.dismissActiveSheet()
                    vm.savePlayer()
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Attacks Unlocked")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AttackChoiceDetailRow: View {
    @ObservedObject var vm: GameViewModel
    let attack: Attack

    var body: some View {
        let snap = vm.effectiveAttack(for: attack)
        let hints = modifierHints(for: attack)

        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 10) {
                if let a = attack.primaryStylingAffinity {
                    AffinityIcon(affinity: a, size: 18)
                }

                Text(attack.name)
                    .font(.headline)

                Spacer()
            }

            // Combat outputs (effective)
            HStack(spacing: 10) {
                statChip(label: "Armor", value: snap.armorRemoved)
                statChip(label: "HP", value: snap.hpRemoved)
                statChip(label: "Mana", value: snap.manaCost)
                Spacer()
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
        .contentShape(Rectangle())
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
                    // If you ever add other affinities to mana discount later:
                    out.append("More \(affinity.displayName) lowers mana cost.")
                }

            case .addHPPerWeeklyEffort(let affinity, _):
                // Your intent: Strength => more HP damage
                if affinity == .force {
                    out.append("More Force increases HP damage.")
                } else {
                    out.append("More \(affinity.displayName) increases HP damage.")
                }

            case .addArmorPerWeeklyEffort(let affinity, _):
                // Your intent: Precision => more armor removal
                if affinity == .precision {
                    out.append("More Precision increases armor removal.")
                } else {
                    out.append("More \(affinity.displayName) increases armor removal.")
                }
            }
        }

        // De-dupe while preserving order
        var seen: Set<String> = []
        return out.filter { seen.insert($0).inserted }
    }
}
