package com.example.kmp.foundation

data class RequestPayload(
    val endpoint: String,
    val params: Map<String, String> = emptyMap()
)

data class ResponseResult(
    val code: Int,
    val body: String,
    val source: RequestPayload? = null
)

sealed interface NetworkState {
    data class Loading(val progress: Float) : NetworkState
    data class Success(val data: ResponseResult) : NetworkState
    data class Error(val message: String, val retryable: Boolean) : NetworkState
}

fun createRequest(endpoint: String): RequestPayload =
    RequestPayload(endpoint)

fun createResponse(code: Int, body: String, source: RequestPayload?): ResponseResult =
    ResponseResult(code, body, source)

fun createLoadingState(progress: Float): NetworkState =
    NetworkState.Loading(progress)

fun createSuccessState(result: ResponseResult): NetworkState =
    NetworkState.Success(result)

fun createErrorState(message: String, retryable: Boolean): NetworkState =
    NetworkState.Error(message, retryable)

// KMT-2364: Explicit cross-framework field accessors.
// K/N compiles direct property access (request.endpoint) as GEP in the caller's
// IR — no function call, so RAUW cannot redirect it to foundationKit.
// These top-level functions in the foundation package ARE RAUW'd to external
// declarations in businessKit and resolved from foundationKit at dyld load time,
// ensuring businessKit always reads fields via foundationKit's live code/offsets.
fun requestGetEndpoint(r: RequestPayload): String = r.endpoint
fun requestGetParams(r: RequestPayload): Map<String, String> = r.params
fun responseGetCode(r: ResponseResult): Int = r.code
fun responseGetBody(r: ResponseResult): String = r.body
fun responseGetSource(r: ResponseResult): RequestPayload? = r.source
fun loadingGetProgress(s: NetworkState.Loading): Float = s.progress
fun successGetData(s: NetworkState.Success): ResponseResult = s.data
fun errorGetMessage(s: NetworkState.Error): String = s.message
fun errorGetRetryable(s: NetworkState.Error): Boolean = s.retryable
