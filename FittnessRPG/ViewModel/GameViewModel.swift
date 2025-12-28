import Foundation
import SwiftUI
import HealthKit
import Combine

final class GameViewModel: ObservableObject {
    @Published var player: Player
    @Published var recentSessions: [WorkoutSession] = []

    // Level-up Attack Choice UI
    @Published var showAttackChoiceSheet: Bool = false
    @Published var attackChoices: [AttackDefinition] = []

    // MARK: - Quests (definitions)
    @Published var quests: [QuestArea] = [
        QuestArea(
            name: "Field",
            unlockMiles: 0,
            enemies: [
                Enemy(name: "Slime", requiredAttackHint: "Any attack", HP: 10, mockingLine: "Slime jiggles. You slap like pudding."),
                Enemy(name: "Goblin", requiredAttackHint: "Try something stronger", HP: 20, mockingLine: "Goblin laughs. Come back when you grow legs!"),
                Enemy(name: "Wolf", requiredAttackHint: "Bring real force", HP: 30, mockingLine: "Wolf yawns. That tickled.")
            ],
            rewardsXP: 300
        ),
        QuestArea(
            name: "Cave",
            unlockMiles: 5,
            enemies: [
                Enemy(name: "Bat Swarm", requiredAttackHint: "Fast hits help", HP: 20, mockingLine: "Bats screech. Try again, groundwalker!"),
                Enemy(name: "Ogre", requiredAttackHint: "Heavy blows", HP: 30, mockingLine: "Ogre smirks. You call that effort?"),
                Enemy(name: "Stone Golem", requiredAttackHint: "Big damage", HP: 40, mockingLine: "Golem does not move. You are beneath notice.")
            ],
            rewardsXP: 600
        ),
        QuestArea(
            name: "Seaside",
            unlockMiles: 10,
            enemies: [
                Enemy(name: "Crab", requiredAttackHint: "Break the shell", HP: 50, mockingLine: "Crab snaps claws. Weak like sea foam!"),
                Enemy(name: "Merfolk Guard", requiredAttackHint: "Prove yourself", HP: 60, mockingLine: "Guard flicks hair. Pathetic."),
                Enemy(name: "Leviathan", requiredAttackHint: "Peak power", HP: 70, mockingLine: "Leviathan laughs. Return with real power.")
            ],
            rewardsXP: 1000
        )
    ]

    init() {
        self.player = PersistenceManager.shared.loadPlayer() ?? Player()
        self.player.grantStarterAttackIfNeeded()
        self.player.ensureAttackStateIsValid()
        savePlayer()
    }

    func savePlayer() { PersistenceManager.shared.savePlayer(player) }

    func resetPlayer() {
        PersistenceManager.shared.clearPlayer()
        player = Player()
        player.grantStarterAttackIfNeeded()
        player.ensureAttackStateIsValid()
        savePlayer()
    }

    // MARK: - HealthKit
    func requestHealthKitAccess() {
        HealthKitManager.shared.requestAuthorization { success in
            if success { self.loadWorkouts() }
        }
    }

