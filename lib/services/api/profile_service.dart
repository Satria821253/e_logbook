import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class ProfileService {
  static const String baseUrl = 'http://192.168.1.19:5000/api';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  ); // ✅ CUKUP SAMPAI SINI

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      print('🔍 Fetching profile from API...');
      final response = await _dio.get(
        '/mobile/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('📡 Profile API Response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        print('📄 Profile data keys: ${data.keys.toList()}');

        String mappedRole = 'Nahkoda';
        if (data['role'] != null) {
          final apiRole = data['role'].toString().toLowerCase();
          if (apiRole == 'abk') {
            mappedRole = 'ABK';
          } else if (apiRole == 'nahkoda') {
            mappedRole = 'Nahkoda';
          }
        }

        String? photoUrl;
        final fotoUrl = data['fotoUrl'];
        final foto = data['foto'];

        print('📸 fotoUrl from API: $fotoUrl');
        print('📸 foto from API: $foto');

        if (fotoUrl != null && fotoUrl.toString().isNotEmpty) {
          final path = fotoUrl.toString();
          if (path.startsWith('http')) {
            photoUrl = path;
          } else if (path.startsWith('/')) {
            photoUrl = 'http://192.168.1.19:5000$path';
          } else {
            // Path relatif tanpa slash, tambahkan /uploads/profile-photos/
            photoUrl = 'http://192.168.1.19:5000/uploads/profile-photos/$path';
          }
        } else if (foto != null && foto.toString().isNotEmpty) {
          final path = foto.toString();
          if (path.startsWith('http')) {
            photoUrl = path;
          } else if (path.startsWith('/')) {
            photoUrl = 'http://192.168.1.19:5000$path';
          } else {
            // Path relatif tanpa slash, tambahkan /uploads/profile-photos/
            photoUrl = 'http://192.168.1.19:5000/uploads/profile-photos/$path';
          }
        }

        print('📸 Final photoUrl: $photoUrl');

        final user = UserModel(
          id: data['id'] is int
              ? data['id']
              : int.tryParse(data['id'].toString()) ?? 0,
          name: data['nama'] ?? '',
          username: data['username'],
          email: data['email'] ?? '',
          phone: data['noTelepon'] ?? '',
          address: data['alamat'],
          role: mappedRole,
          profilePicture: photoUrl,
        );

        print('✅ User created with photo: ${user.profilePicture}');

        return {
          'success': true,
          'user': user,
          'isActive': data['isActive'] ?? true,
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal mengambil profil',
      };
    } on DioException catch (e) {
      print('❌ DioException in getProfile: ${e.message}');
      if (e.response?.statusCode == 401) {
        final message = e.response?.data['message'] ?? '';
        return {
          'success': false,
          'message': message,
          'isAccountInactive': message.toLowerCase().contains('tidak aktif'),
        };
      }
      return {'success': false, 'message': 'Gagal mengambil profil'};
    } catch (e) {
      print('❌ Error in getProfile: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? username,
    String? phone,
    String? address,
    String? photoPath,
  }) async {
    try {
      print('🔄 Starting profile update...');
      print(
        '📝 Update data: name=$name, username=$username, phone=$phone, address=$address',
      );
      if (photoPath != null) print('📸 Photo path: $photoPath');

      final token = await _getToken();
      if (token == null) {
        print('❌ No token found');
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }
      print('✅ Token found: ${token.substring(0, 20)}...');

      FormData formData = FormData.fromMap({
        if (name != null) 'nama': name,
        if (username != null) 'username': username,
        if (phone != null) 'noTelepon': phone,
        if (address != null) 'alamat': address,
        if (photoPath != null)
          'foto': await MultipartFile.fromFile(
            photoPath,
            filename: photoPath.split(RegExp(r'[\\/]')).last,
          ),
      });

      print(
        '📤 Sending FormData fields: ${formData.fields.map((f) => '${f.key}=${f.value}').join(', ')}',
      );
      if (formData.files.isNotEmpty) {
        print('📎 Files: ${formData.files.map((f) => f.key).join(', ')}');
      }

      final response = await _dio.put(
        '/mobile/profile',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('📥 API Response Status: ${response.statusCode}');
      print('📥 API Response Data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        print('✅ Profile update successful!');

        // Get updated photo URL from response - use fotoUrl field
        String? newPhotoUrl;
        if (response.data['data'] != null) {
          print(
            '📋 Response data fields: ${response.data['data'].keys.toList()}',
          );

          // Check if name was updated
          if (response.data['data']['nama'] != null) {
            print('✅ Name updated in API: ${response.data['data']['nama']}');
          }

          // Check if username was updated
          if (response.data['data']['username'] != null) {
            print(
              '✅ Username updated in API: ${response.data['data']['username']}',
            );
          }

          // Try foto field from response (API returns 'foto' not 'fotoUrl')
          if (response.data['data']['foto'] != null) {
            final fotoPath = response.data['data']['foto'].toString();
            print('📸 Foto path from API: $fotoPath');

            if (fotoPath.isNotEmpty) {
              if (fotoPath.startsWith('http')) {
                newPhotoUrl = fotoPath;
              } else if (fotoPath.startsWith('/')) {
                newPhotoUrl = 'http://192.168.1.19:5000$fotoPath';
              } else {
                // Path relatif tanpa slash, tambahkan /uploads/profile-photos/
                newPhotoUrl =
                    'http://192.168.1.19:5000/uploads/profile-photos/$fotoPath';
              }
              print('📸 Final photo URL: $newPhotoUrl');
            }
          }
        }

        return {
          'success': true,
          'message': 'Profil berhasil diperbarui',
          'photoUrl': newPhotoUrl,
        };
      }

      print('❌ API returned error: ${response.data}');
      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal memperbarui profil',
      };
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      return {
        'success': false,
        'message':
            e.response?.data['message'] ??
            'Gagal memperbarui profil: ${e.message}',
      };
    } catch (e) {
      print('❌ General Exception: $e');
      return {
        'success': false,
        'message': 'Gagal memperbarui profil: ${e.toString()}',
      };
    }
  }
}
