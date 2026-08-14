import Combine
import SwiftUI
import UIKit

struct WallModeSetupView: View {
    @ObservedObject var wallMode: WallModeController
    @Environment(\.presentationMode) private var presentationMode
    @State private var draft: WallModeConfiguration
    @State private var guidedAccessIsEnabled = UIAccessibility.isGuidedAccessEnabled
    @State private var showMountedTips = false
    @State private var showScheduleTimes = false
    let initialSection: WallModeSetupInitialSection?

    init(
        wallMode: WallModeController,
        initialSection: WallModeSetupInitialSection? = nil
    ) {
        self.wallMode = wallMode
        self.initialSection = initialSection
        _draft = State(initialValue: wallMode.configuration)
        _showScheduleTimes = State(initialValue: initialSection == .schedule)
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                Form {
                    displaySection
                        .id(WallModeSetupInitialSection.schedule)

                    mountedTipsSection
                        .id(WallModeSetupInitialSection.checklist)
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

    private var displaySection: some View {
        Section("Display") {
            Label("Stays awake while the frame is playing", systemImage: "sun.max.fill")

            Toggle("Night Schedule", isOn: $draft.scheduleEnabled)

            if draft.scheduleEnabled {
                Text(scheduleSummary)
                    .font(.footnote)
                    .foregroundColor(.secondary)

                DisclosureGroup("Adjust Schedule", isExpanded: $showScheduleTimes) {
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
            }

            Text("The night schedule applies while FrameWink is open. It cannot relaunch the app after a device restart.")
                .font(.footnote)
                .foregroundColor(.secondary)

            if let error = wallMode.configurationError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
        }
    }

    private var mountedTipsSection: some View {
        Section {
            DisclosureGroup("Mounted Display Tips", isExpanded: $showMountedTips) {
                Label(
                    guidedAccessIsEnabled ? "Guided Access is on" : "Guided Access is off",
                    systemImage: guidedAccessIsEnabled ? "checkmark.shield.fill" : "shield"
                )
                .foregroundColor(guidedAccessIsEnabled ? .green : .secondary)

                Text("Guided Access is optional. Start it with the device’s Accessibility Shortcut after the frame is playing.")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                mountedTip(
                    "Use reliable power and keep the device ventilated.",
                    systemImage: "powerplug"
                )
                mountedTip(
                    "Keep the charging cable strain-free and check battery condition regularly.",
                    systemImage: "battery.100"
                )
                mountedTip(
                    "Lock orientation before mounting if you want a fixed presentation.",
                    systemImage: "rectangle.portrait.rotate"
                )
                mountedTip(
                    "After a device restart, open FrameWink and start the frame again.",
                    systemImage: "arrow.clockwise"
                )
            }
        }
    }

    private func saveAndDismiss() {
        wallMode.updateConfiguration(draft)
        guard wallMode.configurationError == nil else { return }
        presentationMode.wrappedValue.dismiss()
    }

    private var scheduleSummary: String {
        "Dims at \(timeTitle(draft.dimStartMinute)) · Dark at \(timeTitle(draft.blackoutStartMinute)) · Resumes at \(timeTitle(draft.blackoutEndMinute))"
    }

    private func timeTitle(_ minute: Int) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date(for: minute))
    }

    private func mountedTip(_ text: LocalizedStringKey, systemImage: String) -> some View {
        Label {
            Text(text)
                .font(.footnote)
        } icon: {
            Image(systemName: systemImage)
                .foregroundColor(.secondary)
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
                        detail: "Allow Photos access for FrameWink in Settings, then try again."
                    )
                } else if case .failed(let message) = controller.albumCatalogPhase,
                          controller.albums.isEmpty {
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
                } else if controller.albumCatalogPhase == .loading,
                          controller.albums.isEmpty {
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
                                    preheatThumbnails: { maxPixelDimension in
                                        controller.preheatAlbumCovers(
                                            maxPixelDimension: maxPixelDimension
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
                ToolbarItem(placement: .confirmationAction) {
                    if controller.albumCatalogPhase == .loading,
                       !controller.albums.isEmpty {
                        ProgressView()
                            .accessibilityLabel("Refreshing albums")
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
    let preheatThumbnails: (Int) -> Void
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
                    Image(systemName: "photo")
                        .font(.system(size: 34, weight: .light))
                        .foregroundColor(.secondary.opacity(0.45))
                        .accessibilityLabel("Loading album cover from this device")
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
        let dimension = min(max(roundedPixels, 256), 768)
        guard requestedPixelDimension != dimension else { return }
        preheatThumbnails(dimension)
        requestedPixelDimension = dimension
    }
}

private enum AlbumCoverLoadingState {
    case local
    case cloud
    case ready
    case unavailable
}
