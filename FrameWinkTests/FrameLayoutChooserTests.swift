import XCTest
@testable import FrameWink

final class FrameLayoutChooserTests: XCTestCase {
    private let chooser = FrameLayoutChooser()
    private let landscapeViewport = PixelSize(width: 1_366, height: 1_024)

    func testFitKeepsTheWholeLandscapePhoto() throws {
        let item = fixture(id: "landscape", width: 1_500, height: 1_000)
        let page = try XCTUnwrap(
            chooser.pages(for: [item], viewport: landscapeViewport, preference: .fit).first
        )

        XCTAssertEqual(page.kind, .singleFit)
        XCTAssertEqual(page.placements.first?.sourceCrop, .unit)
        XCTAssertEqual(page.placements.first?.contentMode, .fit)
    }

    func testFillProducesAValidCenteredCropForPanorama() throws {
        let item = fixture(id: "panorama", width: 4_000, height: 1_000)
        let placement = try XCTUnwrap(
            chooser.pages(for: [item], viewport: landscapeViewport, preference: .fill)
                .first?.placements.first
        )

        XCTAssertEqual(placement.contentMode, .crop)
        XCTAssertTrue(placement.sourceCrop.isWithinUnitBounds)
        XCTAssertLessThan(placement.sourceCrop.width, 1)
        XCTAssertEqual(placement.sourceCrop.midX, 0.5, accuracy: 0.000_001)
    }

    func testSquarePhotoFillUsesAValidCenteredVerticalCrop() throws {
        let item = fixture(id: "square", width: 1_200, height: 1_200)
        let crop = try XCTUnwrap(
            chooser.pages(for: [item], viewport: landscapeViewport, preference: .fill)
                .first?.placements.first?.sourceCrop
        )

        XCTAssertTrue(crop.isWithinUnitBounds)
        XCTAssertEqual(crop.width, 1, accuracy: 0.000_001)
        XCTAssertLessThan(crop.height, 1)
        XCTAssertEqual(crop.midY, 0.5, accuracy: 0.000_001)
    }

    func testFillMovesCropToProtectAnEdgePositionedFace() throws {
        let face = NormalizedRect(x: 0.88, y: 0.30, width: 0.10, height: 0.22)
        let item = fixture(
            id: "right-edge-face",
            width: 4_000,
            height: 1_000,
            importantRects: [face]
        )
        let crop = try XCTUnwrap(
            chooser.pages(for: [item], viewport: landscapeViewport, preference: .fill)
                .first?.placements.first?.sourceCrop
        )

        XCTAssertGreaterThanOrEqual(crop.maxX, face.maxX)
        XCTAssertLessThanOrEqual(crop.minX, face.minX)
    }

    func testUnsafeMultiFaceFillFallsBackToFit() throws {
        let item = fixture(
            id: "wide-faces",
            width: 4_000,
            height: 1_000,
            importantRects: [
                NormalizedRect(x: 0.02, y: 0.2, width: 0.12, height: 0.2),
                NormalizedRect(x: 0.86, y: 0.2, width: 0.12, height: 0.2),
            ]
        )
        let page = try XCTUnwrap(
            chooser.pages(for: [item], viewport: landscapeViewport, preference: .fill).first
        )

        XCTAssertEqual(page.kind, .singleFit)
        XCTAssertEqual(page.placements.first?.sourceCrop, .unit)
    }

    func testAutomaticPairsCompatiblePortraitsWithoutOverlap() throws {
        let first = fixture(
            id: "portrait-a",
            width: 1_000,
            height: 1_500,
            importantRects: [NormalizedRect(x: 0.3, y: 0.1, width: 0.3, height: 0.25)]
        )
        let second = fixture(
            id: "portrait-b",
            width: 1_000,
            height: 1_500,
            importantRects: [NormalizedRect(x: 0.4, y: 0.2, width: 0.3, height: 0.25)]
        )
        let page = try XCTUnwrap(
            chooser.pages(
                for: [first, second],
                viewport: landscapeViewport,
                preference: .automatic
            ).first
        )

        XCTAssertEqual(page.kind, .pairedPortraits)
        XCTAssertEqual(page.placements.count, 2)
        XCTAssertEqual(page.placements[0].screenFrame.maxX, page.placements[1].screenFrame.minX)
        XCTAssertTrue(page.placements.allSatisfy { $0.sourceCrop.isWithinUnitBounds })
    }

