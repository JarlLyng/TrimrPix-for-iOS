// SPDX-License-Identifier: AGPL-3.0-only
//
//  TrimrPix_for_iOSTests.swift
//  TrimrPix for iOSTests
//
//  Unit tests for the core, platform-independent services and models (#21).
//  Test images are generated in memory (no bundled fixtures) so the suite is
//  self-contained.
//
//  Created by Jarl Lyng on 24/03/2026.
//

import Testing
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import TrimrPix_for_iOS

// MARK: - Image fixtures

/// Builds an in-memory image. `noisy` produces high-frequency content that
/// resists compression (good for exercising quality/target search); the smooth
/// gradient otherwise compresses easily. `embedMetadata` writes GPS + EXIF so
/// metadata-stripping can be verified on a real round-trip.
private func makeImageData(
    width: Int = 256,
    height: Int = 256,
    utType: UTType = .png,
    noisy: Bool = false,
    embedMetadata: Bool = false
) -> Data {
    let bytesPerRow = width * 4
    var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
    for y in 0..<height {
        for x in 0..<width {
            let i = y * bytesPerRow + x * 4
            if noisy {
                pixels[i]     = UInt8((x &* 73 &+ y &* 151 &+ x &* y) & 0xFF)
                pixels[i + 1] = UInt8((x &* 91 &+ y &* 13) & 0xFF)
                pixels[i + 2] = UInt8((x &* 7 &+ y &* 197) & 0xFF)
            } else {
                pixels[i]     = UInt8((x * 255) / max(1, width - 1))
                pixels[i + 1] = UInt8((y * 255) / max(1, height - 1))
                pixels[i + 2] = 128
            }
            pixels[i + 3] = 255
        }
    }

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(
        data: &pixels, width: width, height: height,
        bitsPerComponent: 8, bytesPerRow: bytesPerRow,
        space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    let cgImage = context.makeImage()!

    let output = NSMutableData()
    let destination = CGImageDestinationCreateWithData(output, utType.identifier as CFString, 1, nil)!

    var properties: [CFString: Any] = [:]
    if embedMetadata {
        properties[kCGImagePropertyGPSDictionary] = [
            kCGImagePropertyGPSLatitude: 55.6761,
            kCGImagePropertyGPSLongitude: 12.5683,
        ] as CFDictionary
        properties[kCGImagePropertyExifDictionary] = [
            kCGImagePropertyExifISOSpeedRatings: [100],
            kCGImagePropertyExifDateTimeOriginal: "2026:01:01 10:00:00",
        ] as CFDictionary
    }

    CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
    _ = CGImageDestinationFinalize(destination)
    return output as Data
}

private func decodedImage(from data: Data) -> CGImage? {
    CGImageSourceCreateWithData(data as CFData, nil)
        .flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }
}

private func uniqueColorCount(of image: CGImage) -> Int {
    let w = image.width, h = image.height
    var pixels = [UInt8](repeating: 0, count: w * h * 4)
    let context = CGContext(
        data: &pixels, width: w, height: h,
        bitsPerComponent: 8, bytesPerRow: w * 4,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
    var colors = Set<UInt32>()
    for i in stride(from: 0, to: pixels.count, by: 4) {
        let packed = UInt32(pixels[i]) << 24 | UInt32(pixels[i + 1]) << 16
            | UInt32(pixels[i + 2]) << 8 | UInt32(pixels[i + 3])
        colors.insert(packed)
    }
    return colors.count
}

// MARK: - CompressionService

@Suite struct CompressionServiceTests {

    @Test func compressesToValidImageOfSameDimensions() throws {
        let service = CompressionService()
        let source = makeImageData(width: 256, height: 256, utType: .png, noisy: true)

        let out = try service.compress(data: source, mode: .quality(.good), format: .jpeg)
        #expect(!out.isEmpty)

        let image = decodedImage(from: out)
        #expect(image?.width == 256)
        #expect(image?.height == 256)
    }

    @Test func smallerQualityProducesSmallerOrEqualOutput() throws {
        let service = CompressionService()
        // Lossless PNG source so JPEG encoding always actually compresses.
        let source = makeImageData(width: 512, height: 512, utType: .png, noisy: true)

        let same = try service.compress(data: source, mode: .quality(.same), format: .jpeg)
        let smaller = try service.compress(data: source, mode: .quality(.smaller), format: .jpeg)

        #expect(smaller.count <= same.count)
    }

    @Test func invalidDataThrows() {
        let service = CompressionService()
        #expect(throws: TrimrPixError.self) {
            try service.compress(data: Data([0x00, 0x01, 0x02, 0x03]), mode: .quality(.good), format: .jpeg)
        }
    }

    @Test func targetSizeFitsWhenAchievable() throws {
        let service = CompressionService()
        let source = makeImageData(width: 512, height: 512, utType: .png, noisy: false)

        let out = try service.compress(data: source, mode: .targetSize(1_000_000), format: .jpeg)
        #expect(Int64(out.count) <= 1_000_000)
        #expect(decodedImage(from: out)?.width == 512)
    }

    @Test func targetSizeNeverExceedsMaxQualitySize() throws {
        let service = CompressionService()
        let source = makeImageData(width: 512, height: 512, utType: .png, noisy: true)

        let maxQuality = try service.compress(data: source, mode: .quality(.same), format: .jpeg)
        let targeted = try service.compress(data: source, mode: .targetSize(40_000), format: .jpeg)

        // A tight target must not produce a file larger than the highest-quality encode.
        #expect(targeted.count <= maxQuality.count)
    }

    @Test func estimateIsPositiveAndCappedAtOriginal() {
        let service = CompressionService()
        let source = makeImageData(width: 512, height: 512, utType: .jpeg, noisy: false)

        let estimate = service.estimateCompressedSize(data: source, quality: .good, format: .jpeg)
        #expect(estimate > 0)
        #expect(estimate <= Int64(source.count))
    }
}

