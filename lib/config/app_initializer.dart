import 'package:e_logbook/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:e_logbook/services/api/auth_service.dart';
import 'package:e_logbook/services/local/offline_sync_service.dart';
import 'package:e_logbook/services/realtime/realtime_update_service.dart';
import 'package:e_logbook/services/local/crash_reporter.dart';

class AppInitializer {
  static Future<bool> initialize() async {
    try {
      // Initialize crash reporter first
      await CrashReporter.initialize();
      
      await dotenv.load(fileName: ".env");

         // 🔴 VALIDASI DI SINI
    if (ApiConfig.geminiApiKey.isEmpty) {
      throw Exception('API Key Gemini belum dikonfigurasi');
    }
      await _cleanupCache();
      AuthService.init();
      await initializeDateFormatting('id_ID', null);
      _startBackgroundServices();
      
      CrashReporter.log('App initialized successfully');
      return true;
    } catch (e, stack) {
      debugPrint('❌ Initialization error: $e');
      CrashReporter.recordError(e, stack, fatal: true);
      return false;
    }
  }

  static Future<void> _cleanupCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('popup_shown_this_session');
    
    final userData = prefs.getString('user_data');
    if (userData != null && userData.contains('api10-')) {
      await prefs.remove('user_data');
      await prefs.remove('user_profile');
      debugPrint('🧹 Cleared corrupted cache');
    }
  }

  static void _startBackgroundServices() {
    OfflineSyncService.startConnectivityMonitoring();
    RealtimeUpdateService.startPolling();
  }
}
