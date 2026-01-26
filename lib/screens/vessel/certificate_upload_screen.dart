import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../services/api/vessel_service.dart';
import '../../services/api/document_service.dart';
import '../../services/realtime/realtime_update_service.dart';

class CertificateUploadScreen extends StatefulWidget {
  const CertificateUploadScreen({Key? key}) : super(key: key);

  @override
  State<CertificateUploadScreen> createState() => _CertificateUploadScreenState();
}

class _CertificateUploadScreenState extends State<CertificateUploadScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _nomorSertifikatController = TextEditingController();
  DateTime? _tanggalBerlaku;
  String? _filePath;
  String? _fileName;
  String? _fileType; // 'pdf', 'image'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkPersonalDocuments();
    });
  }

  Future<void> _checkPersonalDocuments() async {
    try {
      // 1. Cek apakah sudah ada sertifikat yang diupload
      final vesselDocs = await VesselService().getVesselDocuments();
      final sertifikatJalan = vesselDocs['sertifikatJalan'] as List? ?? [];
      
      if (sertifikatJalan.isNotEmpty) {
        _showAlreadyUploadedDialog();
        return;
      }
      
      // 2. Cek dokumen pribadi
      final response = await DocumentService.getDocuments();
      if (response['success'] == true) {
        final docs = response['documents'] as List;
        
        final Map<String, dynamic> latestDocs = {};
        for (var doc in docs) {
          final docType = doc['jenisDokumen'] ?? 'Unknown';
          final docId = doc['id'];
          if (!latestDocs.containsKey(docType) || docId > latestDocs[docType]['id']) {
            latestDocs[docType] = doc;
          }
        }
        
        final approvedCount = latestDocs.values.where((d) => d['status'] == 'approved').length;
        
        if (approvedCount < 8) {
          final totalUploaded = latestDocs.length;
          if (totalUploaded < 8) {
            _showDocumentIncompleteDialog(hasDocuments: false);
          } else {
            _showDocumentIncompleteDialog(hasDocuments: true);
          }
        }
      }
    } catch (e) {
      print('❌ Error checking documents: $e');
    }
  }

  void _showAlreadyUploadedDialog() {
    late AnimationController shakeController;
    shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    final shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: shakeController,
      curve: Curves.easeInOut,
    ));

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async {
            shakeController.forward(from: 0);
            return false;
          },
          child: AnimatedBuilder(
            animation: shakeAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: shakeAnimation.value,
                child: child,
              );
            },
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
                          onPressed: () {
                            shakeController.dispose();
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle_outline, size: 40, color: Colors.blue),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Sudah Mengisi Sertifikat',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Anda sudah mengisi Sertifikat Jalan untuk trip kali ini.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tunggu admin mereset untuk trip berikutnya.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        shakeController.dispose();
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDocumentIncompleteDialog({required bool hasDocuments}) {
    late AnimationController shakeController;
    shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    final shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: shakeController,
      curve: Curves.easeInOut,
    ))..addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        if (shakeController.isAnimating == false) {
          // Animation selesai, siap untuk digunakan lagi
        }
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async {
            shakeController.forward(from: 0);
            return false;
          },
          child: AnimatedBuilder(
            animation: shakeAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: shakeAnimation.value,
                child: child,
              );
            },
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
                          onPressed: () {
                            shakeController.dispose();
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.description_outlined, size: 40, color: Colors.orange),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Dokumen Belum Lengkap',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Dokumen pribadi Anda belum lengkap atau belum disetujui.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Silakan lengkapi dokumen pribadi terlebih dahulu sebelum upload sertifikat kapal.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        shakeController.dispose();
                        Navigator.pop(context);
                        Navigator.pop(context);
                        if (hasDocuments) {
                          Navigator.pushNamed(context, '/document-status');
                        } else {
                          Navigator.pushNamed(
                            context,
                            '/nahkoda-document-upload',
                            arguments: {'fromVesselDocs': true},
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Lengkapi Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nomorSertifikatController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final fileSize = file.size;
        
        // Check file size (max 10MB)
        if (fileSize > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Ukuran file maksimal 10MB')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          return;
        }

        setState(() {
          _filePath = file.path;
          _fileName = file.name;
          _fileType = file.extension?.toLowerCase() == 'pdf' ? 'pdf' : 'image';
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        
        // Check file size (max 10MB)
        if (fileSize > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Ukuran file maksimal 10MB')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          return;
        }

        setState(() {
          _filePath = image.path;
          _fileName = image.path.split('/').last;
          _fileType = 'image';
        });
      }
    } catch (e) {
      print('Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitCertificate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tanggalBerlaku == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Tanggal berlaku harus diisi'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('File sertifikat harus diupload'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nama = _namaController.text.trim();
      final nomorSertifikat = _nomorSertifikatController.text.trim();
      final tanggalBerlaku = '${_tanggalBerlaku!.year}-${_tanggalBerlaku!.month.toString().padLeft(2, '0')}-${_tanggalBerlaku!.day.toString().padLeft(2, '0')}';
      
      print('📄 Submitting certificate:');
      print('   Nama: "$nama" (length: ${nama.length})');
      print('   Nomor: "$nomorSertifikat" (length: ${nomorSertifikat.length})');
      print('   Tanggal: $tanggalBerlaku');
      print('   File: $_fileName');

      final result = await VesselService().uploadSertifikatJalan(
        nama: nama,
        nomorSertifikat: nomorSertifikat,
        tanggalBerlaku: tanggalBerlaku,
        filePath: _filePath!,
      );

      print('✅ Upload result: $result');

      if (mounted) {
        // Trigger auto-refresh di parent screen
        RealtimeUpdateService.notifyListeners('vessel');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Sertifikat berhasil diupload'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error uploading certificate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Gagal upload sertifikat: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Upload Sertifikat Jalan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderInfo(),
              SizedBox(height: 24),
              _buildInputCard(),
              SizedBox(height: 24),
              _buildSubmitButton(),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.verified_rounded, color: Colors.blue[800], size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Dokumen Sertifikat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pastikan dokumen jelas dan valid',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
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
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Sertifikat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 20),
            
            // Nama Sertifikat
            TextFormField(
              controller: _namaController,
              decoration: _buildInputDecoration(
                label: 'Nama Sertifikat',
                hint: 'Contoh: Sertifikat Jalan 2024',
                icon: Icons.badge_rounded,
                iconColor: Colors.blue,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Nama sertifikat wajib diisi';
                if (value!.length < 3) return 'Minimal 3 karakter';
                return null;
              },
            ),
            SizedBox(height: 20),
            
            // Nomor Sertifikat
            TextFormField(
              controller: _nomorSertifikatController,
              decoration: _buildInputDecoration(
                label: 'Nomor Sertifikat',
                hint: 'Contoh: SJ-001/2024',
                icon: Icons.confirmation_number_rounded,
                iconColor: Colors.purple,
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Nomor sertifikat wajib diisi';
                if (value!.length < 3) return 'Minimal 3 karakter';
                if (value.length > 50) return 'Maksimal 50 karakter';
                if (!RegExp(r'^[a-zA-Z0-9\-\/\s]+$').hasMatch(value)) {
                  return 'Hanya boleh huruf, angka, dash, slash, dan spasi';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            
            // Tanggal Berlaku
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 3650)), // 10 years
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Colors.blue,
                          onPrimary: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) setState(() => _tanggalBerlaku = date);
              },
              child: InputDecorator(
                decoration: _buildInputDecoration(
                  label: 'Tanggal Berlaku',
                  icon: Icons.event_available_rounded,
                  iconColor: Colors.green,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _tanggalBerlaku != null
                          ? '${_tanggalBerlaku!.day}/${_tanggalBerlaku!.month}/${_tanggalBerlaku!.year}'
                          : 'Pilih tanggal berlaku',
                      style: TextStyle(
                        color: _tanggalBerlaku != null ? Colors.black87 : Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // File Upload Section
            _buildFileUploadSection(),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    String? hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.grey[700]),
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(icon, color: iconColor),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  Widget _buildFileUploadSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upload_file_rounded, color: Colors.blue[700], size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File Sertifikat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'PDF, JPG, PNG (Max 10MB)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_filePath != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                      color: Colors.green[700],
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fileName ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[900],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          _fileType == 'pdf' ? 'Dokumen PDF' : 'Gambar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20),
                    onPressed: () => setState(() {
                      _filePath = null;
                      _fileName = null;
                      _fileType = null;
                    }),
                    color: Colors.green[700],
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
          
          SizedBox(height: 16),
          
          // Upload Options
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: Icon(Icons.folder_rounded, size: 20),
                  label: Text('Pilih File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue[700],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.blue[200]!),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickImageFromCamera,
                  icon: Icon(Icons.camera_alt_rounded, size: 20),
                  label: Text('Ambil Foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple[700],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.purple[200]!),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Info Box
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.amber[800], size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pastikan dokumen terlihat jelas, tidak buram, dan semua teks dapat dibaca',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[900],
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

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _isLoading ? null : LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        color: _isLoading ? Colors.grey[300] : null,
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitCertificate,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_rounded, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Upload Sertifikat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}