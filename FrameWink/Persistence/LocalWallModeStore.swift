import Foundation

protocol WallModeConfigurationStoring {
    func loadConfiguration() -> WallModeConfiguration
    func saveConfiguration(_ configuration: WallModeConfiguration) throws
}

final class LocalWallModeStore: WallModeConfigurationStoring {
    let configurationURL: URL

    private let fileManager: FileManager

    init(directory: URL, fileManager: FileManager = .default) {
        configurationURL = directory.appendingPathComponent("wall-mode.json")
        self.fileManager = fileManager
    }

    func loadConfiguration() -> WallModeConfiguration {
        guard fileManager.fileExists(atPath: configurationURL.path),
              let data = try? Data(contentsOf: configurationURL),
              var configuration = try? JSONDecoder().decode(
                WallModeConfiguration.self,
                from: data
              ) else {
            return .defaultConfiguration
        }
        configuration.normalize()
        return configuration
    }

    func saveConfiguration(_ configuration: WallModeConfiguration) throws {
        var normalized = configuration
        normalized.normalize()
        try fileManager.createDirectory(
            at: configurationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(normalized).write(to: configurationURL, options: .atomic)
    }
}
