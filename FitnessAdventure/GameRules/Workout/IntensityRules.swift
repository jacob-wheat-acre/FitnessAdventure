import Foundation

enum IntensityTier: String, CaseIterable {
    case starting
    case establishing
    case consistent
    case committed
    case highlyActive
    case athlete

    var displayName: String {
        switch self {
        case .starting: return "Starting"
        case .establishing: return "Establishing"
        case .consistent: return "Consistent"
        case .committed: return "Committed"
        case .highlyActive: return "Highly Active"
        case .athlete: return "Athlete"
        }
    }

    var multiplier: Double {
        switch self {
        case .starting: return 1.0
        case .establishing: return 1.2
        case .consistent: return 1.4
        case .committed: return 1.6
        case .highlyActive: return 1.8
        case .athlete: return 2.0
        }
    }

    static func tier(forWeeklyEfforts count: Int) -> IntensityTier {
        switch count {
        case 0...3:   return .starting
        case 4...7:   return .establishing
        case 8...12:  return .consistent
        case 13...18: return .committed
        case 19...25: return .highlyActive
        default:      return .athlete
        }
    }
}
