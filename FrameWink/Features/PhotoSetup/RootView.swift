import SwiftUI

private enum SheetDestination: String, Identifiable, Equatable {
    case photos
    case photoPicker
    case importStatus
    case albumPicker
    case privacy
    case reviewSuggestions
    case automaticAlbumReview
    case frameSettings
    case wallModePaywall

    var id: String { rawValue }
}

enum FrameContentSelector {
    static func slides(
        for mode: PhotoCollectionMode,
        standardSlides: [DisplaySlide],
        automaticAlbumSlides: [DisplaySlide],
        isInitialPersonalImport: Bool = false
    ) -> [DisplaySlide] {
        if isInitialPersonalImport { return [] }
        return mode == .automaticAlbum ? automaticAlbumSlides : standardSlides
    }
}

enum FramePreparationPresentation {
    static func isInitialPersonalImport(
        phase: ImportPhase,
        importedPhotoCount: Int
    ) -> Bool {
        guard importedPhotoCount == 0 else { return false }
        switch phase {
        case .importing, .cancelling:
            return true
        case .idle, .finished, .deletionFailed:
            return false
        }
    }

    static func showsBackdrop(
        hasSlides: Bool,
        isPreparing: Bool,
        isFrameMode: Bool
    ) -> Bool {
        !hasSlides && isPreparing && !isFrameMode
    }
}

