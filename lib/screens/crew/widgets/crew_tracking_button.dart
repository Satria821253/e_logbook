import 'package:e_logbook/screens/tracking/active_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../../../services/api/trip_service.dart';
import '../../../services/api/zone_service.dart';
import '../../../services/cuaca/weather_service.dart';
import '../../../routes/crew_routes.dart';
import '../../../provider/tracking_minimize_provider.dart';
import '../../tracking/waiting_schedule_screen.dart';
import '../../tracking/waiting_approval_screen.dart';
import '../../tracking/pre_tracking_simple_wrapper.dart';

class CrewTrackingButton extends StatelessWidget {
  const CrewTrackingButton({super.key});

  Future<Map<String, dynamic>?> _getTripData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      int? currentUserId;
      
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        currentUserId = userData['id'];
      }
      
      if (currentUserId == null) return null;
      
      final response = await TripService.getAllTrips();
      if (response['success'] == true && response['data'] != null) {
        final allTrips = List<Map<String, dynamic>>.from(response['data']);
        
        print('🔍 [Crew] Total trips: ${allTrips.length}');
        print('🔍 [Crew] Current user ID: $currentUserId');
        
        final myTrip = allTrips.firstWhere(
          (trip) {
            final nahkodaId = trip['nahkodaId'];
            final awakKapal = trip['awakKapal'] as List?;
            
            // Cek apakah user adalah nahkoda
            if (nahkodaId == currentUserId) {
              print('✅ [Crew] Found trip as nahkoda: ${trip['id']}');
              return true;
            }
            
            // Cek apakah user ada di awakKapal
            if (awakKapal != null) {
              for (var crew in awakKapal) {
                final crewId = crew is Map ? crew['id'] : crew;
                if (crewId == currentUserId) {
                  print('✅ [Crew] Found trip as crew member: ${trip['id']}');
                  return true;
                }
              }
            }
            
            return false;
          },
          orElse: () => {},
        );
        
        if (myTrip.isEmpty) return null;
        
        // Parse harbor coordinates
        Map<String, dynamic>? harborCoords;
        String harborName = '-';
        final areaTangkap = myTrip['areaTangkap'];
        
        if (areaTangkap != null) {
          harborName = areaTangkap['nama'] ?? '-';
          
          // Cek apakah ada koordinat langsung dari areaTangkap
          if (areaTangkap['latitude'] != null && areaTangkap['longitude'] != null) {
            harborCoords = {
              'lat': areaTangkap['latitude'],
              'lng': areaTangkap['longitude'],
            };
            print('✅ [Crew] Koordinat dari areaTangkap: $harborCoords');
          } else {
            // Jika tidak ada koordinat, fetch dari harbor-zones API
            print('⚠️ [Crew] areaTangkap tidak ada koordinat, fetching dari harbor-zones...');
            try {
              final harborZones = await ZoneService.getAllHarborZones();
              
              // Cari zona yang namanya match
              for (var zone in harborZones) {
                if (zone.name.toLowerCase() == harborName.toLowerCase() ||
                    harborName.toLowerCase().contains(zone.name.toLowerCase()) ||
                    zone.name.toLowerCase().contains(harborName.toLowerCase())) {
                  
                  if (zone.isCircle && zone.centerPoint != null) {
                    harborCoords = {
                      'lat': zone.centerPoint!.latitude,
                      'lng': zone.centerPoint!.longitude,
                    };
                    print('✅ [Crew] Koordinat dari harbor-zones (circle): $harborCoords');
                    break;
                  } else if (zone.isPolygon && zone.polygonCoordinates?.isNotEmpty == true) {
                    // Gunakan titik pertama polygon sebagai center
                    harborCoords = {
                      'lat': zone.polygonCoordinates!.first.latitude,
                      'lng': zone.polygonCoordinates!.first.longitude,
                    };
                    print('✅ [Crew] Koordinat dari harbor-zones (polygon): $harborCoords');
                    break;
                  }
                }
              }
              
              if (harborCoords == null) {
                print('❌ [Crew] Zona "$harborName" tidak ditemukan di harbor-zones');
                print('🔍 [Crew] Mencari di catch-polygons...');
                
                // Cari di catch-polygons
                final catchPolygons = await ZoneService.getAllCatchPolygons();
                for (var polygon in catchPolygons) {
                  if (polygon.name.toLowerCase() == harborName.toLowerCase() ||
                      harborName.toLowerCase().contains(polygon.name.toLowerCase()) ||
                      polygon.name.toLowerCase().contains(harborName.toLowerCase())) {
                    
                    if (polygon.coordinates.isNotEmpty) {
                      // Gunakan titik pertama polygon sebagai center
                      harborCoords = {
                        'lat': polygon.coordinates.first.latitude,
                        'lng': polygon.coordinates.first.longitude,
                      };
                      print('✅ [Crew] Koordinat dari catch-polygons: $harborCoords');
                      break;
                    }
                  }
                }
                
                if (harborCoords == null) {
                  print('❌ [Crew] Zona "$harborName" tidak ditemukan di catch-polygons');
                }
              }
            } catch (e) {
              print('❌ [Crew] Error fetching zones: $e');
            }
          }
        }
        
        // Fallback ke koordinat default jika tidak ditemukan
        if (harborCoords == null) {
          print('⚠️ [Crew] Koordinat tidak ditemukan, menggunakan default (Pelabuhan Muara Baru)...');
          harborCoords = {
            'lat': -6.1075,
            'lng': 106.7803,
          };
          print('✅ [Crew] Koordinat default: $harborCoords');
        }
        
        // Debug BBM dan Es dari perizinan.operasional (sama seperti nahkoda)
        print('⛽ [Crew] ===== DEBUG BBM & ES =====');
        final perizinan = myTrip['perizinan'];
        final operasional = perizinan?['operasional'];
        print('⛽ [Crew] perizinan: $perizinan');
        print('⛽ [Crew] operasional: $operasional');
        
        final fuelValue = (operasional?['bensinTersedia'] ?? 0).toDouble();
        final iceValue = (operasional?['esTersedia'] ?? 0).toDouble();
        
        print('⛽ [Crew] bensinTersedia: ${operasional?['bensinTersedia']}');
        print('⛽ [Crew] esTersedia: ${operasional?['esTersedia']}');
        print('⛽ [Crew] Converted fuelSupply: $fuelValue');
        print('⛽ [Crew] Converted iceSupply: $iceValue');
        print('⛽ [Crew] ===== END DEBUG =====');
        
        return {
          'tripId': myTrip['id'],
          'vesselName': myTrip['kapal']?['namaKapal'] ?? 'Kapal',
          'vesselNumber': myTrip['kapal']?['nomorRegistrasi'] ?? '-',
          'captainName': myTrip['nahkoda']?['nama'] ?? 'Nahkoda',
          'crewCount': (myTrip['awakKapal'] as List?)?.length ?? 0,
          'departureHarbor': harborName,
          'estimatedDuration': myTrip['durasi'] ?? 1,
          'departureDate': myTrip['tanggalBerangkat'] != null 
              ? DateTime.parse(myTrip['tanggalBerangkat'])
              : DateTime.now(),
          'estimatedReturnDate': myTrip['estimasiPulang'] != null
              ? DateTime.parse(myTrip['estimasiPulang'])
              : null,
          'fuelSupply': fuelValue,
          'iceSupply': iceValue,
          'emergencyContact': myTrip['kontakDarurat'] ?? '',
          'notes': myTrip['catatan'],
          'status': myTrip['status'],
          'nahkodaId': myTrip['nahkodaId'],
          'awakKapal': myTrip['awakKapal'],
          'harborCoordinates': harborCoords,
          'zoneRadius': myTrip['radiusZona']?.toDouble() ?? 50.0,
        };
      }
      
      return null;
    } catch (e) {
      print('❌ [CrewTracking] Error: $e');
      return null;
    }
  }

  void _showAlreadyInTrackingDialog(BuildContext context) {
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
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.sailing,
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tracking Aktif',
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
            const Text(
              'Anda sudah berada dalam tracking aktif. Silakan gunakan floating button untuk membuka tracking.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tap floating button di pojok kanan bawah untuk melihat tracking',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
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
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _showNoTripDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.info_outline, color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Belum Ada Trip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: const Text(
          'Belum ada trip yang dijadwalkan untuk Anda.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _handleTracking(BuildContext context) async {
    // Cek apakah tracking sudah aktif dari provider
    final trackingProvider = Provider.of<TrackingMinimizeProvider>(context, listen: false);
    if (trackingProvider.isTrackingActive) {
      _showAlreadyInTrackingDialog(context);
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final tripData = await _getTripData();
      
      if (context.mounted) Navigator.pop(context);
      
      if (tripData == null) {
        if (context.mounted) _showNoTripDialog(context);
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      int? currentUserId;
      
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        currentUserId = userData['id'];
      }
      
      if (currentUserId == null) {
        if (context.mounted) _showNoTripDialog(context);
        return;
      }
      
      final status = tripData['status'] as String? ?? '';
      final statusLower = status.toLowerCase();
      
      print('🔍 [Crew] Status: $status');
      
      // Jika status 'menunggu_dokumen' -> ke MySchedulesScreen
      if (statusLower == 'menunggu_dokumen') {
        if (context.mounted) {
          CrewRoutes.navigateToMySchedules(context);
        }
        return;
      }
      
      // Jika status 'aktif' -> ke PreTrackingSimple
      if (statusLower == 'aktif') {
        if (context.mounted) {
          _navigateToPreTrackingSimple(context, tripData);
        }
        return;
      }
      
      // Jika status 'menunggu_izin' atau 'pending' -> ke WaitingApprovalScreen
      if (statusLower == 'menunggu_izin' || statusLower == 'pending') {
        if (context.mounted) {
          _navigateToWaitingApproval(context, tripData);
        }
        return;
      }
      
      // Jika status 'diizinkan' atau 'disetujui' -> ke WaitingScheduleScreen (crew menunggu sampai berlayar)
      if (statusLower == 'diizinkan' || statusLower == 'disetujui') {
        if (context.mounted) {
          _navigateToWaitingSchedule(context, tripData);
        }
        return;
      }
      
      // Status lain -> cek cuaca dulu (crew tidak ada buffer)
      if (context.mounted) {
        _checkWeatherAndNavigate(context, tripData, status);
      }
    } catch (e) {
      print('❌ [CrewTracking] Error: $e');
      if (context.mounted) {
        Navigator.pop(context);
        await Future.delayed(Duration(milliseconds: 300));
        if (context.mounted) _showNoTripDialog(context);
      }
    }
  }

  void _navigateToPreTrackingSimple(BuildContext context, Map<String, dynamic> tripData) async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    final userRole = prefs.getString('role') ?? 'ABK';
    String userName = 'ABK';
    
    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString);
        userName = userData['name'] ?? userData['nama'] ?? 'ABK';
      } catch (e) {
        print('❌ Error parsing user_data: $e');
      }
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PreTrackingSimple(
          tripId: tripData['tripId'],
          vesselName: tripData['vesselName'] ?? 'Kapal',
          vesselNumber: tripData['vesselNumber'] ?? '-',
          captainName: tripData['captainName'] ?? 'Nahkoda',
          crewCount: tripData['crewCount'] ?? 0,
          departureHarbor: tripData['departureHarbor'] ?? '-',
          departureDate: tripData['departureDate'] ?? DateTime.now(),
          estimatedReturnDate: tripData['estimatedReturnDate'],
          estimatedDuration: tripData['estimatedDuration'] ?? 1,
          fuelAmount: tripData['fuelSupply']?.toDouble() ?? 0.0,
          iceStorage: tripData['iceSupply']?.toDouble() ?? 0.0,
          harborCoordinates: tripData['harborCoordinates'],
          zoneRadius: tripData['zoneRadius']?.toDouble() ?? 50.0,
          userRole: userRole,
          userName: userName,
        ),
      ),
    );
  }

  void _navigateToWaitingSchedule(BuildContext context, Map<String, dynamic> tripData) async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    final userRole = prefs.getString('role') ?? 'ABK';
    String userName = 'ABK';
    
    print('👤 [Crew WaitingSchedule] ===== DEBUG USER =====');
    print('👤 [Crew WaitingSchedule] userDataString: $userDataString');
    print('👤 [Crew WaitingSchedule] userRole: $userRole');
    
    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString);
        userName = userData['name'] ?? userData['nama'] ?? 'ABK';
        print('👤 [Crew WaitingSchedule] userData: $userData');
        print('👤 [Crew WaitingSchedule] userName: $userName');
      } catch (e) {
        print('❌ [Crew WaitingSchedule] Error parsing user_data: $e');
      }
    }
    print('👤 [Crew WaitingSchedule] Final userName: $userName');
    print('👤 [Crew WaitingSchedule] ===== END DEBUG =====');
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WaitingScheduleScreen(
          scheduledDepartureTime: tripData['departureDate'] ?? DateTime.now(),
          tripData: {
            'vesselName': tripData['vesselName'] ?? 'Kapal',
            'vesselNumber': tripData['vesselNumber'] ?? '-',
            'captainName': tripData['captainName'] ?? 'Nahkoda',
            'crewCount': tripData['crewCount'] ?? 0,
            'selectedHarbor': tripData['departureHarbor'] ?? '-',
            'departureTime': tripData['departureDate'] ?? DateTime.now(),
            'estimatedReturnDate': tripData['estimatedReturnDate'],
            'estimatedDuration': tripData['estimatedDuration'] ?? 1,
            'emergencyContact': tripData['emergencyContact'] ?? '',
            'fuelAmount': tripData['fuelSupply']?.toDouble() ?? 0.0,
            'iceStorage': tripData['iceSupply']?.toDouble() ?? 0.0,
            'notes': tripData['notes'],
            'harborCoordinates': tripData['harborCoordinates'],
            'zoneRadius': tripData['zoneRadius']?.toDouble() ?? 50.0,
            'userRole': userRole,
            'userName': userName,
          },
        ),
      ),
    );
  }

  void _navigateToActiveTracking(BuildContext context, Map<String, dynamic> tripData) async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    final userRole = prefs.getString('role') ?? 'ABK';
    String userName = 'ABK';
    
    print('👤 [Crew] ===== DEBUG USER =====');
    print('👤 [Crew] userDataString: $userDataString');
    print('👤 [Crew] userRole: $userRole');
    
    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString);
        userName = userData['name'] ?? userData['nama'] ?? 'ABK';
        print('👤 [Crew] userData: $userData');
        print('👤 [Crew] userName: $userName');
      } catch (e) {
        print('❌ [Crew] Error parsing user_data: $e');
      }
    }
    print('👤 [Crew] Final userName: $userName');
    print('👤 [Crew] ===== END DEBUG =====');
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveTrackingScreen(
          vesselName: tripData['vesselName'] ?? 'Kapal',
          vesselNumber: tripData['vesselNumber'] ?? '-',
          captainName: tripData['captainName'] ?? 'Nahkoda',
          crewCount: tripData['crewCount'] ?? 0,
          selectedHarbor: tripData['departureHarbor'] ?? '-',
          departureTime: tripData['departureDate'] ?? DateTime.now(),
          estimatedReturnDate: tripData['estimatedReturnDate'],
          estimatedDuration: tripData['estimatedDuration'] ?? 1,
          emergencyContact: tripData['emergencyContact'] ?? '',
          fuelAmount: tripData['fuelSupply']?.toDouble() ?? 0.0,
          iceStorage: tripData['iceSupply']?.toDouble() ?? 0.0,
          notes: tripData['notes'],
          harborCoordinates: tripData['harborCoordinates'],
          zoneRadius: tripData['zoneRadius']?.toDouble() ?? 50.0,
          userRole: userRole,
          userName: userName,
        ),
      ),
    );
  }

  void _navigateToWaitingApproval(BuildContext context, Map<String, dynamic> tripData) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WaitingApprovalScreen(
          tripData: {
            'tripId': tripData['tripId'],
            'vesselName': tripData['vesselName'] ?? 'Kapal',
            'vesselNumber': tripData['vesselNumber'] ?? '-',
            'captainName': tripData['captainName'] ?? 'Nahkoda',
            'crewCount': tripData['crewCount'] ?? 0,
            'departureHarbor': tripData['departureHarbor'] ?? '-',
            'departureDate': tripData['departureDate'] ?? DateTime.now(),
            'estimatedReturnDate': tripData['estimatedReturnDate'],
            'estimatedDuration': tripData['estimatedDuration'] ?? 1,
            'emergencyContact': tripData['emergencyContact'] ?? '',
            'fuelAmount': tripData['fuelSupply']?.toDouble() ?? 0.0,
            'iceStorage': tripData['iceSupply']?.toDouble() ?? 0.0,
            'notes': tripData['notes'],
            'harborCoordinates': tripData['harborCoordinates'],
            'zoneRadius': tripData['zoneRadius']?.toDouble() ?? 50.0,
          },
        ),
      ),
    );
  }

  Future<void> _checkWeatherAndNavigate(BuildContext context, Map<String, dynamic> tripData, String status) async {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memeriksa Cuaca...'),
            ],
          ),
        ),
      ),
    );

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
        _routeByStatus(context, tripData, status);
        return;
      }

      final isExtreme = _isWeatherExtreme(weather);

      if (!context.mounted) return;

      if (isExtreme) {
        _showWeatherWarning(context, weather);
      } else {
        await Future.delayed(Duration(milliseconds: 300));
        if (context.mounted) {
          _routeByStatus(context, tripData, status);
        }
      }
    } catch (e) {
      print('❌ [Crew Weather Check] Error: $e');
      if (context.mounted) {
        Navigator.pop(context);
        await Future.delayed(Duration(milliseconds: 300));
        if (context.mounted) {
          _routeByStatus(context, tripData, status);
        }
      }
    }
  }

  void _routeByStatus(BuildContext context, Map<String, dynamic> tripData, String status) {
    final statusLower = status.toLowerCase();
    
    // Status menunggu_dokumen -> MySchedulesScreen
    if (statusLower == 'menunggu_dokumen') {
      CrewRoutes.navigateToMySchedules(context);
      return;
    }
    
    // Status aktif -> PreTrackingSimple
    if (statusLower == 'aktif') {
      _navigateToPreTrackingSimple(context, tripData);
      return;
    }
    
    // Status menunggu_izin/pending -> WaitingApprovalScreen
    if (statusLower == 'menunggu_izin' || statusLower == 'pending') {
      _navigateToWaitingApproval(context, tripData);
      return;
    }
    
    // Status diizinkan/disetujui -> WaitingScheduleScreen
    if (statusLower == 'diizinkan' || statusLower == 'disetujui') {
      _navigateToWaitingSchedule(context, tripData);
      return;
    }
    
    // Status berlayar -> ActiveTrackingScreen
    if (statusLower == 'berlayar') {
      _navigateToActiveTracking(context, tripData);
      return;
    }
    
    // Status lain -> tampilkan no trip dialog
    _showNoTripDialog(context);
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

  void _showWeatherWarning(BuildContext context, WeatherData weather) {
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isNight = now.hour >= 18 || now.hour < 6;
    final lottieAsset = isNight 
        ? 'assets/animations/tripmalam.json'
        : 'assets/animations/tripsiang.json';

    return GestureDetector(
      onTap: () => _handleTracking(context),
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
