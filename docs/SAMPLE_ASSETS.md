# Bundled sample asset record

The publisher supplied and approved the ten personal photographs used for the
current Sample Photos experience. The repository contains only display-sized
derivatives. The original files remain outside the repository and were not
modified. No third-party or web-downloaded photo is bundled.

On 2026-08-14, each derivative was auto-oriented, converted to sRGB baseline
JPEG, resized to a maximum 2,048-pixel edge, and exported at quality 90 with
metadata stripped. `exiftool` found no EXIF, GPS, IPTC, TIFF, camera serial,
creator, copyright, date, or XMP data in the resulting files. The remaining
JPEG file/JFIF fields contain only format, dimensions, encoding, and resolution.
`BundledSampleImageLoaderTests` independently rejects private metadata and
checks the catalog dimensions against every bundled file.

| Resource | Pixels | Visible content |
|---|---:|---|
| `sample-city-skyline.jpg` | 2048 × 1365 | City skyline at dusk |
| `sample-city-tower.jpg` | 1365 × 2048 | Illuminated tower at dusk |
| `sample-autumn-leaves.jpg` | 2048 × 1365 | Red and orange leaves |
| `sample-water-bird.jpg` | 1365 × 2048 | White wading bird and reflection |
| `sample-coast-aerial.jpg` | 2048 × 1536 | Pier and turquoise coast from above |
| `sample-spring-flowers.jpg` | 2048 × 1365 | Red and yellow tulips |
| `sample-open-road.jpg` | 2048 × 1365 | Open road and blue sky |
| `sample-evening-sail.jpg` | 1365 × 2048 | Sailboat at sunset |
| `sample-mountain-volcano.jpg` | 2048 × 1365 | Lava at night |
| `sample-sunset-city.jpg` | 2048 × 1536 | City beneath a pink sunset |

The three earlier AI-generated PNG samples were removed rather than left as
unused bundle weight. The ten JPEG derivatives total approximately 5.1 MiB,
less than the previous three PNGs, and include three portrait photos so the
sample experience exercises the same pairing and responsive-layout paths as a
personal reel.

## `AppIcon-1024.png`

The opaque 1,024-pixel app icon master was generated with Codex's built-in
image-generation tool on 2026-08-12 and saved in
`FrameWink/Resources/Assets.xcassets/AppIcon.appiconset/`.

```text
Use case: logo-brand
Asset type: iPadOS App Store icon master, square 1024 × 1024 bitmap
Primary request: Create a refined, memorable icon for FrameWink, a private local digital photo-frame app. Show a single bold cream-colored picture-frame shape enclosing an abstract warm sunrise over two simple curved hills; add one tiny four-point glint near the upper-right inside edge to suggest a playful wink.
Style/medium: premium flat geometric illustration with subtle tactile grain, exceptionally clean silhouette, native Apple-platform sensibility without copying an Apple icon
Composition/framing: centered, symmetrical overall balance, large simple forms that remain legible at 32 px, generous but not empty margins, full-bleed square background
Lighting/mood: warm, calm, trustworthy, quietly joyful
Color palette: deep midnight indigo background, warm ivory frame, muted coral sun, sage and muted teal hills, small soft-gold glint
Constraints: opaque full-bleed square; no transparency; no text; no letters; no photography; no device mockup; no border around the overall canvas; do not pre-round the canvas corners because iPadOS applies its own mask; no watermark
Avoid: gradients that turn muddy at small size, thin linework, excessive detail, lens/camera imagery, human faces, hearts, smiley faces, neon colors, glossy 3D rendering
```
