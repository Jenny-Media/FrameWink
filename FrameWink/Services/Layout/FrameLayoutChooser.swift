import Foundation

protocol FrameLayoutChoosing {
    func pages(
        for items: [FrameLayoutItem],
        viewport: PixelSize,
        preference: FrameLayoutPreference,
        allowsAutomaticMosaic: Bool
    ) -> [FramePage]
}

extension FrameLayoutChoosing {
    func pages(
        for items: [FrameLayoutItem],
        viewport: PixelSize,
        preference: FrameLayoutPreference
    ) -> [FramePage] {
        pages(
            for: items,
            viewport: viewport,
            preference: preference,
            allowsAutomaticMosaic: false
        )
    }
}

struct FrameLayoutChooser: FrameLayoutChoosing {
    private let compactMinimumWidth = 560
    private let compactMinimumHeight = 500
    private let compactPortraitMaximumAspectRatio = 0.62
    private let compactImportantCenterTolerance = 0.18
    private let compactImportantEdgeInset = 0.07
    private let compactSingleMinimumSourceFraction = 0.70
    private let multiPhotoMinimumSourceFraction = 0.68
    private let largeMinimumDimension = 900
    private let compatibilityLookahead = 4
    private let nearbyEventInterval: TimeInterval = 12 * 60 * 60

    func pages(
        for items: [FrameLayoutItem],
        viewport: PixelSize,
        preference: FrameLayoutPreference,
        allowsAutomaticMosaic: Bool = false
    ) -> [FramePage] {
        guard viewport.width > 0, viewport.height > 0 else { return [] }

        let usesCompactLayout = isCompact(viewport)
        if preference == .mosaic, !usesCompactLayout {
            return mosaicPreferredPages(for: items, viewport: viewport)
        }

        var result: [FramePage] = []
        var remaining = items
        let singlePreference: FrameLayoutPreference = preference == .mosaic
            ? .automatic
            : preference

        while let first = remaining.first {
            if preference == .automatic,
               allowsAutomaticMosaic,
               min(viewport.width, viewport.height) >= largeMinimumDimension,
               result.count % 20 == 12,
               let group = nearbyMosaicGroup(in: remaining),
               let mosaic = mosaicPage(items: group, viewport: viewport) {
                result.append(mosaic)
                let groupIDs = Set(group.map(\.id))
                remaining.removeAll(where: { groupIDs.contains($0.id) })
                continue
            }

            if preference == .automatic,
               (!usesCompactLayout || stackedPhotoCapacity(for: viewport) >= 3),
               (items.count <= 4 || result.isEmpty || result.count % 5 == 3),
               let page = automaticComposition(
                   anchoredBy: first,
                   in: remaining,
                   viewport: viewport
               ) {
                    result.append(page)
                    let composedIDs = Set(page.placements.map(\.photoID))
                    remaining.removeAll(where: { composedIDs.contains($0.id) })
                    continue
            }

            result.append(
                singlePage(
                    item: first,
                    viewport: viewport,
                    preference: singlePreference
                )
            )
            remaining.removeFirst()
        }

        return result
    }

    private func mosaicPreferredPages(
        for items: [FrameLayoutItem],
        viewport: PixelSize
    ) -> [FramePage] {
        var pages: [FramePage] = []
        var remaining = items

        while let first = remaining.first {
            let largestGroup = min(remaining.count, 4)
            var composedPage: FramePage?
            if largestGroup >= 2 {
                for groupSize in stride(from: largestGroup, through: 2, by: -1) {
                    let group = Array(remaining.prefix(groupSize))
                    if let mosaic = mosaicPage(items: group, viewport: viewport) {
                        composedPage = mosaic
                        break
                    }
                }
            }

            if let composedPage {
                pages.append(composedPage)
                let composedIDs = Set(composedPage.placements.map(\.photoID))
                remaining.removeAll(where: { composedIDs.contains($0.id) })
            } else {
                pages.append(
                    singlePage(
                        item: first,
                        viewport: viewport,
                        preference: .automatic
                    )
                )
                remaining.removeFirst()
            }
        }
        return pages
    }

    private func automaticComposition(
        anchoredBy first: FrameLayoutItem,
        in items: [FrameLayoutItem],
        viewport: PixelSize
    ) -> FramePage? {
        let stackItems = compatibleStackItems(
            anchoredBy: first,
            in: items,
            viewport: viewport
        )
        if stackItems.count >= 2 {
            for groupSize in stride(from: stackItems.count, through: 2, by: -1) {
                if let stack = stackedPage(
                    items: Array(stackItems.prefix(groupSize)),
                    viewport: viewport
                ) {
                    return stack
                }
            }
        }
        guard let matchIndex = compatibleMatchIndex(
            for: first,
            in: items,
            viewport: viewport
        ) else {
            return nil
        }
        let second = items[matchIndex]
        return pairedPage(first: first, second: second, viewport: viewport)
            ?? stackedPage(items: [first, second], viewport: viewport)
    }

