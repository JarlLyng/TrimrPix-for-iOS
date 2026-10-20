// SPDX-License-Identifier: AGPL-3.0-only
//
//  SizeChange.swift
//  TrimrPix for iOS
//
//  Created by Jarl Lyng on 20/10/2026.
//

import Foundation

/// A compressed photo's size before and after, and what it saved. The result
/// screen's "Space saved" and "Avg. savings" and the lifetime counter all
/// read from this, so they can't drift apart.
nonisolated struct SizeChange: Hashable, Sendable {
    /// The photo's size before compression.
    let before: Int64
    /// The compressed bytes written back to the library.
    let after: Int64

    /// `librarySize` is the photo's current version in the library, measured
    /// just before it was edited. The picker's bytes can be a re-encoded copy
    /// of a different size, smaller or larger (a 1.27 MB JPEG arrived as
    /// 993 KB, a 2.8 MB HEIC as 4.1 MB), so they are only the fallback for
    /// when Photos can't give a size.
    init(librarySize: Int64?, pickerSize: Int64, after: Int64) {
        self.before = librarySize ?? pickerSize
        self.after = after
    }

    /// Bytes saved. Never negative: a photo that came out larger counts as
    /// saving nothing.
    var savedBytes: Int64 { max(0, before - after) }

    /// Savings as a whole percentage of `before` (0-100).
    var savedPercentage: Int {
        guard before > 0 else { return 0 }
        return Int((Double(savedBytes) / Double(before) * 100).rounded())
    }

    /// Total bytes saved across `changes`.
    static func totalSaved(_ changes: [SizeChange]) -> Int64 {
        changes.reduce(0) { $0 + $1.savedBytes }
    }

    /// The mean of each photo's percentage, so one large photo doesn't
    /// outweigh the rest. 0 for no photos.
    static func averagePercentage(_ changes: [SizeChange]) -> Int {
        guard !changes.isEmpty else { return 0 }
        return changes.reduce(0) { $0 + $1.savedPercentage } / changes.count
    }
}
