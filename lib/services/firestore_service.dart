// lib/services/firestore_service.dart
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

  // イベント一覧を取得するメソッド（改良版）
  Future<List<Event>> getEvents() async {
    try {
      debugPrint('Attempting to fetch events from Firestore');
      
      // アクティブと今後のイベントを優先して取得
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // 終了していないイベント（現在進行中と未来のイベント）をまず取得
      final activeSnapshot = await _firestore.collection('events')
          .where('endDate', isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(now))
          .orderBy('endDate')  // 終了日でソート
          .get();
      
      debugPrint('Firestore active events response: ${activeSnapshot.docs.length} documents');
      
      // 過去のイベントも取得（直近10件）
      final pastSnapshot = await _firestore.collection('events')
          .where('endDate', isLessThanOrEqualTo: Timestamp.fromMillisecondsSinceEpoch(now))
          .orderBy('endDate', descending: true)  // 終了日の新しい順
          .limit(10)
          .get();
      
      debugPrint('Firestore past events response: ${pastSnapshot.docs.length} documents');
      
      // 両方のスナップショットをマージ
      final allDocs = [...activeSnapshot.docs, ...pastSnapshot.docs];
      
      if (allDocs.isEmpty) {
        debugPrint('No events found in Firestore');
        return [];
      }
      
      final events = allDocs.map((doc) {
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
      
      debugPrint('Successfully parsed ${events.length} events from Firestore');
      return events;
    } catch (e) {
      debugPrint('Error fetching events from Firestore: $e');
      return []; // エラー時は空リストを返す
    }
  }

  // ゲーム情報を取得するメソッド
  Future<List<Game>> getGames() async {
    try {
      debugPrint('Attempting to fetch games from Firestore');
      final snapshot = await _firestore.collection('games').get();
      
      debugPrint('Firestore games response: ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('No games found in Firestore');
        return [];
      }
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Game(
          id: doc.id,
          name: data['name'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          developer: data['developer'] ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching games from Firestore: $e');
      return []; // エラー時は空リストを返す
    }
  }

  // 特定のゲームのイベントを取得するメソッド
  Future<List<Event>> getEventsByGame(String gameId) async {
    try {
      debugPrint('Fetching events for game: $gameId');
      final snapshot = await _firestore.collection('events')
          .where('gameId', isEqualTo: gameId)
          .orderBy('startDate', descending: true)
          .get();
      
      debugPrint('Found ${snapshot.docs.length} events for game $gameId');
      
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
      debugPrint('Error fetching events for game $gameId: $e');
      return [];
    }
  }

  // アプリ設定を取得するメソッド
  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('appSettings').get();
      
      if (!doc.exists) {
        return {}; // 設定が存在しない場合は空のマップを返す
      }
      
      return doc.data() ?? {};
    } catch (e) {
      debugPrint('Error fetching app settings: $e');
      return {};
    }
  }

  // 推奨イベントを取得するメソッド
  Future<List<Event>> getFeaturedEvents() async {
    try {
      // 設定からフィーチャーイベントのIDリストを取得
      final settings = await getAppSettings();
      final featuredIds = List<String>.from(settings['featuredEvents'] ?? []);
      
      if (featuredIds.isEmpty) {
        return [];
      }
      
      // IDに一致するイベントを取得
      final events = <Event>[];
      
      for (final id in featuredIds) {
        final doc = await _firestore.collection('events').doc(id).get();
        if (doc.exists) {
          final data = doc.data()!;
          events.add(Event(
            id: doc.id,
            gameId: data['gameId'] ?? '',
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            startDate: _parseTimestamp(data['startDate']),
            endDate: _parseTimestamp(data['endDate']),
            type: _parseEventType(data['type'] ?? 'other'),
            imageUrl: data['imageUrl'] ?? '',
          ));
        }
      }
      
      return events;
    } catch (e) {
      debugPrint('Error fetching featured events: $e');
      return [];
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