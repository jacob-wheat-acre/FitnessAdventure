
import SwiftUI
import Combine

struct CharacterCreationView: View {
    @EnvironmentObject var vm: GameViewModel

    @State private var draftName: String = ""
    @State private var draftSpecies: Species = .Human
    @State private var draftClass: PlayerClass = .Knight

    var body: some View {
        VStack(spacing: 18) {
            Text("Create Your Hero")
                .font(.largeTitle)
                .bold()

            TextField("Name", text: $draftName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            // Species Picker
            Picker("Species", selection: $draftSpecies) {
                ForEach(Species.allCases, id: \.self) { species in
                    Text(species.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Class Picker
            Picker("Class", selection: $draftClass) {
                ForEach(PlayerClass.allCases, id: \.self) { cls in
                    Text(cls.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Button {
                createCharacter()
            } label: {
                Text("Create Character")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.85))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
    }

    private func createCharacter() {
        vm.player.name = draftName
        vm.player.species = draftSpecies
        vm.player.playerClass = draftClass

        vm.player.initializeSkills()
        vm.player.grantStarterAttackIfNeeded()
        vm.player.ensureAttackStateIsValid()

        vm.savePlayer()
    }
}