    func loadWorkouts() {
        HealthKitManager.shared.fetchRecentWorkouts { workouts in
            var sessions: [WorkoutSession] = []
            let group = DispatchGroup()

            for workout in workouts {
                group.enter()
                HealthKitManager.shared.fetchCalories(for: workout) { calories in
                    HealthKitManager.shared.fetchDistance(for: workout) { distance in
                        let type: WorkoutType
                        switch workout.workoutActivityType {
                        case .running, .walking: type = .run
                        case .cycling: type = .cycle
                        default: type = .strength
                        }

                        sessions.append(
                            WorkoutSession(
                                id: workout.uuid,
                                type: type,
                                calories: calories,
                                distanceMiles: distance,
                                completedAt: workout.endDate
                            )
                        )
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                self.recentSessions = sessions.sorted { $0.completedAt > $1.completedAt }
            }
        }
    }

    // MARK: - Workouts -> XP/Distance + Mana
    func applyWorkout(_ session: WorkoutSession) {
        guard !player.appliedWorkoutIDs.contains(where: { $0 == session.id }) else { return }

        let previousLevel = player.level
        _ = player.applyWorkout(session.id, calories: session.calories, distance: session.distanceMiles)

        replenishManaPerWorkout()

        savePlayer()

        if player.level > previousLevel {
            presentAttackChoiceIfAvailable()
        }
    }

    func applyWorkouts(_ sessions: [WorkoutSession]) {
        for session in sessions { applyWorkout(session) }
    }

    func applyAllWorkouts() {
        for session in recentSessions { applyWorkout(session) }
    }

    func isApplied(_ session: WorkoutSession) -> Bool {
        player.appliedWorkoutIDs.contains(session.id)
    }

    // MARK: - XP (general)
    func addXP(_ amount: Int) {
        let previousLevel = player.level
        _ = player.addXP(amount)
        savePlayer()

        if player.level > previousLevel {
            presentAttackChoiceIfAvailable()
        }
    }

    // MARK: - Attacks / Loadout / Mana (read-only in body-safe helpers)
    func currentEquippedAttacks() -> [AttackDefinition] {
        let cls = player.playerClass
        return player.equippedAttackIDs.compactMap { AttackCatalog.attack(for: cls, id: $0) }
    }

    func mana(for attackID: String) -> Int {
        player.manaByAttackID[attackID] ?? 0
    }

    func spendMana(for attackID: String) -> Bool {
        let current = player.manaByAttackID[attackID] ?? 0
        guard current > 0 else { return false }
        player.manaByAttackID[attackID] = current - 1
        savePlayer()
        return true
    }

    private func replenishManaPerWorkout() {
        player.ensureAttackStateIsValid()
        let cls = player.playerClass

        for attackID in player.equippedAttackIDs {
            guard let def = AttackCatalog.attack(for: cls, id: attackID) else { continue }
            let current = player.manaByAttackID[attackID] ?? 0
            player.manaByAttackID[attackID] = min(def.maxMana, current + 1)
        }
    }

    func learnAttack(newAttackID: String, replacing replacedID: String?) {
        player.ownedAttackIDs.insert(newAttackID)

        if let def = AttackCatalog.attack(for: player.playerClass, id: newAttackID) {
            player.manaByAttackID[newAttackID] = def.maxMana
        } else {
            player.manaByAttackID[newAttackID] = player.manaByAttackID[newAttackID] ?? 0
        }

        if let replacedID {
            if let idx = player.equippedAttackIDs.firstIndex(of: replacedID) {
                player.equippedAttackIDs[idx] = newAttackID
            } else if player.equippedAttackIDs.count < player.equippedLimit {
                player.equippedAttackIDs.append(newAttackID)
            }
        } else {
            if player.equippedAttackIDs.count < player.equippedLimit {
                player.equippedAttackIDs.append(newAttackID)
            }
        }

        player.ensureAttackStateIsValid()
        savePlayer()
    }

    func presentAttackChoiceIfAvailable() {
        player.ensureAttackStateIsValid()

        let choices = AttackCatalog.learnableAttacks(
            for: player.playerClass,
            atLevel: player.level,
            excluding: player.ownedAttackIDs
        )

        guard !choices.isEmpty else { return }

        attackChoices = Array(choices.prefix(6))
        showAttackChoiceSheet = true
    }

    // MARK: - Quest persistence (Phase 2)

    /// Read-only: returns current progress (or default). Does not mutate.
    func progress(for questName: String) -> QuestAreaProgress {
        player.questProgressByAreaName[questName] ?? QuestAreaProgress()
    }

    /// Mutating: saves progress.
    private func setProgress(_ p: QuestAreaProgress, for questName: String) {
        player.questProgressByAreaName[questName] = p
        savePlayer()
    }

    /// Returns the current enemy + current HP (persisted) for this quest, or nil if completed/invalid.
    /// Read-only: does not mutate player.
    func currentEnemyState(for quest: QuestArea) -> (enemy: Enemy, hp: Int, index: Int, total: Int)? {
        let p = progress(for: quest.name)
        guard !p.completed else { return nil }
        guard quest.enemies.indices.contains(p.currentEnemyIndex) else { return nil }

        let enemy = quest.enemies[p.currentEnemyIndex]
        let hp = p.currentEnemyHP ?? enemy.HP
        return (enemy, hp, p.currentEnemyIndex, quest.enemies.count)
    }

    struct QuestDamageResult {
        let enemyDefeated: Bool
        let questCompleted: Bool
        let newHP: Int
        let newIndex: Int
    }

    /// Applies damage to the current enemy, persisting HP and advancing when defeated.
    /// Mutating: updates and saves player.
    func applyDamage(_ damage: Int, in quest: QuestArea) -> QuestDamageResult? {
        var p = progress(for: quest.name)
        guard !p.completed else { return nil }
        guard quest.enemies.indices.contains(p.currentEnemyIndex) else { return nil }

        let enemy = quest.enemies[p.currentEnemyIndex]
        let currentHP = p.currentEnemyHP ?? enemy.HP

        let newHP = max(0, currentHP - max(0, damage))

        if newHP == 0 {
            // Enemy defeated: advance to next enemy
            p.currentEnemyIndex += 1
            p.currentEnemyHP = nil

            if p.currentEnemyIndex >= quest.enemies.count {
                // Quest completed
                p.completed = true
            }
        } else {
            // Persist remaining HP
            p.currentEnemyHP = newHP
        }

        setProgress(p, for: quest.name)

        return QuestDamageResult(
            enemyDefeated: newHP == 0,
            questCompleted: p.completed,
            newHP: newHP,
            newIndex: p.currentEnemyIndex
        )
    }

    func isQuestCompleted(_ quest: QuestArea) -> Bool {
        progress(for: quest.name).completed
    }

    func isQuestRewardClaimed(_ quest: QuestArea) -> Bool {
        progress(for: quest.name).rewardClaimed
    }

    /// Claim quest reward once. Mutating: saves player and grants XP.
    @discardableResult
    func claimQuestReward(_ quest: QuestArea) -> Bool {
        var p = progress(for: quest.name)
        guard p.completed, !p.rewardClaimed else { return false }

        p.rewardClaimed = true
        setProgress(p, for: quest.name)

        addXP(quest.rewardsXP)
        return true
    }

    /// Read-only label for quest selection UI
    func questSummaryText(for quest: QuestArea) -> String {
        let p = progress(for: quest.name)
        if p.completed {
            return p.rewardClaimed ? "Completed (Reward Claimed)" : "Completed (Reward Ready)"
        }
        let idx = min(max(0, p.currentEnemyIndex), max(quest.enemies.count - 1, 0))
        return "Enemy \(idx + 1)/\(quest.enemies.count)"
    }
}
