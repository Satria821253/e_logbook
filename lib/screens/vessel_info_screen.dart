import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
import 'dart:convert';

class VesselInfoScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  
  const VesselInfoScreen({Key? key, this.arguments}) : super(key: key);

  @override
  _VesselInfoScreenState createState() => _VesselInfoScreenState();
}

class _VesselInfoScreenState extends State<VesselInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fuelController = TextEditingController();
  final _iceController = TextEditingController();

  // Data dari web (mock data)
  String vesselName = "KM Bahari Jaya";
  String vesselNumber = "GT-001-2024";

  List<PlatformFile> _certificateFiles = [];
  bool _isLoading = false;
  List<Map<String, dynamic>>? _documentData; // Store document data
  String? _source;
  bool _isDataSubmitted = false; // Track if data already submitted

  @override
  void initState() {
    super.initState();
    // Extract arguments
    if (widget.arguments != null) {
      _source = widget.arguments!['source'];
      _documentData = widget.arguments!['documents'];
    }
    
    // Always load saved data (both from profile and document-completion)
    _loadSavedData();
  }
  
  void _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load fuel and ice data
      _fuelController.text = prefs.getString('vessel_fuel') ?? '';
      _iceController.text = prefs.getString('vessel_ice') ?? '';
      
      // Check if data was already submitted
      _isDataSubmitted = prefs.getBool('vessel_submitted') ?? false;
      
      // Load saved certificate files
      final savedFiles = prefs.getStringList('vessel_certificates') ?? [];
      _certificateFiles = savedFiles.map((fileJson) {
        final fileData = json.decode(fileJson);
        return PlatformFile(
          name: fileData['name'],
          size: fileData['size'],
          path: fileData['path'],
        );
      }).toList();
    });
    
    print('DEBUG: Loaded vessel data - Fuel: ${_fuelController.text}, Ice: ${_iceController.text}, Certificates: ${_certificateFiles.length}, Submitted: $_isDataSubmitted');
  }
  
  void _saveCompletionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vessel_completed', true);
    await prefs.setString('vessel_fuel', _fuelController.text);
    await prefs.setString('vessel_ice', _iceController.text);
    await prefs.setBool('vessel_submitted', _isDataSubmitted);
    
    // Save certificate files
    final filesJson = _certificateFiles.map((file) => json.encode({
      'name': file.name,
      'size': file.size,
      'path': file.path ?? '/mock/path',
    })).toList();
    await prefs.setStringList('vessel_certificates', filesJson);
    
    print('Vessel completion status saved');
  }
  
  void _markFullyCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('full_process_completed', true);
    print('Full process completion saved globally');
  }

  @override
  void dispose() {
    _fuelController.dispose();
    _iceController.dispose();
    super.dispose();
  }

  Future<void> _pickCertificateFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _certificateFiles.addAll(result.files);
        });
        
        // Save progress immediately
        _saveProgress();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('${result.files.length} file berhasil dipilih'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Gagal memilih file'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _removeCertificate(int index) {
    setState(() {
      _certificateFiles.removeAt(index);
    });
    // Save progress immediately
    _saveProgress();
  }
  
  void _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vessel_fuel', _fuelController.text);
    await prefs.setString('vessel_ice', _iceController.text);
    
    // Save certificate files
    final filesJson = _certificateFiles.map((file) => json.encode({
      'name': file.name,
      'size': file.size,
      'path': file.path ?? '/mock/path',
    })).toList();
    await prefs.setStringList('vessel_certificates', filesJson);
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _saveVesselInfo() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if coming from profile without completing documents first
    if (_source != 'document-completion' && !_isDataSubmitted) {
      _showDocumentRequiredDialog();
      return;
    }
    
    // Check if certificates are uploaded when coming from document completion
    if (_source == 'document-completion' && _certificateFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sertifikat kapal harus diupload'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Data berhasil dikirim ke admin'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      
      // Save data locally and mark as completed globally
      setState(() {
        _isDataSubmitted = true;
      });
      
      // Save completion status globally (simulate with static/shared preference)
      _saveCompletionStatus();
      _markFullyCompleted();

      // Navigate back based on source
      if (_source == 'document-completion') {
        // Mark as fully completed and go back to main screen (home tab)
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        // Default: just pop back to profile
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan data'),
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
                    _buildSupplySection(),
                    SizedBox(height: ResponsiveHelper.height(context, mobile: 16, tablet: 24)),
                    _buildCertificateSection(),
                    SizedBox(height: ResponsiveHelper.height(context, mobile: 24, tablet: 32)),
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
    final uploadedDocs = _documentData!.where((doc) => doc['isUploaded']).toList();
    
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
              color: Colors.green.withOpacity(0.1),
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
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.check_circle,
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
                        'Dokumen Terupload',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
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
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.green, size: 20),
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
                    Icon(Icons.check, color: Colors.green, size: 16),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
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
                    Icons.inventory_2_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Persediaan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4F9C),
                      ),
                    ),
                    Text(
                      'Input stok saat ini',
                      style: TextStyle(fontSize: 12, color:Colors.grey[600]),
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
                TextFormField(
                  controller: _fuelController,
                  onChanged: (value) => _saveProgress(), // Auto-save on change
                  decoration: InputDecoration(
                    labelText: 'Bensin',
                    hintText: 'Masukkan jumlah liter',
                    suffixText: 'Liter',
                    prefixIcon: Container(
                      margin: EdgeInsets.all(12),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.local_gas_station,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.orange, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Jumlah bensin harus diisi';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _iceController,
                  onChanged: (value) => _saveProgress(), // Auto-save on change
                  decoration: InputDecoration(
                    labelText: 'Es',
                    hintText: 'Masukkan jumlah kilogram',
                    suffixText: 'Kg',
                    prefixIcon: Container(
                      margin: EdgeInsets.all(12),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.ac_unit, color: Colors.blue, size: 20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Jumlah es harus diisi';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCertificateSection() {
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
                    Icons.verified_user_outlined,
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
                        'Sertifikat Kapal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4F9C),
                        ),
                      ),
                      Text(
                        'Upload dokumen resmi dari admin',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _pickCertificateFiles,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade50,
                          Colors.blue.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade300,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.cloud_upload_outlined,
                            size: 40,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Pilih File',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'PDF, DOC, atau Gambar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_certificateFiles.isNotEmpty) ...[
                 
                  SizedBox(height: 12),
                  ...List.generate(_certificateFiles.length, (index) {
                    final file = _certificateFiles[index];
                    final extension = file.extension ?? '';
                    final fileSize = file.size / 1024;

                    return Container(
                      margin: EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getFileColor(extension).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getFileIcon(extension),
                              color: _getFileColor(extension),
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getFileColor(
                                          extension,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        extension.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getFileColor(extension),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      fileSize < 1024
                                          ? '${fileSize.toStringAsFixed(0)} KB'
                                          : '${(fileSize / 1024).toStringAsFixed(1)} MB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!_isDataSubmitted)
                            IconButton(
                              onPressed: () => _removeCertificate(index),
                              icon: Icon(
                                Icons.close_rounded,
                                color: Colors.red.shade400,
                              ),
                              constraints: BoxConstraints(),
                              padding: EdgeInsets.all(8),
                              splashRadius: 20,
                            ),
                        ],
                      ),
                    );
                  }),
                ],
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
