import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class LocalProfileService {
  static const String _keyProfilePicture = 'profile_picture_path';

  // Clear profile picture cache
  static Future<void> clearProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get all profile picture keys and delete files
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyProfilePicture));
    for (final key in keys) {
      final path = prefs.getString(key);
      if (path != null) {
        final file = File(path);
        if (file.existsSync()) {
          try {
            await file.delete();
          } catch (e) {
            print('Error deleting profile picture: $e');
          }
        }
      }
      await prefs.remove(key);
    }
  }
}
