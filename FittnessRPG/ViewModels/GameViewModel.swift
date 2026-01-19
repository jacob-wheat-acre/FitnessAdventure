//
//  GameViewModel.swift
//  FittnessRPG
//

import Foundation
import SwiftUI
import HealthKit
import Combine

final class GameViewModel: ObservableObject {
    @Published var player: Player
    @Published var recentSessions: [WorkoutSession] = []
    @Published var lastEarnedEffort: Effort? = nil

    @Published var attackChoices: [Attack] = []
    
    // for routing between Attack selection sheet and level up sheet
    @Published var activeSheet: ActiveSheet? = nil
    private var pendingSheets: [ActiveSheet] = []
    
    // In-memory encounter cache (per quest area)
    @Published private var encounterByQuestName: [String: EncounterState] = [:]

    @Published var quests: [QuestArea] = [
        QuestArea(name: "Field", unlockMiles: 0, enemies: EnemyCatalog.field, rewardButtonName: "Field Button"),
        QuestArea(name: "Cave", unlockMiles: 20, enemies: EnemyCatalog.cave, rewardButtonName: "Cave Button"),
        QuestArea(name: "Seaside", unlockMiles: 35, enemies: EnemyCatalog.seaside, rewardButtonName: "Seaside Button")
    ]
    
    @Published var defeatPopupMessage: String? = nil
    @Published var defeatPopupEnemyName: String? = nil
    
    @Published var levelUpSnapshot: LevelUpSnapshot? = nil
    
    @Published var applyAllSummary: ApplyAllSummary? = nil

    // MARK: - Sheet mechanics and queue
    

    func presentSheetNow(_ sheet: ActiveSheet) {
        guard !isAlreadyScheduled(sheet) else { return }
        
        if activeSheet == nil {
            activeSheet = sheet
        } else {
            pendingSheets.append(sheet)
        }
    }

    func enqueueSheet(_ sheet: ActiveSheet) {
        guard !isAlreadyScheduled(sheet) else { return }
        
        switch sheet {
        case .levelUp:
            //insert before the first attackchoice, so levelup always precedes it.
            if let idx = pendingSheets.firstIndex(where: { $0.id == "attackChoice" }) {
                pendingSheets.insert(sheet, at: idx)
            } else {
                pendingSheets.append(sheet)
            }
            
        default:
            pendingSheets.append(sheet)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.presentNextSheetIfPossible()
        }
    }

    func dismissActiveSheet() {
        print("DISMISS active=\(activeSheet?.id ?? "nil") pendingSheets.map{ $0.id}")
        activeSheet = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.presentNextSheetIfPossible()
        }
        
