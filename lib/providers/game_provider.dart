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

  // Firestoreからゲーム情報を取得
  Future<void> fetchGames() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final games = await _firestoreService.getGames();
      
      if (games.isNotEmpty) {
        _games = games;
        debugPrint('Loaded ${games.length} games from Firestore');
      } else {
        debugPrint('No games in Firestore, loading sample data');
        // Firestoreにデータがなければサンプルデータを読み込む
        loadSampleGames();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching Firestore games: $e');
      _error = 'ゲーム情報の取得に失敗しました';
      
      // エラー時もサンプルデータを読み込む
      loadSampleGames();
      
      _isLoading = false;
      notifyListeners();
    }
  }

  // サンプルゲームデータの読み込み
  void loadSampleGames() {
    _games = [
      Game(
        id: 'proseka',
        name: 'プロジェクトセカイカラフルステージ',
        imageUrl: 'https://via.placeholder.com/50',
        developer: 'SEGA / Colorful Palette',
      ),
      Game(
        id: 'bandori',
        name: 'バンドリ！ガールズバンドパーティ！',
        imageUrl: 'https://via.placeholder.com/50',
        developer: 'Craft Egg / Bushiroad',
      ),
      Game(
        id: 'yumeste',
        name: 'ユメステ',
        imageUrl: 'https://via.placeholder.com/50',
        developer: 'Happy Elements',
      ),
      Game(
        id: 'deresute',
        name: 'アイドルマスター シンデレラガールズ スターライトステージ',
        imageUrl: 'https://via.placeholder.com/50',
        developer: 'Bandai Namco Entertainment / Cygames',
      ),
      Game(
        id: 'mirishita',
        name: 'アイドルマスター ミリオンライブ！ シアターデイズ',
        imageUrl: 'https://via.placeholder.com/50',
        developer: 'Bandai Namco Entertainment',
      ),
    ];
    
    notifyListeners();
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