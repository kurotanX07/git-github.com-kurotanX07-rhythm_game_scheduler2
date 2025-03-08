// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_game_scheduler/models/event.dart';
import 'package:rhythm_game_scheduler/providers/improved_event_provider.dart';
import 'package:rhythm_game_scheduler/providers/game_provider.dart';
import 'package:rhythm_game_scheduler/screens/calendar_screen.dart';
import 'package:rhythm_game_scheduler/screens/settings_screen.dart';
import 'package:rhythm_game_scheduler/services/improved_ad_service.dart';
import 'package:rhythm_game_scheduler/widgets/event_list.dart';
import 'package:rhythm_game_scheduler/widgets/featured_event_card.dart';
import 'package:rhythm_game_scheduler/widgets/game_filter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rhythm_game_scheduler/utils/error_handler.dart';

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
  
  // ネットワークエラー状態
  bool _hasNetworkError = false;

  @override
  void initState() {
    super.initState();
    
    // 広告サービスの初期化確認
    if (!_adService.isInitialized) {
      _initializeAdService();
    } else {
      // インタースティシャル広告をあらかじめロードしておく
      _adService.loadInterstitialAd();
    }
    
    // 接続状態のチェック
    _checkConnectivity();
  }
  
  Future<void> _initializeAdService() async {
    try {
      await _adService.initialize();
      // インタースティシャル広告をあらかじめロードしておく
      _adService.loadInterstitialAd();
    } catch (e, stack) {
      debugPrint('Failed to initialize ad service: $e');
      AppErrorHandler().reportError(e, stack);
    }
  }
  
  Future<void> _checkConnectivity() async {
    try {
      final isNetworkAvailable = await AppErrorHandler().isNetworkAvailable();
      setState(() {
        _hasNetworkError = !isNetworkAvailable;
      });
      
      if (!isNetworkAvailable) {
        // UI上でネットワークエラーを表示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ネットワーク接続がありません。オフラインモードで動作します。'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<EventProvider>(
          builder: (context, eventProvider, _) {
            return eventProvider.isSearching
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
                : Text(_tabTitles[_selectedIndex]);
          },
        ),
        actions: _buildAppBarActions(),
      ),
      body: Column(
        children: [
          // ネットワークエラー表示
          if (_hasNetworkError)
            Container(
              width: double.infinity,
              color: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'オフラインモードで表示中。最新データを取得するには、ネットワーク接続を確認してください。',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          
          // メインコンテンツ
          Expanded(
            child: _buildBody(),
          ),
          
          // バナー広告を表示
          Consumer<EventProvider>(
            builder: (context, eventProvider, _) {
              // 検索中は広告を表示しない
              if (eventProvider.isSearching) {
                return const SizedBox.shrink();
              }
              
              if (_adService.isBannerAdLoaded && _adService.bannerAd != null) {
                return Container(
                  alignment: Alignment.center,
                  width: _adService.bannerAd!.size.width.toDouble(),
                  height: _adService.bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _adService.bannerAd!),
                );
              }
              
              return const SizedBox.shrink();
            },
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

  List<Widget> _buildAppBarActions() {
    return [
      // 検索ボタン
      Consumer<EventProvider>(
        builder: (context, eventProvider, _) {
          return IconButton(
            icon: Icon(eventProvider.isSearching ? Icons.close : Icons.search),
            onPressed: () {
              eventProvider.toggleSearch();
              if (!eventProvider.isSearching) {
                _searchController.clear();
              }
            },
          );
        },
      ),
      // 更新ボタン（検索中以外とイベント一覧タブのみ表示）
      Consumer<EventProvider>(
        builder: (context, eventProvider, _) {
          if (_selectedIndex == 0 && !eventProvider.isSearching) {
            return IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _refreshData(eventProvider),
              tooltip: 'データを更新',
            );
          }
          return const SizedBox.shrink();
        },
      ),
    ];
  }

  Future<void> _refreshData(EventProvider eventProvider) async {
    // ネットワーク接続を確認
    final isConnected = await AppErrorHandler().isNetworkAvailable();
    
    if (!isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ネットワーク接続がありません。接続を確認して再試行してください。'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      setState(() {
        _hasNetworkError = true;
      });
      return;
    }
    
    setState(() {
      _hasNetworkError = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('データを更新中...'))
      );
    }
    
    try {
      // ゲームとイベントのデータを更新
      await context.read<GameProvider>().fetchGames();
      await eventProvider.refreshAllData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('データを更新しました'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      // データ更新時にインタースティシャル広告を表示（確率で表示）
      if (DateTime.now().millisecond % 10 < 3) { // 約30%の確率
        _adService.showInterstitialAd();
      }
    } catch (e, stack) {
      debugPrint('Error refreshing data: $e');
      AppErrorHandler().reportError(e, stack);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('データの更新中にエラーが発生しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      
      // 検索モードを解除（タブ切り替え時）
      if (context.read<EventProvider>().isSearching) {
        context.read<EventProvider>().toggleSearch();
        _searchController.clear();
      }
    });
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildEventsTab();
      case 1:
        return const CalendarScreen();
      case 2:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEventsTab() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
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
              _buildFeaturedEventsSection(eventProvider),
              
              // ゲームフィルター
              const GameFilter(),
              
              // イベントリスト
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => eventProvider.fetchEvents(isRefresh: true),
                  child: EventList(events: eventProvider.filteredEvents),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  // フィーチャーイベントセクションの構築
  Widget _buildFeaturedEventsSection(EventProvider eventProvider) {
    final gameProvider = context.read<GameProvider>();
    
    // お気に入りに登録したゲームのイベントだけをフィルタリング
    final favoriteGameIds = gameProvider.favoriteGames.map((game) => game.id).toList();
    final favoriteEvents = eventProvider.featuredEvents
        .where((event) => favoriteGameIds.contains(event.gameId))
        .toList();
    
    // お気に入りゲームがない場合や、フィーチャーイベントがない場合はセクションを非表示
    if ((favoriteGameIds.isEmpty || favoriteEvents.isEmpty) && !eventProvider.isFeaturedLoading) {
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
              'お気に入りゲームのイベント',
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
                : favoriteEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite_border, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text(
                              'お気に入りゲームのイベントがありません',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '設定からゲームをお気に入り登録してください',
                              style: TextStyle(
                                color: Colors.grey, 
                                fontSize: 12
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: favoriteEvents.length,
                        itemBuilder: (context, index) {
                          final event = favoriteEvents[index];
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