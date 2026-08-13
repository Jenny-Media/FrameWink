import Combine
import ImageIO
import SwiftUI
import UIKit

struct SampleSlideshowView: View {
    let slides: [DisplaySlide]
    let loadImportedImage: (ImportedPhoto) async -> UIImage?
    let loadAutomaticAlbumImage: (ImportedPhoto) async -> UIImage?
    let automaticAlbumPhotoDidDisplay: (ImportedPhoto) -> Void
    let preferredLayoutPreference: FrameLayoutPreference
    let preferredInterval: TimeInterval
    let availableLayoutPreferences: [FrameLayoutPreference]
    let presentationDidChange: (FrameLayoutPreference, TimeInterval) -> Void
    @Binding var isFrameMode: Bool
    let wallVisualState: WallVisualState
    let refreshWallSchedule: (Date) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var playback = FramePlaybackCoordinator()
    @State private var layoutPreference: FrameLayoutPreference = .automatic
    @State private var controlsVisible = true
    @State private var hintVisible = false
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var hideHintTask: Task<Void, Never>?
    @StateObject private var imageCache = DisplayImageCache()

    private let layoutChooser = FrameLayoutChooser()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let availableIntervals: [TimeInterval] = [5, 10, 30, 60]

    var body: some View {
        GeometryReader { proxy in
            let viewport = PixelSize(
                width: Int(proxy.size.width.rounded()),
                height: Int(proxy.size.height.rounded())
            )
            let pages = layoutChooser.pages(
                for: slides.map(\.frameLayoutItem),
                viewport: viewport,
                preference: layoutPreference,
                allowsAutomaticMosaic: availableLayoutPreferences.contains(.mosaic)
            )
            let layoutSignature = pages.map(\.id).joined(separator: "|")
            let slidesByID = Dictionary(uniqueKeysWithValues: slides.map { ($0.id, $0) })

            ZStack {
                Color.black

                if let page = activePage(in: pages) {
                    framePage(page, slidesByID: slidesByID)
                        .id(page.id)
                        .transition(
                            reduceMotion || playback.isInteractingWithResize
                                ? .identity
                                : .opacity
                        )

                    if !isFrameMode,
                       let slide = slidesByID[page.placements.first?.photoID ?? ""] {
                        caption(for: slide)
                            .id(slide.id)
                            .transition(.identity)
                            .transaction { transaction in
                                transaction.animation = nil
                            }
                    }
                }

                wallScheduleOverlay

                if isFrameMode {
                    interactionLayer

                    if hintVisible, wallVisualState != .blackout {
                        controlsHint
                            .transition(reduceMotion ? .identity : .opacity)
                    }

                    if controlsVisible {
                        frameControls(isCompact: proxy.size.width < 600)
                            .transition(reduceMotion ? .identity : .opacity)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onAppear {
                applyPreferredPresentation()
                synchronizePages(pages, signature: layoutSignature)
                if isFrameMode {
                    showInitialGuidance()
                }
            }
            .onChange(of: layoutSignature) { newSignature in
                synchronizePages(pages, signature: newSignature)
            }
            .onChange(of: playback.currentPageIndex) { _ in
                if let page = playback.pageChangeRequiringHistory(in: pages),
                   isFrameMode {
                    recordAutomaticAlbumPhotos(in: page, slidesByID: slidesByID)
                }
            }
            .onChange(of: isFrameMode) { active in
                guard active, let page = activePage(in: pages) else { return }
                recordAutomaticAlbumPhotos(in: page, slidesByID: slidesByID)
            }
            .onChange(of: preferredLayoutPreference) { _ in
                applyPreferredPresentation()
            }
            .onChange(of: preferredInterval) { _ in
                applyPreferredPresentation()
            }
            .onChange(of: availableLayoutPreferences) { preferences in
                if !preferences.contains(layoutPreference) {
                    layoutPreference = .automatic
                }
            }
            .task(id: nextPagePreloadID(in: pages, slidesByID: slidesByID)) {
                await preloadNextPage(in: pages, slidesByID: slidesByID)
            }
        }
        .background(Color.black)
        .clipped()
        .onFrameInteractiveResizeChange { isResizing in
            playback.setInteractiveResize(isResizing, at: Date())
        }
        .onReceive(timer) { date in
            refreshWallSchedule(date)
            var updatedPlayback = playback
            guard updatedPlayback.tick(at: date) else { return }
            if reduceMotion {
                playback = updatedPlayback
            } else {
                withAnimation(.easeInOut(duration: 0.65)) {
                    playback = updatedPlayback
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.didReceiveMemoryWarningNotification
            )
        ) { _ in
            imageCache.removeAllImages()
        }
        .onChange(of: isFrameMode) { isActive in
            if isActive {
                showInitialGuidance()
            } else {
                hideControlsTask?.cancel()
                hideHintTask?.cancel()
                hintVisible = false
            }
        }
        .onChange(of: voiceOverEnabled) { isEnabled in
            if isEnabled {
                hideControlsTask?.cancel()
                hideHintTask?.cancel()
                setHintVisible(false)
                setControlsVisible(true)
            } else {
                scheduleControlsToRecede()
            }
        }
        .onDisappear {
            hideControlsTask?.cancel()
            hideHintTask?.cancel()
        }
    }

    private func activePage(in pages: [FramePage]) -> FramePage? {
        playback.activePage(in: pages)
    }

    private func framePage(
        _ page: FramePage,
        slidesByID: [String: DisplaySlide]
    ) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                ForEach(page.placements) { placement in
                    if let slide = slidesByID[placement.photoID] {
                        FramePhotoView(
                            slide: slide,
                            placement: placement,
                            initialImage: imageCache.cachedImage(
                                forKey: slide.imageCacheKey
                            ),
                            loadImage: cachedImage,
                            motionEnabled: isFrameMode
                                && playback.isPlaying
                                && page.placements.count == 1
                                && FrameMotionSafety.canZoom(
                                    placement: placement,
                                    importantRects: slide.importantRects,
                                    maximumScale: 1.025
                                )
                                && !reduceMotion
                                && !playback.isInteractingWithResize,
                            motionDuration: max(playback.interval * 1.6, 11)
                        )
                        .frame(
                            width: proxy.size.width * CGFloat(placement.screenFrame.width),
                            height: proxy.size.height * CGFloat(placement.screenFrame.height)
                        )
                        .position(
                            x: proxy.size.width * CGFloat(placement.screenFrame.midX),
                            y: proxy.size.height * CGFloat(placement.screenFrame.midY)
                        )
                    }
                }
            }
        }
    }

    private func nextPagePreloadID(
        in pages: [FramePage],
        slidesByID: [String: DisplaySlide]
    ) -> String? {
        guard pages.count > 1 else { return nil }
        let page = pages[(playback.currentPageIndex + 1) % pages.count]
        let imageRevisions = page.placements.compactMap { placement in
            slidesByID[placement.photoID]?.imageCacheKey
        }
        return ([page.id] + imageRevisions).joined(separator: "|")
    }

    private func preloadNextPage(
        in pages: [FramePage],
        slidesByID: [String: DisplaySlide]
    ) async {
        guard pages.count > 1 else { return }
        let page = pages[(playback.currentPageIndex + 1) % pages.count]
        for placement in page.placements {
            guard !Task.isCancelled,
                  let slide = slidesByID[placement.photoID] else {
                return
            }
            _ = await cachedImage(for: slide)
        }
    }

    private func cachedImage(for slide: DisplaySlide) async -> UIImage? {
        await imageCache.image(forKey: slide.imageCacheKey) {
            switch slide.source {
            case .bundled(let resourceName):
                return await BundledSampleImageLoader.imageAsync(named: resourceName)
            case .imported(let photo):
                return await loadImportedImage(photo)
            case .automaticAlbum(let photo):
                return await loadAutomaticAlbumImage(photo)
            }
        }
    }

    private func recordAutomaticAlbumPhotos(
        in page: FramePage,
        slidesByID: [String: DisplaySlide]
    ) {
        for placement in page.placements {
            guard let slide = slidesByID[placement.photoID],
                  case .automaticAlbum(let photo) = slide.source else {
                continue
            }
            automaticAlbumPhotoDidDisplay(photo)
        }
    }

    private func caption(for slide: DisplaySlide) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(slide.title)
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                .foregroundColor(.white)
                .shadow(radius: 8)

            Text(slide.caption)
                .font(.headline)
                .foregroundColor(.white.opacity(0.84))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(.horizontal, 34)
        .padding(.bottom, isFrameMode ? 125 : 250)
        .allowsHitTesting(false)
    }

