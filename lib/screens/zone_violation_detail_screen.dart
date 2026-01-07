import 'package:e_logbook/services/location_tracking_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen detail pelanggaran zona real-time
class ZoneViolationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> zoneInfo;
  final VoidCallback onDismiss;

  const ZoneViolationDetailScreen({
    super.key,
    required this.zoneInfo,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double fs(double size) => size * (width / 390);
    double sp(double size) => size * (width / 390);

    final distance = zoneInfo['distance'] as double;
    final zoneRadius = zoneInfo['zoneRadius'] as double; 
    final excessDistance = zoneInfo['excessDistance'] as double;
    final harborName = zoneInfo['harborName'] as String;
    final vesselName = LocationTrackingService.currentVessel ?? 'Unknown';
    
    final position = LocationTrackingService.lastPosition;
    final lat = position?.latitude ?? 0.0;
    final lng = position?.longitude ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: Text(
          '🚨 Pelanggaran Zona',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: fs(18),
          ),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              onDismiss();
              Navigator.pop(context);
            },
            tooltip: 'Tutup & Matikan Alarm',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Warning
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(sp(24)),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(sp(30)),
                  bottomRight: Radius.circular(sp(30)),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: fs(80),
                    color: Colors.white,
                  ),
                  SizedBox(height: sp(12)),
                  Text(
                    'KAPAL DI LUAR ZONA!',
                    style: TextStyle(
                      fontSize: fs(24),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: sp(8)),
                  Text(
                    'Segera kembali ke zona pengawasan pelabuhan',
                    style: TextStyle(
                      fontSize: fs(14),
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: sp(24)),

            // Info Cards
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sp(16)),
              child: Column(
                children: [
                  // Kapal Info
                  _buildInfoCard(
                    context,
                    icon: Icons.directions_boat,
                    title: 'Informasi Kapal',
                    items: [
                      _InfoItem('Nama Kapal', vesselName),
                      _InfoItem('Pelabuhan', harborName),
                      _InfoItem(
                        'Waktu Deteksi',
                        DateFormat('dd MMM yyyy, HH:mm:ss').format(DateTime.now()),
                      ),
                    ],
                    sp: sp,
                    fs: fs,
                  ),

                  SizedBox(height: sp(16)),

                  // Distance Info
                  _buildInfoCard(
                    context,
                    icon: Icons.place,
                    title: 'Informasi Jarak',
                    items: [
                      _InfoItem(
                        'Jarak dari Pelabuhan',
                        '${distance.toStringAsFixed(2)} km',
                        valueColor: Colors.orange,
                      ),
                      _InfoItem(
                        'Batas Zona Aman',
                        '${zoneRadius.toStringAsFixed(2)} km',
                        valueColor: Colors.green,
                      ),
                      _InfoItem(
                        'Kelebihan Jarak',
                        '${excessDistance.toStringAsFixed(2)} km',
                        valueColor: Colors.red,
                        isBold: true,
                      ),
                    ],
                    sp: sp,
                    fs: fs,
                  ),

                  SizedBox(height: sp(16)),

                  // Koordinat Info
                  _buildInfoCard(
                    context,
                    icon: Icons.location_on,
                    title: 'Koordinat Saat Ini',
                    items: [
                      _InfoItem('Latitude', lat.toStringAsFixed(6)),
                      _InfoItem('Longitude', lng.toStringAsFixed(6)),
                    ],
                    sp: sp,
                    fs: fs,
                  ),

                  SizedBox(height: sp(24)),

                  // Peringatan
                  Container(
                    padding: EdgeInsets.all(sp(16)),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(sp(12)),
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade900),
                        SizedBox(width: sp(12)),
                        Expanded(
                          child: Text(
                            'Melanggar zona pengawasan dapat dikenakan sanksi sesuai peraturan yang berlaku.',
                            style: TextStyle(
                              fontSize: fs(12),
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: sp(24)),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openInGoogleMaps(lat, lng),
                          icon: const Icon(Icons.map),
                          label: const Text('Buka Maps'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4F9C),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: sp(16)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(sp(12)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: sp(12)),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            onDismiss();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Mengerti'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: sp(16)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(sp(12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: sp(32)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<_InfoItem> items,
    required double Function(double) sp,
    required double Function(double) fs,
  }) {
    return Container(
      padding: EdgeInsets.all(sp(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sp(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1B4F9C), size: fs(24)),
              SizedBox(width: sp(12)),
              Text(
                title,
                style: TextStyle(
                  fontSize: fs(16),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B4F9C),
                ),
              ),
            ],
          ),
          SizedBox(height: sp(16)),
          ...items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: sp(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: fs(13),
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: fs(13),
                        fontWeight: item.isBold ? FontWeight.bold : FontWeight.w600,
                        color: item.valueColor ?? Colors.black87,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _openInGoogleMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}

class _InfoItem {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  _InfoItem(
    this.label,
    this.value, {
    this.valueColor,
    this.isBold = false,
  });
}