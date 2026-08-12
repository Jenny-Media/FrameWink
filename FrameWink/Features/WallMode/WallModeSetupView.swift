import Combine
import SwiftUI
import UIKit

struct WallModeSetupView: View {
    @ObservedObject var wallMode: WallModeController
    @Environment(\.presentationMode) private var presentationMode
    @State private var draft: WallModeConfiguration
    @State private var guidedAccessIsEnabled = UIAccessibility.isGuidedAccessEnabled

    init(wallMode: WallModeController) {
        self.wallMode = wallMode
        _draft = State(initialValue: wallMode.configuration)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Label("Paid feature preview", systemImage: "sparkles")
                        .foregroundColor(.accentColor)
                    Text("Wall Mode is the planned one-time upgrade for durable frame behavior. StoreKit gating arrives in the purchase milestone; this screen currently previews and verifies the local behavior.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("Foreground display schedule") {
                    Toggle("Use dimming and blackout schedule", isOn: $draft.scheduleEnabled)

                    DatePicker(
                        "Begin dimming",
                        selection: minuteBinding(\.dimStartMinute),
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!draft.scheduleEnabled)

                    DatePicker(
                        "Begin blackout",
                        selection: minuteBinding(\.blackoutStartMinute),
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!draft.scheduleEnabled)

                    DatePicker(
                        "End blackout",
                        selection: minuteBinding(\.blackoutEndMinute),
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!draft.scheduleEnabled)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dimming strength: \(Int(draft.dimOpacity * 100))%")
                        Slider(value: $draft.dimOpacity, in: 0.15...0.9)
                            .disabled(!draft.scheduleEnabled)
                    }

                    Text("The schedule is a black visual overlay only while FrameWink is visible in the foreground. It does not change system brightness, lock the iPad, wake a suspended app, or relaunch after a restart.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("Guided Access") {
                    HStack {
                        Label(
                            guidedAccessIsEnabled ? "Guided Access is active" : "Guided Access is not active",
                            systemImage: guidedAccessIsEnabled ? "checkmark.shield.fill" : "shield"
                        )
                        .foregroundColor(guidedAccessIsEnabled ? .green : .secondary)
                        Spacer()
                    }

                    Text("Start Frame Mode, then use the iPad’s configured Accessibility Shortcut to begin Guided Access. FrameWink can report the public status but cannot switch consumer Guided Access on for you.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("Wall commissioning checklist") {
                    ForEach(WallChecklistItem.allCases) { item in
                        Button {
                            toggle(item)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(
                                    systemName: draft.completedChecklistItems.contains(item)
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                )
                                .foregroundColor(
                                    draft.completedChecklistItems.contains(item)
                                        ? .green
                                        : .secondary
                                )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .foregroundColor(.primary)
                                    Text(item.detail)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(item.title)
                        .accessibilityValue(
                            draft.completedChecklistItems.contains(item)
                                ? "Completed"
                                : "Not completed"
                        )
                    }
                }

                if let error = wallMode.configurationError {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Wall Mode Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        wallMode.updateConfiguration(draft)
                        if wallMode.configurationError == nil {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            guidedAccessIsEnabled = UIAccessibility.isGuidedAccessEnabled
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIAccessibility.guidedAccessStatusDidChangeNotification
            )
        ) { _ in
            guidedAccessIsEnabled = UIAccessibility.isGuidedAccessEnabled
        }
    }

    private func minuteBinding(
        _ keyPath: WritableKeyPath<WallModeConfiguration, Int>
    ) -> Binding<Date> {
        Binding(
            get: {
                date(for: draft[keyPath: keyPath])
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                draft[keyPath: keyPath] = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            }
        )
    }

    private func date(for minute: Int) -> Date {
        let start = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(byAdding: .minute, value: minute, to: start) ?? start
    }

    private func toggle(_ item: WallChecklistItem) {
        if draft.completedChecklistItems.contains(item) {
            draft.completedChecklistItems.remove(item)
        } else {
            draft.completedChecklistItems.insert(item)
        }
    }
}
