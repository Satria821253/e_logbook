import 'package:e_logbook/constants/indonesia_harbors.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class HarborZoneMapView extends StatefulWidget {
  final String selectedHarborName;
  final double? currentLat;
  final double? currentLng;

  const HarborZoneMapView({
    super.key,
    required this.selectedHarborName,
    this.currentLat,
    this.currentLng,
  });

  @override
  State<HarborZoneMapView> createState() => _HarborZoneMapViewState();
}

class _HarborZoneMapViewState extends State<HarborZoneMapView> {
  GoogleMapController? _mapController;
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};
  LatLng _initialPosition = const LatLng(-2.5, 118.0);

  @override
  void initState() {
    super.initState();
    _loadHarborZone();
  }

  @override
  void didUpdateWidget(HarborZoneMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedHarborName != widget.selectedHarborName ||
        oldWidget.currentLat != widget.currentLat ||
        oldWidget.currentLng != widget.currentLng) {
      _loadHarborZone();
    }
  }

  void _loadHarborZone() {
    final harbor = IndonesiaHarbors.getHarborByFullName(widget.selectedHarborName);
    
    if (harbor == null) {
      setState(() {
        _circles = {};
        _markers = {};
      });
      return;
    }

    // Buat circle untuk zona pelabuhan
    final zoneCircle = Circle(
      circleId: CircleId(harbor.id),
      center: harbor.centerPoint,
      radius: harbor.radiusKm * 1000, // Convert km to meters
      strokeWidth: 3,
      strokeColor: const Color(0xFF1B4F9C),
      fillColor: const Color(0xFF1B4F9C).withOpacity(0.2),
    );

    // Marker pelabuhan
    final harborMarker = Marker(
      markerId: MarkerId('harbor_${harbor.id}'),
      position: harbor.centerPoint,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: harbor.name,
        snippet: 'Radius: ${harbor.radiusKm} km',
      ),
    );

    Set<Marker> markers = {harborMarker};

    // Marker lokasi tangkapan
    if (widget.currentLat != null && widget.currentLng != null) {
      final isInZone = harbor.isLocationInZone(
        widget.currentLat!,
        widget.currentLng!,
      );

      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(widget.currentLat!, widget.currentLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isInZone ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: isInZone ? 'Lokasi Tangkapan (Dalam Zona)' : 'Lokasi Tangkapan (Luar Zona)',
            snippet: '${harbor.getDistanceFromCenter(widget.currentLat!, widget.currentLng!).toStringAsFixed(2)} km dari pelabuhan',
          ),
        ),
      );
    }

    setState(() {
      _circles = {zoneCircle};
      _markers = markers;
    });

    // Animate camera ke zona
    if (_mapController != null) {
      if (widget.currentLat != null && widget.currentLng != null) {
        // Jika ada lokasi tangkapan, fokus ke area yang mencakup keduanya
        final bounds = LatLngBounds(
          southwest: LatLng(
            widget.currentLat! < harbor.centerPoint.latitude
                ? widget.currentLat!
                : harbor.centerPoint.latitude,
            widget.currentLng! < harbor.centerPoint.longitude
                ? widget.currentLng!
                : harbor.centerPoint.longitude,
          ),
          northeast: LatLng(
            widget.currentLat! > harbor.centerPoint.latitude
                ? widget.currentLat!
                : harbor.centerPoint.latitude,
            widget.currentLng! > harbor.centerPoint.longitude
                ? widget.currentLng!
                : harbor.centerPoint.longitude,
          ),
        );

        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      } else {
        // Fokus ke pelabuhan saja
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(harbor.centerPoint, 8),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double fs(double size) => size * (width / 390);
    double sp(double size) => size * (width / 390);

    final harbor = IndonesiaHarbors.getHarborByFullName(widget.selectedHarborName);
    final isInZone = harbor != null &&
        widget.currentLat != null &&
        widget.currentLng != null &&
        harbor.isLocationInZone(widget.currentLat!, widget.currentLng!);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(sp(12)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 5,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _loadHarborZone();
            },
            circles: _circles,
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),

          // Info Card
          Positioned(
            top: sp(8),
            left: sp(8),
            right: sp(8),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: sp(12), vertical: sp(8)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(sp(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: sp(12),
                        height: sp(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4F9C).withOpacity(0.5),
                          border: Border.all(
                            color: const Color(0xFF1B4F9C),
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: sp(8)),
                      Expanded(
                        child: Text(
                          widget.selectedHarborName,
                          style: TextStyle(
                            fontSize: fs(12),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B4F9C),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (widget.currentLat != null && widget.currentLng != null && harbor != null) ...[
                    SizedBox(height: sp(4)),
                    Row(
                      children: [
                        Icon(
                          isInZone ? Icons.check_circle : Icons.warning,
                          size: fs(14),
                          color: isInZone ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: sp(4)),
                        Expanded(
                          child: Text(
                            isInZone
                                ? 'Dalam zona penangkapan'
                                : 'Di luar zona penangkapan!',
                            style: TextStyle(
                              fontSize: fs(11),
                              color: isInZone ? Colors.green[700] : Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Legend
          Positioned(
            bottom: sp(8),
            right: sp(8),
            child: Container(
              padding: EdgeInsets.all(sp(8)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(sp(6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: Colors.blue, size: fs(16)),
                      SizedBox(width: sp(4)),
                      Text('Pelabuhan', style: TextStyle(fontSize: fs(10))),
                    ],
                  ),
                  if (widget.currentLat != null && widget.currentLng != null) ...[
                    SizedBox(height: sp(4)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: isInZone ? Colors.green : Colors.red,
                          size: fs(16),
                        ),
                        SizedBox(width: sp(4)),
                        Text('Lokasi Tangkapan', style: TextStyle(fontSize: fs(10))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}