    func testRotationReflowsPortraitPairIntoSinglePages() {
        let items = [
            fixture(id: "portrait-a", width: 1_000, height: 1_500),
            fixture(id: "portrait-b", width: 1_000, height: 1_500),
        ]

        let landscapePages = chooser.pages(
            for: items,
            viewport: landscapeViewport,
            preference: .automatic
        )
        let portraitPages = chooser.pages(
            for: items,
            viewport: PixelSize(width: 1_024, height: 1_366),
            preference: .automatic
        )

        XCTAssertEqual(landscapePages.count, 1)
        XCTAssertEqual(landscapePages.first?.kind, .pairedPortraits)
        XCTAssertEqual(portraitPages.count, 2)
        XCTAssertTrue(portraitPages.allSatisfy { $0.kind != .pairedPortraits })
    }

    func testWideResizePairsTheAnchoredFirstPhotoInALargeCompatibleReel() throws {
        let items = (0..<30).map { index in
            fixture(id: "portrait-\(index)", width: 1_000, height: 1_500)
        }

        let compactPages = chooser.pages(
            for: items,
            viewport: PixelSize(width: 520, height: 760),
            preference: .automatic
        )
        let widePages = chooser.pages(
            for: items,
            viewport: landscapeViewport,
            preference: .automatic
        )

        XCTAssertEqual(compactPages.first?.placements.map(\.photoID), ["portrait-0"])
        XCTAssertEqual(widePages.first?.kind, .pairedPortraits)
        XCTAssertEqual(
            try XCTUnwrap(widePages.first).placements.map(\.photoID),
            ["portrait-0", "portrait-1"]
        )
    }

    func testFillRecomputesTheCropForTheResizedWindow() throws {
        let item = fixture(id: "square", width: 1_200, height: 1_200)

        let wideCrop = try XCTUnwrap(
            chooser.pages(
                for: [item],
                viewport: landscapeViewport,
                preference: .fill
            ).first?.placements.first?.sourceCrop
        )
        let tallCrop = try XCTUnwrap(
            chooser.pages(
                for: [item],
                viewport: PixelSize(width: 700, height: 1_100),
                preference: .fill
            ).first?.placements.first?.sourceCrop
        )

        XCTAssertLessThan(wideCrop.height, 1)
        XCTAssertEqual(wideCrop.width, 1, accuracy: 0.000_001)
        XCTAssertLessThan(tallCrop.width, 1)
        XCTAssertEqual(tallCrop.height, 1, accuracy: 0.000_001)
        XCTAssertNotEqual(wideCrop, tallCrop)
    }

    func testCompactViewportAlwaysUsesSinglePhotoPages() {
        let items = [
            fixture(id: "portrait-a", width: 1_000, height: 1_500),
            fixture(id: "portrait-b", width: 1_000, height: 1_500),
            fixture(id: "portrait-c", width: 1_000, height: 1_500),
        ]
        let compactViewport = PixelSize(width: 520, height: 760)

        let automaticPages = chooser.pages(
            for: items,
            viewport: compactViewport,
            preference: .automatic,
            allowsAutomaticMosaic: true
        )
        let mosaicPages = chooser.pages(
            for: items,
            viewport: compactViewport,
            preference: .mosaic,
            allowsAutomaticMosaic: true
        )

        XCTAssertEqual(automaticPages.count, items.count)
        XCTAssertEqual(mosaicPages.count, items.count)
        XCTAssertTrue((automaticPages + mosaicPages).allSatisfy {
            $0.placements.count == 1
        })
    }

