import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalProfileService {
  static const String _keyProfile = 'user_profile';
  static const String _keyProfilePicture = 'profile_picture_path';

  // Save profile to local
  static Future<void> saveProfile(Map<String, dynamic> profileData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(profileData));
  }

  // Get profile from local
  static Future<Map<String, dynamic>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = prefs.getString(_keyProfile);
    if (profile != null) {
      return jsonDecode(profile) as Map<String, dynamic>;
    }
    return null;
  }

  // Save profile picture locally with user-specific naming
  static Future<String?> saveProfilePictureLocally(String sourcePath, {String? userId, String? role}) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final userIdentifier = userId ?? 'default';
      final roleIdentifier = role ?? 'user';
      final fileName = 'profile_${userIdentifier}_${roleIdentifier}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localPath = '${appDir.path}/$fileName';
      
      final sourceFile = File(sourcePath);
      await sourceFile.copy(localPath);
      
      final prefs = await SharedPreferences.getInstance();
      final profilePictureKey = '${_keyProfilePicture}_${userIdentifier}_$roleIdentifier';
      await prefs.setString(profilePictureKey, localPath);
      
      // Also save with generic key for backward compatibility
      await prefs.setString(_keyProfilePicture, localPath);
      
      return localPath;
    } catch (e) {
      print('Error saving profile picture locally: $e');
      return null;
    }
  }

  // Get profile picture path with user-specific lookup
  static Future<String?> getProfilePicturePath({String? userId, String? role}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try user-specific path first
    if (userId != null && role != null) {
      final userIdentifier = userId;
      final roleIdentifier = role;
      final profilePictureKey = '${_keyProfilePicture}_${userIdentifier}_$roleIdentifier';
      final userSpecificPath = prefs.getString(profilePictureKey);
      if (userSpecificPath != null && File(userSpecificPath).existsSync()) {
        return userSpecificPath;
      }
    }
    
    // Fallback to generic path
    final genericPath = prefs.getString(_keyProfilePicture);
    if (genericPath != null && File(genericPath).existsSync()) {
      return genericPath;
    }
    
    return null;
  }

  // Clear profile and associated files
  static Future<void> clearProfile() async {
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
    
    await prefs.remove(_keyProfile);
  }

  // Update specific field
  static Future<void> updateField(String key, dynamic value) async {
    final profile = await getProfile();
    if (profile != null) {
      profile[key] = value;
      await saveProfile(profile);
    }
  }
}
