/*
 * BusinessBridgeSetup.kt — Business iOS bridge registration.
 *
 * The iOS host application calls configureBusinessBridge() at startup to supply
 * concrete implementations of the auth and network protocols.  Kotlin business code
 * then uses authDelegate() and networkDelegate() to access host capabilities without
 * owning auth sessions or network configuration.
 *
 * Call order in App.init() / application(_:didFinishLaunchingWithOptions:):
 *   BusinessBridgeSetupKt.configureBusinessBridge(
 *       authDelegate: AppAuthDelegate(),
 *       networkDelegate: AppNetworkDelegate()
 *   )
 *
 * NOTE: K/N cinterop appends "Protocol" to ObjC @protocol names.
 *   ObjC: @protocol KMPAuthDelegate    →  Kotlin: KMPAuthDelegateProtocol
 *   ObjC: @protocol KMPNetworkDelegate →  Kotlin: KMPNetworkDelegateProtocol
 */
@file:OptIn(kotlinx.cinterop.ExperimentalForeignApi::class)

package com.example.kmp.business

import businessBridge.KMPAuthDelegateProtocol
import businessBridge.KMPNetworkDelegateProtocol

internal var _authDelegate: KMPAuthDelegateProtocol? = null
internal var _networkDelegate: KMPNetworkDelegateProtocol? = null

/**
 * Register the host app's auth and network delegates.
 * Both protocols are surfaced in businessKit's umbrella header, making their
 * types visible to Swift code that does `import businessKit`.
 */
fun configureBusinessBridge(
    authDelegate: KMPAuthDelegateProtocol,
    networkDelegate: KMPNetworkDelegateProtocol,
) {
    _authDelegate = authDelegate
    _networkDelegate = networkDelegate
}
