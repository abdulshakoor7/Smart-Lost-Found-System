plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // --- ADD THIS LINE (CRITICAL FOR FIREBASE) ---
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.smart_lost_and_found_system_for_campus"
    compileSdk = flutter.compileSdkVersion

    // --- FIX 1: Set specific NDK version ---
    ndkVersion = "27.0.12077973"
    // ---------------------------------------

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.smart_lost_and_found_system_for_campus"

        // --- FIX 2: Set Min SDK to 23 (Required for Firebase) ---
        minSdk = 23
        // --------------------------------------------------------

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            // These must both be false for normal development/debugging
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}