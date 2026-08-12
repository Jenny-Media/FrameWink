import Foundation
import UIKit

@MainActor
protocol IdleTimerControlling: AnyObject {
    var isIdleTimerDisabled: Bool { get set }
}

@MainActor
final class ApplicationIdleTimerController: IdleTimerControlling {
    var isIdleTimerDisabled: Bool {
        get { UIApplication.shared.isIdleTimerDisabled }
        set { UIApplication.shared.isIdleTimerDisabled = newValue }
    }
}

@MainActor
final class WallModeController: ObservableObject {
    @Published private(set) var configuration: WallModeConfiguration
    @Published private(set) var visualState: WallVisualState = .normal
    @Published private(set) var frameModeIsActive = false
    @Published private(set) var sceneIsForeground = true
    @Published private(set) var isEntitled = false
    @Published private(set) var configurationError: String?

    private let idleTimer: IdleTimerControlling
    private let store: WallModeConfigurationStoring
    private let evaluator: WallScheduleEvaluator
    private var calendar: Calendar
    private var previousIdleTimerState: Bool?

    init(
        idleTimer: IdleTimerControlling,
        store: WallModeConfigurationStoring,
        evaluator: WallScheduleEvaluator = WallScheduleEvaluator(),
        calendar: Calendar = .current
    ) {
        self.idleTimer = idleTimer
        self.store = store
        self.evaluator = evaluator
        self.calendar = calendar
        configuration = store.loadConfiguration()
        refresh(at: Date())
    }

    var ownsIdleTimerState: Bool {
        previousIdleTimerState != nil
    }

    func setFrameModeActive(_ isActive: Bool, at date: Date = Date()) {
        frameModeIsActive = isActive
        synchronizeIdleTimerOwnership()
        refresh(at: date)
    }

    func setEntitled(_ entitled: Bool, at date: Date = Date()) {
        isEntitled = entitled
        synchronizeIdleTimerOwnership()
        refresh(at: date)
    }

    func setSceneIsForeground(_ isForeground: Bool, at date: Date = Date()) {
        sceneIsForeground = isForeground
        synchronizeIdleTimerOwnership()
        refresh(at: date)
    }

    func updateConfiguration(_ newConfiguration: WallModeConfiguration, at date: Date = Date()) {
        var normalized = newConfiguration
        normalized.normalize()
        do {
            try store.saveConfiguration(normalized)
            configuration = normalized
            configurationError = nil
            refresh(at: date)
        } catch {
            configurationError = error.localizedDescription
        }
    }

    func refresh(at date: Date = Date()) {
        visualState = evaluator.visualState(
            at: date,
            calendar: calendar,
            configuration: configuration,
            frameModeIsActive: frameModeIsActive && isEntitled,
            sceneIsForeground: sceneIsForeground
        )
    }

    func restoreOwnedDisplayState(at date: Date = Date()) {
        frameModeIsActive = false
        restoreIdleTimerIfNeeded()
        refresh(at: date)
    }

    private func synchronizeIdleTimerOwnership() {
        if isEntitled && frameModeIsActive && sceneIsForeground {
            if previousIdleTimerState == nil {
                previousIdleTimerState = idleTimer.isIdleTimerDisabled
            }
            if !idleTimer.isIdleTimerDisabled {
                idleTimer.isIdleTimerDisabled = true
            }
        } else {
            restoreIdleTimerIfNeeded()
        }
    }

    private func restoreIdleTimerIfNeeded() {
        guard let previousIdleTimerState = previousIdleTimerState else { return }
        idleTimer.isIdleTimerDisabled = previousIdleTimerState
        self.previousIdleTimerState = nil
    }
}
