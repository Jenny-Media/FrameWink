import MessageUI
import SwiftUI
import UIKit

extension FeedbackDraft {
    @MainActor
    static func current() -> FeedbackDraft {
        let device = UIDevice.current
        var hardware = utsname()
        uname(&hardware)
        let hardwareModel = withUnsafeBytes(of: hardware.machine) { bytes in
            String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
        }
        let unknown = NSLocalizedString("Unknown", comment: "Unavailable app version or build")
        return FeedbackDraft(
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
                as? String ?? unknown,
            appBuild: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
                as? String ?? unknown,
            deviceModel: "\(device.model) (\(hardwareModel))",
            systemVersion: "\(device.systemName) \(device.systemVersion)"
        )
    }
}

struct FeedbackMailView: UIViewControllerRepresentable {
    let draft: FeedbackDraft
    let didFail: () -> Void
    @Environment(\.dismiss) private var dismiss

    static var canSendMail: Bool {
        MFMailComposeViewController.canSendMail()
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([FeedbackDraft.recipient])
        controller.setSubject(draft.subject)
        controller.setMessageBody(draft.body, isHTML: false)
        return controller
    }

    func updateUIViewController(_ controller: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: { dismiss() }, didFail: didFail)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        private let dismiss: () -> Void
        private let didFail: () -> Void

        init(dismiss: @escaping () -> Void, didFail: @escaping () -> Void) {
            self.dismiss = dismiss
            self.didFail = didFail
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            if result == .failed || error != nil { didFail() }
            dismiss()
        }
    }
}