struct RootView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var wallMode: WallModeController
    @ObservedObject var purchases: PurchaseController
    @ObservedObject var automaticAlbum: AutomaticAlbumController
    @ObservedObject var frameConfigurations: FrameConfigurationController
    let initialPresentation: RootInitialPresentation?

    @State private var presentedSheet: SheetDestination?
    @State private var isFrameMode = false
    @State private var didApplyInitialPresentation = false
    @AppStorage("preferredPhotoCollectionMode") private var preferredPhotoMode = ""

    init(
        model: AppModel,
        wallMode: WallModeController,
        purchases: PurchaseController,
        automaticAlbum: AutomaticAlbumController,
        frameConfigurations: FrameConfigurationController,
        initialPresentation: RootInitialPresentation? = nil
    ) {
        self.model = model
        self.wallMode = wallMode
        self.purchases = purchases
        self.automaticAlbum = automaticAlbum
        self.frameConfigurations = frameConfigurations
        self.initialPresentation = initialPresentation
    }

    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                let isCompact = proxy.size.width < 700 || proxy.size.height < 620

                ZStack {
                    SampleSlideshowView(
                        slides: displayedSlides,
                        loadImportedImage: { photo in
                            await model.image(for: photo)
                        },
                        loadAutomaticAlbumImage: { photo in
                            await automaticAlbum.image(for: photo)
                        },
                        automaticAlbumPhotoDidDisplay: { photo in
                            automaticAlbum.recordDisplayed(photo)
                        },
                        preferredLayoutPreference: activeLayoutPreference,
                        preferredInterval: activeInterval,
                        allowsAutomaticMosaic: frameConfigurations.isEntitled,
                        presentationDidChange: saveCurrentPresentation,
                        isFrameMode: $isFrameMode,
                        wallVisualState: wallMode.visualState,
                        refreshWallSchedule: wallMode.refresh
                    )
                    .ignoresSafeArea()

                    if FramePreparationPresentation.showsBackdrop(
                        hasSlides: !displayedSlides.isEmpty,
                        isPreparing: isPreparingCurrentSource,
                        isFrameMode: isFrameMode
                    ) {
                        preparationBackdrop
                            .ignoresSafeArea()
                    }

                    if !isFrameMode && !isInitialPersonalImport {
                        chrome(isCompact: isCompact)
                    }

                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .statusBarHidden(isFrameMode)
        .framePersistentSystemOverlaysHidden(isFrameMode)
        .sheet(item: $presentedSheet) { destination in
            switch destination {
            case .photos:
                PhotosSheet(
                    model: model,
                    automaticAlbum: automaticAlbum,
                    purchases: purchases,
                    currentPhotoMode: $model.collectionMode,
                    choosePhotos: {
                        replacePresentedSheet(with: .photoPicker)
                    },
                    chooseAlbum: {
                        replacePresentedSheet(
                            with: purchases.isWallModeUnlocked
                                ? .albumPicker
                                : .wallModePaywall
                        )
                        if purchases.isWallModeUnlocked {
                            automaticAlbum.requestAccessAndLoadAlbums()
                        }
                    },
                    reviewPersonalPhotos: {
                        replacePresentedSheet(with: .reviewSuggestions)
                    },
                    reviewAutomaticAlbum: {
                        replacePresentedSheet(with: .automaticAlbumReview)
                    }
                )
            case .photoPicker:
                PhotoPickerView(selectionLimit: model.remainingPhotoCapacity) { items in
                    model.importSelectedItems(items)
                }
                .ignoresSafeArea()
            case .importStatus:
                ImportStatusCard(
                    phase: model.importPhase,
                    canRetry: model.canRetryImport,
                    cancel: model.cancelImport,
                    retry: model.retryImport,
                    dismiss: model.dismissImportStatus
                )
            case .albumPicker:
                AlbumPickerView(controller: automaticAlbum) { _ in
                    selectPhotoMode(.automaticAlbum)
                }
            case .privacy:
                PrivacyAndDataSheet(
                    model: model,
                    automaticAlbum: automaticAlbum,
                    currentPhotoMode: $model.collectionMode
                )
            case .reviewSuggestions:
                ReviewSuggestionsView(model: model)
            case .automaticAlbumReview:
                AutomaticAlbumReviewView(controller: automaticAlbum)
            case .frameSettings:
                WallModeSetupView(
                    wallMode: wallMode,
                    initialSection: initialPresentation.wallModeSetupSection
                )
            case .wallModePaywall:
                WallModePaywallView(
                    purchases: purchases,
                    initiallyShowsPurchaseControls: initialPresentation
                        == .wallModePaywallPurchase
                )
            }
        }
        .onChange(of: isFrameMode) { isActive in
            wallMode.setFrameModeActive(isActive)
            synchronizeImportStatusPresentation(shouldShowImportStatus)
#if DEBUG
            PhysicalAcceptanceRecorder.shared.recordStateChange()
#endif
        }
        .onChange(of: model.collectionMode) { mode in
            preferredPhotoMode = mode.rawValue
        }
        .onChange(of: shouldShowImportStatus) { shouldShow in
            synchronizeImportStatusPresentation(shouldShow)
        }
        .onChange(of: frameConfigurations.activeConfigurationID) { _ in
            applyActiveFrameConfiguration()
        }
        .onAppear {
            wallMode.setFrameModeActive(isFrameMode)
            applyActiveFrameConfiguration()
            if initialPresentation == nil {
                restorePreferredPhotoMode()
            }
            applyInitialPresentationIfNeeded()
            synchronizeImportStatusPresentation(shouldShowImportStatus)
        }
#if DEBUG
        .onAppear {
            if DebugScreenshotScenario.current == .albumPicker {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    automaticAlbum.requestAccessAndLoadAlbums()
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    presentedSheet = .albumPicker
                }
            }
        }
