import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripInfoScreen extends StatefulWidget {
  const TripInfoScreen({Key? key}) : super(key: key);

  @override
  State<TripInfoScreen> createState() => _TripInfoScreenState();
}

class _TripInfoScreenState extends State<TripInfoScreen> {
  // Dummy data - nanti akan diambil dari API
  Map<String, dynamic>? _tripData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  Future<void> _loadTripData() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    // Dummy data - ganti dengan API call
    setState(() {
      _tripData = {
        'vesselName': 'KM Bahari Jaya',
        'vesselNumber': 'KP-12345-JKT',
        'crewCount': 8,
        'departureHarbor': 'Pelabuhan Muara Baru',
        'estimatedDuration': 5,
        'departureDate': DateTime.now().add(const Duration(days: 2)),
        'estimatedReturnDate': DateTime.now().add(const Duration(days: 7)),
        'fuelSupply': 500.0,
        'iceSupply': 1000.0,
        'status': 'scheduled', // scheduled, active, completed
      };
      _isLoading = false;
    });
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
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Info Trip',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _tripData == null
                          ? _buildNoTripScheduled()
                          : _buildTripInfo(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoTripScheduled() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Penjadwalan Trip',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Admin belum mengirim informasi trip.\nSilakan hubungi admin untuk penjadwalan trip.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _loadTripData(),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4F9C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripInfo() {
    final data = _tripData!;
    final departureDate = data['departureDate'] as DateTime;
    final returnDate = data['estimatedReturnDate'] as DateTime;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(data['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getStatusColor(data['status'])),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(data['status']),
                  size: 16,
                  color: _getStatusColor(data['status']),
                ),
                const SizedBox(width: 6),
                Text(
                  _getStatusText(data['status']),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(data['status']),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Data Kapal Section
          _buildSection(
            title: 'Data Kapal',
            icon: Icons.directions_boat,
            children: [
              _buildInfoRow('Nama Kapal', data['vesselName']),
              _buildInfoRow('Nomor Kapal', data['vesselNumber']),
              _buildInfoRow('Jumlah Crew', '${data['crewCount']} orang'),
            ],
          ),

          const SizedBox(height: 20),

          // Jadwal Trip Section
          _buildSection(
            title: 'Jadwal Trip',
            icon: Icons.schedule,
            children: [
              _buildInfoRow('Pelabuhan Keberangkatan', data['departureHarbor']),
              _buildInfoRow('Estimasi Trip', '${data['estimatedDuration']} hari'),
              _buildInfoRow('Tanggal Keberangkatan', DateFormat('dd MMM yyyy, HH:mm').format(departureDate)),
              _buildInfoRow('Estimasi Tanggal Kembali', DateFormat('dd MMM yyyy').format(returnDate)),
            ],
          ),

          const SizedBox(height: 20),

          // Persediaan Section
          _buildSection(
            title: 'Persediaan',
            icon: Icons.inventory,
            children: [
              _buildInfoRow('Persediaan Bensin', '${data['fuelSupply']} liter'),
              _buildInfoRow('Persediaan Es', '${data['iceSupply']} kg'),
            ],
          ),

          const SizedBox(height: 32),

          // Action Button
          if (data['status'] == 'scheduled')
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _startTrip(),
                icon: const Icon(Icons.sailing),
                label: const Text(
                  'Mulai Trip',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4F9C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1B4F9C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4F9C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'scheduled':
        return Icons.schedule;
      case 'active':
        return Icons.sailing;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'scheduled':
        return 'Terjadwal';
      case 'active':
        return 'Sedang Berlangsung';
      case 'completed':
        return 'Selesai';
      default:
        return 'Unknown';
    }
  }

  void _startTrip() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mulai Trip'),
        content: const Text('Apakah Anda yakin ingin memulai trip sekarang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to pre-trip form with trip data
              Navigator.pushNamed(
                context,
                '/pre-trip-form',
                arguments: _tripData,
              );
            },
            child: const Text('Mulai'),
          ),
        ],
      ),
    );
  }
}