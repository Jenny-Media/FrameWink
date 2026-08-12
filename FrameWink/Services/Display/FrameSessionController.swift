import Foundation

struct FrameSessionController: Equatable {
    private(set) var pageCount: Int
    private(set) var currentPageIndex: Int
    private(set) var isPlaying: Bool
    private(set) var interval: TimeInterval
    private var lastAdvanceDate: Date?

    init(
        pageCount: Int = 0,
        currentPageIndex: Int = 0,
        isPlaying: Bool = true,
        interval: TimeInterval = 7,
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

    @discardableResult
    mutating func tick(at date: Date) -> Bool {
        guard isPlaying, pageCount > 0 else { return false }
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
    }

    mutating func resume(at date: Date) {
        isPlaying = true
        lastAdvanceDate = date
    }

    mutating func togglePlayback(at date: Date) {
        isPlaying ? pause() : resume(at: date)
    }

    mutating func setInterval(_ newInterval: TimeInterval, at date: Date) {
        interval = min(max(newInterval, 1), 3_600)
        lastAdvanceDate = isPlaying ? date : nil
    }
}
