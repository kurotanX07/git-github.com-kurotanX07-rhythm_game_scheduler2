import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_game_scheduler/models/game.dart';
import 'package:rhythm_game_scheduler/providers/game_provider.dart';
import 'package:rhythm_game_scheduler/providers/event_provider.dart';

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
                const Text(
                  'ゲームフィルター',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        final gameProvider = context.read<GameProvider>();
                        gameProvider.selectAll();
                        
                        // イベントフィルター更新
                        context.read<EventProvider>().setSelectedGameIds(
                          gameProvider.selectedGames.map((game) => game.id).toList()
                        );
                      },
                      child: const Text('すべて選択'),
                    ),
                    TextButton(
                      onPressed: () {
                        final gameProvider = context.read<GameProvider>();
                        gameProvider.unselectAll();
                        
                        // イベントフィルター更新
                        context.read<EventProvider>().setSelectedGameIds([]);
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
                return Wrap(
                  spacing: 8.0,
                  children: gameProvider.games.map((game) {
                    return FilterChip(
                      label: Text(game.name),
                      selected: game.isSelected,
                      onSelected: (selected) {
                        gameProvider.toggleGameSelection(game.id);
                        
                        // 選択されたゲームのIDをイベントプロバイダーに渡す
                        context.read<EventProvider>().setSelectedGameIds(
                          gameProvider.selectedGames.map((g) => g.id).toList()
                        );
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