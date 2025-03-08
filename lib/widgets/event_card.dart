import 'package:flutter/material.dart';
import 'package:rhythm_game_scheduler/models/event.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_game_scheduler/providers/game_provider.dart';
import 'package:rhythm_game_scheduler/models/game.dart';
import 'package:rhythm_game_scheduler/screens/event_detail_screen.dart';

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({super.key, required this.event});

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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // ゲームアイコン
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: game.imageUrl.isNotEmpty
                        ? NetworkImage(game.imageUrl)
                        : null,
                    child: game.imageUrl.isEmpty
                        ? Text(
                            game.name.isNotEmpty ? game.name[0] : '?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (event.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    event.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              Text(event.description),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('開始: ${event.formattedStartDate}'),
                      Text('終了: ${event.formattedEndDate}'),
                    ],
                  ),
                  Text(
                    event.duration,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}