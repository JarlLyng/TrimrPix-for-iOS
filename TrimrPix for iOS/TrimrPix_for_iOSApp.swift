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
            // Only an App Store build is "production". A TestFlight build used
            // to report as production too, so our own test runs arrived looking
            // like real crashes from real users (#91).
            options.environment = Self.isTestFlightBuild ? "testflight" : "production"
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

            // Sessions are off because sentry-cocoa 9.8.0 cannot send one
            // without a per-installation ID (#90).
            //
            // A session envelope always carries `did`, and `SentryHub` fills it
            // straight from `SentryInstallation`: it never consults the user,
            // so the shared `anonymous` user does not change it. `applyToSession`
            // copies only the environment across, and `captureSession` hands the
            // envelope to `captureEnvelope` without going through `beforeSend`,
            // so the scrubbing below cannot reach it either. There is no
            // `beforeSendSession` hook. The ID is therefore unavoidable while
            // sessions are on, which is what rules them out.
            //
            // Crash-free rates are still available in Xcode Organizer, which
            // needs no identifier in the app. Re-check on an SDK upgrade: if a
            // future version can send a session without the ID, turn this back
            // on and record the envelope test in the PR.
            options.enableAutoSessionTracking = false
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
            // enableCaptureFailedRequests intentionally omitted: the app makes
            // no network requests of its own, so there is nothing to capture.

            // Anonymous is a recipe, not Sentry's default (#90). Even with no
            // user set, sentry-cocoa fills in a random per-installation ID as
            // `user.id` and records `contexts.app.device_app_hash`, a hash of
            // the vendor identifier. Apple counts data as linked unless the
            // identifiers are removed before collection, and GDPR treats a
            // persistent per-install ID as personal data — so the store label
            // "Data Not Linked to You" would not have been honest.
            //
            // One hook covers everything here. sentry-cocoa has no
            // `beforeSendTransaction` — that is the React Native SDK, which
            // the portfolio standard was written from. A transaction is just
            // an event with a transaction type, and `SentryClient` runs
            // `beforeSend` for every event that is not user feedback, so this
            // sees transactions too.
            options.beforeSend = { event in
                Self.stripInstallIdentifiers(from: event)
            }
        }

        // Set before anything can be sent, so the SDK never fills in an
        // installation ID of its own.
        SentrySDK.setUser(User(userId: Self.anonymousUserID))

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        SentrySDK.configureScope { scope in
            scope.setTag(value: "\(version) (\(build))", key: "app_version")
        }

        #if DEBUG
        print("[Sentry] Initialized for TrimrPix iOS v\(version)")
        #endif
    }

    // MARK: - Anonymous telemetry (#90)

    /// The one user every install shares. Setting it stops sentry-cocoa
    /// substituting a random per-installation ID.
    private static let anonymousUserID = "anonymous"

    /// Whether this build came from TestFlight rather than the App Store.
    ///
    /// TestFlight builds are signed with a sandbox receipt. Without this they
    /// report as `production`, so our own test runs are indistinguishable from
    /// real users' crashes in Sentry (#91).
    private static var isTestFlightBuild: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    /// Remove the per-installation identifiers sentry-cocoa adds on its own.
    ///
    /// `contexts.app.device_app_hash` is a hash of the vendor identifier and
    /// `contexts.device.id` is a per-install ID; both are stable for the life
    /// of the install, which is what makes them personal data. The user is
    /// pinned to the shared `anonymous` value here as well as at start, so a
    /// stray `setUser` elsewhere cannot reintroduce one.
    ///
    /// The Sentry organisation also scrubs these server-side, which covers
    /// crashes this code cannot reach. This is the half that keeps them from
    /// leaving the device at all.
    private static func stripInstallIdentifiers<T: Event>(from event: T) -> T {
        if var context = event.context {
            context["app"]?.removeValue(forKey: "device_app_hash")
            context["device"]?.removeValue(forKey: "device_unique_identifier")
            context["device"]?.removeValue(forKey: "id")
            event.context = context
        }

        // The bundle path in every frame and debug image carries a container
        // UUID that iOS reassigns on each install and update, so it is a
        // per-install ID hiding inside something that looks like a file path.
        for exception in event.exceptions ?? [] {
            for frame in exception.stacktrace?.frames ?? [] {
                frame.package = DiagnosticsRedaction.redactContainerPaths(frame.package)
            }
        }
        for thread in event.threads ?? [] {
            for frame in thread.stacktrace?.frames ?? [] {
                frame.package = DiagnosticsRedaction.redactContainerPaths(frame.package)
            }
        }
        for image in event.debugMeta ?? [] {
            image.codeFile = DiagnosticsRedaction.redactContainerPaths(image.codeFile)
        }

        if event.user == nil {
            event.user = User(userId: anonymousUserID)
        } else if event.user?.userId != anonymousUserID {
            event.user?.userId = anonymousUserID
        }
        event.user?.email = nil
        event.user?.username = nil
        event.user?.ipAddress = nil

        return event
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
