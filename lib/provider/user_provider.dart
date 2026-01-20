import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userData = prefs.getString('user_data');
    
    if (token != null && userData != null) {
      final Map<String, dynamic> userMap = jsonDecode(userData);
      
      // Simpan foto lama jika ada
      final oldPhoto = _user?.profilePicture;
      
      _user = UserModel(
        id: userMap['id'],
        name: userMap['name'],
        username: userMap['username'] ?? '',
        email: userMap['email'] ?? '',
        phone: userMap['phone'] ?? '',
        address: userMap['address'],
        token: token,
        role: userMap['role'],
        profilePicture: oldPhoto, // Keep old photo while loading
      );
      
      notifyListeners();
      
      // Load profile picture from API
      await _loadProfilePictureFromAPI(token);
      
      notifyListeners();
    }
  }
  
  Future<void> _loadProfilePictureFromAPI(String token) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'http://210.79.191.17:5000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      
      print('🔄 Loading profile picture from API...');
      final response = await dio.get(
        '/api/mobile/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      print('📡 Profile API response: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final profileData = response.data['data'];
        final photoUrl = profileData['fotoUrl'];
        
        print('📸 Photo URL from API: $photoUrl');
        
        if (photoUrl != null && _user != null) {
          final fullPhotoUrl = photoUrl.startsWith('http') ? photoUrl : 'http://210.79.191.17:5000$photoUrl';
          print('📸 Full photo URL: $fullPhotoUrl');
          
          _user = UserModel(
            id: _user!.id,
            name: _user!.name,
            username: _user!.username,
            email: _user!.email,
            phone: _user!.phone,
            address: _user!.address,
            token: _user!.token,
            role: _user!.role,
            vesselName: _user!.vesselName,
            vesselNumber: _user!.vesselNumber,
            captainName: _user!.captainName,
            crewCount: _user!.crewCount,
            crewNames: _user!.crewNames,
            profilePicture: fullPhotoUrl,
          );
          print('✅ Profile picture loaded successfully');
        } else {
          print('⚠️ No photo URL in response');
        }
      }
    } catch (e) {
      print('❌ Error loading profile picture: $e');
    }
  }

  Future<void> setUser(UserModel user) async {
    _user = user;
    notifyListeners();
  }

  Future<void> updateVesselInfo({
    required String vesselName,
    required String vesselNumber,
    required String captainName,
    required int crewCount,
    List<String>? crewNames,
  }) async {
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        name: _user!.name,
        username: _user!.username,
        email: _user!.email,
        phone: _user!.phone,
        address: _user!.address,
        token: _user!.token,
        role: _user!.role,
        vesselName: vesselName,
        vesselNumber: vesselNumber,
        captainName: captainName,
        crewCount: crewCount,
        crewNames: crewNames,
      );
      notifyListeners();
    }
  }

  Future<void> updateRole(String role) async {
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        name: _user!.name,
        username: _user!.username,
        email: _user!.email,
        phone: _user!.phone,
        address: _user!.address,
        token: _user!.token,
        role: role,
        vesselName: _user!.vesselName,
        vesselNumber: _user!.vesselNumber,
        captainName: _user!.captainName,
        crewCount: _user!.crewCount,
        crewNames: _user!.crewNames,
      );
      notifyListeners();
    }
  }

  Future<void> updateProfilePicture(String path) async {
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        name: _user!.name,
        username: _user!.username,
        email: _user!.email,
        phone: _user!.phone,
        address: _user!.address,
        token: _user!.token,
        role: _user!.role,
        vesselName: _user!.vesselName,
        vesselNumber: _user!.vesselNumber,
        captainName: _user!.captainName,
        crewCount: _user!.crewCount,
        crewNames: _user!.crewNames,
        profilePicture: path,
      );
      notifyListeners();
    }
  }

  void refreshProfilePicture() {
    notifyListeners();
  }

  Future<void> clearUser() async {
    _user = null;
    notifyListeners();
  }
}
