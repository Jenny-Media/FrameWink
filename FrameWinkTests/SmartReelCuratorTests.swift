import XCTest
@testable import FrameWink

final class SmartReelCuratorTests: XCTestCase {
    private let curator = SmartReelCurator()
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    func testHighConfidenceMetadataAndQualityFiltersAreHardExclusions() throws {
        let hidden = fixture(index: 1, isHidden: true)
        let screenshot = fixture(index: 2, isScreenshot: true)
        let blurred = fixture(index: 3, sharpness: 0.02)
        let eligible = fixture(index: 4)

        let reel = try curator.makeReel(
            from: [hidden, screenshot, blurred, eligible],
            exclusions: [],
            maximumCount: 30,
            now: baseDate,
            reelID: id(999)
        )

        XCTAssertEqual(reel.selections.map(\.candidateID), [eligible.candidate.id])
    }

    func testBurstAndNearDuplicateSuppressionKeepTheStrongestPhoto() throws {
        let duplicatePrint = FixtureFeaturePrint(values: [0.2, 0.4, 0.6])
        let weaker = fixture(
            index: 1,
            dateOffset: 0,
            sharpness: 0.5,
            featurePrint: duplicatePrint
        )
        let stronger = fixture(
            index: 2,
            dateOffset: 3_600,
            sharpness: 0.9,
            featurePrint: duplicatePrint
        )
        let burstLoser = fixture(
            index: 3,
            dateOffset: 7_200,
            sharpness: 0.4,
            burstIdentifier: "burst-a"
        )
        let burstWinner = fixture(
            index: 4,
            dateOffset: 7_201,
            sharpness: 0.8,
            burstIdentifier: "burst-a"
        )

        let reel = try curator.makeReel(
            from: [weaker, stronger, burstLoser, burstWinner],
            exclusions: [],
            maximumCount: 30,
            now: baseDate,
            reelID: id(999)
        )
        let selected = Set(reel.selections.map(\.candidateID))

        XCTAssertEqual(selected, [stronger.candidate.id, burstWinner.candidate.id])
    }

    func testVisionDistanceNormalizationDoesNotCollapseOrdinaryPhotos() {
        XCTAssertEqual(VisionFeaturePrint.normalized(rawDistance: -0.1), 0)
        XCTAssertEqual(VisionFeaturePrint.normalized(rawDistance: 0.8), 0.8)
        XCTAssertEqual(VisionFeaturePrint.normalized(rawDistance: 40), 1)
    }

