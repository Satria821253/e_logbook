import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../routes/nahkoda_routes.dart';
import '../../../services/cuaca/weather_service.dart';
import '../../../services/api/trip_service.dart';
import '../../../services/api/zone_service.dart';
import '../../../constants/tracking_constants.dart';
import '../../../provider/tracking_minimize_provider.dart';
import '../../tracking/waiting_schedule_screen.dart';
import '../../tracking/waiting_approval_screen.dart';
import 'dart:core';

class NahkodaTrackingButton extends StatelessWidget {
  const NahkodaTrackingButton({super.key});

  // Get trip data from API
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
        
        // Filter trips untuk nahkoda ini
        final myTrips = allTrips.where((trip) {
          final nahkodaId = trip['nahkodaId'];
          return nahkodaId == currentUserId;
        }).toList();
        
        if (myTrips.isEmpty) return null;
        
        print('🔍 [Nahkoda] Total my trips: ${myTrips.length}');
        
        // PRIORITAS 1: Cari trip dengan status "berlayar"
        var myTrip = myTrips.firstWhere(
          (trip) => trip['status']?.toLowerCase() == 'berlayar',
          orElse: () => {},
        );
        
        if (myTrip.isNotEmpty) {
          print('✅ [Nahkoda] PRIORITAS 1: Ditemukan trip berlayar');
        } else {
          // PRIORITAS 2: Cari trip dengan status "disetujui" atau "diizinkan"
          myTrip = myTrips.firstWhere(
            (trip) {
              final status = trip['status']?.toLowerCase();
              return status == 'disetujui' || status == 'diizinkan';
            },
            orElse: () => {},
          );
          
          if (myTrip.isNotEmpty) {
            print('✅ [Nahkoda] PRIORITAS 2: Ditemukan trip disetujui/diizinkan');
          } else {
            // PRIORITAS 3: Cari trip dengan status "aktif"
            myTrip = myTrips.firstWhere(
              (trip) => trip['status']?.toLowerCase() == 'aktif',
              orElse: () => {},
            );
            
            if (myTrip.isNotEmpty) {
              print('✅ [Nahkoda] PRIORITAS 3: Ditemukan trip aktif');
            } else {
              // PRIORITAS 4: Cari trip dengan status "menunggu_dokumen"
              myTrip = myTrips.firstWhere(
                (trip) => trip['status']?.toLowerCase() == 'menunggu_dokumen',
                orElse: () => {},
              );
              
              if (myTrip.isNotEmpty) {
                print('✅ [Nahkoda] PRIORITAS 4: Ditemukan trip menunggu_dokumen');
              } else {
                // FALLBACK: Ambil trip pertama
                myTrip = myTrips.first;
                print('⚠️ [Nahkoda] FALLBACK: Menggunakan trip pertama');
              }
            }
          }
        }
        
        print('🔍 [Nahkoda] Selected trip ID: ${myTrip['id']}, Status: ${myTrip['status']}');
        
        // Debug SEMUA field di myTrip
        print('🔍 [Nahkoda] ===== ALL TRIP FIELDS =====');
        myTrip.forEach((key, value) {
          print('🔍 [Nahkoda]   $key: $value');
        });
        print('🔍 [Nahkoda] ===== END ALL FIELDS =====');
        
        print('🔍 [Nahkoda] ===== PARSING HARBOR COORDINATES =====');
        
        // Parse harbor coordinates
        Map<String, dynamic>? harborCoords;
        String harborName = '-';
        
        // PRIORITAS 1: Gunakan harborZoneId dari backend (paling akurat)
        final harborZoneId = myTrip['harborZoneId'];
        final harborZone = myTrip['harborZone'];
        final areaTangkap = myTrip['areaTangkap'];
        
        print('🔍 [Nahkoda] harborZoneId: $harborZoneId');
        print('🔍 [Nahkoda] harborZone: $harborZone');
        print('🔍 [Nahkoda] areaTangkap: $areaTangkap');
        
