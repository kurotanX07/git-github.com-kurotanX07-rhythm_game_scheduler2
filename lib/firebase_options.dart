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
    apiKey: 'AIzaSyCcNLKRfI1fUVnQqWlTH2XtA_UguGlWM6o',
    appId: '1:860612149078:web:44bdd5a9b3de759cdc20f7',
    messagingSenderId: '860612149078',
    projectId: 'rhythm-game-scheduler',
    authDomain: 'rhythm-game-scheduler.firebaseapp.com',
    storageBucket: 'rhythm-game-scheduler.firebasestorage.app',
  );

  // Firebase ConsoleからのAndroid設定
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAo11Jf6Cuy536ZhibDVMZou8ca6UagwwQ',
    appId: '1:860612149078:android:06e4de0ad6ebd184dc20f7',
    messagingSenderId: '860612149078',
    projectId: 'rhythm-game-scheduler',
    storageBucket: 'rhythm-game-scheduler.firebasestorage.app',
  );
}