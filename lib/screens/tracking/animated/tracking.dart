import 'package:e_logbook/screens/schedules/my_schedules_screen.dart';
import 'package:e_logbook/services/cuaca/weather_service.dart';
import 'package:e_logbook/services/api/trip_service.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../waiting_schedule_screen.dart';
import '../../nahkoda/screens/aktif_tracking.dart';

class TrackingAnimationButton extends StatefulWidget {
  const TrackingAnimationButton({super.key});

  @override
  State<TrackingAnimationButton> createState() =>
      _TrackingAnimationButtonState();
}

class _TrackingAnimationButtonState extends State<TrackingAnimationButton> {
  late String _currentAnimation;

  @override
  void initState() {
    super.initState();
    _updateAnimationBasedOnTime();
  }

  void _updateAnimationBasedOnTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final isDay = hour >= 6 && hour < 18;

    setState(() {
      _currentAnimation = isDay
          ? 'assets/animations/tripsiang.json'
          : 'assets/animations/tripmalam.json';
    });
  }

  // ========================= MODERN LOADING DIALOG =========================

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

  // ========================= WEATHER CHECK =========================

  Future<void> _checkWeatherAndNavigate(BuildContext context) async {
    _showModernLoading(context);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      final weather = await WeatherService.getWeatherByPosition(position);

      if (context.mounted) Navigator.pop(context);

      if (weather == null) {
        if (!context.mounted) return;
        _showModernErrorDialog(
          context,
          'Gagal Mendapatkan Data Cuaca',
          'Tidak dapat mengakses data cuaca saat ini. Coba lagi nanti.',
        );
        return;
      }

      final isExtreme = _isWeatherExtreme(weather);

      if (!context.mounted) return;

      if (isExtreme) {
        _showModernWeatherWarning(context, weather);
      } else {
        // Cuaca aman, langsung navigasi ke schedule
        await Future.delayed(Duration(milliseconds: 300));
        if (context.mounted) {
          await _navigateToSchedule(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showModernErrorDialog(
          context,
          'Terjadi Kesalahan',
          'Tidak dapat memeriksa kondisi cuaca: ${e.toString()}',
        );
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

  // ========================= MODERN WARNING DIALOG =========================

  void _showModernWeatherWarning(BuildContext context, WeatherData weather) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon dengan animasi
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade700],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Cuaca Tidak Aman',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4F9C),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Kondisi cuaca saat ini tidak mendukung untuk melaut',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),

            const SizedBox(height: 24),

            // Weather Info Cards
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.red.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade200, width: 2),
              ),
              child: Column(
                children: [
                  _buildModernWeatherRow(
                    Icons.wb_cloudy_rounded,
                    'Kondisi',
                    weather.condition,
                    Colors.red,
                  ),
                  const Divider(height: 24),
                  _buildModernWeatherRow(
                    Icons.air_rounded,
                    'Kecepatan Angin',
                    '${weather.windSpeed.toStringAsFixed(1)} km/h',
                    Colors.red,
                  ),
                  const Divider(height: 24),
                  _buildModernWeatherRow(
                    Icons.waves_rounded,
                    'Tinggi Ombak',
                    '${weather.waveHeight.toStringAsFixed(1)} m',
                    Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Demi keselamatan, tunda trip hingga cuaca membaik',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4F9C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ========================= HELPER WIDGET =========================

  void _showModernErrorDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade700],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4F9C),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4F9C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mengerti',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToSchedule(BuildContext context) async {
    try {
      print('🔍 Checking schedule...');
      
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      int? currentUserId;
      
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        currentUserId = userData['id'];
        print('👤 Current User ID: $currentUserId');
      }
      
      final response = await TripService.getAllTrips();
      print('📋 Trip response: ${response['success']}');
      
      if (response['success'] == true && response['data'] != null) {
        final allTrips = List<Map<String, dynamic>>.from(response['data']);
        print('📊 Total trips: ${allTrips.length}');
        
        // Cari trip untuk user ini
        final myTrip = allTrips.firstWhere(
          (trip) {
            final nahkodaId = trip['nahkodaId'];
            final awakKapal = trip['awakKapal'] as List?;
            final status = trip['status']?.toLowerCase();
            
            final isMyTrip = (currentUserId != null && nahkodaId == currentUserId) ||
                             (currentUserId != null && awakKapal != null && awakKapal.contains(currentUserId));
            
            return isMyTrip && (status == 'disetujui' || status == 'aktif' || status == 'berlayar');
          },
          orElse: () => {},
        );
        
        if (myTrip.isNotEmpty) {
          final status = myTrip['status']?.toLowerCase();
          print('✅ Found trip with status: $status');
          
          // Jika status berlayar, langsung ke ActiveTrackingScreen tanpa cek cuaca
          if (status == 'berlayar') {
            print('🚢 Status berlayar, navigating directly to ActiveTrackingScreen');
            await _navigateToActiveTracking(context, myTrip);
            return;
          }
          
          // Untuk status disetujui/aktif, ke WaitingScheduleScreen tanpa cek cuaca
          print('⏰ Navigating to WaitingScheduleScreen');
          await _navigateToWaitingSchedule(context, myTrip);
          return;
        }
        
        // Cari trip menunggu izin
        final pendingTrips = allTrips.where((trip) {
          final nahkodaId = trip['nahkodaId'];
          final awakKapal = trip['awakKapal'] as List?;
          final status = trip['status']?.toLowerCase();
          
          final isMyTrip = (currentUserId != null && nahkodaId == currentUserId) ||
                           (currentUserId != null && awakKapal != null && awakKapal.contains(currentUserId));
          
          return isMyTrip && status == 'menunggu_izin';
        }).toList();
        
        if (pendingTrips.isEmpty) {
          if (context.mounted) {
            _showNoScheduleDialog(context);
          }
        } else {
          if (context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MySchedulesScreen(),
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          _showNoScheduleDialog(context);
        }
      }
    } catch (e) {
      print('❌ Error checking schedule: $e');
      if (context.mounted) {
        _showNoScheduleDialog(context);
      }
    }
  }

  Future<void> _navigateToWaitingSchedule(BuildContext context, Map<String, dynamic> tripData) async {
    final kapal = tripData['kapal'] ?? {};
    final nahkoda = tripData['nahkoda'] ?? {};
    final perizinan = tripData['perizinan'] ?? {};
    
    double totalFuel = 0;
    double totalIce = 0;
    
    final fuelDataList = perizinan['fuelData'] as List? ?? [];
    for (var fuel in fuelDataList) {
      totalFuel += (fuel['jumlahLiter'] ?? 0).toDouble();
    }
    
    final iceDataList = perizinan['iceData'] as List? ?? [];
    for (var ice in iceDataList) {
      totalIce += (ice['jumlahKg'] ?? 0).toDouble();
    }
    
    DateTime departureTime = DateTime.now();
    try {
      if (tripData['tanggalBerangkat'] != null) {
        final dateString = tripData['tanggalBerangkat'].toString();
        final datePart = DateTime.parse(dateString);
        departureTime = DateTime(datePart.year, datePart.month, datePart.day, 8, 0);
      }
    } catch (e) {
      print('❌ Error parsing date: $e');
    }
    
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('role')?.toLowerCase();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WaitingScheduleScreen(
          scheduledDepartureTime: departureTime,
          tripData: {
            'vesselName': kapal['namaKapal'] ?? '-',
            'vesselNumber': kapal['nomorRegistrasi'] ?? '-',
            'captainName': nahkoda['nama'] ?? '-',
            'crewCount': (tripData['awakKapal'] as List?)?.length ?? 0,
            'selectedHarbor': tripData['pelabuhanAsal'] ?? '-',
            'departureTime': departureTime,
            'estimatedDuration': tripData['durasi'] ?? 1,
            'fuelAmount': totalFuel,
            'iceStorage': totalIce,
            'userRole': userRole == 'nahkoda' ? 'Nahkoda' : 'ABK',
            'userName': nahkoda['nama'] ?? '-',
          },
        ),
      ),
    );
  }

  Future<void> _navigateToActiveTracking(BuildContext context, Map<String, dynamic> tripData) async {
    final kapal = tripData['kapal'] ?? {};
    final nahkoda = tripData['nahkoda'] ?? {};
    final perizinan = tripData['perizinan'] ?? {};
    
    double totalFuel = 0;
    double totalIce = 0;
    
    final fuelDataList = perizinan['fuelData'] as List? ?? [];
    for (var fuel in fuelDataList) {
      totalFuel += (fuel['jumlahLiter'] ?? 0).toDouble();
    }
    
    final iceDataList = perizinan['iceData'] as List? ?? [];
    for (var ice in iceDataList) {
      totalIce += (ice['jumlahKg'] ?? 0).toDouble();
    }
    
    DateTime departureTime = DateTime.now();
    try {
      if (tripData['tanggalBerangkat'] != null) {
        final dateString = tripData['tanggalBerangkat'].toString();
        final datePart = DateTime.parse(dateString);
        departureTime = DateTime(datePart.year, datePart.month, datePart.day, 8, 0);
      }
    } catch (e) {
      print('❌ Error parsing date: $e');
    }
    
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('role')?.toLowerCase();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveTrackingScreen(
          vesselName: kapal['namaKapal'] ?? '',
          vesselNumber: kapal['nomorRegistrasi'] ?? '',
          captainName: nahkoda['nama'] ?? '',
          crewCount: (tripData['awakKapal'] as List?)?.length ?? 0,
          selectedHarbor: tripData['pelabuhanAsal'] ?? '',
          departureTime: departureTime,
          estimatedReturnDate: null,
          estimatedDuration: tripData['durasi'] ?? 1,
          emergencyContact: '',
          fuelAmount: totalFuel,
          iceStorage: totalIce,
          notes: null,
          harborCoordinates: null,
          zoneRadius: 50.0,
          userRole: userRole == 'nahkoda' ? 'Nahkoda' : 'ABK',
          userName: nahkoda['nama'] ?? '',
        ),
      ),
    );
  }

  void _showNoScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Belum Ada Jadwal Trip',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Anda belum memiliki jadwal penugasan trip. Silakan hubungi admin untuk mendapatkan jadwal trip atau cek menu Jadwal Tugas untuk informasi lebih lanjut.',
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MySchedulesScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4F9C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Cek Jadwal',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ========================= HELPER WIDGET =========================

  Widget _buildModernWeatherRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========================= UI BUTTON =========================

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getTripStatus(),
      builder: (context, snapshot) {
        final isSailing = snapshot.data == 'berlayar';
        
        return GestureDetector(
          onTap: () => _checkWeatherAndNavigate(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: isSailing ? Colors.green : const Color(0xFF1B4F9C),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isSailing ? Colors.green : const Color(0xFF1B4F9C)).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: (isSailing ? Colors.greenAccent : Colors.blueAccent).withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: Lottie.asset(
                      _currentAnimation,
                      key: ValueKey(_currentAnimation),
                      fit: BoxFit.cover,
                      repeat: true,
                      animate: true,
                    ),
                  ),
                ),
              ),
              if (isSailing)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.sailing,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _getTripStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString == null) return null;
      
      final userData = json.decode(userDataString);
      final currentUserId = userData['id'];
      
      final response = await TripService.getAllTrips();
      if (response['success'] == true && response['data'] != null) {
        final allTrips = List<Map<String, dynamic>>.from(response['data']);
        
        final myTrip = allTrips.firstWhere(
          (trip) {
            final nahkodaId = trip['nahkodaId'];
            final awakKapal = trip['awakKapal'] as List?;
            final isMyTrip = (currentUserId != null && nahkodaId == currentUserId) ||
                             (currentUserId != null && awakKapal != null && awakKapal.contains(currentUserId));
            return isMyTrip;
          },
          orElse: () => {},
        );
        
        if (myTrip.isNotEmpty) {
          return myTrip['status']?.toString().toLowerCase();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
