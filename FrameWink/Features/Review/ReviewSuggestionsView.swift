import SwiftUI
import UIKit

struct ReviewSuggestionsView: View {
    @ObservedObject var model: AppModel

    @Environment(\.presentationMode) private var presentationMode
    @State private var undoDismissTask: Task<Void, Never>?

    private let columns = [
        GridItem(.adaptive(minimum: 190, maximum: 280), spacing: 16),
    ]

    var body: some View {
        NavigationView {
            Group {
                if model.reviewPhotos.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 46))
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                        Text("No suggestions to review")
                            .font(.title2.weight(.semibold))
                        Text("Refresh the Smart Reel to analyze the remaining imported photos.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Only these locally curated photos will play. Remove anything you don’t want appearing in your frame.")
                                .foregroundColor(.secondary)

                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(model.reviewPhotos) { photo in
                                    ReviewPhotoCard(
                                        photo: photo,
                                        loadImage: { photo in
                                            await model.thumbnail(for: photo)
                                        },
                                        neverShow: neverShow
                                    )
                                }
                            }
                        }
                        .padding(24)
                    }
                }
            }
            .navigationTitle("Review Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .safeAreaInset(edge: .bottom) {
            if model.canUndoNeverShow {
                ReviewUndoBar(undo: undoNeverShow)
            }
        }
        .onDisappear {
            undoDismissTask?.cancel()
            model.clearNeverShowUndo()
        }
    }

    private func neverShow(_ candidateID: UUID) {
        model.neverShow(candidateID: candidateID)
        scheduleUndoDismissal()
    }

    private func undoNeverShow() {
        undoDismissTask?.cancel()
        model.undoNeverShow()
    }

    private func scheduleUndoDismissal() {
        undoDismissTask?.cancel()
        undoDismissTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                model.clearNeverShowUndo()
            }
        }
    }
}

private struct ReviewPhotoCard: View {
    let photo: ImportedPhoto
    let loadImage: (ImportedPhoto) async -> UIImage?
    let neverShow: (UUID) -> Void

    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.88)

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .tint(.white)
                    .accessibilityLabel("Loading suggestion")
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            Button(role: .destructive) {
                neverShow(photo.id)
            } label: {
                Label("Never Show Again", systemImage: "eye.slash.fill")
                    .font(.footnote.weight(.semibold))
                    .frame(minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.red)
            .accessibilityIdentifier("never-show-" + photo.id.uuidString)
            .padding(12)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .task(id: photo.id) {
            image = await loadImage(photo)
        }
        .onDisappear {
            image = nil
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Smart Reel photo suggestion")
    }
}

struct AutomaticAlbumReviewView: View {
    @ObservedObject var controller: AutomaticAlbumController
    @Environment(\.presentationMode) private var presentationMode
    @State private var undoDismissTask: Task<Void, Never>?

    private let columns = [
        GridItem(.adaptive(minimum: 190, maximum: 280), spacing: 16),
    ]

    var body: some View {
        NavigationView {
            Group {
                if controller.reviewPhotos.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 46))
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                        Text("No automatic suggestions to review")
                            .font(.title2.weight(.semibold))
                        Text("Refresh the selected album after photos become available on this device.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Text("These cached album selections can play offline. Never Show Again remains a hard veto when the album refreshes.")
                                .foregroundColor(.secondary)

                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(controller.reviewPhotos) { photo in
                                    ReviewPhotoCard(
                                        photo: photo,
                                        loadImage: { photo in
                                            await controller.thumbnail(for: photo)
                                        },
                                        neverShow: neverShow
                                    )
                                }
                            }
                        }
                        .padding(24)
                    }
                }
            }
            .navigationTitle("Review Automatic Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .safeAreaInset(edge: .bottom) {
            if controller.canUndoNeverShow {
                ReviewUndoBar(undo: undoNeverShow)
            }
        }
        .onDisappear {
            undoDismissTask?.cancel()
            controller.clearNeverShowUndo()
        }
    }

    private func neverShow(_ candidateID: UUID) {
        controller.neverShow(candidateID: candidateID)
        scheduleUndoDismissal()
    }

    private func undoNeverShow() {
        undoDismissTask?.cancel()
        controller.undoNeverShow()
    }

    private func scheduleUndoDismissal() {
        undoDismissTask?.cancel()
        undoDismissTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                controller.clearNeverShowUndo()
            }
        }
    }
}

private struct ReviewUndoBar: View {
    let undo: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Label("Photo hidden", systemImage: "eye.slash")
                .foregroundColor(.primary)

            Spacer()

            Button("Undo", action: undo)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("undo-never-show")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .accessibilityElement(children: .contain)
    }
}
