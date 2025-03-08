import 'package:flutter/foundation.dart';
import 'package:rhythm_game_scheduler/models/event.dart';
import 'package:rhythm_game_scheduler/services/firestore_service.dart';

class EventProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Event> _events = [];
  List<String> _selectedGameIds = [];
  bool _isLoading = false;
  String? _error;

  EventProvider() {
    // 初期化時にローカルデータを読み込んでおく
    loadSampleEvents();
  }

  List<Event> get events => List.unmodifiable(_events);
  bool get isLoading => _isLoading;
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

  // サンプルデータをFirestoreに追加
  Future<void> seedFirestoreData() async {
    try {
      await _firestoreService.seedSampleData();
      debugPrint('Sample data seeded to Firestore');
    } catch (e) {
      debugPrint('Error seeding Firestore data: $e');
      _error = 'サンプルデータの追加に失敗しました';
    }
  }

  // Firestoreからイベントデータを取得する
  Future<void> fetchFirestoreEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final events = await _firestoreService.getEvents();
      
      if (events.isNotEmpty) {
        _events = events;
        debugPrint('Loaded ${events.length} events from Firestore');
      } else {
        debugPrint('No events in Firestore, using sample data');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching Firestore events: $e');
      _error = 'データの取得に失敗しました';
      _isLoading = false;
      notifyListeners();
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
      // 残りのイベントはそのまま
    ];
    
    notifyListeners();
  }

  // 検索関連の変数を追加
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
      
      // ゲームIDでの検索（ゲーム名で検索するには別途GameProviderとの連携が必要）
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