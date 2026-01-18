import SwiftUI
import Foundation

struct MainMenuView: View {
    @ObservedObject var vm: GameViewModel
    @State private var animateXP: CGFloat
    @State private var showResetConfirm: Bool = false

    init(vm: GameViewModel) {
        self.vm = vm
        _animateXP = State(initialValue: vm.player.xpProgress)
    }

    var body: some View {
        let model = vm

        return NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    Text("Welcome, \(model.player.name)")
                        .font(.largeTitle)
                        .bold()

                    HStack(spacing: 10) {
                        ClassIcon(playerClass: model.player.playerClass, size: 18)
                        Text(model.player.playerClass.displayName)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    Text("Level \(model.player.level)")
                        .font(.title)
                        .bold()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("XP: \(Int(model.player.experience))/\(Int(model.player.xpForNextLevel))")
                            .font(.caption)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle().fill(.gray.opacity(0.3))
                                Rectangle()
                                    .fill(.green)
                                    .frame(width: geo.size.width * animateXP)
                            }
                            .frame(height: 12)
                            .cornerRadius(6)
                        }
                        .frame(height: 12)
                    }
                    .padding(.horizontal)

                    Text("Miles Journeyed: \(String(format: "%.1f", model.player.distanceProgress))")
                        .font(.headline)

                    // Mana + Past 7 Days + Intensity
                    PoolsCard(vm: model)

                    // MARK: - Menu buttons (Attack-button style)
                    VStack(spacing: 12) {

                        NavigationLink {
                            WorkoutChoiceView(vm: model)
                        } label: {
                            MenuButtonLabel(
                                text: "Workouts",
                                systemImage: "figure.walk",
                                background: RPGColors.endurance.opacity(0.85)
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            QuestSelectionView(vm: model)
                        } label: {
                            MenuButtonLabel(
                                text: "Quests",
                                systemImage: "map.fill",
                                background: RPGColors.rhythm.opacity(0.85)
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            SkillTreeView(vm: model)
                        } label: {
                            MenuButtonLabel(
                                text: "Skill Tree",
                                systemImage: "tree.fill",
                                background: RPGColors.precision.opacity(0.85)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // All Time effort stats below Skill Tree
                    AllTimeEffortsCard(vm: model)

                    // Trophy Room button underneath All Time effort stats
                    NavigationLink {
                        TrophyRoomView(vm: model)
                    } label: {
                        MenuButtonLabel(
                            text: "Trophy Room (\(model.player.defeatedEnemyIDs.count))",
                            systemImage: "trophy.fill",
                            background: Color.yellow.opacity(0.85)
                        )
                    }
                    .buttonStyle(.plain)

                    // Reset character BELOW All Time stats
                    Button {
                        showResetConfirm = true
                    } label: {
                        MenuButtonLabel(
                            text: "Reset Character",
                            systemImage: "trash.fill",
                            background: Color.red.opacity(0.85)
                        )
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog(
                        "Reset character?",
                        isPresented: $showResetConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Reset", role: .destructive) {
                            model.resetPlayer()
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This permanently clears your character, quests, mana, and effort stats on this device.")
                    }

                    Color.clear.frame(height: 16)
                }
                .padding()
            }
            .navigationTitle("Main Menu")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: model.player.xpProgress) { _, newValue in
                withAnimation(.easeOut(duration: 1)) {
                    animateXP = newValue
                }
            }
            .sheet(
                isPresented: Binding(
                    get: { model.showAttackChoiceSheet },
                    set: { model.showAttackChoiceSheet = $0 }
                )
            ) {
                AttackChoiceView(vm: model, choices: model.attackChoices)
            }
        }
    }
}

// MARK: - Trophy Room

private struct TrophyRoomView: View {
    @ObservedObject var vm: GameViewModel
    @State private var selected: TrophyEntry? = nil

    private struct TrophyEntry: Identifiable {
        let id: String          // enemy id
        let name: String        // enemy name
        let trophyText: String  // narrative.trophy
    }

