// SPDX-License-Identifier: AGPL-3.0-only
//
//  CompressionQuality.swift
//  TrimrPix for iOS
//
//  Created by Jarl Lyng on 24/03/2026.
//

import Foundation

/// Quality presets for image compression
nonisolated enum CompressionQuality: String, CaseIterable, Identifiable, Sendable {
    case same = "Same"
    case good = "Good"
    case smaller = "Smaller"

    var id: String { rawValue }

    /// The compression quality value (0.0 - 1.0) used by CGImageDestination
    var quality: Double {
        switch self {
        case .same: return 0.95
        case .good: return 0.80
        case .smaller: return 0.60
        }
    }

    /// Palette size for lossy PNG color quantization, or `nil` to skip
    /// quantization and re-encode losslessly. Fewer colors → smaller files,
    /// so the level genuinely differentiates PNG output (previously Good and
    /// Smaller both quantized to 256 and produced identical files — see #32).
    var pngMaxColors: Int? {
        switch self {
        case .same: return nil   // lossless re-encode, no color reduction
        case .good: return 256
        case .smaller: return 64
        }
    }

    /// Localized name shown in the picker (rawValue stays English — it is the
    /// persistence key).
    var displayName: String {
        switch self {
        case .same: return String(localized: "Same")
        case .good: return String(localized: "Good")
        case .smaller: return String(localized: "Smaller")
        }
    }

    /// User-facing description of the quality level
    var description: String {
        switch self {
        case .same: return String(localized: "No visible quality loss")
        case .good: return String(localized: "Light compression, hard to tell the difference")
        case .smaller: return String(localized: "More aggressive compression")
        }
    }
}
