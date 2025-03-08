plugins {
    id("com.android.application")
    id("kotlin-android")
    // Firebase Crashlyticsプラグインを追加
    id("com.google.firebase.crashlytics")
    // Google Servicesプラグインを追加
    id("com.google.gms.google-services")
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
            // リリース時の難読化を有効化
            isMinifyEnabled = true
            // ProGuardの設定
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("debug") // リリース用の署名設定があれば変更
        }
        
        debug {
            // デバッグビルドでCrashlyticsを無効化（任意）
            manifestPlaceholders["crashlyticsEnabled"] = false
        }
    }
    
    // Firebase Performance Monitoring部分を削除
}

dependencies {
    // デスガリングツールの更新（バージョンを1.2.2以上に）
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")
    
    // マルチDexのサポートを追加
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    
    // Firebase Crashlytics
    implementation("com.google.firebase:firebase-crashlytics")
    
    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}