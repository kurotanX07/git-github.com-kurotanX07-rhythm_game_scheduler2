// lib/providers/game_provider.dart
import 'package:flutter/foundation.dart';
import 'package:rhythm_game_scheduler/models/game.dart';
import 'package:rhythm_game_scheduler/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Game> _games = [];
  bool _isLoading = false;
  String? _error;
  bool _favoritesAsFilter = false; // お気に入りをフィルターとして使用するかどうか

  GameProvider() {
    // 初期化時にLocalStorageから設定を読み込んでから、Firestoreからゲーム情報を取得
    _loadPreferences().then((_) => fetchGames());
  }

  List<Game> get games => List.unmodifiable(_games);
  List<Game> get selectedGames => _games.where((game) => game.isSelected).toList();
  List<Game> get favoriteGames => _games.where((game) => game.isFavorite).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get favoritesAsFilter => _favoritesAsFilter;

  // 設定を読み込む
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // お気に入り設定の読み込み
      final favoriteIds = prefs.getStringList('favorite_games') ?? [];
      
      // フィルター設定の読み込み
      final selectedIds = prefs.getStringList('selected_games') ?? [];
      
      // お気に入りをフィルターとして使用するかの設定
      _favoritesAsFilter = prefs.getBool('favorites_as_filter') ?? false;
      
      // ゲームリストへの反映は、ゲーム読み込み後に行う
      _favoriteIds = favoriteIds;
      _selectedIds = selectedIds;
      
      debugPrint('Loaded preferences: ${favoriteIds.length} favorites, ${selectedIds.length} selected');
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  // 設定を保存する
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // お気に入り設定の保存
      final favoriteIds = _games
          .where((game) => game.isFavorite)
          .map((game) => game.id)
          .toList();
      await prefs.setStringList('favorite_games', favoriteIds);
      
      // フィルター設定の保存
      final selectedIds = _games
          .where((game) => game.isSelected)
          .map((game) => game.id)
          .toList();
      await prefs.setStringList('selected_games', selectedIds);
      
      // お気に入りをフィルターとして使用するかの設定
      await prefs.setBool('favorites_as_filter', _favoritesAsFilter);
      
      debugPrint('Saved preferences: ${favoriteIds.length} favorites, ${selectedIds.length} selected');
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  // ロード中に保持しておくIDリスト
  List<String> _favoriteIds = [];
  List<String> _selectedIds = [];

  // Firestoreからゲーム情報を取得
  Future<void> fetchGames() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final games = await _firestoreService.getGames();
      
      if (games.isNotEmpty) {
        // 保存しておいたお気に入りとフィルター状態を反映
        _games = games.map((game) {
          return game.copyWith(
            isFavorite: _favoriteIds.contains(game.id),
            isSelected: _selectedIds.contains(game.id),
          );
        }).toList();
        
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
    final sampleGames = [
      Game(
        id: 'proseka',
        name: 'プロジェクトセカイカラフルステージ',
        imageUrl: 'https://via.placeholder.com/50',
        developer: 'SEGA / Colorful Palette',
        description: 'バーチャル・シンガーと新世代アイドルたちが織りなす、新しい音楽ゲーム。',
        officialUrl: 'https://pjsekai.sega.jp/',
      ),
      Game(
        id: 'bandori',
        name: 'バンドリ！ガールズバンドパーティ！',
        imageUrl: 'https://via.placeholder.com/50',
        developer: 'Craft Egg / Bushiroad',
        description: '「キズナ」と「ガールズバンド」をテーマにしたリズムゲーム。',
        officialUrl: 'https://bang-dream.bushimo.jp/',
      ),
      Game(
        id: 'yumeste',
        name: 'ユメステ',
        imageUrl: 'https://via.placeholder.com/50',
        developer: 'Happy Elements',
        description: 'あんさんぶるスターズ!!Music のリズムゲーム。',
        officialUrl: 'https://ensemble-stars.jp/',
      ),
      Game(
        id: 'deresute',
        name: 'アイドルマスター シンデレラガールズ スターライトステージ',
        imageUrl: 'https://via.placeholder.com/50',
        developer: 'Bandai Namco Entertainment / Cygames',
        description: 'アイドルマスター シンデレラガールズのリズムゲームアプリ。',
        officialUrl: 'https://cinderella.idolmaster.jp/sl-stage/',
      ),
      Game(
        id: 'mirishita',
        name: 'アイドルマスター ミリオンライブ！ シアターデイズ',
        imageUrl: 'https://via.placeholder.com/50',
        developer: 'Bandai Namco Entertainment',
        description: 'アイドルマスター ミリオンライブ!のリズムゲームアプリ。',
        officialUrl: 'https://millionlive.idolmaster.jp/theaterdays/',
      ),
    ];
    
    // 保存しておいたお気に入りとフィルター状態を反映
    _games = sampleGames.map((game) {
      return game.copyWith(
        isFavorite: _favoriteIds.contains(game.id),
        isSelected: _selectedIds.contains(game.id),
      );
    }).toList();
    
    notifyListeners();
  }

  // ゲームの選択状態を切り替え（フィルター用）
  void toggleGameSelection(String gameId) {
    final index = _games.indexWhere((game) => game.id == gameId);
    if (index != -1) {
      final game = _games[index];
      _games[index] = game.copyWith(isSelected: !game.isSelected);
      _savePreferences();
      notifyListeners();
    }
  }

  // すべてのゲームを選択
  void selectAll() {
    _games = _games.asMap().entries.map((entry) {
      return entry.value.copyWith(isSelected: true);
    }).toList();
    _savePreferences();
    notifyListeners();
  }

  // すべてのゲームの選択を解除
  void unselectAll() {
    _games = _games.asMap().entries.map((entry) {
      return entry.value.copyWith(isSelected: false);
    }).toList();
    _savePreferences();
    notifyListeners();
  }
  
  // ゲームのお気に入り状態を切り替え
  void toggleFavorite(String gameId) {
    final index = _games.indexWhere((game) => game.id == gameId);
    if (index != -1) {
      final game = _games[index];
      _games[index] = game.copyWith(isFavorite: !game.isFavorite);
      _savePreferences();
      notifyListeners();
    }
  }
  
  // お気に入りをフィルターとして使用するかどうかの設定を切り替え
  void toggleFavoritesAsFilter() {
    _favoritesAsFilter = !_favoritesAsFilter;
    _savePreferences();
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