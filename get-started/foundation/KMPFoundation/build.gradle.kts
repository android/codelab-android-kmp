// ─── KMPFoundation — XCFramework 交付 & 本地仓库发布模块 ─────────────────────
//
// 该模块不含任何 Kotlin 源文件，不参与 K/N 编译。
// 所有 Foundation Kotlin 代码、cinterop 桥接、iOS 框架配置均在 :foundation:foundationCommon 中。
//
// 职责（双阶段）：
//   1. buildIOS*    — 触发 foundationCommon 的 assemble*XCFramework 任务（本地联调用）
//   2. publishIOS*  — 将 XCFramework + podspec 发布到本地二进制仓库
//
// 本地仓库位置：<root>/../kmp-local-repo/   (即 get-started/ 的兄弟目录)
//
// 注意：foundationBridge pod（header-only）归 iOS 工程所有，KMP 仅发布 XCFramework。
//
// iOS 工程 Podfile：
//   pod 'foundationBridge', :path => './foundationBridge'             # iOS 工程本地
//   pod 'foundationKit',    :path => '../kmp-local-repo/foundationKit' # 二进制仓库

// ─── 工具函数 ─────────────────────────────────────────────────────────────────

/** foundationCommon 的 XCFramework 输出目录 */
fun foundationCommonXCFrameworkDir(variant: String): File =
    file("../foundationCommon/build/XCFrameworks/$variant")

/** 本地二进制仓库根目录（get-started/ 的兄弟目录） */
val localRepoRoot: File
    get() = rootProject.projectDir.resolve("../kmp-local-repo")

// ─── 本地联调任务（buildIOSDebug / buildIOSRelease）────────────────────────────

tasks.register("buildIOSDebug") {
    description = "Build iOS debug XCFramework via foundationCommon (no publish)"
    group = "kotlin multiplatform"
    dependsOn(":foundation:foundationCommon:assembleFoundationKitDebugXCFramework")
    notCompatibleWithConfigurationCache("accesses file system at execution time")
    doLast {
        println("✅ foundationKit debug built at: ${foundationCommonXCFrameworkDir("debug")}")
        println("   Run publishIOSDebug to push to kmp-local-repo/")
    }
}

tasks.register("buildIOSRelease") {
    description = "Build iOS release XCFramework via foundationCommon (no publish)"
    group = "kotlin multiplatform"
    dependsOn(":foundation:foundationCommon:assembleFoundationKitReleaseXCFramework")
    notCompatibleWithConfigurationCache("accesses file system at execution time")
    doLast {
        println("✅ foundationKit release built at: ${foundationCommonXCFrameworkDir("release")}")
        println("   Run publishIOSRelease to push to kmp-local-repo/")
    }
}

// ─── 发布到本地二进制仓库（publishIOSDebug / publishIOSRelease）────────────────
//
// 发布内容（仅 XCFramework 二进制，不含 foundationBridge pod）：
//   kmp-local-repo/
//     foundationKit/
//       foundationKit.podspec    (含 spec.dependency 'foundationBridge')
//       foundationKit.xcframework/
//
// foundationBridge pod（header-only）由 iOS 工程在 iosApp/foundationBridge/ 维护，
// KMP 侧的 foundation-bridge/headers/ 仅供 cinterop 编译使用（内容与 iOS pod 保持一致）。

/** 将 foundationKit XCFramework pod 发布到本地仓库 */
fun publishFoundationKitPod(xcfwDir: File) {
    val target = localRepoRoot.resolve("foundationKit")
    val xcfwTarget = target.resolve("foundationKit.xcframework")

    // 清理旧 XCFramework，避免残留 slice
    xcfwTarget.deleteRecursively()
    xcfwTarget.mkdirs()

    // 复制 XCFramework
    xcfwDir.resolve("foundationKit.xcframework")
        .copyRecursively(xcfwTarget, overwrite = true)

    // 复制 podspec（含 spec.dependency 'foundationBridge'）
    file("foundationKit.podspec")
        .copyTo(target.resolve("foundationKit.podspec"), overwrite = true)

    println("   📦 foundationKit → ${target}")
}

tasks.register("publishIOSDebug") {
    description = "Build foundationKit debug XCFramework and publish to kmp-local-repo/"
    group = "kotlin multiplatform"
    dependsOn(":foundation:foundationCommon:assembleFoundationKitDebugXCFramework")
    notCompatibleWithConfigurationCache("accesses file system at execution time")
    doLast {
        publishFoundationKitPod(foundationCommonXCFrameworkDir("debug"))
        println("✅ foundationKit debug published to kmp-local-repo/")
    }
}

tasks.register("publishIOSRelease") {
    description = "Build foundationKit release XCFramework and publish to kmp-local-repo/"
    group = "kotlin multiplatform"
    dependsOn(":foundation:foundationCommon:assembleFoundationKitReleaseXCFramework")
    notCompatibleWithConfigurationCache("accesses file system at execution time")
    doLast {
        publishFoundationKitPod(foundationCommonXCFrameworkDir("release"))
        println("✅ foundationKit release published to kmp-local-repo/")
    }
}
