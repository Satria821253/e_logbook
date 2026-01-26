import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _registrationReadKey = 'registration_read_';
  static const String _systemReadKey = 'system_read_';

  // Mark registration notification as read
  static Future<void> markRegistrationAsRead(String registrationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_registrationReadKey$registrationId', true);
  }

  // Mark system notification as read
  static Future<void> markSystemAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_systemReadKey$notificationId', true);
  }

  // Check if registration notification is read
  static Future<bool> isRegistrationRead(String registrationId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_registrationReadKey$registrationId') ?? false;
  }

  // Check if system notification is read
  static Future<bool> isSystemRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_systemReadKey$notificationId') ?? false;
  }

  // Get unread registration count
  static Future<int> getUnreadRegistrationCount(List<String> registrationIds) async {
    int count = 0;
    for (String id in registrationIds) {
      if (!(await isRegistrationRead(id))) {
        count++;
      }
    }
    return count;
  }

  // Get unread system count
  static Future<int> getUnreadSystemCount(List<String> systemIds) async {
    int count = 0;
    for (String id in systemIds) {
      if (!(await isSystemRead(id))) {
        count++;
      }
    }
    return count;
  }
}