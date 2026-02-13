import 'dart:io';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
          message: 'Data disimpan offline. Akan dikirim otomatis saat ada sinyal.',
        );
      }

      // Ada internet - coba kirim langsung
      bool success = await _sendToServer(catchData, imageFile);
      
      if (success) {
        return SubmissionResult(
          success: true,
          isOffline: false,
          message: 'Data berhasil dikirim ke server.',
        );
      } else {
        // Gagal kirim - simpan offline
        await OfflineSyncService.savePendingCatch(
          catchData: catchData,
          imagePath: imageFile.path,
        );
        
        return SubmissionResult(
          success: true,
          isOffline: true,
          message: 'Gagal kirim ke server. Data disimpan offline.',
        );
      }
    } catch (e) {
      // Error - simpan offline sebagai fallback
      await OfflineSyncService.savePendingCatch(
        catchData: catchData,
        imagePath: imageFile.path,
      );
      
      return SubmissionResult(
        success: true,
        isOffline: true,
        message: 'Terjadi error. Data disimpan offline.',
        error: e.toString(),
      );
    }
  }

  static Future<bool> _sendToServer(
    Map<String, dynamic> catchData,
    File imageFile,
  ) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/mobile/catches');
      
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      debugPrint('🌐 Sending to API: $uri');
      debugPrint('📦 Fish: ${catchData['fish_name']}');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      
      // Add authorization header if token exists
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Add form fields
      request.fields.addAll({
        'fish_name': catchData['fish_name'],
        'fish_type': catchData['fish_type'],
        'weight': catchData['weight'].toString(),
        'quantity': catchData['quantity'].toString(),
        'condition': catchData['condition'],
        'crew_count': catchData['crew_count'].toString(),
        'departure_date': catchData['departure_date'],
        'departure_time': catchData['departure_time'],
        'arrival_date': catchData['arrival_date'],
        'arrival_time': catchData['arrival_time'],
        'trip_duration_hours': catchData['trip_duration_hours'].toString(),
        'trip_duration_minutes': catchData['trip_duration_minutes'].toString(),
        'fishing_zone': catchData['fishing_zone'],
        'location_name': catchData['location_name'],
        'latitude': catchData['latitude'].toString(),
        'longitude': catchData['longitude'].toString(),
        'water_depth': catchData['water_depth'].toString(),
        'weather_condition': catchData['weather_condition'],
        'notes': catchData['notes'] ?? '',
        'kapalId': catchData['kapalId'].toString(),
      });
      
      // Add tripId if available
      if (catchData['tripId'] != null) {
        request.fields['tripId'] = catchData['tripId'].toString();
      }
      
      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('photo', imageFile.path),
      );
      
      debugPrint('📤 Sending request...');
      
      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timeout after 30 seconds');
        },
      );
      
      // Get response
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');
      
      // Check if successful (201 Created or 200 OK)
      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ Catch data sent successfully');
        return true;
      } else {
        debugPrint('❌ Server error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Network error: $e');
      return false;
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