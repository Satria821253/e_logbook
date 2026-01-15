import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserService {
  static const String _userKey = 'user_data';

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      if (userData != null) {
        final json = jsonDecode(userData);
        return UserModel.fromJson(json);
      }
      return null;
    } catch (e) {
      // Clear corrupted data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      return null;
    }
  }

  static Future<void> updateVesselInfo({
    required String vesselName,
    required String vesselNumber,
    required String captainName,
    required int crewCount,
  }) async {
    final user = await getUser();
    if (user != null) {
      final updatedUser = UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        token: user.token,
        vesselName: vesselName,
        vesselNumber: vesselNumber,
        captainName: captainName,
        crewCount: crewCount,
      );
      await saveUser(updatedUser);
    }
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}