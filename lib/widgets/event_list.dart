// lib/widgets/event_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_game_scheduler/models/event.dart';
import 'package:rhythm_game_scheduler/providers/event_provider.dart';
import 'package:rhythm_game_scheduler/providers/game_provider.dart';
import 'package:rhythm_game_scheduler/widgets/event_card.dart';

class EventList extends StatelessWidget {
  final List<Event> events;

  const EventList({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    
    // ローディング中の表示
    if (eventProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('イベント情報を読み込み中...'),
          ],
        ),
      );
    }
    
    // エラー発生時の表示
    if (eventProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(eventProvider.error ?? ''),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 再読み込みを試みる
                eventProvider.fetchEvents();
              },
              child: Text('再試行'),
            ),
          ],
        ),
      );
    }
    
    // お気に入りモードかどうかを確認し、適切なメッセージを表示
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              gameProvider.favoritesAsFilter 
                  ? Icons.favorite_border 
                  : Icons.event_busy,
              size: 48, 
              color: gameProvider.favoritesAsFilter ? Colors.red : Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              gameProvider.favoritesAsFilter
                  ? 'お気に入りのゲームにイベントがありません'
                  : '選択したゲームにイベントがありません',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (gameProvider.favoritesAsFilter) ...[
              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.games),
                label: Text('ゲーム一覧でお気に入り設定'),
                onPressed: () {
                  Navigator.pushNamed(context, '/games');
                },
              ),
            ],
          ],
        ),
      );
    }

    // 日付でイベントをソート（現在進行中 → 近日開始 → 終了したイベント）
    final now = DateTime.now();
    final activeEvents = events.where((e) => 
      e.startDate.isBefore(now) && e.endDate.isAfter(now)).toList();
    final upcomingEvents = events.where((e) => 
      e.startDate.isAfter(now)).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final pastEvents = events.where((e) => 
      e.endDate.isBefore(now)).toList()
      ..sort((a, b) => b.endDate.compareTo(a.endDate)); // 新しい順

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<EventProvider>(context, listen: false).fetchEvents();
      },
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          if (activeEvents.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text(
                '開催中のイベント',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...activeEvents.map((event) => EventCard(event: event)),
          ],
          
          if (upcomingEvents.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text(
                '近日開始のイベント',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...upcomingEvents.map((event) => EventCard(event: event)),
          ],
          
          if (pastEvents.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text(
                '終了したイベント',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...pastEvents.take(5).map((event) => EventCard(event: event)),
            
            if (pastEvents.length > 5)
              Center(
                child: TextButton(
                  onPressed: () {
                    // 過去のイベントをもっと表示するための処理（実装予定）
                  },
                  child: const Text('もっと見る'),
                ),
              ),
          ],
          
          // イベントが0件の場合でもプルリフレッシュできるように余白を追加
          if (activeEvents.isEmpty && upcomingEvents.isEmpty && pastEvents.isEmpty)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100),
                const Text('登録されているイベントがありません'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('更新'),
                  onPressed: () {
                    eventProvider.fetchEvents();
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
        ],
      ),
    );
  }
}