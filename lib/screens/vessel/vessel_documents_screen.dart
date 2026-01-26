import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';
import '../../services/api/vessel_service.dart';
import '../../services/realtime/realtime_update_service.dart';
import 'vessel_certificates_screen.dart';
import 'vessel_bbm_screen.dart';
import 'vessel_ice_screen.dart';

class VesselDocumentsScreen extends StatefulWidget {
  const VesselDocumentsScreen({Key? key}) : super(key: key);

  @override
  State<VesselDocumentsScreen> createState() => _VesselDocumentsScreenState();
}

class _VesselDocumentsScreenState extends State<VesselDocumentsScreen> {
  Map<String, dynamic>? _documentsData;
  Map<String, dynamic>? _vesselData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    
    // Register listeners untuk auto-update
    RealtimeUpdateService.addListener('certificates', () {
      if (mounted) {
        print('🔔 Certificates changed, auto-refreshing...');
        _loadDocuments();
      }
    });
    
    RealtimeUpdateService.addListener('bbm', () {
      if (mounted) {
        print('🔔 BBM data changed, auto-refreshing...');
        _loadDocuments();
      }
    });
    
    RealtimeUpdateService.addListener('ice', () {
      if (mounted) {
        print('🔔 Ice data changed, auto-refreshing...');
        _loadDocuments();
      }
    });
    
    RealtimeUpdateService.addListener('vessel', () {
      if (mounted) {
        print('🔔 Vessel data changed, auto-refreshing...');
        _loadDocuments();
      }
    });
  }

  @override
  void dispose() {
    RealtimeUpdateService.removeListener('certificates');
    RealtimeUpdateService.removeListener('bbm');
    RealtimeUpdateService.removeListener('ice');
    RealtimeUpdateService.removeListener('vessel');
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      // Load kedua API secara paralel untuk lebih cepat
      final results = await Future.wait([
        VesselService().getVesselData(),
        VesselService().getVesselDocuments(),
      ]);
      
      final vesselData = results[0];
      final data = results[1] as Map<String, dynamic>;
      
      print('📄 Documents data received:');
      print('   Sertifikat Jalan: ${(data['sertifikatJalan'] as List).length} items');
      print('   Data BBM: ${(data['dataBahanBakar'] as List).length} items');
      print('👨✈️ Nahkoda: ${vesselData?['nahkoda']?['nama']}');
      
      setState(() {
        _documentsData = data;
        _vesselData = vesselData;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading documents: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Gagal memuat dokumen: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final kapalInfo = _documentsData?['kapal'];
    
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
            title: Text(
              'Dokumen Kapal',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeaderBanner(kapalInfo, isNahkoda),
                      SizedBox(height: 24),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 12),
                              child: Text(
                                'Menu Dokumen',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            if (isNahkoda) ...[
                              _buildMenuCard(
                                icon: Icons.local_gas_station_rounded,
                                title: 'Data BBM',
                                subtitle: 'Riwayat pengisian bahan bakar',
                                gradient: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VesselBBMScreen(documentsData: _documentsData),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 12),
                              _buildMenuCard(
                                icon: Icons.ac_unit_rounded,
                                title: 'Data Es',
                                subtitle: 'Riwayat pembelian es',
                                gradient: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VesselIceScreen(),
                                    ),
                                  );
                                },
                              ),
                            ] else ...[
                              _buildMenuCard(
                                icon: Icons.ac_unit_rounded,
                                title: 'Data Es',
                                subtitle: 'Riwayat pembelian es',
                                gradient: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VesselIceScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                            SizedBox(height: 12),
                            _buildMenuCard(
                              icon: Icons.description_rounded,
                              title: 'Sertifikat Jalan',
                              subtitle: 'Dokumen sertifikat kapal',
                              gradient: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VesselCertificatesScreen(documentsData: _documentsData),
                                  ),
                                );
                                if (result == true && mounted) {
                                  _loadDocuments();
                                }
                              },
                            ),
                            SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeaderBanner(Map<String, dynamic>? kapalInfo, bool isNahkoda) {
    final vesselName = kapalInfo?['namaKapal'] ?? 'Tidak ada nama';
    final vesselNumber = kapalInfo?['nomorRegistrasi'] ?? '-';
    final nahkodaName = _vesselData?['nahkoda']?['nama'];

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
            child: Lottie.asset(
              'assets/animations/PreTrip.json',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.description_rounded, size: 50, color: Color(0xFF1B4F9C));
              },
            ),
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
          if (!isNahkoda && nahkodaName != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 16, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    'Nahkoda: $nahkodaName',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 24),
        ],
      ),
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