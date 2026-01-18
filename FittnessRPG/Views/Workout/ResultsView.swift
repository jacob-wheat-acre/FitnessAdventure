//
//  ResultsView.swift
//  FittnessRPG
//

import SwiftUI

struct ResultsView: View {
    @ObservedObject var vm: GameViewModel
    let session: WorkoutSession

    @State private var applied = false

    var alreadyApplied: Bool { vm.isApplied(session) }

    // Tier computation (single source of truth)
    private var tierResult: (tier: EffortTier, basis: EffortTierRules.Basis, metricValue: Double, thresholds: EffortTierRules.Thresholds) {
        EffortTierRules.tier(
            workoutType: session.type,
            avgHeartRate: session.avgHeartRate,
            calories: session.calories,
            durationMinutes: session.durationMinutes
        )
    }

    private var tierBasisText: String {
        "Tier basis: \(tierResult.basis.rawValue)"
    }

    private var computedTierLabel: String {
        tierResult.tier.displayName
    }

    private var thresholdDetails: [String] {
        EffortTierRules.thresholdLines(for: tierResult.basis, workoutType: session.type)
    }

    // MARK: - Adjustment display (UI-only; does not affect tier logic)
    private var isDistanceAdjusted: Bool { session.type == .cycle }

    private var creditedDistanceMiles: Double {
        if session.type == .cycle { return session.distanceMiles * 0.5 }
        return session.distanceMiles
    }

    // MARK: - Apply summary (persistent)
    private struct ApplySummary {
        let xpEarned: Int
        let distanceEarnedMiles: Double
        let effortCount: Int
        let effortAffinity: Affinity
        let effortTier: EffortTier
        let manaGained: Int
        let manaBefore: Int
        let manaAfter: Int
    }

    @State private var summary: ApplySummary? = nil

    // MARK: - Effort mapping (must match GameViewModel.awardEffort)
    private func effortAffinity(for session: WorkoutSession) -> Affinity {
        switch session.type {
        case .walk: return .rhythm
        case .strength: return .force
        case .run, .cycle: return .endurance
        case .other: return .precision
        }
    }

    private func effortCount(for tier: EffortTier) -> Int {
        switch tier {
        case .easy: return 1
        case .moderate: return 2
        case .hard: return 3
        }
    }

    private func adjustedPill(_ text: String = "Adjusted") -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.thinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(.secondary.opacity(0.35), lineWidth: 1)
            )
    }

    private func adjustedRow(label: String, value: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .imageScale(.medium)
                    .foregroundStyle(.secondary)

                Text("\(label): \(value)")
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                adjustedPill()
            }

            Text(note)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 22)
        }
    }

    // MARK: - Summary card (persistent)
    @ViewBuilder
    private func appliedSummaryCard(_ s: ApplySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("Workout Applied")
                    .font(.headline)
                Spacer()
            }

            // 1) XP earned
            summaryRow(label: "XP earned", value: "+\(s.xpEarned)")

            // 2) Distance earned (credited)
            summaryRow(
                label: "Distance earned",
                value: String(format: "+%.2f miles", s.distanceEarnedMiles)
            )

            // 3) Efforts earned count + type, with your requested phrasing
            // Example: "Moderate Walk: earned 2 Rhythm"
            Text("\(s.effortTier.displayName) \(session.type.rawValue.capitalized): earned \(s.effortCount) \(s.effortAffinity.displayName)")
                .font(.subheadline)

            // 4) Mana regenerated (delta)
            summaryRow(label: "Mana regenerated", value: "+\(max(0, s.manaGained))")

            // Optional: show before/after for clarity
            Text("Mana: \(s.manaBefore) → \(s.manaAfter)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
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

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
        .font(.subheadline)
    }

    var body: some View {
        let affinity = session.type.effortAffinity

        VStack(spacing: 18) {

            // Title with themed icon
            HStack(spacing: 10) {
                AffinityIcon(affinity: affinity, size: 22)
                Text(session.type.rawValue.capitalized)
                    .font(.largeTitle)
                    .bold()
                Spacer()
            }

            // Workout facts + tier disclosure card
            VStack(alignment: .leading, spacing: 10) {

                HStack {
                    Text("Calories Burned")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(session.calories))")
                        .monospacedDigit()
                }

                HStack {
                    Text("Distance")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(String(format: "%.2f", session.distanceMiles)) miles")
                        .monospacedDigit()
                }

                if isDistanceAdjusted {
                    adjustedRow(
                        label: "Distance Credit",
                        value: "\(String(format: "%.2f", creditedDistanceMiles)) miles",
                        note: "Cycling distance counts as 50% credit."
                    )
                    .padding(.top, 2)
                }

                if session.durationMinutes > 0 {
                    HStack {
                        Text("Duration")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(session.durationMinutes)) min")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                if let hr = session.avgHeartRate {
                    HStack {
                        Text("Avg HR")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(hr)) bpm")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                } else if session.durationMinutes > 0 {
                    HStack {
                        Text("Calories/min")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f", tierResult.metricValue))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                Text(tierBasisText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Text("Computed Tier: \(computedTierLabel)")
                        .font(.headline)

                    Text(computedTierLabel)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(affinity.uiColor.opacity(0.18))
                        .clipShape(Capsule())
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tier thresholds")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(thresholdDetails, id: \.self) { line in
                        Text("• \(line)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Persistent summary once applied (or already applied)
            if let s = summary {
                appliedSummaryCard(s)
            } else if alreadyApplied {
                // Best-effort display if we don't have captured deltas
                // (We cannot reconstruct exact mana gained after the fact without storing it.)
                let a = effortAffinity(for: session)
                let count = effortCount(for: tierResult.tier)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("Workout Already Applied")
                            .font(.headline)
                        Spacer()
                    }

                    summaryRow(label: "XP earned", value: "+\(Int(session.calories))")
                    summaryRow(label: "Distance earned", value: String(format: "+%.2f miles", creditedDistanceMiles))
                    Text("\(tierResult.tier.displayName) \(session.type.rawValue.capitalized): earned \(count) \(a.displayName)")
                        .font(.subheadline)

                    Text("Mana regenerated: (not available for previously applied workouts)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            if !alreadyApplied {
                Button {
                    // Capture before/after to compute mana delta accurately.
                    let manaBefore = vm.manaPoolCurrent()

                    // Apply
                    vm.applyWorkout(session)
                    applied = true

                    let manaAfter = vm.manaPoolCurrent()
                    let manaGained = max(0, manaAfter - manaBefore)

                    let tier = tierResult.tier
                    let effortAffinity = effortAffinity(for: session)
                    let effortEarned = effortCount(for: tier)

                    summary = ApplySummary(
                        xpEarned: Int(session.calories),
                        distanceEarnedMiles: creditedDistanceMiles,
                        effortCount: effortEarned,
                        effortAffinity: effortAffinity,
                        effortTier: tier,
                        manaGained: manaGained,
                        manaBefore: manaBefore,
                        manaAfter: manaAfter
                    )
                } label: {
                    HStack(spacing: 10) {
                        AffinityIcon(affinity: affinity, size: 16)
                        Text("Apply Workout")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(affinity.uiColor.opacity(0.85))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            } else {
                // No quick flash; we keep the persistent card instead.
                EmptyView()
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Workout Result")
        .navigationBarTitleDisplayMode(.inline)
    }
}
