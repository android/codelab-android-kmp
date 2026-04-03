/*
 * Copyright 2024 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import com.diffplug.gradle.spotless.SpotlessExtension
import com.diffplug.gradle.spotless.SpotlessPlugin

plugins {
    alias(libs.plugins.androidApplication) apply false
    alias(libs.plugins.kotlinAndroid) apply false
    alias(libs.plugins.kotlinCompose) apply false
    alias(libs.plugins.spotless) apply false
    alias(libs.plugins.kotlinMultiplatform) apply false
    alias(libs.plugins.androidKotlinMultiplatformLibrary) apply false
    alias(libs.plugins.androidLint) apply false
}

// ─── KMP → iOS 本地二进制仓库发布（聚合任务）────────────────────────────────
// 一键将 foundation + business 的 XCFramework 和桥接头文件发布到 kmp-local-repo/，
// iOS 工程随后执行 pod install 即可消费最新产物，无需接触 KMP 源码。
//
// 用法：
//   ./gradlew publishKMPIOSDebug    # 发布 debug 产物
//   ./gradlew publishKMPIOSRelease  # 发布 release 产物

tasks.register("publishKMPIOSDebug") {
    description = "Publish all KMP iOS debug XCFrameworks to kmp-local-repo/"
    group = "kotlin multiplatform"
    dependsOn(
        ":foundation:KMPFoundation:publishIOSDebug",
        ":business:KMPBusiness:publishIOSDebug",
    )
    doLast {
        println("✅ All KMP iOS debug artifacts published to kmp-local-repo/")
        println("   Next: cd ../iosApp && pod install")
    }
}

tasks.register("publishKMPIOSRelease") {
    description = "Publish all KMP iOS release XCFrameworks to kmp-local-repo/"
    group = "kotlin multiplatform"
    dependsOn(
        ":foundation:KMPFoundation:publishIOSRelease",
        ":business:KMPBusiness:publishIOSRelease",
    )
    doLast {
        println("✅ All KMP iOS release artifacts published to kmp-local-repo/")
        println("   Next: cd ../iosApp && pod install")
    }
}

subprojects {
    // TODO migrate to init-script
    apply<SpotlessPlugin>()
    configure<SpotlessExtension> {
        kotlin {
            target("**/*.kt")
            targetExclude("${layout.buildDirectory}/**/*.kt")
            ktlint(libs.versions.ktlint.get())
            licenseHeaderFile(rootProject.file("spotless/copyright.kt"))
        }

        kotlinGradle {
            target("*.gradle.kts")
            ktlint(libs.versions.ktlint.get())
            licenseHeaderFile(rootProject.file("spotless/copyright.kt"), "(^(?![\\/ ]\\*).*$)")
        }

        format("xml") {
            target("**/*.xml")
            targetExclude("**/build/**/*.xml")
            // Look for the first XML tag that isn't a comment (<!--) or the xml declaration (<?xml)
            licenseHeaderFile(rootProject.file("spotless/copyright.xml"), "(<[^!?])")
        }
    }
}