import SwiftUI
import Foundation

struct LevelUpView: View {
    let snapshot: LevelUpSnapshot
    @ObservedObject var vm: GameViewModel
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Level Up!")
                .font(.title).bold()

            Text("You reached Level \(snapshot.newLevel).")

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Mana per workout")
                    Spacer()
                    Text("\(snapshot.manaPerWorkout)")
                        .bold()
                }

                HStack {
                    Text("Mana cap")
                    Spacer()
                    Text("\(snapshot.manaCap)")
                        .bold()
                }

                HStack {
                    Text("XP to next level")
                    Spacer()
                    Text(snapshot.xpToNextLevel == Int.max ? "MAX" : "\(snapshot.xpToNextLevel)")
                        .bold()
                }
            }
            .padding()
            .background(.thinMaterial)
            .cornerRadius(12)

            Spacer()

            Button("Continue") {
                // If you’re doing upgrade choices, this is where you’d route into that flow.
                // For now, dismiss:
                vm.dismissActiveSheet()
                vm.savePlayer()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

