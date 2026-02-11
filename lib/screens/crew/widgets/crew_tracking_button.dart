import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../constants/tracking_constants.dart';
import '../../../services/api/trip_service.dart';
import '../../tracking/pre_trip_fromscreen.dart';

class CrewTrackingButton extends StatelessWidget {
  const CrewTrackingButton({super.key});

  Future<Map<String, dynamic>?> _getActiveTripData() async {
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
        
        // Cari trip yang sedang berlayar untuk user ini
        final activeTrip = allTrips.firstWhere(
          (trip) {
            final nahkodaId = trip['nahkodaId'];
            final awakKapal = trip['awakKapal'] as List?;
            final status = trip['status']?.toLowerCase();
            
            final isMyTrip = (nahkodaId == currentUserId) ||
                             (awakKapal != null && awakKapal.contains(currentUserId));
            
            return isMyTrip && status == 'berlayar';
          },
          orElse: () => {},
        );
        
        if (activeTrip.isEmpty) return null;
        
        return {
          'tripId': activeTrip['id'],
          'vesselName': activeTrip['kapal']?['namaKapal'] ?? 'Kapal',
          'vesselNumber': activeTrip['kapal']?['nomorRegistrasi'] ?? '-',
          'crewCount': (activeTrip['awakKapal'] as List?)?.length ?? 0,
          'departureHarbor': activeTrip['areaTangkap']?['nama'] ?? '-',
          'estimatedDuration': activeTrip['durasi'] ?? 0,
          'departureDate': activeTrip['tanggalBerangkat'] != null 
              ? DateTime.parse(activeTrip['tanggalBerangkat'])
              : DateTime.now(),
          'estimatedReturnDate': activeTrip['estimasiPulang'] != null
              ? DateTime.parse(activeTrip['estimasiPulang'])
              : DateTime.now(),
          'fuelSupply': 0.0,
          'iceSupply': 0.0,
          'status': activeTrip['status'],
          'nahkodaId': activeTrip['nahkodaId'],
          'awakKapal': activeTrip['awakKapal'],
        };
      }
      
      return null;
    } catch (e) {
      print('❌ [CrewTracking] Error: $e');
      return null;
    }
  }

  void _showNotBerlayarDialog(BuildContext context) {
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
              child: Text('Belum Berlayar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: const Text(
          'Tracking hanya dapat diakses saat trip sudah berstatus "Berlayar".',
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final tripData = await _getActiveTripData();
      
      if (context.mounted) Navigator.pop(context);
      
      if (tripData == null) {
        if (context.mounted) _showNotBerlayarDialog(context);
      } else {
        // Validasi akses tracking
        final prefs = await SharedPreferences.getInstance();
        final userDataString = prefs.getString('user_data');
        final userRole = prefs.getString('role') ?? 'crew';
        int? currentUserId;
        
        if (userDataString != null) {
          final userData = json.decode(userDataString);
          currentUserId = userData['id'];
        }
        
        if (currentUserId == null) {
          if (context.mounted) _showNotBerlayarDialog(context);
          return;
        }
        
        final canAccess = TrackingConstants.canAccessTracking(
          role: userRole,
          userId: currentUserId,
          nahkodaId: tripData['nahkodaId'],
          awakKapal: tripData['awakKapal'],
          departureDate: tripData['departureDate'],
          status: tripData['status'],
        );
        
        if (!canAccess) {
          if (context.mounted) _showNotBerlayarDialog(context);
        } else {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PreTripFormScreen(tripData: tripData),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ [CrewTracking] Error: $e');
      if (context.mounted) {
        Navigator.pop(context);
        await Future.delayed(Duration(milliseconds: 300));
        if (context.mounted) _showNotBerlayarDialog(context);
      }
    }
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
