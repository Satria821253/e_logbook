import 'package:e_logbook/services/getAPi/document_service.dart';
import 'package:e_logbook/services/realtime_update_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VesselCertificatesScreen extends StatefulWidget {
  final Map<String, dynamic>? documentsData;

  const VesselCertificatesScreen({Key? key, this.documentsData}) : super(key: key);

  @override
  State<VesselCertificatesScreen> createState() => _VesselCertificatesScreenState();
}

class _VesselCertificatesScreenState extends State<VesselCertificatesScreen> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    final sertifikatJalan = widget.documentsData?['sertifikatJalan'] as List? ?? [];
    if (sertifikatJalan.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkPersonalDocumentsAndShowDialog();
      });
    }
  }

  Future<void> _checkPersonalDocumentsAndShowDialog() async {
    try {
      final response = await DocumentService.getDocuments();
      if (response['success'] == true) {
        final docs = response['documents'] as List;
        
        // Group by jenisDokumen untuk hitung unique dokumen
        final Map<String, dynamic> latestDocs = {};
        for (var doc in docs) {
          final docType = doc['jenisDokumen'] ?? 'Unknown';
          final docId = doc['id'];
          if (!latestDocs.containsKey(docType) || docId > latestDocs[docType]['id']) {
            latestDocs[docType] = doc;
          }
        }
        
        final totalUploaded = latestDocs.length;
        const totalRequired = 8;
        
        // Cek berapa yang approved
        final approvedCount = latestDocs.values.where((d) => d['status'] == 'approved').length;
        
        print('📊 [Sertifikat Check] Total: $totalUploaded, Approved: $approvedCount');
        
        // Jika semua 8 dokumen sudah approved, tampilkan popup upload sertifikat
        if (approvedCount >= totalRequired) {
          print('✅ All personal documents approved, show certificate upload popup');
          _showNoCertificateUploadDialog();
          return;
        }
        
        // Jika belum lengkap 8 dokumen, ke upload dokumen pribadi
        if (totalUploaded < totalRequired) {
          _showNoCertificateDialog(hasDocuments: false);
        } else {
          // Sudah 8 dokumen tapi belum semua approved, ke status screen
          _showNoCertificateDialog(hasDocuments: true);
        }
      } else {
        _showNoCertificateDialog(hasDocuments: false);
      }
    } catch (e) {
      print('❌ Error checking documents: $e');
      _showNoCertificateDialog(hasDocuments: false);
    }
  }

  void _showNoCertificateUploadDialog() {
    final shakeController = AnimationController(
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
                      child: Icon(Icons.upload_file, size: 40, color: Colors.blue),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Belum Upload Sertifikat',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Dokumen pribadi Anda sudah lengkap dan disetujui.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Silakan upload Sertifikat Jalan kapal untuk melanjutkan.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        shakeController.dispose();
                        Navigator.pop(context);
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/certificate-upload');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Upload Sertifikat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _showNoCertificateDialog({required bool hasDocuments}) {
    final shakeController = AnimationController(
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
                      'Belum ada Sertifikat Jalan yang disetujui admin.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Admin tidak akan memberikan Sertifikat Jalan jika data belum terpenuhi.',
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
                          // Ada dokumen tapi belum approved, ke status screen
                          Navigator.pushNamed(context, '/document-status');
                        } else {
                          // Belum ada dokumen, ke upload screen
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
  Widget build(BuildContext context) {
    final kapalInfo = widget.documentsData?['kapal'];
    final sertifikatJalan = widget.documentsData?['sertifikatJalan'] as List? ?? [];

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
          'Sertifikat Kapal',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          // Upload button
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/certificate-upload');
              if (result == true && mounted) {
                RealtimeUpdateService.notifyListeners('certificates');
                Navigator.pop(context, true);
              }
            },
            tooltip: 'Upload Sertifikat',
          ),
        ],
      ),
      body: Column(
        children: [
          if (kapalInfo != null) _buildKapalHeader(kapalInfo),
          Expanded(
            child: sertifikatJalan.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: sertifikatJalan.length,
                    itemBuilder: (context, index) {
                      return _buildSertifikatCard(sertifikatJalan[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKapalHeader(Map<String, dynamic> kapal) {
    final nahkoda = widget.documentsData?['nahkoda'] as Map<String, dynamic>?;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.directions_boat_rounded, color: Colors.white, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kapal['namaKapal'] ?? '-',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      kapal['nomorRegistrasi'] ?? '-',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (nahkoda != null) ...[
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
                    'Nahkoda: ${nahkoda['nama'] ?? '-'}',
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
        ],
      ),
    );
  }

  Widget _buildSertifikatCard(Map<String, dynamic> doc) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final uploadedAt = doc['uploadedAt'] != null ? DateTime.tryParse(doc['uploadedAt']) : null;
    final tanggalBerlaku = doc['tanggalBerlaku'] != null ? DateTime.tryParse(doc['tanggalBerlaku']) : null;

    // Debug log
    print('📅 Certificate data:');
    print('   tanggalBerlaku raw: ${doc['tanggalBerlaku']}');
    print('   tanggalBerlaku parsed: $tanggalBerlaku');
    print('   uploadedAt raw: ${doc['uploadedAt']}');
    print('   uploadedAt parsed: $uploadedAt');

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6).withOpacity(0.1), Color(0xFF2563EB).withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.description_rounded, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['nama'] ?? 'Sertifikat Jalan',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        doc['nomorSertifikat'] ?? '-',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
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
              children: [
                _buildDetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Berlaku Hingga',
                  value: tanggalBerlaku != null 
                      ? dateFormat.format(tanggalBerlaku) 
                      : 'Belum diisi admin',
                  color: tanggalBerlaku != null ? Colors.orange : Colors.grey,
                ),
                SizedBox(height: 12),
                _buildDetailRow(
                  icon: Icons.upload_file_rounded,
                  label: 'Diupload',
                  value: uploadedAt != null ? dateFormat.format(uploadedAt) : '-',
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
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
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Belum ada sertifikat jalan',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
