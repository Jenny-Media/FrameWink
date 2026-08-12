import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ImageDownsampleError: LocalizedError {
    case unreadableSource
    case thumbnailCreationFailed
    case destinationCreationFailed
    case destinationFinalizeFailed

    var errorDescription: String? {
        switch self {
        case .unreadableSource:
            return "This photo could not be read."
        case .thumbnailCreationFailed:
            return "This photo format could not be prepared for display."
        case .destinationCreationFailed, .destinationFinalizeFailed:
            return "The display-sized photo could not be saved."
        }
    }
}

struct ImageIODownsampler: ImageDownsampling {
    func downsampleImage(
        at sourceURL: URL,
        to destinationURL: URL,
        maxPixelDimension: Int
    ) throws -> PixelSize {
        guard maxPixelDimension > 0 else {
            throw ImageDownsampleError.thumbnailCreationFailed
        }

        let sourceOptions = [
            kCGImageSourceShouldCache: false
        ] as CFDictionary

        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, sourceOptions) else {
            throw ImageDownsampleError.unreadableSource
        }

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelDimension
        ] as CFDictionary

        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            throw ImageDownsampleError.thumbnailCreationFailed
        }

        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw ImageDownsampleError.destinationCreationFailed
        }

        let destinationOptions = [
            kCGImageDestinationLossyCompressionQuality: 0.88
        ] as CFDictionary
        CGImageDestinationAddImage(destination, image, destinationOptions)

        guard CGImageDestinationFinalize(destination) else {
            throw ImageDownsampleError.destinationFinalizeFailed
        }

        return PixelSize(width: image.width, height: image.height)
    }
}