    private func compatibleMatchIndex(
        for first: FrameLayoutItem,
        in items: [FrameLayoutItem],
        viewport: PixelSize
    ) -> Int? {
        guard items.count > 1 else { return nil }
        let upperBound = min(items.count - 1, compatibilityLookahead)
        return (1...upperBound).first { index in
            let candidate = items[index]
            guard belongsToNearbyEvent(first, candidate) else { return false }
            return pairedPage(first: first, second: candidate, viewport: viewport) != nil
                || stackedPage(items: [first, candidate], viewport: viewport) != nil
        }
    }

    private func compatibleStackItems(
        anchoredBy first: FrameLayoutItem,
        in items: [FrameLayoutItem],
        viewport: PixelSize
    ) -> [FrameLayoutItem] {
        let capacity = stackedPhotoCapacity(for: viewport)
        guard capacity > 1,
              first.pixelSize.aspectRatio >= 1.15 else {
            return []
        }
        var matches = [first]
        for candidate in items.dropFirst().prefix(compatibilityLookahead + 2) {
            guard matches.count < capacity else { break }
            guard belongsToNearbyEvent(first, candidate),
                  candidate.pixelSize.aspectRatio >= 1.15 else {
                continue
            }
            matches.append(candidate)
        }
        return matches.count >= 2 ? matches : []
    }

    private func stackedPhotoCapacity(for viewport: PixelSize) -> Int {
        guard viewport.aspectRatio <= 0.85, viewport.height >= 500 else { return 1 }
        let idealCount = Int((1.5 / viewport.aspectRatio).rounded())
        let heightBound = max(viewport.height / 220, 1)
        return min(max(idealCount, 2), min(heightBound, 4))
    }

    private func nearbyMosaicGroup(in items: [FrameLayoutItem]) -> [FrameLayoutItem]? {
        guard items.count >= 3, let first = items.first, first.creationDate != nil else {
            return nil
        }
        var group = [first]
        for candidate in items.dropFirst().prefix(compatibilityLookahead + 1)
            where belongsToNearbyEvent(first, candidate) {
            group.append(candidate)
            if group.count == 4 { break }
        }
        return group.count >= 3 ? group : nil
    }

    private func belongsToNearbyEvent(
        _ first: FrameLayoutItem,
        _ second: FrameLayoutItem
    ) -> Bool {
        switch (first.creationDate, second.creationDate) {
        case let (firstDate?, secondDate?):
            return abs(firstDate.timeIntervalSince(secondDate)) <= nearbyEventInterval
        case (nil, nil):
            return true
        default:
            return false
        }
    }

    private func mosaicPage(
        items: [FrameLayoutItem],
        viewport: PixelSize
    ) -> FramePage? {
        guard items.count >= 2 else { return nil }
        let frames: [NormalizedRect]
        switch items.count {
        case 2:
            frames = [
                NormalizedRect(x: 0, y: 0, width: 0.5, height: 1),
                NormalizedRect(x: 0.5, y: 0, width: 0.5, height: 1),
            ]
        case 3:
            frames = [
                NormalizedRect(x: 0, y: 0, width: 0.58, height: 1),
                NormalizedRect(x: 0.58, y: 0, width: 0.42, height: 0.5),
                NormalizedRect(x: 0.58, y: 0.5, width: 0.42, height: 0.5),
            ]
        default:
            frames = [
                NormalizedRect(x: 0, y: 0, width: 0.5, height: 0.5),
                NormalizedRect(x: 0.5, y: 0, width: 0.5, height: 0.5),
                NormalizedRect(x: 0, y: 0.5, width: 0.5, height: 0.5),
                NormalizedRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5),
            ]
        }

