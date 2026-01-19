import SwiftUI

struct WorkoutChoiceView: View {
    @ObservedObject var vm: GameViewModel

    @State private var showManualEntry = false

    // NEW: Apply-all summary sheet
    //@State private var applyAllSummary: ApplyAllSummary? = nil :::::MOVED ELSEWHERE:::::

    private var cutoff72Hours: Date {
        Date().addingTimeInterval(-72 * 3600)
    }

    private var last72HoursSessions: [WorkoutSession] {
        vm.recentSessions.filter { $0.completedAt >= cutoff72Hours }
    }

    private var sessionsToApplyInWindow: [WorkoutSession] {
        last72HoursSessions
            .sorted { $0.completedAt > $1.completedAt }
            .filter { !vm.isApplied($0) }
    }

    private var canApplyAnyInWindow: Bool {
        !sessionsToApplyInWindow.isEmpty
    }

    var body: some View {
        VStack(spacing: 12) {

            // MARK: - Polished action buttons
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                spacing: 12
            ) {
                Button {
                    vm.requestHealthKitAccess()
                } label: {
                    ActionButtonLabel(
                        title: "Load",
                        systemImage: "arrow.triangle.2.circlepath",
                        background: RPGColors.rhythm.opacity(0.85),
                        isEnabled: true
                    )
                }
                .buttonStyle(.plain)

                // Apply ONLY last 72 hours (rolling window) + show summary
                Button {
                    applyAllLast3DaysAndShowSummary()
                } label: {
                    ActionButtonLabel(
                        title: "Apply All (3 days)",
                        systemImage: "checkmark.circle.fill",
                        background: RPGColors.endurance.opacity(0.85),
                        isEnabled: canApplyAnyInWindow
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canApplyAnyInWindow)

                // Manual entry (for non-HealthKit users)
                Button {
                    vm.presentSheetNow(.manualEntry)
                } label: {
                    ActionButtonLabel(
                        title: "Manual Entry",
                        systemImage: "square.and.pencil",
                        background: RPGColors.precision.opacity(0.85),
                        isEnabled: true
                    )
                }
                .buttonStyle(.plain)

                // Optional: keep grid balanced; you can replace this with something else later
                Color.clear
                    .frame(height: 0)
            }
            .padding(.horizontal)
            .padding(.top, 6)

            List(vm.recentSessions) { session in
                NavigationLink {
                    ResultsView(vm: vm, session: session)
                } label: {
                    HStack(spacing: 10) {
                        AffinityIcon(affinity: session.type.effortAffinity, size: 16)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.type.rawValue.capitalized)
                                .font(.body)

                            Text(session.completedAt.formatted(date: .numeric, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if vm.isApplied(session) {
                            Text("Applied")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.thinMaterial)
                                .clipShape(Capsule())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Workouts")


    }

    // MARK: - Apply All + Summary

    private func applyAllLast3DaysAndShowSummary() {
        let sessions = sessionsToApplyInWindow
        guard !sessions.isEmpty else { return }

        // Compute summary BEFORE applying (for deterministic totals), but mana is net before/after.
        let manaBefore = vm.manaPoolCurrent()
        var summary = ApplyAllSummary.make(from: sessions)
        
        // present the summary first
        vm.applyAllSummary = summary
        vm.presentSheetNow(.applyAllSummary)
                
        // Apply them (enqueue levelup/attackchoice behind the summary
        for s in sessions {
            vm.applyWorkout(s)
        }

        let manaAfter = vm.manaPoolCurrent()
        summary.manaGainedNet = max(0, manaAfter - manaBefore)
        summary.manaBefore = manaBefore
        summary.manaAfter = manaAfter
        
        vm.applyAllSummary = summary
        vm.savePlayer()
        
    }
}

// MARK: - Summary model

struct ApplyAllSummary {
    struct GroupKey: Hashable {
        let tier: EffortTier
        let workoutType: WorkoutType
    }

    struct GroupLine: Identifiable {
        let id = UUID()
        let countWorkouts: Int
        let tier: EffortTier
        let workoutType: WorkoutType
        let totalEffortsEarned: Int
        let affinity: Affinity
    }

    let workoutCount: Int
    let totalXPEarned: Int
    let totalDistanceCredited: Double

    // Grouped lines like: "2x Hard Walk: earned 6 Rhythm"
    let groupLines: [GroupLine]

    // Mana (filled after apply)
    var manaGainedNet: Int = 0
    var manaBefore: Int = 0
    var manaAfter: Int = 0

    static func make(from sessions: [WorkoutSession]) -> ApplyAllSummary {
        var xp = 0
        var distanceCredited: Double = 0

        var grouped: [GroupKey: (count: Int, totalEfforts: Int, affinity: Affinity)] = [:]

        for s in sessions {
            xp += Int(max(0, s.calories.rounded()))

            let credited = (s.type == .cycle) ? (max(0, s.distanceMiles) * 0.5) : max(0, s.distanceMiles)
            distanceCredited += credited

            let tierResult = EffortTierRules.tier(
                workoutType: s.type,
                avgHeartRate: s.avgHeartRate,
                calories: s.calories,
                durationMinutes: s.durationMinutes
            )

            let effortAmount: Int
            switch tierResult.tier {
            case .easy: effortAmount = 1
            case .moderate: effortAmount = 2
            case .hard: effortAmount = 3
            }

            let affinity = s.type.effortAffinity
            let key = GroupKey(tier: tierResult.tier, workoutType: s.type)

            if let existing = grouped[key] {
                grouped[key] = (existing.count + 1, existing.totalEfforts + effortAmount, existing.affinity)
            } else {
                grouped[key] = (1, effortAmount, affinity)
            }
        }

        let lines: [GroupLine] = grouped.map { (key, val) in
            GroupLine(
                countWorkouts: val.count,
                tier: key.tier,
                workoutType: key.workoutType,
                totalEffortsEarned: val.totalEfforts,
                affinity: val.affinity
            )
        }
        // Sort: Hard -> Moderate -> Easy, then by workout name for stability
        .sorted { a, b in
            if a.tier != b.tier { return a.tier > b.tier } // relies on Comparable in EffortTier
            return a.workoutType.rawValue < b.workoutType.rawValue
        }

        return ApplyAllSummary(
            workoutCount: sessions.count,
            totalXPEarned: xp,
            totalDistanceCredited: distanceCredited,
            groupLines: lines
        )
    }
}

// MARK: - Summary sheet UI

struct ApplyAllSummaryView: View {
    let summary: ApplyAllSummary?
    @ObservedObject var vm: GameViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let s = summary {
                List {
                    Section("Totals") {
                        row("Workouts applied", "\(s.workoutCount)")
                        row("XP earned", "+\(s.totalXPEarned)")
                        row("Distance earned", String(format: "+%.2f mi", s.totalDistanceCredited))
                        row("Mana regenerated", "+\(s.manaGainedNet)")
                        Text("Mana: \(s.manaBefore) → \(s.manaAfter)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Section("Efforts earned") {
                        ForEach(s.groupLines) { line in
                            Text("\(line.countWorkouts)x \(line.tier.displayName) \(line.workoutType.rawValue.capitalized): earned \(line.totalEffortsEarned) \(line.affinity.displayName)")
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .navigationTitle("Workout Applied")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            vm.applyAllSummary = nil        // optional cleanup
                            vm.dismissActiveSheet()         // CRITICAL: advances the queue
                            vm.savePlayer()
                            dismiss()
                        }

                    }
                }
            } else {
                VStack(spacing: 12) {
                    Text("No summary available.")
                        .foregroundStyle(.secondary)
                    Button("Done") {
                        vm.applyAllSummary = nil        // optional cleanup
                        vm.dismissActiveSheet()         // CRITICAL: advances the queue
                        vm.savePlayer()
                        dismiss()
                    }

                }
                .navigationTitle("Workout Applied")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).monospacedDigit()
        }
        .font(.subheadline)
    }
}

// MARK: - Shared polished label

private struct ActionButtonLabel: View {
    let title: String
    let systemImage: String
    let background: Color
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(isEnabled ? 0.95 : 0.75))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(isEnabled ? 0.95 : 0.75))
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isEnabled ? background : RPGColors.neutral.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(isEnabled ? 0.12 : 0.08), lineWidth: 1)
        )
        .opacity(isEnabled ? 1.0 : 0.70)
        .contentShape(Rectangle())
    }
}
