import Foundation
import SwiftUI
import Combine

struct TrophySheetModel: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let text: String
}

/// Single router for ALL sheets in the app.
enum ActiveSheet: Identifiable {
    case attackChoice
    case levelUp(LevelUpSnapshot)
    case trophyDetail(TrophySheetModel)
    case manualEntry
    case applyAllSummary

    var id: String {
        switch self {
        case .attackChoice:
            return "attackChoice"
        case .levelUp(let s):
            return "levelUp-\(s.id.uuidString)"
        case .trophyDetail(let m):
            return "trophy-\(m.id.uuidString)"
        case .manualEntry:
            return "manualEntry"
        case .applyAllSummary:
            return "applyAllSummary"
        }
    }
}

