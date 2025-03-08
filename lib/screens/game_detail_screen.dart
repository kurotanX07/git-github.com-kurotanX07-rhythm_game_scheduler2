import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_game_scheduler/models/game.dart';
import 'package:rhythm_game_scheduler/models/event.dart';
import 'package:rhythm_game_scheduler/providers/game_provider.dart';
import 'package:rhythm_game_scheduler/providers/event_provider.dart';
import 'package:rhythm_game_scheduler/screens/event_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class GameDetailScreen extends StatefulWidget {
  final String gameId;

  const GameDetailScreen({super.key, required this.gameId});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  List<Event> _gameEvents = [];
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _loadGameEvents();
  }

  Future<void> _loadGameEvents() async {
    setState(() {
      _isLoadingEvents = true;
    });

    try {
      final events = await context.read<EventProvider>().getEventsByGame(widget.gameId);
      setState(() {
        _gameEvents = events;
        _isLoadingEvents = false;
      });
    } catch (e) {
      setState(() {
        _gameEvents = [];
        _isLoadingEvents = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ゲーム詳細'),
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          final game = gameProvider.getGameById(widget.gameId);

          if (game.id == 'unknown') {
            return const Center(
              child: Text('ゲームが見つかりません'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ゲーム情報ヘッダー
                _buildGameHeader(context, game, gameProvider),
                
                const SizedBox(height: 24),
                
                // イベント一覧
                _buildEventsSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameHeader(
      BuildContext context, Game game, GameProvider gameProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ゲームアイコン
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
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
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // ゲーム詳細情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '開発: ${game.developer}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // お気に入りとフィルター設定用のトグルボタン
                      Row(
                        children: [
                          _buildToggleButton(
                            label: 'お気に入り',
                            icon: game.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            isActive: game.isFavorite,
                            activeColor: Colors.red,
                            onPressed: () {
                              gameProvider.toggleFavorite(game.id);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildToggleButton(
                            label: 'フィルター',
                            icon: game.isSelected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            isActive: game.isSelected,
                            activeColor: Colors.blue,
                            onPressed: () {
                              gameProvider.toggleGameSelection(game.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ゲーム説明（もしあれば）
            if (game.description != null && game.description!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ゲーム説明',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    game.description!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            
            const SizedBox(height: 16),
            // アクションボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.public,
                  label: '公式サイト',
                  onPressed: () {
                    _launchURL(game.officialUrl ?? 'https://example.com');
                  },
                ),
                _buildActionButton(
                  icon: Icons.play_arrow,
                  label: 'アプリを開く',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('近日実装予定の機能です')),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.refresh,
                  label: 'データ更新',
                  onPressed: () {
                    _loadGameEvents();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('イベント情報を更新しています...')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      icon: Icon(
        icon,
        color: isActive ? activeColor : Colors.grey,
        size: 20,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isActive ? activeColor : Colors.grey,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isActive ? activeColor : Colors.grey,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEventsSection() {
    if (_isLoadingEvents) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_gameEvents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('このゲームのイベントはありません'),
        ),
      );
    }

    // イベントを日付でソート（現在進行中 → 近日開始 → 終了したイベント）
    final now = DateTime.now();
    final activeEvents = _gameEvents
        .where((e) => e.startDate.isBefore(now) && e.endDate.isAfter(now))
        .toList();
    final upcomingEvents = _gameEvents
        .where((e) => e.startDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final pastEvents = _gameEvents
        .where((e) => e.endDate.isBefore(now))
        .toList()
      ..sort((a, b) => b.endDate.compareTo(a.endDate)); // 新しい順

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'イベント',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        if (activeEvents.isNotEmpty) ...[
          _buildEventCategory('開催中のイベント', activeEvents),
        ],
        
        if (upcomingEvents.isNotEmpty) ...[
          _buildEventCategory('近日開始のイベント', upcomingEvents),
        ],
        
        if (pastEvents.isNotEmpty) ...[
          _buildEventCategory('終了したイベント', pastEvents.take(5).toList()),
        ],
      ],
    );
  }

  Widget _buildEventCategory(String title, List<Event> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...events.map((event) => _buildEventCard(event)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEventCard(Event event) {
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
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
}