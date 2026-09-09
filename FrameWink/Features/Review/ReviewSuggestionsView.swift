import SwiftUI
import UIKit

private enum ReviewSheet: String, Identifiable {
    case hiddenPhotos

    var id: String { rawValue }
}

struct ReviewSuggestionsView: View {
    @ObservedObject var model: AppModel

    @Environment(\.presentationMode) private var presentationMode
    @State private var undoDismissTask: Task<Void, Never>?
    @State private var presentedSheet: ReviewSheet?

    private let columns = [
        GridItem(.adaptive(minimum: 190, maximum: 280), spacing: 16),
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if model.reviewPhotos.isEmpty {
                        ReviewEmptyState(
                            detail: "There are no photos in this frame. Photos you removed remain available under Hidden from Frame."
                        )
                    } else {
                        Group {
                            ReviewIntroduction(
                                photoCount: model.reviewPhotos.count,
                                source: "the photos you chose"
                            )

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
                    }

                    if !model.excludedReviewPhotos.isEmpty {
                        HiddenPhotosLink(count: model.excludedReviewPhotos.count) {
                            presentedSheet = .hiddenPhotos
                        }
                    }
                }
                .padding(24)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if model.canUndoNeverShow {
                    ReviewUndoBar(undo: undoNeverShow)
                }
            }
            .navigationTitle("Photos in This Frame")
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
        .onDisappear {
            undoDismissTask?.cancel()
            model.clearNeverShowUndo()
        }
        .sheet(item: $presentedSheet) { _ in
            HiddenPhotosView(
                photos: model.excludedReviewPhotos,
                source: "the photos you chose",
                loadImage: { photo in await model.thumbnail(for: photo) },
                allowAgain: { model.restoreNeverShowChoice(candidateID: $0) },
                allowAllAgain: model.resetNeverShowChoices
            )
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
        ZStack {
            Color.black.opacity(0.88)

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                ProgressView()
                    .tint(.white)
                    .accessibilityLabel("Loading photo")
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .overlay(alignment: .bottom) {
            Button(role: .destructive) {
                neverShow(photo.id)
            } label: {
                Label("Never Show Again", systemImage: "eye.slash.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(.black.opacity(0.68), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("never-show-" + photo.id.uuidString)
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .task(id: photo.id) {
            image = await loadImage(photo)
        }
        .onDisappear {
            image = nil
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Photo currently included in this frame")
    }
}

struct AutomaticAlbumReviewView: View {
    @ObservedObject var controller: AutomaticAlbumController
    @Environment(\.presentationMode) private var presentationMode
    @State private var undoDismissTask: Task<Void, Never>?
    @State private var presentedSheet: ReviewSheet?

    private let columns = [
        GridItem(.adaptive(minimum: 190, maximum: 280), spacing: 16),
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if controller.reviewPhotos.isEmpty {
                        ReviewEmptyState(
                            detail: "There are no photos in this frame yet. Photos you removed remain available under Hidden from Frame. You can also choose another album or wait for this album to finish preparing."
                        )
                    } else {
                        Group {
                            ReviewIntroduction(
                                photoCount: controller.reviewPhotos.count,
                                source: controller.selectedAlbumTitle
                            )

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
                    }

                    if !controller.excludedReviewPhotos.isEmpty {
                        HiddenPhotosLink(count: controller.excludedReviewPhotos.count) {
                            presentedSheet = .hiddenPhotos
                        }
                    }
                }
                .padding(24)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if controller.canUndoNeverShow {
                    ReviewUndoBar(undo: undoNeverShow)
                }
            }
            .navigationTitle("Photos in This Frame")
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
        .onDisappear {
            undoDismissTask?.cancel()
            controller.clearNeverShowUndo()
        }
        .sheet(item: $presentedSheet) { _ in
            HiddenPhotosView(
                photos: controller.excludedReviewPhotos,
                source: controller.selectedAlbumTitle,
                loadImage: { photo in await controller.thumbnail(for: photo) },
                allowAgain: { controller.restoreNeverShowChoice(candidateID: $0) },
                allowAllAgain: controller.resetNeverShowChoices
            )
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
            Label("Removed from this frame", systemImage: "eye.slash")
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

private struct HiddenPhotosLink: View {
    let count: Int
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: 14) {
                Image(systemName: "eye.slash.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Hidden from Frame")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(count == 1 ? "1 photo can be allowed again" : "\(count) photos can be allowed again")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("manage-hidden-photos")
    }
}

private struct HiddenPhotosView: View {
    let photos: [ImportedPhoto]
    let source: String
    let loadImage: (ImportedPhoto) async -> UIImage?
    let allowAgain: (UUID) -> Void
    let allowAllAgain: () -> Void

    @Environment(\.presentationMode) private var presentationMode
    @State private var showsAllowAllConfirmation = false

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 240), spacing: 16),
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("These photos from \(source) stay in Apple Photos, but FrameWink won’t show them. Allow any photo again whenever you change your mind.")
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(photos) { photo in
                            HiddenPhotoCard(
                                photo: photo,
                                loadImage: loadImage,
                                allowAgain: {
                                    allowAgain(photo.id)
                                    if photos.count == 1 {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("Hidden from Frame")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if photos.count > 1 {
                        Button("Allow All") {
                            showsAllowAllConfirmation = true
                        }
                        .accessibilityIdentifier("restore-excluded-photos")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("Allow All Photos Again?", isPresented: $showsAllowAllConfirmation) {
            Button("Allow All") {
                allowAllAgain()
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("FrameWink will choose again from these photos. Your Apple Photos library is unchanged.")
        }
    }
}

private struct HiddenPhotoCard: View {
    let photo: ImportedPhoto
    let loadImage: (ImportedPhoto) async -> UIImage?
    let allowAgain: () -> Void

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.black.opacity(0.88)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                ProgressView()
                    .tint(.white)
                    .accessibilityLabel("Loading photo")
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 190)
        .overlay(alignment: .bottom) {
            Button(action: allowAgain) {
                Label("Allow Again", systemImage: "eye.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(.black.opacity(0.68), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("allow-again-" + photo.id.uuidString)
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .task(id: photo.id) {
            image = await loadImage(photo)
        }
        .onDisappear {
            image = nil
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Photo hidden from this frame")
    }
}

private struct ReviewIntroduction: View {
    let photoCount: Int
    let source: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(photoCount == 1 ? "1 photo will appear" : "\(photoCount) photos will appear")
                .font(.title2.weight(.semibold))

            Text("These are the photos FrameWink will show from \(source). Choose Never Show Again to keep a photo out of this frame. Your original photo is never changed.")
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("review-frame-summary")
    }
}

private struct ReviewEmptyState: View {
    let detail: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 46))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text("No photos in this frame")
                .font(.title2.weight(.semibold))

            Text(detail)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

        }
        .padding(32)
    }
}
