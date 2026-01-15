import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DocumentStatusScreen extends StatefulWidget {
  const DocumentStatusScreen({Key? key}) : super(key: key);

  @override
  State<DocumentStatusScreen> createState() => _DocumentStatusScreenState();
}

class _DocumentStatusScreenState extends State<DocumentStatusScreen> {
  List<Map<String, dynamic>> _allDocuments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocumentStatus();
  }

  void _loadDocumentStatus() async {
    // TODO: Fetch dari API untuk mendapatkan status terbaru
    // Sementara load dari local storage
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    
    if (userDataString != null) {
      final userData = json.decode(userDataString);
      final userId = userData['id']?.toString() ?? 'unknown';
      final userRole = userData['role']?.toString() ?? 'unknown';
      
      final documentsKey = 'documents_${userId}_$userRole';
      final savedDocuments = prefs.getStringList(documentsKey) ?? [];
      
      setState(() {
        _allDocuments = savedDocuments.map((doc) => json.decode(doc) as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'verified':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'verified':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'pending':
      default:
        return 'Menunggu Verifikasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
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
          'Status Dokumen',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _allDocuments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada dokumen',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(isTablet ? 32 : 20),
                  itemCount: _allDocuments.length,
                  itemBuilder: (context, index) {
                    final doc = _allDocuments[index];
                    final status = doc['status'] ?? 'pending';
                    final hasFile = doc['hasFile'] == true;

                    return Container(
                      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                        border: Border.all(
                          color: _getStatusColor(status).withOpacity(0.3),
                          width: 2,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: isTablet ? 56 : 48,
                                  height: isTablet ? 56 : 48,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
                                  ),
                                  child: Icon(
                                    _getStatusIcon(status),
                                    color: _getStatusColor(status),
                                    size: isTablet ? 28 : 24,
                                  ),
                                ),
                                SizedBox(width: isTablet ? 16 : 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc['name'] ?? 'Dokumen',
                                        style: TextStyle(
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isTablet ? 10 : 8,
                                          vertical: isTablet ? 6 : 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                                        ),
                                        child: Text(
                                          _getStatusText(status),
                                          style: TextStyle(
                                            fontSize: isTablet ? 13 : 11,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (doc['rejectionReason'] != null) ...[
                              SizedBox(height: isTablet ? 16 : 12),
                              Container(
                                padding: EdgeInsets.all(isTablet ? 14 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.red, size: isTablet ? 20 : 18),
                                    SizedBox(width: isTablet ? 10 : 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Alasan Penolakan:',
                                            style: TextStyle(
                                              fontSize: isTablet ? 13 : 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red[800],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            doc['rejectionReason'],
                                            style: TextStyle(
                                              fontSize: isTablet ? 14 : 12,
                                              color: Colors.red[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isTablet ? 12 : 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Navigate to re-upload
                                    Navigator.pushNamed(context, '/document-completion');
                                  },
                                  icon: Icon(Icons.upload_file, size: isTablet ? 20 : 18),
                                  label: Text(
                                    'Upload Ulang',
                                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (hasFile && doc['filePath'] != null) ...[
                              SizedBox(height: isTablet ? 12 : 8),
                              Row(
                                children: [
                                  Icon(Icons.insert_drive_file, size: isTablet ? 18 : 16, color: Colors.grey[600]),
                                  SizedBox(width: isTablet ? 8 : 6),
                                  Expanded(
                                    child: Text(
                                      doc['filePath'].split('/').last,
                                      style: TextStyle(
                                        fontSize: isTablet ? 13 : 11,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
