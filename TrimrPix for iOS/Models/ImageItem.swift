//
//  ImageItem.swift
//  TrimrPix for iOS
//
//  Created by Jarl Lyng on 24/03/2026.
//

import Foundation
import SwiftUI
import UIKit
import Photos
import PhotosUI

/// Represents an image selected from the Photos library for compression.
///
/// The full original bytes are deliberately NOT retained here — only the
/// `PhotosPickerItem` token, the original byte count, and a small thumbnail.
/// The bytes are reloaded lazily, one photo at a time, when estimating or
/// compressing (#25), so a large batch never holds every photo's data in RAM
/// at once.
struct ImageItem: Identifiable {

    let id = UUID()
    let assetIdentifier: String
    /// Source token used to lazily reload the original bytes on demand.
    let pickerItem: PhotosPickerItem
    let originalSize: Int64
    var compressedSize: Int64?
    var thumbnail: UIImage?
    var isCompressing: Bool = false
    var isCompressed: Bool = false
    /// True if this photo was compressed via copy-and-delete fallback rather
    /// than true in-place replacement. Some photos (pristine HEIC with
    /// auxiliary data like HDR gain maps or spatial stereo, Live Photos, etc.)
    /// can't be replaced in place on iOS 26 because the Photos framework
    /// validates auxiliary content on commit. For those we create a new asset
    /// from the compressed data and delete the original, preserving creation
    /// date, location, and favorite status.
    var wasReplaced: Bool = false
    var error: TrimrPixError?

    /// Builds an item from data loaded once at selection time. The `data` is
    /// used only to derive the byte count and thumbnail — it is intentionally
    /// not stored (see type doc / #25); compression reloads it via `pickerItem`.
    init(pickerItem: PhotosPickerItem, assetIdentifier: String, data: Data) {
        self.pickerItem = pickerItem
        self.assetIdentifier = assetIdentifier
        self.originalSize = Int64(data.count)
        self.thumbnail = ImageItem.generateThumbnail(from: data)
    }

    /// Estimated savings as a percentage (0-100)
    var savingsPercentage: Int {
        guard let compressedSize, originalSize > 0 else { return 0 }
        let savings = Double(originalSize - compressedSize) / Double(originalSize) * 100
        return max(0, Int(savings.rounded()))
    }

    private static func generateThumbnail(from data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        let maxDimension: CGFloat = 120
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let thumbnailSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        }
    }
}

// MARK: - Formatting

extension Int64 {
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self)
    }
}