// MARK: - ColorQuantizer

@Suite struct ColorQuantizerTests {

    @Test func reducesToAtMostMaxColors() throws {
        let source = makeImageData(width: 48, height: 48, utType: .png, noisy: true)
        let cgImage = try #require(decodedImage(from: source))

        let quantized = try #require(ColorQuantizer().quantize(cgImage, maxColors: 8))
        #expect(quantized.width == 48)
        #expect(quantized.height == 48)
        // Allow one extra slot for a possible transparent palette entry.
        #expect(uniqueColorCount(of: quantized) <= 8 + 1)
    }

    @Test func fewerColorsThanMoreColors() throws {
        let source = makeImageData(width: 48, height: 48, utType: .png, noisy: true)
        let cgImage = try #require(decodedImage(from: source))

        let coarse = uniqueColorCount(of: try #require(ColorQuantizer().quantize(cgImage, maxColors: 4)))
        let fine = uniqueColorCount(of: try #require(ColorQuantizer().quantize(cgImage, maxColors: 64)))
        #expect(coarse <= fine)
    }
}

// MARK: - MetadataStrippingOptions

@Suite struct MetadataStrippingOptionsTests {

    private func properties(from data: Data, options: MetadataStrippingOptions) -> [CFString: Any]? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return options.processedProperties(from: source) as? [CFString: Any]
    }

    @Test func stripsGPSByDefault() {
        let data = makeImageData(utType: .jpeg, embedMetadata: true)
        let props = properties(from: data, options: MetadataStrippingOptions())
        #expect(props?[kCGImagePropertyGPSDictionary] == nil)
    }

    @Test func keepsGPSWhenRequested() {
        let data = makeImageData(utType: .jpeg, embedMetadata: true)
        var options = MetadataStrippingOptions()
        options.keepGPS = true
        let props = properties(from: data, options: options)
        #expect(props?[kCGImagePropertyGPSDictionary] != nil)
    }

    @Test func keepsDateTimeButStripsCameraSettingsByDefault() {
        // Defaults: keepDateTime = true, keepCameraSettings = false.
        let data = makeImageData(utType: .jpeg, embedMetadata: true)
        let props = properties(from: data, options: MetadataStrippingOptions())
        let exif = props?[kCGImagePropertyExifDictionary] as? [CFString: Any]

        #expect(exif?[kCGImagePropertyExifDateTimeOriginal] != nil)   // kept
        #expect(exif?[kCGImagePropertyExifISOSpeedRatings] == nil)    // stripped
    }
}

// MARK: - Models

@Suite struct ModelTests {

    @Test func outputFormatFromUTI() {
        #expect(OutputFormat.from(uti: "public.jpeg") == .jpeg)
        #expect(OutputFormat.from(uti: "public.png") == .png)
        #expect(OutputFormat.from(uti: "public.heic") == .heic)
        #expect(OutputFormat.from(uti: "org.webmproject.webp") == .webp)
        #expect(OutputFormat.from(uti: "com.adobe.raw-image") == nil)
    }

    @Test func outputFormatFromPathExtension() {
        #expect(OutputFormat.from(pathExtension: "JPG") == .jpeg)
        #expect(OutputFormat.from(pathExtension: "jpeg") == .jpeg)
        #expect(OutputFormat.from(pathExtension: "heif") == .heic)
        #expect(OutputFormat.from(pathExtension: "dng") == nil)
    }

    @Test func pngMaxColorsDifferentiatesQualityLevels() {
        #expect(CompressionQuality.same.pngMaxColors == nil)   // lossless
        #expect(CompressionQuality.good.pngMaxColors == 256)
        #expect(CompressionQuality.smaller.pngMaxColors == 64)
        // Lossy quality decreases from Same → Smaller.
        #expect(CompressionQuality.same.quality > CompressionQuality.smaller.quality)
    }

    @Test func targetSizeBytesAreDecimal() {
        #expect(TargetSize.kb500.bytes == 500_000)
        #expect(TargetSize.mb1.bytes == 1_000_000)
        #expect(TargetSize.mb5.bytes == 5_000_000)
        #expect(TargetSize.mb1.label == "1 MB")
    }
}
