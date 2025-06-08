plugins {
    id("com.android.application")
    id("com.google.gms.google-services")

    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.veterinary_app"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true

    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.veterinary_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // Import the Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:32.7.4")) // Corrected syntax
    // Add the Firebase SDK for Google Analytics (optional, but good for FCM)
    implementation("com.google.firebase:firebase-analytics-ktx") // Corrected syntax for Kotlin
    // Add the Firebase SDK for Cloud Messaging
    implementation("com.google.firebase:firebase-messaging-ktx") // Corrected syntax for Kotlin
    implementation(kotlin("stdlib-jdk8"))

}

flutter {
    source = "../.."
}
