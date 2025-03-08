// lib/services/firebase_service.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:rhythm_game_scheduler/utils/secure_config.dart';

/// 安全にFirebaseの設定を提供するクラス
class SecureFirebaseOptions {
  // 設定インスタンス
  static final _config = SecureConfig();
  
  /// 現在のプラットフォームに対するFirebaseOptionsを取得
  static Future<FirebaseOptions> getCurrentPlatformOptions() async {
    // 設定の初期化を確認
    if (!SecureConfig().isInitialized) {
      await SecureConfig().initialize();
    }
    
    if (kIsWeb) {
      return web;
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return web; // Windowsの場合はWeb設定を使用
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web設定
  static FirebaseOptions get web {
    final apiKey = _config.getApiKey();
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: _config.getString('firebase_web_app_id', '1:801753812238:web:9e434bd7afe8953eb79b5f'),
      messagingSenderId: _config.getString('firebase_messaging_sender_id', '801753812238'),
      projectId: _config.getString('firebase_project_id', 'rhythm-game-bot'),
      authDomain: _config.getString('firebase_auth_domain', 'rhythm-game-bot.firebaseapp.com'),
      storageBucket: _config.getString('firebase_storage_bucket', 'rhythm-game-bot.firebasestorage.app'),
    );
  }

  // Android設定
  static FirebaseOptions get android {
    final apiKey = _config.getApiKey();
    
    return FirebaseOptions(
      apiKey: apiKey,
      appId: _config.getString('firebase_android_app_id', '1:801753812238:android:16bafb09152f2621b79b5f'),
      messagingSenderId: _config.getString('firebase_messaging_sender_id', '801753812238'),
      projectId: _config.getString('firebase_project_id', 'rhythm-game-bot'),
      storageBucket: _config.getString('firebase_storage_bucket', 'rhythm-game-bot.firebasestorage.app'),
    );
  }
}