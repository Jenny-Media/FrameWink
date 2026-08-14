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
    let allowsAutomaticMosaic: Bool
    let presentationDidChange: (TimeInterval) -> Void
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
    @State private var pageTransitionDirection: FramePageTransitionDirection = .dissolve
    @State private var isShowingFrameControls = false
    @State private var sharePreparationID: String?
    @State private var sharePreparationCount = 0
    @State private var shareTask: Task<Void, Never>?
    @State private var sharedPhotos: SharedFramePhotos?
    @GestureState private var interactiveDragOffset: CGFloat = 0
    @StateObject private var imageCache = DisplayImageCache()

    private let layoutChooser = FrameLayoutChooser()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
                allowsAutomaticMosaic: allowsAutomaticMosaic
            )
            let layoutSignature = pages.map(\.id).joined(separator: "|")
            let slidesByID = Dictionary(uniqueKeysWithValues: slides.map { ($0.id, $0) })

            ZStack {
                Color.black

                if let page = activePage(in: pages) {
                    framePage(page, slidesByID: slidesByID)
                        .id(page.id)
                        .offset(
                            x: reduceMotion || playback.isInteractingWithResize
                                ? 0
                                : interactiveDragOffset
                        )
                        .transition(
                            reduceMotion || playback.isInteractingWithResize
                                ? .identity
                                : pageTransitionDirection.transition
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
                    if let page = activePage(in: pages) {
                        interactionLayer(
                            page: page,
                            pages: pages,
                            signature: layoutSignature,
                            slidesByID: slidesByID
                        )
                    }

                    if sharePreparationID != nil {
                        ProgressView(
                            sharePreparationCount > 1
                                ? "Preparing photos…"
                                : "Preparing photo…"
                        )
                            .tint(.white)
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(.black.opacity(0.62), in: Capsule())
                            .allowsHitTesting(false)
                            .accessibilityIdentifier("share-photo-preparing")
                    }

                    if hintVisible, wallVisualState != .blackout {
                        controlsHint
                            .transition(reduceMotion ? .identity : .opacity)
                    }

                    if controlsVisible {
                        frameControls(
                            isCompact: proxy.size.width < 600,
                            pages: pages,
                            signature: layoutSignature,
                            slidesByID: slidesByID
                        )
                            .transition(reduceMotion ? .identity : .opacity)

                        if !isShowingFrameControls {
                            quickExitControl
                                .transition(reduceMotion ? .identity : .opacity)
                        }
                    }
                } else if pages.count > 1,
                          let page = activePage(in: pages) {
                    previewNavigationLayer(
                        page: page,
                        pages: pages,
                        signature: layoutSignature,
                        slidesByID: slidesByID
                    )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onAppear {
                applyPreferredPresentation()
                synchronizePages(pages, signature: layoutSignature)
                if isFrameMode {
                    showInitialGuidance()
                }
#if DEBUG
                if DebugScreenshotScenario.current == .frameControls {
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        isShowingFrameControls = true
                    }
                }
#endif
            }
            .onChange(of: layoutSignature) { newSignature in
                synchronizePages(pages, signature: newSignature)
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
            .onReceive(timer) { date in
                refreshWallSchedule(date)
                var updatedPlayback = playback
                let didAdvance = updatedPlayback.tick(
                    in: pages,
                    signature: layoutSignature,
                    at: date
                )
                guard didAdvance else {
                    if updatedPlayback != playback {
                        playback = updatedPlayback
                    }
                    return
                }
                let displayedPage = updatedPlayback.pageChangeRequiringHistory(
                    in: pages
                )
                pageTransitionDirection = .dissolve
                if reduceMotion {
                    playback = updatedPlayback
                } else {
                    withAnimation(.easeInOut(duration: 0.65)) {
                        playback = updatedPlayback
                    }
                }
                if isFrameMode, let displayedPage {
                    recordAutomaticAlbumPhotos(
                        in: displayedPage,
                        slidesByID: slidesByID
                    )
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
                isShowingFrameControls = false
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
        .onChange(of: isShowingFrameControls) { isShowing in
            if isShowing {
                hideControlsTask?.cancel()
            } else if isFrameMode {
                scheduleControlsToRecede()
            }
        }
        .onDisappear {
            hideControlsTask?.cancel()
            hideHintTask?.cancel()
            shareTask?.cancel()
            sharePreparationID = nil
            sharePreparationCount = 0
        }
        .sheet(item: $sharedPhotos) { sharedPhotos in
            SystemPhotoShareSheet(images: sharedPhotos.images)
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
                            motionEnabled: FramePhotoMotionPolicy.shouldAnimate(
                                isFrameMode: isFrameMode,
                                isPlaying: playback.isPlaying,
                                photoCount: page.placements.count,
                                reduceMotionEnabled: reduceMotion,
                                isInteractingWithResize: playback.isInteractingWithResize
                            ),
                            motionDuration: max(playback.interval * 0.92, 4.5)
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

    private func interactionLayer(
        page: FramePage,
        pages: [FramePage],
        signature: String,
        slidesByID: [String: DisplaySlide]
    ) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color.clear
                    .accessibilityHidden(true)

                photoActionTargets(
                    page: page,
                    slidesByID: slidesByID,
                    size: proxy.size
                )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if controlsVisible {
                    setControlsVisible(false)
                    hideControlsTask?.cancel()
                } else {
                    revealControls()
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 30)
                    .updating($interactiveDragOffset) { value, offset, _ in
                        guard abs(value.translation.width) > abs(value.translation.height) else {
                            return
                        }
                        offset = value.translation.width
                    }
                    .onEnded { value in
                        navigate(
                            with: value,
                            pages: pages,
                            signature: signature,
                            slidesByID: slidesByID
                        )
                        if controlsVisible {
                            scheduleControlsToRecede()
                        }
                    }
            )
        }
    }

    private func previewNavigationLayer(
        page: FramePage,
        pages: [FramePage],
        signature: String,
        slidesByID: [String: DisplaySlide]
    ) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color.clear
                    .accessibilityHidden(true)

                photoActionTargets(
                    page: page,
                    slidesByID: slidesByID,
                    size: proxy.size
                )
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 30)
                    .updating($interactiveDragOffset) { value, offset, _ in
                        guard abs(value.translation.width) > abs(value.translation.height) else {
                            return
                        }
                        offset = value.translation.width
                    }
                    .onEnded { value in
                        navigate(
                            with: value,
                            pages: pages,
                            signature: signature,
                            slidesByID: slidesByID
                        )
                    }
            )
        }
    }

    @ViewBuilder
    private func photoActionTargets(
        page: FramePage,
        slidesByID: [String: DisplaySlide],
        size: CGSize
    ) -> some View {
        ForEach(page.placements) { placement in
            if let slide = slidesByID[placement.photoID] {
                Color.clear
                    .contentShape(Rectangle())
                    .frame(
                        width: size.width * CGFloat(placement.screenFrame.width),
                        height: size.height * CGFloat(placement.screenFrame.height)
                    )
                    .position(
                        x: size.width * CGFloat(placement.screenFrame.midX),
                        y: size.height * CGFloat(placement.screenFrame.midY)
                    )
                    .contextMenu {
                        Button {
                            prepareToShare(slide)
                        } label: {
                            Label("Share Photo", systemImage: "square.and.arrow.up")
                        }
                        .accessibilityIdentifier("share-photo-action-" + slide.id)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(slide.accessibilityLabel)
                    .accessibilityAction(named: Text("Share Photo")) {
                        prepareToShare(slide)
                    }
                    .accessibilityIdentifier("frame-photo-actions-" + slide.id)
            }
        }
    }

    private func prepareToShare(_ slide: DisplaySlide) {
        prepareToShare([slide])
    }

    private func prepareToShare(_ slides: [DisplaySlide]) {
        guard !slides.isEmpty else { return }
        shareTask?.cancel()
        sharePreparationID = slides.map(\.id).joined(separator: "|")
        sharePreparationCount = slides.count
        shareTask = Task {
            var images: [UIImage] = []
            images.reserveCapacity(slides.count)
            for slide in slides {
                guard let image = await cachedImage(for: slide),
                      !Task.isCancelled else {
                    sharePreparationID = nil
                    sharePreparationCount = 0
                    return
                }
                images.append(image)
            }
            sharePreparationID = nil
            sharePreparationCount = 0
            guard !Task.isCancelled else { return }
            sharedPhotos = SharedFramePhotos(images: images)
        }
    }

    private func navigate(
        with value: DragGesture.Value,
        pages: [FramePage],
        signature: String,
        slidesByID: [String: DisplaySlide]
    ) {
        guard abs(value.translation.width) > abs(value.translation.height) else {
            return
        }
        if value.translation.width < 0 {
            showNextPage(
                in: pages,
                signature: signature,
                slidesByID: slidesByID
            )
        } else {
            showPreviousPage(
                in: pages,
                signature: signature,
                slidesByID: slidesByID
            )
        }
    }

    private func frameControls(
        isCompact: Bool,
        pages: [FramePage],
        signature: String,
        slidesByID: [String: DisplaySlide]
    ) -> some View {
        VStack {
            Spacer()

            HStack(spacing: isCompact ? 12 : 18) {
                Button {
                    showPreviousPage(
                        in: pages,
                        signature: signature,
                        slidesByID: slidesByID
                    )
                } label: {
                    Image(systemName: "backward.fill")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Previous photo")
                .accessibilityValue(playbackPosition(in: pages))

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

                Button {
                    showNextPage(
                        in: pages,
                        signature: signature,
                        slidesByID: slidesByID
                    )
                } label: {
                    Image(systemName: "forward.fill")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Next photo")
                .accessibilityValue(playbackPosition(in: pages))

                Divider()
                    .frame(height: 26)
                    .overlay(Color.white.opacity(0.35))

                Button {
                    hideControlsTask?.cancel()
                    isShowingFrameControls = true
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("More playback options")
                .popover(
                    isPresented: $isShowingFrameControls,
                    attachmentAnchor: .rect(.bounds)
                ) {
                    FrameControlsPanel(
                        interval: playback.interval,
                        slides: shareableSlides(
                            pages: pages,
                            slidesByID: slidesByID
                        ),
                        selectInterval: selectInterval,
                        share: shareFromFrameControls,
                        dismiss: {
                            isShowingFrameControls = false
                        }
                    )
                    .frameControlsPresentation()
                }
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
    }

    private var quickExitControl: some View {
        VStack {
            HStack {
                Spacer()

                Button {
                    hideControlsTask?.cancel()
                    isFrameMode = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.bold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)
                .background(.ultraThinMaterial, in: Circle())
                .shadow(color: .black.opacity(0.28), radius: 12, y: 5)
                .accessibilityLabel("Exit Frame")
                .accessibilityHint("Return to FrameWink")
                .accessibilityIdentifier("frame-quick-close-control")
            }

            Spacer()
        }
        .padding(.top, 18)
        .padding(.trailing, 20)
    }

    private func shareableSlides(
        pages: [FramePage],
        slidesByID: [String: DisplaySlide]
    ) -> [DisplaySlide] {
        activePage(in: pages)?.placements.compactMap {
            slidesByID[$0.photoID]
        } ?? []
    }

    private func selectInterval(_ interval: TimeInterval) {
        playback.setInterval(interval, at: Date())
        presentationDidChange(interval)
    }

    private func shareFromFrameControls(_ slides: [DisplaySlide]) {
        isShowingFrameControls = false
        prepareToShare(slides)
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

    private func showNextPage(
        in pages: [FramePage],
        signature: String,
        slidesByID: [String: DisplaySlide]
    ) {
        performPageChange(
            direction: .forward,
            slidesByID: slidesByID
        ) { updatedPlayback in
            updatedPlayback.next(in: pages, signature: signature, at: Date())
        }
    }

    private func showPreviousPage(
        in pages: [FramePage],
        signature: String,
        slidesByID: [String: DisplaySlide]
    ) {
        performPageChange(
            direction: .backward,
            slidesByID: slidesByID
        ) { updatedPlayback in
            updatedPlayback.previous(in: pages, signature: signature, at: Date())
        }
    }

    private func performPageChange(
        direction: FramePageTransitionDirection,
        slidesByID: [String: DisplaySlide],
        _ change: (inout FramePlaybackCoordinator) -> FramePage?
    ) {
        var updatedPlayback = playback
        let displayedPage = change(&updatedPlayback)
        pageTransitionDirection = direction
        if reduceMotion {
            playback = updatedPlayback
        } else {
            withAnimation(.easeInOut(duration: 0.4)) {
                playback = updatedPlayback
            }
        }
        if isFrameMode, let displayedPage {
            recordAutomaticAlbumPhotos(
                in: displayedPage,
                slidesByID: slidesByID
            )
        }
        scheduleControlsToRecede()
    }

    private func synchronizePages(_ pages: [FramePage], signature: String) {
        playback.synchronizePages(pages, signature: signature)
    }

    private func applyPreferredPresentation() {
        layoutPreference = preferredLayoutPreference
        playback.setInterval(
            FramePlaybackTiming.normalized(preferredInterval),
            at: Date()
        )
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

    private func playbackPosition(in pages: [FramePage]) -> String {
        guard !pages.isEmpty else { return "No photos" }
        let position = min(playback.currentPageIndex, pages.count - 1) + 1
        return "Photo \(position) of \(pages.count)"
    }
}

private struct FrameControlsPanel: View {
    let interval: TimeInterval
    let slides: [DisplaySlide]
    let selectInterval: (TimeInterval) -> Void
    let share: ([DisplaySlide]) -> Void
    let dismiss: () -> Void
    @State private var selectedInterval: TimeInterval

    init(
        interval: TimeInterval,
        slides: [DisplaySlide],
        selectInterval: @escaping (TimeInterval) -> Void,
        share: @escaping ([DisplaySlide]) -> Void,
        dismiss: @escaping () -> Void
    ) {
        self.interval = interval
        self.slides = slides
        self.selectInterval = selectInterval
        self.share = share
        self.dismiss = dismiss
        _selectedInterval = State(initialValue: interval)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Frame Controls")
                    .font(.headline)
                    .accessibilityIdentifier("frame-controls-panel")

                Spacer()

                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close Frame Controls")
                .accessibilityIdentifier("close-frame-controls")
            }

            controlSection(title: "Photo Duration") {
                selectionGrid(columns: 4) {
                    ForEach(FramePlaybackTiming.availableIntervals, id: \.self) { candidate in
                        selectionButton(
                            title: FramePlaybackTiming.title(for: candidate),
                            isSelected: selectedInterval == candidate,
                            accessibilityIdentifier: "frame-speed-\(Int(candidate))"
                        ) {
                            selectedInterval = candidate
                            selectInterval(candidate)
                        }
                    }
                }
            }

            Divider()

            if !slides.isEmpty {
                Button {
                    share(slides)
                } label: {
                    HStack(spacing: 0) {
                        Image(systemName: "square.and.arrow.up")
                            .frame(width: 28)
                        Text(slides.count == 1 ? "Share Photo" : "Share Photos")
                            .frame(maxWidth: .infinity, alignment: .center)
                        Color.clear
                            .frame(width: 28, height: 1)
                    }
                    .frame(maxWidth: .infinity, minHeight: 38)
                }
                .buttonStyle(.bordered)
                .tint(.accentColor)
                .accessibilityLabel(slides.count == 1 ? "Share Photo" : "Share Photos")
                .accessibilityHint(
                    slides.count == 1
                        ? "Opens the system share sheet"
                        : "Shares every photo in the current frame"
                )
                .accessibilityIdentifier("frame-share-current-photos")
            }
        }
        .padding(20)
        .frame(idealWidth: 410, maxWidth: 460, alignment: .leading)
        .foregroundColor(.primary)
        .background(Color(uiColor: .systemBackground))
        .onChange(of: interval) { newInterval in
            selectedInterval = newInterval
        }
    }

    @ViewBuilder
    private func controlSection<Content: View>(
        title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            content()
        }
    }

    @ViewBuilder
    private func selectionGrid<Content: View>(
        columns: Int,
        @ViewBuilder content: () -> Content
    ) -> some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: 8),
                count: columns
            ),
            spacing: 8
        ) {
            content()
        }
    }

    private func selectionButton(
        title: String,
        isSelected: Bool,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 38)
            .contentShape(Rectangle())
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .accentColor : .secondary)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(accessibilityIdentifier)
    }

}

