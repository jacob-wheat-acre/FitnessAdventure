//
//  WorkoutChoiceView.swift
//  FittnessRPG
//
//  Created by Jacob Whitaker on 12/25/25.
//

import SwiftUI

struct WorkoutChoiceView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var showLoading = false

    private var rollingSevenDaysAgo: Date {
        Date().addingTimeInterval(-7 * 24 * 60 * 60)
    }

    private var recentRollingSessions: [WorkoutSession] {
        vm.recentSessions
            .filter { $0.completedAt >= rollingSevenDaysAgo }
            .sorted { $0.completedAt > $1.completedAt }
    }

    var body: some View {
        VStack(spacing: 15) {

            Text("Fitness Workouts (Last Seven Days)")
                .font(.title)
                .bold()
                .padding(.top)

            Button {
                vm.requestHealthKitAccess()
                showLoading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showLoading = false
                }
            } label: {
                Text("Load Workouts")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            if showLoading {
                ProgressView("Fetching workouts...")
                    .padding()
            }

            // APPLY ALL (rolling 7×24 hours)
            if !recentRollingSessions.isEmpty {
                Button {
                    withAnimation(.easeOut(duration: 1)) {
                        vm.applyWorkouts(recentRollingSessions)
                    }
                } label: {
                    Text("Apply All Workouts")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding([.horizontal, .top])
            }

            // WORKOUT LIST
            List(recentRollingSessions) { session in
                NavigationLink {
                    ResultsView(session: session)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(session.type.rawValue.capitalized)
                                .font(.headline)

                            Text(
                                "Date: \(session.completedAt.formatted(date: .abbreviated, time: .shortened)) | " +
                                "Calories: \(Int(session.calories)) | " +
                                "Miles: \(String(format: "%.2f", session.distanceMiles))"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()

                        if vm.isApplied(session) {
                            Text("APPLIED")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
                .listRowBackground(vm.isApplied(session) ? Color.gray.opacity(0.2) : Color.clear)
            }

            Spacer()
        }
        .navigationTitle("Workouts")
    }
}
