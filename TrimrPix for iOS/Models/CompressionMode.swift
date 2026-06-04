//
//  CompressionMode.swift
//  TrimrPix for iOS
//
//  Created by Jarl Lyng on 04/06/2026.
//

import Foundation

/// How the compressor decides how hard to compress each photo.
/// - `.quality`: encode at a fixed quality preset (the original behavior).
/// - `.targetSize`: search the encoder settings to bring each photo to at most
///   the given number of bytes (binary-searches lossy quality for JPEG/HEIC/
///   WebP, reduces the palette for PNG).
nonisolated enum CompressionMode: Sendable {
    case quality(CompressionQuality)
    case targetSize(Int64)
}

/// UI-facing selector for which mode the user is in (the two segments of the
/// Configure-screen mode picker).
nonisolated enum CompressionModeKind: String, CaseIterable, Identifiable, Sendable {
    case quality = "Quality"
    case targetSize = "Target size"

    var id: String { rawValue }
}

/// Preset per-photo target sizes. Values are decimal (1 MB = 1,000,000 bytes)
/// to match `ByteCountFormatter`'s `.file` count style used elsewhere.
nonisolated enum TargetSize: Int64, CaseIterable, Identifiable, Sendable {
    case kb500 = 500_000
    case mb1 = 1_000_000
    case mb2 = 2_000_000
    case mb5 = 5_000_000

    var id: Int64 { rawValue }

    /// Maximum bytes per photo.
    var bytes: Int64 { rawValue }

    var label: String {
        switch self {
        case .kb500: return "500 KB"
        case .mb1: return "1 MB"
        case .mb2: return "2 MB"
        case .mb5: return "5 MB"
        }
    }
}
