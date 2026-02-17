import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import 'offline_sync_service.dart';

class CatchSubmissionService {
  // Submit catch dengan offline fallback
  static Future<SubmissionResult> submitCatch({
    required Map<String, dynamic> catchData,
    required File imageFile,
  }) async {
    try {
      // Cek koneksi internet
      final connectivity = await Connectivity().checkConnectivity();
      
      if (connectivity == ConnectivityResult.none) {
        // Tidak ada internet - simpan offline
        await OfflineSyncService.savePendingCatch(
          catchData: catchData,
          imagePath: imageFile.path,
        );
        
        return SubmissionResult(
          success: true,
          isOffline: true,
          message: '📡 Data disimpan offline. Akan dikirim otomatis saat ada sinyal.',
        );
      }

      // Ada internet - coba kirim langsung
      try {
        await _sendToServer(catchData, imageFile);
        return SubmissionResult(
          success: true,
          isOffline: false,
          message: '✅ Data berhasil dikirim ke server.',
        );
      } catch (e) {
        // Jika error dari server (400, 500, dll), tampilkan pesan error
        if (e.toString().contains('Server Error')) {
          return SubmissionResult(
            success: false,
            isOffline: false,
            message: e.toString().replaceAll('Exception: ', ''),
            error: e.toString(),
          );
        }
        
        // Network error lainnya - simpan offline
        await OfflineSyncService.savePendingCatch(
          catchData: catchData,
          imagePath: imageFile.path,
        );
        
        return SubmissionResult(
          success: true,
          isOffline: true,
          message: '⚠️ Gagal kirim ke server. Data disimpan offline.',
          error: e.toString(),
        );
      }
    } catch (e) {
      // Error - simpan offline sebagai fallback
      try {
        await OfflineSyncService.savePendingCatch(
          catchData: catchData,
          imagePath: imageFile.path,
        );
        
        return SubmissionResult(
          success: true,
          isOffline: true,
          message: '⚠️ Terjadi error. Data disimpan offline.',
          error: e.toString(),
        );
      } catch (offlineError) {
        return SubmissionResult(
          success: false,
          isOffline: false,
          message: '❌ Gagal menyimpan data: ${offlineError.toString()}',
          error: offlineError.toString(),
        );
      }
    }
  }

