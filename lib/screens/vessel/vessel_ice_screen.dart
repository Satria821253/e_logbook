import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';
import '../../services/api/vessel_service.dart';
import '../../services/api/document_service.dart';

class VesselIceScreen extends StatefulWidget {
  const VesselIceScreen({Key? key}) : super(key: key);

  @override
  State<VesselIceScreen> createState() => _VesselIceScreenState();
}

class _VesselIceScreenState extends State<VesselIceScreen> with TickerProviderStateMixin {
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  bool _isLoading = true;
  Map<String, dynamic>? _iceData;
  Map<String, dynamic>? _vesselData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkValidations();
    });
  }

  Future<void> _checkValidations() async {
    print('🔍 [ICE] _checkValidations called');
    // Cek role user
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isNahkoda = userProvider.user?.isNahkoda == true;
    print('👤 [ICE] User role: ${isNahkoda ? "Nahkoda" : "Crew"}');
    
    // Jika Nahkoda, cek apakah ada data es
    if (isNahkoda) {
      print('👨‍✈️ [ICE] Nahkoda detected, loading ice data...');
      await _loadIceData();
      
      print('📊 [ICE] Ice data loaded: ${_iceData != null}');
      if (mounted) {
        if (_iceData == null) {
          print('⚠️ [ICE] Failed to load data (null), showing popup...');
          _showNoIceDataDialog();
        } else {
          final iceDataList = _iceData?['iceData'] as List? ?? [];
          print('🧊 [ICE] Ice data count: ${iceDataList.length}');
          if (iceDataList.isEmpty) {
            print('⚠️ [ICE] No ice data, showing popup...');
            _showNoIceDataDialog();
          } else {
            print('✅ [ICE] Ice data available, showing list');
          }
        }
      }
      return;
    }
    
    // Untuk Crew: Cek dokumen pribadi
    print('👥 [ICE] Crew detected, checking documents...');
    try {
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
        print('📝 [ICE] Approved documents: $approvedCount/8');
        
        if (approvedCount < 8) {
          final totalUploaded = latestDocs.length;
          if (totalUploaded < 8) {
            _showDocumentIncompleteDialog(hasDocuments: false);
          } else {
            _showDocumentIncompleteDialog(hasDocuments: true);
          }
          return;
        }
      }
    } catch (e) {
      print('❌ Error checking documents: $e');
    }
    
    // Load data es
    await _loadIceData();
    
    // Cek apakah ada data es (hanya untuk crew)
    if (mounted) {
      if (_iceData == null) {
        _showNoIceDataDialog();
      } else {
        final iceDataList = _iceData?['iceData'] as List? ?? [];
        if (iceDataList.isEmpty) {
          _showNoIceDataDialog();
        }
      }
    }
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
                      'Dokumen pribadi Anda belum lengkap atau belum disetujui.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Silakan lengkapi dokumen pribadi terlebih dahulu sebelum melihat data es.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        shakeController.dispose();
                        nav.pop();
                        nav.pop();
                        await Future.delayed(Duration(milliseconds: 200));
                        if (hasDocuments) {
                          nav.pushNamed('/document-status');
                        } else {
                          nav.pushNamed('/crew-document-upload');
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

  void _showNoIceDataDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isNahkoda = userProvider.user?.isNahkoda == true;
    
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
                      child: Icon(Icons.ac_unit_outlined, size: 40, color: Colors.blue),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Belum Ada Data Es',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      isNahkoda 
                        ? 'Crew belum melakukan pembelian es.'
                        : 'Anda belum melakukan pembelian es.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      isNahkoda
                        ? 'Silakan tunggu crew untuk input data es terlebih dahulu.'
                        : 'Silakan upload data es terlebih dahulu melalui menu Manajemen Es.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        shakeController.dispose();
                        Navigator.pop(context);
                        Navigator.pop(context);
                        if (!isNahkoda) {
                          // Crew: redirect ke manajemen es
                          Navigator.pushNamed(context, '/ice-management');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        isNahkoda ? 'OK' : 'Upload Data Es',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
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

  Future<void> _loadIceData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        VesselService().getIceData(),
        VesselService().getVesselData(),
      ]);
      
      setState(() {
        _iceData = results[0] as Map<String, dynamic>;
        _vesselData = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kapalInfo = _iceData?['kapal'];
    final iceDataList = _iceData?['iceData'] as List? ?? [];

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
          'Data Es Kapal',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.cyan))
          : Column(
              children: [
                if (kapalInfo != null) _buildKapalHeader(kapalInfo),
                Expanded(
                  child: iceDataList.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadIceData,
                          child: ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: iceDataList.length,
                            itemBuilder: (context, index) {
                              return _buildIceCard(iceDataList[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildKapalHeader(Map<String, dynamic> kapal) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isNahkoda = userProvider.user?.isNahkoda == true;
    final nahkodaName = _vesselData?['nahkoda']?['nama'];
    
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
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
                if (!isNahkoda && nahkodaName != null) ...[
                  SizedBox(height: 4),
                  Text(
                    'Nahkoda: $nahkodaName',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIceCard(Map<String, dynamic> doc) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    final tanggalPembelian = doc['tanggalPembelian'] != null ? DateTime.parse(doc['tanggalPembelian']) : null;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.cyan[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.ac_unit_rounded, color: Colors.cyan[700], size: 22),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc['jenisEs'] ?? 'Es',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      tanggalPembelian != null ? dateFormat.format(tanggalPembelian) : '-',
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
          SizedBox(height: 12),
          Divider(height: 1),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.scale_rounded, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 6),
                    Text(
                      '${doc['jumlahKg'] ?? 0} Kg',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.payments_rounded, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 6),
                    Text(
                      _formatCurrency(doc['totalHarga'] ?? 0),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (doc['lokasiPembelian'] != null && doc['lokasiPembelian'].toString().isNotEmpty) ...[
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 16, color: Colors.grey[600]),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    doc['lokasiPembelian'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (doc['buktiFileUrl'] != null) ...[
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.receipt, size: 16, color: Colors.green[600]),
                SizedBox(width: 6),
                Text(
                  'Bukti tersedia',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ac_unit_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Belum ada data es',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'Rp 0';
    final number = value is int ? value : (value is double ? value.toInt() : 0);
    return _currencyFormat.format(number);
  }
}
