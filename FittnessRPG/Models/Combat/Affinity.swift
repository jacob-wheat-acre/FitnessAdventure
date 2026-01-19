//
//  Affinity.swift
//  FittnessRPG
//
//  Created by Jacob Whitaker on 12/28/25.
//

import Foundation

enum Affinity: String, Codable, CaseIterable, Identifiable {
    case rhythm
    case endurance
    case force
    case precision
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .rhythm: return "Rhythm"
        case .endurance: return "Endurance"
        case .force: return "Force"
        case .precision: return "Precision"
        }
    }
}
