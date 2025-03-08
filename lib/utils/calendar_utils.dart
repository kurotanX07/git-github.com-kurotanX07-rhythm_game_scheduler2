import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:rhythm_game_scheduler/models/event.dart' as app_event;

class CalendarUtils {
  // リズムゲームイベントをデバイスカレンダーイベントに変換
  static Event convertToCalendarEvent(app_event.Event gameEvent) {
    // イベントの開始と終了時刻
    final startDate = gameEvent.startDate;
    final endDate = gameEvent.endDate;
    
    // イベントタイプに基づいて色を設定
    String title;
    switch (gameEvent.type) {
      case app_event.EventType.ranking:
        title = '【ランキング】${gameEvent.title}';
        break;
      case app_event.EventType.live:
        title = '【ライブ】${gameEvent.title}';
        break;
      case app_event.EventType.gacha:
        title = '【ガチャ】${gameEvent.title}';
        break;
      default:
        title = gameEvent.title;
    }
    
    return Event(
      title: title,
      description: gameEvent.description,
      location: '', // 特定の場所はないのでから文字列
      startDate: startDate,
      endDate: endDate,
      allDay: false,
      iosParams: const IOSParams(
        reminder: Duration(hours: 1), // 1時間前に通知
      ),
      androidParams: const AndroidParams(
        emailInvites: [], // メール招待なし
      ),
    );
  }
  
  // カレンダーにイベントを追加
  static Future<bool> addEventToCalendar(app_event.Event gameEvent) async {
    final calendarEvent = convertToCalendarEvent(gameEvent);
    return Add2Calendar.addEvent2Cal(calendarEvent);
  }
}