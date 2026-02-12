import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../routes/nahkoda_routes.dart';
import '../../../services/cuaca/weather_service.dart';
import '../../../constants/tracking_constants.dart';

class NahkodaTrackingButton extends StatelessWidget {
  const NahkodaTrackingButton({super.key});

  // Simulate checking trip data - nanti akan diambil dari API/Provider
  Future<Map<String, dynamic>?> _getTripData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Dummy data - sama seperti di TripInfoScreen
    return {
      'vesselName': 'KM Bahari Jaya',
      'vesselNumber': 'KP-12345-JKT',
      'crewCount': 8,
      'departureHarbor': 'Pelabuhan Muara Baru',
      'estimatedDuration': 5,
      'departureDate': DateTime.now().add(const Duration(days: 2)),
      'estimatedReturnDate': DateTime.now().add(const Duration(days: 7)),
      'fuelSupply': 500.0,
      'iceSupply': 1000.0,
      'status': 'scheduled',
    };
  }

  void _showTooEarlyDialog(BuildContext context, Duration timeUntilCanStart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.schedule,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Belum Waktunya',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tracking dapat dimulai ${TrackingConstants.nahkodaBufferMinutes ~/ 60} jam sebelum waktu keberangkatan.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tersedia dalam: ${_formatDuration(timeUntilCanStart)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NahkodaRoutes.navigateToTripInfo(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4F9C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cek Info Trip'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} hari ${duration.inHours % 24} jam';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} jam ${duration.inMinutes % 60} menit';
    } else {
      return '${duration.inMinutes} menit';
    }
  }

  void _showNoTripDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.schedule,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Belum Ada Penjadwalan Trip',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Admin belum mengirim informasi trip. Silakan hubungi admin untuk penjadwalan trip atau cek Info Trip untuk melihat jadwal terbaru.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NahkodaRoutes.navigateToTripInfo(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4F9C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cek Info Trip'),
          ),
        ],
      ),
    );
  }

  void _handleTripPreparation(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final tripData = await _getTripData();
      
      // Close loading - pastikan context masih valid
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (tripData == null) {
        if (context.mounted) {
          _showNoTripDialog(context);
        }
      } else {
        // Ambil user data untuk validasi
        final prefs = await SharedPreferences.getInstance();
        final userDataString = prefs.getString('user_data');
        final userRole = prefs.getString('role') ?? 'crew';
        int? currentUserId;
        
        if (userDataString != null) {
          try {
            final userData = json.decode(userDataString);
            currentUserId = userData['id'];
          } catch (e) {
            print('❌ Error parsing user_data: $e');
          }
        }
        
        if (currentUserId == null) {
          if (context.mounted) {
            _showNoTripDialog(context);
          }
          return;
        }
        
        // Cek apakah sudah waktunya untuk mulai tracking berdasarkan role dan user ID
        final departureDate = tripData['departureDate'] as DateTime;
        final nahkodaId = tripData['nahkodaId'] as int?;
        final awakKapal = tripData['awakKapal'] as List<dynamic>?;
        final status = tripData['status'] as String? ?? '';
        
        final canAccess = TrackingConstants.canAccessTracking(
          role: userRole,
          userId: currentUserId,
          nahkodaId: nahkodaId,
          awakKapal: awakKapal,
          departureDate: departureDate,
          status: status,
        );
        
        if (!canAccess) {
          final now = DateTime.now();
          final bufferMinutes = TrackingConstants.getBufferMinutes(userRole);
          final allowedStartTime = departureDate.subtract(Duration(minutes: bufferMinutes));
          
          if (context.mounted) {
            _showTooEarlyDialog(context, allowedStartTime.difference(now));
          }
        } else {
          // Cek cuaca dulu sebelum lanjut
          if (context.mounted) {
            _checkWeatherAndNavigate(context, tripData);
          }
        }
      }
    } catch (e) {
      print('❌ [Trip Preparation] Error: $e');
      // Close loading
      if (context.mounted) {
        Navigator.pop(context);
        await Future.delayed(Duration(milliseconds: 300));
        if (context.mounted) {
          _showNoTripDialog(context);
        }
      }
    }
  }

  // Cek cuaca sebelum navigasi ke pre-trip form
  Future<void> _checkWeatherAndNavigate(BuildContext context, Map<String, dynamic> tripData) async {
    if (!context.mounted) return;
    
    _showModernLoading(context);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      final weather = await WeatherService.getWeatherByPosition(position);

      if (!context.mounted) return;
      Navigator.pop(context);

      if (weather == null) {
        if (!context.mounted) return;
        _showErrorDialog(
          context,
          'Gagal Mendapatkan Data Cuaca',
          'Tidak dapat mengakses data cuaca. Lanjutkan ke persiapan trip?',
        );
        return;
      }

      final isExtreme = _isWeatherExtreme(weather);

      if (!context.mounted) return;

      if (isExtreme) {
        _showWeatherWarning(context, weather, tripData);
      } else {
        // Cuaca aman, langsung navigasi
        await Future.delayed(Duration(milliseconds: 300));
        if (context.mounted) {
          Navigator.pushNamed(
            context,
            '/pre-trip-form',
            arguments: tripData,
          );
        }
      }
    } catch (e) {
      print('❌ [Weather Check] Error: $e');
      if (context.mounted) {
        Navigator.pop(context);
        await Future.delayed(Duration(milliseconds: 300));
        if (context.mounted) {
          _showErrorDialog(
            context,
            'Terjadi Kesalahan',
            'Tidak dapat memeriksa kondisi cuaca. Lanjutkan ke persiapan trip?',
          );
        }
      }
    }
  }

  bool _isWeatherExtreme(WeatherData weather) {
    final condition = weather.condition.toLowerCase();
    if (condition.contains('petir') ||
        condition.contains('thunder') ||
        condition.contains('storm') ||
        condition.contains('badai')) {
      return true;
    }
    if (weather.windSpeed > 40) return true;
    if (weather.waveHeight > 2.5) return true;
    return false;
  }

  void _showModernLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade700],
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const Icon(Icons.cloud, color: Colors.white, size: 40),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Memeriksa Cuaca',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4F9C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Memastikan kondisi aman untuk melaut...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeatherWarning(BuildContext context, WeatherData weather, Map<String, dynamic> tripData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 60),
            SizedBox(height: 12),
            Text('Cuaca Tidak Aman', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Kondisi cuaca saat ini tidak mendukung untuk melaut'),
            SizedBox(height: 16),
            Text('Kondisi: ${weather.condition}'),
            Text('Angin: ${weather.windSpeed.toStringAsFixed(1)} km/h'),
            Text('Ombak: ${weather.waveHeight.toStringAsFixed(1)} m'),
            SizedBox(height: 16),
            Text(
              'Disarankan menunggu hingga kondisi membaik',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isNight = now.hour >= 18 || now.hour < 6;
    final lottieAsset = isNight 
        ? 'assets/animations/tripmalam.json'
        : 'assets/animations/tripsiang.json';

    return GestureDetector(
      onTap: () => _handleTripPreparation(context),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1565C0), width: 4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: Lottie.asset(
            lottieAsset,
            fit: BoxFit.cover,
            repeat: true,
            animate: true,
          ),
        ),
      ),
    );
  }
}