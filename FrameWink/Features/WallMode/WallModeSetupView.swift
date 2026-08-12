import Combine
import SwiftUI
import UIKit

struct WallModeSetupView: View {
    @ObservedObject var wallMode: WallModeController
    @ObservedObject var automaticAlbum: AutomaticAlbumController
    @ObservedObject var frameConfigurations: FrameConfigurationController
    @Environment(\.presentationMode) private var presentationMode
    @State private var draft: WallModeConfiguration
    @State private var guidedAccessIsEnabled = UIAccessibility.isGuidedAccessEnabled
    @State private var showAlbumPicker = false
    @State private var showDeleteAlbumConfirmation = false
    @State private var newConfigurationName = "My Frame"
    @State private var newConfigurationSource = FrameConfigurationSource.samples
    @State private var newConfigurationLayout = FrameLayoutPreference.automatic
    @State private var newConfigurationInterval: TimeInterval = 10

    init(
        wallMode: WallModeController,
        automaticAlbum: AutomaticAlbumController,
        frameConfigurations: FrameConfigurationController
    ) {
        self.wallMode = wallMode
        self.automaticAlbum = automaticAlbum
        self.frameConfigurations = frameConfigurations
        _draft = State(initialValue: wallMode.configuration)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Label("Wall Mode Lifetime", systemImage: "checkmark.seal.fill")
                        .foregroundColor(.accentColor)
                    Text("Your one-time Wall Mode unlock is active. These settings stay on this iPad and never upload your photos or configuration.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("Automatic Photos album") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(automaticAlbum.selectedAlbumTitle)
                                .font(.headline)
                            Text(automaticAlbumStatus)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(
                            automaticAlbum.configuration.isConfigured
                                ? "Change Album"
                                : "Choose Album"
                        ) {
                            automaticAlbum.requestAccessAndLoadAlbums()
                            showAlbumPicker = true
                        }
                    }

                    Toggle(
                        "Refresh when the selected album changes",
                        isOn: Binding(
                            get: { automaticAlbum.configuration.automaticRefresh },
                            set: automaticAlbum.setAutomaticRefresh
                        )
                    )
                    .disabled(!automaticAlbum.configuration.isConfigured)

                    Toggle(
                        "Strict Offline",
                        isOn: Binding(
                            get: { automaticAlbum.configuration.strictOffline },
                            set: automaticAlbum.setStrictOffline
                        )
                    )
                    .disabled(!automaticAlbum.configuration.isConfigured)

                    Text("Strict Offline skips album photos that Apple Photos has not downloaded to this iPad. Turn it off to let Apple Photos fetch selected-album items from iCloud during refresh. FrameWink never uploads them.")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    if automaticAlbum.configuration.isConfigured {
                        HStack {
                            Button("Refresh Now") {
                                automaticAlbum.refresh()
                            }
                            .disabled(isAlbumBusy)

                            Spacer()

                            Button("Delete Automatic Album Cache", role: .destructive) {
                                showDeleteAlbumConfirmation = true
                            }
                        }
                    }

                    if let report = automaticAlbum.lastSyncReport,
                       report.hasPartialFailure {
                        Text(partialReport(report))
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }
                }