        var placements: [FrameLayoutPlacement] = []
        for (item, frame) in zip(items, frames) {
            let cellAspect = viewport.aspectRatio * frame.width / frame.height
            guard let placement = multiPhotoPlacement(
                item: item,
                frame: frame,
                cellAspectRatio: cellAspect,
                id: "mosaic:\(item.id)"
            ) else {
                return nil
            }
            placements.append(placement)
        }
        return FramePage(
            id: "mosaic:" + items.map(\.id).joined(separator: ":"),
            kind: .mosaic,
            placements: placements
        )
    }

    private func multiPhotoPlacement(
        item: FrameLayoutItem,
        frame: NormalizedRect,
        cellAspectRatio: Double,
        id: String
    ) -> FrameLayoutPlacement? {
        if let crop = safeCrop(for: item, targetAspectRatio: cellAspectRatio),
           crop.width * crop.height >= multiPhotoMinimumSourceFraction {
            return FrameLayoutPlacement(
                id: id,
                photoID: item.id,
                screenFrame: frame,
                sourceCrop: crop,
                contentMode: .crop
            )
        }

        let occupancy = FrameLayoutOccupancy.fittedPhotoFraction(
            photoAspectRatio: item.pixelSize.aspectRatio,
            cellAspectRatio: cellAspectRatio
        )
        guard occupancy >= FrameLayoutOccupancy.minimumMultiPhotoPhotoFraction else {
            return nil
        }
        return FrameLayoutPlacement(
            id: id,
            photoID: item.id,
            screenFrame: frame,
            sourceCrop: .unit,
            contentMode: .fit
        )
    }

    private func singlePage(
        item: FrameLayoutItem,
        viewport: PixelSize,
        preference: FrameLayoutPreference
    ) -> FramePage {
        let requestedFill = preference != .fit
        let proposedCrop = requestedFill
            ? safeCrop(for: item, targetAspectRatio: viewport.aspectRatio)
            : nil
        let crop = proposedCrop.flatMap { crop in
            guard isCompact(viewport) else { return crop }
            let retainedSourceFraction = crop.width * crop.height
            return retainedSourceFraction >= compactSingleMinimumSourceFraction
                ? crop
                : nil
        }
        let usesFill = requestedFill && crop != nil
        let kind: FrameLayoutKind = usesFill ? .singleFill : .singleFit

        return FramePage(
            id: "single:\(item.id):\(kind.rawValue)",
            kind: kind,
            placements: [
                FrameLayoutPlacement(
                    id: "single:\(item.id)",
                    photoID: item.id,
                    screenFrame: .unit,
                    sourceCrop: crop ?? .unit,
                    contentMode: usesFill ? .crop : .fit
                ),
            ]
        )
    }

    private func isCompact(_ viewport: PixelSize) -> Bool {
        viewport.width < compactMinimumWidth
            || viewport.height < compactMinimumHeight
    }

    private func pairedPage(
        first: FrameLayoutItem,
        second: FrameLayoutItem,
        viewport: PixelSize
    ) -> FramePage? {
        guard viewport.aspectRatio >= 1.18,
              first.pixelSize.aspectRatio > 0,
              second.pixelSize.aspectRatio > 0,
              first.pixelSize.aspectRatio <= 0.9,
              second.pixelSize.aspectRatio <= 0.9 else {
            return nil
        }

        let cellAspect = (Double(viewport.width) / 2) / Double(viewport.height)
        guard let firstCrop = safeCrop(for: first, targetAspectRatio: cellAspect),
              let secondCrop = safeCrop(for: second, targetAspectRatio: cellAspect) else {
            return nil
        }

        return FramePage(
            id: "pair:\(first.id):\(second.id)",
            kind: .pairedPortraits,
            placements: [
                FrameLayoutPlacement(
                    id: "pair-left:\(first.id)",
                    photoID: first.id,
                    screenFrame: NormalizedRect(x: 0, y: 0, width: 0.5, height: 1),
                    sourceCrop: firstCrop,
                    contentMode: .crop
                ),
                FrameLayoutPlacement(
                    id: "pair-right:\(second.id)",
                    photoID: second.id,
                    screenFrame: NormalizedRect(x: 0.5, y: 0, width: 0.5, height: 1),
                    sourceCrop: secondCrop,
                    contentMode: .crop
                ),
            ]
        )
    }

    private func stackedPage(
        items: [FrameLayoutItem],
        viewport: PixelSize
    ) -> FramePage? {
        guard items.count >= 2,
              items.count <= stackedPhotoCapacity(for: viewport),
              items.allSatisfy({ $0.pixelSize.aspectRatio >= 1.15 }) else {
            return nil
        }

        let count = Double(items.count)
        let cellAspect = viewport.aspectRatio * count
        let crops = items.map { safeCrop(for: $0, targetAspectRatio: cellAspect) }
        guard crops.allSatisfy({ $0 != nil }) else {
            return nil
        }

        return FramePage(
            id: "stack:" + items.map(\.id).joined(separator: ":"),
            kind: .stackedLandscapes,
            placements: zip(items.indices, zip(items, crops)).map { index, pair in
                let (item, crop) = pair
                return FrameLayoutPlacement(
                    id: "stack-\(index):\(item.id)",
                    photoID: item.id,
                    screenFrame: NormalizedRect(
                        x: 0,
                        y: Double(index) / count,
                        width: 1,
                        height: 1 / count
                    ),
                    sourceCrop: crop ?? .unit,
                    contentMode: .crop
                )
            }
        )
    }

    private func safeCrop(
        for item: FrameLayoutItem,
        targetAspectRatio: Double
    ) -> NormalizedRect? {
        let imageAspect = item.pixelSize.aspectRatio
        guard imageAspect > 0, targetAspectRatio > 0 else { return nil }

        let cropWidth: Double
        let cropHeight: Double
        if imageAspect > targetAspectRatio {
            cropWidth = targetAspectRatio / imageAspect
            cropHeight = 1
        } else {
            cropWidth = 1
            cropHeight = imageAspect / targetAspectRatio
        }

        guard let importantBounds = importantBounds(item.importantRects) else {
            return NormalizedRect(
                x: (1 - cropWidth) / 2,
                y: (1 - cropHeight) / 2,
                width: cropWidth,
                height: cropHeight
            )
        }

        let tolerance = 0.000_001
        guard importantBounds.width <= cropWidth + tolerance,
              importantBounds.height <= cropHeight + tolerance,
              let originX = safeOrigin(
                  cropLength: cropWidth,
                  importantMinimum: importantBounds.minX,
                  importantMaximum: importantBounds.maxX
              ),
              let originY = safeOrigin(
                  cropLength: cropHeight,
                  importantMinimum: importantBounds.minY,
                  importantMaximum: importantBounds.maxY
              ) else {
            return nil
        }

        let crop = NormalizedRect(
            x: originX,
            y: originY,
            width: cropWidth,
            height: cropHeight
        )
        guard compactCropKeepsImportantContentComfortablyPlaced(
            importantBounds,
            crop: crop,
            targetAspectRatio: targetAspectRatio
        ) else {
            return nil
        }
        return crop
    }

    private func compactCropKeepsImportantContentComfortablyPlaced(
        _ importantBounds: NormalizedRect,
        crop: NormalizedRect,
        targetAspectRatio: Double
    ) -> Bool {
        guard targetAspectRatio <= compactPortraitMaximumAspectRatio else {
            return true
        }

        let tolerance = 0.000_001
        if crop.width < 1 - tolerance {
            let minimum = (importantBounds.minX - crop.minX) / crop.width
            let maximum = (importantBounds.maxX - crop.minX) / crop.width
            let center = (importantBounds.midX - crop.minX) / crop.width
            guard minimum >= compactImportantEdgeInset,
                  maximum <= 1 - compactImportantEdgeInset,
                  abs(center - 0.5) <= compactImportantCenterTolerance else {
                return false
            }
        }

        if crop.height < 1 - tolerance {
            let minimum = (importantBounds.minY - crop.minY) / crop.height
            let maximum = (importantBounds.maxY - crop.minY) / crop.height
            let center = (importantBounds.midY - crop.minY) / crop.height
            guard minimum >= compactImportantEdgeInset,
                  maximum <= 1 - compactImportantEdgeInset,
                  abs(center - 0.5) <= compactImportantCenterTolerance else {
                return false
            }
        }

        return true
    }

    private func safeOrigin(
        cropLength: Double,
        importantMinimum: Double,
        importantMaximum: Double
    ) -> Double? {
        let minimumOrigin = max(0, importantMaximum - cropLength)
        let maximumOrigin = min(1 - cropLength, importantMinimum)
        guard minimumOrigin <= maximumOrigin else { return nil }

        let centeredOrigin = (importantMinimum + importantMaximum - cropLength) / 2
        return min(max(centeredOrigin, minimumOrigin), maximumOrigin)
    }

    private func importantBounds(_ rects: [NormalizedRect]) -> NormalizedRect? {
        let validRects = rects
            .map { $0.clampedToUnitBounds() }
            .filter { $0.width > 0 && $0.height > 0 }
        guard let first = validRects.first else { return nil }

        return validRects.dropFirst().reduce(first) { partial, rect in
            let minX = min(partial.minX, rect.minX)
            let minY = min(partial.minY, rect.minY)
            let maxX = max(partial.maxX, rect.maxX)
            let maxY = max(partial.maxY, rect.maxY)
            return NormalizedRect(
                x: minX,
                y: minY,
                width: maxX - minX,
                height: maxY - minY
            )
        }
    }
}
