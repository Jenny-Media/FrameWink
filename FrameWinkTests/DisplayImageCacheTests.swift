import UIKit
import XCTest
@testable import FrameWink

@MainActor
final class DisplayImageCacheTests: XCTestCase {
    func testRepeatedRequestReusesDecodedImageUntilCacheIsCleared() async {
        let cache = DisplayImageCache()
        let fixture = UIImage()
        var loadCount = 0

        let first = await cache.image(forKey: "fixture") {
            loadCount += 1
            return fixture
        }
        let second = await cache.image(forKey: "fixture") {
            loadCount += 1
            return UIImage()
        }

        XCTAssertTrue(first === fixture)
        XCTAssertTrue(second === fixture)
        XCTAssertEqual(loadCount, 1)
        XCTAssertTrue(cache.cachedImage(forKey: "fixture") === fixture)

        cache.removeAllImages()
        XCTAssertNil(cache.cachedImage(forKey: "fixture"))
        _ = await cache.image(forKey: "fixture") {
            loadCount += 1
            return fixture
        }
        XCTAssertEqual(loadCount, 2)
    }

    func testConcurrentRequestsForOneImageShareTheInFlightLoad() async {
        let cache = DisplayImageCache()
        let fixture = UIImage()
        let counter = DisplayImageLoadCounter()

        async let first = cache.image(forKey: "fixture") {
            await counter.increment()
            try? await Task.sleep(nanoseconds: 20_000_000)
            return fixture
        }
        async let second = cache.image(forKey: "fixture") {
            await counter.increment()
            return fixture
        }

        let images = await [first, second]
        let loadCount = await counter.value
        XCTAssertTrue(images.allSatisfy { $0 === fixture })
        XCTAssertEqual(loadCount, 1)
    }

    func testClearingCachePreventsAnInFlightImageFromRepopulatingIt() async {
        let cache = DisplayImageCache()
        let fixture = UIImage()
        let gate = DisplayImageLoadGate()

        let request = Task { @MainActor in
            await cache.image(forKey: "fixture") {
                await gate.waitUntilReleased()
                return fixture
            }
        }

        await gate.waitUntilLoaderStarted()
        cache.removeAllImages()
        await gate.release()

        let loadedImage = await request.value
        XCTAssertTrue(loadedImage === fixture)
        XCTAssertNil(cache.cachedImage(forKey: "fixture"))
    }
}

private actor DisplayImageLoadCounter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}

private actor DisplayImageLoadGate {
    private var loaderStarted = false
    private var loaderStartWaiters: [CheckedContinuation<Void, Never>] = []
    private var released = false
    private var releaseWaiters: [CheckedContinuation<Void, Never>] = []

    func waitUntilLoaderStarted() async {
        guard !loaderStarted else { return }
        await withCheckedContinuation { continuation in
            loaderStartWaiters.append(continuation)
        }
    }

    func waitUntilReleased() async {
        loaderStarted = true
        loaderStartWaiters.forEach { $0.resume() }
        loaderStartWaiters = []

        guard !released else { return }
        await withCheckedContinuation { continuation in
            releaseWaiters.append(continuation)
        }
    }

    func release() {
        released = true
        releaseWaiters.forEach { $0.resume() }
        releaseWaiters = []
    }
}
