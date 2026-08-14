import SwiftUI

struct BundledSamplePhoto {
    let id: String
    let resourceName: String
    let pixelSize: PixelSize
    let title: LocalizedStringKey
    let caption: LocalizedStringKey
    let accessibilityLabel: LocalizedStringKey

    var slide: DisplaySlide {
        DisplaySlide(
            id: id,
            title: title,
            caption: caption,
            accessibilityLabel: accessibilityLabel,
            source: .bundled(resourceName: resourceName),
            bundledPixelSize: pixelSize
        )
    }
}

enum BundledSampleCatalog {
    static let photos = [
        BundledSamplePhoto(
            id: "sample-city-skyline",
            resourceName: "sample-city-skyline",
            pixelSize: PixelSize(width: 2_048, height: 1_365),
            title: "Keep beautiful views close",
            caption: "Bundled example · no Photos access needed",
            accessibilityLabel: "Sample photo of a city skyline at dusk"
        ),
        BundledSamplePhoto(
            id: "sample-city-tower",
            resourceName: "sample-city-tower",
            pixelSize: PixelSize(width: 1_365, height: 2_048),
            title: "A new view of familiar places",
            caption: "Bundled example · stays on this iPad",
            accessibilityLabel: "Portrait sample photo of an illuminated city tower at dusk"
        ),
        BundledSamplePhoto(
            id: "sample-autumn-leaves",
            resourceName: "sample-autumn-leaves",
            pixelSize: PixelSize(width: 2_048, height: 1_365),
            title: "Color worth remembering",
            caption: "Bundled example · works offline",
            accessibilityLabel: "Sample photo of red and orange autumn leaves"
        ),
        BundledSamplePhoto(
            id: "sample-water-bird",
            resourceName: "sample-water-bird",
            pixelSize: PixelSize(width: 1_365, height: 2_048),
            title: "Quiet moments in nature",
            caption: "Bundled example · no Photos access needed",
            accessibilityLabel: "Portrait sample photo of a white wading bird and its reflection"
        ),
        BundledSamplePhoto(
            id: "sample-coast-aerial",
            resourceName: "sample-coast-aerial",
            pixelSize: PixelSize(width: 2_048, height: 1_536),
            title: "See things differently",
            caption: "Bundled example · stays on this iPad",
            accessibilityLabel: "Aerial sample photo of a pier meeting a turquoise coast"
        ),
        BundledSamplePhoto(
            id: "sample-spring-flowers",
            resourceName: "sample-spring-flowers",
            pixelSize: PixelSize(width: 2_048, height: 1_365),
            title: "Small signs of spring",
            caption: "Bundled example · works offline",
            accessibilityLabel: "Sample photo of red and yellow tulips in soft window light"
        ),
        BundledSamplePhoto(
            id: "sample-open-road",
            resourceName: "sample-open-road",
            pixelSize: PixelSize(width: 2_048, height: 1_365),
            title: "Remember the road ahead",
            caption: "Bundled example · no Photos access needed",
            accessibilityLabel: "Sample photo of an open road beneath a blue sky"
        ),
        BundledSamplePhoto(
            id: "sample-evening-sail",
            resourceName: "sample-evening-sail",
            pixelSize: PixelSize(width: 1_365, height: 2_048),
            title: "Evenings by the water",
            caption: "Bundled example · stays on this iPad",
            accessibilityLabel: "Portrait sample photo of a sailboat silhouetted at sunset"
        ),
        BundledSamplePhoto(
            id: "sample-mountain-volcano",
            resourceName: "sample-mountain-volcano",
            pixelSize: PixelSize(width: 2_048, height: 1_365),
            title: "The world in motion",
            caption: "Bundled example · works offline",
            accessibilityLabel: "Sample photo of glowing lava rising from a volcano at night"
        ),
        BundledSamplePhoto(
            id: "sample-sunset-city",
            resourceName: "sample-sunset-city",
            pixelSize: PixelSize(width: 2_048, height: 1_536),
            title: "Last light over the city",
            caption: "Bundled example · no Photos access needed",
            accessibilityLabel: "Sample photo of a city beneath a vivid pink sunset"
        ),
    ]

    static let slides = photos.map(\.slide)
}
