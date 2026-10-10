// SPDX-License-Identifier: AGPL-3.0-only
//
//  SupportContact.swift
//  TrimrPix for iOS
//

import Foundation
import UIKit

/// The one address users can reach, and the prefilled mail that goes with it.
///
/// The app collects no usage data, so what people choose to tell us is the only
/// way we learn how it is used. Asking for a public review while offering no
/// private route leaves an unhappy user nowhere to go but the review (#58).
///
/// The version lines are put in the mail body rather than sent anywhere, so the
/// user reads everything before it leaves the device.
enum SupportContact {
    static let address = "support@iamjarl.com"

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    /// `mailto:` with the subject and the two version lines already filled in.
    /// Returns nil only if the components cannot form a URL, which would mean a
    /// malformed address constant.
    static var feedbackURL: URL? {
        let subject = "TrimrPix for iOS \(appVersion) feedback"
        let body = """


        ---
        App version: \(appVersion)
        iOS version: \(UIDevice.current.systemVersion)
        """

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = address
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }
}
