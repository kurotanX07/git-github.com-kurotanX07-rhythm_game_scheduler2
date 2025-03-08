import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rhythm_game_scheduler/models/event.dart';
import 'package:rhythm_game_scheduler/models/game.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  
  FirestoreService() : _firestore = FirebaseFirestore.instance {
    // オフラインキャッシュを有効化
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('Firestore offline cache enabled');
    } catch (e) {
      debugPrint('Failed to enable Firestore offline cache: $e');
    }
  }

  // イベント一覧を取得するメソッド
  Future<List<Event>> getEvents() async {
    try {
      debugPrint('Attempting to fetch events from Firestore');
      final snapshot = await _firestore.collection('events').get();
      
      debugPrint('Firestore response: ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('No events found in Firestore');
        return [];
      }
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Event(
          id: doc.id,
          gameId: data['gameId'] ?? '',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          startDate: _parseTimestamp(data['startDate']),
          endDate: _parseTimestamp(data['endDate']),
          type: _parseEventType(data['type'] ?? 'other'),
          imageUrl: data['imageUrl'] ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching events from Firestore: $e');
      return []; // エラー時は空リストを返す
    }
  }
  
  // サンプルデータをFirestoreに追加
  Future<void> seedSampleData() async {
    try {
      // イベントデータの追加
      final eventsRef = _firestore.collection('events');
      final eventSnapshots = await eventsRef.get();
      
      // イベントデータが空の場合のみ追加
      if (eventSnapshots.docs.isEmpty) {
        debugPrint('Adding sample events to Firestore');
        final now = DateTime.now();
        
        final events = [
          {
            'gameId': 'proseka',
            'title': 'Next Frontier!イベント',
            'description': 'ランキング形式のイベントです。「Next Frontier!」をテーマにしたカードが手に入ります。',
            'startDate': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
            'endDate': Timestamp.fromDate(now.add(const Duration(days: 5))),
            'type': 'ranking',
            'imageUrl': 'https://via.placeholder.com/120x80',
          },
          {
            'gameId': 'bandori',
            'title': 'ロゼリア 新曲発表会イベント',
            'description': 'ロゼリアの新曲「PASSION」をフィーチャーしたイベントです。',
            'startDate': Timestamp.fromDate(now.add(const Duration(days: 3))),
            'endDate': Timestamp.fromDate(now.add(const Duration(days: 10))),
            'type': 'ranking',
            'imageUrl': 'https://via.placeholder.com/120x80',
          },
          {
            'gameId': 'yumeステ',
            'title': '夏休み特別キャンペーン',
            'description': '期間限定で夏をテーマにしたカードがピックアップされたガチャが登場します。',
            'startDate': Timestamp.fromDate(now.add(const Duration(days: 1))),
            'endDate': Timestamp.fromDate(now.add(const Duration(days: 14))),
            'type': 'gacha',
            'imageUrl': 'https://via.placeholder.com/120x80',
          },
          {
            'gameId': 'deresute',
            'title': 'LIVE Parade イベント',
            'description': 'アイドルの総力戦イベント。チームを編成して上位報酬を目指しましょう。',
            'startDate': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
            'endDate': Timestamp.fromDate(now.add(const Duration(days: 3))),
            'type': 'ranking',
            'imageUrl': 'https://via.placeholder.com/120x80',
          },
          {
            'gameId': 'mirishita',
            'title': '765プロ THANKS フェスティバル',
            'description': '765プロダクション全体のライブフェスティバル。レアカードをゲットするチャンス！',
            'startDate': Timestamp.fromDate(now.add(const Duration(days: 7))),
            'endDate': Timestamp.fromDate(now.add(const Duration(days: 14))),
            'type': 'live',
            'imageUrl': 'https://via.placeholder.com/120x80',
          },
        ];
        
        for (final event in events) {
          await eventsRef.add(event);
        }
        debugPrint('Sample events added to Firestore');
      } else {
        debugPrint('Firestore already has events, skipping seed');
      }
    } catch (e) {
      debugPrint('Error seeding sample data: $e');
      rethrow;
    }
  }
  
  // Timestamp型をDateTime型に変換（null安全対応）
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return DateTime.now(); // デフォルト値
  }
  
  // イベントの種類を文字列からEnum型に変換
  EventType _parseEventType(String type) {
    switch (type) {
      case 'ranking':
        return EventType.ranking;
      case 'live':
        return EventType.live;
      case 'gacha':
        return EventType.gacha;
      case 'campaign':
        return EventType.campaign;
      default:
        return EventType.other;
    }
  }
}