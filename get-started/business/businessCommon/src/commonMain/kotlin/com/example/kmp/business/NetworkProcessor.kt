package com.example.kmp.business

import com.example.kmp.foundation.NetworkState
import com.example.kmp.foundation.RequestPayload
import com.example.kmp.foundation.ResponseResult
import com.example.kmp.foundation.errorGetMessage
import com.example.kmp.foundation.errorGetRetryable
import com.example.kmp.foundation.loadingGetProgress
import com.example.kmp.foundation.requestGetEndpoint
import com.example.kmp.foundation.createResponse
import com.example.kmp.foundation.responseGetBody
import com.example.kmp.foundation.responseGetCode
import com.example.kmp.foundation.responseGetSource
import com.example.kmp.foundation.successGetData

class NetworkProcessor {

    fun executeRequest(request: RequestPayload): ResponseResult =
        createResponse(200, "OK from ${requestGetEndpoint(request)}", source = request)

    // All test methods take Any — this is the real KMT-2364 scenario:
    // objects created by foundationKit, passed as Any, checked/cast in businessKit

    // Sealed class when-matching via Any (internal cast).
    // KMT-2364: use foundation accessor functions for field reads so RAUW redirects
    // them to foundationKit — avoids GEP-at-wrong-offset crash from direct property access.
    fun describeStateAny(obj: Any): String {
        val state = obj as NetworkState
        return when (state) {
            is NetworkState.Loading -> "loading(${loadingGetProgress(state)})"
            is NetworkState.Success -> "success(code=${responseGetCode(successGetData(state))})"
            is NetworkState.Error -> "error(${errorGetMessage(state)}, retry=${errorGetRetryable(state)})"
        }
    }

    // Collection filtering via Any list
    fun countSuccessInList(items: List<Any>): Int =
        items.count { it is NetworkState.Success }

    // Type identity checks
    fun isRequest(obj: Any): Boolean = obj is RequestPayload
    fun isResponse(obj: Any): Boolean = obj is ResponseResult
    fun isNetworkState(obj: Any): Boolean = obj is NetworkState
    fun isLoadingState(obj: Any): Boolean = obj is NetworkState.Loading
    fun isSuccessState(obj: Any): Boolean = obj is NetworkState.Success
    fun isErrorState(obj: Any): Boolean = obj is NetworkState.Error

    // Round-trip: Any → as RequestPayload → execute → ResponseResult
    fun processAnyRequest(obj: Any): ResponseResult {
        val req = obj as RequestPayload
        return executeRequest(req)
    }

    // Verify cross-framework reference survives: cast response.source back.
    // KMT-2364: use responseGetSource/requestGetEndpoint so reads go through
    // RAUW'd external declarations resolved from foundationKit.
    fun getSourceEndpoint(obj: Any): String {
        val resp = obj as ResponseResult
        val src = responseGetSource(resp) ?: return "null"
        return requestGetEndpoint(src)
    }
}
