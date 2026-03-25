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
        guard let dsn = Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String,
              !dsn.isEmpty else {
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
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
