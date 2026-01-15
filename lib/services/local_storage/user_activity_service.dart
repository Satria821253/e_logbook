import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserActivityService {
  static const String _keyUserActivities = 'user_activities';
  static const String _keyLastLogin = 'last_login';
  static const String _keyLastSync = 'last_sync';

  // Save user activity
  static Future<void> saveActivity({
    required String userId,
    required String activityType,
    required String description,
    Map<String, dynamic>? data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final activity = {
      'userId': userId,
      'type': activityType,
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    };
    
    List<String> activities = prefs.getStringList(_keyUserActivities) ?? [];
    activities.add(jsonEncode(activity));
    
    // Keep only last 100 activities
    if (activities.length > 100) {
      activities = activities.sublist(activities.length - 100);
    }
    
    await prefs.setStringList(_keyUserActivities, activities);
  }

  // Get all activities
  static Future<List<Map<String, dynamic>>> getActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final activities = prefs.getStringList(_keyUserActivities) ?? [];
    
    return activities.map((activity) {
      return jsonDecode(activity) as Map<String, dynamic>;
    }).toList();
  }

  // Get activities by user
  static Future<List<Map<String, dynamic>>> getActivitiesByUser(String userId) async {
    final activities = await getActivities();
    return activities.where((activity) => activity['userId'] == userId).toList();
  }

  // Save last login
  static Future<void> saveLastLogin(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastLogin, jsonEncode({
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  // Get last login
  static Future<Map<String, dynamic>?> getLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getString(_keyLastLogin);
    if (lastLogin != null) {
      return jsonDecode(lastLogin) as Map<String, dynamic>;
    }
    return null;
  }

  // Save last sync time
  static Future<void> saveLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSync, DateTime.now().toIso8601String());
  }

  // Get last sync time
  static Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_keyLastSync);
    if (lastSync != null) {
      return DateTime.parse(lastSync);
    }
    return null;
  }

  // Clear all activities
  static Future<void> clearActivities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserActivities);
  }
}
