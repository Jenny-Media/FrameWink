import Foundation

@MainActor
final class FrameConfigurationController: ObservableObject {
    @Published private(set) var configurations: [SavedFrameConfiguration]
    @Published private(set) var activeConfigurationID: UUID?
    @Published private(set) var persistenceError: String?
    @Published private(set) var isEntitled = false

    private let store: FrameConfigurationStoring

    init(store: FrameConfigurationStoring) {
        self.store = store
        let archive = store.loadArchive()
        var normalizedConfigurations = archive.configurations
        normalizedConfigurations.indices.forEach { index in
            normalizedConfigurations[index].normalize()
        }
        configurations = normalizedConfigurations
        activeConfigurationID = archive.activeConfigurationID

        guard normalizedConfigurations != archive.configurations else { return }
        do {
            try store.saveArchive(
                FrameConfigurationArchive(
                    configurations: normalizedConfigurations,
                    activeConfigurationID: archive.activeConfigurationID
                )
            )
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    var activeConfiguration: SavedFrameConfiguration? {
        guard isEntitled else { return nil }
        return configurations.first { $0.id == activeConfigurationID }
    }

    var availableLayoutPreferences: [FrameLayoutPreference] {
        [.automatic]
    }

    func setEntitled(_ entitled: Bool) {
        guard isEntitled != entitled else { return }
        isEntitled = entitled
    }

    func create(
        name: String,
        source: FrameConfigurationSource,
        albumIdentifier: String? = nil,
        albumTitle: String? = nil,
        layoutPreference: FrameLayoutPreference,
        interval: TimeInterval
    ) {
        guard isEntitled else { return }
        var configuration = SavedFrameConfiguration(
            id: UUID(),
            name: name,
            source: source,
            albumIdentifier: source == .automaticAlbum ? albumIdentifier : nil,
            albumTitle: source == .automaticAlbum ? albumTitle : nil,
            layoutPreference: layoutPreference,
            interval: interval
        )
        configuration.normalize()
        configurations.append(configuration)
        activeConfigurationID = configuration.id
        persist()
    }

    func activate(_ id: UUID) {
        guard isEntitled, configurations.contains(where: { $0.id == id }) else {
            return
        }
        activeConfigurationID = id
        persist()
    }

    func updateActive(
        layoutPreference: FrameLayoutPreference,
        interval: TimeInterval
    ) {
        guard isEntitled,
              let id = activeConfigurationID,
              let index = configurations.firstIndex(where: { $0.id == id }) else {
            return
        }
        configurations[index].layoutPreference = layoutPreference
        configurations[index].interval = interval
        configurations[index].normalize()
        persist()
    }

    func saveCurrent(
        source: FrameConfigurationSource,
        albumIdentifier: String? = nil,
        albumTitle: String? = nil,
        layoutPreference: FrameLayoutPreference,
        interval: TimeInterval
    ) {
        guard isEntitled else { return }
        if let id = activeConfigurationID,
           let index = configurations.firstIndex(where: { $0.id == id }) {
            configurations[index].source = source
            configurations[index].albumIdentifier = source == .automaticAlbum
                ? albumIdentifier
                : nil
            configurations[index].albumTitle = source == .automaticAlbum ? albumTitle : nil
            configurations[index].layoutPreference = layoutPreference
            configurations[index].interval = interval
            configurations[index].normalize()
        } else {
            var configuration = SavedFrameConfiguration(
                id: UUID(),
                name: "My Frame",
                source: source,
                albumIdentifier: source == .automaticAlbum ? albumIdentifier : nil,
                albumTitle: source == .automaticAlbum ? albumTitle : nil,
                layoutPreference: layoutPreference,
                interval: interval
            )
            configuration.normalize()
            configurations.append(configuration)
            activeConfigurationID = configuration.id
        }
        persist()
    }

    func delete(_ id: UUID) {
        guard isEntitled else { return }
        configurations.removeAll { $0.id == id }
        if activeConfigurationID == id {
            activeConfigurationID = configurations.first?.id
        }
        persist()
    }

    private func persist() {
        do {
            try store.saveArchive(
                FrameConfigurationArchive(
                    configurations: configurations,
                    activeConfigurationID: activeConfigurationID
                )
            )
            persistenceError = nil
        } catch {
            persistenceError = error.localizedDescription
        }
    }
}
