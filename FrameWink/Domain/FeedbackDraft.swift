import Foundation

/// Contains only the basic context a user can review and edit in their email draft.
struct FeedbackDraft {
    static let recipient = "framewink@jenny.media"

    let appVersion: String
    let appBuild: String
    let deviceModel: String
    let systemVersion: String

    var subject: String {
        NSLocalizedString("FrameWink Feedback", comment: "Feedback email subject")
    }

    var body: String {
        String(
            format: NSLocalizedString(
                "What would you like us to improve?\n\n\n\nApp: FrameWink %@ (%@)\nDevice: %@\nSystem: %@\n\nYou can edit or remove these details before sending. No photos or logs are attached.",
                comment: "Editable feedback email with app version, build, device model, and OS version"
            ),
            appVersion, appBuild, deviceModel, systemVersion
        )
    }
}
