import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
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

  // Firebase ConsoleからのWeb設定
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB4j3dsfn-4oRf8mT-rccxf4Y7h1qw9sI0',
    appId: '1:801753812238:web:9e434bd7afe8953eb79b5f',
    messagingSenderId: '801753812238',
    projectId: 'rhythm-game-bot',
    authDomain: 'rhythm-game-bot.firebaseapp.com',
    storageBucket: 'rhythm-game-bot.firebasestorage.app',
  );

  // Firebase ConsoleからのAndroid設定
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA0hsHbFPDgciYgwD7OlTAzu3BGyhuT-WM',
    appId: '1:801753812238:android:16bafb09152f2621b79b5f',
    messagingSenderId: '801753812238',
    projectId: 'rhythm-game-bot',
    storageBucket: 'rhythm-game-bot.firebasestorage.app',
  );
}