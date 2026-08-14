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

The opaque 1,024-pixel app icon master was regenerated with Codex's built-in
image-generation tool on 2026-08-14 and saved in
`FrameWink/Resources/Assets.xcassets/AppIcon.appiconset/`.

```text
Use case: logo-brand
Asset type: production iOS and iPadOS App Store icon, square 1024 × 1024 bitmap
Primary request: Redesign the FrameWink app icon as an exceptionally clear, premium flat geometric mark for a private local photo-frame app. Preserve the core idea of a warm ivory picture frame around a coral sunset and two overlapping hills, with a subtle playful wink cue. Use a clean, thick, softly squared gallery-frame silhouette with one small four-point gold wink glint tucked inside the upper-right corner. Simplify every contour and enlarge the important forms so the icon remains recognizable at 32 px.
Style/medium: crisp premium flat vector-like illustration with extremely subtle paper grain only; no thin strokes; no tiny decoration besides the wink glint
Composition/framing: centered bold mark occupying about 78% of the square; broad frame rail; large half-sun; two sweeping hills with clear overlap; generous internal negative space; visually balanced at thumbnail scale
Lighting/mood: warm, calm, trustworthy, quietly joyful
Color palette: deep midnight indigo background, warm ivory frame, muted coral sun, sage and muted teal hills, small soft-gold glint
Constraints: opaque full-bleed square; no transparency; no text; no letters; no photography; no device mockup; no border around the overall canvas; do not pre-round the canvas corners because iPadOS applies its own mask; no watermark
Avoid: scalloped ornate frame edges, gradients that turn muddy, glossy 3D, drop shadows, excessive texture, fine lines, realistic landscape detail, neon colors
```

The selected clean-gallery candidate is also retained under
`Design/AppIconIterations/` with the two rejected explorations, full prompts,
and 32-pixel comparison sheets. The production PNG is an opaque, metadata-free
sRGB image. Its SHA-256 is
`5f4881ffb1a29b9a06a18bc1297828bb68cffdb9830dbd7422145b988b772e8a`.
