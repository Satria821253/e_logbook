import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class VesselHeaderCard extends StatelessWidget {
  final String vesselName;
  final String vesselNumber;
  final VoidCallback onSummaryTap;

  const VesselHeaderCard({
    super.key,
    required this.vesselName,
    required this.vesselNumber,
    required this.onSummaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double sp(double size) => size * (width / 390);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sp(16)),
      child: Column(
        children: [
          // 🚢 ICON KAPAL (FOCUS UTAMA)
          SizedBox(
            width: sp(130),
            height: sp(130),
            child: Lottie.asset(
              'assets/animations/PreTrip.json', // pastikan path benar
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
          // 🚢 NAMA KAPAL (DOMINAN)
          Text(
            vesselName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: sp(19),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B4F9C),
            ),
          ),
          Text(
            'No. Kapal: $vesselNumber',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: sp(12),
              color: Colors.grey[600],
            ),
          ),
          TextButton.icon(
            onPressed: onSummaryTap,
            icon: const Icon(Icons.bar_chart, size: 18),
            label: const Text('Ringkasan Trip'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1B4F9C),
              padding: EdgeInsets.symmetric(
                horizontal: sp(12),
                vertical: sp(6),
              ),
              textStyle: TextStyle(fontSize: sp(13)),
            ),
          ),
        ],
      ),
    );
  }
}
