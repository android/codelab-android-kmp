/*
 * KMT-2364: Cross-framework GC test helpers.
 *
 * businessKit holds foundationKit objects through a GC cycle, verifying that
 * embedRuntime=false means both frameworks share a single K/N GC instance.
 * If there were two separate runtimes, objects created by foundationKit could
 * be collected by foundationKit's GC while businessKit still holds a reference,
 * leading to dangling pointers, crashes, or silent type-identity failures.
 */
package com.example.kmp.business

import com.example.kmp.foundation.RequestPayload
import com.example.kmp.foundation.gcCollect
import com.example.kmp.foundation.requestGetEndpoint

class GCCrossFrameworkProcessor {

    /**
     * T10 — Cross-framework object survives GC.
     * businessKit holds a reference to a foundationKit-created RequestPayload,
     * triggers GC (via foundationKit's gcCollect — the shared runtime's GC),
     * then verifies the object is still reachable via a Kotlin is-check.
     */
    fun holdThroughGC(obj: Any): Boolean {
        gcCollect()
        return obj is RequestPayload
    }

    /**
     * T11 — Field readable after cross-framework GC.
     * Same as T10 but also reads a field value through the RAUW'd accessor,
     * confirming the object's data is intact after GC.
     */
    fun readEndpointAfterGC(obj: Any): String {
        gcCollect()
        val req = obj as? RequestPayload ?: return "CAST_FAILED"
        return requestGetEndpoint(req)
    }
}
