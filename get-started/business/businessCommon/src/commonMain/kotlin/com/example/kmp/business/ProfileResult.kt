package com.example.kmp.business

/**
 * Result of a bridge round-trip fetch.
 * Produced by ProfileLoader (iOS) after the full call chain:
 *   Swift → Kotlin → ObjC auth/network bridge → Kotlin callback → Swift
 */
data class ProfileResult(
    val success: Boolean,
    val userId: String,
    val token: String,
    val networkStatus: String,
    val httpStatus: Int,
    val responseBody: String,
    val errorMessage: String? = null,
) {
    /** One-line summary shown in the UI. */
    fun summary(): String = if (success) {
        buildString {
            appendLine("userId      : $userId")
            appendLine("token       : ${token.take(20)}...")
            appendLine("network     : $networkStatus")
            appendLine("httpStatus  : $httpStatus")
            append("responseBody: $responseBody")
        }
    } else {
        "error: $errorMessage"
    }
}
