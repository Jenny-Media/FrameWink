# MVP architecture

## Compatibility baseline

- iPad-only application.
- Minimum iPadOS 15.
- SwiftUI application lifecycle.
- Use `ObservableObject`/`@StateObject` for shared state.
- Use Swift concurrency only where availability and cancellation behavior are
  understood and tested on iPadOS 15.
- Apple frameworks only for the MVP.

## Domain models

Suggested domain types:

- `PhotoCandidate`: common identifier, source, dimensions, dates when known,
  thumbnail provider, and optional PhotoKit metadata.
- `ImportedPhoto`: app-controlled, display-sized file created from PHPicker.
- `PhotoLibraryAsset`: minimal PhotoKit metadata exposed across the service seam.
- `CachedAlbumAsset`: app-controlled display copy mapped to its selected-album
  asset identifier and modification state.
- `PhotoSignals`: quality, face, saliency, similarity, and layout measurements.
- `CuratedPhoto`: candidate identifier plus algorithm version and final score.
- `SmartReel`: ordered curated selections and creation metadata.
- `FrameLayout`: single fit/fill, paired portraits, or four-photo Mosaic.
- `DisplaySchedule`: dim/blackout intervals and preferred intensity.
- `EntitlementState`: loading, free, purchased, unavailable, or revoked.

Do not make views depend directly on `PHAsset`, `VNRequest`, StoreKit
transactions, or file URLs.

## Services

### Photo importing

`PhotoImporting` should:

- Accept up to 100 PHPicker results in free mode.
- Downsample during decode rather than retaining full-resolution bitmaps.
- Store display-sized copies in an app-controlled directory.
- Produce stable identifiers and minimal metadata.
- Support cancellation, partial failure, retry, and delete-all.

### Photo library

`PhotoLibrarySourcing` should:

- Request authorization only from a user-initiated automatic-album action.
- Fetch selected albums and assets without modifying the library.
- Observe changes only for paid automatic sources.
- Distinguish local-ready assets from assets requiring Apple Photos/iCloud.
- Support strict-offline requests with network access disabled.

### Curation

`PhotoCurating` accepts common candidates and produces a deterministic reel.
The MVP pipeline:

1. High-confidence exclusions.
2. Cheap sharpness, exposure, and contrast signals.
3. Burst and time-bucket grouping.
4. Near-duplicate feature-print comparisons within bounded buckets.
5. Vision face-capture quality and attention saliency where useful.
6. Event/date diversity and a mix of recent and older selections.
7. Layout-fitness scoring.
8. Final selection with stable tie-breaking.
9. User exclusions applied as hard vetoes.

Never perform all-pairs similarity comparison across an unbounded library.

### Layout

`FrameLayoutChoosing` should be a pure, testable component. Inputs include
screen aspect ratio, orientation, image dimensions, face/saliency rectangles,
and nearby candidates. Output includes layout type and crop rectangles.

### Display behavior

`FrameSessionControlling` should own:

- Timer and navigation state.
- Idle-timer disabling only while Frame Mode is active.
- Saving and restoring app-controlled brightness behavior.
- A visual dimming/blackout overlay.
- Reduce Motion behavior.
- Guided Access status messaging where public APIs permit it.

It must never promise exact wake from suspension or restart.

### Purchases

`PurchaseControlling` should:

- Use StoreKit 2.
- Derive entitlement from verified current transactions.
- Listen for transaction updates.
- Handle pending, cancellation, purchase failure, restore, refund/revocation,
  offline launch, and StoreKit unavailability.
- Keep the free experience available when StoreKit is unavailable.
- Never use a `UserDefaults` Boolean as the sole entitlement source.

## Persistence

Use separate app-controlled storage for:

- Imported display-sized images.
- Codable settings.
- Curator signals keyed by candidate identifier and algorithm revision.
- Smart Reel definitions.
- Never-show exclusions.
- Recent-display history.
- Automatic-album configuration, display-sized cache, and asset metadata.
- Multiple saved frame source/layout/timing configurations.

All caches must be disposable and rebuildable. Deleting imported photos must
remove the files and all derived records that reference them.

## Performance rules

- Request or decode thumbnails appropriate for screen/inference size.
- Never retain several full-resolution photos concurrently.
- Bound concurrent Vision work to one operation on 2 GB devices until measured.
- Make analysis cancellable and resumable.
- Pause or reduce work at serious or critical thermal state.
- Preload only a small number of upcoming display images.
- Keep slideshow transitions smooth while analysis runs.

## Test seams

- Inject clocks, deterministic random seeds, thumbnail providers, purchase
  clients, and persistence locations.
- Keep ranking and layout logic independent from Apple UI frameworks where
  practical.
- Include fixture images representing landscapes, portraits, duplicates,
  bursts, blur, under/overexposure, screenshots, panoramas, multiple faces, and
  awkward edge-positioned faces.
