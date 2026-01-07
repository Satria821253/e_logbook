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
                padding: const EdgeInsets.only(left: 0, right: 20, top: 10, bottom: 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Kelengkapan Dokumen',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Status Summary
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.upload_file,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$uploadedCount',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Selesai',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.pending_actions,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_documents.length - uploadedCount}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Tersisa',
                              style: TextStyle(
                                fontSize: 12,
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

              const SizedBox(height: 20),

              // Progress Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progress Dokumen',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${(completionPercentage * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4F9C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: completionPercentage,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B4F9C)),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$uploadedCount dari ${_documents.length} dokumen telah diunggah',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Document List
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final document = _documents[index];
                      final isUploaded = document['isUploaded'];
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isUploaded ? Colors.green : Colors.grey.shade300,
                            width: isUploaded ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Document Icon
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isUploaded 
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(
                                  isUploaded ? Icons.check_circle : Icons.description,
                                  color: isUploaded ? Colors.green : Colors.grey[600],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Document Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      document['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (isUploaded && document['filePath'] != null) ...[
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () => _viewDocument(document['filePath']),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getFileIcon(document['filePath']),
                                                size: 14,
                                                color: Colors.blue,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  _truncateFileName(document['filePath'].split('/').last, 15),
                                                  style: const TextStyle(
                                                    fontSize: 12,
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
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: _uploadingDocuments.contains(index)
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        isUploaded ? 'Ganti' : 'Upload',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _submitDocuments(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4F9C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_forward, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Lanjut',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Removed the "Selesaikan Semua Dokumen" button
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
  
  void _markFullyCompleted() {
    // Save full completion status globally
    // SharedPreferences.getInstance().then((prefs) => prefs.setBool('full_process_completed', true));
    print('Full process completion saved globally');
  }
}