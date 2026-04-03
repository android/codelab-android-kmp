/*
 * KMPLogger.kt — Kotlin logging facade backed by the native log bridge.
 *
 * Kotlin code anywhere in foundationKit calls KMPLogger.info("Tag", "message").
 * The call is forwarded to the KMPLoggerDelegate registered by the iOS host app,
 * which routes it into its native log pipeline (os_log, CocoaLumberjack, etc.).
 *
 * Falls back silently (no-op) when no delegate has been registered, so it is safe
 * to call before configureFoundationLogger() has been invoked.
 *
 * NOTE: K/N cinterop converts NS_ENUM to a Long typealias; each enum member
 *   becomes a top-level Long val (NOT an enum class entry).
 *   e.g. KMPLogLevel = typealias Long; KMPLogLevelVerbose: Long = 0L
 */
@file:OptIn(kotlinx.cinterop.ExperimentalForeignApi::class)

package com.example.kmp.foundation

import foundationBridge.KMPLogLevelDebug
import foundationBridge.KMPLogLevelError
import foundationBridge.KMPLogLevelInfo
import foundationBridge.KMPLogLevelVerbose
import foundationBridge.KMPLogLevelWarning

object KMPLogger {

    fun verbose(tag: String, message: String) = emit(message, KMPLogLevelVerbose, tag)
    fun debug(tag: String, message: String)   = emit(message, KMPLogLevelDebug,   tag)
    fun info(tag: String, message: String)    = emit(message, KMPLogLevelInfo,    tag)
    fun warn(tag: String, message: String)    = emit(message, KMPLogLevelWarning,  tag)
    fun error(tag: String, message: String)   = emit(message, KMPLogLevelError,   tag)

    private fun emit(message: String, level: Long, tag: String) {
        _loggerDelegate?.logMessage(message, level = level, tag = tag)
    }
}
