import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/getAPi/vessel_service.dart';
import 'vessel/ice_management_screen.dart';
import 'vessel/vessel_documents_screen.dart';
import 'dart:convert';

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
  String _userRole = 'Crew';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkDocumentCompletion();
  }

  void _checkDocumentCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final isCompleted = prefs.getBool('personal_documents_completed') ?? false;
    
    if (!isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDocumentRequiredDialog();
      });
    } else {
      _loadUserRole();
      _loadVesselData();
    }
  }

  void _showDocumentRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
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
                child: const Icon(Icons.description, size: 40, color: Colors.orange),
              ),
              const SizedBox(height: 20),
              const Text(
                'Dokumen Belum Lengkap',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Anda harus melengkapi dokumen pribadi terlebih dahulu sebelum mengakses informasi kapal.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/document-completion').then((_) {
                    _checkDocumentCompletion();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Lengkapi Dokumen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = json.decode(userDataString);
      setState(() {
        _userRole = userData['role']?.toString() ?? 'Crew';
      });
    }
  }

  Future<void> _loadVesselData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('vessel_data');
      
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
  Widget build(BuildContext context) {
    final roleUpper = _userRole.toUpperCase();
    final isNahkoda = roleUpper == 'NAHKODA' || roleUpper == 'NAKHODA';

    return Scaffold(
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
                    SizedBox(height: 30),
                    _buildHeader(),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildVesselInfoCard(),
                          SizedBox(height: 16),
                          _buildMenuCard(
                            icon: Icons.description,
                            title: 'Dokumen Kapal',
                            subtitle: 'Lihat dokumen kapal',
                            color: Colors.blue,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VesselDocumentsScreen())),
                          ),
                          SizedBox(height: 16),
                          if (!isNahkoda)
                            _buildMenuCard(
                              icon: Icons.ac_unit,
                              title: 'Manajemen Es',
                              subtitle: 'Input & history es',
                              color: Colors.cyan,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IceManagementScreen())),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF1B4F9C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Lottie.asset('assets/animations/PreTrip.json', width: 100, height: 100),
          ),
          SizedBox(height: 16),
          Text('Detail Kapal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          SizedBox(height: 8),
          Text('Kelola data operasional kapal', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildVesselInfoCard() {
    final nahkoda = _vesselData?['nahkoda'] as Map<String, dynamic>?;
    final roleUpper = _userRole.toUpperCase();
    final isNahkoda = roleUpper == 'NAHKODA' || roleUpper == 'NAKHODA';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1B4F9C).withOpacity(0.1),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Color(0xFF1B4F9C), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.info_outline, color: Colors.white, size: 24),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informasi Kapal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4F9C))),
                    Text('Data terdaftar di sistem', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRow('Nama Kapal', vesselName, Icons.directions_boat_rounded, Color(0xFF1B4F9C)),
                SizedBox(height: 16),
                _buildInfoRow('Nomor Registrasi', vesselNumber, Icons.confirmation_number_outlined, Color(0xFF2563EB)),
                if (!isNahkoda) ...[
                  SizedBox(height: 16),
                  _buildInfoRow('Nahkoda', nahkoda?['nama'] ?? 'Tidak ada data', Icons.person, Color(0xFF10B981)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 32),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
