//
//  ModelTransformers.swift
//  FoodShutter
//
//  Image processing utilities
//

import UIKit
import Foundation

enum TransformError: Error, LocalizedError {
    case imageConversionFailed

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "Failed to convert image to JPEG format"
        }
    }
}

struct ModelTransformers {

    // MARK: - Image Processing

    static func optimizeImageForUpload(_ image: UIImage, maxDimension: CGFloat = 1024) -> UIImage {
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
        if scale >= 1.0 { return image }
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    static func imageToJPEGData(_ image: UIImage, quality: CGFloat = 0.8) throws -> Data {
        let optimized = optimizeImageForUpload(image)
        guard let data = optimized.jpegData(compressionQuality: quality) else {
            throw TransformError.imageConversionFailed
        }
        return data
    }
}