    private var interactionLayer: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                if controlsVisible {
                    setControlsVisible(false)
                    hideControlsTask?.cancel()
                } else {
                    revealControls()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else {
                            return
                        }
                        if value.translation.width < 0 {
                            showNextPage()
                        } else {
                            showPreviousPage()
                        }
                        if controlsVisible {
                            scheduleControlsToRecede()
                        }
                    }
            )
            .accessibilityHidden(true)
    }

    private func frameControls(isCompact: Bool) -> some View {
        VStack {
            HStack {
                Button {
                    isFrameMode = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(.black.opacity(0.55), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close frame")
                .accessibilityIdentifier("frame-close-control")

                Spacer()
            }

            Spacer()

            HStack(spacing: isCompact ? 12 : 18) {
                Button(action: showPreviousPage) {
                    Image(systemName: "backward.fill")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Previous photo")

                Button {
                    playback.togglePlayback(at: Date())
                    if playback.isPlaying {
                        scheduleControlsToRecede()
                    } else {
                        hideControlsTask?.cancel()
                    }
                } label: {
                    Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(
                    playback.isPlaying ? "Pause slideshow" : "Resume slideshow"
                )
                .accessibilityIdentifier("frame-playback-control")

                Button(action: showNextPage) {
                    Image(systemName: "forward.fill")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Next photo")

                Divider()
                    .frame(height: 26)
                    .overlay(Color.white.opacity(0.35))

                Menu {
                    Menu("Display Style") {
                        ForEach(availableLayoutPreferences) { preference in
                            Button {
                                layoutPreference = preference
                                presentationDidChange(preference, playback.interval)
                                revealControls()
                            } label: {
                                if layoutPreference == preference {
                                    Label(preference.title, systemImage: "checkmark")
                                } else {
                                    Text(preference.title)
                                }
                            }
                        }
                    }

                    Menu("Slideshow Speed") {
                        ForEach(availableIntervals, id: \.self) { interval in
                            Button {
                                playback.setInterval(interval, at: Date())
                                presentationDidChange(layoutPreference, interval)
                                revealControls()
                            } label: {
                                if playback.interval == interval {
                                    Label(intervalTitle(interval), systemImage: "checkmark")
                                } else {
                                    Text(intervalTitle(interval))
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("More playback options")
            }
            .font(.title3.weight(.semibold))
            .foregroundColor(.white)
            .buttonStyle(.plain)
            .padding(.horizontal, isCompact ? 18 : 24)
            .padding(.vertical, isCompact ? 12 : 16)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.28), radius: 16, y: 7)
            .padding(.bottom, 28)
        }
        .padding(.horizontal, 26)
        .padding(.top, 28)
    }

    private var controlsHint: some View {
        Text("Tap for controls · Swipe to navigate")
            .font(.footnote.weight(.semibold))
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
            .background(.black.opacity(0.48), in: Capsule())
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, controlsVisible ? 104 : 28)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var wallScheduleOverlay: some View {
        switch wallVisualState {
        case .normal:
            EmptyView()
        case .dimmed(let opacity):
            Color.black
                .opacity(opacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        case .blackout:
            Color.black
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityLabel("Scheduled frame blackout")
        }
    }

    private func showNextPage() {
        performPageChange {
            playback.next(at: Date())
        }
    }

    private func showPreviousPage() {
        performPageChange {
            playback.previous(at: Date())
        }
    }

    private func performPageChange(_ change: () -> Void) {
        if reduceMotion {
            change()
        } else {
            withAnimation(.easeInOut(duration: 0.4), change)
        }
        scheduleControlsToRecede()
    }

    private func synchronizePages(_ pages: [FramePage], signature: String) {
        playback.synchronizePages(pages, signature: signature)
    }

    private func applyPreferredPresentation() {
        layoutPreference = availableLayoutPreferences.contains(preferredLayoutPreference)
            ? preferredLayoutPreference
            : .automatic
        playback.setInterval(preferredInterval, at: Date())
    }

    private func revealControls() {
        hideHintTask?.cancel()
        hintVisible = false
        setControlsVisible(true)
        scheduleControlsToRecede()
    }

    private func showInitialGuidance() {
        setControlsVisible(true)
        setHintVisible(!voiceOverEnabled)
        scheduleHintToRecede()
        scheduleControlsToRecede()
    }

    private func setControlsVisible(_ visible: Bool) {
        if reduceMotion {
            controlsVisible = visible
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                controlsVisible = visible
            }
        }
    }

    private func setHintVisible(_ visible: Bool) {
        if reduceMotion {
            hintVisible = visible
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                hintVisible = visible
            }
        }
    }

    private func scheduleHintToRecede() {
        hideHintTask?.cancel()
        guard isFrameMode, hintVisible, !voiceOverEnabled else { return }
        hideHintTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                setHintVisible(false)
            }
        }
    }

    private func scheduleControlsToRecede() {
        hideControlsTask?.cancel()
        guard FrameOverlayVisibilityPolicy.shouldAutomaticallyHideControls(
            isFrameMode: isFrameMode,
            isPlaying: playback.isPlaying,
            voiceOverEnabled: voiceOverEnabled
        ) else { return }

        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                setControlsVisible(false)
            }
        }
    }

    private func intervalTitle(_ interval: TimeInterval) -> String {
        "\(Int(interval)) sec"
    }
}

private extension DisplaySlide {
    var imageCacheKey: String {
        switch source {
        case .bundled(let resourceName):
            return "bundled:" + resourceName
        case .imported(let photo):
            return "imported:" + photo.filename
        case .automaticAlbum(let photo):
            return "automatic:" + photo.filename
        }
    }

    var frameLayoutItem: FrameLayoutItem {
        let pixelSize: PixelSize
        let creationDate: Date?
        switch source {
        case .bundled:
            pixelSize = PixelSize(width: 1_536, height: 1_024)
            creationDate = nil
        case .imported(let photo), .automaticAlbum(let photo):
            pixelSize = PixelSize(
                width: photo.pixelWidth,
                height: photo.pixelHeight
            )
            creationDate = photo.creationDate
        }

        return FrameLayoutItem(
            id: id,
            pixelSize: pixelSize,
            importantRects: importantRects,
            creationDate: creationDate
        )
    }
}

private struct FramePhotoView: View {
    let slide: DisplaySlide
    let placement: FrameLayoutPlacement
    let initialImage: UIImage?
    let loadImage: (DisplaySlide) async -> UIImage?
    let motionEnabled: Bool
    let motionDuration: TimeInterval

    @State private var image: UIImage?
    @State private var motionExpanded = false
    @State private var motionTask: Task<Void, Never>?

    init(
        slide: DisplaySlide,
        placement: FrameLayoutPlacement,
        initialImage: UIImage?,
        loadImage: @escaping (DisplaySlide) async -> UIImage?,
        motionEnabled: Bool,
        motionDuration: TimeInterval
    ) {
        self.slide = slide
        self.placement = placement
        self.initialImage = initialImage
        self.loadImage = loadImage
        self.motionEnabled = motionEnabled
        self.motionDuration = motionDuration
        _image = State(initialValue: initialImage)
    }

    var body: some View {
        ZStack {
            Color.black

            if let image = image ?? initialImage {
                photo(image)
                    .scaleEffect(motionEnabled && motionExpanded ? 1.025 : 1)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .accessibilityLabel("Loading photo")
            }
        }
        .clipped()
        .task(id: slide.imageCacheKey) {
            image = await loadImage(slide)
        }
        .onAppear(perform: updateMotion)
        .onChange(of: motionEnabled) { _ in
            updateMotion()
        }
        .onChange(of: motionDuration) { _ in
            updateMotion()
        }
        .onDisappear {
            motionTask?.cancel()
        }
        .accessibilityIdentifier("frame-photo-" + slide.id)
        .accessibilityLabel(slide.accessibilityLabel)
    }

    @ViewBuilder
    private func photo(_ image: UIImage) -> some View {
        switch placement.contentMode {
        case .fit:
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .crop:
            croppedImage(image)
        }
    }

    private func updateMotion() {
        motionTask?.cancel()
        guard motionEnabled else {
            withAnimation(nil) {
                motionExpanded = false
            }
            return
        }

        motionTask = Task { @MainActor in
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: motionDuration)) {
                    motionExpanded.toggle()
                }
                try? await Task.sleep(
                    nanoseconds: UInt64(motionDuration * 1_000_000_000)
                )
            }
        }
    }

    private func croppedImage(_ image: UIImage) -> some View {
        GeometryReader { proxy in
            let crop = placement.sourceCrop
            let fullWidth = proxy.size.width / CGFloat(max(crop.width, 0.000_001))
            let fullHeight = proxy.size.height / CGFloat(max(crop.height, 0.000_001))

            Image(uiImage: image)
                .resizable()
                .frame(width: fullWidth, height: fullHeight)
                .offset(
                    x: -fullWidth * CGFloat(crop.x),
                    y: -fullHeight * CGFloat(crop.y)
                )
        }
        .clipped()
    }
}

