import 'package:intl/intl.dart';

enum EventType {
  ranking,
  live,
  gacha,
  campaign,
  other,
}

class Event {
  final String id;
  final String gameId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final EventType type;
  final String imageUrl;

  Event({
    required this.id,
    required this.gameId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.imageUrl = '',
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return now.isBefore(startDate);
  }

  bool get isFinished {
    final now = DateTime.now();
    return now.isAfter(endDate);
  }

  String get formattedStartDate {
    return DateFormat('yyyy/MM/dd HH:mm').format(startDate);
  }

  String get formattedEndDate {
    return DateFormat('yyyy/MM/dd HH:mm').format(endDate);
  }

  String get duration {
    final days = endDate.difference(startDate).inDays;
    return '$days日間';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameId': gameId,
      'title': title,
      'description': description,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'type': type.toString().split('.').last,
      'imageUrl': imageUrl,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      gameId: map['gameId'],
      title: map['title'],
      description: map['description'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
      type: EventType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => EventType.other,
      ),
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}