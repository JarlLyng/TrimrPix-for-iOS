// SPDX-License-Identifier: AGPL-3.0-only
//
//  CompressionService.swift
//  TrimrPix for iOS
//
//  Ported from macOS version. Adapted for iOS:
//  - Data in/out instead of URL-based file I/O
//  - No AppKit dependencies (uses CoreGraphics/ImageIO directly)
//  - Quality controlled by CompressionQuality enum instead of Settings
//  - Granular metadata stripping via MetadataStrippingOptions
//
//  Created by Jarl Lyng on 24/03/2026.
//

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Service responsible for image compression
nonisolated final class CompressionService: Sendable {

    private let colorQuantizer = ColorQuantizer()

    /// Compresses image data using the given mode (fixed quality or a per-photo
    /// target size) and format.
    func compress(
        data: Data,
        mode: CompressionMode,
        format: OutputFormat,
        metadataOptions: MetadataStrippingOptions = MetadataStrippingOptions()
    ) throws -> Data {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw TrimrPixError.invalidImageData
        }

        let processedProps = metadataOptions.processedProperties(from: imageSource)

        let compressedData: Data
        switch mode {
        case .quality(let quality):
            compressedData = try encode(cgImage: cgImage, format: format, quality: quality, properties: processedProps)
        case .targetSize(let target):
            compressedData = try encodeToTarget(cgImage: cgImage, format: format, target: target, properties: processedProps)
        }

        // If compression made the file larger, return original with metadata processed
        if compressedData.count >= data.count {
            return reencodeWithProperties(from: data, properties: processedProps) ?? data
        }

        return compressedData
    }

    /// Estimates the compressed size by encoding a downscaled thumbnail and
    /// scaling the result by pixel count, rather than fully encoding the image.
    /// The savings estimate is recomputed for every photo on every quality and
    /// metadata toggle, so a full-res encode per photo per change was wasteful
    /// (#31). The `format` argument is only a fallback: in-place replacement
    /// keeps each photo's original format, so we detect it from the data and
    /// estimate against that — otherwise a HEIC/PNG/WebP original would be
    /// estimated as JPEG and the number wouldn't match the real result.
    func estimateCompressedSize(
        data: Data,
        quality: CompressionQuality,
        format: OutputFormat,
        metadataOptions: MetadataStrippingOptions = MetadataStrippingOptions()
    ) -> Int64 {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return Int64(data.count)
        }

        let resolvedFormat = OutputFormat.from(uti: (CGImageSourceGetType(source) as String?) ?? "") ?? format

        // Decode a reduced-size thumbnail (caps the larger side at 1024px;
        // never upscales). Far cheaper to encode than the full-res image.
        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 1024,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        guard let sample = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary) else {
            return Int64(data.count)
        }

        let imgProps = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let fullWidth = imgProps?[kCGImagePropertyPixelWidth] as? Int ?? sample.width
        let fullHeight = imgProps?[kCGImagePropertyPixelHeight] as? Int ?? sample.height
        let originalPixels = max(1, fullWidth * fullHeight)
        let samplePixels = max(1, sample.width * sample.height)

        let processedProps = metadataOptions.processedProperties(from: source)
        guard let sampleData = try? encode(cgImage: sample, format: resolvedFormat, quality: quality, properties: processedProps) else {
            return Int64(data.count)
        }

        // Compressed size scales roughly with pixel count for a given format
        // and quality. Cap at the original size (compression never helps for
        // already-tiny files).
        let scaled = Double(sampleData.count) * Double(originalPixels) / Double(samplePixels)
        return min(Int64(scaled.rounded()), Int64(data.count))
    }

    /// Encodes a CGImage to the given format/quality. Shared by the real
    /// compression path and the estimate so both stay in sync.
    private func encode(
        cgImage: CGImage,
        format: OutputFormat,
        quality: CompressionQuality,
        properties: CFDictionary?
    ) throws -> Data {
        switch format {
        case .png:
            return try compressPNG(cgImage: cgImage, quality: quality, properties: properties)
        case .jpeg:
            return try compressWithDestination(cgImage: cgImage, type: .jpeg, lossyQuality: quality.quality, properties: properties)
        case .webp:
            return try compressWithDestination(cgImage: cgImage, type: .webP, lossyQuality: quality.quality, properties: properties)
        case .heic:
            return try compressWithDestination(cgImage: cgImage, type: .heic, lossyQuality: quality.quality, properties: properties)
        }
    }

    /// Encodes a CGImage so the result is at most `target` bytes. For lossy
    /// formats (JPEG/HEIC/WebP) it binary-searches the quality parameter for
    /// the highest quality that fits; for PNG it reduces the color palette.
    /// If even the most aggressive setting exceeds the target, returns the
    /// smallest result it could produce (the UI still reports the actual size).
    private func encodeToTarget(
        cgImage: CGImage,
        format: OutputFormat,
        target: Int64,
        properties: CFDictionary?
    ) throws -> Data {
        if format == .png {
            return try compressPNGToTarget(cgImage: cgImage, target: target, properties: properties)
        }

        let type = format.utType
        var low = 0.0
        var high = 1.0
        var bestFitting: Data?

        // ~7 iterations narrows quality to <1% — plenty for a size target.
        for _ in 0..<7 {
            let mid = (low + high) / 2
            let candidate = try compressWithDestination(cgImage: cgImage, type: type, lossyQuality: mid, properties: properties)
            if Int64(candidate.count) <= target {
                bestFitting = candidate   // fits — try to spend the headroom on higher quality
                low = mid
            } else {
                high = mid                // too big — back off quality
            }
        }

        if let bestFitting { return bestFitting }
        // Nothing fit; return the lowest-quality (smallest) encode we can make.
        return try compressWithDestination(cgImage: cgImage, type: type, lossyQuality: 0.0, properties: properties)
    }

    // MARK: - Private

    /// Compresses using CGImageDestination (JPEG, WebP, HEIC) at an explicit
    /// lossy quality (0.0–1.0).
    private func compressWithDestination(
        cgImage: CGImage,
        type: UTType,
        lossyQuality: Double,
        properties: CFDictionary?
    ) throws -> Data {
        let outputData = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(
            outputData, type.identifier as CFString, 1, nil
        ) else {
            throw TrimrPixError.compressionFailed(format: type.identifier, underlyingError: nil)
        }

        // Start with processed metadata properties
        var options: [CFString: Any] = (properties as? [CFString: Any]) ?? [:]

        // Add compression quality
        options[kCGImageDestinationLossyCompressionQuality] = lossyQuality

        // Add progressive JPEG encoding
        if type == .jpeg {
            options[kCGImagePropertyJFIFDictionary] = [
                kCGImagePropertyJFIFIsProgressive: true
            ] as CFDictionary
        }

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw TrimrPixError.compressionFailed(format: type.identifier, underlyingError: nil)
        }

        return outputData as Data
    }

    /// Compresses PNG with optional lossy quantization
    private func compressPNG(
        cgImage: CGImage,
        quality: CompressionQuality,
        properties: CFDictionary?
    ) throws -> Data {
        // Try lossy quantization for Good/Smaller quality levels. The palette
        // size comes from the quality level, so Smaller produces a smaller
        // file than Good (#32). `same` returns nil → lossless re-encode below.
        if let maxColors = quality.pngMaxColors,
           let quantizedImage = colorQuantizer.quantize(cgImage, maxColors: maxColors),
           let quantizedData = pngData(from: quantizedImage, properties: properties) {
            return quantizedData
        }

        // Fallback: standard PNG re-encoding
        guard let data = pngData(from: cgImage, properties: properties) else {
            throw TrimrPixError.compressionFailed(format: "PNG", underlyingError: nil)
        }
        return data
    }

    /// Reduces the PNG palette until the result fits `target`, returning the
    /// highest-fidelity (most colors) version that fits, or the smallest
    /// version achievable if none fit.
    private func compressPNGToTarget(
        cgImage: CGImage,
        target: Int64,
        properties: CFDictionary?
    ) throws -> Data {
        var smallest: Data?
        for colors in [256, 128, 64, 32, 16] {
            guard let quantized = colorQuantizer.quantize(cgImage, maxColors: colors),
                  let data = pngData(from: quantized, properties: properties) else {
                continue
            }
            if smallest == nil || data.count < smallest!.count {
                smallest = data
            }
            if Int64(data.count) <= target {
                return data   // most colors that still fits
            }
        }
        if let smallest { return smallest }

        // Quantization unavailable — fall back to a lossless re-encode.
        guard let data = pngData(from: cgImage, properties: properties) else {
            throw TrimrPixError.compressionFailed(format: "PNG", underlyingError: nil)
        }
        return data
    }

    /// Encodes a CGImage as PNG with the given metadata properties.
    private func pngData(from cgImage: CGImage, properties: CFDictionary?) -> Data? {
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outputData, UTType.png.identifier as CFString, 1, nil
        ) else {
            return nil
        }
        let options = (properties as? [CFString: Any]) ?? [:]
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return outputData as Data
    }

    /// Re-encodes image data with processed metadata properties
    private func reencodeWithProperties(from data: Data, properties: CFDictionary?) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }

        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(outputData, type, 1, nil) else {
            return nil
        }

        let options = (properties as? [CFString: Any]) ?? [:]
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return outputData as Data
    }
}