    func testRankingIsDeterministicForFixedInputRevisionAndIdentity() throws {
        let photos = (1...40).map { index in
            fixture(
                index: index,
                dateOffset: TimeInterval(index * 3_600),
                sharpness: 0.3 + Double(index % 7) / 10,
                featurePrint: FixtureFeaturePrint(values: [Double(index) * 0.2])
            )
        }

        let first = try curator.makeReel(
            from: photos.shuffled(),
            exclusions: [],
            maximumCount: 30,
            now: baseDate,
            reelID: id(998)
        )
        let second = try curator.makeReel(
            from: Array(photos.reversed()),
            exclusions: [],
            maximumCount: 30,
            now: baseDate,
            reelID: id(998)
        )

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.selections.count, 30)
    }

    func testNeverShowExclusionIsAHardVeto() throws {
        let excluded = fixture(index: 1, sharpness: 1)
        let remaining = fixture(index: 2, sharpness: 0.5)

        let reel = try curator.makeReel(
            from: [excluded, remaining],
            exclusions: [excluded.candidate.id],
            maximumCount: 30,
            now: baseDate,
            reelID: id(999)
        )

        XCTAssertEqual(reel.selections.map(\.candidateID), [remaining.candidate.id])
    }

    func testDateCapPromotesMultipleEventsOverOneLargeHighScoringDay() throws {
        let crowdedDay = (1...8).map { index in
            fixture(
                index: index,
                dateOffset: TimeInterval(index * 60),
                sharpness: 0.95,
                featurePrint: FixtureFeaturePrint(values: [Double(index) * 0.2])
            )
        }
        let otherDays = (9...12).map { index in
            fixture(
                index: index,
                dateOffset: TimeInterval((index - 8) * 86_400),
                sharpness: 0.35,
                featurePrint: FixtureFeaturePrint(values: [Double(index) * 0.2])
            )
        }

        let reel = try curator.makeReel(
            from: crowdedDay + otherDays,
            exclusions: [],
            maximumCount: 6,
            now: baseDate,
            reelID: id(999)
        )
        let days = Set(reel.selections.compactMap { selection in
            (crowdedDay + otherDays)
                .first { $0.candidate.id == selection.candidateID }?
                .candidate.creationDate.map { Calendar.current.ordinality(of: .day, in: .era, for: $0) }
        })

        XCTAssertGreaterThanOrEqual(days.count, 4)
        XCTAssertLessThanOrEqual(
            reel.selections.filter { selection in
                crowdedDay.contains { $0.candidate.id == selection.candidateID }
            }.count,
            3
        )
    }

    func testSelectionIncludesStrongOlderAndRecentPhotos() throws {
        var photos: [AnalyzedPhoto] = []
        for index in 1...10 {
            let sharpness = index == 1 || index == 10 ? 0.9 : 0.5
            let photo = fixture(
                index: index,
                dateOffset: TimeInterval(index * 86_400),
                sharpness: sharpness,
                featurePrint: FixtureFeaturePrint(values: [Double(index) * 0.2])
            )
            photos.append(photo)
        }

        let reel = try curator.makeReel(
            from: photos,
            exclusions: [],
            maximumCount: 4,
            now: baseDate,
            reelID: id(999)
        )

        XCTAssertTrue(reel.selections.contains { $0.candidateID == photos.first?.candidate.id })
        XCTAssertTrue(reel.selections.contains { $0.candidateID == photos.last?.candidate.id })
    }

    func testLayoutFitnessContributesToRanking() throws {
        let awkward = fixture(index: 1, layoutFitness: 0.1)
        let frameReady = fixture(index: 2, layoutFitness: 1)

        let reel = try curator.makeReel(
            from: [awkward, frameReady],
            exclusions: [],
            maximumCount: 2,
            now: baseDate,
            reelID: id(999)
        )

        XCTAssertEqual(reel.selections.first?.candidateID, frameReady.candidate.id)
    }

    func testOneHundredCandidatePureFixtureFinishesWellInsideBudget() throws {
        let photos = (1...100).map { index in
            fixture(
                index: index,
                dateOffset: TimeInterval(index * 180),
                featurePrint: FixtureFeaturePrint(values: [Double(index) * 0.2])
            )
        }
        let start = CFAbsoluteTimeGetCurrent()

        let reel = try curator.makeReel(
            from: photos,
            exclusions: [],
            maximumCount: 30,
            now: baseDate,
            reelID: id(999)
        )

        XCTAssertEqual(reel.selections.count, 30)
        XCTAssertLessThan(CFAbsoluteTimeGetCurrent() - start, 1)
    }

    func testRecentRepeatedPhotoYieldsToFreshDisplayablePhoto() throws {
        let repeated = fixture(index: 1, sharpness: 0.95)
        let fresh = fixture(index: 2, dateOffset: 86_400, sharpness: 0.72)
        let history = DisplayHistoryEntry(
            candidateID: repeated.candidate.id,
            lastDisplayedAt: baseDate.addingTimeInterval(-60),
            displayCount: 12
        )

        let reel = try curator.makeReel(
            from: [repeated, fresh],
            exclusions: [],
            displayHistory: [repeated.candidate.id: history],
            maximumCount: 1,
            now: baseDate,
            reelID: id(999)
        )

        XCTAssertEqual(reel.selections.first?.candidateID, fresh.candidate.id)
    }

    func testFiveThousandCandidatePoolUsesBoundedSimilarityWindow() throws {
        let photos = (1...5_000).map { index in
            fixture(
                index: index,
                dateOffset: TimeInterval(index * 10),
                featurePrint: FixtureFeaturePrint(values: [Double(index) * 0.2])
            )
        }
        let start = CFAbsoluteTimeGetCurrent()

        let reel = try curator.makeReel(
            from: photos,
            exclusions: [],
            maximumCount: 100,
            now: baseDate,
            reelID: id(999_999)
        )

        let elapsed = CFAbsoluteTimeGetCurrent() - start
        print(String(format: "PAID_5000_CURATOR_PERF elapsed=%.3fs", elapsed))
        XCTAssertEqual(reel.selections.count, 100)
        XCTAssertLessThan(elapsed, 5)
    }

    private func fixture(
        index: Int,
        dateOffset: TimeInterval = 0,
        sharpness: Double = 0.7,
        exposure: Double = 0.5,
        contrast: Double = 0.7,
        isHidden: Bool = false,
        isScreenshot: Bool = false,
        burstIdentifier: String? = nil,
        layoutFitness: Double = 0.9,
        featurePrint: (any PhotoFeaturePrintDistance)? = nil
    ) -> AnalyzedPhoto {
        let candidateID = id(index)
        let candidate = PhotoCandidate(
            id: candidateID,
            source: .pickerImport,
            pixelWidth: 1_600,
            pixelHeight: 1_200,
            creationDate: baseDate.addingTimeInterval(dateOffset),
            isHidden: isHidden,
            isScreenshot: isScreenshot,
            burstIdentifier: burstIdentifier
        )
        return AnalyzedPhoto(
            candidate: candidate,
            signals: PhotoSignals(
                candidateID: candidateID,
                algorithmRevision: SmartReelCurator.algorithmRevision,
                sharpness: sharpness,
                exposure: exposure,
                contrast: contrast,
                faceQuality: 0.7,
                saliencyConfidence: 0.7,
                layoutFitness: layoutFitness,
                importantRects: []
            ),
            featurePrint: featurePrint
        )
    }

    private func id(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }
}
