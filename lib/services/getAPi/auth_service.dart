import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../admin_notification_service.dart';
import 'package:flutter/material.dart';
import '../../utils/account_status_interceptor.dart';

class AuthService {
  static const String baseUrl = 'http://210.79.191.17/api';
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
    required String login,
    required String password,
  }) async {
    try {
      print('🔐 Login attempt for user: $login');

      final response = await _dio.post(
        '/mobile/login',
        data: {'email': login, 'password': password},
      );

      print('📥 Login response status: ${response.statusCode}');
      print('📥 Login response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['token'];
        final userData = response.data['user'];
        final profile = userData['profile'] ?? {};
        final kapal = profile['kapal'];

        print('✅ Login successful for user: ${profile['nama']}');
        print('👤 User role from API: ${userData['role']}');
        print('🚢 Vessel data from API: $kapal');
        print('🚢 Profile structure: $profile');
        print('🚢 Kapal keys: ${kapal?.keys}');

        // Map role from API: 'nahkoda' -> 'Nahkoda', 'abk' -> 'Crew', 'crew' -> 'Crew'
        String mappedRole = 'Nahkoda';
        if (userData['role'] != null) {
          final apiRole = userData['role'].toString().toLowerCase();
          if (apiRole == 'abk' || apiRole == 'crew') {
            mappedRole = 'Crew';
          } else if (apiRole == 'nahkoda') {
            mappedRole = 'Nahkoda';
          }
        }

        print('🔄 Mapped role: $mappedRole');

        final user = UserModel(
          id: userData['id'] is int
              ? userData['id']
              : int.tryParse(userData['id'].toString()) ?? 0,
          name: profile['nama'] ?? '',
          email: userData['email'] ?? '',
          phone: profile['telepon'] ?? '',
          address: profile['alamat'],
          role: mappedRole,
          profilePicture: null,
          vesselName: kapal?['namaKapal'],
          vesselNumber: kapal?['nomorKapal'],
          captainName: kapal?['nahkoda']?['nama'],
        );

        if (token != null) {
          await saveToken(token);
          print('💾 Token saved successfully');
        }

        // Fetch vessel data from my-vessel endpoint
        try {
          final vesselDio = Dio(
            BaseOptions(
              baseUrl: 'http://210.79.191.17:5000',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

          final vesselResponse = await vesselDio.get(
            '/api/mobile/vessels/my-vessel',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          if (vesselResponse.statusCode == 200 &&
              vesselResponse.data['success'] == true) {
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
              print('💾 Vessel data fetched: ${vesselData['namaKapal']}');
            } else {
              print('ℹ️ No vessel assigned');
            }
          } else {
            print('ℹ️ No vessel assigned');
          }
        } catch (e) {
          print('ℹ️ Could not fetch vessel: $e');
        }

        // Initialize document requirements for nahkoda after successful login
        if (user.isNahkoda) {
          await AdminNotificationService.initializeNahkodaDocuments(user.email);

          // Create welcome notification
          await AdminNotificationService.createAdminNotification(
            userId: user.email,
            title: 'Selamat Datang, Nahkoda!',
            message:
                'Mohon lengkapi dokumen-dokumen yang diperlukan sebelum memulai trip pertama Anda.',
            type: 'document_requirement',
            isUrgent: true,
          );
        }

        return {
          'success': true,
          'user': user,
          'token': token,
          'message': response.data['message'] ?? 'Login berhasil',
        };
      } else {
        print('❌ Login failed: ${response.data['message']}');
        return {
          'success': false,
          'message': response.data['message'] ?? 'Login gagal',
        };
      }
    } on DioException catch (e) {
      print('⚠️ DioException: ${e.type}');
      print('⚠️ Response: ${e.response?.data}');

      if (e.response?.statusCode == 400) {
        return {
          'success': false,
          'message':
              e.response?.data['message'] ?? 'Email dan password wajib diisi',
        };
      } else if (e.response?.statusCode == 401) {
        final message =
            e.response?.data['message'] ?? 'Email atau password salah';
        return {
          'success': false,
          'message': message,
          'isAccountInactive': message.toLowerCase().contains('tidak aktif'),
        };
      } else if (e.response?.statusCode == 403) {
        return {
          'success': false,
          'message':
              e.response?.data['message'] ??
              'Akun tidak memiliki akses mobile app',
        };
      } else if (e.response?.statusCode == 429) {
        return {
          'success': false,
          'message':
              e.response?.data['message'] ??
              'Terlalu banyak percobaan, coba lagi nanti',
        };
      } else if (e.type == DioExceptionType.connectionTimeout) {
        return {
          'success': false,
          'message': 'Koneksi timeout. Periksa koneksi internet Anda',
          'isTimeout': true,
        };
      } else if (e.type == DioExceptionType.receiveTimeout) {
        return {
          'success': false,
          'message': 'Server tidak merespons. Coba lagi nanti',
          'isTimeout': true,
        };
      } else if (e.type == DioExceptionType.connectionError) {
        return {
          'success': false,
          'message':
              'Tidak dapat terhubung ke server. Periksa koneksi internet Anda',
        };
      } else if (e.type == DioExceptionType.sendTimeout) {
        return {
          'success': false,
          'message': 'Gagal mengirim data. Coba lagi',
          'isTimeout': true,
        };
      } else {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Login gagal. Coba lagi',
        };
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan tidak terduga'};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs
        .clear(); // Hapus semua data termasuk token, user_data, vessel_data, dll
  }
}