#endif
        .onDisappear {
            wallMode.restoreOwnedDisplayState()
        }
    }

    private func chrome(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 10 : 16) {
            HStack(alignment: .top) {
                sampleBadge

                Spacer()

                homeMenu
            }
            .padding(.horizontal, isCompact ? 16 : 26)
            .padding(.top, isCompact ? 10 : 18)

            Spacer()

            setupCard(isCompact: isCompact)
                .padding(.horizontal, isCompact ? 14 : 26)
                .padding(.bottom, isCompact ? 10 : 18)
        }
    }

    private var homeMenu: some View {
        Menu {
            Button {
                presentedSheet = .photos
            } label: {
                Label("Photos…", systemImage: "photo.on.rectangle.angled")
            }

            Button {
                presentedSheet = purchases.isWallModeUnlocked
                    ? .frameSettings
                    : .wallModePaywall
            } label: {
                Label(
                    purchases.isWallModeUnlocked ? "Frame Settings" : "More Frame Features",
                    systemImage: purchases.isWallModeUnlocked ? "gearshape" : "sparkles"
                )
            }

            Divider()

            Button {
                presentedSheet = .privacy
            } label: {
                Label("Privacy & Data", systemImage: "lock.shield")
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(.system(size: 34))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 6)
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More")
        .accessibilityHint("Change photos, review selections, or open settings")
    }

    @ViewBuilder
    private var sampleBadge: some View {
        if model.collectionMode == .samples {
            Label("Sample Photos", systemImage: "sparkles")
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.black.opacity(0.52), in: Capsule())
                .accessibilityLabel("Bundled sample photos")
        }
    }

    private func setupCard(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? 13 : 20) {
            VStack(alignment: .leading, spacing: 7) {
                Text(setupTitle)
                    .font((isCompact ? Font.title3 : Font.title2).weight(.semibold))
                    .foregroundColor(.primary)

                if model.collectionMode == .automaticAlbum {
                    Text(automaticAlbumStatus)
                        .foregroundColor(.secondary)

                    if case .syncing(let progress) = automaticAlbum.phase {
                        automaticAlbumProgress(progress, label: "Automatic album sync progress")
                    } else if case .curating(let progress) = automaticAlbum.phase {
                        automaticAlbumProgress(progress, label: "Automatic album curation progress")
                    }
                } else if model.collectionMode == .samples {
                    Text(sampleSetupDescription)
                        .foregroundColor(.secondary)
                } else {
                    Text(curationStatus)
                        .foregroundColor(.secondary)

                    if case .analyzing(let progress) = model.curationPhase {
                        ProgressView(value: progress.fractionCompleted)
                            .accessibilityLabel("Smart Reel analysis progress")
                            .accessibilityValue("\(progress.completedCount) of \(progress.totalCount)")
                    }
                }
            }

            setupActions(isCompact: isCompact)
        }
        .padding(isCompact ? 16 : 22)
        .frame(maxWidth: 860)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 20, y: 8)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-setup-card")
    }

    @ViewBuilder
    private func setupActions(isCompact: Bool) -> some View {
        let actions = Group {
            primarySetupAction
            secondarySetupAction
        }

        if isCompact {
            VStack(spacing: 10) {
                actions
            }
        } else {
            HStack(spacing: 12) {
                actions
            }
        }
    }

    private var primarySetupAction: some View {
                Button {
                    primaryAction()
                } label: {
                    Label(primaryActionTitle, systemImage: primaryActionIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(primaryActionIsDisabled)
                .accessibilityIdentifier(
                    primaryActionTitle == "Choose an Album"
                        ? "album-picker-action"
                        : "primary-frame-action"
                )
    }

    private var secondarySetupAction: some View {
                Button(secondaryActionTitle) {
                    secondaryAction()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(secondaryActionIsDisabled)
                .accessibilityIdentifier(
                    model.collectionMode == .automaticAlbum
                        ? "album-picker-action"
                        : "secondary-photo-action"
                )
    }

    private var preparationBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.14), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.white.opacity(0.72))
                    .accessibilityHidden(true)

                Text("Preparing \(setupTitle) on this device")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.86))

                if let progress = currentPreparationProgress {
                    Group {
                        if progress.totalCount > 0 {
                            ProgressView(value: progress.fractionCompleted)
                                .accessibilityValue(
                                    "\(progress.completedCount) of \(progress.totalCount)"
                                )
                        } else {
                            ProgressView()
                        }
                    }
                    .progressViewStyle(.linear)
                    .tint(.white)
                    .frame(maxWidth: 360)
                    .accessibilityLabel(currentPreparationAccessibilityLabel)

                    Text(currentPreparationDetail)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.72))
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
            .padding(.bottom, 110)
        }
        .allowsHitTesting(false)
    }

    private var currentPreparationProgress: ImportProgress? {
        if isInitialPersonalImport {
            switch model.importPhase {
            case .importing(let progress), .cancelling(let progress):
                return progress
            case .idle, .finished, .deletionFailed:
                return nil
            }
        }
        switch model.collectionMode {
        case .automaticAlbum:
            switch automaticAlbum.phase {
            case .syncing(let progress), .curating(let progress):
                return progress
            default:
                return nil
            }
        case .personal:
            if case .analyzing(let progress) = model.curationPhase {
                return progress
            }
            if case .importing(let progress) = model.importPhase {
                return progress
            }
            if case .cancelling(let progress) = model.importPhase {
                return progress
            }
            return nil
        case .samples:
            return nil
        }
    }

    private var currentPreparationDetail: String {
        if model.collectionMode == .automaticAlbum {
            return automaticAlbumStatus
        }
        switch model.importPhase {
        case .importing(let progress):
            return "Preparing \(progress.completedCount) of \(progress.totalCount) selected photos…"
        case .cancelling:
            return "Stopping after the current photo…"
        case .idle, .finished, .deletionFailed:
            break
        }
        return curationStatus
    }

    private var currentPreparationAccessibilityLabel: String {
        if model.collectionMode == .automaticAlbum,
           case .curating = automaticAlbum.phase {
            return "Automatic album curation progress"
        }
        if model.collectionMode == .automaticAlbum {
            return "Automatic album sync progress"
        }
        return "Photo preparation progress"
    }

    private var curationStatus: String {
        if model.smartReel != nil {
            switch model.importPhase {
            case .importing(let progress):
                return "\(model.smartReel?.selections.count ?? 0) photos in your reel — adding more (\(progress.completedCount) of \(progress.totalCount))…"
            case .cancelling:
                return "Your reel is ready. Stopping after the current photo…"
            case .idle, .finished, .deletionFailed:
                break
            }
        }
        switch model.curationPhase {
        case .idle:
            return "\(model.importedPhotos.count) photos are ready."
        case .analyzing(let progress):
            return "Finding your best photos — \(progress.completedCount) of \(progress.totalCount)…"
        case .ready(let count):
            if model.importedPhotos.count > count {
                return "\(count) photos in your reel from \(model.importedPhotos.count) selected."
            }
            return count == 1 ? "1 photo is ready." : "\(count) photos are ready."
        case .cancelled:
            return "Photo preparation paused."
        case .failed:
            return "Your photos are safe, but preparation needs another try."
        }
    }

    private var displayedSlides: [DisplaySlide] {
        FrameContentSelector.slides(
            for: model.collectionMode,
            standardSlides: model.slides,
            automaticAlbumSlides: automaticAlbum.slides,
            isInitialPersonalImport: isInitialPersonalImport
        )
    }

    private var isInitialPersonalImport: Bool {
        FramePreparationPresentation.isInitialPersonalImport(
            phase: model.importPhase,
            importedPhotoCount: model.importedPhotos.count
        )
    }

    private var setupTitle: String {
        if isInitialPersonalImport { return "My Photos" }
        switch model.collectionMode {
        case .automaticAlbum:
            return automaticAlbum.selectedAlbumTitle
        case .personal:
            return "My Photos"
        case .samples:
            return model.importedPhotos.isEmpty ? "Make this frame yours" : "Sample Photos"
        }
    }

    private var sampleSetupDescription: String {
        if !model.importedPhotos.isEmpty {
            return "Enjoy the examples, or switch back to your selected photos."
        }
        if purchases.isWallModeUnlocked {
            return "Choose a Photos album and FrameWink will quietly find the best photos for your frame."
        }
        return "Choose a few favorites and FrameWink will quietly prepare them for your frame."
    }

    private var automaticAlbumStatus: String {
        switch automaticAlbum.phase {
        case .idle:
            return automaticAlbum.configuration.isConfigured
                ? "This album will update automatically."
                : "Choose a Photos album to begin."
        case .loadingAlbums:
            return "Loading your albums…"
        case .syncing(let progress):
            if let readyCount = automaticAlbum.smartReel?.selections.count,
               readyCount > 0 {
                return "\(readyCount) photos ready — adding more (\(progress.completedCount) of \(progress.totalCount))…"
            }
            return "Preparing \(progress.completedCount) of \(progress.totalCount) photos…"
        case .curating(let progress):
            if let readyCount = automaticAlbum.smartReel?.selections.count,
               readyCount > 0 {
                return "\(readyCount) photos ready — improving your reel (\(progress.completedCount) of \(progress.totalCount))…"
            }
            return "Finding your best photos — \(progress.completedCount) of \(progress.totalCount)…"
        case .ready(let photoCount, let suggestionCount):
            if suggestionCount == 1 { return "1 photo is ready from \(photoCount) album item(s)." }
            return "\(suggestionCount) photos are ready."
        case .accessDenied:
            return "Allow Photos access in Settings to use this album."
        case .failed(let message):
            return message
        }
    }

    private var primaryActionTitle: String {
        switch model.collectionMode {
        case .samples where model.importedPhotos.isEmpty
            && !automaticAlbum.configuration.isConfigured:
            return purchases.isWallModeUnlocked ? "Choose an Album" : "Choose Photos"
        default:
            return isPreparingCurrentSource ? "Preparing Photos…" : "Start Frame"
        }
    }

    private var primaryActionIcon: String {
        if primaryActionTitle == "Choose an Album" { return "photo.on.rectangle.angled" }
        if primaryActionTitle == "Choose Photos" { return "photo.badge.plus" }
        return "play.fill"
    }

    private var primaryActionIsDisabled: Bool {
        if primaryActionTitle == "Choose an Album" || primaryActionTitle == "Choose Photos" {
            return false
        }
        return isPreparingCurrentSource || displayedSlides.isEmpty
    }

    private var secondaryActionTitle: String {
        switch model.collectionMode {
        case .automaticAlbum:
            return automaticAlbum.configuration.isConfigured ? "Change Album" : "Choose Photos"
        case .personal:
            if model.isImporting { return "Stop Adding" }
            if !model.canAddPhotos {
                return "\(ManualPhotoCollectionPolicy.maximumCandidateCount) Photos Added"
            }
            return "Add Photos"
        case .samples:
            if model.importedPhotos.isEmpty {
                return purchases.isWallModeUnlocked ? "Choose Photos" : "Start Sample Frame"
            }
            return "My Photos"
        }
    }

    private var isPreparingCurrentSource: Bool {
        if isInitialPersonalImport { return true }
        switch model.collectionMode {
        case .automaticAlbum:
            if automaticAlbum.canDisplay { return false }
            switch automaticAlbum.phase {
            case .loadingAlbums, .syncing, .curating: return true
            default: return !automaticAlbum.canDisplay
            }
        case .personal:
            return model.smartReel == nil && !model.importedPhotos.isEmpty
        case .samples:
            return false
        }
    }

    private var secondaryActionIsDisabled: Bool {
        model.collectionMode == .personal && !model.isImporting && !model.canAddPhotos
    }

    private var shouldShowImportStatus: Bool {
        switch model.importPhase {
        case .idle:
            return false
        case .importing, .cancelling:
            return model.smartReel == nil
        case .finished(let report):
            return report.wasCancelled
                || !report.failures.isEmpty
                || report.limitReachedCount > 0
        case .deletionFailed:
            return true
        }
    }

    private func primaryAction() {
        if primaryActionTitle == "Choose an Album" {
            chooseAlbum()
        } else if primaryActionTitle == "Choose Photos" {
            presentedSheet = .photoPicker
        } else {
            isFrameMode = true
        }
    }

    private func secondaryAction() {
        switch model.collectionMode {
        case .automaticAlbum:
            automaticAlbum.configuration.isConfigured
                ? chooseAlbum()
                : (presentedSheet = .photoPicker)
        case .personal:
            if model.isImporting {
                model.cancelImport()
            } else if model.canAddPhotos {
                presentedSheet = .photoPicker
            }
        case .samples:
            if model.importedPhotos.isEmpty {
                if purchases.isWallModeUnlocked {
                    presentedSheet = .photoPicker
                } else {
                    isFrameMode = true
                }
            } else {
                selectPhotoMode(.personal)
            }
        }
    }

    private func chooseAlbum() {
        guard purchases.isWallModeUnlocked else {
            presentedSheet = .wallModePaywall
            return
        }
        automaticAlbum.requestAccessAndLoadAlbums()
        presentedSheet = .albumPicker
    }

    private func replacePresentedSheet(with destination: SheetDestination) {
        presentedSheet = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            presentedSheet = destination
        }
    }

    private func synchronizeImportStatusPresentation(_ shouldShow: Bool) {
        guard shouldShow, !isFrameMode else {
            if presentedSheet == .importStatus {
                presentedSheet = nil
            }
            return
        }

        if presentedSheet == nil {
            presentedSheet = .importStatus
        } else if presentedSheet == .photoPicker {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                guard shouldShowImportStatus, !isFrameMode else { return }
                presentedSheet = .importStatus
            }
        }
    }

    private func selectPhotoMode(_ mode: PhotoCollectionMode) {
        model.collectionMode = mode
        preferredPhotoMode = mode.rawValue
    }

    private func restorePreferredPhotoMode() {
#if DEBUG
        if DebugScreenshotScenario.current != nil { return }
#endif
        if let preferred = PhotoCollectionMode(rawValue: preferredPhotoMode) {
            switch preferred {
            case .automaticAlbum where automaticAlbum.configuration.isConfigured:
                model.collectionMode = .automaticAlbum
                return
            case .personal where !model.importedPhotos.isEmpty:
                model.collectionMode = .personal
                return
            case .samples:
                model.collectionMode = .samples
                return
            default:
                break
            }
        }

        if automaticAlbum.configuration.isConfigured {
            model.collectionMode = .automaticAlbum
        } else if !model.importedPhotos.isEmpty {
            model.collectionMode = .personal
        } else {
            model.collectionMode = .samples
        }
    }

    private func automaticAlbumProgress(
        _ progress: ImportProgress,
        label: String
    ) -> some View {
        ProgressView(value: progress.fractionCompleted)
            .accessibilityLabel(label)
            .accessibilityValue("\(progress.completedCount) of \(progress.totalCount)")
    }

    private var activeLayoutPreference: FrameLayoutPreference {
        if initialPresentation == .mosaicFrame {
            return .mosaic
        }
        return .automatic
    }

    private var activeInterval: TimeInterval {
        FramePlaybackTiming.normalized(
            frameConfigurations.activeConfiguration?.interval
                ?? FramePlaybackTiming.defaultInterval
        )
    }

    private func saveCurrentPresentation(interval: TimeInterval) {
        frameConfigurations.saveCurrent(
            source: currentFrameSource,
            albumIdentifier: automaticAlbum.configuration.albumIdentifier,
            albumTitle: automaticAlbum.configuration.albumTitle,
            layoutPreference: .automatic,
            interval: interval
        )
    }

    private var currentFrameSource: FrameConfigurationSource {
        switch model.collectionMode {
        case .samples: return .samples
        case .personal: return .freeSmartReel
        case .automaticAlbum: return .automaticAlbum
        }
    }

    private func applyActiveFrameConfiguration() {
        guard let configuration = frameConfigurations.activeConfiguration else { return }
        switch configuration.source {
        case .samples:
            model.collectionMode = .samples
        case .freeSmartReel:
            model.collectionMode = model.importedPhotos.isEmpty ? .samples : .personal
        case .automaticAlbum:
            if let albumIdentifier = configuration.albumIdentifier,
               automaticAlbum.configuration.albumIdentifier != albumIdentifier {
                automaticAlbum.selectAlbum(
                    PhotoLibraryAlbum(
                        id: albumIdentifier,
                        title: configuration.albumTitle ?? "Saved Album",
                        photoCount: 0
                    )
                )
            }
            model.collectionMode = .automaticAlbum
        }
    }

    private func applyInitialPresentationIfNeeded() {
        guard !didApplyInitialPresentation else { return }
        didApplyInitialPresentation = true
        switch initialPresentation {
        case .frameMode, .mosaicFrame:
            isFrameMode = true
        case .wallModePaywallFeatures, .wallModePaywallPurchase:
            presentedSheet = .wallModePaywall
        case .wallModeSetup:
            presentedSheet = .frameSettings
        case .automaticAlbumReview:
            presentedSheet = .automaticAlbumReview
        case .freeReview:
            presentedSheet = .reviewSuggestions
        case nil:
            break
        }
    }
}

