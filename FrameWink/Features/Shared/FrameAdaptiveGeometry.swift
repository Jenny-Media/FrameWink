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
            divisions = reservedRegions(kind: .division, layoutDirectionBehavior: .fixed)
                .map { region in
                    // Respect Apple's margins as well as the physical fold itself.
                    CGRect(
                        x: region.frame.minX - region.margins.leading,
                        y: region.frame.minY - region.margins.top,
                        width: region.frame.width + region.margins.leading + region.margins.trailing,
                        height: region.frame.height + region.margins.top + region.margins.bottom
                    )
                }
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
