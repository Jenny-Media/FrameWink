import Foundation

/// Local view geometry only: no device name, screen singleton, or orientation assumption.
struct FrameViewportRegions: Equatable {
    let photo: CGRect
    let controls: CGRect
    let isDivided: Bool

    init(size: CGSize, safeArea: CGRect, divisions: [CGRect]) {
        let bounds = CGRect(origin: .zero, size: size)
        var photo = bounds
        var controls = bounds
        var isDivided = false

        for division in divisions {
            let fold = division.intersection(bounds)
            guard !fold.isNull, fold.width > 0, fold.height > 0 else { continue }

            let first: CGRect
            let second: CGRect
            if fold.height > fold.width, fold.height >= bounds.height / 2 {
                first = CGRect(x: 0, y: 0, width: fold.minX, height: bounds.height)
                second = CGRect(x: fold.maxX, y: 0,
                                width: bounds.width - fold.maxX, height: bounds.height)
            } else if fold.width >= bounds.width / 2 {
                first = CGRect(x: 0, y: 0, width: bounds.width, height: fold.minY)
                second = CGRect(x: 0, y: fold.maxY,
                                width: bounds.width, height: bounds.height - fold.maxY)
            } else {
                continue
            }
            guard first.width > 0, first.height > 0,
                  second.width > 0, second.height > 0 else { continue }

            // Photos stay above/left of the fold; touch controls use the bottom/right.
            photo = first
            controls = second
            isDivided = true
            break
        }

        self.photo = photo
        let safeControls = controls.intersection(safeArea)
        self.controls = safeControls.isNull ? .zero : safeControls
        self.isDivided = isDivided
    }
}
