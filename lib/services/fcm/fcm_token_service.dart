import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FCMTokenService {
  static final Dio _dio = Dio();
  static final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';

  // Kirim FCM token ke backend saat login
  static Future<void> sendTokenToBackend(String fcmToken, String userId) async {
    try {
      print('📤 Sending FCM token to backend...');
      
      final response = await _dio.post(
        '$_baseUrl/users/fcm-token',
        data: {
          'userId': userId,
          'fcmToken': fcmToken,
          'platform': 'android', // atau 'ios'
        },
      );

      if (response.statusCode == 200) {
        print('✅ FCM token sent successfully');
      }
    } catch (e) {
      print('❌ Error sending FCM token: $e');
    }
  }

  // Hapus FCM token saat logout
  static Future<void> removeTokenFromBackend(String userId) async {
    try {
      print('📤 Removing FCM token from backend...');
      
      await _dio.delete(
        '$_baseUrl/users/fcm-token',
        data: {'userId': userId},
      );

      print('✅ FCM token removed');
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }
  }
}
