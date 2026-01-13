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
  
  final List<Map<String, dynamic>> _documents = [
    {'name': 'Surat Izin Berlayar (SIB)', 'isUploaded': false, 'filePath': null},
    {'name': 'Sertifikat Keselamatan Kapal', 'isUploaded': false, 'filePath': null},
    {'name': 'Dokumen Crew List', 'isUploaded': false, 'filePath': null},
    {'name': 'Manifest Muatan', 'isUploaded': false, 'filePath': null},
    {'name': 'Surat Keterangan Kesehatan ABK', 'isUploaded': false, 'filePath': null},
    {'name': 'Dokumen Asuransi Kapal', 'isUploaded': false, 'filePath': null},
    {'name': 'Sertifikat Radio', 'isUploaded': false, 'filePath': null},
    {'name': 'Log Book Mesin', 'isUploaded': false, 'filePath': null},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedDocuments();
  }
  
  void _loadSavedDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDocuments = prefs.getStringList('documents') ?? [];
    
    if (savedDocuments.isNotEmpty) {
      setState(() {
        for (int i = 0; i < savedDocuments.length && i < _documents.length; i++) {
          final docData = json.decode(savedDocuments[i]);
          _documents[i] = docData;
        }
      });
    }
  }
  
  void _saveDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final documentsJson = _documents.map((doc) => json.encode(doc)).toList();
    await prefs.setStringList('documents', documentsJson);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    
    final uploadedCount = _documents.where((doc) => doc['isUploaded']).length;
    final completionPercentage = uploadedCount / _documents.length;

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
                        'Kelengkapan Dokumen',
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
                          final isUploaded = document['isUploaded'];

                          return Container(
                            margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                              border: Border.all(
                                color: isUploaded ? Colors.green : Colors.grey.shade300,
                                width: isUploaded ? 2 : 1,
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
                                      color: isUploaded
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
                                    ),
                                    child: Icon(
                                      isUploaded ? Icons.check_circle : Icons.description,
                                      color: isUploaded ? Colors.green : Colors.grey[600],
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
                                        if (isUploaded && document['filePath'] != null) ...[
                                          SizedBox(height: isTablet ? 10 : 8),
                                          GestureDetector(
                                            onTap: () => _viewDocument(document['filePath']),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isTablet ? 10 : 8,
                                                vertical: isTablet ? 6 : 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    _getFileIcon(document['filePath']),
                                                    size: isTablet ? 16 : 14,
                                                    color: Colors.blue,
                                                  ),
                                                  SizedBox(width: isTablet ? 6 : 4),
                                                  Flexible(
                                                    child: Text(
                                                      _truncateFileName(
                                                        document['filePath'].split('/').last,
                                                        isTablet ? 25 : 15,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: isTablet ? 14 : 12,
                                                        color: Colors.blue,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: isTablet ? 12 : 8),
                                  // Upload/Replace Button
                                  ElevatedButton(
                                    onPressed: _uploadingDocuments.contains(index)
                                        ? null
                                        : () => _uploadDocument(index),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isUploaded ? Colors.orange : const Color(0xFF2563EB),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 20 : 16,
                                        vertical: isTablet ? 12 : 8,
                                      ),
                                    ),
                                    child: _uploadingDocuments.contains(index)
                                        ? SizedBox(
                                            width: isTablet ? 18 : 16,
                                            height: isTablet ? 18 : 16,
                                            child: const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            isUploaded ? 'Ganti' : 'Upload',
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
            'Pilih Sumber File',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
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
          
          SizedBox(height: isTablet ? 16 : 12),
          
          _buildOptionTile(
            icon: Icons.folder,
            title: 'File Dokumen',
            subtitle: 'Pilih PDF, Word, atau file lainnya',
            onTap: () => _pickFile(index),
            isTablet: isTablet,
          ),
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
        type: FileType.any,
        allowMultiple: false,
      );
      if (result?.files.single.path != null) {
        _handleFileSelected(index, result!.files.single.path!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error memilih file: $e')),
      );
    }
  }

  void _handleFileSelected(int index, String filePath) {
    setState(() {
      _uploadingDocuments.add(index);
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _documents[index]['isUploaded'] = true;
        _documents[index]['filePath'] = filePath;
        _uploadingDocuments.remove(index);
      });
      _saveDocuments();
    });
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

  void _submitDocuments() {
    final uploadedCount = _documents.where((doc) => doc['isUploaded']).length;
    
    if (uploadedCount == _documents.length) {
      Navigator.pushNamed(context, '/vessel-info', arguments: {
        'source': 'document-completion',
        'documents': _documents,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan lengkapi semua dokumen terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}