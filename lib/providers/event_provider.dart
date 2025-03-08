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
    // 初期化時にFirestoreからデータを読み込む
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

  // Firestoreからイベントデータを取得する（サンプルデータを使わないバージョン）
  Future<void> fetchEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final events = await _firestoreService.getEvents();
      
      _events = events; // 空の場合も含めてFirestoreのデータを使用
      debugPrint('Loaded ${events.length} events from Firestore');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching Firestore events: $e');
      _error = 'データの取得に失敗しました';
      
      // エラー時は空のリストをセット（サンプルデータを使わない）
      _events = [];
      
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
      _featuredEvents = []; // エラー時は空リスト
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