private extension View {
    @ViewBuilder
    func framePersistentSystemOverlaysHidden(_ hidden: Bool) -> some View {
        if #available(iOS 16.0, *) {
            persistentSystemOverlays(hidden ? .hidden : .automatic)
        } else {
            self
        }
    }
}

private extension Optional where Wrapped == RootInitialPresentation {
    var wallModeSetupSection: WallModeSetupInitialSection? {
        guard case .wallModeSetup(let section) = self else { return nil }
        return section
    }
}

private struct PhotosSheet: View {
    @ObservedObject var model: AppModel
    @ObservedObject var automaticAlbum: AutomaticAlbumController
    @ObservedObject var purchases: PurchaseController
    @Binding var currentPhotoMode: PhotoCollectionMode
    @Environment(\.presentationMode) private var presentationMode

    let choosePhotos: () -> Void
    let chooseAlbum: () -> Void
    let reviewPersonalPhotos: () -> Void
    let reviewAutomaticAlbum: () -> Void

    var body: some View {
        NavigationView {
            List {
                Section("Your Frame") {
                    if !model.importedPhotos.isEmpty {
                        sourceButton(
                            title: "My Selected Photos",
                            detail: "\(model.importedPhotos.count) selected on this device",
                            systemImage: "photo.stack",
                            mode: .personal
                        )
                        .accessibilityIdentifier("photo-source-personal")
                    }

                    if automaticAlbum.configuration.isConfigured {
                        sourceButton(
                            title: automaticAlbum.selectedAlbumTitle,
                            detail: "Updates from the album you chose",
                            systemImage: "rectangle.stack",
                            mode: .automaticAlbum
                        )
                        .accessibilityIdentifier("photo-source-automatic")
                    }

                    sourceButton(
                        title: "Sample Photos",
                        detail: "Bundled examples with no Photos access",
                        systemImage: "sparkles",
                        mode: .samples
                    )
                    .accessibilityIdentifier("photo-source-samples")
                }

                Section("Choose Photos") {
                    Button(action: choosePhotos) {
                        Label(
                            model.importedPhotos.isEmpty ? "Choose Photos" : "Add Photos",
                            systemImage: "photo.badge.plus"
                        )
                    }
                    .disabled(!model.canAddPhotos || model.isImporting)
                    .accessibilityIdentifier("choose-photos-action")

                    Text(
                        "\(model.importedPhotos.count) of \(ManualPhotoCollectionPolicy.maximumCandidateCount) photos selected"
                    )
                    .font(.footnote)
                    .foregroundColor(.secondary)

                    Button(action: chooseAlbum) {
                        Label(
                            automaticAlbum.configuration.isConfigured
                                ? "Change Album"
                                : "Choose an Album",
                            systemImage: purchases.isWallModeUnlocked
                                ? "photo.on.rectangle.angled"
                                : "lock.fill"
                        )
                    }
                    .accessibilityIdentifier("choose-album-action")

                    if !purchases.isWallModeUnlocked {
                        Text("Automatic album updates are included with FrameWink Lifetime.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                if canReviewCurrentSource {
                    Section {
                        Button("Review Photos", action: reviewCurrentSource)
                            .accessibilityIdentifier("review-photos-action")
                    }
                }
            }
            .navigationTitle("Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var canReviewCurrentSource: Bool {
        switch currentPhotoMode {
        case .personal:
            return model.smartReel != nil
        case .automaticAlbum:
            return automaticAlbum.smartReel != nil
        case .samples:
            return false
        }
    }

    private func reviewCurrentSource() {
        switch currentPhotoMode {
        case .personal:
            reviewPersonalPhotos()
        case .automaticAlbum:
            reviewAutomaticAlbum()
        case .samples:
            break
        }
    }

    private func sourceButton(
        title: String,
        detail: String,
        systemImage: String,
        mode: PhotoCollectionMode
    ) -> some View {
        Button {
            currentPhotoMode = mode
            presentationMode.wrappedValue.dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .foregroundColor(.primary)
                    Text(detail)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if currentPhotoMode == mode {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.accentColor)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .accessibilityAddTraits(currentPhotoMode == mode ? .isSelected : [])
    }
}

private struct PrivacyAndDataSheet: View {
    @ObservedObject var model: AppModel
    @ObservedObject var automaticAlbum: AutomaticAlbumController
    @Binding var currentPhotoMode: PhotoCollectionMode
    @Environment(\.presentationMode) private var presentationMode
    @State private var showDeleteImportedConfirmation = false
    @State private var showDeleteAlbumConfirmation = false
    @State private var showResetNeverShowConfirmation = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 18) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 54))
                        .foregroundColor(.accentColor)
                        .accessibilityHidden(true)

                    Text("Private by design")
                        .font(.largeTitle.bold())

                    Text("FrameWink has no server and never uploads your photos. Selection, preparation, and display happen on this device.")
                        .font(.title3)

                    privacyPoint(
                        icon: "photo.on.rectangle.angled",
                        title: "You choose what enters",
                        detail: "Free Smart Reel uses the private system picker. Paid automatic albums request Photos access only after you choose that feature, list albums so you can choose, then read photo content only from that album."
                    )

                    privacyPoint(
                        icon: "arrow.down.right.and.arrow.up.left",
                        title: "Display-sized local copies",
                        detail: "Picker imports and automatic-album cache items are downsampled before they are saved to keep storage and memory use bounded. Photo copies and derived analysis are excluded from device backup."
                    )

                    privacyPoint(
                        icon: "trash",
                        title: "Delete whenever you want",
                        detail: "Delete Imported Photos and Remove Downloaded Album Photos erase app-controlled copies and derived records without changing Apple Photos."
                    )
                    }
                    .padding(.vertical, 8)
                }

