// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_game_scheduler/models/event.dart';
import 'package:rhythm_game_scheduler/providers/event_provider.dart';
import 'package:rhythm_game_scheduler/providers/game_provider.dart';
import 'package:rhythm_game_scheduler/screens/calendar_screen.dart';
import 'package:rhythm_game_scheduler/screens/settings_screen.dart';
import 'package:rhythm_game_scheduler/services/ad_service.dart';
import 'package:rhythm_game_scheduler/widgets/event_list.dart';
import 'package:rhythm_game_scheduler/widgets/featured_event_card.dart';
import 'package:rhythm_game_scheduler/widgets/game_filter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<String> _tabTitles = ['イベント一覧', 'カレンダー', '設定'];
  final TextEditingController _searchController = TextEditingController();
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    
    // ゲームフィルターが変更されたときに、イベントフィルターを更新
    Future.microtask(() {
      final gameProvider = context.read<GameProvider>();
      final eventProvider = context.read<EventProvider>();
      
      // 最初はすべてのゲームを選択
      gameProvider.selectAll();
      
      // イベントフィルター更新
      eventProvider.setSelectedGameIds(
        gameProvider.selectedGames.map((game) => game.id).toList()
      );
    });
    
    // インタースティシャル広告をあらかじめロードしておく
    _adService.loadInterstitialAd();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // タブ切り替え時の処理
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // タブ切り替え時にインタースティシャル広告を表示（確率で表示）
    if (index == 1 || index == 2) { // カレンダーや設定に移動したとき
      // 一定確率（約30%）で広告を表示
      if (DateTime.now().millisecond % 10 < 3) {
        _adService.showInterstitialAd();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: eventProvider.isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'イベントを検索...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  eventProvider.updateSearchQuery(value);
                },
              )
            : Text(_tabTitles[_selectedIndex]),
        actions: [
          // 検索ボタン
          IconButton(
            icon: Icon(eventProvider.isSearching ? Icons.close : Icons.search),
            onPressed: () {
              eventProvider.toggleSearch();
              if (!eventProvider.isSearching) {
                _searchController.clear();
              }
            },
          ),
          // 更新ボタン
          if (_selectedIndex == 0 && !eventProvider.isSearching)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('データを更新中...'))
                );
                
                // ゲームとイベントのデータを更新
                context.read<GameProvider>().fetchGames();
                eventProvider.fetchEvents();
                eventProvider.fetchFeaturedEvents();
                
                // データ更新時にインタースティシャル広告を表示（確率で表示）
                if (DateTime.now().millisecond % 10 < 3) { // 約30%の確率
                  _adService.showInterstitialAd();
                }
              },
              tooltip: 'データを更新',
            ),
        ],
      ),
      body: Column(
        children: [
          // メインコンテンツ
          Expanded(
            child: _buildBody(),
          ),
          
          // バナー広告を表示
          if (_adService.isBannerAdLoaded && _adService.bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _adService.bannerAd!.size.width.toDouble(),
              height: _adService.bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _adService.bannerAd!),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'イベント',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'カレンダー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final eventProvider = Provider.of<EventProvider>(context);
    
    switch (_selectedIndex) {
      case 0:
        if (eventProvider.isSearching && eventProvider.searchQuery.isNotEmpty) {
          // 検索結果を表示
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '検索結果: ${eventProvider.searchResults.length}件',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              Expanded(
                child: EventList(events: eventProvider.searchResults),
              ),
            ],
          );
        } else {
          // 通常のイベント一覧を表示
          return Column(
            children: [
              // フィーチャーイベントセクション
              _buildFeaturedEventsSection(),
              
              const GameFilter(),
              
              Expanded(
                child: Consumer<EventProvider>(
                  builder: (context, eventProvider, child) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        await eventProvider.fetchEvents();
                      },
                      child: EventList(events: eventProvider.filteredEvents),
                    );
                  },
                ),
              ),
            ],
          );
        }
      case 1:
        return const CalendarScreen();
      case 2:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  // フィーチャーイベントセクションの構築
  Widget _buildFeaturedEventsSection() {
    final eventProvider = Provider.of<EventProvider>(context);
    final featuredEvents = eventProvider.featuredEvents;
    
    // フィーチャーイベントがない場合は表示しない
    if (featuredEvents.isEmpty && !eventProvider.isFeaturedLoading) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              '注目のイベント',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          
          SizedBox(
            height: 180,
            child: eventProvider.isFeaturedLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: featuredEvents.length,
                    itemBuilder: (context, index) {
                      final event = featuredEvents[index];
                      return FeaturedEventCard(event: event);
                    },
                  ),
          ),
          
          const Divider(
            height: 24,
            thickness: 1,
            indent: 8,
            endIndent: 8,
          ),
        ],
      ),
    );
  }
}