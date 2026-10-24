import SwiftUI

extension GeometryProxy {
    func frameViewportRegions(controlInsets: EdgeInsets? = nil) -> FrameViewportRegions {
        let insets = controlInsets ?? safeAreaInsets
        let safeArea = CGRect(
            x: insets.leading,
            y: insets.top,
            width: max(0, size.width - insets.leading - insets.trailing),
            height: max(0, size.height - insets.top - insets.bottom)
        )
        var divisions: [CGRect] = []
        #if FRAMEWINK_NATIVE_DUO
        if #available(iOS 27.1, *) {
            // The system's frame already includes its interaction margins.
            // Expanding it again needlessly shrinks both usable halves.
            divisions = reservedRegions(kind: .division, layoutDirectionBehavior: .fixed)
                .map(\.frame)
        }
        #endif
        #if DEBUG
        // Explicit UI-test fixtures exercise the companion control surface and
        // division transitions on ordinary Simulators, not native hinge detection.
        let environment = ProcessInfo.processInfo.environment
        let alwaysDivided = environment["FRAMEWINK_UI_TEST_HORIZONTAL_DIVISION"] == "1"
        let dividedInPortrait = environment["FRAMEWINK_UI_TEST_PORTRAIT_DIVISION"] == "1"
            && size.height > size.width
        if DebugScreenshotScenario.current != nil, alwaysDivided || dividedInPortrait {
            divisions = [CGRect(x: 0, y: size.height / 2 - 20,
                                width: size.width, height: 40)]
        }
        #endif
        return FrameViewportRegions(size: size, safeArea: safeArea, divisions: divisions)
    }
}

extension View {
    func frameViewportRegion(_ region: CGRect) -> some View {
        frame(width: region.width, height: region.height)
            .position(x: region.midX, y: region.midY)
    }
}
