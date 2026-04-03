// ─── KMPBusiness — XCFramework 交付 & 本地仓库发布模块 ───────────────────────
//
// 该模块不含任何 Kotlin 源文件，不参与 K/N 编译。
// 所有 Business Kotlin 代码、cinterop 桥接、iOS 框架配置均在 :business:businessCommon 中。
//
// 职责（双阶段）：
//   1. buildIOS*    — 触发 businessCommon 的 assemble*XCFramework 任务（本地联调用）
//   2. publishIOS*  — 将 XCFramework + podspec 发布到本地二进制仓库
//
// 本地仓库位置：<root>/../kmp-local-repo/   (即 get-started/ 的兄弟目录)
//
// 注意：businessBridge pod（header-only）归 iOS 工程所有，KMP 仅发布 XCFramework。
//
// iOS 工程 Podfile：
//   pod 'businessBridge', :path => './businessBridge'               # iOS 工程本地
//   pod 'businessKit',    :path => '../kmp-local-repo/businessKit'  # 二进制仓库

// ─── 工具函数 ─────────────────────────────────────────────────────────────────

/** businessCommon 的 XCFramework 输出目录 */
fun businessCommonXCFrameworkDir(variant: String): File =
    file("../businessCommon/build/XCFrameworks/$variant")

/** 本地二进制仓库根目录（get-started/ 的兄弟目录） */
val localRepoRoot: File
    get() = rootProject.projectDir.resolve("../kmp-local-repo")

// ─── 本地联调任务（buildIOSDebug / buildIOSRelease）────────────────────────────

tasks.register("buildIOSDebug") {
    description = "Build iOS debug XCFramework via businessCommon (no publish)"
    group = "kotlin multiplatform"
    dependsOn(":business:businessCommon:assembleBusinessKitDebugXCFramework")
    notCompatibleWithConfigurationCache("accesses file system at execution time")
    doLast {
        println("✅ businessKit debug built at: ${businessCommonXCFrameworkDir("debug")}")
        println("   Run publishIOSDebug to push to kmp-local-repo/")
    }
}

tasks.register("buildIOSRelease") {
    description = "Build iOS release XCFramework via businessCommon (no publish)"
    group = "kotlin multiplatform"
    dependsOn(":business:businessCommon:assembleBusinessKitReleaseXCFramework")
    notCompatibleWithConfigurationCache("accesses file system at execution time")
    doLast {
        println("✅ businessKit release built at: ${businessCommonXCFrameworkDir("release")}")
        println("   Run publishIOSRelease to push to kmp-local-repo/")
    }
}

// ─── 发布到本地二进制仓库（publishIOSDebug / publishIOSRelease）────────────────
//
// 发布内容（仅 XCFramework 二进制，不含 businessBridge pod）：
//   kmp-local-repo/
//     businessKit/
//       businessKit.podspec    (含 spec.dependency 'businessBridge' + 'foundationKit')
//       businessKit.xcframework/
//
// businessBridge pod（header-only）由 iOS 工程在 iosApp/businessBridge/ 维护，
// KMP 侧的 business-bridge/headers/ 仅供 cinterop 编译使用（内容与 iOS pod 保持一致）。

/** 将 businessKit XCFramework pod 发布到本地仓库 */
fun publishBusinessKitPod(xcfwDir: File) {
    val target = localRepoRoot.resolve("businessKit")
    val xcfwTarget = target.resolve("businessKit.xcframework")

    // 清理旧 XCFramework，避免残留 slice
    xcfwTarget.deleteRecursively()
    xcfwTarget.mkdirs()

    // 复制 XCFramework
    xcfwDir.resolve("businessKit.xcframework")
        .copyRecursively(xcfwTarget, overwrite = true)

    // 复制 podspec（含 spec.dependency 'businessBridge' + 'foundationKit'）
    file("businessKit.podspec")
        .copyTo(target.resolve("businessKit.podspec"), overwrite = true)

    println("   📦 businessKit → ${target}")
}

tasks.register("publishIOSDebug") {
    description = "Build businessKit debug XCFramework and publish to kmp-local-repo/"
    group = "kotlin multiplatform"
    dependsOn(":business:businessCommon:assembleBusinessKitDebugXCFramework")
    notCompatibleWithConfigurationCache("accesses file system at execution time")
    doLast {
        publishBusinessKitPod(businessCommonXCFrameworkDir("debug"))
        println("✅ businessKit debug published to kmp-local-repo/")
    }
}

tasks.register("publishIOSRelease") {
    description = "Build businessKit release XCFramework and publish to kmp-local-repo/"
    group = "kotlin multiplatform"
    dependsOn(":business:businessCommon:assembleBusinessKitReleaseXCFramework")
    notCompatibleWithConfigurationCache("accesses file system at execution time")
    doLast {
        publishBusinessKitPod(businessCommonXCFrameworkDir("release"))
        println("✅ businessKit release published to kmp-local-repo/")
    }
}
