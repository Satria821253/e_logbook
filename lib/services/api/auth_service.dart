import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../nitification/admin_notification_service.dart';
import 'package:flutter/material.dart';
import '../../utils/account_status_interceptor.dart';
import '../../utils/token_interceptor.dart';

class AuthService {
  // Use HTTP for web development, HTTPS for mobile
  static const String baseUrl = kIsWeb 
      ? 'http://elogbookipb.web.id/api'
      : 'https://elogbookipb.web.id/api';

  static late Dio _dio;

  static void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  static void addAccountStatusInterceptor(BuildContext context) {
    _dio.interceptors.add(AccountStatusInterceptor(context));
  }

  static void addTokenInterceptor(BuildContext context) {
    _dio.interceptors.removeWhere((i) => i is TokenInterceptor);
    _dio.interceptors.add(TokenInterceptor(context: context));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/mobile/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['token'];
        final user = await _processUserData(response.data['user']);
        
        if (token != null) await saveToken(token);
        await _fetchVesselData(token);
        await _initializeUserNotifications(user);

        return {
          'success': true,
          'user': user,
          'token': token,
          'message': 'Login berhasil',
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Login gagal',
      };
    } on DioException catch (e) {
      return _handleLoginError(e);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan tidak terduga'};
    }
  }

  static Future<UserModel> _processUserData(Map<String, dynamic> userData) async {
    final profile = userData['profile'] ?? {};
    
    String mappedRole = 'Crew';
    if (userData['role'] != null) {
      final apiRole = userData['role'].toString().toLowerCase();
      if (apiRole == 'nahkoda') mappedRole = 'Nahkoda';
    }

    return UserModel(
      id: userData['id'] is int ? userData['id'] : int.tryParse(userData['id'].toString()) ?? 0,
      name: profile['nama'] ?? '',
      email: userData['email'] ?? '',
      phone: profile['telepon'] ?? '',
      address: profile['alamat'],
      role: mappedRole,
      profilePicture: null,
      vesselName: null,
      vesselNumber: null,
      captainName: null,
    );
  }

  static Future<void> _fetchVesselData(String token) async {
    try {
      final vesselResponse = await _dio.get(
        '/mobile/vessels/my-vessel',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (vesselResponse.statusCode == 200 && vesselResponse.data['success'] == true) {
        final vessels = vesselResponse.data['data'] as List;
        if (vessels.isNotEmpty) {
          final vesselData = vessels[0];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'vessel_data',
            jsonEncode({
              'kapal': {
                'id': vesselData['id'],
                'namaKapal': vesselData['namaKapal'],
                'nomorRegistrasi': vesselData['nomorRegistrasi'],
              },
              'nahkoda': vesselData['nahkoda'],
            }),
          );
        }
      }
    } catch (e) {
      // Silent fail - vessel data is optional
    }
  }

  static Future<void> _initializeUserNotifications(UserModel user) async {
    if (user.isNahkoda) {
      try {
        await AdminNotificationService.initializeNahkodaDocuments(user.email);
        await AdminNotificationService.createAdminNotification(
          userId: user.email,
          title: 'Selamat Datang, Nahkoda!',
          message: 'Mohon lengkapi dokumen-dokumen yang diperlukan sebelum memulai trip pertama Anda.',
          type: 'document_requirement',
          isUrgent: true,
        );
      } catch (e) {
        // Silent fail - notifications are optional
      }
    }
  }

  static Map<String, dynamic> _handleLoginError(DioException e) {
    if (e.response?.statusCode == 400) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Email dan password wajib diisi'};
    } else if (e.response?.statusCode == 401) {
      final message = e.response?.data['message'] ?? 'Email atau password salah';
      return {'success': false, 'message': message, 'isAccountInactive': message.toLowerCase().contains('tidak aktif')};
    } else if (e.response?.statusCode == 403) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Akun tidak memiliki akses mobile app'};
    } else if (e.response?.statusCode == 429) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Terlalu banyak percobaan, coba lagi nanti'};
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return {'success': false, 'message': 'Koneksi timeout. Periksa koneksi internet Anda', 'isTimeout': true};
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return {'success': false, 'message': 'Server tidak merespons. Coba lagi nanti', 'isTimeout': true};
    } else if (e.type == DioExceptionType.connectionError) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda'};
    } else if (e.type == DioExceptionType.sendTimeout) {
      return {'success': false, 'message': 'Gagal mengirim data. Coba lagi', 'isTimeout': true};
    }
    return {'success': false, 'message': e.response?.data['message'] ?? 'Login gagal. Coba lagi'};
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await prefs.remove('vessel_data');
    await prefs.remove('popup_shown_this_session');
  }
}
