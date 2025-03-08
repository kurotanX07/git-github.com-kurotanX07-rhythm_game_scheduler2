plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kurotanx07.rhythm_game_bot"
    compileSdk = flutter.compileSdkVersion
    
    // NDKバージョン設定
    ndkVersion = "26.1.10909125"

    compileOptions {
        // Java 11に変更（Kotlinと合わせる）
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // デスガリングを有効化
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.kurotanx07.rhythm_game_bot"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // マルチDexを有効化
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // デスガリングツールの更新（バージョンを1.2.2以上に）
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")
    // マルチDexのサポートを追加
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}