import SwiftUI

struct CharacterCreationView: View {
    @ObservedObject var vm: GameViewModel

    @State private var draftName = ""
    @State private var draftClass: PlayerClass = .Knight

    @FocusState private var nameFocused: Bool

    private var trimmedName: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canCreate: Bool {
        !trimmedName.isEmpty
    }

    private let nameSuggestions: [String] = [
        "Reuel",
        "William",
        "Agatha",
        "Ernest",
        "Fyodor",
        "Isaac",
        "Gabriel",
        "Joanne",
        "George",
        "Franz"
    ]
    
    private var draftClassAccent: Color {
        switch draftClass {
        case .Knight: return RPGColors.force
        case .Wizard: return RPGColors.rhythm
        case .Jester: return RPGColors.endurance
        }
    }

    var body: some View {
        VStack(spacing: 20) {

            Text("Create Your Hero")
                .font(.largeTitle)
                .bold()

            // MARK: - Name entry (improved tone + UX)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text("What is thy name, adventurer?")
                        .font(.headline)

                    Spacer()
                }

                HStack(spacing: 10) {
                    TextField("Adventurer name", text: $draftName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .keyboardType(.namePhonePad)
                        .submitLabel(.done)
                        .focused($nameFocused)
                        .onSubmit { nameFocused = false }

                    if !trimmedName.isEmpty {
                        Button {
                            draftName = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear name")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
                )

                HStack {
                    Button("Use Random") {
                        if let pick = nameSuggestions.randomElement() {
                            draftName = pick
                            nameFocused = false
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(trimmedName.count)/24")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            //.onAppear {
                // Optional: start with keyboard ready (comment out if you dislike)
                // DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                //    nameFocused = true
            //    }
            //}



            // MARK: - Class picker + description
            VStack(alignment: .leading, spacing: 10) {
                Text("Class")
                    .font(.headline)

                // Replace your current HStack(spacing: 12) { ... } with this:

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(PlayerClass.allCases, id: \.self) { cls in
                        Button {
                            draftClass = cls
                        } label: {
                            VStack(spacing: 8) {
                                ClassIcon(playerClass: cls, size: 18)

                                Text(cls.displayName)
                                    .font(.subheadline)
                                    .fontWeight(draftClass == cls ? .semibold : .regular)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(draftClass == cls ? Color.primary.opacity(0.08) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.secondary.opacity(draftClass == cls ? 0.45 : 0.25), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(cls.displayName))
                    }
                }

                // Description box
                ClassDescriptionCard(selectedClass: draftClass)
            }

            Button {
                nameFocused = false

                vm.player.name = trimmedName
                vm.player.playerClass = draftClass
                vm.player.initializeSkills()

                vm.player.notifiedUsableAttackIDs = []
                vm.savePlayer()
                vm.addXP(0)
            } label: {
                HStack(spacing: 12) {
                    ClassIcon(playerClass: draftClass, size: 18)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Begin Adventure")
                            .font(.headline)

                        Text("Start with today’s small win")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    canCreate
                    ? draftClassAccent.opacity(0.85)
                    : RPGColors.neutral.opacity(0.45)
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(canCreate ? 0.15 : 0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canCreate)

            Spacer()
        }
        .padding()
    }
}

private struct ClassDescriptionCard: View {
    let selectedClass: PlayerClass

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 10) {
                ClassIcon(playerClass: selectedClass, size: 18)
                Text("\(selectedClass.displayName) Overview")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {

                // MARK: - Bias with Effort icons
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bias")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        ForEach(biasAffinities, id: \.self) { affinity in
                            HStack(spacing: 6) {
                                AffinityIcon(affinity: affinity, size: 16)
                                Text(affinity.displayName)
                                    .font(.body)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(affinity.uiColor.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }

                infoRow(label: "Fantasy", value: fantasyText)
                infoRow(label: "Who it fits", value: whoItFitsText)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.20), lineWidth: 1)
        )
    }

    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var biasAffinities: [Affinity] {
        switch selectedClass {
        case .Knight: return [.force, .endurance]
        case .Wizard: return [.rhythm, .precision]
        case .Jester: return [.endurance, .rhythm]
        }
    }

    private var fantasyText: String {
        switch selectedClass {
        case .Knight: return "Direct, forceful, heavy-duty hits"
        case .Wizard: return "Channel life-force into controlled strikes"
        case .Jester: return "Win through timing, flow, and consistency"
        }
    }

    private var whoItFitsText: String {
        switch selectedClass {
        case .Knight:
            return "People who like lifting, running, and hustling"
        case .Wizard:
            return "People who value technique-driven workouts, experimentation, and creativity"
        case .Jester:
            return "Walkers, runners, bicyclists, people who appreciate spontaneity"
        }
    }
}
