//
//  QuestView.swift
//  FittnessRPG
//

import SwiftUI

struct QuestView: View {
    @ObservedObject var vm: GameViewModel
    let quest: QuestArea

    @State private var message: String = ""

    // Anchored toast banner state (PERSISTENT)
    @State private var showToast: Bool = false
    @State private var toastExpanded: Bool = false
    @State private var toastText: String = ""

    var body: some View {
        let raw = vm.currentEnemyState(for: quest)
        let encounter = vm.encounterState(for: quest)

        VStack(spacing: 0) {

            // MARK: - Locked Top (Enemy + Resources)
            if let raw, let encounter {
                LockedEncounterHeader(
                    vm: vm,
                    raw: raw,
                    encounter: encounter
                )
            } else {
                LockedCompletedHeader(vm: vm, quest: quest, message: $message)
            }

            // MARK: - Anchored Toast Banner (persistent)
            if showToast {
                CombatToastBanner(
                    text: toastText,
                    isExpanded: $toastExpanded,
                    onDismiss: { dismissToast() }
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Divider().opacity(0.35)

            // MARK: - Scrollable Bottom (Attacks)
            if let encounter {
                AttackScroller(
                    vm: vm,
                    encounter: encounter,
                    onTapAttack: handleTap(attack:)
                )
            } else {
                Spacer()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .onChange(of: message) { _, newValue in
            presentToast(for: newValue)
        }
        
        .fullScreenCover(
            isPresented: Binding(
                get: { vm.defeatPopupMessage != nil },
                set: { if !$0 { vm.defeatPopupMessage = nil } }
            )
        ) {
            DefeatPopupView(
                enemyName: vm.defeatPopupEnemyName ?? "Enemy",
                message: vm.defeatPopupMessage ?? "",
                onDone: {
                    vm.defeatPopupMessage = nil
                    vm.defeatPopupEnemyName = nil
                }
            )
        }

    }

    // MARK: - Toast control (persistent)

    private func presentToast(for newValue: String) {
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        toastText = trimmed

        // Expand automatically if it's long (prevents “still truncated” frustration)
        if !toastExpanded {
            toastExpanded = trimmed.count > 120 || trimmed.contains("\n")
        }

        if !showToast {
            withAnimation(.easeOut(duration: 0.18)) {
                showToast = true
            }
        }
    }

    private func dismissToast() {
        withAnimation(.easeOut(duration: 0.18)) {
            showToast = false
        }
        toastExpanded = false
        toastText = ""
    }

    // MARK: - Attack handling

    private func handleTap(attack: Attack) {
        message = ""

        guard attack.requiredLevel <= vm.player.level else {
            message = "Requires Level \(attack.requiredLevel)."
            return
        }

        // Check requirements (efforts)
        if let req = attack.requirement {
            for gate in req.gates {
                let have = vm.player.effortCount(affinity: gate.affinity, minTier: nil)
                if have < gate.minCount {
                    message = "Requires: \(req.displayText()). Apply workouts to earn more."
                    return
                }
            }
        }

        // Check effective mana cost (boosters/discounts supported)
        let snapshot = vm.effectiveAttack(for: attack)
        guard vm.manaPoolCurrent() >= snapshot.manaCost else {
            message = "Not enough mana."
            return
        }

        perform(attack: attack)
    }

    private func perform(attack: Attack) {
        let result = vm.applyEncounterAttack(attack, in: quest)
        
        if let defeat = result.defeatPopupMessage, !defeat.isEmpty {
            vm.defeatPopupEnemyName = result.enemyName ?? "Enemy"
            vm.defeatPopupMessage = defeat  // triggers full screen cover
            return
        }
        
        if !result.message.isEmpty {
            toastText = result.message
            showToast = true
        }
    }
}

// MARK: - Anchored toast banner

private struct CombatToastBanner: View {
    let text: String
    @Binding var isExpanded: Bool
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack(spacing: 10) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(isExpanded ? "Combat Log" : "Last action")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                ScrollView {
                    Text(text)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 170)
            } else {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.15)) {
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - Locked top header (enemy + resources)

private struct LockedEncounterHeader: View {
    @ObservedObject var vm: GameViewModel

    let raw: (enemy: RPGEnemy, currentHP: Int, maxHP: Int, index: Int, total: Int)
    let encounter: EncounterState

    var body: some View {
        let armorPoints = encounter.enemy.armorPointsRemaining

        VStack(spacing: 12) {

            Text(encounter.enemy.name)
                .font(.title2)
                .bold()
                .padding(.top, 10)

            VStack(spacing: 6) {
                Text("Armor: \(armorPoints)  •  HP: \(encounter.enemy.hp)/\(max(raw.maxHP, 1))")
                    .font(.headline)

                ProgressView(value: Double(encounter.enemy.hp), total: Double(max(raw.maxHP, 1)))
                    .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(encounter.enemy.narrative.opening)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.12))
            .cornerRadius(12)
            .padding(.horizontal)

            LockedResourcesBar(vm: vm)
        }
        .padding(.bottom, 10)
    }
}

private struct LockedCompletedHeader: View {
    @ObservedObject var vm: GameViewModel
    let quest: QuestArea
    @Binding var message: String

    var body: some View {
        VStack(spacing: 12) {
            Text("Quest Complete!")
                .font(.title2)
                .bold()
                .padding(.top, 10)

            if vm.isQuestRewardClaimed(quest) {
                Text("Reward already claimed.")
                    .foregroundStyle(.secondary)
            } else {
                Button("Claim \(quest.rewardButtonName)") {
                    let claimed = vm.claimQuestReward(quest)
                    message = claimed ? "Reward claimed!" : "Reward not available."
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }

            LockedResourcesBar(vm: vm)
        }
        .padding(.bottom, 10)
    }
}

// MARK: - Locked resources bar (Mana only)

private struct LockedResourcesBar: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        HStack(spacing: 12) {

            Image(systemName: "bolt.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.yellow)

            Text("Mana")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(vm.manaPoolCurrent()) / \(vm.manaPoolMax())")
                .font(.subheadline)
                .monospacedDigit()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Scrollable attack list

private struct AttackScroller: View {
    @ObservedObject var vm: GameViewModel
    let encounter: EncounterState
    let onTapAttack: (Attack) -> Void

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Text("Choose Attack")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            ScrollView {
                LazyVStack(spacing: 10) {
                    let attacks = vm.currentKnownAttacks()

                    if attacks.isEmpty {
                        Text("No attacks unlocked yet. (You should have Level 1 attacks.)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                    } else {
                        ForEach(attacks) { atk in
                            let snapshot = vm.effectiveAttack(for: atk)

                            AttackButtonRow(
                                vm: vm,
                                encounter: encounter,
                                attack: atk,
                                manaPoolCurrent: vm.manaPoolCurrent(),
                                effectiveManaCost: snapshot.manaCost,
                                effectiveHPRemoved: snapshot.hpRemoved,
                                effectiveArmorRemoved: snapshot.armorRemoved,
                                onTap: { onTapAttack(atk) }
                            )
                        }
                    }

                    Color.clear.frame(height: 18)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
        }
    }
}

// MARK: - Attack row

private struct AttackButtonRow: View {
    @ObservedObject var vm: GameViewModel
    let encounter: EncounterState
    let attack: Attack
    let manaPoolCurrent: Int

    let effectiveManaCost: Int
    let effectiveHPRemoved: Int
    let effectiveArmorRemoved: Int

    let onTap: () -> Void

    var body: some View {
        let enabled = isEnabled
        let styleColor = buttonColor(enabled: enabled)

        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    if let affinity = attack.primaryStylingAffinity {
                        AffinityIcon(affinity: affinity, size: 18)
                    }

                    Text(attack.name)
                        .font(.headline)

                    Spacer()
                }

                HStack(spacing: 14) {
                    statChip(label: "Armor Remove", value: effectiveArmorRemoved)
                    statChip(label: "HP Remove", value: effectiveHPRemoved)
                    
                    if matchesEnemyWeakness {
                        Text("Weakness")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Capsule())
                    }

                    Spacer()
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(enabled ? 0.92 : 0.75))

                HStack {
                    Text("Mana Cost: \(max(0, effectiveManaCost))")
                    Spacer()
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(enabled ? 0.9 : 0.75))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(styleColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(enabled ? 0.12 : 0.10), lineWidth: 1)
            )
            .opacity(enabled ? 1.0 : 0.55)
        }
        .disabled(!enabled)
    }

    private func statChip(label: String, value: Int) -> some View {
        HStack(spacing: 6) {
            Text("\(label):")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.85))
            Text("\(max(0, value))")
                .monospacedDigit()
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.14))
        .clipShape(Capsule())
    }

    private func buttonColor(enabled: Bool) -> Color {
        if !enabled { return RPGColors.neutral.opacity(0.45) }
        if let a = attack.primaryStylingAffinity { return a.uiColor.opacity(0.85) }
        return Color.blue.opacity(0.70)
    }

    private var isEnabled: Bool {
        guard manaPoolCurrent >= max(0, effectiveManaCost) else { return false }
        return vm.meetsRequirementForUseOutsideEncounter(attack)
    }

    private var matchesEnemyWeakness: Bool {
        false
    }
}
