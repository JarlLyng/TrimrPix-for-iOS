//
//  MetadataStrippingOptions.swift
//  TrimrPix for iOS
//
//  Created by Jarl Lyng on 24/03/2026.
//

import Foundation
import ImageIO

/// Controls which metadata categories are kept during compression.
/// All toggles use "keep" semantics: true = keep, false = strip.
nonisolated struct MetadataStrippingOptions: Sendable, Codable, Equatable {
    var keepDateTime: Bool = true
    var keepCameraSettings: Bool = false
    var keepGPS: Bool = false
    var keepIPTC: Bool = false
    var keepAppleMaker: Bool = false

    /// EXIF keys that contain date/time information
    private static let dateTimeKeys: Set<String> = [
        kCGImagePropertyExifDateTimeOriginal as String,
        kCGImagePropertyExifDateTimeDigitized as String,
        kCGImagePropertyExifSubsecTime as String,
        kCGImagePropertyExifSubsecTimeOriginal as String,
        kCGImagePropertyExifSubsecTimeDigitized as String,
        kCGImagePropertyExifOffsetTime as String,
        kCGImagePropertyExifOffsetTimeOriginal as String,
        kCGImagePropertyExifOffsetTimeDigitized as String,
    ]

    /// Processes the metadata properties from an image source, stripping selected categories
    func processedProperties(from source: CGImageSource, index: Int = 0) -> CFDictionary? {
        guard var properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] else {
            return nil
        }

        // GPS
        if !keepGPS {
            properties.removeValue(forKey: kCGImagePropertyGPSDictionary)
        }

        // EXIF — selective stripping
        if !keepCameraSettings || !keepDateTime {
            if var exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
                if !keepCameraSettings && keepDateTime {
                    // Keep only date/time keys, remove everything else
                    let keysToKeep = exif.filter { Self.dateTimeKeys.contains($0.key as String) }
                    exif = keysToKeep
                } else if !keepCameraSettings && !keepDateTime {
                    // Remove entire EXIF
                    exif = [:]
                } else if keepCameraSettings && !keepDateTime {
                    // Remove only date/time keys
                    for key in Self.dateTimeKeys {
                        exif.removeValue(forKey: key as CFString)
                    }
                }
                properties[kCGImagePropertyExifDictionary] = exif as CFDictionary
            }
        }

        // Also handle TIFF DateTime if present
        if var tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
            if !keepCameraSettings && keepDateTime {
                // Keep DateTime, remove camera model etc.
                let dateValue = tiff[kCGImagePropertyTIFFDateTime]
                tiff = [:]
                if let dateValue {
                    tiff[kCGImagePropertyTIFFDateTime] = dateValue
                }
                properties[kCGImagePropertyTIFFDictionary] = tiff as CFDictionary
            } else if !keepCameraSettings && !keepDateTime {
                properties[kCGImagePropertyTIFFDictionary] = [:] as CFDictionary
            } else if keepCameraSettings && !keepDateTime {
                tiff.removeValue(forKey: kCGImagePropertyTIFFDateTime)
                properties[kCGImagePropertyTIFFDictionary] = tiff as CFDictionary
            }
        }

        // IPTC
        if !keepIPTC {
            properties.removeValue(forKey: kCGImagePropertyIPTCDictionary)
        }

        // Apple Maker
        if !keepAppleMaker {
            properties.removeValue(forKey: kCGImagePropertyMakerAppleDictionary)
        }

        return properties as CFDictionary
    }

    /// User-facing labels for each option
    static let labels: [(keyPath: WritableKeyPath<MetadataStrippingOptions, Bool>, label: String, description: String)] = [
        (\.keepDateTime, "Date & time", "When the photo was taken"),
        (\.keepCameraSettings, "Camera settings", "Model, exposure, ISO, aperture"),
        (\.keepGPS, "GPS location", "Latitude, longitude, altitude"),
        (\.keepIPTC, "Copyright & description", "Photographer, caption, keywords"),
        (\.keepAppleMaker, "Apple data", "Live Photo, HDR, burst info"),
    ]
}
