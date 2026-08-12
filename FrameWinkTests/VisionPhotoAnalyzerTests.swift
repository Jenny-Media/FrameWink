import Darwin
import UIKit
import XCTest
@testable import FrameWink

final class VisionPhotoAnalyzerTests: XCTestCase {
    func testBundledSamplesAlwaysProduceConventionalSignals() async throws {
        let analyzer = VisionPhotoAnalyzer()
        let names = ["sample-lakeside", "sample-beach-dog", "sample-kitchen"]

        for (index, name) in names.enumerated() {
            let image = try XCTUnwrap(BundledSampleImageLoader.image(named: name))
            let id = UUID()
            let analyzed = try await analyzer.analyze(
                candidate: PhotoCandidate(
                    id: id,
                    source: .bundledSample,
                    pixelWidth: Int(image.size.width),
                    pixelHeight: Int(image.size.height),
                    creationDate: Date(timeIntervalSince1970: Double(index))
                ),
                image: image,
                cachedSignals: nil
            )

            XCTAssertEqual(analyzed.signals.candidateID, id)
            XCTAssertGreaterThan(analyzed.signals.sharpness, 0)
            XCTAssertGreaterThan(analyzed.signals.contrast, 0)
            XCTAssertGreaterThan(analyzed.signals.exposure, 0)
            XCTAssertLessThan(analyzed.signals.exposure, 1)
        }
    }

    func testOneHundredBoundedAnalysesCompleteWithinThirtySecondsOnSimulator() async throws {
        let analyzer = VisionPhotoAnalyzer()
        let image = try XCTUnwrap(
            BundledSampleImageLoader.image(named: "sample-lakeside")
        )
        let peakBefore = peakResidentMemoryBytes()
        let start = CFAbsoluteTimeGetCurrent()

        for index in 0..<100 {
            _ = try await analyzer.analyze(
                candidate: PhotoCandidate(
                    id: UUID(),
                    source: .bundledSample,
                    pixelWidth: Int(image.size.width),
                    pixelHeight: Int(image.size.height),
                    creationDate: Date(timeIntervalSince1970: Double(index))
                ),
                image: image,
                cachedSignals: nil
            )
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let peakGrowth = peakResidentMemoryBytes() - peakBefore
        print(
            String(
                format: "SMART_REEL_ANALYSIS_PERF elapsed=%.3fs peak_growth=%.1fMB",
                elapsed,
                Double(peakGrowth) / 1_048_576
            )
        )
        XCTAssertLessThan(elapsed, 30)
        XCTAssertLessThan(peakGrowth, 300 * 1_048_576)
    }

    private func peakResidentMemoryBytes() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size
        )
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        return result == KERN_SUCCESS ? UInt64(info.resident_size_max) : 0
    }
}
