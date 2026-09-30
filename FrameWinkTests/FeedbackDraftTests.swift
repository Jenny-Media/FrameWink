import UIKit
import XCTest
@testable import FrameWink

final class FeedbackDraftTests: XCTestCase {
    func testDraftContainsOnlyBasicEditableAppAndDeviceContext() {
        let draft = FeedbackDraft(
            appVersion: "1.0.1",
            appBuild: "32",
            deviceModel: "iPad (iPad14,1)",
            systemVersion: "iPadOS 27.0"
        )

        let context = draft.body.components(separatedBy: "\n").filter {
            $0.hasPrefix("App:") || $0.hasPrefix("Device:") || $0.hasPrefix("System:")
        }
        XCTAssertEqual(context, [
            "App: FrameWink 1.0.1 (32)",
            "Device: iPad (iPad14,1)",
            "System: iPadOS 27.0",
        ])
        XCTAssertTrue(draft.body.contains("edit or remove these details before sending"))
        XCTAssertTrue(draft.body.contains("No photos or logs are attached."))
        XCTAssertFalse(draft.body.contains("file://"))
        XCTAssertFalse(draft.body.contains("https://"))
    }

    @MainActor
    func testCurrentDraftUsesBundleVersionAndNonuniqueDeviceContext() {
        let draft = FeedbackDraft.current()

        XCTAssertEqual(
            draft.appVersion,
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        )
        XCTAssertEqual(
            draft.appBuild,
            Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        )
        XCTAssertTrue(draft.deviceModel.hasPrefix(UIDevice.current.model + " ("))
        XCTAssertEqual(
            draft.systemVersion,
            "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        )
        if let vendorID = UIDevice.current.identifierForVendor?.uuidString {
            XCTAssertFalse(draft.body.contains(vendorID))
        }
    }
}
