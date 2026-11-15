// SPDX-License-Identifier: AGPL-3.0-only
//
//  DiagnosticsRedaction.swift
//  TrimrPix for iOS
//

import Foundation

/// Removes the per-installation identifier that hides in crash report paths.
///
/// Every stack frame's `package` and every debug image's `code_file` is an
/// absolute path, and on iOS an app's bundle lives under
/// `/var/containers/Bundle/Application/<UUID>/`. iOS assigns that UUID a new
/// value on every install **and every update**, so it is a per-installation
/// identifier, and it left the device on every crash report (#90, rule 1).
///
/// It is easy to miss because it is not a field anyone added: it rides along
/// inside strings that look like plain file paths.
///
/// The UUID is replaced rather than the path dropped, so the rest of the path
/// still reads normally and frames stay groupable. `in_app` is unaffected:
/// sentry-cocoa sets it as its own property on the frame before `beforeSend`
/// runs, so rewriting `package` afterwards cannot change it.
nonisolated enum DiagnosticsRedaction {

    /// What a redacted container UUID is replaced with. A well-formed UUID, so
    /// anything parsing the path still sees the shape it expects.
    static let redactedUUID = "00000000-0000-0000-0000-000000000000"

    /// Matches the UUID directly after an iOS container directory. Both the
    /// bundle container (`Bundle/Application`) and the data container
    /// (`Containers/Data/Application`) carry one.
    private static let containerUUID: NSRegularExpression? = try? NSRegularExpression(
        pattern: "(Bundle/Application/|Containers/Data/Application/)"
            + "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}"
    )

    /// Replace any per-install container UUID in `path`, leaving the rest alone.
    ///
    /// Returns the path unchanged when there is nothing to redact, which is the
    /// common case for system frames under `/usr/lib` and friends.
    static func redactContainerPaths(_ path: String) -> String {
        guard let regex = containerUUID else { return path }
        let range = NSRange(path.startIndex..<path.endIndex, in: path)
        return regex.stringByReplacingMatches(
            in: path,
            range: range,
            withTemplate: "$1" + redactedUUID
        )
    }

    /// Convenience for optional values, since the Sentry fields are nullable.
    static func redactContainerPaths(_ path: String?) -> String? {
        path.map(redactContainerPaths)
    }
}
