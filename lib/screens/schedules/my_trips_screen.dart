import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/api/trip_service.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({Key? key}) : super(key: key);

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  List<Map<String, dynamic>> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    try {
      // Ambil kapal ID dari profile
      final prefs = await SharedPreferences.getInstance();
      final vesselDataString = prefs.getString('vessel_data');
      int? userKapalId;
      
      if (vesselDataString != null) {
        try {
          final vesselData = json.decode(vesselDataString);
          userKapalId = vesselData['kapal']?['id'];
          print('🚢 [MyTrips] User Kapal ID: $userKapalId');
        } catch (e) {
          print('❌ [MyTrips] Error parsing vessel_data: $e');
        }
      }
      
      final response = await TripService.getAllTrips();
      if (response['success'] == true && response['data'] != null) {
        final allTrips = List<Map<String, dynamic>>.from(response['data']);
        
        // Filter berdasarkan kapal
        final filteredTrips = userKapalId != null
            ? allTrips.where((trip) => trip['kapal']?['id'] == userKapalId).toList()
            : allTrips;
        
        print('🔍 [MyTrips] Filtered: ${filteredTrips.length}/${allTrips.length} trips');
        
        if (mounted) {
          setState(() {
            _trips = filteredTrips;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _trips = [];
          });
        }
      }
    } catch (e) {
      print('Error loading trips: $e');
      if (mounted) {
        setState(() {
          _trips = [];
        });
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu_dokumen':
        return Colors.orange;
      case 'menunggu_izin':
        return Colors.amber;
      case 'siap_berangkat':
        return Colors.blue;
      case 'berlangsung':
        return Colors.green;
      case 'selesai':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu_dokumen':
        return 'Menunggu Dokumen';
      case 'menunggu_izin':
        return 'Menunggu Izin';
      case 'siap_berangkat':
        return 'Siap Berangkat';
      case 'berlangsung':
        return 'Berlangsung';
      case 'selesai':
        return 'Selesai';
      default:
        return status ?? 'Unknown';
    }
  }

  String _getCrewCount(dynamic awakKapal) {
    if (awakKapal == null) return '0 orang';
    if (awakKapal is List) {
      return '${awakKapal.length} orang';
    }
    return '0 orang';
  }

  String _formatTargetIkan(String? targetIkan) {
    if (targetIkan == null || targetIkan.isEmpty) return '-';
    if (targetIkan.toLowerCase() == 'sesuai jadwal tugas') return 'Belum ditentukan';
    return targetIkan;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Trip Saya',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        child: _trips.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _trips.length,
                itemBuilder: (context, index) {
                  return _buildTripCard(_trips[index]);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sailing_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Belum ada trip yang ditugaskan',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    // Debug: Print trip data
    print('\n========== TRIP CARD DATA ==========');
    print('Trip ID: ${trip['id']}');
    print('Nahkoda: ${trip['nahkoda']}');
    print('awakKapal: ${trip['awakKapal']}');
    print('durasi: ${trip['durasi']}');
    print('targetIkan: ${trip['targetIkan']}');
    print('estimasiBerat: ${trip['estimasiBerat']}');
    print('====================================\n');

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B4F9C).withOpacity(0.1), Color(0xFF2563EB).withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.sailing, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip['taskTitle'] ?? 'Trip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(trip['status']),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(trip['status']),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trip['nahkoda'] != null) ...[
                  _buildInfoRow(
                    Icons.person_outline,
                    'Nahkoda',
                    trip['nahkoda']['nama']?.toString() ?? trip['nahkoda']['username']?.toString() ?? '-',
                    Colors.purple,
                  ),
                  SizedBox(height: 12),
                ],
                _buildInfoRow(
                  Icons.groups,
                  'Jumlah Crew',
                  _getCrewCount(trip['awakKapal']),
                  Colors.orange,
                ),
                if (trip['targetIkan'] != null) ...[
                  SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.phishing,
                    'Target Ikan',
                    _formatTargetIkan(trip['targetIkan'].toString()),
                    Colors.cyan,
                  ),
                ],
                if (trip['estimasiBerat'] != null) ...[
                  SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.scale,
                    'Estimasi Berat',
                    '${trip['estimasiBerat']} kg',
                    Colors.teal,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
