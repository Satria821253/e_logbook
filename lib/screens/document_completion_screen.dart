import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
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
    final uploadedCount = _documents.where((doc) => doc['isUploaded']).length;
    final completionPercentage = uploadedCount / _documents.length;
    final isTablet = ResponsiveHelper.isTablet(context);

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
                  right: ResponsiveHelper.responsiveWidth(context, mobile: 20, tablet: 32),
                  top: ResponsiveHelper.responsiveHeight(context, mobile: 10, tablet: 16),
                  bottom: ResponsiveHelper.responsiveHeight(context, mobile: 20, tablet: 28),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: ResponsiveHelper.responsiveWidth(context, mobile: 24, tablet: 28),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Kelengkapan Dokumen',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 20, tablet: 24),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.responsiveWidth(context, mobile: 48, tablet: 56)),
                  ],
                ),
              ),

              // Status Summary
              Container(
                margin: ResponsiveHelper.responsiveHorizontalPadding(context, mobile: 20, tablet: 32),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: ResponsiveHelper.responsivePadding(context, mobile: 16, tablet: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.upload_file,
                              color: Colors.white,
                              size: ResponsiveHelper.responsiveWidth(context, mobile: 24, tablet: 28),
                            ),
                            SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 8, tablet: 12)),
                            Text(
                              '$uploadedCount',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 20, tablet: 24),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Selesai',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 12, tablet: 14),
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16)),
                    Expanded(
                      child: Container(
                        padding: ResponsiveHelper.responsivePadding(context, mobile: 16, tablet: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.pending_actions,
                              color: Colors.white,
                              size: ResponsiveHelper.responsiveWidth(context, mobile: 24, tablet: 28),
                            ),
                            SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 8, tablet: 12)),
                            Text(
                              '${_documents.length - uploadedCount}',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 20, tablet: 24),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Tersisa',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 12, tablet: 14),
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

              SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 20, tablet: 28)),

              // Progress Card
              Container(
                margin: ResponsiveHelper.responsiveHorizontalPadding(context, mobile: 20, tablet: 32),
                padding: ResponsiveHelper.responsivePadding(context, mobile: 20, tablet: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.responsiveWidth(context, mobile: 16, tablet: 20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: ResponsiveHelper.responsiveWidth(context, mobile: 10, tablet: 14),
                      offset: Offset(0, ResponsiveHelper.responsiveHeight(context, mobile: 4, tablet: 6)),
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
                            fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 16, tablet: 18),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),  
                        ),
                        Text(
                          '${(completionPercentage * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 16, tablet: 18),
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4F9C),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 12, tablet: 16)),
                    LinearProgressIndicator(
                      value: completionPercentage,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B4F9C)),
                      minHeight: ResponsiveHelper.responsiveHeight(context, mobile: 8, tablet: 10),
                    ),
                    SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 8, tablet: 12)),
                    Text(
                      '$uploadedCount dari ${_documents.length} dokumen telah diunggah',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 20, tablet: 28)),

              // Document List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(ResponsiveHelper.responsiveWidth(context, mobile: 24, tablet: 32)),
                      topRight: Radius.circular(ResponsiveHelper.responsiveWidth(context, mobile: 24, tablet: 32)),
                    ),
                  ),
                  child: ListView.builder(
                    padding: ResponsiveHelper.responsivePadding(context, mobile: 20, tablet: 32),
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final document = _documents[index];
                      final isUploaded = document['isUploaded'];
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: ResponsiveHelper.responsiveHeight(context, mobile: 16, tablet: 20)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16)),
                          border: Border.all(
                            color: isUploaded ? Colors.green : Colors.grey.shade300,
                            width: isUploaded ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: ResponsiveHelper.responsiveWidth(context, mobile: 8, tablet: 12),
                              offset: Offset(0, ResponsiveHelper.responsiveHeight(context, mobile: 2, tablet: 3)),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: ResponsiveHelper.responsivePadding(context, mobile: 16, tablet: 20),
                          child: Row(
                            children: [
                              // Document Icon
                              Container(
                                width: ResponsiveHelper.responsiveWidth(context, mobile: 48, tablet: 56),
                                height: ResponsiveHelper.responsiveHeight(context, mobile: 48, tablet: 56),
                                decoration: BoxDecoration(
                                  color: isUploaded 
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(ResponsiveHelper.responsiveWidth(context, mobile: 24, tablet: 28)),
                                ),
                                child: Icon(
                                  isUploaded ? Icons.check_circle : Icons.description,
                                  color: isUploaded ? Colors.green : Colors.grey[600],
                                  size: ResponsiveHelper.responsiveWidth(context, mobile: 24, tablet: 28),
                                ),
                              ),
                              SizedBox(width: ResponsiveHelper.responsiveWidth(context, mobile: 16, tablet: 20)),
                              // Document Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      document['name'],
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 16, tablet: 18),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (isUploaded && document['filePath'] != null) ...[
                                      SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 8, tablet: 10)),
                                      GestureDetector(
                                        onTap: () => _viewDocument(document['filePath']),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: ResponsiveHelper.responsiveWidth(context, mobile: 8, tablet: 10),
                                            vertical: ResponsiveHelper.responsiveHeight(context, mobile: 4, tablet: 6),
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(ResponsiveHelper.responsiveWidth(context, mobile: 6, tablet: 8)),
                                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getFileIcon(document['filePath']),
                                                size: ResponsiveHelper.responsiveWidth(context, mobile: 14, tablet: 16),
                                                color: Colors.blue,
                                              ),
                                              SizedBox(width: ResponsiveHelper.responsiveWidth(context, mobile: 4, tablet: 6)),
                                              Flexible(
                                                child: Text(
                                                  _truncateFileName(document['filePath'].split('/').last, isTablet ? 20 : 15),
                                                  style: TextStyle(
                                                    fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 12, tablet: 14),
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
                              // Upload/Replace Button
                              ElevatedButton(
                                onPressed: _uploadingDocuments.contains(index) ? null : () => _uploadDocument(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isUploaded ? Colors.orange : const Color.fromARGB(255, 39, 117, 235),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveHelper.responsiveWidth(context, mobile: 8, tablet: 10)),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveHelper.responsiveWidth(context, mobile: 16, tablet: 20),
                                    vertical: ResponsiveHelper.responsiveHeight(context, mobile: 8, tablet: 12),
                                  ),
                                ),
                                child: _uploadingDocuments.contains(index)
                                    ? SizedBox(
                                        width: ResponsiveHelper.responsiveWidth(context, mobile: 16, tablet: 18),
                                        height: ResponsiveHelper.responsiveHeight(context, mobile: 16, tablet: 18),
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
                                          fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16),
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

              // Submit Buttons
              Container(
                color: Colors.white,
                padding: ResponsiveHelper.responsivePadding(context, mobile: 20, tablet: 32),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: ResponsiveHelper.responsiveHeight(context, mobile: 56, tablet: 64),
                      child: ElevatedButton(
                        onPressed: () => _submitDocuments(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4F9C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: ResponsiveHelper.responsiveWidth(context, mobile: 20, tablet: 24),
                            ),
                            SizedBox(width: ResponsiveHelper.responsiveWidth(context, mobile: 8, tablet: 12)),
                            Text(
                              'Lanjut',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 16, tablet: 18),
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
    return Container(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 20),
          const Text(
            'Pilih Sumber File',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildOptionTile(
            icon: Icons.camera_alt,
            title: 'Ambil Gambar',
            subtitle: 'Gunakan kamera untuk mengambil foto',
            onTap: () => _takePhoto(index),
          ),
          
          const SizedBox(height: 12),
          
          _buildOptionTile(
            icon: Icons.photo_library,
            title: 'Pilih Foto dari Galeri',
            subtitle: 'Pilih gambar dari galeri',
            onTap: () => _pickImage(index),
          ),
          
          const SizedBox(height: 12),
          
          _buildOptionTile(
            icon: Icons.folder,
            title: 'File Dokumen',
            subtitle: 'Pilih PDF, Word, atau file lainnya',
            onTap: () => _pickFile(index),
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
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
      // Save documents immediately after upload
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
    final maxNameLength = maxLength - extension.length - 4; // 4 for "...."
    
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
      // Documents complete, go to vessel info
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