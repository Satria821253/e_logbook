import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class DocumentService {
  static const String baseUrl = 'http://192.168.1.12:5173/api';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(minutes: 2),
      receiveTimeout: const Duration(minutes: 2),
      sendTimeout: const Duration(minutes: 2),
      headers: {'Accept': 'application/json'},
    ),
  );

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, dynamic>> uploadDocument({
    required String jenisDokumen,
    String? nomorDokumen,
    String? tanggalBerlaku,
    required String filePath,
    String? keterangan,
  }) async {
    try {
      print('📤 Uploading document:');
      print('  - jenisDokumen: $jenisDokumen');
      print('  - nomorDokumen: $nomorDokumen');
      print('  - tanggalBerlaku: $tanggalBerlaku');
      print('  - filePath: $filePath');
      print('  - keterangan: $keterangan');
      
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }
      
      // Check file size
      final file = File(filePath);
      final fileSize = await file.length();
      print('📁 File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        return {
          'success': false,
          'message': 'File terlalu besar. Maksimal 10MB',
        };
      }

      // Build FormData - hanya kirim field yang diperlukan
      final formDataMap = <String, dynamic>{
        'jenisDokumen': jenisDokumen,
        'dokumen': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split(RegExp(r'[\\\\/]')).last,
        ),
      };
      
      // Hanya tambahkan nomorDokumen jika ada dan tidak kosong
      if (nomorDokumen != null && nomorDokumen.isNotEmpty) {
        formDataMap['nomorDokumen'] = nomorDokumen;
      }
      
      // Hanya tambahkan tanggalBerlaku jika ada dan tidak kosong
      if (tanggalBerlaku != null && tanggalBerlaku.isNotEmpty) {
        formDataMap['tanggalBerlaku'] = tanggalBerlaku;
      }
      
      // Hanya tambahkan keterangan jika ada dan tidak kosong
      if (keterangan != null && keterangan.isNotEmpty) {
        formDataMap['keterangan'] = keterangan;
      }

      FormData formData = FormData.fromMap(formDataMap);
      
      print('🚀 Starting upload...');
      final response = await _dio.post(
        '/mobile/profile/documents',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: (sent, total) {
          final progress = (sent / total * 100).toStringAsFixed(1);
          print('📤 Upload progress: $progress%');
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'message': response.data['message'],
          'data': response.data['data'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal upload dokumen',
      };
    } on DioException catch (e) {
      print('❌ DioException: ${e.type}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Status code: ${e.response?.statusCode}');
      
      // Print detailed error information
      if (e.response?.data != null && e.response?.data['errors'] != null) {
        print('❌ Detailed errors:');
        for (var error in e.response?.data['errors']) {
          print('   - ${error['message']}');
        }
      }
      
      String errorMessage = 'Gagal upload dokumen';
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Koneksi timeout. Periksa koneksi internet Anda';
      } else if (e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Upload timeout. File mungkin terlalu besar';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server tidak merespons. Coba lagi nanti';
      }
      
      return {
        'success': false,
        'message': e.response?.data['message'] ?? errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal upload dokumen: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getDocuments() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await _dio.get(
        '/mobile/profile/documents',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'documents': response.data['data'] ?? [],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal mengambil dokumen',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal mengambil dokumen: ${e.toString()}',
      };
    }
  }
}
