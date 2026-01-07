import 'package:e_logbook/constants/indonesia_harbors.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/zone_alert.dart';



class ZoneCheckerService {

  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isAlarmPlaying = false;

  /// Cek apakah lokasi tangkapan dalam zona yang sesuai
  static Map<String, dynamic> checkZone({
    required String selectedHarborName,
    required double latitude,
    required double longitude,
    required String vesselName,
  }) {
    // Cari harbor berdasarkan nama
    final harbor = IndonesiaHarbors.getHarborByFullName(selectedHarborName);
    
    if (harbor == null) {
      return {
        'isViolation': false,
        'message': 'Data pelabuhan tidak ditemukan',
        'distance': 0.0,
        'zoneRadius': 0.0,
      };
    }

    // Hitung jarak dari lokasi ke pusat pelabuhan
    final distance = harbor.getDistanceFromCenter(latitude, longitude);
    final zoneRadius = harbor.radiusKm;

    // Cek apakah dalam zona
    final isInZone = distance <= zoneRadius;
    final isViolation = !isInZone;

    Map<String, dynamic> result = {
      'isViolation': isViolation,
      'isInZone': isInZone,
      'distance': distance,
      'zoneRadius': zoneRadius,
      'harborName': harbor.fullName,
      'harborId': harbor.id,
    };

    if (isViolation) {
      final excessDistance = distance - zoneRadius;
      final alertType = _determineAlertType(excessDistance);

      // Buat zone alert sesuai dengan model yang benar
      final alert = ZoneAlert(
        id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        harborZoneId: harbor.id,
        harborZoneName: harbor.fullName,
        currentDistance: distance,
        zoneRadius: zoneRadius,
        violationLocation: LatLng(latitude, longitude), // Gunakan LatLng dari google_maps_flutter
        vesselName: vesselName,
        alertType: alertType,
        isRead: false,
      );

      result['excessDistance'] = excessDistance;
      result['alertType'] = alertType;
      result['alert'] = alert;
    }

    return result;
  }

  

  /// Tentukan tipe alert berdasarkan jarak kelebihan
  static String _determineAlertType(double excessDistance) {
    if (excessDistance > 50) return 'critical';
    if (excessDistance > 20) return 'warning';
    return 'info';
  }

 
  /// Get color berdasarkan alert type
  static Color getAlertColor(String alertType) {
    switch (alertType) {
      case 'critical':
        return Colors.red.shade900;
      case 'warning':
        return Colors.orange.shade700;
      case 'info':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }

  /// Get icon berdasarkan alert type
  static IconData getAlertIcon(String alertType) {
    switch (alertType) {
      case 'critical':
        return Icons.dangerous;
      case 'warning':
        return Icons.warning_amber;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.info;
    }
  }

  static Future<void> triggerAlarm() async {
    if (_isAlarmPlaying) return;

    try {
      _isAlarmPlaying = true;

      // Set release mode ke LOOP agar berulang
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Set volume maksimal
      await _audioPlayer.setVolume(1.0);

      // Play alarm sound dari assets
      await _audioPlayer.play(AssetSource('audio/alarm.m4a'));

      print('🚨 Alarm dimulai (looping)');
    } catch (e) {
      print('❌ Error playing alarm: $e');
      _isAlarmPlaying = false;
    }
  }


  /// ⭐ Stop alarm
  static Future<void> stopAlarm() async {
    if (!_isAlarmPlaying) return;

    try {
      await _audioPlayer.stop();
      _isAlarmPlaying = false;
      print('✅ Alarm dihentikan');
    } catch (e) {
      print('❌ Error stopping alarm: $e');
    }
  }

  /// Get alarm status
  static bool get isAlarmPlaying => _isAlarmPlaying;

  /// Dispose audio player (call saat app closed)
  static Future<void> dispose() async {
    await _audioPlayer.dispose();
    _isAlarmPlaying = false;
  }

  /// Vibrate device (optional, bisa dikombinasikan dengan audio)
  static Future<void> vibrateDevice() async {
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      print('❌ Vibration not supported: $e');
    }
  }
}