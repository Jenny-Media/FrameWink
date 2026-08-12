import Foundation

protocol FrameConfigurationStoring {
    func loadArchive() -> FrameConfigurationArchive
    func saveArchive(_ archive: FrameConfigurationArchive) throws
}

final class LocalFrameConfigurationStore: FrameConfigurationStoring {
    let archiveURL: URL
    private let fileManager: FileManager

    init(directory: URL, fileManager: FileManager = .default) {
        archiveURL = directory.appendingPathComponent("frame-configurations.json")
        self.fileManager = fileManager
    }

    func loadArchive() -> FrameConfigurationArchive {
        guard fileManager.fileExists(atPath: archiveURL.path),
              let data = try? Data(contentsOf: archiveURL),
              var archive = try? JSONDecoder().decode(
                  FrameConfigurationArchive.self,
                  from: data
              ) else {
            return FrameConfigurationArchive(
                configurations: [],
                activeConfigurationID: nil
            )
        }
        archive.configurations = archive.configurations.map { configuration in
            var normalized = configuration
            normalized.normalize()
            return normalized
        }
        if !archive.configurations.contains(where: {
            $0.id == archive.activeConfigurationID
        }) {
            archive.activeConfigurationID = nil
        }
        return archive
    }

    func saveArchive(_ archive: FrameConfigurationArchive) throws {
        try fileManager.createDirectory(
            at: archiveURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(archive).write(to: archiveURL, options: .atomic)
    }
}
