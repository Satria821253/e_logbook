import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../routes/nahkoda_routes.dart';

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
      
      // Close loading
      Navigator.pop(context);
      
      if (tripData == null) {
        _showNoTripDialog(context);
      } else {
        // Navigate to pre-trip form with trip data
        Navigator.pushNamed(
          context,
          '/pre-trip-form',
          arguments: tripData,
        );
      }
    } catch (e) {
      // Close loading
      Navigator.pop(context);
      _showNoTripDialog(context);
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