        // PRIORITAS 1: Cek harborZoneId (paling akurat dari backend)
        if (harborZoneId != null) {
          print('✅ [Nahkoda] PRIORITAS 1: Menggunakan harborZoneId: $harborZoneId');
          try {
            final harborZones = await ZoneService.getAllHarborZones();
            final matchedZone = harborZones.firstWhere(
              (zone) => zone.id == harborZoneId,
              orElse: () => throw Exception('Zone not found'),
            );
            
            harborName = matchedZone.name;
            
            if (matchedZone.isCircle && matchedZone.centerPoint != null) {
              harborCoords = {
                'lat': matchedZone.centerPoint!.latitude,
                'lng': matchedZone.centerPoint!.longitude,
              };
              print('✅ [Nahkoda] Koordinat dari harborZoneId (circle): $harborCoords');
            } else if (matchedZone.isPolygon && matchedZone.polygonCoordinates != null && matchedZone.polygonCoordinates!.isNotEmpty) {
              harborCoords = {
                'lat': matchedZone.polygonCoordinates!.first.latitude,
                'lng': matchedZone.polygonCoordinates!.first.longitude,
              };
              print('✅ [Nahkoda] Koordinat dari harborZoneId (polygon): $harborCoords');
            }
          } catch (e) {
            print('❌ [Nahkoda] Error fetching zone by ID: $e');
          }
        }
        
        // PRIORITAS 2: Cek harborZone yang sudah populated
        if (harborCoords == null && harborZone != null) {
          print('✅ [Nahkoda] PRIORITAS 2: Menggunakan harborZone populated');
          harborName = harborZone['name'] ?? '-';
          
          if (harborZone['latitude'] != null && harborZone['longitude'] != null) {
            harborCoords = {
              'lat': harborZone['latitude'],
              'lng': harborZone['longitude'],
            };
            print('✅ [Nahkoda] Koordinat dari harborZone: $harborCoords');
          } else if (harborZone['centerPoint'] != null) {
            final center = harborZone['centerPoint'];
            if (center['latitude'] != null && center['longitude'] != null) {
              harborCoords = {
                'lat': center['latitude'],
                'lng': center['longitude'],
              };
              print('✅ [Nahkoda] Koordinat dari harborZone.centerPoint: $harborCoords');
            }
          }
        }
        
        // PRIORITAS 3: Cek areaTangkap dengan koordinat langsung
        if (harborCoords == null && areaTangkap != null) {
          print('✅ [Nahkoda] PRIORITAS 3: Menggunakan areaTangkap');
          harborName = areaTangkap['nama'] ?? '-';
          
          if (areaTangkap['latitude'] != null && areaTangkap['longitude'] != null) {
            harborCoords = {
              'lat': areaTangkap['latitude'],
              'lng': areaTangkap['longitude'],
            };
            print('✅ [Nahkoda] Koordinat dari areaTangkap: $harborCoords');
          } else if (harborName != '-' && harborName != 'Area tidak diset') {
            // Cari di harbor-zones berdasarkan nama
            print('🔍 [Nahkoda] Mencari "$harborName" di harbor-zones...');
            try {
              final harborZones = await ZoneService.getAllHarborZones();
              for (var zone in harborZones) {
                if (zone.name.toLowerCase() == harborName.toLowerCase()) {
                  print('✅ [Nahkoda] MATCH! Zone: ${zone.name}');
                  if (zone.isCircle && zone.centerPoint != null) {
                    harborCoords = {
                      'lat': zone.centerPoint!.latitude,
                      'lng': zone.centerPoint!.longitude,
                    };
                    print('✅ [Nahkoda] Koordinat: $harborCoords');
                    break;
                  } else if (zone.isPolygon && zone.polygonCoordinates != null && zone.polygonCoordinates!.isNotEmpty) {
                    harborCoords = {
                      'lat': zone.polygonCoordinates!.first.latitude,
                      'lng': zone.polygonCoordinates!.first.longitude,
                    };
                    print('✅ [Nahkoda] Koordinat: $harborCoords');
                    break;
                  }
                }
              }
              if (harborCoords == null) {
                print('❌ [Nahkoda] "$harborName" tidak ditemukan di harbor-zones');
              }
            } catch (e) {
              print('❌ [Nahkoda] Error: $e');
            }
          }
        }
        
