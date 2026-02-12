import 'package:e_logbook/screens/tracking/waiting_schedule_screen.dart';
import 'package:e_logbook/services/api/trip_service.dart';
import 'package:e_logbook/services/nitification/notification_service.dart';
import 'package:e_logbook/services/nitification/local_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';
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
          
          // Notifikasi ketika status 'disetujui' atau 'aktif'
          if (status == 'disetujui' || status == 'aktif') {
            print('✅ [WaitingApproval] Trip disetujui!');
            setState(() => _isApproved = true);
            timer.cancel();
            
            // Send notification
            await _sendApprovalNotification(response['data']);
            
            _navigateToWaitingSchedule();
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

  Future<void> _sendApprovalNotification(Map<String, dynamic> tripData) async {
    try {
      final kapal = tripData['kapal'] ?? {};
      final vesselName = kapal['namaKapal'] ?? widget.tripData['vesselName'] ?? 'Kapal';
      
      DateTime departureTime = DateTime.now();
      if (tripData['waktuMulai'] != null) {
        departureTime = DateTime.parse(tripData['waktuMulai']);
      } else if (tripData['tanggalBerangkat'] != null) {
        departureTime = DateTime.parse(tripData['tanggalBerangkat']);
      }
      
      final duration = departureTime.difference(DateTime.now());
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      
      String timeText;
      if (hours > 24) {
        final days = duration.inDays;
        timeText = '$days hari lagi';
      } else if (hours > 0) {
        timeText = '$hours jam $minutes menit lagi';
      } else {
        timeText = '$minutes menit lagi';
      }
      
      // Save to notification history
      await NotificationService.addTripNotification(
        tripId: widget.tripData['tripId'].toString(),
        vesselName: vesselName,
        departureTime: departureTime,
        message: 'Trip Anda telah aktif! Kapal $vesselName akan berangkat $timeText',
      );
      
      // Show local notification
      await LocalNotificationService.showTripApprovedNotification(
        vesselName: vesselName,
        departureTime: departureTime,
      );
      
      print('📬 [Notification] Trip aktif notification sent');
    } catch (e) {
      print('❌ [Notification] Error sending notification: $e');
    }
  }

  void _navigateToWaitingSchedule() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    
    final role = _userRole ?? prefs.getString('role') ?? widget.tripData['role'];
    final userName = userProvider.user?.name ?? prefs.getString('name') ?? '';
    
    final tripId = widget.tripData['tripId'];
    double totalFuel = 0;
    double totalIce = 0;
    DateTime? actualDepartureTime;
    int? actualDuration;
    DateTime? estimatedReturnDate;
    
    if (tripId != null) {
      try {
        final response = await TripService.getTripDetail(tripId);
        if (response['success'] == true) {
          final tripData = response['data'];
          final perizinan = tripData['perizinan'] ?? {};
          
          final fuelDataList = perizinan['fuelData'] as List? ?? [];
          for (var fuel in fuelDataList) {
            totalFuel += (fuel['jumlahLiter'] ?? 0).toDouble();
          }
          
          final iceDataList = perizinan['iceData'] as List? ?? [];
          for (var ice in iceDataList) {
            totalIce += (ice['jumlahKg'] ?? 0).toDouble();
          }
          
          if (tripData['waktuMulai'] != null) {
            actualDepartureTime = DateTime.parse(tripData['waktuMulai']);
          } else if (tripData['tanggalBerangkat'] != null) {
            actualDepartureTime = DateTime.parse(tripData['tanggalBerangkat']);
          }
          
          if (tripData['estimasiPulang'] != null) {
            estimatedReturnDate = DateTime.parse(tripData['estimasiPulang']);
          }
          
          actualDuration = tripData['durasi'];
        }
      } catch (e) {
        print('❌ [Navigation] Error: $e');
      }
    }
    
    final fuelAmount = totalFuel > 0 ? totalFuel : (widget.tripData['fuelAmount'] ?? 0.0).toDouble();
    final iceStorage = totalIce > 0 ? totalIce : (widget.tripData['iceStorage'] ?? 0.0).toDouble();
    final estimatedDuration = actualDuration ?? widget.tripData['estimatedDuration'] ?? 1;
    final departureTime = actualDepartureTime ?? widget.tripData['departureDate'] ?? DateTime.now();
    
    if (!mounted) return;
    
    NavigationHelper.pushReplacementNoTransition(
      context,
      WaitingScheduleScreen(
        scheduledDepartureTime: departureTime,
        tripData: {
          'vesselName': widget.tripData['vesselName'] ?? '',
          'vesselNumber': widget.tripData['vesselNumber'] ?? '',
          'captainName': widget.tripData['captainName'] ?? '',
          'crewCount': widget.tripData['crewCount'] ?? 0,
          'selectedHarbor': widget.tripData['departureHarbor'] ?? '',
          'departureTime': departureTime,
          'estimatedReturnDate': estimatedReturnDate,
          'estimatedDuration': estimatedDuration,
          'emergencyContact': widget.tripData['emergencyContact'] ?? '',
          'fuelAmount': fuelAmount,
          'iceStorage': iceStorage,
          'notes': widget.tripData['notes'],
          'harborCoordinates': widget.tripData['harborCoordinates'],
          'zoneRadius': 50.0,
          'userRole': role?.toLowerCase() == 'nahkoda' ? 'Nahkoda' : 'ABK',
          'userName': userName,
        },
      ),
    );
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
                  'Menunggu Persetujuan Admin',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Data trip sedang ditinjau admin.\nAnda akan diarahkan otomatis setelah disetujui.',
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
