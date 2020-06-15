import org.jetbrains.kotlin.gradle.plugin.mpp.KotlinNativeTarget

plugins {
    kotlin("multiplatform")
    id("co.touchlab.native.cocoapods")
}

version = "0.0.1"

kotlin {
    val onPhone = System.getenv("SDK_NAME")?.startsWith("iphoneos") ?: false
    val ios: (String, KotlinNativeTarget.() -> Unit) -> KotlinNativeTarget = if (onPhone) ::iosArm64 else ::iosX64
    ios("ios") {
        compilations["main"].kotlinOptions.freeCompilerArgs += "-Xobjc-generics"
    }

    sourceSets {
        all {
            languageSettings.apply {
                useExperimentalAnnotation("kotlinx.coroutines.ExperimentalCoroutinesApi")
            }
        }

        commonMain {
            dependencies {
                implementation(kotlin("stdlib-common"))
                implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core-native:1.3.5-native-mt")
            }
        }
    }
    cocoapodsext {
        summary = "Swift Coroutine interop tests"
        homepage = "https://touchlab.co"
        framework {
            isStatic = false
        }
    }
}