                Section("Saved frame configurations") {
                    if frameConfigurations.configurations.isEmpty {
                        Text("Save different photo sources, layouts, and timing for quick reuse.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(frameConfigurations.configurations) { configuration in
                            HStack {
                                Button {
                                    frameConfigurations.activate(configuration.id)
                                } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack {
                                            Text(configuration.name)
                                                .foregroundColor(.primary)
                                            if frameConfigurations.activeConfigurationID
                                                == configuration.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        Text(
                                            configurationSummary(configuration)
                                        )
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button(role: .destructive) {
                                    frameConfigurations.delete(configuration.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .accessibilityLabel(
                                    "Delete \(configuration.name) configuration"
                                )
                            }
                        }
                    }

                    TextField("Configuration name", text: $newConfigurationName)

                    Picker("Photo source", selection: $newConfigurationSource) {
                        ForEach(FrameConfigurationSource.allCases) { source in
                            Text(source.title).tag(source)
                        }
                    }

                    Picker("Layout", selection: $newConfigurationLayout) {
                        ForEach(frameConfigurations.availableLayoutPreferences) { layout in
                            Text(layout.title).tag(layout)
                        }
                    }

                    Picker("Photo interval", selection: $newConfigurationInterval) {
                        ForEach([5.0, 10.0, 30.0, 60.0], id: \.self) { interval in
                            Text("\(Int(interval)) sec").tag(interval)
                        }
                    }

                    Button("Save and Activate Configuration") {
                        frameConfigurations.create(
                            name: newConfigurationName,
                            source: newConfigurationSource,
                            albumIdentifier: automaticAlbum.configuration.albumIdentifier,
                            albumTitle: automaticAlbum.configuration.albumTitle,
                            layoutPreference: newConfigurationLayout,
                            interval: newConfigurationInterval
                        )
                        newConfigurationName = "My Frame \(frameConfigurations.configurations.count + 1)"
                    }

                    Text("Mosaic is a paid four-photo layout. A configuration whose source is not ready falls back to Sample Photos until that source becomes available.")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    if let error = frameConfigurations.persistenceError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }

                Section("Foreground display schedule") {
                    Toggle("Use dimming and blackout schedule", isOn: $draft.scheduleEnabled)

                    DatePicker(
                        "Begin dimming",
                        selection: minuteBinding(\.dimStartMinute),
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!draft.scheduleEnabled)

                    DatePicker(
                        "Begin blackout",
                        selection: minuteBinding(\.blackoutStartMinute),
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!draft.scheduleEnabled)

                    DatePicker(
                        "End blackout",
                        selection: minuteBinding(\.blackoutEndMinute),
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!draft.scheduleEnabled)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dimming strength: \(Int(draft.dimOpacity * 100))%")
                        Slider(value: $draft.dimOpacity, in: 0.15...0.9)
                            .disabled(!draft.scheduleEnabled)
                    }

                    Text("The schedule is a black visual overlay only while FrameWink is visible in the foreground. It does not change system brightness, lock the iPad, wake a suspended app, or relaunch after a restart.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("Guided Access") {
                    HStack {
                        Label(
                            guidedAccessIsEnabled ? "Guided Access is active" : "Guided Access is not active",
                            systemImage: guidedAccessIsEnabled ? "checkmark.shield.fill" : "shield"
                        )
                        .foregroundColor(guidedAccessIsEnabled ? .green : .secondary)
                        Spacer()
                    }

                    Text("Start Frame Mode, then use the iPad’s configured Accessibility Shortcut to begin Guided Access. FrameWink can report the public status but cannot switch consumer Guided Access on for you.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("Wall commissioning checklist") {
                    ForEach(WallChecklistItem.allCases) { item in
                        Button {
                            toggle(item)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(
                                    systemName: draft.completedChecklistItems.contains(item)
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                )
                                .foregroundColor(
                                    draft.completedChecklistItems.contains(item)
                                        ? .green
                                        : .secondary
                                )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .foregroundColor(.primary)
                                    Text(item.detail)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(item.title)
                        .accessibilityValue(
                            draft.completedChecklistItems.contains(item)
                                ? "Completed"
                                : "Not completed"
                        )
                    }
                }

                if let error = wallMode.configurationError {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Wall Mode Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        wallMode.updateConfiguration(draft)
                        if wallMode.configurationError == nil {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAlbumPicker) {
            AlbumPickerView(controller: automaticAlbum)
        }
        .alert(
            "Delete Automatic Album Cache?",
            isPresented: $showDeleteAlbumConfirmation
        ) {
            Button("Delete Cache", role: .destructive) {
                automaticAlbum.deleteCachedAlbum()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes FrameWink’s display-sized automatic-album copies, derived records, and current automatic source. It never changes any album or original in Apple Photos. A saved automatic configuration can rebuild the cache when you activate it again.")
        }
        .onAppear {
            guidedAccessIsEnabled = UIAccessibility.isGuidedAccessEnabled
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIAccessibility.guidedAccessStatusDidChangeNotification
            )
        ) { _ in
            guidedAccessIsEnabled = UIAccessibility.isGuidedAccessEnabled
        }
    }

    private func minuteBinding(
        _ keyPath: WritableKeyPath<WallModeConfiguration, Int>
    ) -> Binding<Date> {
        Binding(
            get: {
                date(for: draft[keyPath: keyPath])
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                draft[keyPath: keyPath] = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            }
        )
    }

    private func date(for minute: Int) -> Date {
        let start = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(byAdding: .minute, value: minute, to: start) ?? start
    }

    private func toggle(_ item: WallChecklistItem) {
        if draft.completedChecklistItems.contains(item) {
            draft.completedChecklistItems.remove(item)
        } else {
            draft.completedChecklistItems.insert(item)
        }
    }

    private var isAlbumBusy: Bool {
        switch automaticAlbum.phase {
        case .loadingAlbums, .syncing, .curating:
            return true
        default:
            return false
        }
    }

    private var automaticAlbumStatus: String {
        switch automaticAlbum.phase {
        case .idle:
            return automaticAlbum.configuration.isConfigured
                ? "Ready to refresh"
                : "Optional paid source; access is requested only when you choose it"
        case .loadingAlbums:
            return "Loading authorized albums…"
        case .syncing(let progress):
            return "Preparing \(progress.completedCount) of \(progress.totalCount)…"
        case .curating(let progress):
            return "Curating \(progress.completedCount) of \(progress.totalCount)…"
        case .ready(let photoCount, let suggestionCount):
            return "\(suggestionCount) suggestions from \(photoCount) locally cached photos"
        case .accessDenied:
            return "Photos access is denied or restricted; Free Smart Reel still works"
        case .failed(let message):
            return message
        }
    }

    private func partialReport(_ report: AlbumSyncReport) -> String {
        let cloud = report.cloudOnlyCount > 0
            ? "\(report.cloudOnlyCount) iCloud-only photo(s) skipped. "
            : ""
        let failures = report.failures.isEmpty
            ? ""
            : "\(report.failures.count) photo(s) could not be prepared. "
        return cloud + failures + "Existing local selections remain usable."
    }

    private func configurationSummary(
        _ configuration: SavedFrameConfiguration
    ) -> String {
        let source = configuration.source == .automaticAlbum
            ? (configuration.albumTitle ?? configuration.source.title)
            : configuration.source.title
        return "\(source) · \(configuration.layoutPreference.title) · \(Int(configuration.interval)) sec"
    }
}

private struct AlbumPickerView: View {
    @ObservedObject var controller: AutomaticAlbumController
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            Group {
                if controller.authorization == .denied
                    || controller.authorization == .restricted {
                    VStack(spacing: 14) {
                        Image(systemName: "lock.slash")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("Photos access is unavailable")
                            .font(.title2.weight(.semibold))
                        Text("Free Smart Reel needs no broad permission. To use an automatic album, allow Photos access for FrameWink in iPad Settings, then try again.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding(32)
                } else if controller.albums.isEmpty {
                    VStack(spacing: 14) {
                        ProgressView()
                        Text("Loading albums…")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(controller.albums) { album in
                        Button {
                            controller.selectAlbum(album)
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(album.title)
                                        .foregroundColor(.primary)
                                    Text("\(album.photoCount) photos")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if controller.configuration.albumIdentifier == album.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Automatic Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