                Section("Data on This Device") {
                    if !model.importedPhotos.isEmpty {
                        Text(
                            "\(model.importedPhotos.count) selected photo copies are stored locally."
                        )
                        Button("Delete Imported Photos", role: .destructive) {
                            showDeleteImportedConfirmation = true
                        }
                        .accessibilityIdentifier("delete-imported-photos")
                    } else {
                        Text("No individually selected photo copies are stored.")
                            .foregroundColor(.secondary)
                    }

                    if automaticAlbum.configuration.isConfigured {
                        Button("Reset Hidden Photos") {
                            showResetNeverShowConfirmation = true
                        }

                        Button("Remove Downloaded Album Photos", role: .destructive) {
                            showDeleteAlbumConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle("Privacy & Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("Delete Imported Photos?", isPresented: $showDeleteImportedConfirmation) {
            Button("Delete All Imported Photos", role: .destructive) {
                model.deleteImportedPhotos()
                currentPhotoMode = .samples
            }
            .accessibilityIdentifier("confirm-delete-imported-photos")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every app-controlled photo copy and its derived records. Your Apple Photos library is never changed.")
        }
        .alert("Remove Downloaded Album Photos?", isPresented: $showDeleteAlbumConfirmation) {
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
        .alert("Reset Hidden Photos?", isPresented: $showResetNeverShowConfirmation) {
            Button("Reset") {
                automaticAlbum.resetNeverShowChoices()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Photos you previously chose to never show may appear again. Apple Photos is unchanged.")
        }
    }

    private func privacyPoint(
        icon: String,
        title: LocalizedStringKey,
        detail: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 34)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .foregroundColor(.secondary)
            }
        }
    }
}
