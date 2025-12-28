//
//  QuestSelectionView.swift
//  FittnessRPG
//
//  Created by Jacob Whitaker on 12/25/25.
//

import SwiftUI

struct QuestSelectionView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose a Quest Area")
                .font(.title)
                .bold()
                .padding(.top)

            ForEach(vm.quests) { quest in
                let unlocked = vm.player.distanceProgress >= quest.unlockMiles
                let summary = vm.questSummaryText(for: quest)

                NavigationLink {
                    if unlocked {
                        QuestView(quest: quest)
                            .environmentObject(vm)
                    } else {
                        LockedQuestView(required: quest.unlockMiles)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(quest.name)
                                .font(.headline)
                            Text(summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(unlocked ? "Unlocked" : "Locked")
                            .foregroundColor(unlocked ? .green : .red)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Quests")
    }
}

struct LockedQuestView: View {
    let required: Double

    var body: some View {
        VStack {
            Text("Requires \(Int(required)) miles to enter.")
                .font(.title2)
                .padding()
            Spacer()
        }
    }
}
