// lib/providers/event_provider.dart
import 'package:flutter/foundation.dart';
import 'package:rhythm_game_scheduler/models/event.dart';
import 'package:rhythm_game_scheduler/services/firestore_service.dart';

class EventProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Event> _events = [];
  List<String> _selectedGameIds = [];
  bool _isLoading = false;
  String? _error;
  
  // フィーチャーイベント管理
  List<Event> _featuredEvents = [];
  bool _isFeaturedLoading = false;

  EventProvider() {
    // 初期化時にFirestoreからデータを読み込んでおく
    fetchEvents();
    
    // フィーチャーイベントも取得
    fetchFeaturedEvents();
  }

  List<Event> get events => List.unmodifiable(_events);
  List<Event> get featuredEvents => List.unmodifiable(_featuredEvents);
  bool get isLoading => _isLoading;
  bool get isFeaturedLoading => _isFeaturedLoading;
  String? get error => _error;
  
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

  // Firestoreからイベントデータを取得する（改良版）
  Future<void> fetchEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final events = await _firestoreService.getEvents();
      
      if (events.isNotEmpty) {
        _events = events;
        debugPrint('Loaded ${events.length} events from Firestore');
      } else {
        debugPrint('No events in Firestore, loading sample data');
        // Firestoreにデータがなければサンプルデータを読み込む
        loadSampleEvents();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching Firestore events: $e');
      _error = 'データの取得に失敗しました';
      
      // エラー時もサンプルデータを読み込む
      loadSampleEvents();
      
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // フィーチャーイベントを取得
  Future<void> fetchFeaturedEvents() async {
    _isFeaturedLoading = true;
    notifyListeners();
    
    try {
      final events = await _firestoreService.getFeaturedEvents();
      _featuredEvents = events;
      debugPrint('Loaded ${events.length} featured events');
    } catch (e) {
      debugPrint('Error fetching featured events: $e');
    } finally {
      _isFeaturedLoading = false;
      notifyListeners();
    }
  }

  // 特定のゲームのイベントを取得
  Future<List<Event>> getEventsByGame(String gameId) async {
    try {
      return await _firestoreService.getEventsByGame(gameId);
    } catch (e) {
      debugPrint('Error fetching events for game $gameId: $e');
      return [];
    }
  }

  // ローカルのサンプルデータを読み込む（既存メソッド）
  void loadSampleEvents() {
    final now = DateTime.now();
    
    _events = [
      Event(
        id: '1',
        gameId: 'proseka',
        title: 'Next Frontier!イベント',
        description: 'ランキング形式のイベントです。「Next Frontier!」をテーマにしたカードが手に入ります。',
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 5)),
        type: EventType.ranking,
        imageUrl: 'https://via.placeholder.com/120x80',
      ),
      Event(
        id: '2',
        gameId: 'bandori',
        title: 'ロゼリア 新曲発表会イベント',
        description: 'ロゼリアの新曲「PASSION」をフィーチャーしたイベントです。',
        startDate: now.add(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 10)),
        type: EventType.ranking,
        imageUrl: 'https://via.placeholder.com/120x80',
      ),
      Event(
        id: '3',
        gameId: 'yumeste',
        title: '夏休み特別キャンペーン',
        description: '期間限定で夏をテーマにしたカードがピックアップされたガチャが登場します。',
        startDate: now.add(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 14)),
        type: EventType.gacha,
        imageUrl: 'https://via.placeholder.com/120x80',
      ),
      Event(
        id: '4',
        gameId: 'deresute',
        title: 'LIVE Parade イベント',
        description: 'アイドルの総力戦イベント。チームを編成して上位報酬を目指しましょう。',
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 3)),
        type: EventType.ranking,
        imageUrl: 'https://via.placeholder.com/120x80',
      ),
      Event(
        id: '5',
        gameId: 'mirishita',
        title: '765プロ THANKS フェスティバル',
        description: '765プロダクション全体のライブフェスティバル。レアカードをゲットするチャンス！',
        startDate: now.add(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 14)),
        type: EventType.live,
        imageUrl: 'https://via.placeholder.com/120x80',
      ),
    ];
    
    notifyListeners();
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