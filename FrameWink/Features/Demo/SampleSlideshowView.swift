import Combine
import SwiftUI
import UIKit

struct SampleSlideshowView: View {
    let slides: [DisplaySlide]
    let loadImportedImage: (ImportedPhoto) async -> UIImage?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentIndex = 0

    private let timer = Timer.publish(every: 7, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                if slides.indices.contains(currentIndex) {
                    slideImage(slides[currentIndex])
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .id(slides[currentIndex].id)
                        .transition(reduceMotion ? .identity : .opacity)
                        .accessibilityLabel(slides[currentIndex].accessibilityLabel)
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.08), .black.opacity(0.82)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                if slides.indices.contains(currentIndex) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(slides[currentIndex].title)
                            .font(.system(size: 38, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(radius: 8)

                        Text(slides[currentIndex].caption)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.84))
                    }
                    .padding(.horizontal, 34)
                    .padding(.bottom, 210)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background(Color.black)
        .clipped()
        .onReceive(timer) { _ in
            guard slides.count > 1 else { return }
            let nextIndex = (currentIndex + 1) % slides.count
            if reduceMotion {
                currentIndex = nextIndex
            } else {
                withAnimation(.easeInOut(duration: 1.1)) {
                    currentIndex = nextIndex
                }
            }
        }
        .onChange(of: slides.count) { newCount in
            if newCount == 0 {
                currentIndex = 0
            } else {
                currentIndex = min(currentIndex, newCount - 1)
            }
        }
    }

    @ViewBuilder
    private func slideImage(_ slide: DisplaySlide) -> some View {
        switch slide.source {
        case .bundled(let resourceName):
            if let image = BundledSampleImageLoader.image(named: resourceName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                Color.black
            }
        case .imported(let photo):
            ImportedSlideImage(photo: photo, loadImage: loadImportedImage)
        }
    }
}

enum BundledSampleImageLoader {
    static func image(named resourceName: String, bundle: Bundle = .main) -> UIImage? {
        guard let url = bundle.url(forResource: resourceName, withExtension: "png") else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
}

private struct ImportedSlideImage: View {
    let photo: ImportedPhoto
    let loadImage: (ImportedPhoto) async -> UIImage?

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.black
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .accessibilityLabel("Loading photo")
            }
        }
        .task(id: photo.id) {
            image = await loadImage(photo)
        }
    }
}

#if DEBUG
struct SampleSlideshowView_Previews: PreviewProvider {
    static var previews: some View {
        SampleSlideshowView(
            slides: [
                DisplaySlide(
                    id: "preview",
                    title: "Keep the good days close",
                    caption: "Bundled example · no Photos access needed",
                    accessibilityLabel: "Sample photo",
                    source: .bundled(resourceName: "sample-lakeside")
                )
            ],
            loadImportedImage: { _ in nil }
        )
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
#endif
