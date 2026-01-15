import 'package:flutter/material.dart';
import '../services/getAPi/vessel_service.dart';

class VesselSelectionScreen extends StatefulWidget {
  const VesselSelectionScreen({Key? key}) : super(key: key);

  @override
  State<VesselSelectionScreen> createState() => _VesselSelectionScreenState();
}

class _VesselSelectionScreenState extends State<VesselSelectionScreen> {
  final VesselService _vesselService = VesselService();
  List<Map<String, dynamic>> _vessels = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVessels();
  }

  Future<void> _loadVessels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vessels = await _vesselService.getVessels();
      setState(() {
        _vessels = vessels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Kapal'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadVessels,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _vessels.isEmpty
                  ? const Center(child: Text('Tidak ada kapal tersedia'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _vessels.length,
                      itemBuilder: (context, index) {
                        final vessel = _vessels[index];
                        return _buildVesselCard(vessel);
                      },
                    ),
    );
  }

  Widget _buildVesselCard(Map<String, dynamic> vessel) {
    final nahkoda = vessel['nahkoda'] as Map<String, dynamic>?;
    final abkCount = vessel['abkCount'] ?? 0;
    final statusOperasional = vessel['statusOperasional'] ?? 'unknown';
    final statusPelayaran = vessel['statusPelayaran'] ?? 'unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _selectVessel(vessel),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_boat, size: 32, color: Color(0xFF2196F3)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vessel['namaKapal'] ?? 'Tidak ada nama',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vessel['nomorKapal'] ?? '-',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(statusOperasional),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.person,
                      'Nahkoda',
                      nahkoda?['nama'] ?? 'Tidak ada',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.group,
                      'ABK',
                      '$abkCount orang',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.straighten,
                      'Panjang',
                      '${vessel['panjangKapal'] ?? '0'} m',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.sailing,
                      'Status',
                      _getStatusPelayaranText(statusPelayaran),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'active':
        color = Colors.green;
        text = 'Aktif';
        break;
      case 'maintenance':
        color = Colors.orange;
        text = 'Maintenance';
        break;
      case 'inactive':
        color = Colors.red;
        text = 'Tidak Aktif';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStatusPelayaranText(String status) {
    switch (status) {
      case 'docked':
        return 'Berlabuh';
      case 'sailing':
        return 'Berlayar';
      case 'maintenance':
        return 'Maintenance';
      default:
        return status;
    }
  }

  Future<void> _selectVessel(Map<String, dynamic> vessel) async {
    try {
      await _vesselService.saveSelectedVessel(vessel);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kapal ${vessel['namaKapal']} dipilih'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, vessel);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih kapal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
