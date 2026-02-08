import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/api/trip_service.dart';
import '../../services/api/vessel_service.dart';
import '../nahkoda/my_trips_screen.dart';
import '../crew/screens/crew_my_trips_screen.dart';

class MySchedulesScreen extends StatefulWidget {
  const MySchedulesScreen({Key? key}) : super(key: key);

  @override
  State<MySchedulesScreen> createState() => _MySchedulesScreenState();
}

class _MySchedulesScreenState extends State<MySchedulesScreen> {
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    // Pastikan vessel data sudah tersedia
    await _ensureVesselDataAvailable();
    
    // Baru load schedules
    await _loadSchedules();
  }

  Future<void> _ensureVesselDataAvailable() async {
    try {
      print('🔄 [MySchedules] Ensuring vessel data is available...');
      
      // Panggil VesselService untuk fetch data
      final vesselService = VesselService();
      final vesselData = await vesselService.getVesselData(forceRefresh: false);
      
      if (vesselData != null) {
        print('✅ [MySchedules] Vessel data fetched successfully');
        print('🚢 [MySchedules] Kapal: ${vesselData['kapal']?['namaKapal']}');
      } else {
        print('⚠️ [MySchedules] No vessel data available');
      }
    } catch (e) {
      print('❌ [MySchedules] Error fetching vessel data: $e');
    }
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role');
    });
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      // Ambil kapal ID dari profile
      final prefs = await SharedPreferences.getInstance();
      final vesselDataString = prefs.getString('vessel_data');
      int? userKapalId;
      
      if (vesselDataString != null) {
        try {
          final vesselData = json.decode(vesselDataString);
          userKapalId = vesselData['kapal']?['id'];
          print('🚢 [MySchedules] User Kapal ID: $userKapalId');
        } catch (e) {
          print('❌ [MySchedules] Error parsing vessel_data: $e');
        }
      }
      
      // Ambil semua trips
      final response = await TripService.getAllTrips();
      if (response['success'] == true && response['data'] != null) {
        final allTrips = List<Map<String, dynamic>>.from(response['data']);
        print('\n========== FILTER SCHEDULES START ==========');
        print('📋 [MySchedules] Total trips from API: ${allTrips.length}');
        
        // Filter berdasarkan kapal dan status
        final filteredTrips = allTrips.where((trip) {
          final tripKapalId = trip['kapal']?['id'];
          final status = trip['status']?.toLowerCase();
          
          // Filter: kapal sama DAN status aktif
          final isMatchingKapal = userKapalId == null || tripKapalId == userKapalId;
          final isActiveStatus = status != 'selesai' && status != 'ditolak';
          
          final match = isMatchingKapal && isActiveStatus;
          if (match) {
            print('✅ [MySchedules] Match: Trip ID ${trip['id']}, Kapal ID $tripKapalId, Status: $status');
          }
          return match;
        }).toList();
        
        print('🔍 [MySchedules] Filtered trips: ${filteredTrips.length}');
        print('========== FILTER SCHEDULES END ==========\n');
        
        setState(() {
          _schedules = filteredTrips;
          _isLoading = false;
        });
      } else {
        setState(() {
          _schedules = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [MySchedules] Error loading schedules: $e');
      setState(() {
        _schedules = [];
        _isLoading = false;
      });
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu_dokumen':
        return Colors.orange;
      case 'siap_berangkat':
        return Colors.blue;
      case 'berlayar':
        return Colors.green;
      case 'selesai':
        return Colors.grey;
      case 'ditolak':
        return Colors.red;
      case 'darurat':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu_dokumen':
        return 'Menunggu Dokumen';
      case 'siap_berangkat':
        return 'Siap Berangkat';
      case 'berlayar':
        return 'Berlayar';
      case 'selesai':
        return 'Selesai';
      case 'ditolak':
        return 'Ditolak';
      case 'darurat':
        return 'Darurat';
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
          'Jadwal Tugas Saya',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSchedules,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _schedules.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _schedules.length,
                    itemBuilder: (context, index) {
                      return _buildScheduleCard(_schedules[index]);
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
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Belum ada jadwal tugas',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final dateFormat = DateFormat('dd MMM yyyy');
    
    // Debug: Print schedule data
    print('\n========== SCHEDULE CARD DATA ==========');
    print('Schedule ID: ${schedule['id']}');
    print('Nahkoda: ${schedule['nahkoda']}');
    print('awakKapal: ${schedule['awakKapal']}');
    print('durasi: ${schedule['durasi']}');
    print('targetIkan: ${schedule['targetIkan']}');
    print('estimasiBerat: ${schedule['estimasiBerat']}');
    print('========================================\n');
    
    DateTime? scheduledDate;
    try {
      scheduledDate = schedule['tanggalBerangkat'] != null 
          ? DateTime.parse(schedule['tanggalBerangkat']) 
          : null;
    } catch (e) {
      scheduledDate = null;
    }

    final kapal = schedule['kapal'];
    final nahkoda = schedule['nahkoda'];
    final status = schedule['status'];

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
                  child: Icon(Icons.directions_boat, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kapal?['namaKapal'] ?? kapal?['nama'] ?? 'Kapal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        kapal?['nomorRegistrasi'] ?? '-',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(status),
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
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.calendar_today,
                  'Tanggal Berangkat',
                  scheduledDate != null ? dateFormat.format(scheduledDate) : '-',
                  Colors.blue,
                ),
                if (nahkoda != null) ...[
                  SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.person_outline,
                    'Nahkoda',
                    nahkoda['nama'] ?? nahkoda['username'] ?? '-',
                    Colors.purple,
                  ),
                ],
                SizedBox(height: 12),
                _buildInfoRow(
                  Icons.groups,
                  'Jumlah Crew',
                  _getCrewCount(schedule['awakKapal']),
                  Colors.orange,
                ),
                SizedBox(height: 12),
                _buildInfoRow(
                  Icons.access_time,
                  'Durasi',
                  '${schedule['durasi'] ?? 0} hari',
                  Colors.green,
                ),
                SizedBox(height: 12),
                _buildInfoRow(
                  Icons.location_on,
                  'Area Tangkap',
                  schedule['areaTangkap']?['nama'] ?? '-',
                  Colors.teal,
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate based on role
                      if (_userRole == 'crew' || _userRole == 'abk') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CrewMyTripsScreen(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyTripsScreen(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1B4F9C),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lanjut ke Tugas Trip',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ),
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
