import SwiftUI

private enum SheetDestination: String, Identifiable {
    case photoPicker
    case privacy
    case reviewSuggestions
    case wallModeSetup

    var id: String { rawValue }
}

struct RootView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var wallMode: WallModeController

    @State private var presentedSheet: SheetDestination?
    @State private var showDeleteConfirmation = false
    @State private var isFrameMode = false

    var body: some View {
        NavigationView {
            ZStack {
                SampleSlideshowView(
                    slides: model.slides,
                    loadImportedImage: { photo in
                        await model.image(for: photo)
                    },
                    isFrameMode: $isFrameMode,
                    wallVisualState: wallMode.visualState,
                    refreshWallSchedule: wallMode.refresh
                )
                .ignoresSafeArea()

                if !isFrameMode {
                    chrome
                }

                if model.importPhase != .idle && !isFrameMode {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    ImportStatusCard(
                        phase: model.importPhase,
                        canRetry: model.canRetryImport,
                        cancel: model.cancelImport,
                        retry: model.retryImport,
                        dismiss: model.dismissImportStatus
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(item: $presentedSheet) { destination in
            switch destination {
            case .photoPicker:
                PhotoPickerView(selectionLimit: 100) { items in
                    model.importSelectedItems(items)
                }
                .ignoresSafeArea()
            case .privacy:
                PrivacySheet()
            case .reviewSuggestions:
                ReviewSuggestionsView(model: model)
            case .wallModeSetup:
                WallModeSetupView(wallMode: wallMode)
            }
        }
        .alert("Delete Imported Photos?", isPresented: $showDeleteConfirmation) {
            Button("Delete All Imported Photos", role: .destructive) {
                model.deleteImportedPhotos()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every app-controlled photo copy and its derived records. Your Apple Photos library is never changed.")
        }
        .onChange(of: model.curationPhase) { phase in
            if case .ready = phase {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    guard presentedSheet == nil,
                          case .ready = model.curationPhase else {
                        return
                    }
                    presentedSheet = .reviewSuggestions
                }
            }
        }
        .onChange(of: isFrameMode) { isActive in
            wallMode.setFrameModeActive(isActive)
        }
        .onAppear {
            wallMode.setFrameModeActive(isFrameMode)
        }
        .onDisappear {
            wallMode.restoreOwnedDisplayState()
        }
    }

    private var chrome: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                sampleBadge

                Spacer()

                if !model.importedPhotos.isEmpty {
                    Picker("Displayed photos", selection: $model.collectionMode) {
                        ForEach(PhotoCollectionMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 280)
                    .padding(6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 26)
            .padding(.top, 18)

            Spacer()

            setupCard
                .padding(.horizontal, 26)
                .padding(.bottom, 18)
        }
    }

    @ViewBuilder
    private var sampleBadge: some View {
        if model.collectionMode == .samples || model.importedPhotos.isEmpty {
            Label("SAMPLE PHOTOS", systemImage: "sparkles")
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.black.opacity(0.52), in: Capsule())
                .accessibilityLabel("Bundled sample photos")
        }
    }

    private var setupCard: some View {
        HStack(spacing: 22) {
            VStack(alignment: .leading, spacing: 7) {
                Text(model.importedPhotos.isEmpty ? "Make it yours" : "Your private reel")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)

                if model.importedPhotos.isEmpty {
                    Text("Choose up to 100 photos. FrameWink keeps only display-sized copies on this iPad.")
                        .foregroundColor(.secondary)
                } else {
                    Text(curationStatus)
                        .foregroundColor(.secondary)

                    if case .analyzing(let progress) = model.curationPhase {
                        ProgressView(value: progress.fractionCompleted)
                            .accessibilityLabel("Smart Reel analysis progress")
                            .accessibilityValue("\(progress.completedCount) of \(progress.totalCount)")
                    }
                }
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 10) {
                HStack {
                    Button("Privacy") {
                        presentedSheet = .privacy
                    }
                    .buttonStyle(.bordered)

                    Button("Wall Mode Setup") {
                        presentedSheet = .wallModeSetup
                    }
                    .buttonStyle(.bordered)
                    .accessibilityHint("Opens the paid Wall Mode commissioning and schedule preview")

                    Button(model.importedPhotos.isEmpty ? "Choose My Photos" : "Add Photos") {
                        presentedSheet = .photoPicker
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityHint("Opens the system photo picker with a 100-photo limit")
                }

                Button {
                    isFrameMode = true
                } label: {
                    Label("Play Full Screen", systemImage: "play.fill")
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Starts the full-screen photo frame with playback controls")
                .disabled(
                    model.collectionMode == .personal
                        && !model.importedPhotos.isEmpty
                        && model.smartReel == nil
                )

                if !model.importedPhotos.isEmpty {
                    HStack {
                        Button("Review Suggestions") {
                            presentedSheet = .reviewSuggestions
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.smartReel == nil)

                        if model.isCurating {
                            Button("Stop Curating", role: .cancel) {
                                model.cancelCuration()
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button("Refresh Smart Reel") {
                                model.refreshSmartReel()
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    Button("Delete Imported Photos", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .font(.footnote.weight(.semibold))
                }
            }
        }
        .padding(22)
        .frame(maxWidth: 860)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 20, y: 8)
        .accessibilityElement(children: .contain)
    }

    private var curationStatus: String {
        switch model.curationPhase {
        case .idle:
            return "\(model.importedPhotos.count) imported photos are ready offline."
        case .analyzing(let progress):
            return "Curating \(progress.completedCount) of \(progress.totalCount) photos on this iPad."
        case .ready(let count):
            return "\(count) Smart Reel suggestions are ready to review."
        case .cancelled:
            return "Curation stopped. Saved analysis will be reused when you resume."
        case .failed:
            return "Smart Reel needs another try; your imported photos are still available."
        }
    }
}

private struct PrivacySheet: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 54))
                        .foregroundColor(.accentColor)
                        .accessibilityHidden(true)

                    Text("Private by design")
                        .font(.largeTitle.bold())

                    Text("FrameWink has no server and never uploads your photos. Selection, preparation, and display happen on this iPad.")
                        .font(.title3)

                    privacyPoint(
                        icon: "photo.on.rectangle.angled",
                        title: "You choose what enters",
                        detail: "The system picker shares only the photos you select. It does not grant FrameWink access to browse your library."
                    )

                    privacyPoint(
                        icon: "arrow.down.right.and.arrow.up.left",
                        title: "Display-sized local copies",
                        detail: "Imports are downsampled before they are saved to keep storage and memory use bounded."
                    )

                    privacyPoint(
                        icon: "trash",
                        title: "Delete whenever you want",
                        detail: "Delete Imported Photos removes app-controlled copies and derived records without changing Apple Photos."
                    )
                }
                .frame(maxWidth: 640, alignment: .leading)
                .padding(32)
            }
            .navigationTitle("Privacy")
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

    private func privacyPoint(
        icon: String,
        title: LocalizedStringKey,
        detail: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 34)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .foregroundColor(.secondary)
            }
        }
    }
}
