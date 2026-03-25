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

    /// Compresses image data to the specified format and quality
    func compress(
        data: Data,
        quality: CompressionQuality,
        format: OutputFormat,
        metadataOptions: MetadataStrippingOptions = MetadataStrippingOptions()
    ) throws -> Data {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw TrimrPixError.invalidImageData
        }

        let processedProps = metadataOptions.processedProperties(from: imageSource)

        let compressedData: Data

        switch format {
        case .png:
            compressedData = try compressPNG(cgImage: cgImage, quality: quality, properties: processedProps)
        case .jpeg:
            compressedData = try compressWithDestination(cgImage: cgImage, type: .jpeg, quality: quality, properties: processedProps)
        case .webp:
            compressedData = try compressWithDestination(cgImage: cgImage, type: .webP, quality: quality, properties: processedProps)
        case .heic:
            compressedData = try compressWithDestination(cgImage: cgImage, type: .heic, quality: quality, properties: processedProps)
        }

        // If compression made the file larger, return original with metadata processed
        if compressedData.count >= data.count {
            return reencodeWithProperties(from: data, properties: processedProps) ?? data
        }

        return compressedData
    }

    /// Estimates the compressed size without fully encoding
    func estimateCompressedSize(
        data: Data,
        quality: CompressionQuality,
        format: OutputFormat,
        metadataOptions: MetadataStrippingOptions = MetadataStrippingOptions()
    ) -> Int64 {
        guard let compressed = try? compress(data: data, quality: quality, format: format, metadataOptions: metadataOptions) else {
            return Int64(data.count)
        }
        return Int64(compressed.count)
    }

    // MARK: - Private

    /// Compresses using CGImageDestination (JPEG, WebP, HEIC)
    private func compressWithDestination(
        cgImage: CGImage,
        type: UTType,
        quality: CompressionQuality,
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
        options[kCGImageDestinationLossyCompressionQuality] = quality.quality

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
        let metaOptions = (properties as? [CFString: Any]) ?? [:]

        // Try lossy quantization for Good/Smaller quality levels
        if quality.pngQuantizationEnabled {
            if let quantizedImage = colorQuantizer.quantize(cgImage) {
                let outputData = NSMutableData()
                if let destination = CGImageDestinationCreateWithData(
                    outputData, UTType.png.identifier as CFString, 1, nil
                ) {
                    CGImageDestinationAddImage(destination, quantizedImage, metaOptions as CFDictionary)
                    if CGImageDestinationFinalize(destination) {
                        return outputData as Data
                    }
                }
            }
        }

        // Fallback: standard PNG re-encoding
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outputData, UTType.png.identifier as CFString, 1, nil
        ) else {
            throw TrimrPixError.compressionFailed(format: "PNG", underlyingError: nil)
        }

        CGImageDestinationAddImage(destination, cgImage, metaOptions as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw TrimrPixError.compressionFailed(format: "PNG", underlyingError: nil)
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
