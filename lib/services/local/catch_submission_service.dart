import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
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

  // Kirim ke server (implementasi sesuai API)
  static Future<bool> _sendToServer(
    Map<String, dynamic> catchData,
    File imageFile,
  ) async {
    try {
      // TODO: Implementasi real API call
      // Format data sesuai API spec (data mentah, perhitungan di backend)
      final apiData = {
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
      };
      
      debugPrint('🌐 Sending to API: ${apiData['fish_name']}');
      debugPrint('📦 API Data: $apiData');
      
      // Contoh implementasi dengan http.MultipartRequest:
      // final request = http.MultipartRequest(
      //   'POST', 
      //   Uri.parse('http://your-api/mobile/catches')
      // );
      // request.fields.addAll(apiData);
      // request.files.add(
      //   await http.MultipartFile.fromPath('photo', imageFile.path)
      // );
      // final response = await request.send();
      // return response.statusCode == 201;
      
      await Future.delayed(Duration(seconds: 2)); // Simulasi
      return true; // Ganti dengan logic sebenarnya
    } catch (e) {
      debugPrint('❌ Server error: $e');
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