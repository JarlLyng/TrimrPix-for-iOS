// SPDX-License-Identifier: AGPL-3.0-only
//
//  TrimrPix_for_iOSApp.swift
//  TrimrPix for iOS
//
//  Created by Jarl Lyng on 24/03/2026.
//

import SwiftUI
import Sentry

@main
struct TrimrPix_for_iOSApp: App {

    init() {
        Self.initSentry()
    }

    private static func initSentry() {
        let dsn = Secrets.sentryDSN
        guard !dsn.isEmpty, dsn != "YOUR_SENTRY_DSN_HERE" else {
            #if DEBUG
            print("[Sentry] No DSN configured — skipping initialization")
            #endif
            return
        }

        SentrySDK.start { options in
            options.dsn = dsn

            #if DEBUG
            options.debug = true
            options.environment = "debug"
            options.tracesSampleRate = 1.0
            #else
            options.environment = "production"
            options.tracesSampleRate = 0.2
            #endif

            options.enableAutoSessionTracking = true
            options.enableAppHangTracking = true
            options.appHangTimeoutInterval = 2
            // Screenshots and view hierarchy are intentionally disabled: the
            // Configure/Confirm/Result screens render thumbnails of the user's
            // selected photos, and capturing them on crash would transmit photo
            // content to Sentry — contradicting our privacy promise that photos
            // never leave the device. See issue #28.
            options.attachScreenshot = false
            options.attachViewHierarchy = false
            options.enableMetricKit = true
            options.enableCaptureFailedRequests = true
            options.enableAutoPerformanceTracing = true
        }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        SentrySDK.configureScope { scope in
            scope.setTag(value: "\(version) (\(build))", key: "app_version")
        }

        #if DEBUG
        print("[Sentry] Initialized for TrimrPix iOS v\(version)")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
