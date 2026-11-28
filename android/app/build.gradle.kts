
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("app/key.properties")

if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use {
        keystoreProperties.load(it)
    }
}

val releaseSigningKeys = listOf("keyAlias", "keyPassword", "storePassword")
val releaseStoreFile = keystoreProperties.getProperty("storeFile")?.trim().orEmpty()
val releaseSigningConfigured = keystorePropertiesFile.isFile &&
    releaseStoreFile.isNotBlank() &&
    file(releaseStoreFile).isFile &&
    releaseSigningKeys.all { !keystoreProperties.getProperty(it).isNullOrBlank() }

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.evuddy.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = flutter.minSdkVersion
        applicationId = "com.evuddy.app"
         targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(releaseStoreFile)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (releaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

gradle.taskGraph.whenReady { graph ->
    val releasePackagingRequested = graph.allTasks.any { task ->
        task.name.startsWith("assembleRelease") ||
            task.name.startsWith("bundleRelease") ||
            task.name.startsWith("packageRelease")
    }
    if (releasePackagingRequested && !releaseSigningConfigured) {
        throw GradleException(
            "A Play-ready release requires android/app/key.properties and its matching upload keystore. " +
                "Release builds will not fall back to debug signing."
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