    func testAutomaticStacksCompatibleLandscapesInTallViewport() throws {
        let first = fixture(id: "landscape-a", width: 1_600, height: 1_000)
        let second = fixture(id: "landscape-b", width: 1_800, height: 1_000)

        let page = try XCTUnwrap(
            chooser.pages(
                for: [first, second],
                viewport: PixelSize(width: 820, height: 1_180),
                preference: .automatic
            ).first
        )

        XCTAssertEqual(page.kind, .stackedLandscapes)
        XCTAssertEqual(page.placements.count, 2)
        XCTAssertEqual(page.placements[0].screenFrame.maxY, page.placements[1].screenFrame.minY)
    }

    func testVeryTallWindowStacksThreeLandscapesWithoutPostageStampCells() throws {
        let items = (0..<3).map { index in
            fixture(id: "landscape-\(index)", width: 1_600, height: 1_000)
        }

        let page = try XCTUnwrap(
            chooser.pages(
                for: items,
                viewport: PixelSize(width: 500, height: 1_000),
                preference: .automatic
            ).first
        )

        XCTAssertEqual(page.kind, .stackedLandscapes)
        XCTAssertEqual(page.placements.count, 3)
        XCTAssertEqual(page.placements.map(\.photoID), items.map(\.id))
        XCTAssertTrue(page.placements.allSatisfy {
            $0.screenFrame.height >= 0.33 && $0.sourceCrop.isWithinUnitBounds
        })
    }

    func testExtremelyTallWindowCapsLandscapeStackAtFour() throws {
        let items = (0..<5).map { index in
            fixture(id: "landscape-\(index)", width: 1_600, height: 1_000)
        }

        let page = try XCTUnwrap(
            chooser.pages(
                for: items,
                viewport: PixelSize(width: 360, height: 1_024),
                preference: .automatic
            ).first
        )

        XCTAssertEqual(page.kind, .stackedLandscapes)
        XCTAssertEqual(page.placements.count, 4)
        XCTAssertEqual(page.placements.map(\.photoID), Array(items.prefix(4)).map(\.id))
        XCTAssertTrue(page.placements.allSatisfy {
            $0.screenFrame.height == 0.25 && $0.sourceCrop.isWithinUnitBounds
        })
    }

    func testShortNarrowWindowKeepsSinglePhotoInsteadOfTinyStackCells() {
        let items = (0..<4).map { index in
            fixture(id: "landscape-\(index)", width: 1_600, height: 1_000)
        }

        let pages = chooser.pages(
            for: items,
            viewport: PixelSize(width: 360, height: 600),
            preference: .automatic
        )

        XCTAssertTrue(pages.allSatisfy { $0.placements.count == 1 })
    }

    func testVeryTallStackFallsBackToSmallerSafeGroupForImportantContent() throws {
        let anchored = fixture(id: "anchored", width: 1_600, height: 1_000)
        let unsafeFourth = fixture(
            id: "unsafe-fourth",
            width: 1_600,
            height: 1_000,
            importantRects: [
                NormalizedRect(x: 0.05, y: 0.2, width: 0.12, height: 0.2),
                NormalizedRect(x: 0.83, y: 0.2, width: 0.12, height: 0.2),
            ]
        )
        let items = [
            anchored,
            fixture(id: "landscape-1", width: 1_600, height: 1_000),
            fixture(id: "landscape-2", width: 1_600, height: 1_000),
            unsafeFourth,
        ]

        let page = try XCTUnwrap(
            chooser.pages(
                for: items,
                viewport: PixelSize(width: 360, height: 1_024),
                preference: .automatic
            ).first
        )

        XCTAssertEqual(page.placements.count, 3)
        XCTAssertTrue(page.placements.contains { $0.photoID == anchored.id })
        XCTAssertTrue(page.placements.allSatisfy { $0.sourceCrop.isWithinUnitBounds })
    }

