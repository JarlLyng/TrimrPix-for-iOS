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

    /// Whether PNG quantization should be applied at this quality level
    var pngQuantizationEnabled: Bool {
        switch self {
        case .same: return false
        case .good: return true
        case .smaller: return true
        }
    }

    /// User-facing description of the quality level
    var description: String {
        switch self {
        case .same: return "Ingen synlig kvalitetsforringelse"
        case .good: return "Let komprimering, svaer at se forskel"
        case .smaller: return "Mere aggressiv komprimering"
        }
    }
}
