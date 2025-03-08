// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rhythm_game_scheduler/screens/home_screen.dart';
import 'package:rhythm_game_scheduler/providers/game_provider.dart';
import 'package:rhythm_game_scheduler/providers/improved_event_provider.dart'; // 修正
import 'package:rhythm_game_scheduler/providers/settings_provider.dart';
import 'package:rhythm_game_scheduler/services/notification_service.dart';
import 'package:rhythm_game_scheduler/services/improved_ad_service.dart'; // 修正
import 'package:rhythm_game_scheduler/utils/error_handler.dart';
import 'package:rhythm_game_scheduler/utils/secure_config.dart';
import 'package:rhythm_game_scheduler/services/firebase_service.dart';
import 'package:flutter/services.dart';

void main() async {
  // エラーハンドリングの設定
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // エラーハンドラの初期化
    final errorHandler = AppErrorHandler();
    errorHandler.initialize();
    
    // 画面の向きを縦に固定
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // セキュア設定の初期化
    try {
      await SecureConfig().initialize();
      debugPrint('Secure config initialized successfully');
    } catch (e) {
      debugPrint('Warning: Failed to initialize secure config: $e');
      // エラーを記録するが、アプリは続行
      errorHandler.reportError(e, StackTrace.current);
    }

    // Firebase初期化を試みる
    try {
      final firebaseOptions = await SecureFirebaseOptions.getCurrentPlatformOptions();
      await Firebase.initializeApp(
        options: firebaseOptions,
      );
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Firebase: $e');
      // エラーを記録するが、アプリは続行
      errorHandler.reportError(e, StackTrace.current);
    }
      
    // 広告サービスの初期化
    try {
      await AdService().initialize();
    } catch (e) {
      debugPrint('Failed to initialize AdService: $e');
      errorHandler.reportError(e, StackTrace.current);
    }

    // 通知サービスの初期化
    try {
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
      errorHandler.reportError(e, StackTrace.current);
    }
    
    // アプリケーションを起動
    runApp(
      ErrorBoundary(
        errorBuilder: (errorDetails) {
          // 深刻なエラーが発生した場合のフォールバックUI
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'アプリでエラーが発生しました',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('アプリを再起動してください'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // アプリの再起動を試みる
                        SystemNavigator.pop();
                      },
                      child: const Text('アプリを閉じる'),
                    )
                  ],
                ),
              ),
            ),
          );
        },
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    // 未処理の例外をキャッチしてログに記録
    AppErrorHandler().reportError(error, stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // アプリ名を設定ファイルから取得
    final appName = SecureConfig().getString('app_name', 'リズムゲームスケジューラー');
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()), // gameProviderは任意パラメータに変更したので不要
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          // エラーハンドラーにUIコールバックを設定
          AppErrorHandler().onError = (message) {
            if (context.mounted) {
              ErrorSnackBar.show(context, message);
            }
          };
          
          return MaterialApp(
            title: appName,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              brightness: Brightness.dark,
            ),
            themeMode: settingsProvider.darkModeEnabled 
                ? ThemeMode.dark 
                : ThemeMode.light,
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
            // エラー時のフォールバックルート
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              );
            },
          );
        },
      ),
    );
  }
}