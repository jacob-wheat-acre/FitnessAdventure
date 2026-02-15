import Foundation

struct LevelUpSnapshot: Identifiable, Equatable {
    let id = UUID()
    let newLevel: Int
    let manaPerWorkout: Int
    let manaCap: Int
    let xpToNextLevel: Int
}