        // PRIORITAS 4: Cari di catch-polygons jika masih null
        if (harborCoords == null && harborName != '-' && harborName != 'Area tidak diset') {
          print('🔍 [Nahkoda] PRIORITAS 4: Mencari "$harborName" di catch-polygons...');
          try {
            final catchZones = await ZoneService.getAllCatchPolygons();
            for (var zone in catchZones) {
              if (zone.name.toLowerCase() == harborName.toLowerCase()) {
                print('✅ [Nahkoda] MATCH di catch-polygons! Zone: ${zone.name}');
                if (zone.coordinates.isNotEmpty) {
                  harborCoords = {
                    'lat': zone.coordinates.first.latitude,
                    'lng': zone.coordinates.first.longitude,
                  };
                  print('✅ [Nahkoda] Koordinat dari catch-polygons: $harborCoords');
                  break;
                }
              }
            }
            if (harborCoords == null) {
              print('❌ [Nahkoda] "$harborName" tidak ditemukan di catch-polygons');
            }
          } catch (e) {
            print('❌ [Nahkoda] Error: $e');
          }
        }
        
        // FALLBACK: Gunakan koordinat default
        if (harborCoords == null) {
          print('⚠️ [Nahkoda] FALLBACK: Menggunakan koordinat default');
          harborName = 'Pelabuhan Muara Baru (Default)';
          harborCoords = {
            'lat': -6.1075,
            'lng': 106.7803,
          };
          print('✅ [Nahkoda] Koordinat default: $harborCoords');
        }
        
        print('🔍 [Nahkoda] Final harborCoords: $harborCoords');
        print('🔍 [Nahkoda] ===== END PARSING =====');
        
        // Debug tanggal keberangkatan
        final departureDate = myTrip['tanggalBerangkat'] != null 
            ? DateTime.parse(myTrip['tanggalBerangkat'])
            : DateTime.now();
        print('📅 [Nahkoda] ===== DEBUG TANGGAL =====');
        print('📅 [Nahkoda] Raw tanggalBerangkat: ${myTrip['tanggalBerangkat']}');
        print('📅 [Nahkoda] Parsed departureDate: $departureDate');
        print('📅 [Nahkoda] Current time: ${DateTime.now()}');
        print('📅 [Nahkoda] Time difference: ${departureDate.difference(DateTime.now())}');
        print('📅 [Nahkoda] ===== END DEBUG =====');
        
        // Debug BBM dan Es dari perizinan.operasional
        print('⛽ [Nahkoda] ===== DEBUG BBM & ES =====');
        final perizinan = myTrip['perizinan'];
        final operasional = perizinan?['operasional'];
        print('⛽ [Nahkoda] perizinan: $perizinan');
        print('⛽ [Nahkoda] operasional: $operasional');
        
        final fuelValue = (operasional?['bensinTersedia'] ?? 0).toDouble();
        final iceValue = (operasional?['esTersedia'] ?? 0).toDouble();
        
