import 'package:e_logbook/screens/tracking/animated_vassel_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';

// ✅ WIDGET BARU: Tidak bergantung pada IndonesiaHarbors
class RealTimeZoneMapWithCoordinates extends StatelessWidget {
  final Position currentPosition;
  final double harborLat;
  final double harborLng;
  final String harborName;
  final double zoneRadius; // dalam km
  final bool isViolating;

  const RealTimeZoneMapWithCoordinates({
    super.key,
    required this.currentPosition,
    required this.harborLat,
    required this.harborLng,
    required this.harborName,
    required this.zoneRadius,
    required this.isViolating,
  });

  @override
  Widget build(BuildContext context) {
    final harborCenter = latlong.LatLng(harborLat, harborLng);
    final vesselPosition = latlong.LatLng(
      currentPosition.latitude,
      currentPosition.longitude,
    );

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: vesselPosition,
            initialZoom: 11,
            maxZoom: 18,
            minZoom: 8,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.elogbook',
            ),

            CircleLayer(
              circles: [
                CircleMarker(
                  point: harborCenter,
                  radius: zoneRadius * 1000,
                  color: isViolating
                      ? Colors.red.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                  borderColor: isViolating ? Colors.red : Colors.green,
                  borderStrokeWidth: 2,
                ),
              ],
            ),

            MarkerLayer(
              markers: [
                Marker(
                  point: harborCenter,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.anchor,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                Marker(
                  point: vesselPosition,
                  width: 50,
                  height: 50,
                  child: AnimatedVesselMarke(isViolating: isViolating),
                ),
              ],
            ),

            PolylineLayer(
              polylines: [
                Polyline(
                  points: [harborCenter, vesselPosition],
                  strokeWidth: 2,
                  color: isViolating
                      ? Colors.red.withOpacity(0.6)
                      : Colors.blue.withOpacity(0.6),
                  pattern: const StrokePattern.dotted(),
                ),
              ],
            ),
          ],
        ),

        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(
                  Icons.anchor,
                  harborName,
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildLegendItem(
                  Icons.directions_boat,
                  'Kapal Anda',
                  isViolating ? Colors.red : Colors.green,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isViolating ? Colors.red : Colors.green,
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Zona ${zoneRadius.toInt()} km',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isViolating ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isViolating ? Icons.warning : Icons.check_circle,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isViolating ? 'DI LUAR ZONA' : 'DALAM ZONA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
  
}
