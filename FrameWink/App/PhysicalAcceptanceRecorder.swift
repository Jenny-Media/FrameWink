#if DEBUG
import Foundation
import UIKit

/// Writes a small, photo-free heartbeat for an explicitly launched physical
/// acceptance run. Production and ordinary Debug launches never enable it.
@MainActor
final class PhysicalAcceptanceRecorder {
    static let shared = PhysicalAcceptanceRecorder()

    private var timer: Timer?
    private var outputURL: URL?

    private init() {}

    func start() {
        guard DebugPhysicalAcceptanceMode.isEnabled else { return }
        guard timer == nil else { return }

        let baseURL = (try? LocalImportedPhotoStore.defaultBaseURL())
            ?? FileManager.default.temporaryDirectory
                .appendingPathComponent("FrameWink", isDirectory: true)
        let directory = baseURL.appendingPathComponent(
            "PhysicalAcceptance",
            isDirectory: true
        )
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            outputURL = directory.appendingPathComponent("heartbeat.json")
        } catch {
            assertionFailure("Could not create physical acceptance directory: \(error)")
            return
        }

        UIDevice.current.isBatteryMonitoringEnabled = true
        writeHeartbeat()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) {
            [weak self] _ in
            Task { @MainActor in
                self?.writeHeartbeat()
            }
        }
    }

    func recordStateChange() {
        guard DebugPhysicalAcceptanceMode.isEnabled else { return }
        writeHeartbeat()
    }

    private func writeHeartbeat() {
        guard let outputURL else { return }

        let process = ProcessInfo.processInfo
        let device = UIDevice.current
        let snapshot = Snapshot(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            systemUptimeSeconds: process.systemUptime,
            applicationState: applicationState,
            idleTimerDisabled: UIApplication.shared.isIdleTimerDisabled,
            guidedAccessEnabled: UIAccessibility.isGuidedAccessEnabled,
            thermalState: thermalState(process.thermalState),
            lowPowerModeEnabled: process.isLowPowerModeEnabled,
            batteryLevel: device.batteryLevel >= 0 ? device.batteryLevel : nil,
            batteryState: batteryState(device.batteryState)
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(snapshot).write(to: outputURL, options: .atomic)
        } catch {
            assertionFailure("Could not write physical acceptance heartbeat: \(error)")
        }
    }

    private var applicationState: String {
        switch UIApplication.shared.applicationState {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            return "unknown"
        }
    }

    private func thermalState(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal:
            return "nominal"
        case .fair:
            return "fair"
        case .serious:
            return "serious"
        case .critical:
            return "critical"
        @unknown default:
            return "unknown"
        }
    }

    private func batteryState(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .unknown:
            return "unknown"
        case .unplugged:
            return "unplugged"
        case .charging:
            return "charging"
        case .full:
            return "full"
        @unknown default:
            return "unknown"
        }
    }
}

private struct Snapshot: Encodable {
    let timestamp: String
    let systemUptimeSeconds: TimeInterval
    let applicationState: String
    let idleTimerDisabled: Bool
    let guidedAccessEnabled: Bool
    let thermalState: String
    let lowPowerModeEnabled: Bool
    let batteryLevel: Float?
    let batteryState: String
}
#endif
