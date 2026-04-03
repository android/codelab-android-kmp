/*
 * KMT-2364: GC / memory management test helpers.
 *
 * Verifies that embedRuntime=false results in a single shared GC instance
 * between foundationKit and businessKit. Tests that objects created by
 * foundationKit are tracked by the same GC that businessKit uses.
 */
package com.example.kmp.foundation

import kotlin.experimental.ExperimentalNativeApi
import kotlin.native.runtime.GC
import kotlin.native.runtime.NativeRuntimeApi
import kotlin.native.ref.WeakReference

/** Trigger a synchronous GC collection. Called from both Swift and businessKit. */
@OptIn(NativeRuntimeApi::class)
fun gcCollect() = GC.collect()

/**
 * T8 — Strong reference survives GC.
 * Creates a RequestPayload, triggers GC, and verifies the object is still alive and readable.
 * With a correctly shared runtime, GC only collects unreachable objects; a live strongly-held
 * reference must survive. A duplicated or mis-configured runtime could corrupt live objects.
 */
@OptIn(NativeRuntimeApi::class)
fun testStrongRefSurvivesGC(): Boolean {
    val obj = RequestPayload("/gc-strong-test")
    GC.collect()
    return obj.endpoint == "/gc-strong-test"
}

/**
 * T9 — Weak reference cleared after strong ref released and GC runs.
 * WeakReference.get() returns null after the only strong reference goes out of scope
 * and GC runs.
 *
 * Object creation is isolated in a separate function so that the RequestPayload is
 * truly off all stack frames (and therefore off GC roots) when GC.collect() is called.
 * If both inline in one function, the LLVM backend may retain the old pointer in a
 * register between `strong = null` and `GC.collect()`, keeping the object alive.
 *
 * With two independent runtimes, foundationKit's WeakReference would be tracked by a
 * different GC than the one that might collect the object — this test would then fail
 * (get() would remain non-null even after GC, or the runtime would crash).
 */
@OptIn(ExperimentalNativeApi::class)
private fun makeWeakRef(): WeakReference<RequestPayload> {
    // RequestPayload is a local var here; it goes off the stack when this function returns.
    val obj = RequestPayload("/gc-weak-test")
    return WeakReference(obj)
}

@OptIn(NativeRuntimeApi::class, ExperimentalNativeApi::class)
fun testWeakRefClearedAfterGC(): Boolean {
    val weak = makeWeakRef()      // obj is now off all stack frames
    GC.collect()                  // should collect the now-unreachable RequestPayload
    return weak.get() == null     // WeakReference must be nulled after collection
}

/** Creates an object for the cross-framework GC survival test (T10/T11 in businessKit). */
fun createGCTestPayload(): RequestPayload = RequestPayload("/cross-fw-gc")
