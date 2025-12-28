//
//  ResultsView.swift
//  FittnessRPG
//
//  Created by Jacob Whitaker on 12/25/25.
//

import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var vm: GameViewModel
    let session: WorkoutSession

    @State private var applied = false
    @State private var showXPAnimation = false

    var alreadyApplied: Bool { vm.isApplied(session) }

    var body: some View {
        VStack(spacing: 25) {

            Text(session.type.rawValue.capitalized)
                .font(.largeTitle).bold()

            Text("Calories Burned: \(Int(session.calories))")
            Text("Distance: \(String(format: "%.2f", session.distanceMiles)) miles")

            Spacer()

            if !alreadyApplied {
                Button {
                    vm.applyWorkout(session)
                    applied = true
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.4)) {
                        showXPAnimation = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        showXPAnimation = false
                    }
                } label: {
                    Text("Apply Workout")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.85))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            } else {
                Text("Workout Already Applied")
                    .foregroundColor(.gray)
            }

            if showXPAnimation {
                Text("+\(Int(session.calories)) XP")
                    .font(.title)
                    .bold()
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Workout Result")
    }
}
