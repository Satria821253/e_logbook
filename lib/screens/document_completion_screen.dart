import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DocumentCompletionScreen extends StatefulWidget {
  const DocumentCompletionScreen({Key? key}) : super(key: key);

  @override
  State<DocumentCompletionScreen> createState() => _DocumentCompletionScreenState();
}

class _DocumentCompletionScreenState extends State<DocumentCompletionScreen> {
  final Set<int> _uploadingDocuments = {};
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _initializeDocuments();
  }
  
  void _initializeDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      String userRole = 'ABK';
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        userRole = userData['role']?.toString() ?? 'ABK';
      }
      
      if (mounted) {
        setState(() {
          _documents = _getDocumentsByRole(userRole);
        });
      }
      
      _loadSavedDocuments();
    } catch (e) {
      print('Error initializing documents: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat dokumen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  List<Map<String, dynamic>> _getDocumentsByRole(String role) {
    // Hanya dokumen pribadi (dokumen kapal akan di screen terpisah)
    return [
      {'name': 'KTP', 'serverName': 'KTP', 'hasFile': false, 'filePath': null, 'nomorDokumen': null, 'tanggalBerlaku': null, 'keterangan': null, 'requireNumber': false, 'requireDate': false},
      {'name': 'Buku Pelaut', 'serverName': 'Buku Pelaut', 'hasFile': false, 'filePath': null, 'nomorDokumen': null, 'tanggalBerlaku': null, 'keterangan': null, 'requireNumber': true, 'requireDate': true},
      {'name': 'BST', 'serverName': 'BST', 'hasFile': false, 'filePath': null, 'nomorDokumen': null, 'tanggalBerlaku': null, 'keterangan': null, 'requireNumber': true, 'requireDate': true},
      {'name': 'Surat Keterangan Sehat', 'serverName': 'Surat Keterangan Sehat', 'hasFile': false, 'filePath': null, 'nomorDokumen': null, 'tanggalBerlaku': null, 'keterangan': null, 'requireNumber': true, 'requireDate': true},
      {'name': 'SKCK', 'serverName': 'SKCK', 'hasFile': false, 'filePath': null, 'nomorDokumen': null, 'tanggalBerlaku': null, 'keterangan': null, 'requireNumber': true, 'requireDate': true},
      {'name': 'Pas Foto', 'serverName': 'Pas Foto', 'hasFile': false, 'filePath': null, 'nomorDokumen': null, 'tanggalBerlaku': null, 'keterangan': null, 'requireNumber': true, 'requireDate': true},
    ];
  }
  
  void _loadSavedDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current user info for user-specific storage
      final userDataString = prefs.getString('user_data');
      if (userDataString == null) return;
      
      final userData = json.decode(userDataString);
      final userId = userData['id']?.toString() ?? 'unknown';
      final userRole = userData['role']?.toString() ?? 'unknown';
      
      final documentsKey = 'documents_${userId}_$userRole';
      final savedDocuments = prefs.getStringList(documentsKey) ?? [];
      
      if (savedDocuments.isNotEmpty && mounted) {
        setState(() {
          for (int i = 0; i < savedDocuments.length && i < _documents.length; i++) {
            final docData = json.decode(savedDocuments[i]);
            _documents[i] = docData;
          }
        });
      }
    } catch (e) {
      print('Error loading saved documents: $e');
    }
  }
  
  void _saveDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current user info for user-specific storage
      final userDataString = prefs.getString('user_data');
      if (userDataString == null) return;
      
      final userData = json.decode(userDataString);
      final userId = userData['id']?.toString() ?? 'unknown';
      final userRole = userData['role']?.toString() ?? 'unknown';
      
      final documentsKey = 'documents_${userId}_$userRole';
      final documentsJson = _documents.map((doc) => json.encode(doc)).toList();
      await prefs.setStringList(documentsKey, documentsJson);
    } catch (e) {
      print('Error saving documents: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    
    final uploadedCount = _documents.where((doc) => doc['hasFile'] == true).length;
    final completionPercentage = _documents.isEmpty ? 0.0 : uploadedCount / _documents.length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.only(
                  left: 0,
                  right: isTablet ? 32 : 20,
                  top: isTablet ? 16 : 10,
                  bottom: isTablet ? 28 : 20,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: isTablet ? 28 : 24,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Dokumen Pribadi',
                        style: TextStyle(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(width: isTablet ? 56 : 48),
                  ],
                ),
              ),

              // Status Summary
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 800 : double.infinity,
                  ),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 20 : 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.upload_file,
                                  color: Colors.white,
                                  size: isTablet ? 28 : 24,
                                ),
                                SizedBox(height: isTablet ? 12 : 8),
                                Text(
                                  '$uploadedCount',
                                  style: TextStyle(
                                    fontSize: isTablet ? 24 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Selesai',
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(isTablet ? 20 : 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.pending_actions,
                                  color: Colors.white,
                                  size: isTablet ? 28 : 24,
                                ),
                                SizedBox(height: isTablet ? 12 : 8),
                                Text(
                                  '${_documents.length - uploadedCount}',
                                  style: TextStyle(
                                    fontSize: isTablet ? 24 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Tersisa',
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: isTablet ? 28 : 20),

              // Progress Card
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 800 : double.infinity,
                  ),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20),
                    padding: EdgeInsets.all(isTablet ? 28 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: isTablet ? 14 : 10,
                          offset: Offset(0, isTablet ? 6 : 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress Dokumen',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '${(completionPercentage * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B4F9C),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 16 : 12),
                        LinearProgressIndicator(
                          value: completionPercentage,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B4F9C)),
                          minHeight: isTablet ? 10 : 8,
                        ),
                        SizedBox(height: isTablet ? 12 : 8),
                        Text(
                          '$uploadedCount dari ${_documents.length} dokumen telah diunggah',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: isTablet ? 28 : 20),

              // Document List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isTablet ? 32 : 24),
                      topRight: Radius.circular(isTablet ? 32 : 24),
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 800 : double.infinity,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.all(isTablet ? 32 : 20),
                        itemCount: _documents.length,
                        itemBuilder: (context, index) {
                          final document = _documents[index];
                          final hasFile = document['hasFile'] == true;

                          return Container(
                            margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                              border: Border.all(
                                color: hasFile ? Colors.blue.shade300 : Colors.grey.shade300,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: isTablet ? 12 : 8,
                                  offset: Offset(0, isTablet ? 3 : 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              child: Row(
                                children: [
                                  // Document Icon
                                  Container(
                                    width: isTablet ? 56 : 48,
                                    height: isTablet ? 56 : 48,
                                    decoration: BoxDecoration(
                                      color: hasFile
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
                                    ),
                                    child: Icon(
                                      hasFile ? Icons.insert_drive_file : Icons.description,
                                      color: hasFile ? Colors.blue : Colors.grey[600],
                                      size: isTablet ? 28 : 24,
                                    ),
                                  ),
                                  SizedBox(width: isTablet ? 20 : 16),
                                  // Document Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          document['name'],
                                          style: TextStyle(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (hasFile && document['filePath'] != null) ...[
                                          SizedBox(height: isTablet ? 6 : 4),
                                          Text(
                                            _truncateFileName(
                                              document['filePath'].split('/').last,
                                              isTablet ? 30 : 20,
                                            ),
                                            style: TextStyle(
                                              fontSize: isTablet ? 13 : 11,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: isTablet ? 12 : 8),
                                  // Upload/Replace Button
                                  ElevatedButton(
                                    onPressed: () => _uploadDocument(index),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: hasFile ? Colors.orange : const Color(0xFF2563EB),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 20 : 16,
                                        vertical: isTablet ? 12 : 8,
                                      ),
                                    ),
                                    child: Text(
                                      hasFile ? 'Ganti' : 'Pilih',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isTablet ? 16 : 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Submit Button
              Container(
                color: Colors.white,
                padding: EdgeInsets.all(isTablet ? 32 : 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 800 : double.infinity,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: isTablet ? 64 : 56,
                      child: ElevatedButton(
                        onPressed: () => _submitDocuments(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4F9C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: isTablet ? 24 : 20,
                            ),
                            SizedBox(width: isTablet ? 12 : 8),
                            Text(
                              'Lanjut',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _uploadDocument(int index) {
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
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final isKTP = _documents[index]['name'] == 'KTP';
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 28 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isTablet ? 50 : 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),
          Text(
            isKTP ? 'Pilih Foto KTP' : 'Pilih Sumber File',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isKTP) ...[
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              'KTP hanya dapat diupload dalam bentuk foto/gambar',
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: isTablet ? 24 : 20),
          
          _buildOptionTile(
            icon: Icons.camera_alt,
            title: 'Ambil Gambar',
            subtitle: 'Gunakan kamera untuk mengambil foto',
            onTap: () => _takePhoto(index),
            isTablet: isTablet,
          ),
          
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildOptionTile(
            icon: Icons.photo_library,
            title: 'Pilih Foto dari Galeri',
            subtitle: 'Pilih gambar dari galeri',
            onTap: () => _pickImage(index),
            isTablet: isTablet,
          ),
          
          if (!isKTP) ...[
            SizedBox(height: isTablet ? 16 : 12),
            
            _buildOptionTile(
              icon: Icons.folder,
              title: 'File Dokumen',
              subtitle: 'Pilih PDF atau gambar (JPG, PNG)',
              onTap: () => _pickFile(index),
              isTablet: isTablet,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        ),
        child: Row(
          children: [
            Container(
              width: isTablet ? 56 : 48,
              height: isTablet ? 56 : 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1B4F9C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1B4F9C),
                size: isTablet ? 28 : 24,
              ),
            ),
            SizedBox(width: isTablet ? 20 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isTablet ? 6 : 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isTablet ? 15 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: isTablet ? 18 : 16,
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
        _handleFileSelected(index, image!.path);
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
        _handleFileSelected(index, image!.path);
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
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );
      if (result?.files.single.path != null) {
        final filePath = result!.files.single.path!;
        final extension = filePath.split('.').last.toLowerCase();
        
        // Validasi ekstensi file
        if (!['pdf', 'jpg', 'jpeg', 'png'].contains(extension)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('File tidak didukung! Hanya JPG, PNG, dan PDF yang diperbolehkan'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
        
        _handleFileSelected(index, filePath);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Error memilih file: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleFileSelected(int index, String filePath) async {
    // Validasi ekstensi file
    final extension = filePath.split('.').last.toLowerCase();
    if (!['pdf', 'jpg', 'jpeg', 'png'].contains(extension)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('File tidak didukung! Hanya JPG, PNG, dan PDF yang diperbolehkan'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Show dialog to input document details
    final details = await _showDocumentDetailsDialog(index);
    
    if (details == null) {
      return;
    }

    // Simpan data lokal saja, belum upload ke API
    if (mounted) {
      setState(() {
        _documents[index]['hasFile'] = true;
        _documents[index]['filePath'] = filePath;
        _documents[index]['nomorDokumen'] = details['nomorDokumen'];
        _documents[index]['tanggalBerlaku'] = details['tanggalBerlaku'];
        _documents[index]['keterangan'] = details['keterangan'];
      });
    }
    _saveDocuments();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dokumen berhasil disimpan'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  String _truncateFileName(String fileName, int maxLength) {
    if (fileName.length <= maxLength) return fileName;
    
    final parts = fileName.split('.');
    if (parts.length < 2) {
      return '${fileName.substring(0, maxLength - 3)}...';
    }
    
    final extension = parts.last;
    final nameWithoutExt = parts.sublist(0, parts.length - 1).join('.');
    final maxNameLength = maxLength - extension.length - 4;
    
    if (maxNameLength <= 0) {
      return '....$extension';
    }
    
    return '${nameWithoutExt.substring(0, maxNameLength)}...$extension';
  }

  void _viewDocument(String filePath) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File: ${filePath.split('/').last}')),
    );
  }

  IconData _getFileIcon(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _submitDocuments() async {
    final filledCount = _documents.where((doc) => doc['hasFile'] == true).length;
    
    if (filledCount < _documents.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan lengkapi semua dokumen pribadi terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Simpan status dokumen pribadi selesai
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('personal_documents_completed', true);
    
    // Navigasi ke halaman informasi kapal dengan data dokumen
    if (mounted) {
      Navigator.pushNamed(
        context,
        '/vessel-info',
        arguments: {
          'source': 'document-completion',
          'documents': _documents,
        },
      );
    }
  }

  Future<Map<String, String>?> _showDocumentDetailsDialog(int index) async {
    final nomorController = TextEditingController();
    final keteranganController = TextEditingController();
    DateTime? selectedDate;
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        ),
        child: Container(
          width: isTablet ? 500 : double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isTablet ? 20 : 16),
                    topRight: Radius.circular(isTablet ? 20 : 16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isTablet ? 12 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                      ),
                      child: Icon(
                        Icons.description,
                        color: Colors.white,
                        size: isTablet ? 28 : 24,
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Dokumen',
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: isTablet ? 6 : 4),
                          Text(
                            _documents[index]['name'],
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nomor Dokumen Field
                      _buildFormField(
                        label: 'Nomor Dokumen',
                        icon: Icons.numbers,
                        isRequired: true,
                        isTablet: isTablet,
                        child: TextFormField(
                          controller: nomorController,
                          maxLength: 50,
                          decoration: InputDecoration(
                            hintText: 'Masukkan nomor dokumen (3-50 karakter)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                              borderSide: const BorderSide(color: Color(0xFF1B4F9C), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 14,
                              vertical: isTablet ? 16 : 14,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: isTablet ? 24 : 20),
                      
                      // Tanggal Berlaku Field
                      _buildFormField(
                        label: 'Tanggal Berlaku',
                        icon: Icons.calendar_today,
                        isRequired: true,
                        isTablet: isTablet,
                        child: StatefulBuilder(
                          builder: (context, setState) => InkWell(
                            onTap: () async {
                              final date = await _showCustomDatePicker(context);
                              if (date != null) {
                                setState(() => selectedDate = date);
                              }
                            },
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 14,
                                vertical: isTablet ? 16 : 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                                color: Colors.grey.shade50,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedDate != null
                                          ? _formatDate(selectedDate!)
                                          : 'Pilih tanggal berlaku dokumen',
                                      style: TextStyle(
                                        fontSize: isTablet ? 16 : 14,
                                        color: selectedDate != null
                                            ? Colors.black87
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    color: const Color(0xFF1B4F9C),
                                    size: isTablet ? 22 : 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: isTablet ? 24 : 20),
                      
                      // Keterangan Field
                      _buildFormField(
                        label: 'Keterangan',
                        icon: Icons.note_alt,
                        isRequired: false,
                        isTablet: isTablet,
                        child: TextFormField(
                          controller: keteranganController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Tambahkan keterangan (opsional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                              borderSide: const BorderSide(color: Color(0xFF1B4F9C), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 14,
                              vertical: isTablet ? 16 : 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(isTablet ? 20 : 16),
                    bottomRight: Radius.circular(isTablet ? 20 : 16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 16 : 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                          ),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (nomorController.text.isEmpty || nomorController.text.length < 3 || selectedDate == null) {
                            String errorMessage = '';
                            if (nomorController.text.isEmpty) {
                              errorMessage = 'Nomor dokumen wajib diisi';
                            } else if (nomorController.text.length < 3) {
                              errorMessage = 'Nomor dokumen minimal 3 karakter';
                            } else if (selectedDate == null) {
                              errorMessage = 'Tanggal berlaku wajib dipilih';
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.white),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(errorMessage),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
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
                          backgroundColor: const Color(0xFF1B4F9C),
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 16 : 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.save,
                              color: Colors.white,
                              size: isTablet ? 20 : 18,
                            ),
                            SizedBox(width: isTablet ? 8 : 6),
                            Text(
                              'Simpan',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required bool isRequired,
    required bool isTablet,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 8 : 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4F9C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1B4F9C),
                size: isTablet ? 20 : 18,
              ),
            ),
            SizedBox(width: isTablet ? 12 : 10),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (isRequired) ...[
              SizedBox(width: isTablet ? 6 : 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: isTablet ? 12 : 10),
        child,
      ],
    );
  }

  Future<DateTime?> _showCustomDatePicker(BuildContext context) async {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2050, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B4F9C),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}