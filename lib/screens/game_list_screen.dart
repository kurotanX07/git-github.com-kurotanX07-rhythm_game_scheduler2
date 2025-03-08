import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_game_scheduler/models/game.dart';
import 'package:rhythm_game_scheduler/providers/game_provider.dart';
import 'package:rhythm_game_scheduler/providers/event_provider.dart';
import 'package:rhythm_game_scheduler/screens/game_detail_screen.dart';

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  bool _showOnlyFavorites = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ゲーム一覧'),
        actions: [
          // お気に入りだけを表示するトグルボタン
          IconButton(
            icon: Icon(
              _showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
              color: _showOnlyFavorites ? Colors.red : null,
            ),
            onPressed: () {
              setState(() {
                _showOnlyFavorites = !_showOnlyFavorites;
              });
            },
            tooltip: _showOnlyFavorites ? 'すべて表示' : 'お気に入りのみ表示',
          ),
          // 更新ボタン
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<GameProvider>().fetchGames();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ゲーム情報を更新しています...')),
              );
            },
            tooltip: 'ゲーム情報の更新',
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          if (gameProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (gameProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'エラーが発生しました',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(gameProvider.error ?? ''),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => gameProvider.fetchGames(),
                    child: const Text('再試行'),
                  ),
                ],
              ),
            );
          }

          final games = _showOnlyFavorites
              ? gameProvider.games.where((game) => game.isFavorite).toList()
              : gameProvider.games;

          if (games.isEmpty) {
            return Center(
              child: Text(
                _showOnlyFavorites
                    ? 'お気に入りのゲームがありません'
                    : 'ゲームが見つかりません',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return _buildGameCard(context, game, gameProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildGameCard(
      BuildContext context, Game game, GameProvider gameProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () {
          // ゲーム詳細画面へ遷移
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameDetailScreen(gameId: game.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // ゲームアイコン
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: game.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(game.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: game.imageUrl.isEmpty
                    ? Center(
                        child: Text(
                          game.name.isNotEmpty ? game.name[0] : '?',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // ゲーム情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.developer,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // お気に入りボタン
              IconButton(
                icon: Icon(
                  game.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: game.isFavorite ? Colors.red : null,
                ),
                onPressed: () {
                  gameProvider.toggleFavorite(game.id);
                },
                tooltip: game.isFavorite ? 'お気に入りから削除' : 'お気に入りに追加',
              ),
              // フィルター選択ボタン
              IconButton(
                icon: Icon(
                  game.isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                ),
                onPressed: () {
                  gameProvider.toggleGameSelection(game.id);
                },
                tooltip: game.isSelected ? 'フィルターから外す' : 'フィルターに追加',
              ),
            ],
          ),
        ),
      ),
    );
  }
}