private extension View {
    @ViewBuilder
    func frameControlsPresentation() -> some View {
        if #available(iOS 16.4, *) {
            self
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.hidden)
                .presentationCompactAdaptation(.sheet)
                .presentationBackground(Color(uiColor: .systemBackground))
        } else if #available(iOS 16.0, *) {
            self
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.hidden)
        } else {
            self
        }
    }
}

private struct SharedFramePhotos: Identifiable {
    let id = UUID()
    let images: [UIImage]
}

private struct SystemPhotoShareSheet: UIViewControllerRepresentable {
    let images: [UIImage]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: images,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

private enum FramePageTransitionDirection {
    case dissolve
    case forward
    case backward

    var transition: AnyTransition {
        switch self {
        case .dissolve:
            return .opacity
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
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
    @State private var motionAtEnd = false
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
        GeometryReader { proxy in
            ZStack {
                Color.black

                if let image = image ?? initialImage {
                    photo(image)
                        .scaleEffect(CGFloat(currentMotionState.scale))
                        .offset(
                            x: CGFloat(currentMotionState.offsetX) * proxy.size.width,
                            y: CGFloat(currentMotionState.offsetY) * proxy.size.height
                        )
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .accessibilityLabel("Loading photo")
                }
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
        guard motionEnabled, motionPlan != nil else {
            withAnimation(nil) {
                motionAtEnd = false
            }
            return
        }

        motionTask = Task { @MainActor in
            withAnimation(nil) {
                motionAtEnd = false
            }
            await Task.yield()
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: motionDuration)) {
                motionAtEnd = true
            }
            do {
                try await Task.sleep(
                    nanoseconds: UInt64(motionDuration * 1_000_000_000)
                )
            } catch {
                return
            }
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: motionDuration)) {
                    motionAtEnd.toggle()
                }
                do {
                    try await Task.sleep(
                    nanoseconds: UInt64(motionDuration * 1_000_000_000)
                    )
                } catch {
                    return
                }
            }
        }
    }

    private var motionPlan: FramePhotoMotionPlan? {
        FramePhotoMotionPlanner.plan(
            photoID: slide.id,
            placement: placement,
            importantRects: slide.importantRects
        )
    }

    private var currentMotionState: FramePhotoMotionState {
        guard motionEnabled, let motionPlan else {
            return FramePhotoMotionState(scale: 1, offsetX: 0, offsetY: 0)
        }
        return motionAtEnd ? motionPlan.end : motionPlan.start
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
            preferredInterval: FramePlaybackTiming.defaultInterval,
            allowsAutomaticMosaic: false,
            presentationDidChange: { _ in },
            isFrameMode: .constant(false),
            wallVisualState: .normal,
            refreshWallSchedule: { _ in }
        )
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
#endif
