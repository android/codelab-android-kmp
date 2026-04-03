//
//  KMPGetStartedCodelabApp.swift
//  KMPGetStartedCodelab
//

import SwiftUI
import foundationKit          // Kotlin Foundation API + configureFoundationBridge / configureFoundationLogger
import businessKit            // Kotlin Business API + configureBusinessBridge
import foundationBridgeImpl   // AppPlatformProvider, AppLoggerDelegate (ObjC impl classes)
import businessBridgeImpl     // AppAuthDelegate, AppNetworkDelegate (ObjC impl classes)

@main
struct KMPGetStartedCodelabApp: App {

    init() {
        setupBridges()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    // ─── Bridge setup ──────────────────────────────────────────────────────────
    // Register ObjC implementations of the cinterop bridge protocols so that
    // Kotlin code in foundationKit / businessKit can call into iOS capabilities.
    // Must happen before any Kotlin code executes.
    //
    // AppPlatformProvider, AppLoggerDelegate  ->  foundationBridgeImpl pod
    // AppAuthDelegate, AppNetworkDelegate     ->  businessBridgeImpl pod

    private func setupBridges() {
        // Foundation: platform info + logging
        BridgeSetupKt.configureFoundationBridge(provider: AppPlatformProvider())
        BridgeSetupKt.configureFoundationLogger(delegate: AppLoggerDelegate())

        // Business: auth + network
        BusinessBridgeSetupKt.configureBusinessBridge(
            authDelegate: AppAuthDelegate(),
            networkDelegate: AppNetworkDelegate()
        )
    }
}