        print('⛽ [Nahkoda] bensinTersedia: ${operasional?['bensinTersedia']}');
        print('⛽ [Nahkoda] esTersedia: ${operasional?['esTersedia']}');
        print('⛽ [Nahkoda] Converted fuelSupply: $fuelValue');
        print('⛽ [Nahkoda] Converted iceSupply: $iceValue');
        print('⛽ [Nahkoda] ===== END DEBUG =====');
        
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
      print('❌ [NahkodaTracking] Error: $e');
      return null;
    }
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
    // Cek apakah tracking sudah aktif dari provider
    final trackingProvider = Provider.of<TrackingMinimizeProvider>(context, listen: false);
    if (trackingProvider.isTrackingActive) {
      _showAlreadyInTrackingDialog(context);
      return;
    }
    
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
        final userRole = prefs.getString('role') ?? 'nahkoda';
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
        
        final departureDate = tripData['departureDate'] as DateTime;
        final nahkodaId = tripData['nahkodaId'] as int?;
        final awakKapal = tripData['awakKapal'] as List<dynamic>?;
        final status = tripData['status'] as String? ?? '';
        
        // Cek status trip
        final statusLower = status.toLowerCase();
        
        // Jika status 'menunggu_dokumen' -> ke MySchedulesScreen
        if (statusLower == 'menunggu_dokumen') {
          if (context.mounted) {
            NahkodaRoutes.navigateToMySchedules(context);
          }
          return;
        }
        
        // Jika status 'aktif' -> ke MySchedulesScreen (PreTripSimple)
        if (statusLower == 'aktif') {
          if (context.mounted) {
            NahkodaRoutes.navigateToMySchedules(context);
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
        
        // Jika status 'diizinkan' atau 'disetujui' -> ke WaitingScheduleScreen
        if (statusLower == 'diizinkan' || statusLower == 'disetujui') {
          if (context.mounted) {
            _navigateToWaitingSchedule(context, tripData);
          }
          return;
        }
        
        // Cek apakah sudah waktunya untuk mulai tracking berdasarkan role dan user ID
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
          // Buffer aktif, cek cuaca dulu
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

  // Cek cuaca sebelum navigasi langsung ke ActiveTrackingScreen
  Future<void> _checkWeatherAndNavigate(BuildContext context, Map<String, dynamic> tripData) async {
    if (!context.mounted) return;
    
    // Validasi koordinat pelabuhan
    if (tripData['harborCoordinates'] == null) {
      _showErrorDialog(
        context,
        'Data Tidak Lengkap',
        'Koordinat pelabuhan tidak tersedia. Silakan hubungi admin untuk melengkapi data trip.',
      );
      return;
    }
    
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
          'Tidak dapat mengakses data cuaca. Lanjutkan tracking?',
        );
        return;
      }

      final isExtreme = _isWeatherExtreme(weather);

      if (!context.mounted) return;

      if (isExtreme) {
        _showWeatherWarning(context, weather, tripData);
      } else {
        // Cuaca aman, cek status trip untuk routing yang tepat
        final status = tripData['status'] as String? ?? '';
        final statusLower = status.toLowerCase();
        
        print('✅ [Nahkoda] Cuaca aman, routing berdasarkan status: $status');
        
        await Future.delayed(Duration(milliseconds: 300));
        if (!context.mounted) return;
        
        // Routing berdasarkan status setelah cuaca dicek
        if (statusLower == 'berlayar') {
          // Status berlayar -> ActiveTrackingScreen
          _navigateToActiveTracking(context, tripData);
        } else if (statusLower == 'disetujui' || statusLower == 'diizinkan') {
          // Status disetujui/diizinkan -> WaitingScheduleScreen
          _navigateToWaitingSchedule(context, tripData);
        } else if (statusLower == 'aktif' || statusLower == 'menunggu_dokumen') {
          // Status aktif/menunggu_dokumen -> MySchedulesScreen
          NahkodaRoutes.navigateToMySchedules(context);
        } else {
          // Fallback: ke ActiveTrackingScreen
          _navigateToActiveTracking(context, tripData);
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
            'Tidak dapat memeriksa kondisi cuaca. Lanjutkan tracking?',
          );
        }
      }
    }
  }

  void _navigateToActiveTracking(BuildContext context, Map<String, dynamic> tripData) async {
    // Get user data for userRole and userName
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    final userRole = prefs.getString('role') ?? 'Nahkoda';
    String userName = tripData['captainName'] ?? 'Nahkoda'; // Default ke captain name dari trip
    
    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString);
        // Ambil nama dari user_data, fallback ke captain name dari trip
        userName = userData['nama'] ?? tripData['captainName'] ?? 'Nahkoda';
        print('👤 [Navigate] userName from user_data: $userName');
      } catch (e) {
        print('❌ Error parsing user_data: $e');
      }
    }
    
    // Debug sebelum navigasi
    print('🚀 [Navigate] ===== SENDING TO ACTIVE TRACKING =====');
    print('🚀 [Navigate] userName: $userName');
    print('🚀 [Navigate] userRole: $userRole');
    print('🚀 [Navigate] captainName: ${tripData['captainName']}');
    print('🚀 [Navigate] fuelSupply from tripData: ${tripData['fuelSupply']}');
    print('🚀 [Navigate] iceSupply from tripData: ${tripData['iceSupply']}');
    print('🚀 [Navigate] ===== END =====');
    
    NahkodaRoutes.navigateToActiveTracking(
      context,
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
    );
  }

  void _navigateToWaitingSchedule(BuildContext context, Map<String, dynamic> tripData) async {
    // Validasi koordinat pelabuhan sebelum navigasi
    if (tripData['harborCoordinates'] == null) {
      _showErrorDialog(
        context,
        'Data Tidak Lengkap',
        'Koordinat pelabuhan tidak tersedia. Silakan hubungi admin untuk melengkapi data trip.',
      );
      return;
    }
    
    // Get user data for userRole and userName
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    final userRole = prefs.getString('role') ?? 'Nahkoda';
    String userName = tripData['captainName'] ?? 'Nahkoda';
    
    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString);
        userName = userData['nama'] ?? tripData['captainName'] ?? 'Nahkoda';
      } catch (e) {
        print('❌ Error parsing user_data: $e');
      }
    }
    
    // Debug sebelum navigasi
    print('⏰ [WaitingSchedule] ===== SENDING DATA =====');
    print('⏰ [WaitingSchedule] userName: $userName');
    print('⏰ [WaitingSchedule] fuelSupply: ${tripData['fuelSupply']}');
    print('⏰ [WaitingSchedule] iceSupply: ${tripData['iceSupply']}');
    print('⏰ [WaitingSchedule] ===== END =====');
    
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

  void _navigateToWaitingApproval(BuildContext context, Map<String, dynamic> tripData) {
    // Debug sebelum navigasi
    print('⏳ [WaitingApproval] ===== SENDING DATA =====');
    print('⏳ [WaitingApproval] fuelSupply: ${tripData['fuelSupply']}');
    print('⏳ [WaitingApproval] iceSupply: ${tripData['iceSupply']}');
    print('⏳ [WaitingApproval] ===== END =====');
    
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
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
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
                // Animated Icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade700],
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 110,
                      height: 110,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const Icon(Icons.cloud, color: Colors.white, size: 50),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  'Memeriksa Kondisi Cuaca',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4F9C),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Progress Steps
                _buildProgressStep(Icons.location_on, 'Mendapatkan lokasi GPS', true),
                const SizedBox(height: 8),
                _buildProgressStep(Icons.cloud_queue, 'Mengambil data cuaca', true),
                const SizedBox(height: 8),
                _buildProgressStep(Icons.waves, 'Memeriksa kondisi laut', true),
                
                const SizedBox(height: 16),
                Text(
                  'Memastikan kondisi aman untuk melaut...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProgressStep(IconData icon, String label, bool isActive) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.shade50 : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? Colors.blue.shade700 : Colors.grey.shade400,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isActive ? Colors.blue.shade700 : Colors.grey.shade500,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        if (isActive)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
          ),
      ],
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