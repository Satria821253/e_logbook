import 'package:flutter/material.dart';
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

class _MyTripsScreenState extends State<MyTripsScreen> {
  bool _isLoading = true;
  List<TripModel> _trips = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Ambil kapal ID dari profile
      final prefs = await SharedPreferences.getInstance();
      final vesselDataString = prefs.getString('vessel_data');
      int? userKapalId;
      
      if (vesselDataString != null) {
        try {
          final vesselData = json.decode(vesselDataString);
          userKapalId = vesselData['kapal']?['id'];
          print('🚢 [NahkodaTrips] User Kapal ID: $userKapalId');
        } catch (e) {
          print('❌ [NahkodaTrips] Error parsing vessel_data: $e');
        }
      }
      
      final response = await TripService.getAllTrips();
      if (response['success'] == true) {
        final List<dynamic> tripsData = response['data'] ?? [];
        
        // Filter berdasarkan kapal DAN status bukan selesai/ditolak
        final filteredTrips = tripsData.where((trip) {
          final tripKapalId = trip['kapal']?['id'];
          final status = trip['status']?.toLowerCase();
          final isMatchingKapal = userKapalId == null || tripKapalId == userKapalId;
          final isActive = status != 'selesai' && status != 'ditolak';
          return isMatchingKapal && isActive;
        }).toList();
        
        // Ambil hanya 1 trip pertama
        final limitedTrips = filteredTrips.take(1).toList();
        
        print('🔍 [NahkodaTrips] Filtered: ${limitedTrips.length}/${tripsData.length} trips');
        
        setState(() {
          _trips = limitedTrips.map((json) => TripModel.fromJson(json)).toList();
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
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Tugas Saya', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Belum Ada Tugas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          SizedBox(height: 8),
          Text(
            'Anda belum memiliki trip yang ditugaskan',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(TripModel trip) {
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
                colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
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
                  child: Icon(Icons.directions_boat, color: Colors.white, size: 24),
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
                _buildInfoRow(Icons.groups, 'Jumlah Crew', '${trip.awakKapal.length} orang'),
                SizedBox(height: 12),
                _buildInfoRow(Icons.numbers, 'No. Registrasi', trip.kapal.nomorRegistrasi),
                SizedBox(height: 12),
                _buildInfoRow(Icons.phishing, 'Target Ikan', trip.targetIkan),
                SizedBox(height: 12),
                _buildInfoRow(Icons.scale, 'Estimasi Berat', '${trip.estimasiBerat.toStringAsFixed(0)} kg'),
                
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

                SizedBox(height: 16),
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
                      backgroundColor: Color(0xFF1B4F9C),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
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
