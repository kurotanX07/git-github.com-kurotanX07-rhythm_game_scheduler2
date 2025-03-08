// lib/services/improved_ad_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rhythm_game_scheduler/utils/secure_config.dart';
import 'package:rhythm_game_scheduler/utils/error_handler.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  
  factory AdService() {
    return _instance;
  }
  
  AdService._internal();
  
  // 広告の表示/非表示フラグ（サブスクリプション購入時にfalseになる）
  bool _showAds = true;
  
  // 設定から広告IDを取得
  final SecureConfig _config = SecureConfig();
  
  // 広告初期化フラグ
  bool _isInitialized = false;
  
  // バナー広告オブジェクト
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  
  // インタースティシャル広告オブジェクト
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  
  // 広告表示の制限（ユーザー体験向上のため）
  DateTime? _lastInterstitialShown;
  static const Duration _minInterstitialInterval = Duration(minutes: 3);
  int _sessionAdCount = 0;
  static const int _maxAdsPerSession = 8;
  
  // バナー広告ゲッター
  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerAdLoaded => _isBannerAdLoaded && _showAds;
  
  // 初期化メソッド
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      // WebまたはAndroid/iOS以外のプラットフォームではスキップ
      debugPrint('AdMob is not supported on this platform');
      return;
    }
    
    try {
      // 設定の初期化を確認
      if (!_config.isInitialized) {
        await _config.initialize();
      }
      
      // AdMobの初期化
      await MobileAds.instance.initialize();
      
      // テスト端末の設定（開発時のみ）
      if (kDebugMode) {
        final testDeviceIds = [
          'A15D5SE1D50984EDC8DF97971E593BC8', // テスト端末IDを追加
        ];
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: testDeviceIds),
        );
      }
      
      // サブスクリプション状態を読み込む
      final prefs = await SharedPreferences.getInstance();
      _showAds = !(prefs.getBool('is_premium') ?? false);
      
      _isInitialized = true;
      
      // バナー広告のロード
      await loadBannerAd();
      
      debugPrint('AdMob initialized with ads ${_showAds ? 'enabled' : 'disabled'}');
    } catch (e, stack) {
      debugPrint('Failed to initialize AdMob: $e');
      AppErrorHandler().reportError(e, stack);
      // 初期化失敗時も続行できるようにする
      _isInitialized = true;
    }
  }
  
  String get _bannerAdUnitId {
    return _config.getAdMobBannerId();
  }
  
  String get _interstitialAdUnitId {
    return _config.getAdMobInterstitialId();
  }
  
  // バナー広告のロード
  Future<void> loadBannerAd() async {
    if (!_isInitialized || !_showAds) return;
    
    try {
      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Banner ad loaded');
            _isBannerAdLoaded = true;
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: $error');
            ad.dispose();
            _isBannerAdLoaded = false;
            _bannerAd = null;
          },
        ),
      );
      
      await _bannerAd?.load();
    } catch (e, stack) {
      debugPrint('Error loading banner ad: $e');
      AppErrorHandler().reportError(e, stack);
      _isBannerAdLoaded = false;
      _bannerAd = null;
    }
  }
  
  // インタースティシャル広告のロード
  Future<void> loadInterstitialAd() async {
    if (!_isInitialized || !_showAds) return;
    
    // すでにロード中またはロード済みの場合はスキップ
    if (_isInterstitialAdLoaded || _interstitialAd != null) return;
    
    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Interstitial ad loaded');
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load: $error');
            _isInterstitialAdLoaded = false;
            _interstitialAd = null;
          },
        ),
      );
    } catch (e, stack) {
      debugPrint('Error loading interstitial ad: $e');
      AppErrorHandler().reportError(e, stack);
      _isInterstitialAdLoaded = false;
      _interstitialAd = null;
    }
  }
  
  // インタースティシャル広告の表示
  Future<bool> showInterstitialAd() async {
    if (!_isInitialized || !_showAds) {
      debugPrint('Ads not initialized or disabled');
      return false;
    }
    
    // セッションあたりの広告表示回数制限
    if (_sessionAdCount >= _maxAdsPerSession) {
      debugPrint('Maximum ads per session reached');
      return false;
    }
    
    // 広告表示間隔の制限
    final now = DateTime.now();
    if (_lastInterstitialShown != null) {
      final timeSinceLastAd = now.difference(_lastInterstitialShown!);
      if (timeSinceLastAd < _minInterstitialInterval) {
        debugPrint('Too soon to show another interstitial ad');
        return false;
      }
    }
    
    if (!_isInterstitialAdLoaded || _interstitialAd == null) {
      debugPrint('Interstitial ad not ready');
      await loadInterstitialAd(); // 次回のために再読み込み
      return false;
    }
    
    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Interstitial ad dismissed');
          ad.dispose();
          _isInterstitialAdLoaded = false;
          _interstitialAd = null;
          // 広告が閉じられたら再度ロードする
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Interstitial ad failed to show: $error');
          ad.dispose();
          _isInterstitialAdLoaded = false;
          _interstitialAd = null;
          // 失敗した場合も再度ロードする
          loadInterstitialAd();
        },
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Interstitial ad showed successfully');
          _lastInterstitialShown = now;
          _sessionAdCount++;
        }
      );
      
      await _interstitialAd!.show();
      return true;
    } catch (e, stack) {
      debugPrint('Error showing interstitial ad: $e');
      AppErrorHandler().reportError(e, stack);
      _isInterstitialAdLoaded = false;
      _interstitialAd = null;
      loadInterstitialAd();
      return false;
    }
  }
  
  // 広告の有効/無効を切り替える（サブスクリプション購入時などに使用）
  Future<void> setAdsEnabled(bool enabled) async {
    _showAds = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', !enabled);
    
    if (enabled) {
      await loadBannerAd();
      await loadInterstitialAd();
    } else {
      _bannerAd?.dispose();
      _interstitialAd?.dispose();
      _bannerAd = null;
      _interstitialAd = null;
      _isBannerAdLoaded = false;
      _isInterstitialAdLoaded = false;
    }
    
    debugPrint('Ads ${enabled ? 'enabled' : 'disabled'}');
  }
  
  // セッションカウンターのリセット（アプリ再起動時やホーム画面に戻った時など）
  void resetSessionAdCount() {
    _sessionAdCount = 0;
  }
  
  // リソース解放
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    _isBannerAdLoaded = false;
    _isInterstitialAdLoaded = false;
  }
}