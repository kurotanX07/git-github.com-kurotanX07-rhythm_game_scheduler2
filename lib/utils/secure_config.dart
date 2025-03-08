// lib/utils/secure_config.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// アプリの設定と機密情報を安全に管理するクラス
class SecureConfig {
  // シングルトンパターン
  static final SecureConfig _instance = SecureConfig._internal();
  factory SecureConfig() => _instance;
  SecureConfig._internal();

  // 機密情報の保存に使用するセキュアストレージ
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // キャッシュされた設定値
  Map<String, dynamic> _configValues = {};
  bool _isInitialized = false;
  
  // 初期化状態を取得するためのgetter追加
  bool get isInitialized => _isInitialized;

  // 機密ではない設定の読み込み
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 非機密設定ファイルを読み込む（assets内のJSONファイル）
      await _loadConfigFile();
      
      // 機密情報をセキュアストレージから読み込む
      await _loadSecureValues();
      
      _isInitialized = true;
      debugPrint('SecureConfig initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize SecureConfig: $e');
      rethrow;
    }
  }

  // 設定ファイルからの値の読み込み
  Future<void> _loadConfigFile() async {
    try {
      final configString = await rootBundle.loadString('assets/config.json');
      final config = json.decode(configString) as Map<String, dynamic>;
      _configValues.addAll(config);
    } catch (e) {
      debugPrint('Error loading config file: $e');
      // デフォルト値を使用
      _configValues = {
        // デフォルト設定
        'app_name': 'リズムゲームスケジューラー',
        'debug_mode': kDebugMode,
        'cache_ttl_minutes': 60,
        'ads_enabled': true,
      };
    }
  }

  // セキュアストレージからの機密情報の読み込み
  Future<void> _loadSecureValues() async {
    try {
      // 保存されている全ての値を読み込む
      final allValues = await _secureStorage.readAll();
      
      if (allValues.isEmpty) {
        // 初回起動時は開発環境の値を設定
        if (kDebugMode) {
          await _setDefaultSecureValues();
        }
      } else {
        // 機密情報をメモリにロード
        for (final entry in allValues.entries) {
          _configValues[entry.key] = entry.value;
        }
      }
    } catch (e) {
      debugPrint('Error loading secure values: $e');
      // セキュアストレージの読み込みに失敗した場合でもデフォルト値を使用
      if (kDebugMode) {
        await _setDefaultSecureValues();
      }
    }
  }

  // 開発用のデフォルト値設定（本番では使用しない）
  Future<void> _setDefaultSecureValues() async {
    final defaultSecureValues = {
      'firebase_api_key': 'AIzaSyB4j3dsfn-4oRf8mT-rccxf4Y7h1qw9sI0', // テスト用
      'admob_app_id': 'ca-app-pub-3940256099942544~3347511713', // テスト用
      'admob_banner_id': 'ca-app-pub-3940256099942544/6300978111', // テスト用
      'admob_interstitial_id': 'ca-app-pub-3940256099942544/1033173712', // テスト用
    };
    
    // 設定値をセキュアストレージに保存
    for (final entry in defaultSecureValues.entries) {
      await _secureStorage.write(key: entry.key, value: entry.value);
      _configValues[entry.key] = entry.value;
    }
    
    debugPrint('Default secure values set for development environment');
  }

  // 環境に応じた設定値の取得
  String getApiKey() {
    // 本番環境と開発環境で別のキーを使用
    final keyName = kReleaseMode ? 'firebase_api_key_prod' : 'firebase_api_key';
    return getString(keyName, '');
  }

  // AdMob用のIDを取得
  String getAdMobAppId() {
    final keyName = kReleaseMode ? 'admob_app_id_prod' : 'admob_app_id';
    return getString(keyName, '');
  }

  String getAdMobBannerId() {
    final keyName = kReleaseMode ? 'admob_banner_id_prod' : 'admob_banner_id';
    return getString(keyName, '');
  }

  String getAdMobInterstitialId() {
    final keyName = kReleaseMode ? 'admob_interstitial_id_prod' : 'admob_interstitial_id';
    return getString(keyName, '');
  }

  // 汎用的な設定値取得メソッド
  String getString(String key, String defaultValue) {
    return _configValues[key]?.toString() ?? defaultValue;
  }

  int getInt(String key, int defaultValue) {
    final value = _configValues[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  bool getBool(String key, bool defaultValue) {
    final value = _configValues[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return defaultValue;
  }

  double getDouble(String key, double defaultValue) {
    final value = _configValues[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // カスタム設定の保存（利用者固有の設定など）
  Future<void> saveSecureValue(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
    _configValues[key] = value;
  }

  // カスタム設定の削除
  Future<void> removeSecureValue(String key) async {
    await _secureStorage.delete(key: key);
    _configValues.remove(key);
  }

  // 全てのセキュア設定をクリア（ログアウト時など）
  Future<void> clearAllSecureValues() async {
    await _secureStorage.deleteAll();
    
    // 機密情報のみを削除
    final keysToRemove = [
      'firebase_api_key',
      'firebase_api_key_prod',
      'admob_app_id',
      'admob_app_id_prod',
      'admob_banner_id',
      'admob_banner_id_prod',
      'admob_interstitial_id',
      'admob_interstitial_id_prod',
      'user_token',
      'refresh_token',
    ];
    
    for (final key in keysToRemove) {
      _configValues.remove(key);
    }
  }
}