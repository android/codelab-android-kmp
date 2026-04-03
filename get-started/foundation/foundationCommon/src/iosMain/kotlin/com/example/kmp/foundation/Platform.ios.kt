@file:OptIn(kotlinx.cinterop.ExperimentalForeignApi::class)

package com.example.kmp.foundation

actual fun platform(): String {
    val provider = _platformProvider
    return if (provider != null) {
        "iOS ${provider.osVersion()} / ${provider.deviceModel()} (app ${provider.appVersion()})"
    } else {
        "iOS"
    }
}
