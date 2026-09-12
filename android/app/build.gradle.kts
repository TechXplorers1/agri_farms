plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ─── Read release signing credentials from key.properties ─────────────────────
// key.properties is NOT committed to git (it's in .gitignore).
// For local dev: create android/key.properties manually (see README).
// For CI/CD: inject via environment variables or secret manager.
// ──────────────────────────────────────────────────────────────────────────────
import java.util.Properties

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(keyPropertiesFile.inputStream())
}

android {
    namespace = "com.agrifarms.app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // ─── Release Signing Config ───────────────────────────────────────────────
    // Play Store REQUIRES a proper upload key — debug keys are rejected.
    // Generate once with: keytool -genkey -v -keystore key.jks -keyalg RSA
    //   -keysize 2048 -validity 10000 -alias agrifarms-key
    // Then fill in android/key.properties (never commit this file to git!).
    // ─────────────────────────────────────────────────────────────────────────
    signingConfigs {
        create("release") {
            if (keyPropertiesFile.exists()) {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            } else {
                // Fallback to debug for local development when key.properties is absent.
                // WARNING: Release builds uploaded to Play Store MUST have key.properties.
                println("⚠️  WARNING: key.properties not found — using debug keys (not suitable for Play Store)")
            }
        }
    }

    defaultConfig {
        applicationId = "com.agrifarms.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName 
        multiDexEnabled = true
        manifestPlaceholders += mapOf("appAuthRedirectScheme" to "agrifarms")
    }

    buildTypes {
        release {
            // Use release signing config (reads from key.properties)
            signingConfig = if (keyPropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug") // local dev fallback only
            }
            // Enable R8 code shrinking + obfuscation (Play Store best practice)
            // Reduces APK size and makes code harder to reverse-engineer
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-analytics")
}

configurations.all {
    resolutionStrategy {
        force("com.android.tools:desugar_jdk_libs:2.1.4")
    }
}
