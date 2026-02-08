import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../../tracking/widgets/emergency_button.dart';
import '../../../constants/zones.dart';

class CrewActiveTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;

  const CrewActiveTrackingScreen({Key? key, required this.tripData}) : super(key: key);

  @override
  State<CrewActiveTrackingScreen> createState() => _CrewActiveTrackingScreenState();
}

class _CrewActiveTrackingScreenState extends State<CrewActiveTrackingScreen> {
  Position? _currentPosition;
  String _tripStatus = 'Berlayar';
  Timer? _locationTimer;
  bool _isTracking = true;
  bool _isSendingSOS = false;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  bool _isInRestrictedZone = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmPlaying = false;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
    _initializeMap();
  }

  void _initializeMap() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _updateMarkers();
      _addRestrictedZones();
    });
  }

  void _updateMarkers() {
    if (_currentPosition == null) return;
    
    _markers.clear();
    _markers.add(
      Marker(
        markerId: MarkerId('vessel'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _isInRestrictedZone ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen,
        ),
        infoWindow: InfoWindow(
          title: widget.tripData['vesselName'] ?? 'Kapal',
          snippet: 'Posisi Saat Ini',
        ),
      ),
    );
  }

  void _addRestrictedZones() {
    _circles.clear();
    for (var zone in restrictedZones) {
      _circles.add(
        Circle(
          circleId: CircleId(zone['name']),
          center: LatLng(zone['lat'], zone['lng']),
          radius: zone['radius'],
          fillColor: Colors.red.withOpacity(0.2),
          strokeColor: Colors.red,
          strokeWidth: 2,
        ),
      );
    }
  }

  void _checkZoneViolation() {
    if (_currentPosition == null) return;

    bool inRestrictedZone = false;
    for (var zone in restrictedZones) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        zone['lat'],
        zone['lng'],
      );

      if (distance <= zone['radius']) {
        inRestrictedZone = true;
        break;
      }
    }

    if (inRestrictedZone && !_isInRestrictedZone) {
      setState(() => _isInRestrictedZone = true);
      _playAlarm();
      _showZoneWarning();
    } else if (!inRestrictedZone && _isInRestrictedZone) {
      setState(() => _isInRestrictedZone = false);
      _stopAlarm();
    }
  }

  Future<void> _playAlarm() async {
    if (_isAlarmPlaying) return;
    _isAlarmPlaying = true;
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/alarm.m4a'));
    } catch (e) {
      print('Error playing alarm: $e');
    }
  }

  Future<void> _stopAlarm() async {
    _isAlarmPlaying = false;
    await _audioPlayer.stop();
  }

  void _showZoneWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.red,
        title: Column(
          children: [
            Icon(Icons.warning_amber, color: Colors.white, size: 60),
            SizedBox(height: 12),
            Text(
              '⚠️ PERINGATAN ZONA!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Anda memasuki zona terlarang!\n\nSegera keluar dari area ini.',
          style: TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _stopAlarm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              minimumSize: Size(double.infinity, 45),
            ),
            child: Text('MENGERTI', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _updateMarkers();
          });
          _checkZoneViolation();
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        }
      } catch (e) {
        print('Error getting location: $e');
      }
    });
  }

  Future<void> _sendSOS() async {
    Position? currentPosition;
    try {
      currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      currentPosition = _currentPosition;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Lottie.asset(
              'assets/animations/alert.json',
              width: 80,
              height: 80,
              repeat: true,
            ),
            SizedBox(height: 12),
            Text(
              '🆘 SINYAL DARURAT',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Apakah Anda dalam keadaan darurat?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sinyal SOS akan dikirim ke:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Admin & Tim SAR\n• Lokasi GPS Anda\n• Info Kapal & Crew',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (currentPosition != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '📍 Lokasi Saat Ini:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${currentPosition.latitude.toStringAsFixed(6)}, ${currentPosition.longitude.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sos, size: 20),
                SizedBox(width: 8),
                Text('KIRIM SOS', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSendingSOS = true);
      
      try {
        // TODO: Call API to send SOS
        // await EmergencyService.sendSOS(
        //   tripId: widget.tripData['tripId'],
        //   latitude: currentPosition?.latitude,
        //   longitude: currentPosition?.longitude,
        //   vesselName: widget.tripData['vesselName'],
        //   crewCount: widget.tripData['crewCount'],
        //   message: 'SOS dari ABK',
        // );
        
        await Future.delayed(Duration(seconds: 2));
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/animations/alert.json',
                    width: 100,
                    height: 100,
                    repeat: false,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '✅ SOS TERKIRIM!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Sinyal darurat telah dikirim ke admin dan tim SAR.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Bantuan sedang dalam perjalanan!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Gagal mengirim SOS: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSendingSOS = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Tracking Trip', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)]),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isSendingSOS ? null : _sendSOS,
            icon: EmergencyButtonWidget(onPressed: () {}),
            tooltip: 'SOS Darurat',
            padding: EdgeInsets.zero,
          ),
          SizedBox(width: 8),
          Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.white),
                SizedBox(width: 6),
                Text('Aktif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map View
            Container(
              height: 300,
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _currentPosition == null
                    ? Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          zoom: 12,
                        ),
                        onMapCreated: (controller) => _mapController = controller,
                        markers: _markers,
                        circles: _circles,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: false,
                        mapType: MapType.hybrid,
                      ),
              ),
            ),

            // Zone Status Alert
            if (_isInRestrictedZone)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚠️ ZONA TERLARANG!',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Segera keluar dari area ini',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _stopAlarm,
                      icon: Icon(Icons.volume_off, color: Colors.white),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 16),

            // Trip Header
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.sailing, color: Colors.white, size: 32),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.tripData['vesselName'] ?? 'Kapal',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            SizedBox(height: 4),
                            Text(
                              widget.tripData['vesselNumber'] ?? '-',
                              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.3)),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(Icons.access_time, 'Durasi', '${widget.tripData['estimatedDuration'] ?? 0} hari'),
                      _buildStatItem(Icons.location_on, 'Pelabuhan', widget.tripData['departureHarbor'] ?? '-'),
                    ],
                  ),
                ],
              ),
            ),

            // Location Status
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.my_location, color: Color(0xFF1B4F9C), size: 24),
                      SizedBox(width: 12),
                      Text('Lokasi Saat Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (_currentPosition != null) ...[
                    _buildLocationRow('Latitude', _currentPosition!.latitude.toStringAsFixed(6)),
                    SizedBox(height: 12),
                    _buildLocationRow('Longitude', _currentPosition!.longitude.toStringAsFixed(6)),
                    SizedBox(height: 12),
                    _buildLocationRow('Kecepatan', '${(_currentPosition!.speed * 1.852).toStringAsFixed(1)} knot'),
                  ] else ...[
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Color(0xFF1B4F9C)),
                          SizedBox(height: 12),
                          Text('Mendapatkan lokasi...', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 16),

            // Trip Status
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF1B4F9C), size: 24),
                      SizedBox(width: 12),
                      Text('Status Trip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildStatusRow(Icons.check_circle, 'Status', _tripStatus, Colors.green),
                  SizedBox(height: 12),
                  _buildStatusRow(Icons.person, 'Nahkoda', widget.tripData['captainName'] ?? '-', Colors.blue),
                  SizedBox(height: 12),
                  _buildStatusRow(Icons.group, 'Jumlah ABK', '${widget.tripData['crewCount'] ?? 0} orang', Colors.orange),
                ],
              ),
            ),

            SizedBox(height: 16),

            // GPS Animation
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Lottie.asset(
                'assets/animations/GPS.json',
                width: 200,
                height: 200,
              ),
            ),

            SizedBox(height: 16),

            // SOS Emergency Button
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSendingSOS ? null : _sendSOS,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
                child: _isSendingSOS
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'MENGIRIM SOS...',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          EmergencyButtonWidget(onPressed: () {}),
                          Text(
                            '🆘 KIRIM SOS DARURAT',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tekan untuk mengirim sinyal darurat',
                            style: TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
              ),
            ),

            SizedBox(height: 16),

            // Info Box
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lokasi Anda sedang dilacak secara real-time. Pastikan GPS tetap aktif.',
                      style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Show catch recording screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fitur pencatatan tangkapan')),
          );
        },
        backgroundColor: Color(0xFF1B4F9C),
        icon: Icon(Icons.add_circle_outline),
        label: Text('Catat Tangkapan'),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildLocationRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
