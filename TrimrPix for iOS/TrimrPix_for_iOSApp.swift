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
            options.attachScreenshot = true
            options.attachViewHierarchy = true
            options.enableMetricKit = true
            options.enableCaptureFailedRequests = true
            options.enableAutoPerformanceTracing = true
        }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        SentrySDK.configureScope { scope in
            scope.setTag(value: "\(version) (\(build))", key: "app_version")
        }

        // Diagnostic: force a test event on every launch so we can verify
        // Sentry is receiving data during pre-launch testing. Remove before
        // App Store submission — see GitHub issue tracker.
        SentrySDK.capture(message: "Launch diagnostic — TrimrPix iOS v\(version) (\(build))")

        #if DEBUG
        print("[Sentry] Initialized for TrimrPix iOS v\(version)")
        print("[Sentry] Sent launch diagnostic event — check Sentry dashboard in 1-2 min")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
