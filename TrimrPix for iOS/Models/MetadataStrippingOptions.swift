//
//  MetadataStrippingOptions.swift
//  TrimrPix for iOS
//
//  Created by Jarl Lyng on 24/03/2026.
//

import Foundation
import ImageIO

/// Controls which metadata categories are stripped during compression
nonisolated struct MetadataStrippingOptions: Sendable {
    var keepDateTime: Bool = true
    var stripCameraSettings: Bool = true
    var stripGPS: Bool = true
    var stripIPTC: Bool = true
    var stripAppleMaker: Bool = true

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
        if stripGPS {
            properties.removeValue(forKey: kCGImagePropertyGPSDictionary)
        }

        // EXIF — selective stripping
        if stripCameraSettings || !keepDateTime {
            if var exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
                if stripCameraSettings && keepDateTime {
                    // Keep only date/time keys, remove everything else
                    let keysToKeep = exif.filter { Self.dateTimeKeys.contains($0.key as String) }
                    exif = keysToKeep
                } else if stripCameraSettings && !keepDateTime {
                    // Remove entire EXIF
                    exif = [:]
                } else if !stripCameraSettings && !keepDateTime {
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
            if stripCameraSettings && keepDateTime {
                // Keep DateTime, remove camera model etc.
                let dateKey = kCGImagePropertyTIFFDateTime as String
                let dateValue = tiff[kCGImagePropertyTIFFDateTime]
                tiff = [:]
                if let dateValue {
                    tiff[dateKey as CFString] = dateValue
                }
                properties[kCGImagePropertyTIFFDictionary] = tiff as CFDictionary
            } else if stripCameraSettings && !keepDateTime {
                properties[kCGImagePropertyTIFFDictionary] = [:] as CFDictionary
            } else if !stripCameraSettings && !keepDateTime {
                tiff.removeValue(forKey: kCGImagePropertyTIFFDateTime)
                properties[kCGImagePropertyTIFFDictionary] = tiff as CFDictionary
            }
        }

        // IPTC
        if stripIPTC {
            properties.removeValue(forKey: kCGImagePropertyIPTCDictionary)
        }

        // Apple Maker
        if stripAppleMaker {
            properties.removeValue(forKey: kCGImagePropertyMakerAppleDictionary)
        }

        return properties as CFDictionary
    }

    /// User-facing labels for each option
    static let labels: [(keyPath: WritableKeyPath<MetadataStrippingOptions, Bool>, label: String, description: String, isInverted: Bool)] = [
        (\.keepDateTime, "Dato og klokkeslaet", "Hvornaar billedet blev taget", true),
        (\.stripCameraSettings, "Kameraindstillinger", "Model, eksponering, ISO, blaende", false),
        (\.stripGPS, "GPS-lokation", "Bredde- og laengdegrad, hoejde", false),
        (\.stripIPTC, "Copyright og beskrivelse", "Fotograf, billedtekst, noegleord", false),
        (\.stripAppleMaker, "Apple-data", "Live Photo, HDR, burst-info", false),
    ]
}
