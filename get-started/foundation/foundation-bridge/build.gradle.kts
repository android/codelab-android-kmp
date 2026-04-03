/*
 * foundation-ios-bridge
 *
 * This module is a pure header/definition provider — it contains no Kotlin sources
 * and declares no compilation targets.  Its only artifacts are:
 *
 *   foundationBridge.def   — cinterop definition consumed by :foundation
 *   headers/               — ObjC protocol declarations consumed by the cinterop
 *
 * The actual cinterop compilation is configured in :foundation's build.gradle.kts,
 * which references this module's def file and headers by relative path.  This mirrors
 * the TikTok iOSCommonBridge pattern where the bridge module is a shared header store.
 */

// No plugins — nothing to compile here.
