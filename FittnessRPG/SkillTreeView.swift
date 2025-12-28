//
//  SkillTreeView.swift
//  FittnessRPG
//
//  Attack Tree (attacks-only progression view)
//

import SwiftUI

struct SkillTreeView: View {
    @EnvironmentObject var vm: GameViewModel

    private var classAttacks: [AttackDefinition] {
        AttackCatalog.attacks(for: vm.player.playerClass)
            .sorted { a, b in
                if a.requiredLevel != b.requiredLevel { return a.requiredLevel < b.requiredLevel }
                return a.power < b.power
            }
    }

    private var equippedIDs: Set<String> { Set(vm.player.equippedAttackIDs) }
    private var ownedIDs: Set<String> { vm.player.ownedAttackIDs }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard

                equippedCard

                attackTreeCard

                Spacer(minLength: 24)
            }
            .padding()
        }
        .navigationTitle("Attack Tree")
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                classBadge

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(vm.player.playerClass.rawValue) Attacks")
                        .font(.title2)
                        .bold()
                    Text("Level \(vm.player.level) • Loadout \(vm.player.equippedAttackIDs.count)/\(vm.player.equippedLimit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text("Unlocked: \(ownedIDs.count)/\(classAttacks.count)")
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressView(value: Double(ownedIDs.count), total: Double(max(classAttacks.count, 1)))
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(14)
    }

    private var classBadge: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.20))
                .frame(width: 44, height: 44)

            Image(systemName: classSymbolName(vm.player.playerClass))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.blue)
        }
        .accessibilityLabel("\(vm.player.playerClass.rawValue) class")
    }

    private func classSymbolName(_ cls: PlayerClass) -> String {
        switch cls {
        case .Wizard: return "sparkles"
        case .Knight: return "shield.lefthalf.filled"
        case .Jester: return "theatermasks"
        }
    }

    // MARK: - Equipped

    private var equippedCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Equipped Attacks")
                .font(.headline)

            let equipped = vm.currentEquippedAttacks()

            if equipped.isEmpty {
                Text("No equipped attacks found. (You should have a starter attack.)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(equipped) { atk in
                        AttackRow(
                            attack: atk,
                            level: vm.player.level,
                            isOwned: ownedIDs.contains(atk.id),
                            isEquipped: true,
                            currentMana: vm.player.manaByAttackID[atk.id] ?? 0
                        )
                    }
                }
            }

            Text("Mana replenishes when you apply workouts.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(14)
    }

    // MARK: - Full Tree

    private var attackTreeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Attacks")
                .font(.headline)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(classAttacks.enumerated()), id: \.element.id) { index, atk in
                    AttackTreeNodeRow(
                        attack: atk,
                        isLast: index == classAttacks.count - 1,
                        level: vm.player.level,
                        isOwned: ownedIDs.contains(atk.id),
                        isEquipped: equippedIDs.contains(atk.id),
                        currentMana: vm.player.manaByAttackID[atk.id] ?? 0
                    )
                    .padding(.vertical, 10)
                }
            }

            Divider()
                .padding(.vertical, 6)

            VStack(alignment: .leading, spacing: 6) {
                Text("How to unlock")
                    .font(.subheadline)
                    .bold()

                Text("You unlock new attacks by leveling up, then choosing an attack in the Level Up prompt. If your loadout is full, you’ll replace an equipped attack.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(14)
    }
}

// MARK: - Row (simple card)

private struct AttackRow: View {
    let attack: AttackDefinition
    let level: Int
    let isOwned: Bool
    let isEquipped: Bool
    let currentMana: Int

    private var isLockedByLevel: Bool { level < attack.requiredLevel }

    var body: some View {
        HStack(spacing: 12) {
            statusIcon

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(attack.name)
                        .font(.headline)

                    Spacer()

                    if isEquipped {
                        Text("EQUIPPED")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.18))
                            .foregroundStyle(.green)
                            .cornerRadius(10)
                    } else if isOwned {
                        Text("OWNED")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.16))
                            .foregroundStyle(.blue)
                            .cornerRadius(10)
                    } else if isLockedByLevel {
                        Text("LOCKED")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.20))
                            .foregroundStyle(.secondary)
                            .cornerRadius(10)
                    } else {
                        Text("AVAILABLE")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.16))
                            .foregroundStyle(.orange)
                            .cornerRadius(10)
                    }
                }

                Text(detailLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private var detailLine: String {
        let mana = "Mana \(currentMana)/\(attack.maxMana)"
        return "Req L\(attack.requiredLevel) • PWR \(attack.power) • \(mana) • \(attack.damageType.rawValue.capitalized)"
    }

    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackground)
                .frame(width: 30, height: 30)

            Image(systemName: iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(iconForeground)
        }
    }

    private var iconName: String {
        if isEquipped { return "star.fill" }
        if isOwned { return "checkmark" }
        if isLockedByLevel { return "lock.fill" }
        return "sparkle"
    }

    private var iconBackground: Color {
        if isEquipped { return Color.green.opacity(0.22) }
        if isOwned { return Color.blue.opacity(0.20) }
        if isLockedByLevel { return Color.gray.opacity(0.20) }
        return Color.orange.opacity(0.20)
    }

    private var iconForeground: Color {
        if isEquipped { return .green }
        if isOwned { return .blue }
        if isLockedByLevel { return .secondary }
        return .orange
    }
}

// MARK: - Tree node row (with connector)

private struct AttackTreeNodeRow: View {
    let attack: AttackDefinition
    let isLast: Bool

    let level: Int
    let isOwned: Bool
    let isEquipped: Bool
    let currentMana: Int

    private var isLockedByLevel: Bool { level < attack.requiredLevel }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                nodeIcon

                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.35))
                        .frame(width: 3)
                        .frame(maxHeight: .infinity)
                        .padding(.top, 6)
                }
            }
            .frame(width: 32)

            AttackRow(
                attack: attack,
                level: level,
                isOwned: isOwned,
                isEquipped: isEquipped,
                currentMana: currentMana
            )

            Spacer(minLength: 0)
        }
    }

    private var nodeIcon: some View {
        ZStack {
            Circle()
                .fill(nodeBackground)
                .frame(width: 28, height: 28)

            Image(systemName: nodeSymbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(nodeForeground)
        }
    }

    private var nodeSymbol: String {
        if isEquipped { return "star.fill" }
        if isOwned { return "checkmark" }
        if isLockedByLevel { return "lock.fill" }
        return "sparkle"
    }

    private var nodeBackground: Color {
        if isEquipped { return Color.green.opacity(0.25) }
        if isOwned { return Color.blue.opacity(0.20) }
        if isLockedByLevel { return Color.gray.opacity(0.22) }
        return Color.orange.opacity(0.20)
    }

    private var nodeForeground: Color {
        if isEquipped { return .green }
        if isOwned { return .blue }
        if isLockedByLevel { return .secondary }
        return .orange
    }
}
