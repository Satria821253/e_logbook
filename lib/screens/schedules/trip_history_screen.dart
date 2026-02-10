import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../models/trip_model.dart';
import '../../services/api/trip_service.dart';
import '../../provider/user_provider.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  bool _isLoading = true;
  List<TripModel> _trips = [];
  String? _errorMessage;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadTrips();
  }

  Future<void> _loadUserRole() async {
    // Try SharedPreferences first
    final prefs = await SharedPreferences.getInstance();
    var role = prefs.getString('role')?.toLowerCase();
    
    // Fallback to UserProvider if SharedPreferences is empty
    if (role == null && mounted) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      role = userProvider.user?.role?.toLowerCase();
      print('🔍 [TripHistory] Using UserProvider role: $role');
    }
    
    print('🔍 [TripHistory] Loading user role: $role');
    setState(() {
      _userRole = role;
    });
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      var userId = prefs.getInt('user_id');
      var userRole = prefs.getString('role')?.toLowerCase();
      var userName = prefs.getString('name');
      
      // Fallback to UserProvider if SharedPreferences is empty
      if ((userId == null || userRole == null) && mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userId = userProvider.user?.id;
        userRole = userProvider.user?.role?.toLowerCase();
        userName = userProvider.user?.name;
        print('🔍 [TripHistory] Using UserProvider data');
      }
      
      print('👤 [TripHistory] User ID: $userId, Role: $userRole, Name: $userName');
      
      // Validasi: Jika data user tidak ada, tampilkan error
      if (userId == null || userRole == null) {
        print('❌ [TripHistory] User data not found');
        setState(() {
          _errorMessage = 'Data pengguna tidak ditemukan. Silakan login kembali.';
          _isLoading = false;
        });
        return;
      }
      
      // Pastikan role sudah di-set di state
      if (_userRole == null) {
        setState(() {
          _userRole = userRole;
        });
      }
      
      final response = await TripService.getAllTrips();
      if (response['success'] == true) {
        final List<dynamic> tripsData = response['data'] ?? [];
        
        // Filter berdasarkan role dan user, HANYA status selesai
        final filteredTrips = tripsData.where((trip) {
          final status = trip['status']?.toLowerCase();
          
          // Harus status selesai
          if (status != 'selesai') return false;
          
          // Filter berdasarkan role
          if (userRole == 'nahkoda') {
            // Nahkoda: cek apakah dia nahkoda di trip ini
            final nahkoda = trip['nahkoda'];
            if (nahkoda == null) return false;
            
            // Jika nahkoda adalah object
            if (nahkoda is Map) {
              final nahkodaId = nahkoda['id'];
              final nahkodaNama = nahkoda['nama'];
              final isMyTrip = nahkodaId == userId || nahkodaNama == userName;
              print('🔍 [TripHistory-Nahkoda] Trip ${trip['id']}: nahkodaId=$nahkodaId, userId=$userId, match=$isMyTrip');
              return isMyTrip;
            }
            // Jika nahkoda adalah ID langsung
            else if (nahkoda is int) {
              final isMyTrip = nahkoda == userId;
              print('🔍 [TripHistory-Nahkoda] Trip ${trip['id']}: nahkodaId=$nahkoda, userId=$userId, match=$isMyTrip');
              return isMyTrip;
            }
            return false;
          } else {
            // Crew: cek apakah dia ada di awakKapal
            final awakKapal = trip['awakKapal'];
            if (awakKapal == null) return false;
            
            if (awakKapal is List) {
              final isMyTrip = awakKapal.any((crew) {
                // Jika crew adalah object
                if (crew is Map) {
                  final crewId = crew['id'];
                  final crewNama = crew['nama'];
                  return crewId == userId || crewNama == userName;
                }
                // Jika crew adalah ID langsung
                else if (crew is int) {
                  return crew == userId;
                }
                return false;
              });
              print('🔍 [TripHistory-Crew] Trip ${trip['id']}: isInCrew=$isMyTrip');
              return isMyTrip;
            }
            return false;
          }
        }).toList();
        
        print('✅ [TripHistory] Found ${filteredTrips.length} completed trips');
        
        setState(() {
          _trips = filteredTrips.map((json) => TripModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal mengambil data trip';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [TripHistory] Error: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Riwayat Tugas Saya', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _trips.isEmpty
                  ? _buildEmptyWidget()
                  : RefreshIndicator(
                      onRefresh: _loadTrips,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _trips.length,
                        itemBuilder: (context, index) {
                          return _buildTripCard(_trips[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTrips,
              icon: Icon(Icons.refresh),
              label: Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B4F9C),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Belum Ada Riwayat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          SizedBox(height: 8),
          Text(
            'Belum ada trip yang selesai',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(TripModel trip) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.green.shade700],
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.check_circle, color: Colors.white, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.taskTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        trip.kapal.namaKapal,
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Selesai',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.directions_boat, 'Kapal', trip.kapal.namaKapal),
                SizedBox(height: 12),
                _buildInfoRow(Icons.numbers, 'No. Registrasi', trip.kapal.nomorRegistrasi),
                SizedBox(height: 12),
                // Tampilkan nahkoda hanya jika user adalah crew
                if (_userRole != null && _userRole != 'nahkoda' && trip.nahkoda.nama != '-') ...[
                  _buildInfoRow(Icons.person_outline, 'Nahkoda', trip.nahkoda.nama),
                  SizedBox(height: 12),
                ],
                _buildInfoRow(Icons.groups, 'Jumlah Crew', '${trip.awakKapal.length} orang'),
                SizedBox(height: 12),
                _buildInfoRow(Icons.calendar_today, 'Tanggal Berangkat', dateFormat.format(trip.tanggalBerangkat)),
                SizedBox(height: 12),
                _buildInfoRow(Icons.access_time, 'Durasi', '${trip.durasi} hari'),
                SizedBox(height: 12),
                _buildInfoRow(Icons.location_on, 'Area Tangkap', trip.areaTangkap.nama),
                SizedBox(height: 12),
                _buildInfoRow(Icons.phishing, 'Target Ikan', trip.targetIkan),
                SizedBox(height: 12),
                _buildInfoRow(Icons.scale, 'Estimasi Berat', '${trip.estimasiBerat.toStringAsFixed(0)} kg'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Color(0xFF1B4F9C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: Color(0xFF1B4F9C)),
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
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
