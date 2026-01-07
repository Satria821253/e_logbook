import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'admin_notification_service.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.1.22:8000/api';
  static late Dio _dio;

  static void init() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
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

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final response = await _dio.post('/register', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'remember_me': rememberMe,
      });

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Registrasi berhasil',
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Registrasi gagal',
        };
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return {'success': false, 'message': 'Koneksi timeout'};
      } else if (e.type == DioExceptionType.connectionError) {
        return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
      } else {
        return {'success': false, 'message': 'Terjadi kesalahan: ${e.message}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan tidak terduga'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/login', data: {
        'login': login,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final user = UserModel.fromJson(response.data['user']);
        
        if (token != null) {
          await saveToken(token);
        }
        
        // Initialize document requirements for nahkoda after successful login
        if (user.isNahkoda) {
          await AdminNotificationService.initializeNahkodaDocuments(user.email);
          
          // Create welcome notification
          await AdminNotificationService.createAdminNotification(
            userId: user.email,
            title: 'Selamat Datang, Nahkoda!',
            message: 'Mohon lengkapi dokumen-dokumen yang diperlukan sebelum memulai trip pertama Anda.',
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
        return {
          'success': false,
          'message': response.data['message'] ?? 'Login gagal',
        };
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return {'success': false, 'message': 'Koneksi timeout'};
      } else if (e.type == DioExceptionType.connectionError) {
        return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
      } else {
        return {'success': false, 'message': 'Login gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan tidak terduga'};
    }
  }

  static Future<void> logout() async {
    await removeToken();
  }
}