private extension View {
    @ViewBuilder
    func onFrameInteractiveResizeChange(
        _ action: @escaping (Bool) -> Void
    ) -> some View {
        if #available(iOS 26.0, *) {
            onInteractiveResizeChange(action)
        } else {
            self
        }
    }
}

enum BundledSampleImageLoader {
    static func image(named resourceName: String, bundle: Bundle = .main) -> UIImage? {
        guard let url = bundle.url(forResource: resourceName, withExtension: "png") else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }

    static func imageAsync(
        named resourceName: String,
        bundle: Bundle = .main
    ) async -> UIImage? {
        guard let url = bundle.url(forResource: resourceName, withExtension: "png") else {
            return nil
        }
        return await Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithURL(
                url as CFURL,
                [kCGImageSourceShouldCache: false] as CFDictionary
            ),
                  let image = CGImageSourceCreateImageAtIndex(
                      source,
                      0,
                      [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
                  ) else {
                return nil
            }
            return UIImage(cgImage: image)
        }.value
    }
}

#if DEBUG
struct SampleSlideshowView_Previews: PreviewProvider {
    static var previews: some View {
        SampleSlideshowView(
            slides: [
                DisplaySlide(
                    id: "preview",
                    title: "Keep the good days close",
                    caption: "Bundled example · no Photos access needed",
                    accessibilityLabel: "Sample photo",
                    source: .bundled(resourceName: "sample-lakeside")
                )
            ],
            loadImportedImage: { _ in nil },
            loadAutomaticAlbumImage: { _ in nil },
            automaticAlbumPhotoDidDisplay: { _ in },
            preferredLayoutPreference: .automatic,
            preferredInterval: 7,
            availableLayoutPreferences: [.automatic, .fit, .fill],
            presentationDidChange: { _, _ in },
            isFrameMode: .constant(false),
            wallVisualState: .normal,
            refreshWallSchedule: { _ in }
        )
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
#endif
