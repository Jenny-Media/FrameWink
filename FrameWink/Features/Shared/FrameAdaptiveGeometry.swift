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
        // An explicit UI-test fixture exercises the lower control surface on
        // ordinary Simulators. Physical acceptance never sets this override.
        if DebugScreenshotScenario.current != nil,
           ProcessInfo.processInfo.environment["FRAMEWINK_UI_TEST_HORIZONTAL_DIVISION"] == "1" {
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
