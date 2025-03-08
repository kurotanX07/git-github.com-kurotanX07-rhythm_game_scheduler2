import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_game_scheduler/providers/settings_provider.dart';
import 'package:rhythm_game_scheduler/providers/game_provider.dart';
import 'package:rhythm_game_scheduler/services/ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rhythm_game_scheduler/screens/game_list_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AdService _adService = AdService();
  bool _isPremium = false;
  
  @override
  void initState() {
    super.initState();
    // プレミアム状態の取得
    _checkPremiumStatus();
  }
  
  // プレミアム状態をチェック
  Future<void> _checkPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPremium = prefs.getBool('is_premium') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<SettingsProvider, GameProvider>(
        builder: (context, settingsProvider, gameProvider, child) {
          return ListView(
            children: [
              _buildSectionHeader('ゲーム設定'),
              
              // ゲーム一覧へのリンク
              ListTile(
                leading: const Icon(Icons.gamepad),
                title: const Text('ゲーム一覧'),
                subtitle: const Text('ゲーム情報の閲覧とお気に入り設定'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GameListScreen(),
                    ),
                  );
                },
              ),
              
              // お気に入りをフィルターとして使用
              SwitchListTile(
                title: const Text('お気に入りをフィルターとして使用'),
                subtitle: const Text('お気に入りに追加したゲームのイベントだけを表示します'),
                value: gameProvider.favoritesAsFilter,
                onChanged: (value) {
                  gameProvider.toggleFavoritesAsFilter();
                },
              ),
              
              const Divider(),
              
              _buildSectionHeader('表示設定'),
              
              // ダークモード設定
              SwitchListTile(
                title: const Text('ダークモード'),
                subtitle: const Text('ダークテーマを使用します'),
                value: settingsProvider.darkModeEnabled,
                onChanged: (value) {
                  settingsProvider.setDarkModeEnabled(value);
                },
              ),
              
              const Divider(),
              
              _buildSectionHeader('通知設定'),
              
              // 通知の有効/無効
              SwitchListTile(
                title: const Text('通知'),
                subtitle: const Text('イベントの通知を受け取ります'),
                value: settingsProvider.notificationsEnabled,
                onChanged: (value) {
                  settingsProvider.setNotificationsEnabled(value);
                },
              ),
              
              // 通知のリードタイム設定
              if (settingsProvider.notificationsEnabled)
                ListTile(
                  title: const Text('イベント開始通知時間'),
                  subtitle: Text('イベント開始の${settingsProvider.notificationLeadTime}分前に通知'),
                  trailing: DropdownButton<int>(
                    value: settingsProvider.notificationLeadTime,
                    items: const [
                      DropdownMenuItem(value: 15, child: Text('15分前')),
                      DropdownMenuItem(value: 30, child: Text('30分前')),
                      DropdownMenuItem(value: 60, child: Text('1時間前')),
                      DropdownMenuItem(value: 120, child: Text('2時間前')),
                      DropdownMenuItem(value: 360, child: Text('6時間前')),
                      DropdownMenuItem(value: 720, child: Text('12時間前')),
                      DropdownMenuItem(value: 1440, child: Text('24時間前')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        settingsProvider.setNotificationLeadTime(value);
                      }
                    },
                  ),
                ),
              
              const Divider(),
              
              _buildSectionHeader('収益化設定'),
              
              // プレミアム（広告非表示）設定
              SwitchListTile(
                title: const Text('プレミアムモード'),
                subtitle: const Text('広告を表示しません（テスト用）'),
                value: _isPremium,
                onChanged: (value) async {
                  // 実際のアプリでは課金処理を行う
                  // ここではテスト用に簡易的な実装
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('is_premium', value);
                  
                  // 広告表示状態を更新
                  await _adService.setAdsEnabled(!value);
                  
                  setState(() {
                    _isPremium = value;
                  });
                  
                  // トースト表示
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value 
                        ? 'プレミアムモードを有効化しました。広告は表示されません。' 
                        : '通常モードに戻りました。広告が表示されます。'
                      ),
                    ),
                  );
                },
              ),
              
              // プレミアム購入ボタン（実際のアプリではここでIn-App Purchase処理を行う）
              if (!_isPremium)
                ListTile(
                  title: const Text('プレミアムプランを購入'),
                  subtitle: const Text('月額300円で広告なしでご利用いただけます'),
                  trailing: const Icon(Icons.monetization_on),
                  onTap: () {
                    // 課金画面を表示（今回はモックとして簡易的なダイアログを表示）
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('プレミアムプラン'),
                        content: const Text('実際のアプリではここで課金処理を行います。\n月額300円で広告が表示されなくなります。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('キャンセル'),
                          ),
                          TextButton(
                            onPressed: () async {
                              // 課金成功とみなして処理
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('is_premium', true);
                              
                              // 広告表示状態を更新
                              await _adService.setAdsEnabled(false);
                              
                              setState(() {
                                _isPremium = true;
                              });
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('購入が完了しました。広告は表示されません。'),
                                  ),
                                );
                              }
                            },
                            child: const Text('購入する'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              
              const Divider(),
              
              _buildSectionHeader('このアプリについて'),
              
              // アプリ情報
              ListTile(
                title: const Text('バージョン'),
                subtitle: const Text('1.0.0'),
              ),
              
              ListTile(
                title: const Text('開発者'),
                subtitle: const Text('リズムゲームスケジューラーチーム'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }
}