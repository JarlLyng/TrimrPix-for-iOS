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
    static func from(pathExtension ext: String) -> OutputFormat? {
        switch ext.lowercased() {
        case "jpg", "jpeg": return .jpeg
        case "png": return .png
        case "webp": return .webp
        case "heic", "heif": return .heic
        default: return nil
        }
    }

    /// Map a Uniform Type Identifier to an `OutputFormat`. Used for in-place
    /// Photos-library replacement where the output bytes must match the
    /// asset's *original* resource UTI, not the `renderedContentURL`'s file
    /// extension (Photos sometimes hands us a `.JPG` URL for HEIC originals
    /// because PhotosPicker/content-editing transcodes for the input side,
    /// but the commit-time validation checks against the original UTI and
    /// rejects with `PHPhotosErrorInvalidResource` (3302) on mismatch).
    static func from(uti: String) -> OutputFormat? {
        switch uti.lowercased() {
        case "public.jpeg": return .jpeg
        case "public.png": return .png
        case "org.webmproject.webp", "public.webp": return .webp
        case "public.heic", "public.heif": return .heic
        default: return nil
        }
    }
}
