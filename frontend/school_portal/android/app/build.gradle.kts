import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android plugin; it
    // provides Kotlin support (Built-in Kotlin), so no separate kotlin-android.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is driven by android/key.properties, which is gitignored and
// therefore absent on CI and on any dev machine that hasn't set it up. Load it
// only if it exists so debug builds and `flutter run` keep working without the
// keystore; release builds fall back to debug signing when it's missing.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
        namespace = "com.ahkstudios.taleem_hub"
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
        // Matches the Firebase Android app registration — do not change without
        // re-registering in the Firebase console and regenerating
        // google-services.json.
        applicationId = "com.ahkstudios.taleem_hub"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Only declared when key.properties is present; otherwise release falls
        // back to debug signing below.
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Real upload key when key.properties exists (Play Store / signed
            // release APKs); debug key otherwise so `flutter run --release`
            // still works out of the box.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Code/resource shrinking is left off by default: R8 needs
            // keep-rules for Firebase and reflection-based plugins, and
            // enabling it untested can strip classes and break the release
            // build. Turn these on together with a tested proguard-rules.pro.
            isMinifyEnabled = false
            isShrinkResources = false
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
