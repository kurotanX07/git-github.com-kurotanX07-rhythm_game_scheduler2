// lib/providers/improved_event_provider.dart
import 'package:flutter/foundation.dart';
import 'package:rhythm_game_scheduler/models/event.dart';
import 'package:rhythm_game_scheduler/services/improved_firestore_service.dart';
import 'package:rhythm_game_scheduler/providers/game_provider.dart';

class EventProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Event> _events = [];
  List<String> _selectedGameIds = [];
  
  // GameProviderを引数として渡すことができるように
  // ただし、必須ではなく任意のパラメータに変更
  final GameProvider? gameProvider;
  
  // ローディング状態を細分化
  bool _isLoadingEvents = false;
  bool _isLoadingFeaturedEvents = false;
  bool _isRefreshing = false; // プルリフレッシュなどの場合
  
  // エラー状態の細分化
  String? _eventsError;
  String? _featuredEventsError;
  int _retryCount = 0;
  
  // フィーチャーイベント管理
  List<Event> _featuredEvents = [];

  // コンストラクタでgameProviderを任意パラメータに変更
  EventProvider({this.gameProvider}) {
    // 初期化時にFirestoreからデータを読み込む
    fetchEvents();
    
    // フィーチャーイベントも取得
    fetchFeaturedEvents();
  }

  // ゲッター
  List<Event> get events => List.unmodifiable(_events);
  List<Event> get featuredEvents => List.unmodifiable(_featuredEvents);
  bool get isLoading => _isLoadingEvents;
  bool get isRefreshing => _isRefreshing;
  bool get isFeaturedLoading => _isLoadingFeaturedEvents;
  String? get error => _eventsError;
  String? get featuredEventsError => _featuredEventsError;
  int get retryCount => _retryCount;
  
  List<Event> get filteredEvents {
    if (_selectedGameIds.isEmpty) {
      return _events;
    }
    return _events.where((event) => _selectedGameIds.contains(event.gameId)).toList();
  }

  void setSelectedGameIds(List<String> gameIds) {
    _selectedGameIds = gameIds;
    notifyListeners();
  }

  // Firestoreからイベントデータを取得する
  Future<void> fetchEvents({bool isRefresh = false}) async {
    if (isRefresh) {
      _isRefreshing = true;
    } else {
      _isLoadingEvents = true;
    }
    _eventsError = null;
    notifyListeners();

    try {
      final events = await _firestoreService.getEvents();
      
      _events = events;
      debugPrint('Loaded ${events.length} events from Firestore');
      
      // 成功した場合はリトライカウントをリセット
      _retryCount = 0;
    } catch (e) {
      _retryCount++;
      
      if (e is FirestoreServiceException) {
        debugPrint('Firestore error: ${e.type} - ${e.message}');
        _eventsError = e.message;
        
        // ネットワークエラーの場合はユーザーフレンドリーなメッセージ
        if (e.type == FirestoreErrorType.network) {
          _eventsError = 'ネットワーク接続に問題があります。接続を確認して再試行してください。';
        }
      } else {
        debugPrint('Error fetching Firestore events: $e');
        _eventsError = 'データの取得に失敗しました';
      }
      
      // 既存のデータは維持（空にしない）
      // オフラインの場合でもキャッシュされたデータを表示できるようにする
    } finally {
      _isLoadingEvents = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }
  
  // フィーチャーイベントを取得
  Future<void> fetchFeaturedEvents() async {
    _isLoadingFeaturedEvents = true;
    _featuredEventsError = null;
    notifyListeners();
    
    try {
      final events = await _firestoreService.getFeaturedEvents();
      _featuredEvents = events;
      debugPrint('Loaded ${events.length} featured events');
    } catch (e) {
      if (e is FirestoreServiceException) {
        debugPrint('Featured events error: ${e.type} - ${e.message}');
        _featuredEventsError = e.message;
      } else {
        debugPrint('Error fetching featured events: $e');
        _featuredEventsError = 'おすすめイベントの取得に失敗しました';
      }
      
      // エラー時は前回のデータを維持（空にしない）
    } finally {
      _isLoadingFeaturedEvents = false;
      notifyListeners();
    }
  }

  // 特定のゲームのイベントを取得
  Future<List<Event>> getEventsByGame(String gameId) async {
    try {
      return await _firestoreService.getEventsByGame(gameId);
    } catch (e) {
      if (e is FirestoreServiceException) {
        debugPrint('Game events error: ${e.type} - ${e.message}');
        return Future.error(e.message);
      } else {
        debugPrint('Error fetching events for game $gameId: $e');
        return Future.error('ゲームのイベント情報を取得できませんでした');
      }
    }
  }

  // エラー発生時の再試行
  Future<void> retryFetchEvents() async {
    await fetchEvents();
  }
  
  // 全データのリフレッシュ
  Future<void> refreshAllData() async {
    await Future.wait([
      fetchEvents(isRefresh: true),
      fetchFeaturedEvents(),
    ]);
  }

  // 検索関連の変数
  String _searchQuery = '';
  bool _isSearching = false;

  // 検索関連のゲッター
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;

  // 検索結果を取得するゲッター
  List<Event> get searchResults {
    if (_searchQuery.isEmpty) {
      return [];
    }
    
    final query = _searchQuery.toLowerCase();
    return _events.where((event) {
      // イベント名での検索
      if (event.title.toLowerCase().contains(query)) {
        return true;
      }
      
      // ゲームIDでの検索
      if (event.gameId.toLowerCase().contains(query)) {
        return true;
      }
      
      // イベント説明での検索
      if (event.description.toLowerCase().contains(query)) {
        return true;
      }
      
      return false;
    }).toList();
  }

  // 検索状態の切り替え
  void toggleSearch() {
    _isSearching = !_isSearching;
    if (!_isSearching) {
      _searchQuery = ''; // 検索を終了したら検索クエリをクリア
    }
    notifyListeners();
  }

  // 検索クエリの更新
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}