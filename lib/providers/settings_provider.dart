import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  int _notificationLeadTime = 30; // 30分前に通知

  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  int get notificationLeadTime => _notificationLeadTime;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
    _notificationLeadTime = prefs.getInt('notification_lead_time') ?? 30;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    notifyListeners();
  }

  Future<void> setDarkModeEnabled(bool value) async {
    _darkModeEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode_enabled', value);
    notifyListeners();
  }

  Future<void> setNotificationLeadTime(int minutes) async {
    _notificationLeadTime = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_lead_time', minutes);
    notifyListeners();
  }
}