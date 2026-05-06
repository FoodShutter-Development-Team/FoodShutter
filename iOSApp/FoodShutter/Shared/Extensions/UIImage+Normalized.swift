//
//  UIImage+Normalized.swift
//  FoodShutter
//

import UIKit

extension UIImage {
    /// Returns a copy with imageOrientation == .up by redrawing into a new context.
    /// Required so that bbox coordinates (computed on the uploaded JPEG, which is always
    /// drawn into a context and therefore orientation-flattened) align with the displayed image.
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
