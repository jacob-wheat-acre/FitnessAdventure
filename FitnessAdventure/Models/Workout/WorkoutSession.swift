import Foundation

enum WorkoutType: String, Codable {
    case run
    case walk
    case cycle
    case strength
    case other
}

struct WorkoutSession: Identifiable, Codable {
    var id: UUID
    let type: WorkoutType
    let calories: Double
    let distanceMiles: Double
    let durationMinutes: Double
    let avgHeartRate: Double?
    let completedAt: Date

    init(
        id: UUID,
        type: WorkoutType,
        calories: Double,
        distanceMiles: Double,
        durationMinutes: Double = 0,
        avgHeartRate: Double? = nil,
        completedAt: Date
    ) {
        self.id = id
        self.type = type
        self.calories = calories
        self.distanceMiles = distanceMiles
        self.durationMinutes = durationMinutes
        self.avgHeartRate = avgHeartRate
        self.completedAt = completedAt
    }
}
