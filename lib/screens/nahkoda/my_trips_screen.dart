import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/trip_model.dart';
import '../../services/api/trip_service.dart';
import '../tracking/pre_trip_fromscreen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({Key? key}) : super(key: key);

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<TripModel> _allTrips = [];
  List<TripModel> _activeTrips = [];
  List<TripModel> _completedTrips = [];
  String? _errorMessage;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        _currentUserId = userData['id'];
      }

      final response = await TripService.getAllTrips();
      
      if (response['success'] == true) {
        final List<dynamic> tripsData = response['data'] ?? [];
        
        // Filter trips yang relevan dengan user (nahkoda)
        final myTrips = tripsData.where((trip) {
          final nahkodaId = trip['nahkodaId'];
          return _currentUserId != null && nahkodaId == _currentUserId;
        }).toList();

        final trips = myTrips.map((json) => TripModel.fromJson(json)).toList();
        
        // Sort by date (newest first)
        trips.sort((a, b) => b.tanggalBerangkat.compareTo(a.tanggalBerangkat));

        setState(() {
          _allTrips = trips;
          _activeTrips = trips.where((t) => 
            t.status.toLowerCase() != 'selesai' && 
            t.status.toLowerCase() != 'ditolak'
          ).toList();
          _completedTrips = trips.where((t) => 
            t.status.toLowerCase() == 'selesai'
          ).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal mengambil data trip';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'menunggu_dokumen':
        return 'Menunggu Dokumen';
      case 'menunggu_izin':
        return 'Menunggu Izin';
      case 'siap_berangkat':
        return 'Siap Berangkat';
      case 'berlayar':
        return 'Berlayar';
      case 'selesai':
        return 'Selesai';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'menunggu_dokumen':
        return Colors.orange;
      case 'menunggu_izin':
        return Colors.amber;
      case 'siap_berangkat':
        return Colors.blue;
      case 'berlayar':
        return Colors.green;
      case 'selesai':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Info Trip', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
            ),
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(text: 'Aktif (${_activeTrips.length})'),
            Tab(text: 'Selesai (${_completedTrips.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTripList(_activeTrips, isActive: true),
                    _buildTripList(_completedTrips, isActive: false),
                  ],
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

  Widget _buildTripList(List<TripModel> trips, {required bool isActive}) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.sailing : Icons.check_circle_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'Tidak Ada Trip Aktif' : 'Belum Ada Trip Selesai',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              isActive 
                ? 'Belum ada trip yang sedang berjalan'
                : 'Riwayat trip yang selesai akan muncul di sini',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) => _buildTripCard(trips[index], isActive: isActive),
      ),
    );
  }

  Widget _buildTripCard(TripModel trip, {required bool isActive}) {
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
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive 
                  ? [const Color(0xFF1B4F9C), const Color(0xFF2563EB)]
                  : [Colors.grey[600]!, Colors.grey[700]!],
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
                  child: Icon(
                    isActive ? Icons.directions_boat : Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
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
                    color: _getStatusColor(trip.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(trip.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                if (trip.nahkoda.nama != '-')
                  _buildInfoRow(Icons.person_outline, 'Nahkoda', trip.nahkoda.nama),
                if (trip.nahkoda.nama != '-')
                  SizedBox(height: 12),
                _buildInfoRow(Icons.calendar_today, 'Tanggal Berangkat', dateFormat.format(trip.tanggalBerangkat)),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.event, 'Estimasi Pulang', dateFormat.format(trip.estimasiPulang)),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.access_time, 'Durasi', '${trip.durasi} hari'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on, 'Area Tangkap', trip.areaTangkap.nama),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.phishing, 'Target Ikan', trip.targetIkan),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.scale, 'Estimasi Berat', '${trip.estimasiBerat.toStringAsFixed(0)} kg'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.groups, 'Jumlah Crew', '${trip.awakKapal.length} orang'),
                
                if (trip.suratTugas != null) ...[
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      // TODO: Open surat tugas
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Membuka surat tugas...')),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF1B4F9C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(0xFF1B4F9C).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.description, color: Color(0xFF1B4F9C), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Lihat Surat Tugas',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B4F9C),
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Color(0xFF1B4F9C), size: 16),
                        ],
                      ),
                    ),
                  ),
                ],

                if (isActive)
                  const SizedBox(height: 16),
                if (isActive)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PreTripFormScreen(
                              tripData: {
                                'tripId': trip.id,
                                'vesselName': trip.kapal.namaKapal,
                                'vesselNumber': trip.kapal.nomorRegistrasi,
                                'crewCount': trip.awakKapal.length,
                                'departureHarbor': trip.areaTangkap.nama,
                                'estimatedDuration': trip.durasi,
                                'departureDate': trip.tanggalBerangkat,
                                'estimatedReturnDate': trip.estimasiPulang,
                                'fuelSupply': 0.0,
                                'iceSupply': 0.0,
                              },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4F9C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Lanjut ke Persiapan Trip',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
