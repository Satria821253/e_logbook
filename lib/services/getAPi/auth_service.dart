import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../admin_notification_service.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.1.6:5000/api/';
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

  static Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    try {
      print('🔐 Login attempt for user: $login');
      
      final response = await _dio.post('/auth/login', data: {
        'username': login,
        'password': password,
      });

      print('📥 Login response status: ${response.statusCode}');
      print('📥 Login response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['token'];
        final userData = response.data['user'];
        
        print('✅ Login successful for user: ${userData['nama']}');
        print('👤 User role from API: ${userData['role']}');
        
        // Map API response to UserModel
        // Map role from API: 'nahkoda' -> 'Nahkoda', 'abk' -> 'ABK', 'admin' -> 'Nahkoda' (fallback)
        String mappedRole = 'Nahkoda';
        if (userData['role'] != null) {
          final apiRole = userData['role'].toString().toLowerCase();
          if (apiRole == 'abk') {
            mappedRole = 'ABK';
          } else if (apiRole == 'nahkoda') {
            mappedRole = 'Nahkoda';
          }
        }
        
        print('🔄 Mapped role: $mappedRole');
        
        final user = UserModel(
          id: userData['id'] ?? 0,
          name: userData['nama'] ?? '',
          email: userData['email'] ?? '',
          phone: userData['telepon'] ?? '',
          role: mappedRole,
          profilePicture: null,
        );
        
        if (token != null) {
          await saveToken(token);
          print('💾 Token saved successfully');
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
        print('❌ Login failed: ${response.data['message']}');
        return {
          'success': false,
          'message': response.data['message'] ?? 'Login gagal',
        };
      }
    } on DioException catch (e) {
      print('⚠️ DioException: ${e.type}');
      print('⚠️ Response: ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Username atau password salah',
        };
      } else if (e.type == DioExceptionType.connectionTimeout) {
        return {'success': false, 'message': 'Koneksi timeout'};
      } else if (e.type == DioExceptionType.connectionError) {
        return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
      } else {
        return {'success': false, 'message': 'Login gagal'};
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan tidak terduga'};
    }
  }

  static Future<void> logout() async {
    await removeToken();
  }
}
