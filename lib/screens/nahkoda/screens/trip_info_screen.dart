import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/trip_model.dart';
import '../../../services/api/trip_service.dart';
import '../../../provider/user_provider.dart';

class TripInfoScreen extends StatefulWidget {
  const TripInfoScreen({Key? key}) : super(key: key);

  @override
  State<TripInfoScreen> createState() => _TripInfoScreenState();
}

class _TripInfoScreenState extends State<TripInfoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TripModel> _scheduledTrips = [];
  List<TripModel> _activeTrips = [];
  List<TripModel> _completedTrips = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserId = userProvider.user?.id;
      final currentUserRole = userProvider.user?.role;

      print('\n========== LOAD TRIPS DEBUG ==========');
      print('Current User ID: $currentUserId');
      print('Current User Role: $currentUserRole');
      print('Current User Name: ${userProvider.user?.name}');

      if (currentUserId == null) {
        throw Exception('User ID tidak ditemukan');
      }

      print('Calling TripService.getAllTrips()...');
      final response = await TripService.getAllTrips();
      
      print('API Response success: ${response['success']}');
      print('API Response data type: ${response['data'].runtimeType}');
      
      if (response['success'] == true) {
        final List<dynamic> tripsData = response['data'] ?? [];
        print('Total trips from API: ${tripsData.length}');
        
        final allTrips = tripsData.map((json) => TripModel.fromJson(json)).toList();
        print('Total trips parsed: ${allTrips.length}');

        // Log semua trips
        print('\n--- ALL TRIPS ---');
        for (var trip in allTrips) {
          print('Trip ID: ${trip.id}');
          print('  Kapal: ${trip.kapal.namaKapal}');
          print('  Nahkoda ID: ${trip.nahkoda.id} (${trip.nahkoda.nama})');
          print('  Crew IDs: ${trip.awakKapal}');
          print('  Status: "${trip.status}" (lowercase: "${trip.status.toLowerCase().trim()}")');
          print('  Tanggal: ${trip.tanggalBerangkat}');
        }

        // Filter trips untuk user ini (nahkoda atau crew)
        final userTrips = allTrips.where((trip) {
          final isNahkoda = trip.nahkoda.id == currentUserId;
          final isCrew = trip.awakKapal.contains(currentUserId);
          print('\nChecking Trip ${trip.id} (${trip.kapal.namaKapal}):');
          print('  Is Nahkoda? $isNahkoda (${trip.nahkoda.id} == $currentUserId)');
          print('  Is Crew? $isCrew (${trip.awakKapal} contains $currentUserId)');
          return isNahkoda || isCrew;
        }).toList();

        print('\n--- USER TRIPS (Filtered) ---');
        print('Total trips for user: ${userTrips.length}');
        for (var trip in userTrips) {
          print('Trip: ${trip.kapal.namaKapal} - Status: "${trip.status}"');
        }

        // Split berdasarkan status
        _scheduledTrips = userTrips.where((trip) {
          final status = trip.status.toLowerCase().trim();
          return status == 'menunggu_dokumen' || 
                 status == 'menunggu_izin' || 
                 status == 'siap_berangkat' ||
                 status == 'disetujui' ||
                 status == 'scheduled' ||
                 status == 'approved' ||
                 status == 'pending';
        }).toList();

        _activeTrips = userTrips.where((trip) {
          final status = trip.status.toLowerCase().trim();
          print('🔍 Checking active: "$status" (original: "${trip.status}")');
          return status == 'berlayar' || 
                 status == 'sedang_melaut' ||
                 status == 'active' || 
                 status == 'sailing' ||
                 status == 'on_trip' ||
                 status == 'on trip' ||
                 status.contains('berlayar') ||
                 status.contains('melaut');
        }).toList();

        _completedTrips = userTrips.where((trip) {
          final status = trip.status.toLowerCase().trim();
          print('🔍 Checking completed: "$status" (original: "${trip.status}")');
          return status == 'selesai' || 
                 status == 'completed' || 
                 status == 'finished' ||
                 status == 'done' ||
                 status.contains('selesai');
        }).toList();

        print('\n--- CATEGORIZED TRIPS ---');
        print('Scheduled: ${_scheduledTrips.length}');
        print('Active: ${_activeTrips.length}');
        print('Completed: ${_completedTrips.length}');
        print('====================================\n');

        // Sort by date (newest first)
        _scheduledTrips.sort((a, b) => a.tanggalBerangkat.compareTo(b.tanggalBerangkat));
        _activeTrips.sort((a, b) => b.tanggalBerangkat.compareTo(a.tanggalBerangkat));
        _completedTrips.sort((a, b) => b.tanggalBerangkat.compareTo(a.tanggalBerangkat));
      }

      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      print('❌ ERROR in _loadTrips: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B4F9C), Color(0xFF2E5BA8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _errorMessage != null
                        ? _buildError()
                        : _buildTabContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(ResponsiveHelper.appBarPadding(context)),
      child: SizedBox(
        height: ResponsiveHelper.appBarHeight(context),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: ResponsiveHelper.appBarIconSize(context),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Expanded(
              child: Text(
                'Info Trip',
                style: TextStyle(
                  fontSize: ResponsiveHelper.appBarTitleSize(context),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: ResponsiveHelper.appBarIconSize(context) + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: const Color(0xFF1B4F9C),
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: [
          Tab(text: 'Terjadwal (${_scheduledTrips.length})'),
          Tab(text: 'Berlayar (${_activeTrips.length})'),
          Tab(text: 'Selesai (${_completedTrips.length})'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildTripList(_scheduledTrips, type: 'scheduled'),
          _buildTripList(_activeTrips, type: 'active'),
          _buildTripList(_completedTrips, type: 'completed'),
        ],
      ),
    );
  }

  Widget _buildTripList(List<TripModel> trips, {required String type}) {
    if (trips.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: trips.length,
        itemBuilder: (context, index) => _buildTripCard(trips[index], type),
      ),
    );
  }

  Widget _buildTripCard(TripModel trip, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(trip, type),
          _buildCardContent(trip),
        ],
      ),
    );
  }

  Widget _buildCardHeader(TripModel trip, String type) {
    List<Color> gradientColors;
    IconData icon;

    switch (type) {
      case 'scheduled':
        gradientColors = [Colors.orange[600]!, Colors.orange[700]!];
        icon = Icons.schedule;
        break;
      case 'active':
        gradientColors = [const Color(0xFF1B4F9C), const Color(0xFF2E5BA8)];
        icon = Icons.sailing;
        break;
      case 'completed':
        gradientColors = [Colors.grey[600]!, Colors.grey[700]!];
        icon = Icons.check_circle;
        break;
      default:
        gradientColors = [Colors.grey[600]!, Colors.grey[700]!];
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.kapal.namaKapal,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  trip.kapal.nomorRegistrasi,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(trip.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    final statusLower = status.toLowerCase();
    
    if (statusLower == 'menunggu_dokumen') {
      color = Colors.orange;
      text = 'Menunggu Dokumen';
    } else if (statusLower == 'menunggu_izin') {
      color = Colors.amber;
      text = 'Menunggu Izin';
    } else if (statusLower == 'disetujui' || statusLower == 'approved') {
      color = Colors.blue;
      text = 'Disetujui';
    } else if (statusLower == 'siap_berangkat' || statusLower == 'scheduled') {
      color = Colors.blue;
      text = 'Siap Berangkat';
    } else if (statusLower == 'berlayar' || statusLower == 'sedang_melaut' || statusLower == 'active' || statusLower == 'sailing') {
      color = Colors.green;
      text = 'Berlayar';
    } else if (statusLower == 'selesai' || statusLower == 'completed' || statusLower == 'finished') {
      color = Colors.teal;
      text = 'Selesai';
    } else if (statusLower == 'darurat' || statusLower == 'emergency') {
      color = Colors.red;
      text = 'Darurat';
    } else if (statusLower == 'ditolak' || statusLower == 'rejected') {
      color = Colors.red;
      text = 'Ditolak';
    } else {
      color = Colors.grey;
      text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCardContent(TripModel trip) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_today, 'Berangkat', 
            DateFormat('dd MMM yyyy, HH:mm').format(trip.tanggalBerangkat)),
          _buildInfoRow(Icons.event, 'Est. Pulang', 
            DateFormat('dd MMM yyyy').format(trip.estimasiPulang)),
          _buildInfoRow(Icons.access_time, 'Durasi', '${trip.durasi} hari'),
          _buildInfoRow(Icons.location_on, 'Area Tangkap', trip.areaTangkap.nama),
          _buildInfoRow(Icons.people, 'Crew', '${trip.getCrewCount()} orang'),
          _buildInfoRow(Icons.set_meal, 'Target Ikan', trip.targetIkan),
          _buildInfoRow(Icons.scale, 'Est. Berat', '${trip.estimasiBerat} kg'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    IconData icon;
    String title;
    String subtitle;

    switch (type) {
      case 'scheduled':
        icon = Icons.schedule;
        title = 'Tidak Ada Jadwal Terjadwal';
        subtitle = 'Belum ada trip yang dijadwalkan';
        break;
      case 'active':
        icon = Icons.sailing;
        title = 'Tidak Ada Trip Berlayar';
        subtitle = 'Belum ada trip yang sedang berlayar';
        break;
      case 'completed':
        icon = Icons.history;
        title = 'Belum Ada Trip Selesai';
        subtitle = 'Belum ada riwayat trip yang selesai';
        break;
      default:
        icon = Icons.info;
        title = 'Tidak Ada Data';
        subtitle = 'Belum ada data tersedia';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTrips,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4F9C),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
