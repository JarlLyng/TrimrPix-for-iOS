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
            return "Failed to load image"
        case .unsupportedImageFormat(let format):
            return "Unsupported image format: \(format)"
        case .invalidImageData:
            return "Invalid image data"
        case .compressionFailed(let format, _):
            return "\(format) compression failed"
        case .formatNotSupported(let format):
            return "Format not supported: \(format)"
        case .photosAccessDenied:
            return "Photos access denied"
        case .photosAccessRestricted:
            return "Photos access restricted"
        case .assetNotFound:
            return "Photo not found in library"
        case .assetReplaceFailed:
            return "Failed to replace photo in library"
        case .userCancelled:
            return "Operation cancelled"
        case .unknown:
            return "An unknown error occurred"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .photosAccessDenied:
            return "Grant photo access in Settings"
        case .photosAccessRestricted:
            return "Photo access is restricted on this device"
        case .compressionFailed:
            return "Try a different format or quality level"
        case .assetReplaceFailed:
            return "Make sure the app has full photo access"
        default:
            return "Try again. If the problem persists, restart the app"
        }
    }
}
