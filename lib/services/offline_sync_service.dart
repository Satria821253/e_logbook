import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class OfflineSyncService {
  static Database? _database;
  static const String _tableName = 'pending_catches';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'offline_sync.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE $_tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            catch_data TEXT NOT NULL,
            image_path TEXT NOT NULL,
            created_at TEXT NOT NULL,
            retry_count INTEGER DEFAULT 0,
            last_error TEXT
          )
        ''');
      },
    );
  }

  // Simpan data catch yang gagal dikirim
  static Future<void> savePendingCatch({
    required Map<String, dynamic> catchData,
    required String imagePath,
  }) async {
    final db = await database;
    await db.insert(_tableName, {
      'catch_data': json.encode(catchData),
      'image_path': imagePath,
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
      'last_error': null,
    });
    debugPrint('📱 Catch saved offline: ${catchData['fishName']}');
  }

  // Ambil semua data pending
  static Future<List<Map<String, dynamic>>> getPendingCatches() async {
    final db = await database;
    return await db.query(_tableName, orderBy: 'created_at ASC');
  }

  // Hapus data yang sudah berhasil dikirim
  static Future<void> deletePendingCatch(int id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Update retry count dan error
  static Future<void> updateRetryCount(int id, String error) async {
    final db = await database;
    await db.update(
      _tableName,
      {
        'retry_count': 'retry_count + 1',
        'last_error': error,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Cek koneksi dan sync otomatis
  static Future<void> autoSync() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      debugPrint('📡 No internet connection');
      return;
    }

    final pendingCatches = await getPendingCatches();
    if (pendingCatches.isEmpty) {
      debugPrint('✅ No pending catches to sync');
      return;
    }

    debugPrint('🔄 Syncing ${pendingCatches.length} pending catches...');

    for (final pendingCatch in pendingCatches) {
      try {
        final catchData = json.decode(pendingCatch['catch_data']);
        final imagePath = pendingCatch['image_path'];
        
        // Cek apakah file gambar masih ada
        if (!await File(imagePath).exists()) {
          debugPrint('❌ Image not found: $imagePath');
          await deletePendingCatch(pendingCatch['id']);
          continue;
        }

        // Kirim data ke server (implementasi sesuai API)
        bool success = await _sendCatchToServer(catchData, imagePath);
        
        if (success) {
          await deletePendingCatch(pendingCatch['id']);
          debugPrint('✅ Synced: ${catchData['fishName']}');
        } else {
          await updateRetryCount(pendingCatch['id'], 'Server error');
          debugPrint('❌ Failed to sync: ${catchData['fishName']}');
        }
      } catch (e) {
        await updateRetryCount(pendingCatch['id'], e.toString());
        debugPrint('❌ Sync error: $e');
      }
    }
  }

  // Simulasi kirim ke server (ganti dengan API call sebenarnya)
  static Future<bool> _sendCatchToServer(
    Map<String, dynamic> catchData,
    String imagePath,
  ) async {
    try {
      // TODO: Implementasi API call ke server
      // Contoh:
      // final response = await http.post(
      //   Uri.parse('your-api-endpoint'),
      //   body: catchData,
      //   files: [File(imagePath)],
      // );
      // return response.statusCode == 200;
      
      // Simulasi delay
      await Future.delayed(Duration(seconds: 2));
      return true; // Ganti dengan logic sebenarnya
    } catch (e) {
      debugPrint('❌ Server error: $e');
      return false;
    }
  }

  // Monitor koneksi dan auto sync
  static void startConnectivityMonitoring() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        debugPrint('📡 Connection restored, starting auto sync...');
        autoSync();
      }
    });
  }

  // Get pending count untuk UI
  static Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return result.first['count'] as int;
  }

  // Cek apakah catch ID ada di pending (untuk status di riwayat)
  static Future<bool> isCatchPending(String catchId) async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: "json_extract(catch_data, '\$.id') = ?",
      whereArgs: [catchId],
    );
    return result.isNotEmpty;
  }

  // Get pending catch dengan detail untuk riwayat
  static Future<Map<String, dynamic>?> getPendingCatchDetails(String catchId) async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: "json_extract(catch_data, '\$.id') = ?",
      whereArgs: [catchId],
    );
    
    if (result.isEmpty) return null;
    
    final pendingData = result.first;
    return {
      'retry_count': pendingData['retry_count'],
      'last_error': pendingData['last_error'],
      'created_at': pendingData['created_at'],
    };
  }
}