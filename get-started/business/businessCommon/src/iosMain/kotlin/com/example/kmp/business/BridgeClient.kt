/*
 * BridgeClient.kt — Kotlin API that wraps the iOS bridge delegates.
 *
 * Business Kotlin code calls these functions instead of touching the delegates
 * directly, keeping the bridge coupling contained in one place.
 *
 * NOTE: K/N cinterop converts NS_ENUM to a Long typealias; each enum member
 *   becomes a top-level Long val (NOT an enum class entry).
 *   e.g. KMPNetworkReachability = typealias Long
 *        KMPNetworkReachabilityWiFi: Long = 1L
 */
@file:OptIn(kotlinx.cinterop.ExperimentalForeignApi::class)

package com.example.kmp.business

import businessBridge.KMPNetworkReachabilityCellular
import businessBridge.KMPNetworkReachabilityNotReachable
import businessBridge.KMPNetworkReachabilityWiFi

// ─── Auth ─────────────────────────────────────────────────────────────────────

/** Returns the logged-in user's stable ID, or null if unauthenticated. */
fun currentUserId(): String? = _authDelegate?.currentUserId()

/** True when a user session is active. */
fun isAuthenticated(): Boolean = _authDelegate?.isAuthenticated() == true

/** Short-lived bearer token, or null if unauthenticated. */
fun authToken(): String? = _authDelegate?.authToken()

// ─── Network ──────────────────────────────────────────────────────────────────

/** Human-readable current network reachability: "WiFi", "Cellular", or "None". */
fun networkStatus(): String = when (_networkDelegate?.reachability()) {
    KMPNetworkReachabilityWiFi         -> "WiFi"
    KMPNetworkReachabilityCellular     -> "Cellular"
    KMPNetworkReachabilityNotReachable -> "None"
    null                               -> "bridge not configured"
    else                               -> "unknown"
}
