import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
import '../services/getAPi/document_service.dart';
import '../services/getAPi/vessel_service.dart';
import 'dart:convert';

class VesselInfoScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  
  const VesselInfoScreen({Key? key, this.arguments}) : super(key: key);

  @override
  _VesselInfoScreenState createState() => _VesselInfoScreenState();
}

class _VesselInfoScreenState extends State<VesselInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Fuel data controllers
  String _jenisBahanBakar = 'Solar';
  final _jumlahLiterController = TextEditingController();
  final _hargaPerLiterController = TextEditingController();
  final _totalHargaController = TextEditingController();
  DateTime? _tanggalPengisian;
  final _lokasiPengisianController = TextEditingController();
  final _keteranganBBMController = TextEditingController();
  String? _buktiBBMPath;

  // Data kapal dari API
  String vesselName = "Belum memilih kapal";
  String vesselNumber = "-";
  Map<String, dynamic>? _vesselData;

  bool _isLoading = false;
  List<Map<String, dynamic>>? _documentData;
  String? _source;
  bool _isDataSubmitted = false;
  String _userRole = 'ABK';
  List<Map<String, dynamic>> _roleDocuments = [];

  @override
  void initState() {
    super.initState();
    if (widget.arguments != null) {
      _source = widget.arguments!['source'];
      _documentData = widget.arguments!['documents'];
    }
    
    _loadUserRole();
    _loadSavedData();
    _loadVesselData();
  }
  
  Future<void> _loadVesselData() async {
    try {
      final vesselData = await VesselService().getVesselData();
      if (mounted && vesselData['kapal'] != null) {
        setState(() {
          _vesselData = vesselData;
          final kapalInfo = vesselData['kapal'];
          vesselName = kapalInfo['namaKapal'] ?? 'Tidak ada nama';
          vesselNumber = kapalInfo['nomorRegistrasi'] ?? '-';
        });
      }
    } catch (e) {
      print('Error loading vessel data: $e');
    }
  }
  
  void _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    
    if (userDataString != null) {
      final userData = json.decode(userDataString);
      setState(() {
        _userRole = userData['role']?.toString() ?? 'ABK';
        _roleDocuments = _getRoleDocuments(_userRole);
      });
    }
  }
  
  List<Map<String, dynamic>> _getRoleDocuments(String role) {
    final roleUpper = role.toUpperCase();
    if (roleUpper == 'NAHKODA' || roleUpper == 'NAKHODA') {
      return [
        {'name': 'Sertifikat Nahkoda', 'serverName': 'Sertifikat Nahkoda', 'hasFile': false, 'filePath': null, 'nomorDokumen': null, 'tanggalBerlaku': null, 'keterangan': null, 'requireNumber': true, 'requireDate': true},
      ];
    } else if (roleUpper == 'CREW' || roleUpper == 'ABK') {
      return [
        {'name': 'Sertifikat Crew', 'serverName': 'Sertifikat Nahkoda', 'hasFile': false, 'filePath': null, 'nomorDokumen': null, 'tanggalBerlaku': null, 'keterangan': null, 'requireNumber': true, 'requireDate': true},
      ];
    }
    return [];
  }
  
  void _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDataSubmitted = prefs.getBool('vessel_submitted') ?? false;
    });
    
    print('DEBUG: Loaded vessel data - Submitted: $_isDataSubmitted');
  }
  
  void _saveCompletionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vessel_completed', true);
    await prefs.setBool('vessel_submitted', _isDataSubmitted);
    
    print('Vessel completion status saved');
  }
  
  void _markFullyCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('full_process_completed', true);
    await prefs.setBool('documents_pending', true);
    print('Full process completion saved globally');
  }
  
  Future<void> _saveDocumentStatus(List<Map<String, dynamic>> documents) async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    
    if (userDataString != null) {
      final userData = json.decode(userDataString);
      final userId = userData['id']?.toString() ?? 'unknown';
      final userRole = userData['role']?.toString() ?? 'unknown';
      
      final documentsKey = 'documents_${userId}_$userRole';
      final documentsJson = documents.map((doc) => json.encode(doc)).toList();
      await prefs.setStringList(documentsKey, documentsJson);
    }
  }
  
  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                child: Icon(
                  Icons.pending,
                  size: 40,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Dokumen Sedang Diverifikasi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Dokumen Anda telah berhasil dikirim dan sedang menunggu verifikasi dari admin.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/document-status');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Lihat Status',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (_source == 'document-completion') {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  @override
  void dispose() {
    _jumlahLiterController.dispose();
    _hargaPerLiterController.dispose();
    _totalHargaController.dispose();
    _lokasiPengisianController.dispose();
    _keteranganBBMController.dispose();
    super.dispose();
  }
  
  void _calculateTotalHarga() {
    final jumlah = double.tryParse(_jumlahLiterController.text) ?? 0;
    final harga = double.tryParse(_hargaPerLiterController.text) ?? 0;
    final total = jumlah * harga;
    _totalHargaController.text = total.toStringAsFixed(0);
  }

  Future<void> _saveVesselInfo() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if coming from profile without completing documents first
    if (_source != 'document-completion' && !_isDataSubmitted) {
      _showDocumentRequiredDialog();
      return;
    }
    
    // Check if role documents are uploaded when coming from document completion
    if (_source == 'document-completion') {
      final roleDocsComplete = _roleDocuments.every((doc) => doc['hasFile'] == true);
      if (!roleDocsComplete) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sertifikat ${_userRole == 'NAHKODA' ? 'Nahkoda' : 'Crew'} harus diupload'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Upload semua dokumen pribadi ke API
      List<Map<String, dynamic>> uploadedDocs = [];
      if (_documentData != null) {
        for (var doc in _documentData!) {
          if (doc['hasFile'] == true) {
            print('📤 Uploading: ${doc['name']}');
            final result = await DocumentService.uploadDocument(
              jenisDokumen: doc['serverName'],
              nomorDokumen: doc['requireNumber'] == true ? doc['nomorDokumen'] : null,
              tanggalBerlaku: doc['requireDate'] == true ? doc['tanggalBerlaku'] : null,
              filePath: doc['filePath']!,
              keterangan: doc['keterangan']?.isNotEmpty == true ? doc['keterangan'] : null,
            );
            print('📥 Result: ${result['success']}');
            
            if (result['success'] == true && result['data'] != null) {
              doc['status'] = result['data']['status'] ?? 'pending';
              doc['documentId'] = result['data']['id'];
              doc['uploadedAt'] = result['data']['uploadedAt'];
              uploadedDocs.add(doc);
            }
            
            // Delay 3.5 detik antar upload untuk menghindari race condition
            await Future.delayed(const Duration(milliseconds: 3500));
          }
        }
      }
      
      // Upload dokumen role-specific ke API
      for (var doc in _roleDocuments) {
        if (doc['hasFile'] == true) {
          print('📤 Uploading: ${doc['name']}');
          final result = await DocumentService.uploadDocument(
            jenisDokumen: doc['serverName'],
            nomorDokumen: doc['requireNumber'] == true ? doc['nomorDokumen'] : null,
            tanggalBerlaku: doc['requireDate'] == true ? doc['tanggalBerlaku'] : null,
            filePath: doc['filePath']!,
            keterangan: doc['keterangan']?.isNotEmpty == true ? doc['keterangan'] : null,
          );
          print('📥 Result: ${result['success']}');
          
          if (result['success'] == true && result['data'] != null) {
            doc['status'] = result['data']['status'] ?? 'pending';
            doc['documentId'] = result['data']['id'];
            doc['uploadedAt'] = result['data']['uploadedAt'];
            uploadedDocs.add(doc);
          }
          
          // Delay 3.5 detik antar upload untuk menghindari race condition
          await Future.delayed(const Duration(milliseconds: 3500));
        }
      }
      
      // Save document status to local storage
      await _saveDocumentStatus(uploadedDocs);

      // Upload data bahan bakar ke API (hanya untuk NAHKODA)
      final roleUpper = _userRole.toUpperCase();
      if ((roleUpper == 'NAHKODA' || roleUpper == 'NAKHODA')) {
        // Validate fuel data
        if (_tanggalPengisian == null) {
          throw Exception('Tanggal pengisian bahan bakar harus diisi');
        }
        
        final jumlahLiter = double.tryParse(_jumlahLiterController.text);
        final hargaPerLiter = double.tryParse(_hargaPerLiterController.text);
        final totalHarga = double.tryParse(_totalHargaController.text);
        
        if (jumlahLiter == null || hargaPerLiter == null || totalHarga == null) {
          throw Exception('Data bahan bakar tidak valid');
        }
        
        print('📤 Uploading fuel data...');
        final fuelResult = await VesselService().uploadBahanBakar(
          jenisBahanBakar: _jenisBahanBakar,
          jumlahLiter: jumlahLiter,
          hargaPerLiter: hargaPerLiter,
          totalHarga: totalHarga,
          tanggalPengisian: _tanggalPengisian!.toIso8601String(),
          lokasiPengisian: _lokasiPengisianController.text.isNotEmpty ? _lokasiPengisianController.text : null,
          keterangan: _keteranganBBMController.text.isNotEmpty ? _keteranganBBMController.text : null,
          buktiFilePath: _buktiBBMPath,
        );
        print('📥 Fuel upload result: ${fuelResult['success']}');
      }

      await Future.delayed(const Duration(seconds: 1));

      // Show pending popup
      if (mounted) {
        _showPendingDialog();
      }
      
      setState(() {
        _isDataSubmitted = true;
      });
      
      _saveCompletionStatus();
      _markFullyCompleted();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim dokumen: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _showDocumentRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.warning,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Dokumen Belum Lengkap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Anda belum mengisi dokumen yang lainnya. Silakan lengkapi dokumen wajib terlebih dahulu sebelum mengirim data kapal.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Close vessel info and go to document completion
              Navigator.pop(context); // Close vessel info
              Navigator.pushNamed(context, '/document-completion');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4F9C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Isi Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(
          color: Colors.white, // ← warna arrow back
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Informasi Kapal',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: ResponsiveHelper.height(context, mobile: 30, tablet: 40)),
            _buildHeaderGradient(),
            SizedBox(height: ResponsiveHelper.height(context, mobile: 16, tablet: 24)),
            Padding(
              padding: ResponsiveHelper.padding(context, mobile: 16, tablet: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildVesselInfoCard(),
                    SizedBox(height: ResponsiveHelper.height(context, mobile: 16, tablet: 24)),
                    if (_documentData != null) _buildDocumentSummary(),
                    if (_documentData != null) SizedBox(height: ResponsiveHelper.height(context, mobile: 16, tablet: 24)),
                    if (_roleDocuments.isNotEmpty) _buildRoleDocumentSection(),
                    if (_roleDocuments.isNotEmpty) SizedBox(height: ResponsiveHelper.height(context, mobile: 16, tablet: 24)),
                    if (_userRole.toUpperCase() == 'NAHKODA' || _userRole.toUpperCase() == 'NAKHODA') _buildSupplySection(),
                    if (_userRole.toUpperCase() == 'NAHKODA' || _userRole.toUpperCase() == 'NAKHODA') SizedBox(height: ResponsiveHelper.height(context, mobile: 16, tablet: 24)),
                    _buildSaveButton(),
                    SizedBox(height: ResponsiveHelper.height(context, mobile: 16, tablet: 24)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderGradient() {
    return Center(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1B4F9C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Lottie.asset(
              'assets/animations/PreTrip.json',
              width: ResponsiveHelper.width(context, mobile: 100, tablet: 120),
              height: ResponsiveHelper.height(context, mobile: 100, tablet: 120),
            ),
          ),
          SizedBox(height: ResponsiveHelper.height(context, mobile: 16, tablet: 20)),
          Text(
            'Lengkapi Data Kapal',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, mobile: 20, tablet: 24),
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: ResponsiveHelper.height(context, mobile: 8, tablet: 12)),
          Text(
            'Pastikan semua informasi terisi dengan benar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, mobile: 13, tablet: 15),
              color: Colors.grey[600],
            ),
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1B4F9C).withOpacity(0.1),
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
                    color: Color(0xFF1B4F9C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Kapal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4F9C),
                      ),
                    ),
                    Text(
                      'Data terdaftar di sistem',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRowModern(
                  'Nama Kapal',
                  vesselName,
                  Icons.directions_boat_rounded,
                  Color(0xFF1B4F9C),
                ),
                SizedBox(height: 16),
                _buildInfoRowModern(
                  'Nomor Registrasi',
                  vesselNumber,
                  Icons.confirmation_number_outlined,
                  Color(0xFF2563EB),
                ),
                if (!isNahkoda && nahkoda != null) ...[
                  SizedBox(height: 16),
                  _buildInfoRowModern(
                    'Nahkoda',
                    nahkoda['nama'] ?? '-',
                    Icons.person,
                    Color(0xFF10B981),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowModern(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 12),
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


  Widget _buildDocumentSummary() {
    final uploadedDocs = _documentData!.where((doc) => doc['hasFile'] == true).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
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
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.description,
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
                        'Dokumen Pribadi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      Text(
                        '${uploadedDocs.length} dokumen siap dikirim',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: uploadedDocs.map((doc) => Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        doc['name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDocumentSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1B4F9C).withOpacity(0.1),
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
                    color: Color(0xFF1B4F9C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.verified_user,
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
                        'Sertifikat ${_userRole == 'NAHKODA' || _userRole == 'NAKHODA' ? 'Nahkoda' : 'Crew'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4F9C),
                        ),
                      ),
                      Text(
                        'Upload sertifikat sesuai role Anda',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
              children: _roleDocuments.asMap().entries.map((entry) {
                final index = entry.key;
                final doc = entry.value;
                final hasFile = doc['hasFile'] == true;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasFile ? Colors.blue.shade300 : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            hasFile ? Icons.insert_drive_file : Icons.description,
                            color: hasFile ? Colors.blue : Colors.grey[600],
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc['name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (hasFile && doc['filePath'] != null)
                                  Text(
                                    doc['filePath'].split('/').last,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _uploadRoleDocument(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasFile ? Colors.orange : Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              hasFile ? 'Ganti' : 'Pilih',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _uploadRoleDocument(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: _buildUploadOptions(index),
      ),
    );
  }

  Widget _buildUploadOptions(int index) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Pilih Sumber File',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildOptionTile(
            icon: Icons.camera_alt,
            title: 'Ambil Gambar',
            onTap: () => _takePhoto(index),
          ),
          SizedBox(height: 12),
          _buildOptionTile(
            icon: Icons.photo_library,
            title: 'Pilih dari Galeri',
            onTap: () => _pickImage(index),
          ),
          SizedBox(height: 12),
          _buildOptionTile(
            icon: Icons.folder,
            title: 'File Dokumen',
            onTap: () => _pickFile(index),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1B4F9C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1B4F9C),
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto(int index) async {
    Navigator.pop(context);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image?.path != null) {
        _handleRoleFileSelected(index, image!.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil foto: $e')),
      );
    }
  }

  Future<void> _pickImage(int index) async {
    Navigator.pop(context);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image?.path != null) {
        _handleRoleFileSelected(index, image!.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error memilih gambar: $e')),
      );
    }
  }

  Future<void> _pickFile(int index) async {
    Navigator.pop(context);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result?.files.single.path != null) {
        _handleRoleFileSelected(index, result!.files.single.path!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error memilih file: $e')),
      );
    }
  }

  void _handleRoleFileSelected(int index, String filePath) async {
    final details = await _showDocumentDetailsDialog(index);
    
    if (details == null) return;

    if (mounted) {
      setState(() {
        _roleDocuments[index]['hasFile'] = true;
        _roleDocuments[index]['filePath'] = filePath;
        _roleDocuments[index]['nomorDokumen'] = details['nomorDokumen'];
        _roleDocuments[index]['tanggalBerlaku'] = details['tanggalBerlaku'];
        _roleDocuments[index]['keterangan'] = details['keterangan'];
      });
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dokumen berhasil disimpan'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<Map<String, String>?> _showDocumentDetailsDialog(int index) async {
    final nomorController = TextEditingController();
    final keteranganController = TextEditingController();
    DateTime? selectedDate;

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Detail Dokumen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nomorController,
                        maxLength: 50,
                        decoration: InputDecoration(
                          labelText: 'Nomor Dokumen *',
                          hintText: 'Masukkan nomor dokumen',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      StatefulBuilder(
                        builder: (context, setState) => InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2050),
                            );
                            if (date != null) {
                              setState(() => selectedDate = date);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Tanggal Berlaku *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              selectedDate != null
                                  ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                  : 'Pilih tanggal',
                              style: TextStyle(
                                color: selectedDate != null ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: keteranganController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Keterangan (opsional)',
                          hintText: 'Tambahkan keterangan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Batal'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (nomorController.text.isEmpty || nomorController.text.length < 3 || selectedDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Nomor dokumen dan tanggal berlaku wajib diisi'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context, {
                            'nomorDokumen': nomorController.text,
                            'tanggalBerlaku': '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                            'keterangan': keteranganController.text,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1B4F9C),
                        ),
                        child: Text('Simpan'),
                      ),
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

  Widget _buildSupplySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
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
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.local_gas_station,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Bahan Bakar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    Text(
                      'Pengisian bahan bakar terakhir',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _jenisBahanBakar,
                  decoration: InputDecoration(
                    labelText: 'Jenis Bahan Bakar *',
                    prefixIcon: Icon(Icons.local_gas_station, color: Colors.orange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['Solar', 'Bensin', 'Pertamax']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _jenisBahanBakar = value!);
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _jumlahLiterController,
                  decoration: InputDecoration(
                    labelText: 'Jumlah Liter *',
                    hintText: 'Masukkan jumlah liter',
                    suffixText: 'Liter',
                    prefixIcon: Icon(Icons.water_drop, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => _calculateTotalHarga(),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Wajib diisi';
                    if (double.tryParse(value!) == null) return 'Harus angka';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _hargaPerLiterController,
                  decoration: InputDecoration(
                    labelText: 'Harga Per Liter *',
                    hintText: 'Masukkan harga per liter',
                    prefixText: 'Rp ',
                    prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _calculateTotalHarga(),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Wajib diisi';
                    if (double.tryParse(value!) == null) return 'Harus angka';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _totalHargaController,
                  decoration: InputDecoration(
                    labelText: 'Total Harga *',
                    prefixText: 'Rp ',
                    prefixIcon: Icon(Icons.payments, color: Colors.purple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Hitung otomatis dari jumlah x harga';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _tanggalPengisian = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tanggal Pengisian *',
                      prefixIcon: Icon(Icons.calendar_today, color: Colors.red),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _tanggalPengisian != null
                          ? '${_tanggalPengisian!.day}/${_tanggalPengisian!.month}/${_tanggalPengisian!.year}'
                          : 'Pilih tanggal pengisian',
                      style: TextStyle(
                        color: _tanggalPengisian != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _lokasiPengisianController,
                  decoration: InputDecoration(
                    labelText: 'Lokasi Pengisian',
                    hintText: 'Contoh: SPBU Pelabuhan',
                    prefixIcon: Icon(Icons.location_on, color: Colors.red),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _keteranganBBMController,
                  decoration: InputDecoration(
                    labelText: 'Keterangan',
                    hintText: 'Tambahkan keterangan',
                    prefixIcon: Icon(Icons.note, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Bukti Pengisian (Opsional)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (_buktiBBMPath != null) ...[
                        SizedBox(height: 8),
                        Text(
                          _buktiBBMPath!.split('/').last,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? image = await picker.pickImage(
                                  source: ImageSource.camera,
                                  imageQuality: 80,
                                );
                                if (image != null) {
                                  setState(() => _buktiBBMPath = image.path);
                                }
                              },
                              icon: Icon(Icons.camera_alt, size: 18),
                              label: Text('Kamera'),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? image = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 80,
                                );
                                if (image != null) {
                                  setState(() => _buktiBBMPath = image.path);
                                }
                              },
                              icon: Icon(Icons.photo_library, size: 18),
                              label: Text('Galeri'),
                            ),
                          ),
                        ],
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


  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: ResponsiveHelper.height(context, mobile: 56, tablet: 64),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(ResponsiveHelper.width(context, mobile: 16, tablet: 20)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1B4F9C).withOpacity(0.3),
            blurRadius: ResponsiveHelper.width(context, mobile: 12, tablet: 16),
            offset: Offset(0, ResponsiveHelper.height(context, mobile: 6, tablet: 8)),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveVesselInfo,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveHelper.width(context, mobile: 16, tablet: 20)),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: ResponsiveHelper.height(context, mobile: 24, tablet: 28),
                width: ResponsiveHelper.width(context, mobile: 24, tablet: 28),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send,
                    color: Colors.white,
                    size: ResponsiveHelper.width(context, mobile: 24, tablet: 28),
                  ),
                  SizedBox(width: ResponsiveHelper.width(context, mobile: 12, tablet: 16)),
                  Text(
                    'Kirim ke Admin',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(context, mobile: 16, tablet: 18),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
