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
            return "Kunne ikke indlaese billede"
        case .unsupportedImageFormat(let format):
            return "Ikke-understoettet billedformat: \(format)"
        case .invalidImageData:
            return "Ugyldig billeddata"
        case .compressionFailed(let format, _):
            return "\(format) komprimering fejlede"
        case .formatNotSupported(let format):
            return "Format ikke understoettet: \(format)"
        case .photosAccessDenied:
            return "Adgang til Fotos er naegtet"
        case .photosAccessRestricted:
            return "Adgang til Fotos er begraenset"
        case .assetNotFound:
            return "Billede ikke fundet i Fotos"
        case .assetReplaceFailed:
            return "Kunne ikke erstatte billede i Fotos"
        case .userCancelled:
            return "Operation annulleret"
        case .unknown:
            return "Ukendt fejl opstod"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .photosAccessDenied:
            return "Giv appen adgang til Fotos i Indstillinger"
        case .photosAccessRestricted:
            return "Fotos-adgang er begraenset paa denne enhed"
        case .compressionFailed:
            return "Proev et andet format eller kvalitetsniveau"
        case .assetReplaceFailed:
            return "Soerg for at appen har fuld adgang til Fotos"
        default:
            return "Proev igen. Hvis problemet vedvarer, genstart appen"
        }
    }
}
