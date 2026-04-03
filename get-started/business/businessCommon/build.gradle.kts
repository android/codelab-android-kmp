import org.jetbrains.kotlin.gradle.plugin.mpp.apple.XCFramework
import org.jetbrains.kotlin.gradle.plugin.mpp.NativeBuildType

plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.androidKotlinMultiplatformLibrary)
}

// ─── businessCommon ───────────────────────────────────────────────────────────
//
// Central module for all Business Kotlin code, cinterop bridge declarations,
// and dependency management.
//
// • Android artifact    — available for Android consumers
// • iOS klibsand framework — compiled here; delivered via :business:KMPBusiness

kotlin {

    androidLibrary {
        namespace = "com.example.kmp.business"
        compileSdk = 36
        minSdk = 24
    }

    val xcfName = "businessKit"
    val xcf = XCFramework(xcfName)

    iosArm64 {
        compilations["main"].cinterops.create("businessBridge") {
            defFile(project.file("../business-bridge/businessBridge.def"))
            includeDirs(project.file("../business-bridge/headers"))
        }
        binaries.framework {
            baseName = xcfName
            xcf.add(this)
            // KMT-2364: Do NOT re-export Foundation types — their ObjC bridge lives in
            // foundationKit.framework only. Re-exporting causes duplicate ObjC class
            // registration, corrupting the BackRef→ObjHeader* mapping.
            binaryOption("embedRuntime", "false")
            binaryOption("externalKlibs", "com.example.kmp.foundation")
            val suffix = if (buildType == NativeBuildType.DEBUG) "debug" else "release"
            linkerOpts(
                "-framework", "foundationKit",
                // foundationKit.framework is produced by foundationCommon (not KMPFoundation).
                "-F", "${projectDir}/../../foundation/foundationCommon/build/bin/iosArm64/${suffix}Framework"
            )
        }
    }

    iosSimulatorArm64 {
        compilations["main"].cinterops.create("businessBridge") {
            defFile(project.file("../business-bridge/businessBridge.def"))
            includeDirs(project.file("../business-bridge/headers"))
        }
        binaries.framework {
            baseName = xcfName
            xcf.add(this)
            binaryOption("embedRuntime", "false")
            binaryOption("externalKlibs", "com.example.kmp.foundation")
            val suffix = if (buildType == NativeBuildType.DEBUG) "debug" else "release"
            linkerOpts(
                "-framework", "foundationKit",
                "-F", "${projectDir}/../../foundation/foundationCommon/build/bin/iosSimulatorArm64/${suffix}Framework"
            )
        }
    }

    sourceSets {
        commonMain {
            dependencies {
                api(project(":foundation:foundationCommon"))
                implementation(libs.kotlin.stdlib)
            }
        }

        iosMain {
            dependencies {
            }
        }
    }
}
