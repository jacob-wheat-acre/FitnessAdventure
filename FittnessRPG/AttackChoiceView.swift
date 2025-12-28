//
//  AttackChoiceView.swift
//  FittnessRPG
//
//  Created by Jacob Whitaker on 12/26/25.
//
import SwiftUI

struct AttackChoiceView: View {
    @EnvironmentObject var vm: GameViewModel
    let choices: [AttackDefinition]

    @Environment(\.dismiss) private var dismiss

    @State private var selectedNewID: String? = nil
    @State private var selectedReplaceID: String? = nil

    private var loadoutFull: Bool {
        vm.player.equippedAttackIDs.count >= vm.player.equippedLimit
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text("Level Up: Learn a New Attack")
                    .font(.title2)
                    .bold()
                    .padding(.top)

                Text("Pick one attack to learn. If your loadout is full, you must replace an equipped attack.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                List {
                    Section("New Attacks") {
                        ForEach(choices) { atk in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(atk.name)
                                        .font(.headline)
                                    Text("Req L\(atk.requiredLevel) • Power \(atk.power) • Max Mana \(atk.maxMana)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: selectedNewID == atk.id ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedNewID == atk.id ? .green : .secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedNewID = atk.id
                            }
                        }
                    }

                    if loadoutFull {
                        Section("Replace Equipped Attack") {
                            let equipped = vm.currentEquippedAttacks()
                            ForEach(equipped) { atk in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(atk.name)
                                            .font(.headline)
                                        Text("Power \(atk.power) • Mana \(vm.mana(for: atk.id))/\(atk.maxMana)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: selectedReplaceID == atk.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedReplaceID == atk.id ? .orange : .secondary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedReplaceID = atk.id
                                }
                            }
                        }
                    }
                }

                Button {
                    guard let newID = selectedNewID else { return }

                    if loadoutFull {
                        guard let replaceID = selectedReplaceID else { return }
                        vm.learnAttack(newAttackID: newID, replacing: replaceID)
                    } else {
                        vm.learnAttack(newAttackID: newID, replacing: nil)
                    }

                    vm.showAttackChoiceSheet = false
                    dismiss()
                } label: {
                    Text(loadoutFull ? "Learn and Replace" : "Learn Attack")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canConfirm ? Color.green.opacity(0.85) : Color.gray.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(!canConfirm)

                Spacer()
            }
            .navigationTitle("New Attack")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var canConfirm: Bool {
        if selectedNewID == nil { return false }
        if loadoutFull && selectedReplaceID == nil { return false }
        return true
    }
}
