import Foundation

/// Speichert den Spielstand als JSON im Ordner „Application Support“ der App.
/// Eine iCloud-Sicherung folgt in einer späteren Version.
struct Persistence {
    private let fileName = "savegame.json"

    private var fileURL: URL? {
        guard let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(fileName)
    }

    func load() -> GameState? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(GameState.self, from: data)
    }

    func save(_ state: GameState) {
        guard let url = fileURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(state) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func delete() {
        guard let url = fileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
