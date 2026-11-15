// SPDX-License-Identifier: AGPL-3.0-only
//
//  SkipReason.swift
//  TrimrPix for iOS
//
//  Created by Jarl Lyng on 19/10/2026.
//

import Foundation

/// Why a photo was left as it is instead of compressed (#71). Nothing in the
/// library changes for a skipped photo, so it is not a failure: it isn't
/// counted as failed and isn't reported to Sentry.
nonisolated enum SkipReason: Hashable, Sendable {
    /// The photo's format can be read but not written on this device, so it
    /// can't be replaced in place. Today that's WebP: ImageIO decodes it, but
    /// `CGImageDestinationCopyTypeIdentifiers()` has no WebP encoder on iOS.
    case formatNotWritable(OutputFormat)
    /// Target-size mode, and the photo is already at or under the target.
    case alreadyUnderTarget
    /// The compressed photo came out no smaller than the one in the library,
    /// so writing it would save nothing or make the photo bigger.
    case wouldNotShrink
    /// The user declined Photos' confirmation, so nothing was replaced. This
    /// is a choice, not a failure: Photos reports it as `userCancelled`
    /// (3072), and the app used to mark every photo in the batch as an error
    /// and report each one to Sentry (#91).
    case userCancelled

    /// Localized explanation for the result screen, shown once per reason.
    var message: String {
        switch self {
        case .formatNotWritable(let format):
            return String(localized: "iOS can open \(format.rawValue) photos but can't save them, so they were left as they are.")
        case .alreadyUnderTarget:
            return String(localized: "Photos already under the target size were left as they are.")
        case .wouldNotShrink:
            return String(localized: "Photos that wouldn't get any smaller were left as they are.")
        case .userCancelled:
            return String(localized: "You chose not to replace these photos, so they were left as they are.")
        }
    }
}
