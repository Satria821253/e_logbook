import 'dart:async';
import 'package:e_logbook/services/device/zone_checker.dart';
import 'package:e_logbook/services/device/foreground_tracking_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

/// Service untuk tracking lokasi secara real-time saat trip aktif
class LocationTrackingService {
  static StreamSubscription<Position>? _positionStream;
  static Position? _lastPosition;
  static bool _isTracking = false;
  static Function(Position, Map<String, dynamic>)? _onLocationUpdate;
  static VoidCallback? _onViolationDetected;
  static VoidCallback? _onBackToSafeZone;
  
  static String? _selectedHarborName;
  static String? _vesselName;
  static bool _isCurrentlyViolating = false;

  /// Mulai tracking lokasi (dipanggil saat user klik "Mulai Tracking")
  static Future<void> startTracking({
    required String harborName,
    required String vesselName,
    required VoidCallback onViolationDetected,
    required VoidCallback onBackToSafeZone,
    required Function(Position, Map<String, dynamic>) onLocationUpdate,
  }) async {
    if (_isTracking) {
      debugPrint('⚠️ Tracking sudah berjalan');
      return;
    }

    _selectedHarborName = harborName;
    _vesselName = vesselName;
    _onViolationDetected = onViolationDetected;
    _onBackToSafeZone = onBackToSafeZone;
    _onLocationUpdate = onLocationUpdate;

    try {
      // Cek permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi tidak aktif');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen. Aktifkan di Settings.');
      }

      // 🚀 START FOREGROUND SERVICE
      await ForegroundTrackingService.startService(
        vesselName: vesselName,
        harborName: harborName,
      );

      // Get initial position
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Mulai streaming posisi dengan interval lebih pendek untuk tracking aktif
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update setiap 50 meter untuk tracking lebih responsif
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onPositionUpdate,
        onError: (error) {
          debugPrint('❌ Error tracking: $error');
          // Cleanup on error
          _cleanup();
        },
        onDone: () {
          debugPrint('📍 Position stream completed');
          _cleanup();
        },
        cancelOnError: true,
      );

      _isTracking = true;
      
      // Trigger initial update
      if (_lastPosition != null) {
        _onPositionUpdate(_lastPosition!);
      }
      
