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

        let isCompact = viewport.width < compactMinimumWidth
            || viewport.height < compactMinimumHeight
        if preference == .mosaic, !isCompact {
            return stride(from: 0, to: items.count, by: 4).map { index in
                mosaicPage(
                    items: Array(items[index..<min(index + 4, items.count)]),
                    viewport: viewport
                )
            }
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
               let group = nearbyMosaicGroup(in: remaining) {
                result.append(mosaicPage(items: group, viewport: viewport))
                let groupIDs = Set(group.map(\.id))
                remaining.removeAll(where: { groupIDs.contains($0.id) })
                continue
            }

            if preference == .automatic, !isCompact,
               (items.count <= 4 || result.isEmpty || result.count % 5 == 3),
               let matchIndex = compatibleMatchIndex(
                   for: first,
                   in: remaining,
                   viewport: viewport
               ) {
                let second = remaining[matchIndex]
                if let page = pairedPage(
                    first: first,
                    second: second,
                    viewport: viewport
                ) ?? stackedPage(
                    first: first,
                    second: second,
                    viewport: viewport
                ) {
                    result.append(page)
                    remaining.remove(at: matchIndex)
                    remaining.removeFirst()
                    continue
                }
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
                || stackedPage(first: first, second: candidate, viewport: viewport) != nil
        }
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
    ) -> FramePage {
        let frames: [NormalizedRect]
        switch items.count {
        case 1:
            frames = [.unit]
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

        let placements = zip(items, frames).map { item, frame in
            let cellAspect = viewport.aspectRatio * frame.width / frame.height
            let crop = safeCrop(for: item, targetAspectRatio: cellAspect)
            return FrameLayoutPlacement(
                id: "mosaic:\(item.id)",
                photoID: item.id,
                screenFrame: frame,
                sourceCrop: crop ?? .unit,
                contentMode: crop == nil ? .fit : .crop
            )
        }
        return FramePage(
            id: "mosaic:" + items.map(\.id).joined(separator: ":"),
            kind: .mosaic,
            placements: placements
        )
    }

    private func singlePage(
        item: FrameLayoutItem,
        viewport: PixelSize,
        preference: FrameLayoutPreference
    ) -> FramePage {
        let requestedFill = preference != .fit
        let crop = requestedFill
            ? safeCrop(for: item, targetAspectRatio: viewport.aspectRatio)
            : nil
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
        first: FrameLayoutItem,
        second: FrameLayoutItem,
        viewport: PixelSize
    ) -> FramePage? {
        guard viewport.aspectRatio <= 0.85,
              first.pixelSize.aspectRatio >= 1.15,
              second.pixelSize.aspectRatio >= 1.15 else {
            return nil
        }

        let cellAspect = Double(viewport.width) / (Double(viewport.height) / 2)
        guard let firstCrop = safeCrop(for: first, targetAspectRatio: cellAspect),
              let secondCrop = safeCrop(for: second, targetAspectRatio: cellAspect) else {
            return nil
        }

        return FramePage(
            id: "stack:\(first.id):\(second.id)",
            kind: .stackedLandscapes,
            placements: [
                FrameLayoutPlacement(
                    id: "stack-top:\(first.id)",
                    photoID: first.id,
                    screenFrame: NormalizedRect(x: 0, y: 0, width: 1, height: 0.5),
                    sourceCrop: firstCrop,
                    contentMode: .crop
                ),
                FrameLayoutPlacement(
                    id: "stack-bottom:\(second.id)",
                    photoID: second.id,
                    screenFrame: NormalizedRect(x: 0, y: 0.5, width: 1, height: 0.5),
                    sourceCrop: secondCrop,
                    contentMode: .crop
                ),
            ]
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

        return NormalizedRect(
            x: originX,
            y: originY,
            width: cropWidth,
            height: cropHeight
        )
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
