//
//  RPGTheme.swift
//  FittnessRPG
//

import SwiftUI

enum RPGColors {
    static let rhythm    = Color(red: 0.35, green: 0.62, blue: 0.92)
    static let endurance = Color.green
    static let force     = Color(red: 0.55, green: 0.10, blue: 0.18)
    static let precision = Color(red: 0.90, green: 0.72, blue: 0.20)
    static let neutral   = Color.gray
}

extension Affinity {
    var sfSymbolName: String {
        switch self {
        case .rhythm: return "figure.walk"
        case .endurance: return "heart.fill"
        case .force: return "dumbbell.fill"
        case .precision: return "arrow.up.right"
        }
    }

    var uiColor: Color {
        switch self {
        case .rhythm: return RPGColors.rhythm
        case .endurance: return RPGColors.endurance
        case .force: return RPGColors.force
        case .precision: return RPGColors.precision
        }
    }
}

extension PlayerClass {
    var sfSymbolName: String {
        switch self {
        case .Knight: return "shield.fill"
        case .Wizard: return "sparkles"
        case .Jester: return "theatermasks.fill"
        }
    }

    var displayName: String { rawValue }
}

extension WorkoutType {
    var effortAffinity: Affinity {
        switch self {
        case .walk: return .rhythm
        case .run, .cycle: return .endurance
        case .strength: return .force
        case .other: return .precision
        }
    }
}

struct AffinityIcon: View {
    let affinity: Affinity
    var size: CGFloat = 16

    var body: some View {
        Image(systemName: affinity.sfSymbolName)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(affinity.uiColor)
            .accessibilityLabel(Text(affinity.displayName))
    }
}

struct ClassIcon: View {
    let playerClass: PlayerClass
    var size: CGFloat = 16

    var body: some View {
        Image(systemName: playerClass.sfSymbolName)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(.primary)
            .accessibilityLabel(Text(playerClass.displayName))
    }
}

struct AffinityPill: View {
    let affinity: Affinity
    var textOverride: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            AffinityIcon(affinity: affinity, size: 14)
            Text(textOverride ?? affinity.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}
