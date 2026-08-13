import SwiftUI

private enum SheetDestination: String, Identifiable {
    case photoPicker
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
    @State private var showDeleteConfirmation = false
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
                        availableLayoutPreferences: availableLayoutPreferences,
                        presentationDidChange: frameConfigurations.updateActive,
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

                    if model.importPhase != .idle && !isFrameMode {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                            .transition(.opacity)

                        ImportStatusCard(
                            phase: model.importPhase,
                            canRetry: model.canRetryImport,
                            cancel: model.cancelImport,
                            retry: model.retryImport,
                            dismiss: model.dismissImportStatus
                        )
                        .transition(.scale.combined(with: .opacity))
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
            case .photoPicker:
                PhotoPickerView(selectionLimit: 100) { items in
                    model.importSelectedItems(items)
                }
                .ignoresSafeArea()
            case .albumPicker:
                AlbumPickerView(controller: automaticAlbum) { _ in
                    selectPhotoMode(.automaticAlbum)
                }
            case .privacy:
                PrivacySheet()
            case .reviewSuggestions:
                ReviewSuggestionsView(model: model)
            case .automaticAlbumReview:
                AutomaticAlbumReviewView(controller: automaticAlbum)
            case .frameSettings:
                WallModeSetupView(
                    wallMode: wallMode,
                    automaticAlbum: automaticAlbum,
                    frameConfigurations: frameConfigurations,
                    currentPhotoMode: $model.collectionMode,
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
        .alert("Delete Imported Photos?", isPresented: $showDeleteConfirmation) {
            Button("Delete All Imported Photos", role: .destructive) {
                model.deleteImportedPhotos()
                selectPhotoMode(.samples)
            }
            .accessibilityIdentifier("confirm-delete-imported-photos")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every app-controlled photo copy and its derived records. Your Apple Photos library is never changed.")
        }
        .onChange(of: isFrameMode) { isActive in
            wallMode.setFrameModeActive(isActive)
#if DEBUG
            PhysicalAcceptanceRecorder.shared.recordStateChange()
#endif
        }
        .onChange(of: model.collectionMode) { mode in
            preferredPhotoMode = mode.rawValue
        }
        .onChange(of: frameConfigurations.activeConfiguration) { _ in
            applyActiveFrameConfiguration()
        }
        .onAppear {
            wallMode.setFrameModeActive(isFrameMode)
            applyActiveFrameConfiguration()
            if initialPresentation == nil {
                restorePreferredPhotoMode()
            }
            applyInitialPresentationIfNeeded()
        }
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
            Section("Photos") {
                if automaticAlbum.canDisplay {
                    Button(automaticAlbum.selectedAlbumTitle) {
                        selectPhotoMode(.automaticAlbum)
                    }
                }
                if !model.importedPhotos.isEmpty {
                    Button("My Selected Photos") {
                        selectPhotoMode(.personal)
                    }
                }
                Button("Sample Photos") {
                    selectPhotoMode(.samples)
                }
                Button("Choose an Album…") {
                    chooseAlbum()
                }
                Button(model.importedPhotos.isEmpty ? "Choose Individual Photos…" : "Add Individual Photos…") {
                    presentedSheet = .photoPicker
                }
            }

            if model.collectionMode == .automaticAlbum,
               automaticAlbum.smartReel != nil {
                Button("Review Photos") {
                    presentedSheet = .automaticAlbumReview
                }
            } else if model.collectionMode == .personal,
                      model.smartReel != nil {
                Button("Review Photos") {
                    presentedSheet = .reviewSuggestions
                }
            }

            Divider()

            Button(purchases.isWallModeUnlocked ? "Frame Settings" : "More Frame Features") {
                presentedSheet = purchases.isWallModeUnlocked
                    ? .frameSettings
                    : .wallModePaywall
            }
            Button("Privacy") {
                presentedSheet = .privacy
            }

            if !model.importedPhotos.isEmpty {
                Divider()
                Button("Delete Imported Photos", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .accessibilityIdentifier("delete-imported-photos")
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

                Text("Preparing \(setupTitle) on this iPad")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.86))
            }
            .padding(.bottom, 110)
        }
        .allowsHitTesting(false)
    }

    private var curationStatus: String {
        switch model.curationPhase {
        case .idle:
            return "\(model.importedPhotos.count) photos are ready."
        case .analyzing(let progress):
            return "Finding your best photos — \(progress.completedCount) of \(progress.totalCount)…"
        case .ready(let count):
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
            return "Preparing \(progress.completedCount) of \(progress.totalCount) photos…"
        case .curating(let progress):
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
            presentedSheet = .photoPicker
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
        return frameConfigurations.activeConfiguration?.layoutPreference ?? .automatic
    }

    private var availableLayoutPreferences: [FrameLayoutPreference] {
        initialPresentation == .mosaicFrame
            ? FrameLayoutPreference.allCases
            : frameConfigurations.availableLayoutPreferences
    }

    private var activeInterval: TimeInterval {
        frameConfigurations.activeConfiguration?.interval ?? 7
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

private struct PrivacySheet: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 54))
                        .foregroundColor(.accentColor)
                        .accessibilityHidden(true)

                    Text("Private by design")
                        .font(.largeTitle.bold())

                    Text("FrameWink has no server and never uploads your photos. Selection, preparation, and display happen on this iPad.")
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
                .frame(maxWidth: 640, alignment: .leading)
                .padding(32)
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
