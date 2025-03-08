import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_game_scheduler/models/game.dart';
import 'package:rhythm_game_scheduler/providers/game_provider.dart';
import 'package:rhythm_game_scheduler/providers/event_provider.dart';
import 'package:rhythm_game_scheduler/screens/game_list_screen.dart';

class GameFilter extends StatelessWidget {
  const GameFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'ゲームフィルター',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ゲーム一覧へのリンク
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GameListScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.settings,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Consumer<GameProvider>(
                      builder: (context, gameProvider, child) {
                        return IconButton(
                          icon: Icon(
                            gameProvider.favoritesAsFilter ? Icons.favorite : Icons.filter_list,
                            color: gameProvider.favoritesAsFilter ? Colors.red : null,
                            size: 20,
                          ),
                          tooltip: gameProvider.favoritesAsFilter 
                              ? 'お気に入りフィルター使用中' 
                              : '通常フィルターモード',
                          onPressed: () {
                            gameProvider.toggleFavoritesAsFilter();
                          },
                        );
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        final gameProvider = context.read<GameProvider>();
                        gameProvider.selectAll();
                      },
                      child: const Text('すべて選択'),
                    ),
                    TextButton(
                      onPressed: () {
                        final gameProvider = context.read<GameProvider>();
                        gameProvider.unselectAll();
                      },
                      child: const Text('選択解除'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Consumer<GameProvider>(
              builder: (context, gameProvider, child) {
                // お気に入りフィルターが有効の場合は、お気に入りに登録したゲームのみ表示
                final displayGames = gameProvider.favoritesAsFilter
                    ? gameProvider.favoriteGames
                    : gameProvider.games;
                
                if (displayGames.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: Text(
                        gameProvider.favoritesAsFilter
                            ? 'お気に入りに登録したゲームがありません'
                            : 'ゲームが見つかりません',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }
                
                return Wrap(
                  spacing: 8.0,
                  children: displayGames.map((game) {
                    return FilterChip(
                      label: Text(game.name),
                      selected: game.isSelected,
                      avatar: game.isFavorite 
                          ? const Icon(Icons.favorite, size: 14, color: Colors.red) 
                          : null,
                      onSelected: (selected) {
                        gameProvider.toggleGameSelection(game.id);
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}