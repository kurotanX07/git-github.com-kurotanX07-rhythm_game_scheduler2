// lib/utils/error_handler.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// グローバルキーを使用するためのインポート
import 'package:rhythm_game_scheduler/main.dart';

class AppErrorHandler {
  // シングルトンパターン
  static final AppErrorHandler _instance = AppErrorHandler._internal();
  factory AppErrorHandler() => _instance;
  AppErrorHandler._internal();

  // エラーログを保存する最大数
  static const int _maxErrorLogs = 50;
  
  // エラー発生時のコールバック（UI通知用）
  Function(String message)? onError;
  
  // UI通知を有効にするかどうか
  bool _enableUINotifications = true;
  
  // アプリケーションの初期化時に呼び出す
  void initialize({bool enableUINotifications = true}) {
    _enableUINotifications = enableUINotifications;
    
    // グローバルエラーハンドリングの設定
    FlutterError.onError = (FlutterErrorDetails details) {
      reportError(details.exception, details.stack);
      // デバッグモードでは元のハンドラーにもエラーを渡す
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };
    
    // 非同期エラーのハンドリング
    PlatformDispatcher.instance.onError = (error, stack) {
      reportError(error, stack);
      return true; // エラーをキャッチしたことを示す
    };
  }
  
  // エラーをログに記録し、必要に応じて通知
  void reportError(dynamic error, StackTrace? stackTrace, {bool? showUI}) {
    final errorMessage = _formatErrorMessage(error);
    final stackTraceStr = stackTrace?.toString() ?? 'No stack trace available';
    
    // エラー内容をログに出力
    developer.log(
      errorMessage,
      name: 'AppErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );
    
    // エラーログを保存
    _saveErrorLog(errorMessage, stackTraceStr);
    
    // UI通知が明示的に無効化されていたら通知しない
    final shouldShowUI = showUI ?? _enableUINotifications;
    if (!shouldShowUI) {
      debugPrint('UI notification suppressed for error: $errorMessage');
      return;
    }
    
    // UIに通知（設定されている場合）
    final message = _getUserFriendlyMessage(error);
    
    // コールバックが設定されている場合は使用
    if (onError != null) {
      onError?.call(message);
    } else {
      // 安全な方法でスナックバーを表示（アプリが初期化済みの場合のみ）
      _tryShowErrorSnackBar(message);
    }
  }
  
  // スナックバーを安全に表示を試みる
  void _tryShowErrorSnackBar(String message) {
    try {
      // ScaffoldMessengerKeyが利用可能か確認
      if (scaffoldMessengerKey.currentState != null && 
          scaffoldMessengerKey.currentContext != null) {
        // UI更新を次のフレームに遅延して安全に実行
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scaffoldMessengerKey.currentState != null) {
            scaffoldMessengerKey.currentState!.clearSnackBars();
            scaffoldMessengerKey.currentState!.showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
      } else {
        // 初期化されていない場合はログにのみ記録
        debugPrint('Error notification (no UI available): $message');
      }
    } catch (e) {
      // スナックバー表示中にエラーが発生しても、アプリがクラッシュしないようにする
      debugPrint('Failed to show error snackbar: $e');
      debugPrint('Original error message: $message');
    }
  }
  
  // ユーザー向けのエラーメッセージを取得
  String _getUserFriendlyMessage(dynamic error) {
    if (error is SocketException || error is TimeoutException) {
      return 'ネットワーク接続に問題があります。接続を確認してください。';
    } else if (error is FormatException) {
      return 'データの形式に問題があります。アプリを再起動してください。';
    } else {
      return '予期しないエラーが発生しました。問題が続く場合は、アプリを再起動してください。';
    }
  }
  
  // エラーメッセージをフォーマット
  String _formatErrorMessage(dynamic error) {
    final timestamp = DateTime.now().toString();
    return '[$timestamp] ${error.toString()}';
  }
  
  // エラーログを保存
  Future<void> _saveErrorLog(String errorMessage, String stackTrace) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 既存のログを取得
      List<String> logs = prefs.getStringList('error_logs') ?? [];
      
      // 新しいログを追加
      final log = '$errorMessage\n$stackTrace';
      logs.add(log);
      
      // 最大数を超えた場合は古いログを削除
      if (logs.length > _maxErrorLogs) {
        logs = logs.sublist(logs.length - _maxErrorLogs);
      }
      
      // 保存
      await prefs.setStringList('error_logs', logs);
    } catch (e) {
      // ログ保存中のエラーは無視（無限ループ防止）
      debugPrint('Error saving error log: $e');
    }
  }
  
  // エラーログを取得
  Future<List<String>> getErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('error_logs') ?? [];
    } catch (e) {
      debugPrint('Error retrieving error logs: $e');
      return [];
    }
  }
  
  // エラーログをクリア
  Future<void> clearErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('error_logs');
    } catch (e) {
      debugPrint('Error clearing error logs: $e');
    }
  }

  // ネットワーク接続状態の確認
  Future<bool> isNetworkAvailable() async {
    try {
      if (kIsWeb) return true; // Webの場合は常にtrueとする
      
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

// エラー表示用のスナックバー
class ErrorSnackBar {
  static void show(BuildContext context, String message) {
    try {
      // まずUI更新を次のフレームに遅延
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          // グローバルキーを使用した表示を試みる
          if (scaffoldMessengerKey.currentState != null) {
            scaffoldMessengerKey.currentState!.clearSnackBars();
            scaffoldMessengerKey.currentState!.showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          
          // コンテキストからScaffoldMessengerを安全に取得
          final messenger = ScaffoldMessenger.maybeOf(context);
          if (messenger != null) {
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          
          // どちらの方法も失敗した場合はログに記録
          debugPrint('Failed to show snackbar: No valid ScaffoldMessenger');
          debugPrint('Error message: $message');
        } catch (e) {
          // エラー発生時にはログに記録
          debugPrint('Error showing snackbar: $e');
          debugPrint('Error message: $message');
        }
      });
    } catch (e) {
      // addPostFrameCallbackでエラーが発生した場合
      debugPrint('Critical error in ErrorSnackBar.show: $e');
      debugPrint('Error message: $message');
    }
  }
}

// アプリケーション全体のエラーをキャッチするためのウィジェット
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
  }) : super(key: key);

  @override
  ErrorBoundaryState createState() => ErrorBoundaryState();
}

class ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(_error!);
    }

    return widget.child;
  }

  static ErrorBoundaryState? of(BuildContext context) {
    return context.findAncestorStateOfType<ErrorBoundaryState>();
  }

  void reportError(FlutterErrorDetails details) {
    setState(() {
      _error = details;
    });
  }
}