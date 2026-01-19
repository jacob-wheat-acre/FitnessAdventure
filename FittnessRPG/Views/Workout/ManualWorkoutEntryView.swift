import SwiftUI

struct ManualWorkoutEntryView: View {
    let onSave: (WorkoutSession) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: WorkoutType = .walk
    @State private var workoutDate: Date = Date()

    @State private var distanceMilesText: String = ""
    @State private var durationMinutesText: String = ""

    @State private var previewCalories: Int = 0

    private var distanceMiles: Double {
        Double(distanceMilesText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var durationMinutes: Double {
        Double(durationMinutesText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var completedAtNoon: Date {
        let cal = Calendar.current
        return cal.date(bySettingHour: 12, minute: 0, second: 0, of: workoutDate) ?? workoutDate
    }

    private var estimatedCalories: Double {
        ManualCalorieEstimator.estimate(
            type: selectedType,
            distanceMiles: distanceMiles,
            durationMinutes: durationMinutes
        )
    }

    private var isValid: Bool {
        // Distance types: require distance OR duration
        // Strength/other: require duration (preferred), but allow save anyway with a conservative default.
        switch selectedType {
        case .run, .walk, .cycle:
            return distanceMiles > 0 || durationMinutes > 0
        case .strength, .other:
            return durationMinutes > 0 || true
        }
    }

    var body: some View {
        Form {
            Section("Workout") {
                Picker("Type", selection: $selectedType) {
                    Text("Run").tag(WorkoutType.run)
                    Text("Walk").tag(WorkoutType.walk)
                    Text("Cycle").tag(WorkoutType.cycle)
                    Text("Traditional weight training").tag(WorkoutType.strength)
                    Text("Other (HIIT, sports, etc.)").tag(WorkoutType.other)
                }

                DatePicker("Date", selection: $workoutDate, displayedComponents: .date)

                Text("Time is assumed to be noon for consistency.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Details") {
                TextField("Distance (miles)", text: $distanceMilesText)
                    .keyboardType(.decimalPad)

                TextField("Duration (minutes)", text: $durationMinutesText)
                    .keyboardType(.decimalPad)

                Text("For the best XP estimate, enter at least distance or duration. Strength/Other generally need duration.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Estimated XP") {
                HStack {
                    Text("Calories (XP)")
                    Spacer()
                    Text("\(Int(estimatedCalories.rounded()))")
                        .monospacedDigit()
                }

                Text(ManualCalorieEstimator.explanation(for: selectedType))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Manual Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let session = WorkoutSession(
                        id: UUID(),
                        type: selectedType,
                        calories: estimatedCalories,
                        distanceMiles: distanceMiles,
                        durationMinutes: durationMinutes,
                        avgHeartRate: nil,
                        completedAt: completedAtNoon
                    )
                    onSave(session)
                    dismiss()
                }
                .disabled(!isValid)
            }
        }
    }
}

// MARK: - Simple, tuneable estimation heuristics

enum ManualCalorieEstimator {

    /// Conservative, game-friendly heuristics:
    /// - If distance is provided for distance-based workouts, use per-mile estimate.
    /// - Else fall back to per-minute estimate when duration is provided.
    /// - If neither is provided, return a small default (so the flow still works).
    static func estimate(type: WorkoutType, distanceMiles: Double, durationMinutes: Double) -> Double {
        let miles = max(0, distanceMiles)
        let minutes = max(0, durationMinutes)

        switch type {
        case .walk:
            if miles > 0 { return miles * 80 }              // ~80 kcal/mile
            if minutes > 0 { return minutes * 4 }           // ~4 kcal/min
            return 60

        case .run:
            if miles > 0 { return miles * 120 }             // ~120 kcal/mile
            if minutes > 0 { return minutes * 10 }          // ~10 kcal/min
            return 100

        case .cycle:
            if miles > 0 { return miles * 50 }              // ~50 kcal/mile (varies widely)
            if minutes > 0 { return minutes * 7 }           // ~7 kcal/min
            return 80

        case .strength:
            if minutes > 0 { return minutes * 6 }           // ~6 kcal/min
            return 120

        case .other:
            if minutes > 0 { return minutes * 8 }           // ~8 kcal/min (HIIT/sports)
            return 150
        }
    }

    static func explanation(for type: WorkoutType) -> String {
        switch type {
        case .walk:
            return "Estimation uses ~80 kcal/mile (or ~4 kcal/min if no distance)."
        case .run:
            return "Estimation uses ~120 kcal/mile (or ~10 kcal/min if no distance)."
        case .cycle:
            return "Estimation uses ~50 kcal/mile (or ~7 kcal/min if no distance)."
        case .strength:
            return "Estimation uses ~6 kcal/min. Duration is recommended."
        case .other:
            return "Estimation uses ~8 kcal/min. Duration is recommended."
        }
    }
}
