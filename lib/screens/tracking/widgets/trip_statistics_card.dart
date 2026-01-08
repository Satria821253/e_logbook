import 'package:e_logbook/utils/responsive_helper.dart';
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
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.responsiveWidth(context, mobile: 16, tablet: 20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              lottieAsset: 'assets/animations/clock.json',
              label: 'Durasi Trip',
              value: _formatDuration(tripDuration),
              color: Colors.blue,
            ),
          ),
          SizedBox(width: ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16)),
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
  }) {
    return Builder(
      builder: (context) => Container(
        constraints: BoxConstraints(
          minHeight: ResponsiveHelper.responsiveHeight(context, mobile: 170, tablet: 200),
        ),
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.responsiveHeight(context, mobile: 20, tablet: 24),
          horizontal: ResponsiveHelper.responsiveWidth(context, mobile: 16, tablet: 20),
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16),
          ),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: ResponsiveHelper.responsiveWidth(context, mobile: 36, tablet: 44),
              height: ResponsiveHelper.responsiveHeight(context, mobile: 36, tablet: 44),
              child: Transform.scale(
                scale: lottieAsset.contains('GPS') ? 3.5 : 2.0,
                child: Lottie.asset(
                  lottieAsset,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
            ),

            SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 25, tablet: 30)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 11, tablet: 13),
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 4, tablet: 6)),
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 16, tablet: 18),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}