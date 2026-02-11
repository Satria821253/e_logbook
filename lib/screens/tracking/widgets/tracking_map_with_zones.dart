import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/catch_polygon_model.dart';
import '../../../models/harbor_zone_model.dart';
import '../../../models/trip_model.dart';
import '../../../services/api/zone_service.dart';


class TrackingMapWithZones extends StatefulWidget {
  final TripModel trip;
  final LatLng currentPosition;
  final Widget vesselMarker;

  const TrackingMapWithZones({
    super.key,
    required this.trip,
    required this.currentPosition,
    required this.vesselMarker,
  });

  @override
  State<TrackingMapWithZones> createState() => _TrackingMapWithZonesState();
}

class _TrackingMapWithZonesState extends State<TrackingMapWithZones> {
  List<CatchPolygonModel> _catchZones = [];
  List<HarborZoneModel> _harborZones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      final catchZones = await ZoneService.getCatchPolygonsByNames(
        widget.trip.areaTangkap.nama,
      );
      final harborZones = await ZoneService.getActiveHarborZones();
      
      setState(() {
        _catchZones = catchZones;
        _harborZones = harborZones;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading zones: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: widget.currentPosition,
            initialZoom: 10,
            maxZoom: 18,
            minZoom: 6,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.elogbook',
            ),
            
            // Zona tangkap polygons
            if (_catchZones.isNotEmpty)
              PolygonLayer(
                polygons: _catchZones.map((zone) {
                  final color = _parseColor(zone.color);
                  return Polygon(
                    points: zone.coordinates,
                    color: color.withOpacity(0.2),
                    borderColor: color,
                    borderStrokeWidth: 2,
                  );
                }).toList(),
              ),

            // Harbor zones (circles)
            if (_harborZones.isNotEmpty)
              CircleLayer(
                circles: _harborZones
                    .where((z) => z.isCircle && z.centerPoint != null)
                    .map((zone) {
                  final color = _parseColor(zone.color);
                  return CircleMarker(
                    point: zone.centerPoint!,
                    radius: zone.radiusMeters ?? 1000,
                    color: zone.isRestricted
                        ? Colors.red.withOpacity(0.2)
                        : color.withOpacity(0.15),
                    borderColor: zone.isRestricted ? Colors.red : color,
                    borderStrokeWidth: 2,
                  );
                }).toList(),
              ),

            // Harbor zones (polygons)
            if (_harborZones.isNotEmpty)
              PolygonLayer(
                polygons: _harborZones
                    .where((z) => z.isPolygon && z.polygonCoordinates != null)
                    .map((zone) {
                  final color = _parseColor(zone.color);
                  return Polygon(
                    points: zone.polygonCoordinates!,
                    color: zone.isRestricted
                        ? Colors.red.withOpacity(0.2)
                        : color.withOpacity(0.15),
                    borderColor: zone.isRestricted ? Colors.red : color,
                    borderStrokeWidth: 2,
                  );
                }).toList(),
              ),

            // Vessel marker
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.currentPosition,
                  width: 50,
                  height: 50,
                  child: widget.vesselMarker,
                ),
              ],
            ),
          ],
        ),

        // Zone info overlay
        if (_catchZones.isNotEmpty || _harborZones.isNotEmpty)
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
              constraints: const BoxConstraints(maxWidth: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_catchZones.isNotEmpty) ...[
                    const Text(
                      'Zona Tangkap',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._catchZones.map((zone) => _buildZoneLegend(zone.name, zone.color)),
                  ],
                  if (_catchZones.isNotEmpty && _harborZones.isNotEmpty)
                    const Divider(height: 16),
                  if (_harborZones.isNotEmpty) ...[
                    const Text(
                      'Zona Pelabuhan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._harborZones.take(3).map((zone) => _buildZoneLegend(
                      zone.name,
                      zone.color,
                      isRestricted: zone.isRestricted,
                    )),
                  ],
                ],
              ),
            ),
          ),

        // Loading indicator
        if (_isLoading)
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Loading zones...', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildZoneLegend(String name, String hexColor, {bool isRestricted = false}) {
    final color = isRestricted ? Colors.red : _parseColor(hexColor);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
