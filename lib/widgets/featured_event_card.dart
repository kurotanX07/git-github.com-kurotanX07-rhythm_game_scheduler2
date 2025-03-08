// lib/widgets/featured_event_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_game_scheduler/models/event.dart';
import 'package:rhythm_game_scheduler/providers/game_provider.dart';
import 'package:rhythm_game_scheduler/screens/event_detail_screen.dart';

class FeaturedEventCard extends StatelessWidget {
  final Event event;

  const FeaturedEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.read<GameProvider>();
    final game = gameProvider.getGameById(event.gameId);

    // イベントステータスに基づいてカードの色を決定
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          width: 160,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // イベント画像
              Stack(
                children: [
                  // イベント画像
                  event.imageUrl.isNotEmpty
                      ? Image.network(
                          event.imageUrl,
                          height: 90,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 90,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.error),
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 90,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image),
                          ),
                        ),
                  
                  // ゲーム名とアイコンをオーバーレイ表示
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      color: Colors.black.withOpacity(0.6),
                      child: Row(
                        children: [
                          // ゲームアイコン（小さめのCircleAvatar）
                          CircleAvatar(
                            radius: 8,
                            backgroundColor: Colors.white,
                            backgroundImage: game.imageUrl.isNotEmpty
                                ? NetworkImage(game.imageUrl)
                                : null,
                            child: game.imageUrl.isEmpty
                                ? Text(
                                    game.name.isNotEmpty ? game.name[0] : '?',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.black,
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(width: 4),
                          // ゲーム名
                          Expanded(
                            child: Text(
                              game.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // ステータスバッジ
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // イベントタイトルと期間
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // イベントタイトル
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const Spacer(),
                      
                      // 期間
                      Text(
                        '${event.formattedStartDate.substring(5)} 〜',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        event.formattedEndDate.substring(5),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}