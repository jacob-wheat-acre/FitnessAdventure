//
//  QuestView.swift
//  FittnessRPG
//
//  Created by Jacob Whitaker on 12/25/25.
//

import SwiftUI

struct QuestView: View {
    @EnvironmentObject var vm: GameViewModel
    let quest: QuestArea

    @State private var lastDamage: Int? = nil
    @State private var message: String = ""

    var body: some View {
        VStack(spacing: 18) {
            Text(quest.name)
                .font(.largeTitle)
                .bold()

            if let state = vm.currentEnemyState(for: quest) {
                // ACTIVE QUEST
                Text(state.enemy.name)
                    .font(.title)
                    .bold()

                VStack(spacing: 8) {
                    Text("Enemy HP: \(state.hp)/\(state.enemy.HP)")
                        .font(.headline)

                    ProgressView(value: Double(state.hp), total: Double(state.enemy.HP))
                        .padding(.horizontal)

                    Text("Hint: \(state.enemy.requiredAttackHint)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Progress: Enemy \(state.index + 1) of \(state.total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let lastDamage {
                    Text("Last Damage: \(lastDamage)")
                        .font(.headline)
                } else {
                    Text("Last Damage: —")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(.red)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Text("Choose Attack")
                    .font(.headline)

                let equipped = vm.currentEquippedAttacks()

                if equipped.isEmpty {
                    Text("No equipped attacks. (You should have a starter attack.)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(equipped) { attack in
                        let mana = vm.mana(for: attack.id)

                        Button {
                            performAttack(attack, enemyMockingLine: state.enemy.mockingLine)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(attack.name)
                                        .font(.headline)
                                    Text("Power \(attack.power) • Mana \(mana)/\(attack.maxMana)")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                Spacer()
                                Text(attack.damageType.rawValue.uppercased())
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(mana > 0 ? Color.blue.opacity(0.85) : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(mana <= 0)
                    }
                }

                Spacer()
            } else {
                // COMPLETED QUEST
                Text("Quest Complete!")
                    .font(.title)
                    .bold()

                if vm.isQuestRewardClaimed(quest) {
                    Text("Reward already claimed.")
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)
                } else {
                    Button("Claim \(quest.rewardsXP) XP") {
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

                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(.secondary)
                        .padding(.top, 6)
                }

                Spacer()
            }
        }
        .padding()
        .navigationTitle(quest.name)
    }

    private func performAttack(_ attack: AttackDefinition, enemyMockingLine: String) {
        message = ""

        guard vm.spendMana(for: attack.id) else {
            message = "Out of mana for \(attack.name). Apply workouts to replenish."
            return
        }

        lastDamage = attack.power

        guard let result = vm.applyDamage(attack.power, in: quest) else {
            message = "Nothing to attack (quest may be complete)."
            return
        }

        if result.questCompleted {
            message = "Area cleared!"
            return
        }

        if result.enemyDefeated {
            message = "Enemy defeated! Next foe awaits."
        } else {
            message = enemyMockingLine
        }
    }
}
