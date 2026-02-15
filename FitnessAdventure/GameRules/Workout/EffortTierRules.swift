import Foundation

/// Single source of truth for Effort tiering.
/// Now supports workout-specific thresholds (knobs) while allowing equal defaults for initial rollout.
struct EffortTierRules {

    enum Basis: String {
        case heartRate = "Heart Rate"
        case caloriesPerMinute = "Calories/minute"
    }

    struct Thresholds: Equatable {
        var hrModerate: Double
        var hrHard: Double
        var cpmModerate: Double
        var cpmHard: Double
    }

    // MARK: - Default thresholds (initial rollout: equal across all workout types)

    static let defaultThresholds = Thresholds(
        hrModerate: 120,
        hrHard: 150,
        cpmModerate: 6,
        cpmHard: 12
    )

    // MARK: - Workout-specific overrides (future tuning knobs)
    // For initial rollout: all equal => no overrides necessary.
    //
    // Later you can tune by adding entries like:
    //   static let overrides: [WorkoutType: Thresholds] = [
    //       .walk: .init(hrModerate: 115, hrHard: 145, cpmModerate: 5, cpmHard: 10),
    //       .run:  .init(hrModerate: 125, hrHard: 155, cpmModerate: 7, cpmHard: 13)
    //   ]
    //
    static let overrides: [WorkoutType: Thresholds] = [:]

    static func thresholds(for workoutType: WorkoutType) -> Thresholds {
        overrides[workoutType] ?? defaultThresholds
    }

    // MARK: - Tier computation

    static func tier(
        workoutType: WorkoutType,
        avgHeartRate: Double?,
        calories: Double,
        durationMinutes: Double
    ) -> (tier: EffortTier, basis: Basis, metricValue: Double, thresholds: Thresholds) {

        let t = thresholds(for: workoutType)

        if let hr = avgHeartRate {
            if hr >= t.hrHard { return (.hard, .heartRate, hr, t) }
            if hr >= t.hrModerate { return (.moderate, .heartRate, hr, t) }
            return (.easy, .heartRate, hr, t)
        }

        let minutes = max(1.0, durationMinutes)
        let cpm = calories / minutes

        if cpm >= t.cpmHard { return (.hard, .caloriesPerMinute, cpm, t) }
        if cpm >= t.cpmModerate { return (.moderate, .caloriesPerMinute, cpm, t) }
        return (.easy, .caloriesPerMinute, cpm, t)
    }

    // MARK: - UI disclosure

    static func thresholdLines(for basis: Basis, workoutType: WorkoutType) -> [String] {
        let t = thresholds(for: workoutType)

        switch basis {
        case .heartRate:
            return [
                "Hard if Avg HR ≥ \(Int(t.hrHard)) bpm",
                "Moderate if Avg HR ≥ \(Int(t.hrModerate)) bpm",
                "Easy otherwise"
            ]
        case .caloriesPerMinute:
            return [
                "Hard if Calories/min ≥ \(Int(t.cpmHard))",
                "Moderate if Calories/min ≥ \(Int(t.cpmModerate))",
                "Easy otherwise"
            ]
        }
    }
}
