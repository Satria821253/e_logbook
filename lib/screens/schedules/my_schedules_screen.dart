import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../services/api/trip_service.dart';
import '../../services/api/vessel_service.dart';
import '../../services/nitification/local_notification_service.dart';
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
  bool _hasActiveTrip = false;
  Map<String, dynamic>? _activeTrip;
  Timer? _notificationPollTimer;
  String? _lastNotificationId;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _initializeData();
    _startNotificationPolling();
  }

  @override
  void dispose() {
    _notificationPollTimer?.cancel();
    super.dispose();
  }

  void _startNotificationPolling() {
    _notificationPollTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      await _checkNewTaskNotification();
    });
  }

  Future<void> _checkNewTaskNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userRole = prefs.getString('role');
      final userDataString = prefs.getString('user_data');
      
      if (token == null || userRole == null) return;
      
      int? currentUserId;
      if (userDataString != null) {
        try {
          final userData = json.decode(userDataString);
          currentUserId = userData['id'];
        } catch (e) {
          print('❌ [Notification] Error parsing user_data: $e');
          return;
        }
      }
      
      if (currentUserId == null) return;

      final response = await http.get(
        Uri.parse('https://elogbookipb.web.id/api/mobile/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final notifications = data['data'] as List;
          
          // Filter notifikasi berdasarkan user ID
          final myNotifications = notifications.where((n) {
            final recipientId = n['userId'] ?? n['recipientId'];
            return recipientId == currentUserId;
          }).toList();
          
          // Cek notifikasi tugas baru
          final newTaskNotif = myNotifications.firstWhere(
            (n) => n['type'] == 'new_task' && n['isRead'] == false,
            orElse: () => null,
          );

          if (newTaskNotif != null && newTaskNotif['id'] != _lastNotificationId) {
            _lastNotificationId = newTaskNotif['id'];
            
            // Hanya tampilkan notifikasi jika tidak ada trip aktif
            if (!_hasActiveTrip) {
              // Untuk crew, tambahkan info bahwa perlu menunggu izin nahkoda
              String message = newTaskNotif['message'] ?? 'Anda mendapat tugas trip baru';
              if (userRole.toLowerCase() == 'crew' || userRole.toLowerCase() == 'abk') {
                message += '. Menunggu Nahkoda mendapatkan izin dari Admin';
              }
              
              await LocalNotificationService.showNewTaskNotification(
                title: newTaskNotif['title'] ?? 'Tugas Baru',
                message: message,
              );
              
              await _loadSchedules();
            }
          }
          
          // Untuk crew: Cek notifikasi status berlayar
          if (userRole.toLowerCase() == 'crew' || userRole.toLowerCase() == 'abk') {
            final berlayarNotif = myNotifications.firstWhere(
              (n) => n['type'] == 'trip_berlayar' && n['isRead'] == false,
              orElse: () => null,
            );
            
            if (berlayarNotif != null) {
              await LocalNotificationService.showNewTaskNotification(
                title: berlayarNotif['title'] ?? 'Trip Berlayar',
                message: berlayarNotif['message'] ?? 'Trip sudah dimulai, tracking aktif',
              );
              
              // Refresh data
              await _loadSchedules();
            }
          }
        }
      }
    } catch (e) {
      print('❌ [Notification] Error: $e');
    }
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
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
    if (!mounted) return;
    setState(() {
      _userRole = prefs.getString('role');
    });
  }

  Future<void> _loadSchedules() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Ambil user ID dari profile
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      int? currentUserId;
      
      if (userDataString != null) {
        try {
          final userData = json.decode(userDataString);
          currentUserId = userData['id'];
          print('👤 [MySchedules] Current User ID: $currentUserId');
        } catch (e) {
          print('❌ [MySchedules] Error parsing user_data: $e');
        }
      }
      
      // Ambil semua trips
      final response = await TripService.getAllTrips();
      if (response['success'] == true && response['data'] != null) {
        final allTrips = List<Map<String, dynamic>>.from(response['data']);
        print('\n========== FILTER SCHEDULES START ==========');
        print('📋 [MySchedules] Total trips from API: ${allTrips.length}');
        
        // Cek apakah ada trip AKTIF/BERLAYAR/DISETUJUI untuk user ini
        final activeTrip = allTrips.firstWhere(
          (trip) {
            final nahkodaId = trip['nahkodaId'];
            final awakKapal = trip['awakKapal'] as List?;
            final status = trip['status']?.toLowerCase();
            
            final isMyTrip = (currentUserId != null && nahkodaId == currentUserId) ||
                             (currentUserId != null && awakKapal != null && awakKapal.contains(currentUserId));
            
            // Cek jika ada trip yang sedang berjalan (aktif, berlayar, atau disetujui)
            return isMyTrip && (status == 'aktif' || status == 'berlayar' || status == 'disetujui');
          },
          orElse: () => {},
        );
        
        final hasActive = activeTrip.isNotEmpty;
        print('🚨 [MySchedules] Has active/ongoing trip: $hasActive');
        
        // Filter: hanya trip yang di-assign ke user ini DAN tidak ada trip aktif
        final filteredTrips = allTrips.where((trip) {
          final nahkodaId = trip['nahkodaId'];
          final awakKapal = trip['awakKapal'] as List?;
          final status = trip['status']?.toLowerCase();
          
          // Filter 1: Apakah trip ini milik user?
          final isMyTrip = (currentUserId != null && nahkodaId == currentUserId) ||
                           (currentUserId != null && awakKapal != null && awakKapal.contains(currentUserId));
          
          // Filter 2: Hanya tampilkan jika TIDAK ada trip aktif
          if (hasActive) {
            return false; // Sembunyikan semua jadwal baru jika ada trip aktif
          }
          
          // Filter 3: Hanya tampilkan yang perlu action (menunggu_dokumen, menunggu_izin)
          final needsAction = status != 'disetujui' && 
                              status != 'aktif' && 
                              status != 'berlayar' &&
                              status != 'selesai' && 
                              status != 'ditolak';
          
          final match = isMyTrip && needsAction;
          if (match) {
            print('✅ [MySchedules] Match: Trip ID ${trip['id']}, Nahkoda ID $nahkodaId, Status: $status');
          }
          return match;
        }).toList();
        
        // Ambil hanya 1 trip pertama
        final limitedTrips = filteredTrips.take(1).toList();
        
        print('🔍 [MySchedules] Filtered trips: ${limitedTrips.length}');
        print('========== FILTER SCHEDULES END ==========\n');
        
        if (!mounted) return;
        setState(() {
          _schedules = limitedTrips;
          _hasActiveTrip = hasActive;
          _activeTrip = hasActive ? activeTrip : null;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _schedules = [];
          _hasActiveTrip = false;
          _activeTrip = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [MySchedules] Error loading schedules: $e');
      if (!mounted) return;
      setState(() {
        _schedules = [];
        _hasActiveTrip = false;
        _activeTrip = null;
        _isLoading = false;
      });
    }
  }


  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu_dokumen':
        return Colors.orange;
      case 'menunggu_izin':
        return Colors.amber;
      case 'disetujui':
        return Colors.green;
      case 'siap_berangkat':
        return Colors.blue;
      case 'berlayar':
        return Colors.green;
      case 'selesai':
        return Colors.green;
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
      case 'menunggu_izin':
        return 'Menunggu Izin';
      case 'disetujui':
        return 'Disetujui';
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
            : Column(
                children: [
                  // Banner jika ada trip aktif
                  if (_hasActiveTrip) _buildActiveTripBanner(),
                  
                  // List jadwal
                  Expanded(
                    child: _schedules.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: _schedules.length,
                            itemBuilder: (context, index) {
                              return _buildScheduleCard(_schedules[index]);
                            },
                          ),
                  ),
                ],
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
            _hasActiveTrip 
                ? 'Tidak ada jadwal baru'
                : 'Belum ada jadwal tugas',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          if (_hasActiveTrip)
            SizedBox(height: 8),
          if (_hasActiveTrip)
            Text(
              'Selesaikan trip yang sedang berjalan terlebih dahulu',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildActiveTripBanner() {
    final kapal = _activeTrip?['kapal'];
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1B4F9C)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.sailing, color: Colors.white, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🚢 Trip Sedang Berjalan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kapal ${kapal?['namaKapal'] ?? '-'} sedang aktif',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Trip baru akan dimulai setelah trip ini selesai',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
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
                // Sembunyikan button jika ada trip aktif
                if (!_hasActiveTrip)
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
                  )
                else
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Selesaikan trip yang sedang berjalan untuk memulai trip baru',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
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
