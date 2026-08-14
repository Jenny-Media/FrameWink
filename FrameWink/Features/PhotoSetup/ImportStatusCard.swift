import SwiftUI

struct ImportStatusCard: View {
    let phase: ImportPhase
    let canRetry: Bool
    let cancel: () -> Void
    let retry: () -> Void
    let dismiss: () -> Void

    var body: some View {
        NavigationView {
            Form {
                content
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    toolbarAction
                }
            }
            .accessibilityIdentifier("import-status-sheet")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .interactiveDismissDisabled(isBusy)
        .onDisappear {
            if !isBusy {
                dismiss()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .idle:
            EmptyView()
        case .importing(let progress):
            progressContent(progress, isCancelling: false)
        case .cancelling(let progress):
            progressContent(progress, isCancelling: true)
        case .finished(let report):
            completionContent(report)
        case .deletionFailed(let message):
            Section {
                Label("Couldn’t delete imported photos", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(message)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var toolbarAction: some View {
        switch phase {
        case .importing:
            Button("Cancel", role: .cancel, action: cancel)
                .accessibilityIdentifier("cancel-photo-import")
        case .cancelling:
            ProgressView()
                .accessibilityLabel("Stopping import")
        case .idle, .finished, .deletionFailed:
            Button("Close", action: dismiss)
                .accessibilityIdentifier("close-import-status")
        }
    }

    @ViewBuilder
    private func progressContent(
        _ progress: ImportProgress,
        isCancelling: Bool
    ) -> some View {
        Section {
            ProgressView(value: progress.fractionCompleted)
                .tint(.accentColor)
                .accessibilityLabel("Photo import progress")
                .accessibilityValue("\(progress.completedCount) of \(progress.totalCount)")

            Text("\(progress.completedCount) of \(progress.totalCount) finished")
                .foregroundColor(.secondary)
        } footer: {
            Text(
                isCancelling
                    ? "FrameWink is keeping every photo that already finished."
                    : "Display-sized copies stay on this iPad and remain available offline."
            )
        }
    }

    @ViewBuilder
    private func completionContent(_ report: PhotoImportReport) -> some View {
        Section {
            completionLabel(report)

            Text(summary(for: report))
                .foregroundColor(.secondary)

            if let firstFailure = report.failures.first {
                Text(firstFailure.message)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }

        if canRetry {
            Section {
                Button(report.wasCancelled ? "Resume Import" : "Retry Failed", action: retry)
                    .accessibilityIdentifier("retry-photo-import")
            }
        }
    }

    @ViewBuilder
    private func completionLabel(_ report: PhotoImportReport) -> some View {
        if report.wasCancelled {
            Label("Import stopped", systemImage: "pause.circle.fill")
        } else if report.limitReachedCount > 0 && report.failures.isEmpty {
            Label("Photo collection full", systemImage: "photo.stack.fill")
                .foregroundColor(.accentColor)
        } else if report.failures.isEmpty {
            Label("Photos ready", systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
        } else {
            Label("Some photos need another try", systemImage: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
        }
    }

    private var navigationTitle: String {
        switch phase {
        case .idle:
            return "Photo Import"
        case .importing:
            return "Preparing Photos"
        case .cancelling:
            return "Stopping Import"
        case .finished:
            return "Import Complete"
        case .deletionFailed:
            return "Couldn’t Delete Photos"
        }
    }

    private var isBusy: Bool {
        switch phase {
        case .importing, .cancelling:
            return true
        case .idle, .finished, .deletionFailed:
            return false
        }
    }

    private func summary(for report: PhotoImportReport) -> String {
        let imported = report.imported.count
        let failed = report.failures.count
        if report.wasCancelled {
            return "\(imported) imported. Unfinished selections can be resumed."
        }
        if failed > 0 {
            return "\(imported) imported, \(failed) couldn’t be prepared. Successful photos are already saved."
        }
        if report.limitReachedCount > 0 {
            return "\(imported) imported. FrameWink keeps up to \(ManualPhotoCollectionPolicy.maximumCandidateCount) selected photos on this iPad."
        }
        return "\(imported) display-sized copies are stored on this iPad and ready offline."
    }
}