    func testAutomaticFindsACompatiblePhotoWithinBoundedLookahead() throws {
        let portraitA = fixture(id: "portrait-a", width: 1_000, height: 1_500)
        let landscape = fixture(id: "landscape", width: 1_600, height: 1_000)
        let portraitB = fixture(id: "portrait-b", width: 1_000, height: 1_500)

        let pages = chooser.pages(
            for: [portraitA, landscape, portraitB],
            viewport: landscapeViewport,
            preference: .automatic
        )

        let pair = try XCTUnwrap(pages.first)
        XCTAssertEqual(pair.kind, .pairedPortraits)
        XCTAssertEqual(pair.placements.map(\.photoID), ["portrait-a", "portrait-b"])
        XCTAssertEqual(pages.last?.placements.first?.photoID, "landscape")
    }

    func testAutomaticMosaicIsRareEntitledAndEventBound() {
        let eventDate = Date(timeIntervalSince1970: 1_700_000_000)
        let items = (0..<20).map { index in
            fixture(
                id: "photo-\(index)",
                width: 1_600,
                height: 1_200,
                creationDate: eventDate.addingTimeInterval(Double(index))
            )
        }

        let freePages = chooser.pages(
            for: items,
            viewport: PixelSize(width: 1_200, height: 1_000),
            preference: .automatic,
            allowsAutomaticMosaic: false
        )
        let entitledPages = chooser.pages(
            for: items,
            viewport: PixelSize(width: 1_200, height: 1_000),
            preference: .automatic,
            allowsAutomaticMosaic: true
        )

        XCTAssertFalse(freePages.contains(where: { $0.kind == .mosaic }))
        XCTAssertEqual(entitledPages.filter { $0.kind == .mosaic }.count, 1)
        XCTAssertEqual(
            entitledPages.first(where: { $0.kind == .mosaic })?.placements.count,
            4
        )
    }

    func testAutomaticCompositionRemainsOccasionalInALargePortraitReel() {
        let items = (0..<30).map { index in
            fixture(id: "portrait-\(index)", width: 1_000, height: 1_500)
        }

        let pages = chooser.pages(
            for: items,
            viewport: landscapeViewport,
            preference: .automatic
        )
        let pairCount = pages.filter { $0.kind == .pairedPortraits }.count

        XCTAssertGreaterThan(pairCount, 0)
        XCTAssertLessThanOrEqual(Double(pairCount) / Double(pages.count), 0.25)
        XCTAssertGreaterThanOrEqual(
            pages.filter { $0.placements.count == 1 }.count,
            Int(Double(pages.count) * 0.7)
        )
    }

    func testAnchorResolverKeepsTheFeaturedPhotoAcrossReflow() throws {
        let items = [
            fixture(id: "portrait-a", width: 1_000, height: 1_500),
            fixture(id: "portrait-b", width: 1_000, height: 1_500),
            fixture(id: "portrait-c", width: 1_000, height: 1_500),
        ]
        let widePages = chooser.pages(
            for: items,
            viewport: landscapeViewport,
            preference: .automatic
        )
        let compactPages = chooser.pages(
            for: items,
            viewport: PixelSize(width: 520, height: 760),
            preference: .automatic
        )

        let compactIndex = FramePageAnchorResolver.index(
            preserving: "portrait-b",
            in: compactPages,
            fallbackIndex: 0
        )
        let wideIndex = FramePageAnchorResolver.index(
            preserving: "portrait-b",
            in: widePages,
            fallbackIndex: compactIndex
        )

        XCTAssertEqual(compactIndex, 1)
        XCTAssertTrue(try XCTUnwrap(widePages[safe: wideIndex]).placements.contains {
            $0.photoID == "portrait-b"
        })
    }

    func testMotionZoomRequiresSlackAroundImportantContent() {
        let crop = NormalizedRect(x: 0.2, y: 0.1, width: 0.6, height: 0.8)
        let placement = FrameLayoutPlacement(
            id: "motion",
            photoID: "photo",
            screenFrame: .unit,
            sourceCrop: crop,
            contentMode: .crop
        )

        XCTAssertTrue(
            FrameMotionSafety.canZoom(
                placement: placement,
                importantRects: [
                    NormalizedRect(x: 0.35, y: 0.3, width: 0.2, height: 0.2),
                ],
                maximumScale: 1.025
            )
        )
        XCTAssertFalse(
            FrameMotionSafety.canZoom(
                placement: placement,
                importantRects: [
                    NormalizedRect(x: 0.2, y: 0.3, width: 0.2, height: 0.2),
                ],
                maximumScale: 1.025
            )
        )
    }

