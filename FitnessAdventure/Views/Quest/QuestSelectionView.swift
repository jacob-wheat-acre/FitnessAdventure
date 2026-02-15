
import SwiftUI

struct QuestSelectionView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            mapBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    header

                    VStack(spacing: 10) {
                        ForEach(Array(vm.quests.enumerated()), id: \.element.id) { idx, quest in
                            let unlocked = isUnlocked(quest)
                            let completed = vm.isQuestCompleted(quest)
                            let claimed = vm.isQuestRewardClaimed(quest)

                            VStack(alignment: .leading, spacing: 8) {

                                // Node row
                                if unlocked {
                                    NavigationLink {
                                        QuestView(vm: vm, quest: quest)
                                    } label: {
                                        QuestMapNode(
                                            title: quest.name,
                                            subtitle: subtitleText(for: quest,
                                                                  unlocked: unlocked,
                                                                  completed: completed,
                                                                  claimed: claimed),
                                            systemImage: regionIcon(for: quest),
                                            isUnlocked: true,
                                            isCompleted: completed,
                                            rewardReady: (completed && !claimed),
                                            isCurrent: isCurrentNode(quest: quest, unlocked: unlocked, completed: completed),
                                            color: regionColor(for: quest)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    QuestMapNode(
                                        title: quest.name,
                                        subtitle: subtitleText(for: quest,
                                                              unlocked: unlocked,
                                                              completed: completed,
                                                              claimed: claimed),
                                        systemImage: regionIcon(for: quest),
                                        isUnlocked: false,
                                        isCompleted: false,
                                        rewardReady: false,
                                        isCurrent: false,
                                        color: regionColor(for: quest)
                                    )
                                    .allowsHitTesting(false)
                                    .opacity(0.70)
                                }

                                // Connector to next node
                                if idx < vm.quests.count - 1 {
                                    MapConnector(isActive: unlocked)
                                        .padding(.leading, 6)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    Color.clear.frame(height: 18)
                }
                .padding(.top, 10)
            }
        }
        .navigationTitle("Quests")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Quest Map")
                .font(.largeTitle)
                .bold()
                .padding(.horizontal)

            Text("Follow the road. Complete regions to earn rewards and unlock the next path.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }

    // MARK: - Background

    private var mapBackground: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.secondarySystemBackground).opacity(0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Canvas { ctx, size in
                // subtle dot grid (reads as “map texture”)
                let step: CGFloat = 24
                for x in stride(from: 0, through: size.width, by: step) {
                    for y in stride(from: 0, through: size.height, by: step) {
                        let r = CGRect(x: x, y: y, width: 1.2, height: 1.2)
                        ctx.fill(Path(ellipseIn: r), with: .color(.secondary.opacity(0.10)))
                    }
                }
            }
        )
    }

    // MARK: - Helpers (preserved from original)

    private func isUnlocked(_ quest: QuestArea) -> Bool {
        vm.player.distanceProgress >= quest.unlockMiles
    }

    private func subtitleText(for quest: QuestArea,
                              unlocked: Bool,
                              completed: Bool,
                              claimed: Bool) -> String {
        if !unlocked {
            return "Locked — unlocks at \(quest.unlockMiles) miles"
        }

        if completed {
            return claimed ? "Completed" : "Reward ready (\(quest.rewardButtonName))"
        }

        return vm.questSummaryText(for: quest)
    }

    // MARK: - “Current node” heuristic

    /// The first quest that is unlocked and not completed gets a subtle ring.
    private func isCurrentNode(quest: QuestArea, unlocked: Bool, completed: Bool) -> Bool {
        guard unlocked, !completed else { return false }
        for q in vm.quests {
            if isUnlocked(q) && !vm.isQuestCompleted(q) {
                return q.id == quest.id
            }
        }
        return false
    }

    // MARK: - Region styling

    private func regionIcon(for quest: QuestArea) -> String {
        switch quest.name.lowercased() {
        case "field": return "leaf.fill"
        case "cave": return "mountain.2.fill"
        case "seaside": return "water.waves"
        default: return "map.fill"
        }
    }

    private func regionColor(for quest: QuestArea) -> Color {
        switch quest.name.lowercased() {
        case "field": return RPGColors.rhythm.opacity(0.90)
        case "cave": return RPGColors.force.opacity(0.90)
        case "seaside": return RPGColors.endurance.opacity(0.90)
        default: return RPGColors.neutral.opacity(0.90)
        }
    }
}

// MARK: - Map node (card + icon badge)

private struct QuestMapNode: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isUnlocked: Bool
    let isCompleted: Bool
    let rewardReady: Bool
    let isCurrent: Bool
    let color: Color

    var body: some View {
        HStack(alignment: .center, spacing: 14) {

            ZStack {
                if isCurrent {
                    Circle()
                        .stroke(color.opacity(0.55), lineWidth: 4)
                        .frame(width: 58, height: 58)
                }

                Circle()
                    .fill(isUnlocked ? color : Color.gray.opacity(0.35))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle().strokeBorder(.white.opacity(isUnlocked ? 0.25 : 0.12), lineWidth: 1)
                    )
                    .shadow(color: isUnlocked ? color.opacity(0.22) : .clear, radius: 10, y: 4)

                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(isUnlocked ? 0.95 : 0.75))

                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .offset(x: 16, y: 16)
                }

                if isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.95))
                        .offset(x: -16, y: 16)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(isUnlocked ? .primary : .secondary)

                    if rewardReady && isUnlocked {
                        Text("XP")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary.opacity(isUnlocked ? 0.9 : 0.3))
                .opacity(isUnlocked ? 1.0 : 0.0)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(isUnlocked ? 0.12 : 0.06), lineWidth: 1)
        )
        .opacity(isUnlocked ? 1.0 : 0.75)
    }
}

// MARK: - Connector between nodes

private struct MapConnector: View {
    let isActive: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Align connector under the badge center
            Rectangle()
                .fill(isActive ? Color.secondary.opacity(0.30) : Color.secondary.opacity(0.16))
                .frame(width: 3, height: 30)
                .cornerRadius(2)

            Spacer()
        }
        .padding(.leading, 22) // aligns under the badge circle
    }
}