      debugPrint('✅ Location tracking started for $vesselName at $harborName');
    } catch (e) {
      debugPrint('❌ Failed to start tracking: $e');
      await _cleanup(); // Ensure cleanup on error
      rethrow;
    }
  }

  /// Handler ketika lokasi update
  static void _onPositionUpdate(Position position) {
    _lastPosition = position;

    if (_selectedHarborName == null || _vesselName == null) return;

    // 🚨 CEK ZONA TERLARANG DULU (PRIORITAS UTAMA)
    final restrictedCheck = ZoneCheckerService.checkRestrictedZones(
      latitude: position.latitude,
      longitude: position.longitude,
      vesselName: _vesselName!,
    );

    bool isInRestrictedZone = restrictedCheck['isInRestrictedZone'] == true;

    // Cek zona pelabuhan (untuk info saja)
    final zoneCheck = ZoneCheckerService.checkZone(
      selectedHarborName: _selectedHarborName!,
      latitude: position.latitude,
      longitude: position.longitude,
      vesselName: _vesselName!,
    );

    // Gabungkan info zona
    final combinedZoneInfo = {
      ...zoneCheck,
      'isInRestrictedZone': isInRestrictedZone,
      'restrictedZoneName': restrictedCheck['zoneName'],
      'restrictedZoneDistance': restrictedCheck['distance'],
    };

    // Callback location update (untuk update UI map)
    _onLocationUpdate?.call(position, combinedZoneInfo);

    // 🚨 DETEKSI MASUK ZONA TERLARANG
    if (isInRestrictedZone && !_isCurrentlyViolating) {
      // MASUK ZONA TERLARANG - TRIGGER ALARM!
      _isCurrentlyViolating = true;
      _onViolationDetected?.call();
      
      debugPrint('🚨 ENTERED RESTRICTED ZONE!');
      debugPrint('   Zone: ${restrictedCheck['zoneName']}');
      debugPrint('   Distance from center: ${restrictedCheck['distance']} km');
      debugPrint('   Zone Radius: ${restrictedCheck['zoneRadius']} km');
      
    } else if (!isInRestrictedZone && _isCurrentlyViolating) {
      // KELUAR DARI ZONA TERLARANG - STOP ALARM
      _isCurrentlyViolating = false;
      _onBackToSafeZone?.call();
      debugPrint('✅ Exited restricted zone - Back to safe area');
    }
  }

  /// Stop tracking (dipanggil saat user akhiri trip)
  static Future<void> stopTracking() async {
    await ForegroundTrackingService.stopService();
    await _cleanup();
    debugPrint('🛑 Location tracking stopped');
  }
  
  /// Internal cleanup method
  static Future<void> _cleanup() async {
    try {
      await _positionStream?.cancel();
    } catch (e) {
      debugPrint('⚠️ Error cancelling position stream: $e');
    } finally {
      _positionStream = null;
      _isTracking = false;
      _isCurrentlyViolating = false;
      _selectedHarborName = null;
      _vesselName = null;
      _onViolationDetected = null;
      _onBackToSafeZone = null;
      _onLocationUpdate = null;
    }
  }

  /// Getter
  static Position? get lastPosition => _lastPosition;
  static bool get isTracking => _isTracking;
  static bool get isCurrentlyViolating => _isCurrentlyViolating;
  static String? get currentHarbor => _selectedHarborName;
  static String? get currentVessel => _vesselName;

  /// Get current zone info
  static Map<String, dynamic>? getCurrentZoneInfo() {
    if (_lastPosition == null || _selectedHarborName == null || _vesselName == null) {
      return null;
    }

    return ZoneCheckerService.checkZone(
      selectedHarborName: _selectedHarborName!,
      latitude: _lastPosition!.latitude,
      longitude: _lastPosition!.longitude,
      vesselName: _vesselName!,
    );
  }
  static Future<void> startTrackingWithCoordinates({
  required double harborLat,
  required double harborLng,
  required String harborName,
  required String vesselName,
  required double zoneRadius,
  required Function() onViolationDetected,
  required Function() onBackToSafeZone,
  required Function(Position, Map<String, dynamic>) onLocationUpdate,
}) async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }
  }

  await ForegroundTrackingService.startService(
    vesselName: vesselName,
    harborName: harborName,
  );

  bool wasViolating = false;
  _vesselName = vesselName;
  _selectedHarborName = harborName;
  _isTracking = true;

  _positionStream = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  ).listen((Position position) {
    _lastPosition = position;

    final restrictedCheck = ZoneCheckerService.checkRestrictedZones(
      latitude: position.latitude,
      longitude: position.longitude,
      vesselName: vesselName,
    );

    bool isInRestrictedZone = restrictedCheck['isInRestrictedZone'] == true;

    final distance = Geolocator.distanceBetween(
          harborLat,
          harborLng,
          position.latitude,
          position.longitude,
        ) /
        1000;

    final zoneInfo = {
      'distance': distance,
      'zoneRadius': zoneRadius,
      'isViolating': isInRestrictedZone,
      'isInRestrictedZone': isInRestrictedZone,
      'restrictedZoneName': restrictedCheck['zoneName'],
      'restrictedZoneDistance': restrictedCheck['distance'],
      'excessDistance': isInRestrictedZone ? restrictedCheck['distance'] : 0.0,
      'harborName': harborName,
    };

    onLocationUpdate(position, zoneInfo);

    ForegroundTrackingService.updateNotification(
      title: '🚢 $vesselName',
      text: 'Jarak: ${distance.toStringAsFixed(1)} km dari $harborName',
    );

    if (isInRestrictedZone && !wasViolating) {
      wasViolating = true;
      _isCurrentlyViolating = true;
      onViolationDetected();
      debugPrint('🚨 ENTERED RESTRICTED ZONE!');
      debugPrint('   Zone: ${restrictedCheck['zoneName']}');
    } else if (!isInRestrictedZone && wasViolating) {
      wasViolating = false;
      _isCurrentlyViolating = false;
      onBackToSafeZone();
      debugPrint('✅ Exited restricted zone - Back to safe area');
    }
  });
}
}