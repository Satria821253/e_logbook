import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:e_logbook/utils/trip_duration_helper.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Widget untuk menampilkan statistik trip
class TripStatisticsCard extends StatelessWidget {
  final DateTime departureDate;
  final DateTime? estimatedReturnDate; // Dari BE (prioritas)
  final int? estimatedDurationDays; // Fallback
  final double? currentDistance;
  final bool isViolating;

  const TripStatisticsCard({
    super.key,
    required this.departureDate,
    this.estimatedReturnDate,
    this.estimatedDurationDays,
    this.currentDistance,
    this.isViolating = false,
  });

  @override
  Widget build(BuildContext context) {
    final helper = TripDurationHelper(
      departureDate: departureDate,
      estimatedReturnDate: estimatedReturnDate,
      estimatedDurationDays: estimatedDurationDays,
    );
    
    // DEBUG
    print('\n========== TRIP STATISTICS DEBUG ==========');
    print('📅 Departure Date: $departureDate');
    print('📅 Estimated Return: ${estimatedReturnDate ?? "NULL (using fallback)"}');
    print('📅 Duration Days: $estimatedDurationDays');
    print('📅 Calculated Return: ${helper.getEstimatedReturnDate()}');
    print('⏱️  Remaining Time: ${helper.formatRemainingTime()}');
    print('🚨 Is Overtime: ${helper.isOvertime()}');
    print('🎨 Status Color: ${helper.getStatusColor()}');
    print('==========================================\n');
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.width(context, mobile: 16, tablet: 20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              lottieAsset: 'assets/animations/clock.json',
              label: helper.getStatusLabel(),
              value: helper.formatRemainingTime(),
              color: helper.getStatusColor(),
            ),
          ),
          SizedBox(width: ResponsiveHelper.width(context, mobile: 12, tablet: 16)),
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
          minHeight: ResponsiveHelper.height(context, mobile: 170, tablet: 200),
        ),
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.height(context, mobile: 20, tablet: 24),
          horizontal: ResponsiveHelper.width(context, mobile: 16, tablet: 20),
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.width(context, mobile: 12, tablet: 16),
          ),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: ResponsiveHelper.width(context, mobile: 36, tablet: 44),
              height: ResponsiveHelper.height(context, mobile: 36, tablet: 44),
              child: Transform.scale(
                scale: lottieAsset.contains('GPS') ? 3.5 : 2.0,
                child: Lottie.asset(
                  lottieAsset,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
            ),

            SizedBox(height: ResponsiveHelper.height(context, mobile: 25, tablet: 30)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, mobile: 11, tablet: 13),
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: ResponsiveHelper.height(context, mobile: 4, tablet: 6)),
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveHelper.font(context, mobile: 16, tablet: 18),
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