    func testLivingPhotoMotionPlanIsDeterministicAndFaceSafe() throws {
        let crop = NormalizedRect(x: 0.1, y: 0.12, width: 0.8, height: 0.76)
        let placement = FrameLayoutPlacement(
            id: "motion",
            photoID: "photo",
            screenFrame: .unit,
            sourceCrop: crop,
            contentMode: .crop
        )
        let importantRects = [
            NormalizedRect(x: 0.38, y: 0.34, width: 0.18, height: 0.2),
        ]

        let first = try XCTUnwrap(
            FramePhotoMotionPlanner.plan(
                photoID: "stable-photo-id",
                placement: placement,
                importantRects: importantRects
            )
        )
        let second = FramePhotoMotionPlanner.plan(
            photoID: "stable-photo-id",
            placement: placement,
            importantRects: importantRects
        )

        XCTAssertEqual(first, second)
        XCTAssertTrue(
            FrameMotionSafety.canApply(
                state: first.start,
                placement: placement,
                importantRects: importantRects
            )
        )
        XCTAssertTrue(
            FrameMotionSafety.canApply(
                state: first.end,
                placement: placement,
                importantRects: importantRects
            )
        )
        XCTAssertNotEqual(first.start, first.end)
        XCTAssertGreaterThan(max(first.start.scale, first.end.scale), 1.03)
    }

    func testLivingPhotoMotionUsesOnlyASubtleCenteredZoomForSafeFitPlacement() throws {
        let placement = FrameLayoutPlacement(
            id: "fit",
            photoID: "photo",
            screenFrame: .unit,
            sourceCrop: .unit,
            contentMode: .fit
        )

        let plan = try XCTUnwrap(
            FramePhotoMotionPlanner.plan(
                photoID: "photo",
                placement: placement,
                importantRects: []
            )
        )
        XCTAssertNotEqual(plan.start, plan.end)
        XCTAssertLessThanOrEqual(max(plan.start.scale, plan.end.scale), 1.04)
        XCTAssertEqual(plan.start.offsetX, 0)
        XCTAssertEqual(plan.start.offsetY, 0)
        XCTAssertEqual(plan.end.offsetX, 0)
        XCTAssertEqual(plan.end.offsetY, 0)
    }

    func testLivingPhotoMotionDeclinesFitZoomWhenImportantContentTouchesAnEdge() {
        let placement = FrameLayoutPlacement(
            id: "fit-edge",
            photoID: "photo",
            screenFrame: .unit,
            sourceCrop: .unit,
            contentMode: .fit
        )

        XCTAssertNil(
            FramePhotoMotionPlanner.plan(
                photoID: "photo",
                placement: placement,
                importantRects: [
                    NormalizedRect(x: 0, y: 0.3, width: 0.2, height: 0.2),
                ]
            )
        )
    }

    func testLivingPhotoMotionPolicyHonorsReduceMotionResizeAndCalmCollages() {
        XCTAssertTrue(
            FramePhotoMotionPolicy.shouldAnimate(
                isFrameMode: true,
                isPlaying: true,
                photoCount: 1,
                reduceMotionEnabled: false,
                isInteractingWithResize: false
            )
        )
        XCTAssertFalse(
            FramePhotoMotionPolicy.shouldAnimate(
                isFrameMode: true,
                isPlaying: true,
                photoCount: 1,
                reduceMotionEnabled: true,
                isInteractingWithResize: false
            )
        )
        XCTAssertFalse(
            FramePhotoMotionPolicy.shouldAnimate(
                isFrameMode: true,
                isPlaying: true,
                photoCount: 1,
                reduceMotionEnabled: false,
                isInteractingWithResize: true
            )
        )
        XCTAssertFalse(
            FramePhotoMotionPolicy.shouldAnimate(
                isFrameMode: true,
                isPlaying: true,
                photoCount: 2,
                reduceMotionEnabled: false,
                isInteractingWithResize: false
            )
        )
    }

