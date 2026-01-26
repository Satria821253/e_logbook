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
      // TODO: Implementasi API call
      // Contoh:
      // final request = http.MultipartRequest('POST', Uri.parse('your-api'));
      // request.fields.addAll(catchData.map((k, v) => MapEntry(k, v.toString())));
      // request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      // final response = await request.send();
      // return response.statusCode == 200;
      
      debugPrint('🌐 Sending to server: ${catchData['fishName']}');
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