  static Future<bool> _sendToServer(
    Map<String, dynamic> catchData,
    File imageFile,
  ) async {
    try {
      debugPrint('\n📤 ========== SENDING CATCH TO SERVER ==========');
      final uri = Uri.parse('${ApiConfig.baseUrl}/mobile/catches');
      
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      debugPrint('🌐 API URL: $uri');
      debugPrint('🔑 Token: ${token != null ? "***${token.substring(token.length - 10)}" : "null"}');
      debugPrint('\n📦 Catch Data to Send:');
      debugPrint('   fish_name: ${catchData['fish_name']}');
      debugPrint('   fish_type: ${catchData['fish_type']}');
      debugPrint('   weight: ${catchData['weight']}');
      debugPrint('   quantity: ${catchData['quantity']}');
      debugPrint('   condition: ${catchData['condition']}');
      debugPrint('   kapalId: ${catchData['kapalId']}');
      debugPrint('   tripId: ${catchData['tripId']}');
      debugPrint('   fishing_zone: ${catchData['fishing_zone']}');
      debugPrint('   location_name: ${catchData['location_name']}');
      debugPrint('   weather_condition: ${catchData['weather_condition']}');
      debugPrint('   crew_count: ${catchData['crew_count']}');
      debugPrint('   departure_date: ${catchData['departure_date']}');
      debugPrint('   departure_time: ${catchData['departure_time']}');
      debugPrint('   arrival_date: ${catchData['arrival_date']}');
      debugPrint('   arrival_time: ${catchData['arrival_time']}');
      debugPrint('   trip_duration_hours: ${catchData['trip_duration_hours']}');
      debugPrint('   trip_duration_minutes: ${catchData['trip_duration_minutes']}');
      debugPrint('   latitude: ${catchData['latitude']}');
      debugPrint('   longitude: ${catchData['longitude']}');
      debugPrint('   water_depth: ${catchData['water_depth']}');
      debugPrint('   notes: ${catchData['notes']}');
      debugPrint('   image: ${imageFile.path}');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers['Accept'] = 'application/json';
      
      // Add authorization header if token exists
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
        debugPrint('✅ Authorization header added');
      } else {
        debugPrint('⚠️ No auth token found');
      }
      
      debugPrint('📝 Request headers: ${request.headers}');
      // Add form fields - sesuai API spec
      debugPrint('\n📝 Adding form fields...');
      
      // Validate data before adding
      if (catchData['fish_name'] == null || catchData['fish_name'].toString().isEmpty) {
        throw Exception('fish_name is null or empty');
      }
      if (catchData['weight'] == null || catchData['weight'] == 0) {
        throw Exception('weight is null or zero');
      }
      if (catchData['kapalId'] == null) {
        throw Exception('kapalId is null');
      }
      
      debugPrint('✅ Data validation passed');
      
      // CRITICAL: Add required fields FIRST (fish_name, weight, kapalId)
      request.fields['fish_name'] = catchData['fish_name'];
      request.fields['weight'] = catchData['weight'].toString();
      request.fields['kapalId'] = catchData['kapalId'].toString();
      
      // Then add other required fields
      request.fields['fish_type'] = catchData['fish_type'];
      request.fields['quantity'] = catchData['quantity'].toString();
      request.fields['condition'] = catchData['condition'];
      
      // Financial data (required by API)
      request.fields['price_per_kg'] = catchData['price_per_kg']?.toString() ?? '0';
      request.fields['total_revenue'] = catchData['total_revenue']?.toString() ?? '0';
      request.fields['fuel_cost'] = catchData['fuel_cost']?.toString() ?? '0';
      request.fields['operational_cost'] = catchData['operational_cost']?.toString() ?? '0';
      request.fields['tax'] = catchData['tax']?.toString() ?? '0';
      request.fields['total_cost'] = catchData['total_cost']?.toString() ?? '0';
      request.fields['net_profit'] = catchData['net_profit']?.toString() ?? '0';
      
      // Trip info
      request.fields['crew_count'] = catchData['crew_count']?.toString() ?? '1';
      request.fields['departure_date'] = catchData['departure_date'];
      request.fields['departure_time'] = catchData['departure_time'];
      request.fields['arrival_date'] = catchData['arrival_date'];
      request.fields['arrival_time'] = catchData['arrival_time'];
      request.fields['trip_duration_hours'] = catchData['trip_duration_hours'].toString();
      request.fields['trip_duration_minutes'] = catchData['trip_duration_minutes'].toString();
      
      // Location info
      request.fields['fishing_zone'] = catchData['fishing_zone'];
      request.fields['location_name'] = catchData['location_name'];
      request.fields['latitude'] = catchData['latitude'].toString();
      request.fields['longitude'] = catchData['longitude'].toString();
      request.fields['water_depth'] = (catchData['water_depth'] ?? 0).toString();
      request.fields['weather_condition'] = catchData['weather_condition'];
      
      // Additional info
      request.fields['notes'] = catchData['notes'] ?? '';
      
      debugPrint('✅ Form fields added: ${request.fields.length} fields');
      
      // Add tripId if available
      if (catchData['tripId'] != null) {
        request.fields['tripId'] = catchData['tripId'].toString();
        debugPrint('✅ tripId added: ${catchData['tripId']}');
      } else {
        debugPrint('⚠️ tripId is null');
      }
      
      // Add image file
      final imageSize = await imageFile.length();
      final imageSizeMB = (imageSize / (1024 * 1024)).toStringAsFixed(2);
      debugPrint('\n📷 Adding image file...');
      debugPrint('   Path: ${imageFile.path}');
      debugPrint('   Size: ${imageSizeMB}MB');
      
      // Determine content type based on file extension
      final extension = imageFile.path.split('.').last.toLowerCase();
      String contentType = 'image/jpeg'; // default
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        contentType = 'image/jpeg';
      }
      
