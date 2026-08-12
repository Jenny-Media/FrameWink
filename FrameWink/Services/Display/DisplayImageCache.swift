import UIKit

private let defaultDisplayImageCacheCostLimit = 80 * 1_024 * 1_024
private let defaultDisplayImageCacheCountLimit = 4

@MainActor
final class DisplayImageCache: ObservableObject {
    private let cache = NSCache<NSString, UIImage>()
    private var inFlight: [String: Task<UIImage?, Never>] = [:]
    private var generation = 0

    init(
        totalCostLimit: Int = defaultDisplayImageCacheCostLimit,
        countLimit: Int = defaultDisplayImageCacheCountLimit
    ) {
        cache.totalCostLimit = max(totalCostLimit, 0)
        cache.countLimit = max(countLimit, 0)
    }

    func cachedImage(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func image(
        forKey key: String,
        loader: @escaping () async -> UIImage?
    ) async -> UIImage? {
        if let cached = cache.object(forKey: key as NSString) {
            return cached
        }
        if let task = inFlight[key] {
            return await task.value
        }

        let loadGeneration = generation
        let task = Task { await loader() }
        inFlight[key] = task
        let image = await task.value
        guard generation == loadGeneration else { return image }
        inFlight[key] = nil
        if let image = image, !Task.isCancelled {
            cache.setObject(
                image,
                forKey: key as NSString,
                cost: Self.decodedCost(of: image)
            )
        }
        return image
    }

    func removeAllImages() {
        generation += 1
        inFlight.values.forEach { $0.cancel() }
        inFlight = [:]
        cache.removeAllObjects()
    }

    private static func decodedCost(of image: UIImage) -> Int {
        if let cgImage = image.cgImage {
            return cgImage.bytesPerRow * cgImage.height
        }
        let width = Int((image.size.width * image.scale).rounded(.up))
        let height = Int((image.size.height * image.scale).rounded(.up))
        return max(width, 1) * max(height, 1) * 4
    }
}
