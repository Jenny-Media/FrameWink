import SwiftUI

struct ImportStatusCard: View {
    let phase: ImportPhase
    let canRetry: Bool
    let cancel: () -> Void
    let retry: () -> Void
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                Label("Couldn’t delete imported photos", systemImage: "exclamationmark.triangle.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.orange)
                Text(message)
                    .foregroundColor(.secondary)
                Button("Dismiss", action: dismiss)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(maxWidth: 480, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.28), radius: 28, y: 12)
        .padding()
    }

    @ViewBuilder
    private func progressContent(_ progress: ImportProgress, isCancelling: Bool) -> some View {
        Text(isCancelling ? "Stopping import…" : "Preparing your photos")
            .font(.title3.weight(.semibold))

        ProgressView(value: progress.fractionCompleted)
            .tint(.accentColor)
            .accessibilityLabel("Photo import progress")
            .accessibilityValue("\(progress.completedCount) of \(progress.totalCount)")

        Text("\(progress.completedCount) of \(progress.totalCount) finished")
            .foregroundColor(.secondary)

        if !isCancelling {
            Button("Cancel Import", role: .cancel, action: cancel)
                .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private func completionContent(_ report: PhotoImportReport) -> some View {
        if report.wasCancelled {
            Label("Import stopped", systemImage: "pause.circle.fill")
                .font(.title3.weight(.semibold))
        } else if report.limitReachedCount > 0 && report.failures.isEmpty {
            Label("Photo collection full", systemImage: "photo.stack.fill")
                .font(.title3.weight(.semibold))
                .foregroundColor(.accentColor)
        } else if report.failures.isEmpty {
            Label("Photos ready", systemImage: "checkmark.circle.fill")
                .font(.title3.weight(.semibold))
                .foregroundColor(.green)
        } else {
            Label("Some photos need another try", systemImage: "exclamationmark.circle.fill")
                .font(.title3.weight(.semibold))
                .foregroundColor(.orange)
        }

        Text(summary(for: report))
            .foregroundColor(.secondary)

        if let firstFailure = report.failures.first {
            Text(firstFailure.message)
                .font(.footnote)
                .foregroundColor(.secondary)
        }

        HStack {
            if canRetry {
                Button(report.wasCancelled ? "Resume Import" : "Retry Failed", action: retry)
                    .buttonStyle(.borderedProminent)
                Button("Done", action: dismiss)
                    .buttonStyle(.bordered)
            } else {
                Button("Done", action: dismiss)
                    .buttonStyle(.borderedProminent)
            }
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
