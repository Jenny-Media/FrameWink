import SwiftUI

struct BundledSamplePhoto {
    let id: String
    let resourceName: String
    let pixelSize: PixelSize
    let title: LocalizedStringKey
    let caption: LocalizedStringKey
    let accessibilityLabel: LocalizedStringKey
    let importantRects: [NormalizedRect]

    init(
        id: String,
        resourceName: String,
        pixelSize: PixelSize,
        title: LocalizedStringKey,
        caption: LocalizedStringKey,
        accessibilityLabel: LocalizedStringKey,
        importantRects: [NormalizedRect] = []
    ) {
        self.id = id
        self.resourceName = resourceName
        self.pixelSize = pixelSize
        self.title = title
        self.caption = caption
        self.accessibilityLabel = accessibilityLabel
        self.importantRects = importantRects
    }

    var slide: DisplaySlide {
        DisplaySlide(
            id: id,
            title: title,
            caption: caption,
            accessibilityLabel: accessibilityLabel,
            source: .bundled(resourceName: resourceName),
            importantRects: importantRects,
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
            caption: "Bundled example · stays on this device",
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
            accessibilityLabel: "Portrait sample photo of a white wading bird and its reflection",
            importantRects: [
                NormalizedRect(x: 0.02, y: 0.08, width: 0.96, height: 0.84),
            ]
        ),
        BundledSamplePhoto(
            id: "sample-coast-aerial",
            resourceName: "sample-coast-aerial",
            pixelSize: PixelSize(width: 2_048, height: 1_536),
            title: "See things differently",
            caption: "Bundled example · stays on this device",
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
            caption: "Bundled example · stays on this device",
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
        BundledSamplePhoto(
            id: "sample-taipei-skyline",
            resourceName: "sample-taipei-skyline",
            pixelSize: PixelSize(width: 2_048, height: 1_365),
            title: "City lights at dusk",
            caption: "Bundled example · stays on this device",
            accessibilityLabel: "Sample photo of the Taipei skyline at dusk"
        ),
        BundledSamplePhoto(
            id: "sample-autumn-waterfall",
            resourceName: "sample-autumn-waterfall",
            pixelSize: PixelSize(width: 2_048, height: 1_366),
            title: "A waterfall through autumn",
            caption: "Bundled example · works offline",
            accessibilityLabel: "Sample photo of a waterfall beneath a bridge in autumn"
        ),
        BundledSamplePhoto(
            id: "sample-sun-rays-ocean",
            resourceName: "sample-sun-rays-ocean",
            pixelSize: PixelSize(width: 2_048, height: 1_152),
            title: "Sunlight over open water",
            caption: "Bundled example · no Photos access needed",
            accessibilityLabel: "Sample photo of sun rays breaking through clouds over the ocean"
        ),
        BundledSamplePhoto(
            id: "sample-autumn-cyclist",
            resourceName: "sample-autumn-cyclist",
            pixelSize: PixelSize(width: 2_048, height: 1_365),
            title: "The road through autumn",
            caption: "Bundled example · stays on this device",
            accessibilityLabel: "Sample photo of a cyclist riding along an autumn road"
        ),
        BundledSamplePhoto(
            id: "sample-mountain-icicles",
            resourceName: "sample-mountain-icicles",
            pixelSize: PixelSize(width: 2_048, height: 1_365),
            title: "Winter in the details",
            caption: "Bundled example · works offline",
            accessibilityLabel: "Sample photo of icicles beneath layered mountain rock"
        ),
        BundledSamplePhoto(
            id: "sample-yellowstone-falls",
            resourceName: "sample-yellowstone-falls",
            pixelSize: PixelSize(width: 2_048, height: 1_365),
            title: "A wider view of wonder",
            caption: "Bundled example · no Photos access needed",
            accessibilityLabel: "Sample photo of Lower Yellowstone Falls in a snowy canyon"
        ),
        BundledSamplePhoto(
            id: "sample-san-francisco-sunset",
            resourceName: "sample-san-francisco-sunset",
            pixelSize: PixelSize(width: 2_048, height: 1_536),
            title: "A city under color",
            caption: "Bundled example · stays on this device",
            accessibilityLabel: "Sample photo of San Francisco City Hall beneath a vivid sunset"
        ),
        BundledSamplePhoto(
            id: "sample-horseshoe-bend",
            resourceName: "sample-horseshoe-bend",
            pixelSize: PixelSize(width: 2_048, height: 1_536),
            title: "Weather over the canyon",
            caption: "Bundled example · works offline",
            accessibilityLabel: "Sample photo of Horseshoe Bend beneath storm clouds"
        ),
        BundledSamplePhoto(
            id: "sample-antelope-canyon",
            resourceName: "sample-antelope-canyon",
            pixelSize: PixelSize(width: 2_048, height: 1_536),
            title: "Light shaped by stone",
            caption: "Bundled example · no Photos access needed",
            accessibilityLabel: "Sample photo of warm layered sandstone in Antelope Canyon"
        ),
        BundledSamplePhoto(
            id: "sample-golden-gate",
            resourceName: "sample-golden-gate",
            pixelSize: PixelSize(width: 2_048, height: 1_365),
            title: "Across the bay",
            caption: "Bundled example · stays on this device",
            accessibilityLabel: "Sample photo of the Golden Gate Bridge across blue water"
        ),
    ]

    static let slides = photos.map(\.slide)
}
