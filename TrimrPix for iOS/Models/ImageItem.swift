//
//  ImageItem.swift
//  TrimrPix for iOS
//
//  Created by Jarl Lyng on 24/03/2026.
//

import Foundation
import UIKit
import Photos

/// Represents an image selected from the Photos library for compression
struct ImageItem: Identifiable {

    let id = UUID()
    let assetIdentifier: String
    var originalData: Data?
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

    init(assetIdentifier: String, data: Data) {
        self.assetIdentifier = assetIdentifier
        self.originalData = data
        self.originalSize = Int64(data.count)
        self.thumbnail = ImageItem.generateThumbnail(from: data)
    }

    /// Estimated savings as a percentage (0-100)
    var savingsPercentage: Int {
        guard let compressedSize, originalSize > 0 else { return 0 }
        let savings = Double(originalSize - compressedSize) / Double(originalSize) * 100
        return max(0, Int(savings.rounded()))
    }

    /// Release heavy data after compression to free memory
    mutating func releaseData() {
        originalData = nil
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
