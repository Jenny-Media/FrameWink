import Foundation

enum FrameOverlayVisibilityPolicy {
    static func shouldAutomaticallyHideControls(
        isFrameMode: Bool,
        isPlaying: Bool,
        voiceOverEnabled: Bool
    ) -> Bool {
        isFrameMode && isPlaying && !voiceOverEnabled
    }
}

struct FramePlaybackCoordinator: Equatable {
    private(set) var session: FrameSessionController
    private(set) var featuredPhotoID: String?
    private(set) var pageLayoutSignature = ""
    private(set) var isInteractingWithResize = false

    init(session: FrameSessionController = FrameSessionController()) {
        self.session = session
    }

    var currentPageIndex: Int { session.currentPageIndex }
    var pageCount: Int { session.pageCount }
    var isPlaying: Bool { session.isPlaying }
    var interval: TimeInterval { session.interval }

    func activePage(in pages: [FramePage]) -> FramePage? {
        guard !pages.isEmpty else { return nil }
        return pages[min(session.currentPageIndex, pages.count - 1)]
    }

    mutating func synchronizePages(_ pages: [FramePage], signature: String) {
        guard pageLayoutSignature != signature
            || session.pageCount != pages.count else {
            return
        }
        let oldIndex = session.currentPageIndex
        session.updatePageCount(pages.count)
        session.selectPage(
            FramePageAnchorResolver.index(
                preserving: featuredPhotoID,
                in: pages,
                fallbackIndex: oldIndex
            )
        )
        pageLayoutSignature = signature

        guard let page = activePage(in: pages) else {
            featuredPhotoID = nil
            return
        }
        if featuredPhotoID == nil
            || !page.placements.contains(where: { $0.photoID == featuredPhotoID }) {
            featuredPhotoID = page.placements.first?.photoID
        }
    }

    mutating func pageChangeRequiringHistory(in pages: [FramePage]) -> FramePage? {
        guard let page = activePage(in: pages) else { return nil }
        let preservesAnchor = featuredPhotoID.map { photoID in
            page.placements.contains(where: { $0.photoID == photoID })
        } ?? false
        guard !preservesAnchor else { return nil }
        featuredPhotoID = page.placements.first?.photoID
        return page
    }

    mutating func setInteractiveResize(_ isResizing: Bool, at date: Date) {
        guard isInteractingWithResize != isResizing else { return }
        isInteractingWithResize = isResizing
        if isResizing {
            session.suspendAdvancement(at: date)
        } else {
            session.resumeAdvancement(at: date)
        }
    }

    @discardableResult
    mutating func tick(at date: Date) -> Bool {
        guard !isInteractingWithResize else { return false }
        return session.tick(at: date)
    }

    @discardableResult
    mutating func tick(
        in pages: [FramePage],
        signature: String,
        at date: Date
    ) -> Bool {
        synchronizePages(pages, signature: signature)
        return tick(at: date)
    }

    mutating func next(at date: Date) { session.next(at: date) }
    mutating func previous(at date: Date) { session.previous(at: date) }

    @discardableResult
    mutating func next(
        in pages: [FramePage],
        signature: String,
        at date: Date
    ) -> FramePage? {
        synchronizePages(pages, signature: signature)
        next(at: date)
        return pageChangeRequiringHistory(in: pages)
    }

    @discardableResult
    mutating func previous(
        in pages: [FramePage],
        signature: String,
        at date: Date
    ) -> FramePage? {
        synchronizePages(pages, signature: signature)
        previous(at: date)
        return pageChangeRequiringHistory(in: pages)
    }

    mutating func togglePlayback(at date: Date) { session.togglePlayback(at: date) }
    mutating func setInterval(_ interval: TimeInterval, at date: Date) {
        session.setInterval(interval, at: date)
    }
}

struct FrameSessionController: Equatable {
    private(set) var pageCount: Int
    private(set) var currentPageIndex: Int
    private(set) var isPlaying: Bool
    private(set) var interval: TimeInterval
    private var lastAdvanceDate: Date?
    private var advancementSuspendedAt: Date?

    init(
        pageCount: Int = 0,
        currentPageIndex: Int = 0,
        isPlaying: Bool = true,
        interval: TimeInterval = FramePlaybackTiming.defaultInterval,
        startedAt: Date = Date()
    ) {
        self.pageCount = max(pageCount, 0)
        self.currentPageIndex = pageCount > 0
            ? min(max(currentPageIndex, 0), pageCount - 1)
            : 0
        self.isPlaying = isPlaying
        self.interval = min(max(interval, 1), 3_600)
        lastAdvanceDate = isPlaying ? startedAt : nil
    }

    mutating func updatePageCount(_ newCount: Int) {
        pageCount = max(newCount, 0)
        currentPageIndex = pageCount > 0
            ? min(currentPageIndex, pageCount - 1)
            : 0
    }

    mutating func selectPage(_ index: Int) {
        guard pageCount > 0 else {
            currentPageIndex = 0
            return
        }
        currentPageIndex = min(max(index, 0), pageCount - 1)
    }

    @discardableResult
    mutating func tick(at date: Date) -> Bool {
        guard isPlaying, advancementSuspendedAt == nil, pageCount > 0 else {
            return false
        }
        guard let lastAdvanceDate = lastAdvanceDate else {
            self.lastAdvanceDate = date
            return false
        }

        let elapsed = max(date.timeIntervalSince(lastAdvanceDate), 0)
        let elapsedIntervals = Int(elapsed / interval)
        guard elapsedIntervals > 0 else { return false }

        let nextPageIndex = (currentPageIndex + elapsedIntervals) % pageCount
        self.lastAdvanceDate = lastAdvanceDate.addingTimeInterval(
            Double(elapsedIntervals) * interval
        )
        guard nextPageIndex != currentPageIndex else { return false }
        currentPageIndex = nextPageIndex
        return true
    }

    mutating func next(at date: Date) {
        guard pageCount > 0 else { return }
        currentPageIndex = (currentPageIndex + 1) % pageCount
        lastAdvanceDate = isPlaying ? date : nil
    }

    mutating func previous(at date: Date) {
        guard pageCount > 0 else { return }
        currentPageIndex = (currentPageIndex - 1 + pageCount) % pageCount
        lastAdvanceDate = isPlaying ? date : nil
    }

    mutating func pause() {
        isPlaying = false
        lastAdvanceDate = nil
        advancementSuspendedAt = nil
    }

    mutating func resume(at date: Date) {
        isPlaying = true
        lastAdvanceDate = date
        advancementSuspendedAt = nil
    }

    mutating func togglePlayback(at date: Date) {
        isPlaying ? pause() : resume(at: date)
    }

    mutating func setInterval(_ newInterval: TimeInterval, at date: Date) {
        interval = min(max(newInterval, 1), 3_600)
        lastAdvanceDate = isPlaying ? date : nil
        advancementSuspendedAt = nil
    }

    mutating func suspendAdvancement(at date: Date) {
        guard isPlaying, advancementSuspendedAt == nil else { return }
        advancementSuspendedAt = date
    }

    mutating func resumeAdvancement(at date: Date) {
        guard let advancementSuspendedAt else { return }
        if let lastAdvanceDate {
            self.lastAdvanceDate = lastAdvanceDate.addingTimeInterval(
                max(date.timeIntervalSince(advancementSuspendedAt), 0)
            )
        }
        self.advancementSuspendedAt = nil
    }
}