    private var trophies: [TrophyEntry] {
        let defeated = vm.player.defeatedEnemyIDs
        guard !defeated.isEmpty else { return [] }

        // Build a lookup from the catalog so this remains source-of-truth.
        let allEnemies = EnemyCatalog.field + EnemyCatalog.cave + EnemyCatalog.seaside
        let byID = Dictionary(uniqueKeysWithValues: allEnemies.map { ($0.id, $0) })

        return defeated
            .map { id in
                if let e = byID[id] {
                    return TrophyEntry(id: id, name: e.name, trophyText: e.narrative.trophy)
                } else {
                    // If catalog changed and id no longer exists.
                    return TrophyEntry(id: id, name: id, trophyText: "A trophy from an earlier adventure.")
                }
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List {
            if trophies.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No trophies yet")
                            .font(.headline)
                        Text("Defeat an enemy in a quest to add it to your Trophy Room.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            } else {
                Section {
                    ForEach(trophies) { t in
                        Button {
                            selected = t
                        } label: {
                            HStack {
                                Text(t.name)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Trophies")
                } footer: {
                    Text("Tap a trophy to read its story.")
                }
            }
        }
        .navigationTitle("Trophy Room")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { t in
            TrophyDetailSheet(title: t.name, text: t.trophyText)
        }
    }
}

private struct TrophyDetailSheet: View {
    let title: String
    let text: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Attack-style menu label

private struct MenuButtonLabel: View {
    let text: String
    let systemImage: String
    let background: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))

            Text(text)
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct PoolsCard: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // MARK: - Mana
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Mana")
                        .font(.headline)

                    Spacer()

                    Text("\(vm.manaPoolCurrent())")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .monospacedDigit()

                    Text("/ \(vm.manaPoolMax())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                ProgressView(
                    value: Double(vm.manaPoolCurrent()),
                    total: Double(max(vm.manaPoolMax(), 1))
                )
                .tint(RPGColors.precision.opacity(0.85))

                Text("Apply a workout to refill the mana pool")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider().opacity(0.35)

            // MARK: - Efforts (Past 7 Days only)
            VStack(alignment: .leading, spacing: 10) {
                Text("Effort Stats")
                    .font(.headline)

                Text("Past 7 Days")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                effortRow(
                    affinity: .rhythm,
                    howToEarn: "Go for a walk",
                    value: countRecentWeek(.rhythm)
                )

                effortRow(
                    affinity: .endurance,
                    howToEarn: "Go for a run or a bike ride",
                    value: countRecentWeek(.endurance)
                )

                effortRow(
                    affinity: .force,
                    howToEarn: "Do traditional strength training",
                    value: countRecentWeek(.force)
                )

                effortRow(
                    affinity: .precision,
                    howToEarn: "Do another type of workout",
                    value: countRecentWeek(.precision)
                )
            }

            Divider().opacity(0.35)

            // MARK: - Intensity (derived from total efforts in the past 7 days)
            VStack(alignment: .leading, spacing: 10) {
                Text("Intensity")
                    .font(.headline)

                Text("Based on total efforts in the past 7 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                let total = totalEffortsRecentWeek()
                let tier = IntensityTier.tier(forWeeklyEfforts: total)

                HStack {
                    Text("Tier")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(tier.displayName)  ×\(String(format: "%.1f", tier.multiplier))")
                        .font(.subheadline)
                        .monospacedDigit()
                }

                HStack {
                    Text("Total efforts (7 days)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(total)")
                        .font(.subheadline)
                        .monospacedDigit()
                }

                Text("Your intensity multiplier increases mana regenerated per workout.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }

    private var rollingWeekStart: Date {
        Date().addingTimeInterval(-7 * 24 * 60 * 60)
    }

    private func countRecentWeek(_ a: Affinity) -> Int {
        vm.player.efforts
            .filter { $0.affinity == a && $0.earnedAt >= rollingWeekStart }
            .count
    }

    private func totalEffortsRecentWeek() -> Int {
        vm.player.efforts
            .filter { $0.earnedAt >= rollingWeekStart }
            .count
    }

    private func effortRow(affinity: Affinity, howToEarn: String, value: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            HStack(spacing: 10) {
                AffinityIcon(affinity: affinity, size: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(affinity.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(howToEarn)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("\(value)")
                .font(.subheadline)
                .monospacedDigit()
        }
    }
}

// MARK: - All Time Efforts (moved below Skill Tree button)

private struct AllTimeEffortsCard: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("All Time Effort Stats")
                    .font(.headline)
                Spacer()
            }

            effortRow(affinity: .rhythm, value: countLifetime(.rhythm))
            effortRow(affinity: .endurance, value: countLifetime(.endurance))
            effortRow(affinity: .force, value: countLifetime(.force))
            effortRow(affinity: .precision, value: countLifetime(.precision))
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }

    private func countLifetime(_ a: Affinity) -> Int {
        vm.player.efforts.filter { $0.affinity == a }.count
    }

    private func effortRow(affinity: Affinity, value: Int) -> some View {
        HStack {
            HStack(spacing: 10) {
                AffinityIcon(affinity: affinity, size: 18)
                Text(affinity.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(value)")
                .font(.subheadline)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
}

