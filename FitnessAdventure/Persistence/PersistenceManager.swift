import Foundation

/// NOTE: File name is "PersistanceManager.swift" in your project,
/// but the type name is `PersistenceManager` (as used by GameViewModel).
///
/// Step 4 upgrade:
/// - Persist a versioned container (`SaveGame`) instead of raw `Player`.
/// - Automatically migrate legacy saves stored under the old key ("RPGPlayer").
/// - If decode fails (corrupt / incompatible), clear and fall back safely.
final class PersistenceManager {
    static let shared = PersistenceManager()

    /// Legacy key that previously stored raw `Player`.
    private let legacyPlayerKey = "RPGPlayer"

    /// New key storing versioned `SaveGame`.
    private let saveGameKey = "RPGSaveGame"

    /// Increment only when you intentionally change the on-disk schema and add migration logic.
    private let currentSchemaVersion = 1

    private init() {}

    // MARK: - Public API (kept stable to minimize ripple)

    func savePlayer(_ player: Player) {
        let save = SaveGame(schemaVersion: currentSchemaVersion, player: player)
        saveSaveGame(save)
    }

    func loadPlayer() -> Player? {
        // 1) Prefer loading the new SaveGame format.
        if let save = loadSaveGame() {
            // Future: handle schema migrations here when schemaVersion changes.
            // For now, v1 is current; return directly.
            return save.player
        }

        // 2) Attempt legacy migration: old key stored raw Player.
        if let legacyPlayer = loadLegacyPlayer() {
            // Migrate forward immediately so all future loads use SaveGame.
            let migrated = SaveGame(schemaVersion: currentSchemaVersion, player: legacyPlayer)
            saveSaveGame(migrated)

            // Optional: clear legacy key to avoid ambiguity.
            // If you prefer keeping it for debugging, comment this line out.
            clearLegacyPlayer()

            return legacyPlayer
        }

        return nil
    }

    func clearPlayer() {
        UserDefaults.standard.removeObject(forKey: saveGameKey)
        UserDefaults.standard.removeObject(forKey: legacyPlayerKey)
    }

    // MARK: - SaveGame container

    private struct SaveGame: Codable {
        let schemaVersion: Int
        let player: Player
    }

    private func saveSaveGame(_ save: SaveGame) {
        do {
            let data = try JSONEncoder().encode(save)
            UserDefaults.standard.set(data, forKey: saveGameKey)
        } catch {
            // If encoding fails, do not overwrite existing save.
            // In practice this should be rare unless Player contains non-Codable state.
            // You could add logging here if desired.
        }
    }

    private func loadSaveGame() -> SaveGame? {
        guard let data = UserDefaults.standard.data(forKey: saveGameKey) else { return nil }
        do {
            return try JSONDecoder().decode(SaveGame.self, from: data)
        } catch {
            // Corrupt / incompatible save. Clear it so we can recover gracefully.
            UserDefaults.standard.removeObject(forKey: saveGameKey)
            return nil
        }
    }

    // MARK: - Legacy (Player-only) compatibility

    private func loadLegacyPlayer() -> Player? {
        guard let data = UserDefaults.standard.data(forKey: legacyPlayerKey) else { return nil }
        do {
            return try JSONDecoder().decode(Player.self, from: data)
        } catch {
            // If legacy is corrupt too, clear it.
            clearLegacyPlayer()
            return nil
        }
    }

    private func clearLegacyPlayer() {
        UserDefaults.standard.removeObject(forKey: legacyPlayerKey)
    }
}
