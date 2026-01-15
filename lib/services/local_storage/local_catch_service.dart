import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalCatchService {
  static const String _keyCatches = 'local_catches';
  static const String _keyPendingSync = 'pending_sync_catches';

  // Save catch to local
  static Future<void> saveCatch(Map<String, dynamic> catchData) async {
    final prefs = await SharedPreferences.getInstance();
    
    List<String> catches = prefs.getStringList(_keyCatches) ?? [];
    catches.add(jsonEncode(catchData));
    
    await prefs.setStringList(_keyCatches, catches);
  }

  // Get all catches
  static Future<List<Map<String, dynamic>>> getAllCatches() async {
    final prefs = await SharedPreferences.getInstance();
    final catches = prefs.getStringList(_keyCatches) ?? [];
    
    return catches.map((catch_) {
      return jsonDecode(catch_) as Map<String, dynamic>;
    }).toList();
  }

  // Get catches by user
  static Future<List<Map<String, dynamic>>> getCatchesByUser(String userId) async {
    final catches = await getAllCatches();
    return catches.where((catch_) => catch_['userId'] == userId).toList();
  }

  // Add to pending sync
  static Future<void> addToPendingSync(Map<String, dynamic> catchData) async {
    final prefs = await SharedPreferences.getInstance();
    
    List<String> pending = prefs.getStringList(_keyPendingSync) ?? [];
    pending.add(jsonEncode(catchData));
    
    await prefs.setStringList(_keyPendingSync, pending);
  }

  // Get pending sync
  static Future<List<Map<String, dynamic>>> getPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_keyPendingSync) ?? [];
    
    return pending.map((catch_) {
      return jsonDecode(catch_) as Map<String, dynamic>;
    }).toList();
  }

  // Clear pending sync
  static Future<void> clearPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPendingSync);
  }

  // Clear all catches
  static Future<void> clearAllCatches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCatches);
  }
}
