import Combine
import SwiftUI
import UIKit

struct WallModeSetupView: View {
    @ObservedObject var wallMode: WallModeController
    @ObservedObject var automaticAlbum: AutomaticAlbumController
    @ObservedObject var frameConfigurations: FrameConfigurationController
    @Binding var currentPhotoMode: PhotoCollectionMode
    @Environment(\.presentationMode) private var presentationMode
    @State private var draft: WallModeConfiguration
    @State private var layoutPreference: FrameLayoutPreference
    @State private var interval: TimeInterval
    @State private var guidedAccessIsEnabled = UIAccessibility.isGuidedAccessEnabled
    @State private var showAlbumPicker = false
    @State private var showReview = false
    @State private var showDeleteAlbumConfirmation = false
    @State private var showResetNeverShowConfirmation = false
    @State private var showMountedTips = false
    let initialSection: WallModeSetupInitialSection?

    init(
        wallMode: WallModeController,
        automaticAlbum: AutomaticAlbumController,
        frameConfigurations: FrameConfigurationController,
        currentPhotoMode: Binding<PhotoCollectionMode>,
        initialSection: WallModeSetupInitialSection? = nil
    ) {
        self.wallMode = wallMode
        self.automaticAlbum = automaticAlbum
        self.frameConfigurations = frameConfigurations
        _currentPhotoMode = currentPhotoMode
        self.initialSection = initialSection
        _draft = State(initialValue: wallMode.configuration)
        _layoutPreference = State(
            initialValue: frameConfigurations.activeConfiguration?.layoutPreference ?? .automatic
        )
        _interval = State(
            initialValue: frameConfigurations.activeConfiguration?.interval ?? 10
        )
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                Form {
                    photosSection
                        .id(WallModeSetupInitialSection.automaticAlbum)

                    slideshowSection
                        .id(WallModeSetupInitialSection.savedConfigurations)

                    displaySection
                        .id(WallModeSetupInitialSection.schedule)

                    mountedTipsSection
                        .id(WallModeSetupInitialSection.checklist)

                    maintenanceSection
                }
                .onAppear {
                    guard let initialSection else { return }
                    if initialSection == .checklist {
                        showMountedTips = true
                    }
                    DispatchQueue.main.async {
                        proxy.scrollTo(initialSection, anchor: .top)
                    }
                }
            }
            .navigationTitle("Frame Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAlbumPicker) {
            AlbumPickerView(controller: automaticAlbum) { _ in
                currentPhotoMode = .automaticAlbum
            }
        }
        .sheet(isPresented: $showReview) {
            AutomaticAlbumReviewView(controller: automaticAlbum)
        }
        .alert(
            "Remove Downloaded Album Photos?",
            isPresented: $showDeleteAlbumConfirmation
        ) {
            Button("Remove Downloads", role: .destructive) {
                automaticAlbum.deleteCachedAlbum()
                if currentPhotoMode == .automaticAlbum {
                    currentPhotoMode = .samples
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes only FrameWink’s copies and analysis. It never changes Apple Photos.")
        }
        .alert(
            "Reset Hidden Photos?",
            isPresented: $showResetNeverShowConfirmation
        ) {
            Button("Reset") {
                automaticAlbum.resetNeverShowChoices()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Photos you previously chose to never show may appear again. Apple Photos is unchanged.")
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

    private var photosSection: some View {
        Section("Photos") {
            HStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 3) {
                    Text(automaticAlbum.selectedAlbumTitle)
                        .font(.headline)
                    Text(automaticAlbumStatus)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Button(
                automaticAlbum.configuration.isConfigured ? "Change Album" : "Choose an Album"
            ) {
                automaticAlbum.requestAccessAndLoadAlbums()
                showAlbumPicker = true
            }
            .accessibilityIdentifier("choose-album")

            if isAlbumBusy {
                ProgressView(value: albumProgress)
                    .accessibilityLabel("Preparing album photos")
            }

            if let report = automaticAlbum.lastSyncReport,
               report.hasPartialFailure {
                Label(partialReport(report), systemImage: "exclamationmark.icloud")
                    .font(.footnote)
                    .foregroundColor(.orange)
            }

            Text("Album changes refresh automatically. Photos may download from iCloud when needed, just like in Photos.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var slideshowSection: some View {
        Section("Slideshow") {
            Picker("Display Style", selection: $layoutPreference) {
                ForEach(frameConfigurations.availableLayoutPreferences) { layout in
                    Text(layout.title).tag(layout)
                }
            }

            Picker("Speed", selection: $interval) {
                ForEach([5.0, 10.0, 30.0, 60.0], id: \.self) { value in
                    Text(intervalTitle(value)).tag(value)
                }
            }

            Text("Automatic style works well for most photos and handles portrait pairs for you.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var displaySection: some View {
        Section("Display") {
            Label("Stays awake while the frame is playing", systemImage: "sun.max.fill")

            Toggle("Night Schedule", isOn: $draft.scheduleEnabled)

            if draft.scheduleEnabled {
                DatePicker(
                    "Begin dimming",
                    selection: minuteBinding(\.dimStartMinute),
                    displayedComponents: .hourAndMinute
                )
                DatePicker(
                    "Screen goes dark",
                    selection: minuteBinding(\.blackoutStartMinute),
                    displayedComponents: .hourAndMinute
                )
                DatePicker(
                    "Resume display",
                    selection: minuteBinding(\.blackoutEndMinute),
                    displayedComponents: .hourAndMinute
                )
            }

            Text("The night schedule applies while FrameWink is open. It cannot relaunch the app after an iPad restart.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var mountedTipsSection: some View {
        Section {
            DisclosureGroup("Mounted iPad Tips", isExpanded: $showMountedTips) {
                Label(
                    guidedAccessIsEnabled ? "Guided Access is on" : "Guided Access is off",
                    systemImage: guidedAccessIsEnabled ? "checkmark.shield.fill" : "shield"
                )
                .foregroundColor(guidedAccessIsEnabled ? .green : .secondary)

                Text("Guided Access is optional. Start it with the iPad’s Accessibility Shortcut after the frame is playing.")
                    .font(.footnote)
                    .foregroundColor(.secondary)

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
                                draft.completedChecklistItems.contains(item) ? .green : .secondary
                            )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title)
                                    .foregroundColor(.primary)
                                Text(item.detail)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var maintenanceSection: some View {
        Section("More Options") {
            if automaticAlbum.smartReel != nil {
                Button("Review Photos") {
                    showReview = true
                }
            }

            if automaticAlbum.configuration.isConfigured {
                Button("Refresh Album Now") {
                    automaticAlbum.refresh()
                }
                .disabled(isAlbumBusy)

                Button("Reset Hidden Photos") {
                    showResetNeverShowConfirmation = true
                }
                .disabled(isAlbumBusy)

                Button("Remove Downloaded Album Photos", role: .destructive) {
                    showDeleteAlbumConfirmation = true
                }
            }

            if let error = wallMode.configurationError
                ?? frameConfigurations.persistenceError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
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

    private var albumProgress: Double? {
        switch automaticAlbum.phase {
        case .syncing(let progress), .curating(let progress):
            return progress.fractionCompleted
        default:
            return nil
        }
    }

    private var automaticAlbumStatus: String {
        switch automaticAlbum.phase {
        case .idle:
            return automaticAlbum.configuration.isConfigured ? "Ready" : "No album selected"
        case .loadingAlbums:
            return "Loading albums…"
        case .syncing(let progress):
            return "Preparing \(progress.completedCount) of \(progress.totalCount)…"
        case .curating(let progress):
            return "Choosing \(progress.completedCount) of \(progress.totalCount)…"
        case .ready(_, let suggestionCount):
            return suggestionCount == 1 ? "1 photo ready" : "\(suggestionCount) photos ready"
        case .accessDenied:
            return "Photos access is unavailable"
        case .failed(let message):
            return message
        }
    }

    private func partialReport(_ report: AlbumSyncReport) -> String {
        if !report.failures.isEmpty {
            return "Some photos could not be prepared. Your existing frame is still available."
        }
        return "Some photos still need to download from iCloud. FrameWink will try again."
    }

    private func intervalTitle(_ value: TimeInterval) -> String {
        switch Int(value) {
        case 5: return "Fast · 5 seconds"
        case 10: return "Normal · 10 seconds"
        case 30: return "Relaxed · 30 seconds"
        default: return "Slow · 1 minute"
        }
    }

    private func saveAndDismiss() {
        wallMode.updateConfiguration(draft)
        frameConfigurations.saveCurrent(
            source: frameSource,
            albumIdentifier: automaticAlbum.configuration.albumIdentifier,
            albumTitle: automaticAlbum.configuration.albumTitle,
            layoutPreference: layoutPreference,
            interval: interval
        )
        guard wallMode.configurationError == nil,
              frameConfigurations.persistenceError == nil else {
            return
        }
        presentationMode.wrappedValue.dismiss()
    }

    private var frameSource: FrameConfigurationSource {
        switch currentPhotoMode {
        case .samples: return .samples
        case .personal: return .freeSmartReel
        case .automaticAlbum: return .automaticAlbum
        }
    }

    private func minuteBinding(
        _ keyPath: WritableKeyPath<WallModeConfiguration, Int>
    ) -> Binding<Date> {
        Binding(
            get: { date(for: draft[keyPath: keyPath]) },
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
}

struct AlbumPickerView: View {
    @ObservedObject var controller: AutomaticAlbumController
    let onSelect: (PhotoLibraryAlbum) -> Void
    @Environment(\.presentationMode) private var presentationMode

    init(
        controller: AutomaticAlbumController,
        onSelect: @escaping (PhotoLibraryAlbum) -> Void = { _ in }
    ) {
        self.controller = controller
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationView {
            Group {
                if controller.authorization == .denied
                    || controller.authorization == .restricted {
                    emptyState(
                        icon: "lock.slash",
                        title: "Photos access is unavailable",
                        detail: "Allow Photos access for FrameWink in iPad Settings, then try again."
                    )
                } else if case .failed(let message) = controller.phase {
                    VStack(spacing: 14) {
                        emptyState(
                            icon: "exclamationmark.triangle",
                            title: "Albums couldn’t be loaded",
                            detail: LocalizedStringKey(message)
                        )
                        Button("Try Again") {
                            controller.requestAccessAndLoadAlbums()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .accessibilityIdentifier("album-picker-error")
                } else if controller.phase == .loadingAlbums {
                    VStack(spacing: 14) {
                        ProgressView()
                        Text("Loading albums…")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityIdentifier("album-picker-loading")
                } else if controller.albums.isEmpty {
                    VStack(spacing: 14) {
                        emptyState(
                            icon: "photo.on.rectangle.angled",
                            title: "No albums available",
                            detail: "Create an album in Photos or change Photos access, then try again."
                        )
                        Button("Try Again") {
                            controller.requestAccessAndLoadAlbums()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .accessibilityIdentifier("album-picker-empty")
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 150), spacing: 18, alignment: .top),
                            ],
                            alignment: .leading,
                            spacing: 24
                        ) {
                            ForEach(controller.albums) { album in
                                AlbumPickerTile(
                                    album: album,
                                    isSelected: controller.configuration
                                        .albumIdentifier == album.id,
                                    loadThumbnail: { maxPixelDimension, progress in
                                        await controller.thumbnail(
                                            for: album,
                                            maxPixelDimension: maxPixelDimension,
                                            progress: progress
                                        )
                                    },
                                    onSelect: {
                                        select(album)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                    }
                    .accessibilityIdentifier("album-picker-list")
                }
            }
            .navigationTitle("Choose an Album")
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

    private func select(_ album: PhotoLibraryAlbum) {
        controller.selectAlbum(album)
        onSelect(album)
        presentationMode.wrappedValue.dismiss()
    }

    private func emptyState(
        icon: String,
        title: LocalizedStringKey,
        detail: LocalizedStringKey
    ) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text(title)
                .font(.title2.weight(.semibold))
            Text(detail)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(32)
    }

}

private struct AlbumPickerTile: View {
    let album: PhotoLibraryAlbum
    let isSelected: Bool
    let loadThumbnail: (
        Int,
        @escaping (AlbumThumbnailLoadingPhase) -> Void
    ) async -> UIImage?
    let onSelect: () -> Void

    @Environment(\.displayScale) private var displayScale
    @State private var thumbnail: UIImage?
    @State private var requestedPixelDimension = 0
    @State private var loadingState = AlbumCoverLoadingState.local

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    GeometryReader { proxy in
                        albumCover
                            .frame(
                                width: proxy.size.width,
                                height: proxy.size.width
                            )
                            .clipped()
                            .onAppear {
                                updateRequestedPixelDimension(proxy.size.width)
                            }
                            .onChange(of: proxy.size.width) { width in
                                updateRequestedPixelDimension(width)
                            }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.white, Color.accentColor)
                            .padding(8)
                            .accessibilityHidden(true)
                    }
                }

                Text(album.title)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(albumCountDescription)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(albumCoverAccessibilityIdentifier)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Select this album for your frame")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .task(id: thumbnailRequestID) {
            guard requestedPixelDimension > 0 else { return }
            loadingState = .local
            let loadedThumbnail = await loadThumbnail(requestedPixelDimension) { phase in
                guard thumbnail == nil else { return }
                loadingState = phase == .cloud ? .cloud : .local
            }
            guard !Task.isCancelled else { return }
            if let loadedThumbnail {
                thumbnail = loadedThumbnail
                loadingState = .ready
            } else if thumbnail == nil {
                loadingState = .unavailable
            }
        }
    }

    @ViewBuilder
    private var albumCover: some View {
        if let thumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Color(UIColor.secondarySystemBackground)
                switch loadingState {
                case .local, .ready:
                    ProgressView()
                        .accessibilityLabel("Loading album cover from this iPad")
                case .cloud:
                    VStack(spacing: 8) {
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.title2)
                        ProgressView()
                    }
                    .foregroundColor(.secondary)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Downloading album cover from iCloud Photos")
                case .unavailable:
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 38, weight: .light))
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Album cover unavailable")
                }
            }
        }
    }

    private var albumCountDescription: String {
        guard let photoCount = album.photoCount else { return "Photo album" }
        return photoCount == 1 ? "1 photo" : "\(photoCount) photos"
    }

    private var accessibilityLabel: Text {
        let selectedDescription = isSelected ? ", selected" : ""
        return Text("\(album.title), \(albumCountDescription)\(selectedDescription)")
    }

    private var albumCoverAccessibilityIdentifier: String {
        if thumbnail != nil { return "album-cover-ready" }
        switch loadingState {
        case .local, .ready:
            return "album-cover-loading"
        case .cloud:
            return "album-cover-cloud-loading"
        case .unavailable:
            return "album-cover-unavailable"
        }
    }

    private var thumbnailRequestID: String {
        "\(album.id)|\(requestedPixelDimension)"
    }

    private func updateRequestedPixelDimension(_ pointDimension: CGFloat) {
        let physicalPixels = Int(ceil(pointDimension * displayScale))
        let roundedPixels = ((max(physicalPixels, 1) + 63) / 64) * 64
        requestedPixelDimension = min(max(roundedPixels, 256), 768)
    }
}

private enum AlbumCoverLoadingState {
    case local
    case cloud
    case ready
    case unavailable
}