        print("AFTER dismiss active=\(activeSheet?.id ?? "nil") pending=\(pendingSheets.map{$0.id})")
    }

    private func presentNextSheetIfPossible() {
        guard activeSheet == nil else { return }
        guard !pendingSheets.isEmpty else { return }
        activeSheet = pendingSheets.removeFirst()
    }
    
    private func isAlreadyScheduled(_ sheet: ActiveSheet) -> Bool {
        if activeSheet?.id == sheet.id { return true }
        return pendingSheets.contains(where: {$0.id == sheet.id })
    }

    
    // MARK: - Manual session persistence (JSON file in Documents)

    private let manualSessionsFilename = "manual_workouts_v1.json"

    private var manualSessionsURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(manualSessionsFilename)
    }

    private func loadManualSessionsFromDisk() -> [WorkoutSession] {
        do {
            let url = manualSessionsURL
            guard FileManager.default.fileExists(atPath: url.path) else { return [] }
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([WorkoutSession].self, from: data)
            return decoded
        } catch {
            // If decoding fails (schema drift), fail soft: return empty rather than crash.
            return []
        }
    }

    private func saveManualSessionsToDisk(_ sessions: [WorkoutSession]) {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: manualSessionsURL, options: [.atomic])
        } catch {
            // Fail soft; do nothing.
        }
    }

    /// Public: add a manually entered workout and persist it.
    func addManualSession(_ session: WorkoutSession) {
        var stored = loadManualSessionsFromDisk()

        // De-dupe by ID
        guard !stored.contains(where: { $0.id == session.id }) else {
            // Still ensure UI has it
            mergeAndPublishSessions(healthKitSessions: [], manualSessions: stored)
            return
        }

        stored.append(session)
        saveManualSessionsToDisk(stored)

        // Update UI list immediately (manual-only merge)
        mergeAndPublishSessions(healthKitSessions: [], manualSessions: stored)
    }

    /// Optional but handy later (e.g., swipe-to-delete for manual sessions).
    func deleteManualSession(_ session: WorkoutSession) {
        var stored = loadManualSessionsFromDisk()
        stored.removeAll { $0.id == session.id }
        saveManualSessionsToDisk(stored)

        // Remove from UI list as well
        recentSessions.removeAll { $0.id == session.id }
        recentSessions.sort { $0.completedAt > $1.completedAt }
    }

    // MARK: - Init / Player persistence

    init() {
        self.player = PersistenceManager.shared.loadPlayer() ?? Player()

        // Ensure pool key exists
        if player.manaByAttackID["__mana_pool"] == nil {
            player.manaPool = player.manaPool
        }

        // Defensive: cap pool if definitions changed
        player.manaPool = min(player.manaPool, manaPoolMax())

        // Seed the list with manual sessions so non-HealthKit users see history immediately.
        let manual = loadManualSessionsFromDisk()
        self.recentSessions = manual.sorted { $0.completedAt > $1.completedAt }

        savePlayer()
    }

    func savePlayer() { PersistenceManager.shared.savePlayer(player) }

    func resetPlayer() {
        PersistenceManager.shared.clearPlayer()
        player = Player()
        player.manaPool = 0
        lastEarnedEffort = nil
        encounterByQuestName = [:]
        activeSheet = nil
        attackChoices = []
        levelUpSnapshot = nil
        UserDefaults.standard.set(false, forKey: "hasSeenOpeningHook")
        


        saveManualSessionsToDisk([])
        recentSessions = []

        savePlayer()
    }

    // MARK: - Attacks (Unlocked by level; no loadouts)

    func currentKnownAttacks() -> [Attack] {
        let cls = player.playerClass
        return AttackCatalog.attacks(for: cls)
            .filter { $0.requiredLevel <= player.level }
            .sorted { a, b in
                if a.requiredLevel != b.requiredLevel { return a.requiredLevel < b.requiredLevel }
                return a.name < b.name
            }
    }

    // MARK: - Intensity (rolling 7-day)

    func totalWeeklyEfforts(now: Date = Date()) -> Int {
        let start = now.addingTimeInterval(-7 * 24 * 60 * 60)
        return player.efforts.filter { $0.earnedAt >= start }.count
    }

    func currentIntensityTier(now: Date = Date()) -> IntensityTier {
        IntensityTier.tier(forWeeklyEfforts: totalWeeklyEfforts(now: now))
    }

    func currentIntensityMultiplier(now: Date = Date()) -> Double {
        currentIntensityTier(now: now).multiplier
    }

    // MARK: - Mana Pool

    func manaPoolCurrent() -> Int { player.manaPool }

    func manaPoolMax() -> Int {
        LevelRules.manaCap(for: player.level)
    }

    private func replenishManaPoolPerWorkout() {
        let baseGain = LevelRules.manaPerWorkout(for: player.level)
        if baseGain <= 0 { return }

        let multiplier = currentIntensityMultiplier()
        let scaledGain = Int((Double(baseGain) * multiplier).rounded(.down))

        let finalGain = max(1, scaledGain) // always at least 1

        let cap = manaPoolMax()
        player.manaPool = min(cap, player.manaPool + finalGain)
    }

    // MARK: - HealthKit

    func requestHealthKitAccess() {
        HealthKitManager.shared.requestAuthorization { success in
            if success { self.loadWorkouts() }
        }
    }

    func loadWorkouts() {
        HealthKitManager.shared.fetchWorkouts(inLastHours: 72) { workouts in
            var hkSessions: [WorkoutSession] = []
            let group = DispatchGroup()

            for workout in workouts {
                group.enter()

                HealthKitManager.shared.fetchCalories(for: workout) { calories in
                    HealthKitManager.shared.fetchDistance(for: workout) { distance in
                        HealthKitManager.shared.fetchAverageHeartRate(for: workout) { avgHR in

                            let type = self.mapWorkoutType(workout.workoutActivityType)
                            let durationMinutes = max(0, workout.duration / 60.0)

                            hkSessions.append(
                                WorkoutSession(
                                    id: workout.uuid,
                                    type: type,
                                    calories: calories,
                                    distanceMiles: distance,
                                    durationMinutes: durationMinutes,
                                    avgHeartRate: avgHR,
                                    completedAt: workout.endDate
                                )
                            )

                            group.leave()
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                let manual = self.loadManualSessionsFromDisk()
                self.mergeAndPublishSessions(healthKitSessions: hkSessions, manualSessions: manual)
            }
        }
    }

    private func mergeAndPublishSessions(healthKitSessions: [WorkoutSession], manualSessions: [WorkoutSession]) {
        // Combine and de-dupe by id, prefer the newest instance if duplicates exist.
        let combined = healthKitSessions + manualSessions

        var byID: [UUID: WorkoutSession] = [:]
        for s in combined {
            if let existing = byID[s.id] {
                // Keep whichever has later completedAt (generally safest)
                byID[s.id] = (s.completedAt >= existing.completedAt) ? s : existing
            } else {
                byID[s.id] = s
            }
        }

        self.recentSessions = Array(byID.values).sorted { $0.completedAt > $1.completedAt }
    }

    private func mapWorkoutType(_ hkType: HKWorkoutActivityType) -> WorkoutType {
        switch hkType {
        case .running: return .run
        case .walking, .hiking: return .walk
        case .cycling: return .cycle
        case .traditionalStrengthTraining: return .strength
        default: return .other
        }
    }

    // MARK: - Workouts -> XP/Distance + Mana + Efforts + Notifications

    func applyWorkout(_ session: WorkoutSession) {
        guard !player.appliedWorkoutIDs.contains(where: { $0 == session.id }) else { return }
      
        let oldLevel = player.level
        
        let creditedDistance = (session.type == .cycle)
            ? (max(0, session.distanceMiles * 0.5))
            : max(0, session.distanceMiles)
        
        let levelUps = player.applyWorkout(
            session.id,
            calories: session.calories,
            distance: creditedDistance
            )
        
        if levelUps > 0 {
            //print("ENQUEUE levelUp: +\(levelUps) newLevel+\(player.level)") <-keeping this for future debugging
            player.unspentLevelUps += levelUps
            let snap = makeLevelUpSnapshot(for: player.level) //new level after applying
            enqueueSheet(.levelUp(snap))
        }
        
        replenishManaPoolPerWorkout()
        awardEffort(for: session)

        // Cap pool (defensive)
        player.manaPool = min(player.manaPool, manaPoolMax())

        presentNewlyUsableAttacksIfNeeded()
        savePlayer()
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

    private func awardEffort(for session: WorkoutSession) {
        let affinity: Affinity
        switch session.type {
        case .walk: affinity = .rhythm
        case .strength: affinity = .force
        case .run, .cycle: affinity = .endurance
        case .other: affinity = .precision
        }

        let tierResult = EffortTierRules.tier(
            workoutType: session.type,
            avgHeartRate: session.avgHeartRate,
            calories: session.calories,
            durationMinutes: session.durationMinutes
        )

        // Tier → amount (Easy=1, Moderate=2, Hard=3)
        let amount: Int
        switch tierResult.tier {
        case .easy: amount = 1
        case .moderate: amount = 2
        case .hard: amount = 3
        }

        var last: Effort? = nil
        for _ in 0..<amount {
            let e = Effort(affinity: affinity, tier: tierResult.tier, earnedAt: session.completedAt)
            player.addEffort(e)
            last = e
        }
        lastEarnedEffort = last
    }

    // MARK: - XP

    func addXP(_ amount: Int) {
        let oldLevel = player.level
        _ = player.addXP(amount)

        let newLevel = player.level
        let levelsGained = max(0, newLevel - oldLevel)

        if levelsGained > 0 {
            player.unspentLevelUps += levelsGained
            enqueueSheet(.levelUp(makeLevelUpSnapshot(for: newLevel)))
        }

        savePlayer()
    }


    // MARK: - Effective attack (modifiers for attacks based on weekly effort stats
    struct EffectiveAttack {
        let manaCost: Int
        let effects: [AttackEffect]
        let hpRemoved: Int
        let armorRemoved: Int
    }

    private var rollingWeekStart: Date {
        Date().addingTimeInterval(-7 * 24 * 60 * 60)
    }

    private func weeklyEffortCount(_ affinity: Affinity, now: Date = Date()) -> Int {
        let start = now.addingTimeInterval(-7 * 24 * 60 * 60)
        return player.efforts.filter { $0.affinity == affinity && $0.earnedAt >= start }.count
    }

    func effectiveAttack(for attack: Attack, now: Date = Date()) -> EffectiveAttack {
        // Start from base values in the attack definition.
        var mana = max(0, attack.manaCost)

        // Consolidate base effects into numeric buckets
        var hp = 0
        var armor = 0

        for e in attack.effects {
            switch e {
            case .removeHP(let amount):
                hp += max(0, amount)
            case .removeArmor(let amount):
                armor += max(0, amount)
            }
        }

        // Apply modifiers (boosters/discounts)
        for mod in attack.modifiers {
            switch mod {

            case .manaDiscountWeeklyEffort(let affinity, let every, let minCost):
                let denom = max(1, every)
                let floorMin = max(1, minCost)

                let wk = weeklyEffortCount(affinity, now: now)
                let discount = wk / denom

                mana = max(floorMin, mana - discount)

            case .addHPPerWeeklyEffort(let affinity, let perEffort):
                let wk = weeklyEffortCount(affinity, now: now)
                hp += max(0, wk * perEffort)

            case .addArmorPerWeeklyEffort(let affinity, let perEffort):
                let wk = weeklyEffortCount(affinity, now: now)
                armor += max(0, wk * perEffort)
            }
        }
        

        // Rebuild effective effects list (single removeHP/removeArmor entries)
        var out: [AttackEffect] = []
        if armor > 0 { out.append(.removeArmor(amount: armor)) }
        if hp > 0 { out.append(.removeHP(amount: hp)) }

        return EffectiveAttack(manaCost: mana, effects: out, hpRemoved: hp, armorRemoved: armor)
    }

    // MARK: - Requirement gating (multi-effort, COUNT ONLY)

    func meetsRequirementForUseOutsideEncounter(_ attack: Attack) -> Bool {
        guard attack.requiredLevel <= player.level else { return false }
        guard let req = attack.requirement else { return true }

        for gate in req.gates {
            let have = player.effortCount(affinity: gate.affinity, minTier: nil) // count ALL units
            if have < gate.minCount { return false }
        }
        return true
    }

    func requirementText(for attack: Attack) -> String {
        attack.requirement?.displayText() ?? "None"
    }

    private func presentNewlyUsableAttacksIfNeeded() {
        // Don't show during bootstrap / character creation
        guard !player.name.isEmpty else { return }
        
        let known = currentKnownAttacks()
        let usableNow = known.filter { meetsRequirementForUseOutsideEncounter($0) }

        let newIDs = usableNow.map { $0.id }.filter { !player.notifiedUsableAttackIDs.contains($0) }
        guard !newIDs.isEmpty else { return }

        let newlyUsable = usableNow.filter { newIDs.contains($0.id) }

        player.notifiedUsableAttackIDs.formUnion(newlyUsable.map { $0.id })

        attackChoices = newlyUsable
        enqueueSheet(.attackChoice)
        
        guard activeSheet == nil else { return }
        activeSheet = .attackChoice
    }

    // MARK: - Quest persistence

    func progress(for questName: String) -> QuestAreaProgress {
        player.questProgressByAreaName[questName] ?? QuestAreaProgress()
    }

    private func setProgress(_ p: QuestAreaProgress, for questName: String) {
        player.questProgressByAreaName[questName] = p
        savePlayer()
    }

    func currentEnemyState(for quest: QuestArea) -> (enemy: RPGEnemy, currentHP: Int, maxHP: Int, index: Int, total: Int)? {
        let p = progress(for: quest.name)
        guard !p.completed else { return nil }
        guard quest.enemies.indices.contains(p.currentEnemyIndex) else { return nil }

        let baseEnemy = quest.enemies[p.currentEnemyIndex]
        let maxHP = max(0, baseEnemy.hp)
        let currentHP = p.currentEnemyHP ?? maxHP

        return (baseEnemy, max(0, currentHP), maxHP, p.currentEnemyIndex, quest.enemies.count)
    }

    // MARK: - EncounterEngine integration

    func encounterState(for quest: QuestArea) -> EncounterState? {
        guard let raw = currentEnemyState(for: quest) else { return nil }

        if let cached = encounterByQuestName[quest.name],
           cached.enemy.id == raw.enemy.id {
            return cached
        }

        let p = progress(for: quest.name)

        var enemy = raw.enemy
        enemy.hp = raw.currentHP

        // Restore persisted armor (otherwise armor regenerates on relaunch / navigation)
        if let persistedArmor = p.currentEnemyArmor {
            enemy.armor = persistedArmor
        }


        return EncounterState(enemy: enemy)
    }

    struct EncounterApplyResult {
        let message: String                 // for toast/log (non-defeat)
        let defeatPopupMessage: String?     // for full-screen popup
        let enemyName: String?
        let enemyDefeated: Bool
        let questCompleted: Bool
    }

    func applyEncounterAttack(_ attack: Attack, in quest: QuestArea) -> EncounterApplyResult {
        guard var state = encounterState(for: quest) else {
            return .init(message: "Nothing to attack (quest may be complete).", defeatPopupMessage: nil, enemyName: nil, enemyDefeated: false, questCompleted: false)
        }

        // Enabeling effort stats into attacks
        let snapshot = effectiveAttack(for: attack)
        
        // Capturing enemy name for display
        let enemyNameAtTimeofAttack = state.enemy.name

        let outcome = EncounterEngine.apply(
            manaCost: snapshot.manaCost,
            effects: snapshot.effects,
            combatAffinity: attack.primaryStylingAffinity,
            manaAvailable: manaPoolCurrent(),
            state: &state
        )

        if case .noEffect(let reason) = outcome.result {
            encounterByQuestName[quest.name] = state
            return .init(message: reason, defeatPopupMessage: nil, enemyName: nil, enemyDefeated: false, questCompleted: false)
        }

        if outcome.manaSpent > 0 {
            player.manaPool = max(0, player.manaPool - outcome.manaSpent)
        }

        var p = progress(for: quest.name)

        if state.isDefeated {
            // Trophy: record this enemy as defeated (for Trophy Room)
            player.defeatedEnemyIDs.insert(state.enemy.id)

            p.currentEnemyIndex += 1
            p.currentEnemyHP = nil
            p.currentEnemyArmor = nil

            if p.currentEnemyIndex >= quest.enemies.count {
                p.completed = true
                encounterByQuestName[quest.name] = nil
            } else {
                encounterByQuestName[quest.name] = nil
            }
        } else {
            p.currentEnemyHP = state.enemy.hp
            p.currentEnemyArmor = state.enemy.armor
            encounterByQuestName[quest.name] = state
        }

        setProgress(p, for: quest.name)
        savePlayer()
        
        var toastMessage = ""
        var defeatPopup: String? = nil
        
        switch outcome.result {
        case.noEffect(let reason):
            toastMessage = reason
            
        case.applied(let messages):
            toastMessage = messages.isEmpty
            ? "Attack applied."
            : messages.joined(separator: " ")
        case.enemyDefeated(message: let message):
            defeatPopup = message
            toastMessage = ""
        }
        
        return.init(
            message: toastMessage,
            defeatPopupMessage: defeatPopup,
            enemyName: defeatPopup == nil ? nil : enemyNameAtTimeofAttack,
            enemyDefeated: state.isDefeated,
            questCompleted: p.completed
        )

    }

    private func encounterMessage(from result: EncounterResult) -> String {
        switch result {
        case .noEffect(let reason):
            return reason
        case .applied(let messages):
            return messages.isEmpty ? "Attack applied." : messages.joined(separator: " ")
        case .enemyDefeated(let message):
            return message
        }
    }

    // MARK: - Quest reward

    func isQuestCompleted(_ quest: QuestArea) -> Bool {
        progress(for: quest.name).completed
    }

    func isQuestRewardClaimed(_ quest: QuestArea) -> Bool {
        progress(for: quest.name).rewardClaimed
    }

    @discardableResult
    func claimQuestReward(_ quest: QuestArea) -> Bool {
        var p = progress(for: quest.name)
        guard p.completed, !p.rewardClaimed else { return false }

        p.rewardClaimed = true
        setProgress(p, for: quest.name)

        // Replace XP reward with a collectible "button"
        player.claimedQuestButtonNames.insert(quest.name)
        
        savePlayer()
        
        return true
    }

    func questSummaryText(for quest: QuestArea) -> String {
        let p = progress(for: quest.name)
        if p.completed {
            return p.rewardClaimed ? "Completed (Reward Claimed)" : "Completed (Reward Ready)"
        }
        let idx = min(max(0, p.currentEnemyIndex), max(quest.enemies.count - 1, 0))
        return "Enemy \(idx + 1)/\(quest.enemies.count)"
    }
    
    private func makeLevelUpSnapshot(for level: Int) -> LevelUpSnapshot {
        LevelUpSnapshot(
            newLevel: level,
            manaPerWorkout: LevelRules.manaPerWorkout(for: level),
            manaCap: LevelRules.manaCap(for: level),
            xpToNextLevel: LevelRules.xpToNextLevel(from: level)
        )
    }
    
    
}



