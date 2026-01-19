//
//  Effort.swift
//  FittnessRPG
//
//  Created by Jacob Whitaker on 12/28/25.
//

import Foundation

enum EffortTier: String, Codable, CaseIterable, Comparable {
    case easy
    case moderate
    case hard
    
    // Comparable for “meets at least”
    static func < (lhs: EffortTier, rhs: EffortTier) -> Bool {
        let order: [EffortTier] = [.easy, .moderate, .hard]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .moderate: return "Moderate"
        case .hard: return "Hard"
        }
    }
}

struct Effort: Codable, Identifiable, Hashable {
    let id: UUID
    let affinity: Affinity
    let tier: EffortTier
    let earnedAt: Date
    
    init(id: UUID = UUID(), affinity: Affinity, tier: EffortTier, earnedAt: Date = Date()) {
        self.id = id
        self.affinity = affinity
        self.tier = tier
        self.earnedAt = earnedAt
    }
    
    var displayName: String { "\(affinity.displayName) Effort (\(tier.displayName))" }
}
