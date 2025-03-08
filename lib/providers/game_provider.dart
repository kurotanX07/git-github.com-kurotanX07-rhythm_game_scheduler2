// lib/providers/game_provider.dart
import 'package:flutter/foundation.dart';
import 'package:rhythm_game_scheduler/models/game.dart';
import 'package:rhythm_game_scheduler/services/firestore_service.dart';

class GameProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Game> _games = [];
  bool _isLoading = false;
  String? _error;

  GameProvider() {
    // 初期化時にFirestoreからゲーム情報を取得
    fetchGames();
  }

  List<Game> get games => List.unmodifiable(_games);
  List<Game> get selectedGames => _games.where((game) => game.isSelected).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Firestoreからゲーム情報を取得（サンプルデータを使わないバージョン）
  Future<void> fetchGames() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final games = await _firestoreService.getGames();
      
      _games = games; // 空の場合も含めてFirestoreのデータをそのまま使用
      debugPrint('Loaded ${games.length} games from Firestore');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching Firestore games: $e');
      _error = 'ゲーム情報の取得に失敗しました';
      
      // エラー時は空のリストをセット（サンプルデータを使わない）
      _games = [];
      
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleGameSelection(String gameId) {
    final index = _games.indexWhere((game) => game.id == gameId);
    if (index != -1) {
      final game = _games[index];
      _games[index] = game.copyWith(isSelected: !game.isSelected);
      notifyListeners();
    }
  }

  void selectAll() {
    _games.asMap().forEach((index, game) {
      _games[index] = game.copyWith(isSelected: true);
    });
    notifyListeners();
  }

  void unselectAll() {
    _games.asMap().forEach((index, game) {
      _games[index] = game.copyWith(isSelected: false);
    });
    notifyListeners();
  }
  
  // ゲームIDからゲーム情報を取得
  Game getGameById(String gameId) {
    return _games.firstWhere(
      (game) => game.id == gameId,
      orElse: () => Game(
        id: 'unknown',
        name: '不明なゲーム',
        imageUrl: '',
        developer: '',
      ),
    );
  }
}