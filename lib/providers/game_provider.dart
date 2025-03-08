import 'package:flutter/foundation.dart';
import 'package:rhythm_game_scheduler/models/game.dart';

class GameProvider with ChangeNotifier {
  // サンプルデータとして、主要なリズムゲームを追加
  final List<Game> _games = [
    Game(
      id: 'proseka',
      name: 'プロジェクトセカイ',
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
      id: 'yumeステ',
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

  List<Game> get games => List.unmodifiable(_games);
  List<Game> get selectedGames => _games.where((game) => game.isSelected).toList();

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
}