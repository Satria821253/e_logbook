import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Widget untuk menampilkan statistik trip
class TripStatisticsCard extends StatelessWidget {
  final Duration tripDuration;
  final double? currentDistance;
  final bool isViolating;

  const TripStatisticsCard({
    super.key,
    required this.tripDuration,
    this.currentDistance,
    this.isViolating = false,
  });

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double fs(double size) => size * (width / 390);
    double sp(double size) => size * (width / 390);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: sp(16)),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              lottieAsset: 'assets/animations/clock.json',
              label: 'Durasi Trip',
              value: _formatDuration(tripDuration),
              color: Colors.blue,
              sp: sp,
              fs: fs,
            ),
          ),
          SizedBox(width: sp(12)),
          Expanded(
            child: _buildStatCard(
              lottieAsset: isViolating
                  ? 'assets/animations/GPSRED.json'
                  : 'assets/animations/GPSBLUE.json',
              label: 'Jarak dari Zona',
              value: currentDistance != null
                  ? '${currentDistance!.toStringAsFixed(1)} km'
                  : '-',
              color: isViolating ? Colors.red : Colors.green,
              sp: sp,
              fs: fs,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String lottieAsset,
    required String label,
    required String value,
    required Color color,
    required double Function(double) sp,
    required double Function(double) fs,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: sp(170)),
      padding: EdgeInsets.symmetric(
    vertical: sp(20),
    horizontal: sp(16),
  ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(sp(12)),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: fs(36),
            height: fs(36),
            child: Transform.scale(
              scale: lottieAsset.contains('GPS') ? 3.5 : 2.0,
              child: Lottie.asset(
                lottieAsset,
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
          ),

          SizedBox(height: sp(25)),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: fs(11), color: Colors.grey[700]),
          ),
          SizedBox(height: sp(4)),
          Text(
            value,
            style: TextStyle(
              fontSize: fs(16),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
