import 'dart:async';
import 'package:e_logbook/services/zone_checker.dart';
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

    // Cek zona
    final zoneCheck = ZoneCheckerService.checkZone(
      selectedHarborName: _selectedHarborName!,
      latitude: position.latitude,
      longitude: position.longitude,
      vesselName: _vesselName!,
    );

    bool isViolation = zoneCheck['isViolation'] == true;

    // Callback location update (untuk update UI map)
    _onLocationUpdate?.call(position, zoneCheck);

    // Deteksi perubahan status violation
    if (isViolation && !_isCurrentlyViolating) {
      // Baru keluar zona - TRIGGER ALARM
      _isCurrentlyViolating = true;
      _onViolationDetected?.call();
      
      debugPrint('🚨 VIOLATION DETECTED!');
      debugPrint('   Distance: ${zoneCheck['distance']} km');
      debugPrint('   Zone Radius: ${zoneCheck['zoneRadius']} km');
      debugPrint('   Excess: ${zoneCheck['excessDistance']} km');
      
    } else if (!isViolation && _isCurrentlyViolating) {
      // Kembali ke zona aman
      _isCurrentlyViolating = false;
      _onBackToSafeZone?.call();
      debugPrint('✅ Back to safe zone');
    }
  }

  /// Stop tracking (dipanggil saat user akhiri trip)
  static Future<void> stopTracking() async {
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
  required double zoneRadius, // dalam km
  required Function() onViolationDetected,
  required Function() onBackToSafeZone,
  required Function(Position, Map<String, dynamic>) onLocationUpdate,
}) async {
  // Check permission
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }
  }

  bool wasViolating = false;

  // Start tracking
  _positionStream = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update setiap 10 meter
    ),
  ).listen((Position position) {
    // Hitung jarak dari pelabuhan
    final distance = Geolocator.distanceBetween(
          harborLat,
          harborLng,
          position.latitude,
          position.longitude,
        ) /
        1000; // Convert ke km

    final isViolating = distance > zoneRadius;
    final excessDistance = isViolating ? distance - zoneRadius : 0.0;

    final zoneInfo = {
      'distance': distance,
      'zoneRadius': zoneRadius,
      'isViolating': isViolating,
      'excessDistance': excessDistance,
      'harborName': harborName,
    };

    // Update callback
    onLocationUpdate(position, zoneInfo);

    // Check violation
    if (isViolating && !wasViolating) {
      wasViolating = true;
      onViolationDetected();
    } else if (!isViolating && wasViolating) {
      wasViolating = false;
      onBackToSafeZone();
    }
  });
}
}