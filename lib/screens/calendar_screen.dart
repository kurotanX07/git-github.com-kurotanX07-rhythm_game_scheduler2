import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm_game_scheduler/models/event.dart';
import 'package:rhythm_game_scheduler/models/game.dart';
import 'package:rhythm_game_scheduler/providers/event_provider.dart';
import 'package:rhythm_game_scheduler/providers/game_provider.dart';
import 'package:rhythm_game_scheduler/screens/event_detail_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _eventsByDay = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ゲームフィルターは表示しない（設定画面に移動）
          
          // カレンダー
          Consumer<EventProvider>(
            builder: (context, eventProvider, child) {
              final events = eventProvider.filteredEvents;
              
              // イベントを日付別にグループ化
              _eventsByDay = _groupEventsByDay(events);
              
              return TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: (day) {
                  // 各日のイベントを取得
                  return _getEventsForDay(day);
                },
                calendarStyle: CalendarStyle(
                  markersMaxCount: 3,
                  markerDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;
                    
                    // イベントの種類別に色分け
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        padding: const EdgeInsets.all(1.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: events.take(3).map((event) {
                            Color dotColor;
                            switch ((event as Event).type) {
                              case EventType.ranking:
                                dotColor = Colors.red;
                                break;
                              case EventType.live:
                                dotColor = Colors.green;
                                break;
                              case EventType.gacha:
                                dotColor = Colors.purple;
                                break;
                              default:
                                dotColor = Colors.blue;
                                break;
                            }
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.0),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dotColor,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          
          // 選択した日のイベント一覧
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    if (_selectedDay == null) {
      return const Center(
        child: Text('日付を選択してください'),
      );
    }

    final events = _getEventsForDay(_selectedDay!);
    
    if (events.isEmpty) {
      return Center(
        child: Text('${DateFormat('yyyy/MM/dd').format(_selectedDay!)} のイベントはありません'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '${DateFormat('yyyy/MM/dd').format(_selectedDay!)} のイベント',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final gameProvider = context.read<GameProvider>();
              final game = gameProvider.games.firstWhere(
                (g) => g.id == event.gameId,
                orElse: () => Game(
                  id: 'unknown',
                  name: '不明なゲーム',
                  imageUrl: '',
                  developer: '',
                ),
              );
                
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
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: game.imageUrl.isNotEmpty
                        ? NetworkImage(game.imageUrl)
                        : null,
                    child: game.imageUrl.isEmpty ? Text(game.name[0]) : null,
                  ),
                  title: Text(event.title),
                  subtitle: Text(game.name),
                  trailing: Container(
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailScreen(event: event),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 日付ごとにイベントをグループ化
  Map<DateTime, List<Event>> _groupEventsByDay(List<Event> events) {
    final Map<DateTime, List<Event>> eventsByDay = {};
    
    for (final event in events) {
      // イベント期間内の各日に対してイベントを追加
      DateTime currentDay = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      
      final endDay = DateTime(
        event.endDate.year,
        event.endDate.month,
        event.endDate.day,
      );
      
      while (currentDay.isBefore(endDay) || currentDay.isAtSameMomentAs(endDay)) {
        if (eventsByDay[currentDay] == null) {
          eventsByDay[currentDay] = [];
        }
        
        eventsByDay[currentDay]!.add(event);
        currentDay = currentDay.add(const Duration(days: 1));
      }
    }
    
    return eventsByDay;
  }

  // 特定の日のイベントを取得
  List<Event> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _eventsByDay[normalizedDay] ?? [];
  }
}