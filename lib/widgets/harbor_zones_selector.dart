import 'package:e_logbook/constants/indonesia_harbors.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:flutter/material.dart';

class HarborZoneSelector extends StatelessWidget {
  final String selectedHarbor;
  final Function(String?) onChanged;
  final double? currentLat;
  final double? currentLng;

  const HarborZoneSelector({
    super.key,
    required this.selectedHarbor,
    required this.onChanged,
    this.currentLat,
    this.currentLng,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double fs(double size) => size * (width / 390);
    double sp(double size) => size * (width / 390);

    // Get nearest harbor jika ada koordinat
    String? nearestHarborInfo;
    if (currentLat != null && currentLng != null) {
      final nearest = IndonesiaHarbors.findNearestHarbor(
        currentLat!,
        currentLng!,
      );
      if (nearest != null) {
        final distance = nearest.getDistanceFromCenter(
          currentLat!,
          currentLng!,
        );
        nearestHarborInfo =
            '📍 Terdekat: ${nearest.name} (~${distance.toStringAsFixed(1)} km)';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16),
            ),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedHarbor,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.anchor, color: Color(0xFF1B4F9C)),
              border: InputBorder.none,
              labelStyle: TextStyle(
                fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16),
              ),
            ),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            style: TextStyle(
              fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16), 
              color: Colors.black87,
            ),
            items: IndonesiaHarbors.harborNames.map((harborName) {
              final harbor = IndonesiaHarbors.getHarborByFullName(harborName);
              return DropdownMenuItem<String>(
                value: harborName,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        harbor?.name ?? harborName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
              
            }).toList(),
            onChanged: onChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Pilih pelabuhan';
              }
              return null;
            },
          ),
        ),

        // Info pelabuhan terpilih
        if (selectedHarbor.isNotEmpty) ...[
          SizedBox(height: sp(8)),
          _buildHarborInfo(selectedHarbor, sp, fs),
        ],

        // Info nearest harbor
        if (nearestHarborInfo != null) ...[
          SizedBox(height: sp(8)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: sp(12), vertical: sp(8)),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(sp(8)),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.near_me, color: Colors.blue, size: fs(16)),
                SizedBox(width: sp(8)),
                Expanded(
                  child: Text(
                    nearestHarborInfo,
                    style: TextStyle(fontSize: fs(12), color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHarborInfo(
    String harborName,
    double Function(double) sp,
    double Function(double) fs,
  ) {
    final harbor = IndonesiaHarbors.getHarborByFullName(harborName);
    if (harbor == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(sp(12)),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(sp(8)),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: sp(8),
                  vertical: sp(4),
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(sp(4)),
                ),
                child: Text(
                  harbor.harborType,
                  style: TextStyle(
                    fontSize: fs(10),
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: sp(8)),
              Text(
                'Radius: ${harbor.radiusKm.toInt()} km',
                style: TextStyle(
                  fontSize: fs(12),
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          SizedBox(height: sp(8)),
          Text(
            harbor.description,
            style: TextStyle(fontSize: fs(11), color: Colors.grey[700]),
          ),
          if (harbor.allowedFishTypes.isNotEmpty) ...[
            SizedBox(height: sp(8)),
            Wrap(
              spacing: sp(6),
              runSpacing: sp(6),
              children: harbor.allowedFishTypes.take(5).map((fishType) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: sp(8),
                    vertical: sp(4),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(sp(4)),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    fishType,
                    style: TextStyle(fontSize: fs(10), color: Colors.blue[800]),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
