//
//  Armor.swift
//  FittnessRPG
//
//  Created by Jacob Whitaker on 12/28/25.
//

import Foundation

enum ArmorType: String, Codable, CaseIterable, Identifiable {
    case structural
    case stability
    case pattern
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .structural: return "Structural"
        case .stability: return "Stability"
        case .pattern: return "Pattern"
        }
    }
}

struct Armor: Codable, Hashable {
    let type: ArmorType
    var value: Int
    
    init(type: ArmorType, value: Int) {
        self.type = type
        self.value = max(0, value)
    }
    
    var isActive: Bool { value > 0 }
}