      debugPrint('   Content-Type: $contentType');
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
          contentType: http_parser.MediaType.parse(contentType),
        ),
      );
      
      debugPrint('✅ Image file added with content type: $contentType');
      debugPrint('\n📤 Sending request...');
      debugPrint('   Total fields: ${request.fields.length}');
      debugPrint('   Total files: ${request.files.length}');
      
      // Debug: Print all fields being sent
      debugPrint('\n📋 All fields being sent:');
      request.fields.forEach((key, value) {
        debugPrint('   [$key] = "$value" (length: ${value.length}, empty: ${value.isEmpty})');
      });
      
      // Validate required fields
      final requiredFields = ['fish_name', 'weight', 'kapalId'];
      final missingFields = <String>[];
      for (final field in requiredFields) {
        if (!request.fields.containsKey(field)) {
          missingFields.add('$field (not found)');
        } else if (request.fields[field]!.isEmpty) {
          missingFields.add('$field (empty)');
        } else {
          debugPrint('   ✅ $field: "${request.fields[field]}"');
        }
      }
      
      if (missingFields.isNotEmpty) {
        debugPrint('❌ Missing or empty required fields: $missingFields');
        throw Exception('Missing required fields: ${missingFields.join(", ")}');
      }
      
      debugPrint('✅ All required fields present and not empty');
      debugPrint('\n📤 Request headers:');
      request.headers.forEach((key, value) {
        debugPrint('   $key: $value');
      });
      
      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('❌ Request timeout after 30 seconds');
          throw TimeoutException('Request timeout after 30 seconds');
        },
      );
      
      // Get response
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('\n📥 ========== SERVER RESPONSE ==========');
      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');
      debugPrint('📥 Response headers: ${response.headers}');
      
      // Check if successful (201 Created or 200 OK)
      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ Catch data sent successfully');
        debugPrint('========== SENDING SUCCESS ==========\n');
        return true;
      } else {
        debugPrint('❌ Server error: ${response.statusCode}');
        debugPrint('📄 Error body: ${response.body}');
        
        // Parse error message from server
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ?? 'Unknown error';
          final errorDetail = errorData['error'] ?? '';
          debugPrint('💬 Server message: $errorMessage');
          debugPrint('💬 Server error detail: $errorDetail');
          
          // Provide user-friendly message based on error
          String userMessage = errorMessage;
          
          if (errorDetail.contains('uploadFile is not a function')) {
            userMessage = 'Server sedang dalam perbaikan. Silakan coba lagi nanti atau hubungi admin.';
            debugPrint('⚠️ Backend error: uploadFile function not available');
          } else if (errorDetail.contains('Only image files allowed')) {
            userMessage = 'Format file tidak didukung. Gunakan foto JPG atau PNG.';
          } else if (response.statusCode == 413) {
            userMessage = 'Ukuran foto terlalu besar. Maksimal 5MB.';
          } else if (response.statusCode == 401) {
            userMessage = 'Sesi berakhir. Silakan login kembali.';
          }
          
          // Throw specific error message
          throw Exception('Server Error (${response.statusCode}): $userMessage');
        } catch (e) {
          if (e.toString().contains('Server Error')) {
            rethrow;
          }
          throw Exception('Server Error (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Network error: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      debugPrint('========== SENDING ERROR ==========\n');
      rethrow;  // Rethrow to be caught by caller
    }
  }

  // Manual sync untuk UI
  static Future<SyncResult> manualSync() async {
    try {
      final pendingCount = await OfflineSyncService.getPendingCount();
      if (pendingCount == 0) {
        return SyncResult(
          success: true,
          message: 'Tidak ada data pending untuk disync.',
          syncedCount: 0,
        );
      }

      await OfflineSyncService.autoSync();
      final remainingCount = await OfflineSyncService.getPendingCount();
      final syncedCount = pendingCount - remainingCount;

      return SyncResult(
        success: true,
        message: 'Berhasil sync $syncedCount dari $pendingCount data.',
        syncedCount: syncedCount,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Gagal sync: $e',
        syncedCount: 0,
      );
    }
  }
}

class SubmissionResult {
  final bool success;
  final bool isOffline;
  final String message;
  final String? error;

  SubmissionResult({
    required this.success,
    required this.isOffline,
    required this.message,
    this.error,
  });
}

class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
  });
}