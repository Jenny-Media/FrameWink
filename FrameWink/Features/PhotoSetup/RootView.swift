import SwiftUI

private enum SheetDestination: String, Identifiable {
    case photoPicker
    case privacy
    case reviewSuggestions
    case automaticAlbumReview
    case wallModeSetup
    case wallModePaywall

    var id: String { rawValue }
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
                    availableLayoutPreferences: frameConfigurations.availableLayoutPreferences,
                    presentationDidChange: frameConfigurations.updateActive,
                    isFrameMode: $isFrameMode,
                    wallVisualState: wallMode.visualState,
                    refreshWallSchedule: wallMode.refresh
                )
                .ignoresSafeArea()

                if !isFrameMode {
                    chrome
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
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(item: $presentedSheet) { destination in
            switch destination {
            case .photoPicker:
                PhotoPickerView(selectionLimit: 100) { items in
                    model.importSelectedItems(items)
                }
                .ignoresSafeArea()
            case .privacy:
                PrivacySheet()
            case .reviewSuggestions:
                ReviewSuggestionsView(model: model)
            case .automaticAlbumReview:
                AutomaticAlbumReviewView(controller: automaticAlbum)
            case .wallModeSetup:
                WallModeSetupView(
                    wallMode: wallMode,
                    automaticAlbum: automaticAlbum,
                    frameConfigurations: frameConfigurations
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
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every app-controlled photo copy and its derived records. Your Apple Photos library is never changed.")
        }
        .onChange(of: model.curationPhase) { phase in
            if case .ready = phase {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    guard presentedSheet == nil,
                          case .ready = model.curationPhase else {
                        return
                    }
                    presentedSheet = .reviewSuggestions
                }
            }
        }
        .onChange(of: isFrameMode) { isActive in
            wallMode.setFrameModeActive(isActive)
        }
        .onChange(of: automaticAlbum.canDisplay) { canDisplay in
            if canDisplay,
               frameConfigurations.activeConfiguration?.source == .automaticAlbum {
                model.collectionMode = .automaticAlbum
            } else if !canDisplay, model.collectionMode == .automaticAlbum {
                model.collectionMode = model.importedPhotos.isEmpty ? .samples : .personal
                isFrameMode = false
            }
        }
        .onChange(of: frameConfigurations.activeConfiguration) { _ in
            applyActiveFrameConfiguration()
        }
        .onAppear {
            wallMode.setFrameModeActive(isFrameMode)
            applyActiveFrameConfiguration()
            applyInitialPresentationIfNeeded()
        }
        .onDisappear {
            wallMode.restoreOwnedDisplayState()
        }
    }

    private var chrome: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                sampleBadge

                Spacer()

                if availableCollectionModes.count > 1 {
                    Picker("Displayed photos", selection: $model.collectionMode) {
                        ForEach(availableCollectionModes) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 280)
                    .padding(6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 26)
            .padding(.top, 18)

            Spacer()

            setupCard
                .padding(.horizontal, 26)
                .padding(.bottom, 18)
        }
    }

    @ViewBuilder
    private var sampleBadge: some View {
        if model.collectionMode == .samples {
            Label("SAMPLE PHOTOS", systemImage: "sparkles")
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.black.opacity(0.52), in: Capsule())
                .accessibilityLabel("Bundled sample photos")
        }
    }

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 7) {
                Text(setupTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)

                if model.collectionMode == .automaticAlbum {
                    Text(automaticAlbumStatus)
                        .foregroundColor(.secondary)

                    if case .syncing(let progress) = automaticAlbum.phase {
                        automaticAlbumProgress(progress, label: "Automatic album sync progress")
                    } else if case .curating(let progress) = automaticAlbum.phase {
                        automaticAlbumProgress(progress, label: "Automatic album curation progress")
                    }
                } else if model.importedPhotos.isEmpty {
                    Text("Choose up to 100 photos. FrameWink keeps only display-sized copies on this iPad.")
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

            VStack(alignment: .trailing, spacing: 10) {
                HStack {
                    Button("Privacy") {
                        presentedSheet = .privacy
                    }
                    .buttonStyle(.bordered)

                    Button(purchases.isWallModeUnlocked ? "Wall Mode Setup" : "Unlock Wall Mode") {
                        presentedSheet = purchases.isWallModeUnlocked
                            ? .wallModeSetup
                            : .wallModePaywall
                    }
                    .buttonStyle(.bordered)
                    .accessibilityHint(
                        purchases.isWallModeUnlocked
                            ? "Opens Wall Mode commissioning and schedule settings"
                            : "Shows the one-time Wall Mode purchase"
                    )

                    Button(model.importedPhotos.isEmpty ? "Choose My Photos" : "Add Photos") {
                        presentedSheet = .photoPicker
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityHint("Opens the system photo picker with a 100-photo limit")
                }

                Button {
                    isFrameMode = true
                } label: {
                    Label("Play Full Screen", systemImage: "play.fill")
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Starts the full-screen photo frame with playback controls")
                .disabled(
                    displayedSlides.isEmpty
                        || (model.collectionMode == .personal
                            && !model.importedPhotos.isEmpty
                            && model.smartReel == nil)
                )

                if model.collectionMode == .automaticAlbum {
                    HStack {
                        Button("Review Automatic Suggestions") {
                            presentedSheet = .automaticAlbumReview
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(automaticAlbum.smartReel == nil)

                        Button("Refresh Album") {
                            automaticAlbum.refresh()
                        }
                        .buttonStyle(.bordered)
                    }
                } else if !model.importedPhotos.isEmpty {
                    HStack {
                        Button("Review Suggestions") {
                            presentedSheet = .reviewSuggestions
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.smartReel == nil)

                        if model.isCurating {
                            Button("Stop Curating", role: .cancel) {
                                model.cancelCuration()
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button("Refresh Smart Reel") {
                                model.refreshSmartReel()
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    Button("Delete Imported Photos", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .font(.footnote.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(22)
        .frame(maxWidth: 860)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 20, y: 8)
        .accessibilityElement(children: .contain)
    }

    private var curationStatus: String {
        switch model.curationPhase {
        case .idle:
            return "\(model.importedPhotos.count) imported photos are ready offline."
        case .analyzing(let progress):
            return "Curating \(progress.completedCount) of \(progress.totalCount) photos on this iPad."
        case .ready(let count):
            return "\(count) Smart Reel suggestions are ready to review."
        case .cancelled:
            return "Curation stopped. Saved analysis will be reused when you resume."
        case .failed:
            return "Smart Reel needs another try; your imported photos are still available."
        }
    }

    private var availableCollectionModes: [PhotoCollectionMode] {
        var modes: [PhotoCollectionMode] = [.samples]
        if !model.importedPhotos.isEmpty {
            modes.append(.personal)
        }
        if automaticAlbum.canDisplay {
            modes.append(.automaticAlbum)
        }
        return modes
    }

    private var displayedSlides: [DisplaySlide] {
        if model.collectionMode == .automaticAlbum {
            return automaticAlbum.slides
        }
        return model.slides
    }

    private var setupTitle: String {
        if model.collectionMode == .automaticAlbum {
            return automaticAlbum.selectedAlbumTitle
        }
        return model.importedPhotos.isEmpty ? "Make it yours" : "Your private reel"
    }

    private var automaticAlbumStatus: String {
        switch automaticAlbum.phase {
        case .idle:
            return "Choose and refresh an album from Wall Mode Setup."
        case .loadingAlbums:
            return "Loading the albums you authorized…"
        case .syncing(let progress):
            return "Preparing \(progress.completedCount) of \(progress.totalCount) album photos on this iPad."
        case .curating(let progress):
            return "Curating \(progress.completedCount) of \(progress.totalCount) cached photos."
        case .ready(let photoCount, let suggestionCount):
            return "\(suggestionCount) suggestions from \(photoCount) cached album photos are ready offline."
        case .accessDenied:
            return "Album access is unavailable. Free Smart Reel is unchanged."
        case .failed(let message):
            return message
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
        frameConfigurations.activeConfiguration?.layoutPreference ?? .automatic
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
            model.collectionMode = automaticAlbum.canDisplay ? .automaticAlbum : .samples
        }
    }

    private func applyInitialPresentationIfNeeded() {
        guard !didApplyInitialPresentation else { return }
        didApplyInitialPresentation = true
        switch initialPresentation {
        case .frameMode:
            isFrameMode = true
        case .wallModePaywallFeatures, .wallModePaywallPurchase:
            presentedSheet = .wallModePaywall
        case .wallModeSetup:
            presentedSheet = .wallModeSetup
        case nil:
            break
        }
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
                        detail: "Picker imports and automatic-album cache items are downsampled before they are saved to keep storage and memory use bounded."
                    )

                    privacyPoint(
                        icon: "trash",
                        title: "Delete whenever you want",
                        detail: "Delete Imported Photos and Delete Automatic Album Cache remove app-controlled copies and derived records without changing Apple Photos."
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
