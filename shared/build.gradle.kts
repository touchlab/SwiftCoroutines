import org.jetbrains.kotlin.gradle.plugin.mpp.KotlinNativeTarget

plugins {
    kotlin("multiplatform")
    kotlin("native.cocoapods")
}

version = "0.0.1"

kotlin {
    val onPhone = System.getenv("SDK_NAME")?.startsWith("iphoneos") ?: false
    val ios: (String, KotlinNativeTarget.() -> Unit) -> KotlinNativeTarget = if (onPhone) ::iosArm64 else ::iosX64
    ios("ios")

    sourceSets {
        all {
            languageSettings.apply {
                useExperimentalAnnotation("kotlinx.coroutines.ExperimentalCoroutinesApi")
            }
        }

        commonMain {
            dependencies {
                implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.5.2-native-mt")
            }
        }
    }
    cocoapods {
        summary = "Swift Coroutine interop tests"
        homepage = "https://touchlab.co"
        framework {
            isStatic = false
        }
    }
}
