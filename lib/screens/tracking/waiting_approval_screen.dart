import 'package:e_logbook/screens/crew/screens/crew_active_tracking_screen.dart';
import 'package:e_logbook/screens/nahkoda/screens/pre_tracking.dart';
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
    _loadUserRole();
    _startPolling();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role');
    });
  }

  void _startPolling() {
    // Simulate polling - replace with actual API call
    _pollTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      // TODO: Call API to check approval status
      // final status = await TripService.checkApprovalStatus(widget.tripData['tripId']);
      
      // Simulate approval after 10 seconds for demo
      if (timer.tick >= 2) {
        setState(() => _isApproved = true);
        timer.cancel();
        _showApprovedDialog();
      }
    });
  }

  void _showApprovedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Trip Disetujui!'),
          ],
        ),
        content: Text('Admin telah menyetujui trip Anda. Silakan mulai tracking sekarang.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPreTracking();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Mulai Tracking'),
          ),
        ],
      ),
    );
  }

  void _navigateToPreTracking() {
    final isNahkoda = _userRole == 'nahkoda';
    
    if (isNahkoda) {
      // Nahkoda goes to PreTrackingScreen
      NavigationHelper.pushReplacementNoTransition(
        context,
        PreTrackingScreen(
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
        ),
      );
    } else {
      // Crew goes to CrewActiveTrackingScreen
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
          title: Text('Menunggu Persetujuan', style: TextStyle(fontWeight: FontWeight.bold)),
          automaticallyImplyLeading: false,
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
                  'Menunggu Persetujuan Admin',
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
