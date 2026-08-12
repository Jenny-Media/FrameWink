import Foundation

protocol CurationStoring {
    func loadSignals(algorithmRevision: Int) throws -> [UUID: PhotoSignals]
    func saveSignals(_ signals: [UUID: PhotoSignals]) throws
    func loadSmartReel() throws -> SmartReel?
    func saveSmartReel(_ reel: SmartReel) throws
    func loadExclusions() throws -> Set<UUID>
    func saveExclusions(_ exclusions: Set<UUID>) throws
}

protocol DisplayHistoryStoring {
    func loadDisplayHistory() throws -> [UUID: DisplayHistoryEntry]
    func recordDisplayed(candidateID: UUID, at date: Date) throws
}

final class LocalCurationStore: CurationStoring, DisplayHistoryStoring {
    private static let displayHistoryWriteInterval: TimeInterval = 6 * 60 * 60
    let directory: URL
    let signalsURL: URL
    let smartReelURL: URL
    let exclusionsURL: URL
    let displayHistoryURL: URL

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(directory: URL, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
        signalsURL = directory.appendingPathComponent("signals.json")
        smartReelURL = directory.appendingPathComponent("smart-reel.json")
        exclusionsURL = directory.appendingPathComponent("exclusions.json")
        displayHistoryURL = directory.appendingPathComponent("display-history.json")

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder = JSONDecoder()
    }

    func loadSignals(algorithmRevision: Int) throws -> [UUID: PhotoSignals] {
        guard fileManager.fileExists(atPath: signalsURL.path) else { return [:] }
        do {
            let data = try Data(contentsOf: signalsURL)
            let decoded = try decoder.decode([PhotoSignals].self, from: data)
            return Dictionary(
                uniqueKeysWithValues: decoded
                    .filter { $0.algorithmRevision == algorithmRevision }
                    .map { ($0.candidateID, $0) }
            )
        } catch {
            try? fileManager.removeItem(at: signalsURL)
            return [:]
        }
    }

    func saveSignals(_ signals: [UUID: PhotoSignals]) throws {
        try prepareDirectory()
        let ordered = signals.values.sorted {
            $0.candidateID.uuidString < $1.candidateID.uuidString
        }
        try encoder.encode(ordered).write(to: signalsURL, options: .atomic)
    }

    func loadSmartReel() throws -> SmartReel? {
        guard fileManager.fileExists(atPath: smartReelURL.path) else { return nil }
        do {
            return try decoder.decode(SmartReel.self, from: Data(contentsOf: smartReelURL))
        } catch {
            try? fileManager.removeItem(at: smartReelURL)
            return nil
        }
    }

    func saveSmartReel(_ reel: SmartReel) throws {
        try prepareDirectory()
        try encoder.encode(reel).write(to: smartReelURL, options: .atomic)
    }

    func loadExclusions() throws -> Set<UUID> {
        guard fileManager.fileExists(atPath: exclusionsURL.path) else { return [] }
        let decoded = try decoder.decode([UUID].self, from: Data(contentsOf: exclusionsURL))
        return Set(decoded)
    }

    func saveExclusions(_ exclusions: Set<UUID>) throws {
        try prepareDirectory()
        let ordered = exclusions.sorted { $0.uuidString < $1.uuidString }
        try encoder.encode(ordered).write(to: exclusionsURL, options: .atomic)
    }

    func loadDisplayHistory() throws -> [UUID: DisplayHistoryEntry] {
        guard fileManager.fileExists(atPath: displayHistoryURL.path) else { return [:] }
        do {
            let decoded = try decoder.decode(
                [DisplayHistoryEntry].self,
                from: Data(contentsOf: displayHistoryURL)
            )
            return Dictionary(uniqueKeysWithValues: decoded.map { ($0.candidateID, $0) })
        } catch {
            try? fileManager.removeItem(at: displayHistoryURL)
            return [:]
        }
    }

    func recordDisplayed(candidateID: UUID, at date: Date) throws {
        var history = try loadDisplayHistory()
        if let existing = history[candidateID],
           date.timeIntervalSince(existing.lastDisplayedAt)
            < Self.displayHistoryWriteInterval {
            return
        }
        var entry = history[candidateID] ?? DisplayHistoryEntry(
            candidateID: candidateID,
            lastDisplayedAt: date,
            displayCount: 0
        )
        entry.lastDisplayedAt = date
        entry.displayCount += 1
        history[candidateID] = entry
        try prepareDirectory()
        let ordered = history.values.sorted {
            $0.candidateID.uuidString < $1.candidateID.uuidString
        }
        try encoder.encode(ordered).write(to: displayHistoryURL, options: .atomic)
    }

    private func prepareDirectory() throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
