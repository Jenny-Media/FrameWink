import Foundation

protocol FrameLayoutChoosing {
    func pages(
        for items: [FrameLayoutItem],
        viewport: PixelSize,
        preference: FrameLayoutPreference
    ) -> [FramePage]
}

struct FrameLayoutChooser: FrameLayoutChoosing {
    func pages(
        for items: [FrameLayoutItem],
        viewport: PixelSize,
        preference: FrameLayoutPreference
    ) -> [FramePage] {
        guard viewport.width > 0, viewport.height > 0 else { return [] }

        var result: [FramePage] = []
        var index = 0

        while index < items.count {
            if preference == .automatic,
               index + 1 < items.count,
               let pair = pairedPage(
                   first: items[index],
                   second: items[index + 1],
                   viewport: viewport
               ) {
                result.append(pair)
                index += 2
            } else {
                result.append(
                    singlePage(
                        item: items[index],
                        viewport: viewport,
                        preference: preference
                    )
                )
                index += 1
            }
        }

        return result
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
        guard viewport.aspectRatio >= 1.2,
              first.pixelSize.aspectRatio > 0,
              second.pixelSize.aspectRatio > 0,
              first.pixelSize.aspectRatio <= 0.9,
              second.pixelSize.aspectRatio <= 0.9 else {
            return nil
        }

        let halfViewportAspect = (Double(viewport.width) / 2) / Double(viewport.height)
        guard let firstCrop = safeCrop(for: first, targetAspectRatio: halfViewportAspect),
              let secondCrop = safeCrop(for: second, targetAspectRatio: halfViewportAspect) else {
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
