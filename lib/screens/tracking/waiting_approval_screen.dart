import 'package:e_logbook/screens/crew/screens/crew_active_tracking_screen.dart';
import 'package:e_logbook/screens/nahkoda/screens/aktif_tracking.dart';
import 'package:e_logbook/services/api/trip_service.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/navigation_helper.dart';

class WaitingApprovalScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;

  const WaitingApprovalScreen({Key? key, required this.tripData}) : super(key: key);

  @override
  State<WaitingApprovalScreen> createState() => _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends State<WaitingApprovalScreen> {
  bool _isApproved = false;
  Timer? _pollTimer;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserRole();
    _startPolling();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? widget.tripData['role'];
    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }
    print('👤 [WaitingApproval] User role loaded: $_userRole');
  }

  void _startPolling() {
    print('🔄 [WaitingApproval] Start polling for trip ${widget.tripData['tripId']}');
    
    _pollTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      try {
        print('🔍 [WaitingApproval] Polling tick ${timer.tick}...');
        
        final tripId = widget.tripData['tripId'];
        if (tripId == null) {
          print('❌ [WaitingApproval] Trip ID is null');
          return;
        }
        
        final response = await TripService.getTripDetail(tripId);
        print('📊 [WaitingApproval] Response: $response');
        
        if (response['success'] == true) {
          final status = response['data']?['status']?.toString().toLowerCase();
          print('📌 [WaitingApproval] Current status: $status');
          
          // Crew menunggu status 'aktif' (Nahkoda sudah mulai)
          // Nahkoda menunggu status 'disetujui' (Admin approve)
          final isNahkoda = _userRole?.toLowerCase() == 'nahkoda';
          final targetStatus = isNahkoda ? 'disetujui' : 'aktif';
          
          if (status == targetStatus) {
            print('✅ [WaitingApproval] Trip ready! Status: $status');
            setState(() => _isApproved = true);
            timer.cancel();
            _showApprovedDialog();
          } else {
            print('⏳ [WaitingApproval] Still waiting... Status: $status');
          }
        } else {
          print('⚠️ [WaitingApproval] API returned success=false');
        }
      } catch (e) {
        print('❌ [WaitingApproval] Error polling: $e');
      }
    });
  }

  void _showApprovedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade50, Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
              ),
              SizedBox(height: 24),
              Text(
                _userRole?.toLowerCase() == 'nahkoda' ? 'Trip Disetujui!' : 'Trip Dimulai!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),
              Text(
                _userRole?.toLowerCase() == 'nahkoda'
                    ? 'Admin telah menyetujui trip Anda.\nSilakan mulai tracking sekarang.'
                    : 'Nahkoda telah memulai trip.\nSilakan mulai tracking sekarang.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.green.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToPreTracking();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.navigation, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Mulai Tracking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPreTracking() {
    // Cek role dari SharedPreferences atau tripData
    final role = _userRole ?? widget.tripData['role'];
    final isNahkoda = role?.toLowerCase() == 'nahkoda';
    
    if (isNahkoda) {
      // Nahkoda goes to ActiveTrackingScreen (title: "Tracking Aktif")
      NavigationHelper.pushReplacementNoTransition(
        context,
        ActiveTrackingScreen(
          vesselName: widget.tripData['vesselName'] ?? '',
          vesselNumber: widget.tripData['vesselNumber'] ?? '',
          captainName: widget.tripData['captainName'] ?? '',
          crewCount: widget.tripData['crewCount'] ?? 0,
          selectedHarbor: widget.tripData['departureHarbor'] ?? '',
          departureTime: widget.tripData['departureDate'] ?? DateTime.now(),
          estimatedDuration: widget.tripData['estimatedDuration'] ?? 1,
          emergencyContact: widget.tripData['emergencyContact'] ?? '',
          fuelAmount: widget.tripData['fuelAmount'] ?? 0.0,
          iceStorage: widget.tripData['iceStorage'] ?? 0.0,
          notes: widget.tripData['notes'],
          harborCoordinates: widget.tripData['harborCoordinates'] ?? {
            'lat': -6.1944,
            'lng': 106.8229,
            'name': widget.tripData['departureHarbor'] ?? 'Unknown',
          },
          zoneRadius: 50.0,
        ),
      );
    } else {
      // Crew goes to CrewActiveTrackingScreen (title: "Tracking Trip")
      NavigationHelper.pushReplacementNoTransition(
        context,
        CrewActiveTrackingScreen(tripData: widget.tripData),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(
            'Menunggu Persetujuan',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          automaticallyImplyLeading: false,
          iconTheme: IconThemeData(color: Colors.white),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)]),
            ),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animations/PreTrip.json',
                  width: 200,
                  height: 200,
                ),
                SizedBox(height: 32),
                Text(
                  _userRole?.toLowerCase() == 'nahkoda'
                      ? 'Menunggu Persetujuan Admin'
                      : 'Menunggu Nahkoda Memulai Trip',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Data trip Anda sedang ditinjau oleh admin.\nAnda akan mendapat notifikasi setelah disetujui.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.directions_boat, 'Kapal', widget.tripData['vesselName'] ?? '-'),
                      Divider(height: 24),
                      _buildInfoRow(Icons.numbers, 'No. Registrasi', widget.tripData['vesselNumber'] ?? '-'),
                      Divider(height: 24),
                      _buildInfoRow(Icons.group, 'Jumlah ABK', '${widget.tripData['crewCount'] ?? 0} orang'),
                      Divider(height: 24),
                      _buildInfoRow(Icons.location_on, 'Pelabuhan', widget.tripData['departureHarbor'] ?? '-'),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                if (!_isApproved)
                  CircularProgressIndicator(color: Color(0xFF1B4F9C)),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Kembali', style: TextStyle(color: Colors.grey[600])),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF1B4F9C), size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
