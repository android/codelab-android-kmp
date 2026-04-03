/*
 * ProfileLoader.kt — iOS 专用，演示完整的 Swift ↔ Kotlin ↔ ObjC 异步回调链路。
 *
 * 调用链：
 *   1. Swift 调用 ProfileLoader().loadProfile(onComplete:)   [Swift → Kotlin]
 *   2. Kotlin 调用 _authDelegate.currentUserId()             [Kotlin → ObjC 桥]
 *   3. Kotlin 调用 _authDelegate.authToken()                 [Kotlin → ObjC 桥]
 *   4. Kotlin 调用 _networkDelegate.reachability()           [Kotlin → ObjC 桥]
 *   5. Kotlin 调用 _networkDelegate.requestURL(completion:)  [Kotlin → ObjC 桥，异步]
 *   6. ObjC AppNetworkDelegate 在后台线程调用 completion      [ObjC → Kotlin 回调]
 *   7. Kotlin 构建 ProfileResult，调用 onComplete            [Kotlin → Swift 回调]
 *   8. Swift 切回主线程，更新 UI                              [Swift]
 */
@file:OptIn(kotlinx.cinterop.ExperimentalForeignApi::class)

package com.example.kmp.business

class ProfileLoader {

    /**
     * 执行完整的 ObjC 桥调用链，并通过 [onComplete] 回调将结果返回给 Swift。
     *
     * 注意：[onComplete] 可能在后台线程被调用（由 ObjC completion block 触发），
     * Swift 侧需自行 dispatch 到主线程再更新 UI。
     */
    fun loadProfile(onComplete: (ProfileResult) -> Unit) {

        // ── 步骤 2 & 3：调用 ObjC auth 桥 ────────────────────────────────────
        val userId = currentUserId()
        val authenticated = isAuthenticated()
        val token = authToken()

        if (!authenticated || userId == null || token == null) {
            onComplete(
                ProfileResult(
                    success = false,
                    userId = userId ?: "(none)",
                    token = token ?: "",
                    networkStatus = "",
                    httpStatus = 0,
                    responseBody = "",
                    errorMessage = "Not authenticated",
                )
            )
            return
        }

        // ── 步骤 4：调用 ObjC network 桥（同步，获取网络状态）─────────────────
        val reachability = networkStatus()

        // ── 步骤 5：调用 ObjC network 桥（异步 HTTP 请求）────────────────────
        val delegate = _networkDelegate
        if (delegate == null) {
            onComplete(
                ProfileResult(
                    success = false,
                    userId = userId,
                    token = token,
                    networkStatus = reachability,
                    httpStatus = 0,
                    responseBody = "",
                    errorMessage = "Network bridge not configured",
                )
            )
            return
        }

        delegate.requestURL(
            url = "https://api.example.com/users/$userId",
            method = "GET",
            body = null,
        ) { responseBody, statusCode, errorMessage ->
            // ── 步骤 6：ObjC completion block 回调到 Kotlin（可能在后台线程）──
            if (errorMessage != null) {
                onComplete(
                    ProfileResult(
                        success = false,
                        userId = userId,
                        token = token,
                        networkStatus = reachability,
                        httpStatus = statusCode.toInt(),
                        responseBody = "",
                        errorMessage = errorMessage,
                    )
                )
            } else {
                // ── 步骤 7：构建结果，回调给 Swift ───────────────────────────
                onComplete(
                    ProfileResult(
                        success = true,
                        userId = userId,
                        token = token,
                        networkStatus = reachability,
                        httpStatus = statusCode.toInt(),
                        responseBody = responseBody ?: "(empty)",
                    )
                )
            }
        }
    }
}
