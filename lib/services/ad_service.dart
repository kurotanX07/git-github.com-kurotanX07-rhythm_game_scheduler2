import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  
  factory AdService() {
    return _instance;
  }
  
  AdService._internal();
  
  // 広告の表示/非表示フラグ（サブスクリプション購入時にfalseになる）
  bool _showAds = true;
  
  // バナー広告用のテストID
  final String _bannerAdUnitId = kDebugMode
      ? (Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'  // Androidテスト用ID
          : 'ca-app-pub-3940256099942544/2934735716') // iOSテスト用ID
      : '<YOUR_PRODUCTION_BANNER_AD_UNIT_ID>'; // 本番用（後で置き換え）
  
  // インタースティシャル広告用のテストID
  final String _interstitialAdUnitId = kDebugMode
      ? (Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'  // Androidテスト用ID
          : 'ca-app-pub-3940256099942544/4411468910') // iOSテスト用ID
      : '<YOUR_PRODUCTION_INTERSTITIAL_AD_UNIT_ID>'; // 本番用（後で置き換え）
  
  // 広告初期化フラグ
  bool _isInitialized = false;
  
  // バナー広告オブジェクト
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  
  // インタースティシャル広告オブジェクト
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  
  // バナー広告ゲッター
  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerAdLoaded => _isBannerAdLoaded && _showAds;
  
  // 初期化メソッド
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (kIsWeb || !Platform.isAndroid && !Platform.isIOS) {
      // WebまたはAndroid/iOS以外のプラットフォームではスキップ
      debugPrint('AdMob is not supported on this platform');
      return;
    }
    
    // AdMobの初期化
    await MobileAds.instance.initialize();
    
    // サブスクリプション状態を読み込む
    final prefs = await SharedPreferences.getInstance();
    _showAds = !(prefs.getBool('is_premium') ?? false);
    
    _isInitialized = true;
    
    // バナー広告のロード
    await loadBannerAd();
    
    debugPrint('AdMob initialized with ads ${_showAds ? 'enabled' : 'disabled'}');
  }
  
  // バナー広告のロード
  Future<void> loadBannerAd() async {
    if (!_isInitialized || !_showAds) return;
    
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
  }
  
  // インタースティシャル広告のロード
  Future<void> loadInterstitialAd() async {
    if (!_isInitialized || !_showAds) return;
    
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
  }
  
  // インタースティシャル広告の表示
  Future<void> showInterstitialAd() async {
    if (!_isInitialized || !_showAds || !_isInterstitialAdLoaded || _interstitialAd == null) {
      debugPrint('Interstitial ad not ready');
      await loadInterstitialAd(); // 次回のために再読み込み
      return;
    }
    
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
    );
    
    await _interstitialAd!.show();
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
  
  // リソース解放
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    // _subscription変数が未定義のため、この行を削除
    // _subscription?.cancel();
  }
}