    func testMosaicRejectsFitTilesWithExcessiveBlankSpace() {
        let edgeContent = [
            NormalizedRect(x: 0.01, y: 0.2, width: 0.08, height: 0.2),
            NormalizedRect(x: 0.91, y: 0.2, width: 0.08, height: 0.2),
        ]
        let items = (0..<4).map { index in
            fixture(
                id: "panorama-\(index)",
                width: 4_000,
                height: 1_000,
                importantRects: edgeContent
            )
        }

        let pages = chooser.pages(
            for: items,
            viewport: landscapeViewport,
            preference: .mosaic
        )

        XCTAssertEqual(pages.count, items.count)
        XCTAssertTrue(pages.allSatisfy { $0.placements.count == 1 })
    }

    func testEveryMosaicFitTileMeetsTheOccupancyThreshold() throws {
        let edgeContent = [
            NormalizedRect(x: 0.2, y: 0.01, width: 0.2, height: 0.08),
            NormalizedRect(x: 0.2, y: 0.91, width: 0.2, height: 0.08),
        ]
        let items = (0..<4).map { index in
            fixture(
                id: "slightly-landscape-\(index)",
                width: 1_050,
                height: 1_000,
                importantRects: edgeContent
            )
        }

        let pages = chooser.pages(
            for: items,
            viewport: PixelSize(width: 1_200, height: 900),
            preference: .mosaic
        )
        let fitPlacements = pages.flatMap(\.placements).filter {
            $0.contentMode == .fit
        }

        XCTAssertEqual(pages.first?.kind, .mosaic)
        XCTAssertEqual(pages.first?.placements.count, 4)
        XCTAssertFalse(fitPlacements.isEmpty)
        for placement in fitPlacements {
            let item = try XCTUnwrap(items.first { $0.id == placement.photoID })
            let cellAspect = (1_200.0 / 900.0)
                * placement.screenFrame.width / placement.screenFrame.height
            XCTAssertGreaterThanOrEqual(
                FrameLayoutOccupancy.fittedPhotoFraction(
                    photoAspectRatio: item.pixelSize.aspectRatio,
                    cellAspectRatio: cellAspect
                ),
                FrameLayoutOccupancy.minimumMultiPhotoPhotoFraction
            )
        }
    }

    func testMosaicCreatesBoundedNonOverlappingFourPhotoGrid() throws {
        let items = (1...5).map { index in
            fixture(id: "photo-\(index)", width: 1_600, height: 1_200)
        }

        let pages = chooser.pages(
            for: items,
            viewport: landscapeViewport,
            preference: .mosaic
        )

        XCTAssertEqual(pages.count, 2)
        XCTAssertEqual(pages.first?.kind, .mosaic)
        XCTAssertEqual(pages.first?.placements.count, 4)
        XCTAssertEqual(pages.last?.placements.count, 1)
        let placements = try XCTUnwrap(pages.first?.placements)
        XCTAssertTrue(placements.allSatisfy {
            $0.screenFrame.isWithinUnitBounds && $0.sourceCrop.isWithinUnitBounds
        })
        for firstIndex in placements.indices {
            for secondIndex in placements.indices where secondIndex > firstIndex {
                let first = placements[firstIndex].screenFrame
                let second = placements[secondIndex].screenFrame
                let overlaps = first.minX < second.maxX
                    && first.maxX > second.minX
                    && first.minY < second.maxY
                    && first.maxY > second.minY
                XCTAssertFalse(overlaps)
            }
        }
    }

    private func fixture(
        id: String,
        width: Int,
        height: Int,
        importantRects: [NormalizedRect] = [],
        creationDate: Date? = nil
    ) -> FrameLayoutItem {
        FrameLayoutItem(
            id: id,
            pixelSize: PixelSize(width: width, height: height),
            importantRects: importantRects,
            creationDate: creationDate
        )
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
