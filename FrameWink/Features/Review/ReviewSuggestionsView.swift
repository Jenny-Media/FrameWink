import SwiftUI
import UIKit

struct ReviewSuggestionsView: View {
    @ObservedObject var model: AppModel

    @Environment(\.presentationMode) private var presentationMode

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
                            Text("Only these locally curated photos will play. Remove anything you don’t want appearing in Frame Mode.")
                                .foregroundColor(.secondary)

                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(model.reviewPhotos) { photo in
                                    ReviewPhotoCard(
                                        photo: photo,
                                        loadImage: { photo in
                                            await model.thumbnail(for: photo)
                                        },
                                        neverShow: model.neverShow
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(.black.opacity(0.6), in: Capsule())
            }
            .buttonStyle(.plain)
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
                        Text("Refresh the selected album after photos become available on this iPad.")
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
                                        neverShow: controller.neverShow
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
