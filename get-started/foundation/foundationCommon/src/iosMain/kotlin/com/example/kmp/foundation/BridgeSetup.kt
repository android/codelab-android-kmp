/*
 * BridgeSetup.kt — Foundation iOS bridge registration.
 *
 * The iOS host application calls these functions at startup to register
 * concrete implementations of the bridge protocols.  Kotlin foundation code
 * then calls the registered providers wherever it needs host-app capabilities.
 *
 * Call order in App.init() / application(_:didFinishLaunchingWithOptions:):
 *   BridgeSetupKt.configureFoundationBridge(provider: AppPlatformProvider())
 *   BridgeSetupKt.configureFoundationLogger(delegate: AppLoggerDelegate())
 *
 * STORAGE: Provider/delegate references are kept in ObjC-level C functions
 * (KMPGetPlatformProvider / KMPSetPlatformProvider etc.) declared in the bridge
 * headers.  This avoids arm64_adrp_lo12 fixup errors that arise when Kotlin
 * `internal var` is referenced across XCFramework dylib boundaries (K/N
 * externalKlibs generates PC-relative — same-dylib-only — relocations for
 * module initializers, which fail when businessKit links against foundationKit).
 *
 * NOTE: K/N cinterop appends "Protocol" to ObjC @protocol names.
 *   ObjC: @protocol KMPPlatformInfoProvider  →  Kotlin: KMPPlatformInfoProviderProtocol
 *   ObjC: @protocol KMPLoggerDelegate        →  Kotlin: KMPLoggerDelegateProtocol
 */
@file:OptIn(kotlinx.cinterop.ExperimentalForeignApi::class)

package com.example.kmp.foundation

import foundationBridge.KMPGetLoggerDelegate
import foundationBridge.KMPGetPlatformProvider
import foundationBridge.KMPLoggerDelegateProtocol
import foundationBridge.KMPPlatformInfoProviderProtocol
import foundationBridge.KMPSetLoggerDelegate
import foundationBridge.KMPSetPlatformProvider

// ─── Internal Kotlin-side accessors (read from ObjC storage) ─────────────────

internal val _platformProvider: KMPPlatformInfoProviderProtocol?
    get() = KMPGetPlatformProvider()

internal val _loggerDelegate: KMPLoggerDelegateProtocol?
    get() = KMPGetLoggerDelegate()

// ─── Public registration functions (called by the iOS host app) ───────────────

/**
 * Register the host app's platform info provider.
 * This function is exported to ObjC/Swift in foundationKit's umbrella header.
 */
fun configureFoundationBridge(provider: KMPPlatformInfoProviderProtocol) {
    KMPSetPlatformProvider(provider)
}

/**
 * Register the host app's log sink.
 * After registration, all KMPLogger calls are forwarded to this delegate.
 */
fun configureFoundationLogger(delegate: KMPLoggerDelegateProtocol) {
    KMPSetLoggerDelegate(delegate)
}
