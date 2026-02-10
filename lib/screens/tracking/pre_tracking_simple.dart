import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../services/api/trip_service.dart';
import '../../utils/navigation_helper.dart';
import '../../provider/user_provider.dart';
import 'waiting_approval_screen.dart';

class PreTrackingScreenSimple extends StatefulWidget {
  final int tripId;
  final Map<String, dynamic> tripData;

  const PreTrackingScreenSimple({
    Key? key,
    required this.tripId,
    required this.tripData,
  }) : super(key: key);

  @override
  State<PreTrackingScreenSimple> createState() => _PreTrackingScreenSimpleState();
}

class _PreTrackingScreenSimpleState extends State<PreTrackingScreenSimple> {
  bool _isSubmitting = false;
  Map<String, dynamic> _tripDetail = {};
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadTripDetail();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      try {
        final response = await TripService.getTripDetail(widget.tripId);
        if (response['success'] == true) {
          final status = response['data']?['status']?.toLowerCase();
          print('🔄 [POLLING] Trip status: $status');
          
          if (status == 'menunggu_izin' && mounted) {
            timer.cancel();
            print('➡️ [POLLING] Nahkoda sudah kirim, redirecting to WaitingApprovalScreen...');
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            NavigationHelper.pushReplacementNoTransition(
              context,
              WaitingApprovalScreen(
                tripData: {
                  ...widget.tripData,
                  'tripId': widget.tripId,
                  'role': userProvider.user?.role ?? 'crew',
                },
              ),
            );
          }
        }
      } catch (e) {
        print('❌ [POLLING] Error: $e');
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTripDetail() async {
    try {
      print('\n🔄 [PRE-TRACKING] Loading trip detail...');
      final response = await TripService.getTripDetail(widget.tripId);
      
      if (response['success'] == true && mounted) {
        final tripData = response['data'] ?? {};
        final status = tripData['status']?.toLowerCase();
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userRole = userProvider.user?.role?.toLowerCase();
        
        print('📊 [PRE-TRACKING] Trip status: $status, Role: $userRole');
        
        // Jika status menunggu_izin atau lebih, redirect ke WaitingApprovalScreen
        if (status == 'menunggu_izin' || status == 'disetujui' || status == 'aktif' || status == 'sedang_melaut') {
          print('➡️ [PRE-TRACKING] Status $status detected, redirecting to WaitingApprovalScreen...');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              NavigationHelper.pushReplacementNoTransition(
                context,
                WaitingApprovalScreen(
                  tripData: {
                    ...widget.tripData,
                    'tripId': widget.tripId,
                    'role': userRole ?? 'crew',
                  },
                ),
              );
            }
          });
          return;
        }
        
        setState(() {
          _tripDetail = tripData;
        });
        
        // Start polling untuk crew (menunggu nahkoda kirim)
        if (userRole == 'crew') {
          print('🔄 [PRE-TRACKING] Starting polling for crew...');
          _startPolling();
        }
        
        print('✅ [PRE-TRACKING] Trip detail loaded');
      }
    } catch (e) {
      print('❌ [PRE-TRACKING] Failed to load trip detail: $e');
    }
  }

  Future<void> _submitAndRequestApproval() async {
    print('\n🔵 [PRE-TRACKING] KIRIM & MULAI TRIP clicked!');
    setState(() => _isSubmitting = true);

    try {
      // Update status trip menjadi menunggu_izin
      print('📤 [PRE-TRACKING] Updating trip status to menunggu_izin...');
      await TripService.updateTripStatus(widget.tripId, 'menunggu_izin');
      print('✅ [PRE-TRACKING] Trip status updated successfully');

      if (!mounted) return;

      // Navigate ke WaitingApprovalScreen
      print('➡️ [PRE-TRACKING] Navigating to WaitingApprovalScreen...');
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      NavigationHelper.pushReplacementNoTransition(
        context,
        WaitingApprovalScreen(
          tripData: {
            'tripId': widget.tripId,
            'vesselName': widget.tripData['vesselName'] ?? '',
            'vesselNumber': widget.tripData['vesselNumber'] ?? '',
            'captainName': widget.tripData['captainName'] ?? '',
            'crewCount': widget.tripData['crewCount'] ?? 0,
            'departureHarbor': widget.tripData['departureHarbor'] ?? '',
            'departureDate': widget.tripData['departureDate'] ?? DateTime.now(),
            'estimatedDuration': widget.tripData['estimatedDuration'] ?? 1,
            'emergencyContact': widget.tripData['emergencyContact'] ?? '',
            'fuelAmount': widget.tripData['fuelAmount'] ?? 0.0,
            'iceStorage': widget.tripData['iceStorage'] ?? 0.0,
            'notes': widget.tripData['notes'],
            'role': userProvider.user?.role ?? 'crew',
            'harborCoordinates': widget.tripData['harborCoordinates'],
          },
        ),
      );
    } catch (e) {
      print('❌ [PRE-TRACKING] Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim perizinan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.user?.role?.toLowerCase();
    
    final width = MediaQuery.of(context).size.width;
    double sp(double size) => size * (width / 390);

    // Extract data from API response or use widget.tripData as fallback
    final kapal = _tripDetail['kapal'] ?? {};
    final nahkoda = _tripDetail['nahkoda'] ?? {};
    final perizinan = _tripDetail['perizinan'] ?? {};
    final fuelDataList = perizinan['fuelData'] as List? ?? [];
    final iceDataList = perizinan['iceData'] as List? ?? [];
    
    // Calculate total fuel and ice
    double totalFuel = 0;
    double totalIce = 0;
    
    for (var fuel in fuelDataList) {
      totalFuel += (fuel['jumlahLiter'] ?? 0).toDouble();
    }
    
    for (var ice in iceDataList) {
      totalIce += (ice['jumlahKg'] ?? 0).toDouble();
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Bersiap Melaut',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: sp(16)),

                  // Vessel Info Card
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: sp(16)),
                    padding: EdgeInsets.all(sp(16)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(sp(12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(sp(12)),
                              decoration: BoxDecoration(
                                color: Color(0xFF1B4F9C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(sp(12)),
                              ),
                              child: Icon(
                                Icons.directions_boat,
                                color: Color(0xFF1B4F9C),
                                size: 28,
                              ),
                            ),
                            SizedBox(width: sp(12)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    kapal['namaKapal'] ?? widget.tripData['vesselName'] ?? '-',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    kapal['nomorRegistrasi'] ?? widget.tripData['vesselNumber'] ?? '-',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 24),
                        _buildInfoRow(
                          Icons.person,
                          'Nahkoda',
                          nahkoda['nama'] ?? widget.tripData['captainName'] ?? '-',
                        ),
                        SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.groups,
                          'ABK',
                          '${(_tripDetail['awakKapal'] as List?)?.length ?? widget.tripData['crewCount'] ?? 0} orang',
                        ),
                        SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.anchor,
                          'Pelabuhan',
                          _tripDetail['pelabuhanAsal'] ?? widget.tripData['departureHarbor'] ?? '-',
                        ),
                        SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Estimasi',
                          '${_tripDetail['durasi'] ?? widget.tripData['estimatedDuration'] ?? 0} hari',
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: sp(16)),

                  // Resources Card
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: sp(16)),
                    padding: EdgeInsets.all(sp(16)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(sp(12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Persediaan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.local_gas_station,
                          'BBM',
                          '${totalFuel.toStringAsFixed(0)} L',
                        ),
                        SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.ac_unit,
                          'Kapasitas Es',
                          '${totalIce.toStringAsFixed(0)} Kg',
                        ),
                        if (widget.tripData['notes'] != null) ...[
                          Divider(height: 24),
                          _buildInfoRow(
                            Icons.note,
                            'Catatan',
                            widget.tripData['notes'],
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: sp(24)),

                  // Ready to Start
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: sp(16)),
                    child: Column(
                      children: [
                        Lottie.asset(
                          'assets/animations/GPS.json',
                          width: 400,
                          height: 400,
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Semua Persiapan Selesai!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          userRole == 'nahkoda'
                              ? 'Kirim perizinan untuk memulai tracking'
                              : 'Menunggu Nahkoda mengirim perizinan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: userRole == 'nahkoda' ? Colors.grey[600] : Colors.orange[700],
                            fontWeight: userRole == 'nahkoda' ? FontWeight.normal : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: sp(100)),
                ],
              ),
            ),
          ),

          // Bottom Button - Only for Nahkoda
          if (userRole == 'nahkoda')
            Container(
              padding: EdgeInsets.all(sp(16)),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAndRequestApproval,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 24, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'KIRIM & MULAI TRIP',
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
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Color(0xFF1B4F9C)),
        SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
