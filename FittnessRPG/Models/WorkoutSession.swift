import Foundation

enum WorkoutType: String, Codable {
    case run, cycle, strength
}

struct WorkoutSession: Identifiable, Codable {
    var id: UUID
    let type: WorkoutType
    let calories: Double
    let distanceMiles: Double
    let completedAt: Date
}
