//
//  OutputFormat.swift
//  TrimrPix for iOS
//
//  Created by Jarl Lyng on 24/03/2026.
//

import Foundation
import UniformTypeIdentifiers

/// Supported output formats for compressed images
nonisolated enum OutputFormat: String, CaseIterable, Identifiable, Sendable {
    case jpeg = "JPEG"
    case png = "PNG"
    case webp = "WebP"
    case heic = "HEIC"

    var id: String { rawValue }

    /// The UTType identifier for this format
    var utType: UTType {
        switch self {
        case .jpeg: return .jpeg
        case .png: return .png
        case .webp: return .webP
        case .heic: return .heic
        }
    }

    /// File extension for this format
    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        case .webp: return "webp"
        case .heic: return "heic"
        }
    }

    /// Map a file extension (case-insensitive, without leading dot) to an
    /// `OutputFormat`, or nil if it's an unsupported format (e.g. `.dng` RAW).
    /// Used for in-place Photos-library replacement where the output file
    /// must match the asset's original format or Photos will reject the
    /// commit with `PHPhotosErrorInvalidResource` (code 3302).
    static func from(pathExtension ext: String) -> OutputFormat? {
        switch ext.lowercased() {
        case "jpg", "jpeg": return .jpeg
        case "png": return .png
        case "webp": return .webp
        case "heic", "heif": return .heic
        default: return nil
        }
    }
}
