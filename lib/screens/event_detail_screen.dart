import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_game_scheduler/models/event.dart';
import 'package:rhythm_game_scheduler/models/game.dart';
import 'package:rhythm_game_scheduler/providers/game_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rhythm_game_scheduler/utils/calendar_utils.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.read<GameProvider>();
    final game = gameProvider.games.firstWhere(
      (g) => g.id == event.gameId,
      orElse: () => Game(
        id: 'unknown',
        name: '不明なゲーム',
        imageUrl: '',
        developer: '',
      ),
    );

    // イベントの状態に応じたステータス表示
    Widget _buildStatusChip() {
      Color statusColor;
      String statusText;

      if (event.isActive) {
        statusColor = Colors.green;
        statusText = '開催中';
      } else if (event.isUpcoming) {
        statusColor = Colors.blue;
        statusText = '近日開始';
      } else {
        statusColor = Colors.grey;
        statusText = '終了';
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          statusText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    // 関連リンクを開く関数
    Future<void> _launchURL(String url) async {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('URLを開けませんでした')),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('イベント詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // シェア機能（実装予定）
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('シェア機能は近日実装予定です')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ゲーム情報
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: game.imageUrl.isNotEmpty
                      ? NetworkImage(game.imageUrl)
                      : null,
                  child: game.imageUrl.isEmpty ? Text(game.name[0]) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
              ],
            ),
            
            const SizedBox(height: 20),
            
            // イベントタイトルとステータス
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // イベント画像
            if (event.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  event.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // 期間情報
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'イベント期間',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('開始日時'),
                            Text(
                              event.formattedStartDate,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('終了日時'),
                            Text(
                              event.formattedEndDate,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Chip(
                        label: Text(
                          '期間: ${event.duration}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // イベント詳細情報
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'イベント詳細',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // イベントタイプに応じた追加情報（例：ランキング情報など）
            if (event.type == EventType.ranking)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ランキング報酬',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('※ 実際のランキング報酬情報が入ります'),
                      // ここにランキング報酬情報を追加
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // 関連リンク
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '関連リンク',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.public),
                      title: const Text('公式サイト'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () {
                        // ダミーリンク - 実際のゲームの公式サイトURLに変更する
                        _launchURL('https://example.com');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.gamepad),
                      title: const Text('アプリを開く'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () {
                        // 各ゲームのスキーム（deep link）または公式サイトに変更
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('近日実装予定の機能です')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // アクションボタン
            Row(
              children: [
                // カレンダー登録ボタン
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('カレンダーに登録'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      final success = await CalendarUtils.addEventToCalendar(event);
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('カレンダーに登録しました')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('カレンダー登録に失敗しました')),
                          );
                        }
                      }
                    },
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // リマインダーボタン
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('アプリ内通知'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      // リマインダー機能（実装予定）
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('リマインダー機能は近日実装予定です')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}