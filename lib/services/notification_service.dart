import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:rhythm_game_scheduler/models/event.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      // Web/Windowsはサポート範囲外
      debugPrint('通知機能は現在のプラットフォームではサポートされていません');
      return;
    }
    
    // タイムゾーンの初期化
    tz.initializeTimeZones();
    
    // Android設定
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS設定（Windowsビルドでは使用されない）
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    // 初期化
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }
  
  // イベント開始の通知をスケジュールする
  Future<void> scheduleEventStartNotification(Event event, int minutesBefore) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint('通知機能は現在のプラットフォームではサポートされていません');
      return;
    }
    
    debugPrint('イベント開始通知をスケジュール: ${event.title}');
    // モバイル向け実装（Windows開発時は実行されない）
  }
  
  // イベント終了の通知をスケジュールする
  Future<void> scheduleEventEndNotification(Event event, int minutesBefore) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint('通知機能は現在のプラットフォームではサポートされていません');
      return;
    }
    
    debugPrint('イベント終了通知をスケジュール: ${event.title}');
    // モバイル向け実装（Windows開発時は実行されない）
  }
  
  // イベントの通知をキャンセルする
  Future<void> cancelEventNotifications(Event event) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return;
    }
    
    final startId = event.id.hashCode;
    final endId = startId + 1000;
    
    await _flutterLocalNotificationsPlugin.cancel(startId);
    await _flutterLocalNotificationsPlugin.cancel(endId);
  }
  
  // すべての通知をキャンセルする
  Future<void> cancelAllNotifications() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return;
    }
    
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
  
  // 通知権限をリクエストする
  Future<bool> requestPermission() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return false;
    }
    
    // 実際のデバイスでのみ実行される処理
    debugPrint('通知権限のリクエスト');
    return true;
  }
}