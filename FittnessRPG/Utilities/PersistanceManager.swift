import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    private let playerKey = "RPGPlayer"

    func savePlayer(_ player: Player) {
        if let data = try? JSONEncoder().encode(player) {
            UserDefaults.standard.set(data, forKey: playerKey)
        }
    }

    func loadPlayer() -> Player? {
        guard let data = UserDefaults.standard.data(forKey: playerKey),
              let player = try? JSONDecoder().decode(Player.self, from: data) else { return nil }
        return player
    }

    func clearPlayer() {
        UserDefaults.standard.removeObject(forKey: playerKey)
    }
}
