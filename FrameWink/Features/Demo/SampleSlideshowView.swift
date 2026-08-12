import Combine
import SwiftUI
import UIKit

struct SampleSlideshowView: View {
    let slides: [DisplaySlide]
    let loadImportedImage: (ImportedPhoto) async -> UIImage?
    @Binding var isFrameMode: Bool
    let wallVisualState: WallVisualState
    let refreshWallSchedule: (Date) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session = FrameSessionController()
    @State private var layoutPreference: FrameLayoutPreference = .automatic
    @State private var controlsVisible = true
    @State private var hideControlsTask: Task<Void, Never>?

    private let layoutChooser = FrameLayoutChooser()
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
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
                preference: layoutPreference
            )
            let slidesByID = Dictionary(uniqueKeysWithValues: slides.map { ($0.id, $0) })

            ZStack {
                Color.black

                if let page = activePage(in: pages) {
                    framePage(page, slidesByID: slidesByID)
                        .id(page.id)
                        .transition(reduceMotion ? .identity : .opacity)

                    if let slide = slidesByID[page.placements.first?.photoID ?? ""] {
                        caption(for: slide)
                    }
                }

                wallScheduleOverlay

                if isFrameMode {
                    interactionLayer

                    if controlsVisible {
                        frameControls
                            .transition(reduceMotion ? .identity : .opacity)
                    } else if wallVisualState != .blackout {
                        controlsHint
                            .transition(reduceMotion ? .identity : .opacity)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onAppear {
                synchronizePageCount(pages.count)
                scheduleControlsToRecede()
            }
            .onChange(of: pages.count) { newCount in
                synchronizePageCount(newCount)
            }
        }
        .background(Color.black)
        .clipped()
        .onReceive(timer) { date in
            refreshWallSchedule(date)
            if reduceMotion {
                session.tick(at: date)
            } else {
                withAnimation(.easeInOut(duration: 0.65)) {
                    session.tick(at: date)
                }
            }
        }
        .onChange(of: isFrameMode) { isActive in
            setControlsVisible(true)
            if isActive {
                scheduleControlsToRecede()
            } else {
                hideControlsTask?.cancel()
            }
        }
        .onDisappear {
            hideControlsTask?.cancel()
        }
    }

    private func activePage(in pages: [FramePage]) -> FramePage? {
        guard !pages.isEmpty else { return nil }
        return pages[min(session.currentPageIndex, pages.count - 1)]
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
                            loadImportedImage: loadImportedImage
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

    private func caption(for slide: DisplaySlide) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(slide.title)
                .font(.system(size: 38, weight: .semibold, design: .rounded))
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
                        revealControls()
                    }
            )
            .accessibilityHidden(true)
    }

    private var frameControls: some View {
        VStack {
            HStack {
                Button {
                    isFrameMode = false
                } label: {
                    Label("Exit Frame Mode", systemImage: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.55), in: Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                Text("FRAME MODE")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.45), in: Capsule())
            }

            Spacer()

            HStack(spacing: 18) {
                Button(action: showPreviousPage) {
                    Image(systemName: "backward.fill")
                }
                .accessibilityLabel("Previous photo")

                Button {
                    session.togglePlayback(at: Date())
                    if session.isPlaying {
                        scheduleControlsToRecede()
                    } else {
                        hideControlsTask?.cancel()
                    }
                } label: {
                    Image(systemName: session.isPlaying ? "pause.fill" : "play.fill")
                }
                .accessibilityLabel(session.isPlaying ? "Pause slideshow" : "Resume slideshow")

                Button(action: showNextPage) {
                    Image(systemName: "forward.fill")
                }
                .accessibilityLabel("Next photo")

                Divider()
                    .frame(height: 26)
                    .overlay(Color.white.opacity(0.35))

                Menu {
                    ForEach(FrameLayoutPreference.allCases) { preference in
                        Button {
                            layoutPreference = preference
                            revealControls()
                        } label: {
                            if layoutPreference == preference {
                                Label(preference.title, systemImage: "checkmark")
                            } else {
                                Text(preference.title)
                            }
                        }
                    }
                } label: {
                    Label(layoutPreference.title, systemImage: "rectangle.split.2x1")
                }
                .accessibilityLabel("Layout: \(layoutPreference.title)")

                Menu {
                    ForEach(availableIntervals, id: \.self) { interval in
                        Button {
                            session.setInterval(interval, at: Date())
                            revealControls()
                        } label: {
                            if session.interval == interval {
                                Label(intervalTitle(interval), systemImage: "checkmark")
                            } else {
                                Text(intervalTitle(interval))
                            }
                        }
                    }
                } label: {
                    Label(intervalTitle(session.interval), systemImage: "timer")
                }
                .accessibilityLabel("Photo interval: \(intervalTitle(session.interval))")
            }
            .font(.title3.weight(.semibold))
            .foregroundColor(.white)
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
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
            .padding(.bottom, 28)
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
                .accessibilityLabel("Scheduled Wall Mode blackout")
        }
    }

    private func showNextPage() {
        performPageChange {
            session.next(at: Date())
        }
    }

    private func showPreviousPage() {
        performPageChange {
            session.previous(at: Date())
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

    private func synchronizePageCount(_ count: Int) {
        session.updatePageCount(count)
    }

    private func revealControls() {
        setControlsVisible(true)
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

    private func scheduleControlsToRecede() {
        hideControlsTask?.cancel()
        guard isFrameMode, session.isPlaying else { return }

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
    var frameLayoutItem: FrameLayoutItem {
        let pixelSize: PixelSize
        switch source {
        case .bundled:
            pixelSize = PixelSize(width: 1_536, height: 1_024)
        case .imported(let photo):
            pixelSize = PixelSize(
                width: photo.pixelWidth,
                height: photo.pixelHeight
            )
        }

        return FrameLayoutItem(
            id: id,
            pixelSize: pixelSize,
            importantRects: importantRects
        )
    }
}

private struct FramePhotoView: View {
    let slide: DisplaySlide
    let placement: FrameLayoutPlacement
    let loadImportedImage: (ImportedPhoto) async -> UIImage?

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.black

            if let image = image {
                switch placement.contentMode {
                case .fit:
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .crop:
                    croppedImage(image)
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .accessibilityLabel("Loading photo")
            }
        }
        .clipped()
        .task(id: slide.id) {
            switch slide.source {
            case .bundled(let resourceName):
                image = BundledSampleImageLoader.image(named: resourceName)
            case .imported(let photo):
                image = await loadImportedImage(photo)
            }
        }
        .accessibilityLabel(slide.accessibilityLabel)
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

enum BundledSampleImageLoader {
    static func image(named resourceName: String, bundle: Bundle = .main) -> UIImage? {
        guard let url = bundle.url(forResource: resourceName, withExtension: "png") else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
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
            isFrameMode: .constant(false),
            wallVisualState: .normal,
            refreshWallSchedule: { _ in }
        )
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
#endif
