import PhotosUI
import SwiftUI

struct PhotoPickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode

    let selectionLimit: Int
    let onSelection: ([PhotoImportItem]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = selectionLimit
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: PhotoPickerView

        init(parent: PhotoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            let items = results.map { PHPickerImportItem(itemProvider: $0.itemProvider) }
            parent.onSelection(items)
        }
    }
}
