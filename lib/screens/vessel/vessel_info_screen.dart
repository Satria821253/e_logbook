import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';
import '../../services/getAPi/vessel_service.dart';
import '../../services/realtime_update_service.dart';
import 'fuel_management_screen.dart';
import 'ice_management_screen.dart';
import 'vessel_documents_screen.dart';
import 'fuel_summary_screen.dart';

class VesselInfoScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const VesselInfoScreen({Key? key, this.arguments}) : super(key: key);

  @override
  _VesselInfoScreenState createState() => _VesselInfoScreenState();
}

class _VesselInfoScreenState extends State<VesselInfoScreen> {
  String vesselName = "Belum memilih kapal";
  String vesselNumber = "-";
  Map<String, dynamic>? _vesselData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVesselData();
    
    // Register listener untuk auto-update
    RealtimeUpdateService.addListener('vessel', () {
      if (mounted) {
        print('🔔 Vessel data changed, auto-refreshing...');
        _loadVesselData();
      }
    });
  }

  Future<void> _loadVesselData() async {
    setState(() => _isLoading = true);
    try {
      final vesselData = await VesselService().getVesselData();
      
      if (mounted) {
        if (vesselData == null || vesselData['kapal'] == null) {
          setState(() {
            vesselName = 'Belum ada kapal yang ditugaskan';
            vesselNumber = '-';
            _vesselData = null;
            _isLoading = false;
          });
          _showNoVesselDialog();
        } else {
          setState(() {
            _vesselData = vesselData;
            final kapalInfo = vesselData['kapal'];
            vesselName = kapalInfo['namaKapal'] ?? 'Tidak ada nama';
            vesselNumber = kapalInfo['nomorRegistrasi'] ?? '-';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          vesselName = 'Belum ada kapal yang ditugaskan';
          vesselNumber = '-';
          _isLoading = false;
        });
      }
    }
  }

  void _showFuelAlreadyFilledDialog() {
    final kapalInfo = _vesselData?['kapal'];
    final namaKapal = kapalInfo?['namaKapal'] ?? '-';
    final nomorRegistrasi = kapalInfo?['nomorRegistrasi'] ?? '-';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_gas_station, size: 40, color: Color(0xFF1B4F9C)),
              ),
              SizedBox(height: 20),
              Text(
                'BBM Sudah Terisi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF1B4F9C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF1B4F9C).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_boat, color: Color(0xFF1B4F9C), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Nama Kapal',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      namaKapal,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.tag, color: Color(0xFF1B4F9C), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'No. Registrasi',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      nomorRegistrasi,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'BBM sudah terisi untuk trip ini.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Untuk update data, silakan ke menu Dokumen Kapal. BBM dapat diisi kembali setelah trip selesai.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1B4F9C),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showNoVesselDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.directions_boat_outlined, size: 40, color: Colors.orange),
              ),
              SizedBox(height: 20),
              Text(
                'Belum Ada Kapal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Anda belum ditugaskan ke kapal manapun. Silakan hubungi admin untuk assignment kapal.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    RealtimeUpdateService.removeListener('vessel');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final isNahkoda = user?.isNahkoda == true;

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
            title: Text('Informasi Kapal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          body: RefreshIndicator(
            onRefresh: _loadVesselData,
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeaderBanner(),
                        SizedBox(height: 24),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildVesselInfoCard(isNahkoda),
                              SizedBox(height: 24),
                              
                              // Section Title
                              Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 12),
                                child: Text(
                                  'Menu Operasional',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              
                              // Menu Grid
                              _buildMenuGrid(isNahkoda),
                              
                              SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Column(
        children: [
          SizedBox(height: 24),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            child: Lottie.asset('assets/animations/PreTrip.json', width: 80, height: 80),
          ),
          SizedBox(height: 16),
          Text(
            vesselName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4F9C),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF1B4F9C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              vesselNumber,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF1B4F9C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVesselInfoCard(bool isNahkoda) {
    final nahkoda = _vesselData?['nahkoda'] as Map<String, dynamic>?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B4F9C).withOpacity(0.1), Color(0xFF2563EB).withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outline, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Detail',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4F9C),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Data kapal terdaftar',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Info Nahkoda - HANYA untuk ABK
                if (!isNahkoda && nahkoda != null) ...[
                  _buildDetailRow(
                    icon: Icons.person,
                    label: 'Nahkoda',
                    value: nahkoda['nama'] ?? 'Tidak ada data',
                    color: Color(0xFF10B981),
                  ),
                  SizedBox(height: 16),
                ],
                
                // Status (example - bisa diganti dengan data real)
                _buildDetailRow(
                  icon: Icons.verified,
                  label: 'Status',
                  value: 'Aktif',
                  color: Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(bool isNahkoda) {
    return Column(
      children: [
        // Dokumen Kapal - Untuk semua
        _buildMenuCard(
          icon: Icons.description_rounded,
          title: 'Dokumen Kapal',
          subtitle: 'Sertifikat & dokumen kapal',
          gradient: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VesselDocumentsScreen()),
          ),
        ),
        SizedBox(height: 12),
        
        // Upload Sertifikat - Untuk semua
        _buildMenuCard(
          icon: Icons.upload_file_rounded,
          title: 'Upload Sertifikat',
          subtitle: 'Upload sertifikat jalan kapal',
          gradient: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
          onTap: () => Navigator.pushNamed(context, '/certificate-upload'),
        ),
        SizedBox(height: 12),
        
        // Menu untuk Nahkoda
        if (isNahkoda) ...[
          _buildMenuCard(
            icon: Icons.local_gas_station_rounded,
            title: 'Manajemen BBM',
            subtitle: 'Input & riwayat bahan bakar',
            gradient: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
            onTap: () async {
              final canAdd = await VesselService().canAddFuel();
              if (!canAdd && mounted) {
                _showFuelAlreadyFilledDialog();
              } else if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FuelManagementScreen()),
                );
              }
            },
          ),
          SizedBox(height: 12),
          _buildMenuCard(
            icon: Icons.analytics_rounded,
            title: 'Ringkasan BBM',
            subtitle: 'Statistik konsumsi bahan bakar',
            gradient: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FuelSummaryScreen()),
            ),
          ),
        ],
        
        // Menu untuk ABK
        if (!isNahkoda) ...[
          _buildMenuCard(
            icon: Icons.ac_unit_rounded,
            title: 'Manajemen Es',
            subtitle: 'Input & riwayat pembelian es',
            gradient: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => IceManagementScreen()),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.white.withOpacity(0.8)),
            ],
          ),
        ),
      ),
    );
  }
}