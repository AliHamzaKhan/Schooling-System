plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android plugin; it
    // provides Kotlin support (Built-in Kotlin), so no separate kotlin-android.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.schoolingsystem.school_portal"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (uses java.time on older APIs).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.schoolingsystem.school_portal"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Backports java.time (and other Java 8+ APIs) so flutter_local_notifications
    // works below its target API. Version tracks the plugin's requirement.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
