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
            options.enableAutoPerformanceTracing = true
            #else
            options.environment = "production"
            // No performance tracing in production: the app makes no network
            // calls, so transactions would be low-value, and MetricKit already
            // covers launch time / hangs / energy natively. Keeps the crash
            // focus lean and off Sentry's transaction quota.
            options.tracesSampleRate = 0
            options.enableAutoPerformanceTracing = false
            #endif

            // Never send personally identifiable information. It's the default,
            // but stated explicitly because privacy is the whole point (and the
            // source is public).
            options.sendDefaultPii = false

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
            // enableCaptureFailedRequests intentionally omitted: the app is
            // fully offline and makes no network requests, so there is nothing
            // to capture.
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
