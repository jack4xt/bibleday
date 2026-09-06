plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "cz.jack4xt.bibleday"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            storeFile = file("bibleday.keystore")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "Coaster0-Ultimate5-Poise5-Lapdog2-Pediatric8"
            keyAlias = "bibleday"
            keyPassword = System.getenv("KEY_PASSWORD") ?: "Coaster0-Ultimate5-Poise5-Lapdog2-Pediatric8"
        }
    }

    defaultConfig {
        applicationId = "cz.jack4xt.bibleday"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

configurations.all {
    exclude(group = "androidx.work", module = "work-runtime")
    exclude(group = "androidx.work", module = "work-runtime-ktx")
}
