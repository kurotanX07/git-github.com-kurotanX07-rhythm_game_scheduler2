// lib/services/improved_firestore_service.dart
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rhythm_game_scheduler/models/event.dart';
import 'package:rhythm_game_scheduler/models/game.dart';

// エラー識別のための列挙型（トップレベルに移動）
enum FirestoreErrorType {
  network,
  permission,
  notFound,
  serverError,
  unknown
}

// カスタムエラークラス（トップレベルに移動）
class FirestoreServiceException implements Exception {
  final String message;
  final FirestoreErrorType type;
  final dynamic originalError;
  
  FirestoreServiceException(this.message, this.type, [this.originalError]);
  
  @override
  String toString() => 'FirestoreServiceException: $message';
}

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

  // エラー判定ヘルパーメソッド
  FirestoreErrorType _getErrorType(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return FirestoreErrorType.permission;
        case 'unavailable':
        case 'network-request-failed':
          return FirestoreErrorType.network;
        case 'not-found':
          return FirestoreErrorType.notFound;
        case 'internal':
        case 'data-loss':
          return FirestoreErrorType.serverError;
        default:
          return FirestoreErrorType.unknown;
      }
    } else if (error is SocketException || error is TimeoutException) {
      return FirestoreErrorType.network;
    }
    return FirestoreErrorType.unknown;
  }

  // エラーメッセージの生成
  String _getErrorMessage(FirestoreErrorType type) {
    switch (type) {
      case FirestoreErrorType.network:
        return 'ネットワーク接続に問題があります。接続を確認して再試行してください。';
      case FirestoreErrorType.permission:
        return '要求された操作を行う権限がありません。';
      case FirestoreErrorType.notFound:
        return '要求されたデータが見つかりませんでした。';
      case FirestoreErrorType.serverError:
        return 'サーバーエラーが発生しました。しばらく経ってから再試行してください。';
      case FirestoreErrorType.unknown:
      default:
        return 'エラーが発生しました。しばらく経ってから再試行してください。';
    }
  }

  // リトライ機能付きのFirestore操作
  Future<T> _executeWithRetry<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        final errorType = _getErrorType(e);
        
        // ネットワークエラーの場合のみリトライ
        if (errorType == FirestoreErrorType.network && attempts < maxRetries) {
          // 指数バックオフでリトライ（0.5秒、1秒、2秒...）
          await Future.delayed(Duration(milliseconds: 500 * (1 << attempts)));
          continue;
        }
        
        // それ以外のエラーまたはリトライ回数超過
        final message = _getErrorMessage(errorType);
        throw FirestoreServiceException(message, errorType, e);
      }
    }
    
    // コンパイルエラー回避のため（実際には到達しない）
    throw FirestoreServiceException(
      '最大リトライ回数を超過しました', 
      FirestoreErrorType.network
    );
  }

  // イベント一覧を取得するメソッド（改良版）
  Future<List<Event>> getEvents() async {
    debugPrint('Attempting to fetch events from Firestore');
    
    return _executeWithRetry(() async {
      // アクティブと今後のイベントを優先して取得
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // 終了していないイベント（現在進行中と未来のイベント）をまず取得
      final activeSnapshot = await _firestore.collection('events')
          .where('endDate', isGreaterThan: now)
          .orderBy('endDate')  // 終了日でソート
          .get();
      
      debugPrint('Firestore active events response: ${activeSnapshot.docs.length} documents');
      
      // 過去のイベントも取得（直近10件）
      final pastSnapshot = await _firestore.collection('events')
          .where('endDate', isLessThanOrEqualTo: now)
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
    });
  }

  // ゲーム情報を取得するメソッド（改良版）
  Future<List<Game>> getGames() async {
    debugPrint('Attempting to fetch games from Firestore');
    
    return _executeWithRetry(() async {
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
    });
  }

  // 特定のゲームのイベントを取得するメソッド（改良版）
  Future<List<Event>> getEventsByGame(String gameId) async {
    debugPrint('Fetching events for game: $gameId');
    
    return _executeWithRetry(() async {
      if (gameId.isEmpty) {
        throw FirestoreServiceException(
          'ゲームIDが指定されていません',
          FirestoreErrorType.unknown
        );
      }
      
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
    });
  }

  // 推奨イベントを取得するメソッド（改良版）
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
        try {
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
        } catch (e) {
          // 個別のイベント取得エラーは処理を継続（残りのイベントを表示するため）
          debugPrint('Error fetching featured event $id: $e');
        }
      }
      
      return events;
    } catch (e) {
      final errorType = _getErrorType(e);
      final message = _getErrorMessage(errorType);
      throw FirestoreServiceException(message, errorType, e);
    }
  }

  // アプリ設定を取得するメソッド（改良版）
  Future<Map<String, dynamic>> getAppSettings() async {
    return _executeWithRetry(() async {
      final doc = await _firestore.collection('settings').doc('appSettings').get();
      
      if (!doc.exists) {
        return {}; // 設定が存在しない場合は空のマップを返す
      }
      
      return doc.data() ?? {};
    });
  }

  // Timestamp型をDateTime型に変換（null安全対応）
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is int) {
      // ミリ秒タイムスタンプの場合
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
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