//
//  TrimrPixError.swift
//  TrimrPix for iOS
//
//  Created by Jarl Lyng on 24/03/2026.
//

import Foundation

/// Error types for the TrimrPix iOS app
nonisolated enum TrimrPixError: LocalizedError, Sendable {

    // Image Loading
    case imageLoadFailed(underlyingError: Error?)
    case unsupportedImageFormat(String)
    case invalidImageData

    // Compression
    case compressionFailed(format: String, underlyingError: Error?)
    case formatNotSupported(String)

    // Photos Library
    case photosAccessDenied
    case photosAccessRestricted
    case assetNotFound(String)
    case assetReplaceFailed(underlyingError: Error?)

    // General
    case userCancelled
    case unknown(underlyingError: Error?)

    var errorDescription: String? {
        switch self {
        case .imageLoadFailed:
            return String(localized: "Failed to load image")
        case .unsupportedImageFormat(let format):
            return String(localized: "Unsupported image format: \(format)")
        case .invalidImageData:
            return String(localized: "Invalid image data")
        case .compressionFailed(let format, _):
            return String(localized: "\(format) compression failed")
        case .formatNotSupported(let format):
            return String(localized: "Format not supported: \(format)")
        case .photosAccessDenied:
            return String(localized: "Photos access denied")
        case .photosAccessRestricted:
            return String(localized: "Photos access restricted")
        case .assetNotFound:
            return String(localized: "Photo not found in library")
        case .assetReplaceFailed:
            return String(localized: "Failed to replace photo in library")
        case .userCancelled:
            return String(localized: "Operation cancelled")
        case .unknown:
            return String(localized: "An unknown error occurred")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .photosAccessDenied:
            return String(localized: "Grant photo access in Settings")
        case .photosAccessRestricted:
            return String(localized: "Photo access is restricted on this device")
        case .compressionFailed:
            return String(localized: "Try a different format or quality level")
        case .assetReplaceFailed:
            return String(localized: "Make sure the app has full photo access")
        default:
            return String(localized: "Try again. If the problem persists, restart the app")
        }
    }
}
