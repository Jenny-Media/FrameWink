import Foundation

enum WallVisualState: Equatable {
    case normal
    case dimmed(opacity: Double)
    case blackout
}

enum WallChecklistItem: String, CaseIterable, Codable, Identifiable {
    case compatibleOS
    case reliablePower
    case batteryCondition
    case ventilation
    case heatAndSunlight
    case cableSecurity
    case orientation
    case autoBrightness
    case guidedAccess
    case rebootRecovery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compatibleOS: return "Confirm iPadOS compatibility"
        case .reliablePower: return "Use reliable continuous power"
        case .batteryCondition: return "Inspect the battery and enclosure"
        case .ventilation: return "Leave room for ventilation"
        case .heatAndSunlight: return "Avoid heat and direct sunlight"
        case .cableSecurity: return "Secure the cable without pinching it"
        case .orientation: return "Lock in the intended orientation"
        case .autoBrightness: return "Review Auto-Brightness"
        case .guidedAccess: return "Start Guided Access manually"
        case .rebootRecovery: return "Plan for restart recovery"
        }
    }

    var detail: String {
        switch self {
        case .compatibleOS:
            return "FrameWink requires iPadOS 15 or later. Install current security updates supported by this iPad."
        case .reliablePower:
            return "Use a reputable charger and cable rated for the iPad. Periodically inspect both for wear or unusual heat."
        case .batteryCondition:
            return "Do not wall-mount an iPad with swelling, screen separation, damage, odor, or unusual heat. Stop using it and seek qualified service."
        case .ventilation:
            return "Do not seal the iPad or charger in an unventilated enclosure. Leave airflow around the device and power hardware."
        case .heatAndSunlight:
            return "Keep the iPad away from radiators, cooking heat, damp areas, and direct sun that can overheat the device or fade the display."
        case .cableSecurity:
            return "Route the cable so it cannot be pulled, tripped over, crushed, sharply bent, or pressed against a connector."
        case .orientation:
            return "Choose portrait or landscape before mounting. FrameWink reflows layouts, but the mount itself must safely support that orientation."
        case .autoBrightness:
            return "FrameWink does not read ambient light or change system brightness. Configure iPadOS Auto-Brightness and display settings to your preference."
        case .guidedAccess:
            return "Consumer Guided Access is started in iPadOS by you. FrameWink can report its status but cannot turn it on automatically."
        case .rebootRecovery:
            return "After a restart or power loss, a normal App Store app cannot guarantee automatic relaunch. Plan to unlock the iPad and reopen FrameWink manually."
        }
    }
}

struct WallModeConfiguration: Codable, Equatable {
    var scheduleEnabled: Bool
    var dimStartMinute: Int
    var blackoutStartMinute: Int
    var blackoutEndMinute: Int
    var dimOpacity: Double
    var completedChecklistItems: Set<WallChecklistItem>

    static let defaultConfiguration = WallModeConfiguration(
        scheduleEnabled: false,
        dimStartMinute: 20 * 60,
        blackoutStartMinute: 23 * 60,
        blackoutEndMinute: 7 * 60,
        dimOpacity: 0.58,
        completedChecklistItems: []
    )

    mutating func normalize() {
        dimStartMinute = Self.normalizedMinute(dimStartMinute)
        blackoutStartMinute = Self.normalizedMinute(blackoutStartMinute)
        blackoutEndMinute = Self.normalizedMinute(blackoutEndMinute)
        dimOpacity = min(max(dimOpacity, 0.15), 0.9)
    }

    private static func normalizedMinute(_ value: Int) -> Int {
        let day = 24 * 60
        return ((value % day) + day) % day
    }
}

struct WallScheduleEvaluator {
    func visualState(
        at date: Date,
        calendar: Calendar,
        configuration: WallModeConfiguration,
        frameModeIsActive: Bool,
        sceneIsForeground: Bool
    ) -> WallVisualState {
        guard configuration.scheduleEnabled,
              frameModeIsActive,
              sceneIsForeground else {
            return .normal
        }

        let components = calendar.dateComponents([.hour, .minute], from: date)
        let minute = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        if contains(
            minute,
            from: configuration.blackoutStartMinute,
            until: configuration.blackoutEndMinute
        ) {
            return .blackout
        }
        if contains(
            minute,
            from: configuration.dimStartMinute,
            until: configuration.blackoutStartMinute
        ) {
            return .dimmed(opacity: configuration.dimOpacity)
        }
        return .normal
    }

    private func contains(_ minute: Int, from start: Int, until end: Int) -> Bool {
        guard start != end else { return false }
        if start < end {
            return minute >= start && minute < end
        }
        return minute >= start || minute < end
    }
}
