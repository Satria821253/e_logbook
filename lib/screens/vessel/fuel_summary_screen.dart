import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/getAPi/vessel_service.dart';
import '../../services/getAPi/document_service.dart';

class FuelSummaryScreen extends StatefulWidget {
  const FuelSummaryScreen({Key? key}) : super(key: key);

  @override
  State<FuelSummaryScreen> createState() => _FuelSummaryScreenState();
}

class _FuelSummaryScreenState extends State<FuelSummaryScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _summaryData;
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    print('\n========== FUEL SUMMARY SCREEN INIT ==========');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkPersonalDocuments();
    });
  }

  Future<void> _checkPersonalDocuments() async {
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
        
        if (approvedCount < 8) {
          final totalUploaded = latestDocs.length;
          if (totalUploaded < 8) {
            _showDocumentIncompleteDialog(hasDocuments: false);
          } else {
            _showDocumentIncompleteDialog(hasDocuments: true);
          }
          return; // Jangan load summary jika dokumen belum lengkap
        }
      }
    } catch (e) {
      print('❌ Error checking documents: $e');
    }
    
    // Hanya load summary jika dokumen sudah lengkap
    await _loadSummary();
    
    // Setelah load, cek apakah ada data BBM
    if (mounted && _summaryData != null) {
      final summary = _summaryData?['summary'];
      final totalPengisian = summary?['totalPengisian'] ?? 0;
      
      if (totalPengisian == 0) {
        _showNoFuelDataDialog();
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
                      'Silakan lengkapi dokumen pribadi terlebih dahulu sebelum melihat data BBM.',
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

  void _showNoFuelDataDialog() {
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
                      child: Icon(Icons.local_gas_station_outlined, size: 40, color: Colors.blue),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Belum Ada Data BBM',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Anda belum pernah melakukan pengisian BBM.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Silakan input data BBM terlebih dahulu untuk melihat ringkasan.',
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
                      child: Text('Input BBM Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Future<void> _loadSummary() async {
    print('\n🔄 [FuelSummary] Loading summary...');
    print('📅 [FuelSummary] Start Date: $_startDate');
    print('📅 [FuelSummary] End Date: $_endDate');
    
    setState(() => _isLoading = true);
    try {
      final data = await VesselService().getFuelSummary(
        startDate: _startDate,
        endDate: _endDate,
      );
      
      print('✅ [FuelSummary] Data received successfully');
      print('📊 [FuelSummary] Data keys: ${data.keys.toList()}');
      
      if (data['summary'] != null) {
        final summary = data['summary'];
        print('📈 [FuelSummary] Total Pengisian: ${summary['totalPengisian']}');
        print('📈 [FuelSummary] Total Liter: ${summary['totalLiter']}');
        print('📈 [FuelSummary] Total Biaya: ${summary['totalBiaya']}');
        print('📈 [FuelSummary] Rata-rata Harga: ${summary['rataRataHarga']}');
        print('📈 [FuelSummary] Pengisian Terakhir: ${summary['pengisianTerakhir'] != null ? "Ada" : "Tidak ada"}');
      }
      
      if (data['details'] != null) {
        print('📋 [FuelSummary] Details count: ${(data['details'] as List).length}');
      }
      
      setState(() {
        _summaryData = data;
        _isLoading = false;
      });
      
      print('✅ [FuelSummary] Summary loaded successfully\n');
    } catch (e, stackTrace) {
      print('❌ [FuelSummary] Error loading fuel summary: $e');
      print('❌ [FuelSummary] Stack trace: $stackTrace');
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat ringkasan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    print('\n📅 [FuelSummary] Opening date range picker...');
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      print('✅ [FuelSummary] Date range selected:');
      print('   Start: ${picked.start}');
      print('   End: ${picked.end}');
      
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadSummary();
    } else {
      print('❌ [FuelSummary] Date range picker cancelled');
    }
  }

  void _clearFilter() {
    print('\n🗑️ [FuelSummary] Clearing date filter...');
    
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    
    print('✅ [FuelSummary] Filter cleared, reloading all data');
    _loadSummary();
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
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Ringkasan BBM',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_rounded),
            onPressed: _selectDateRange,
            tooltip: 'Filter Tanggal',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _summaryData == null
                ? _buildEmptyState()
                : SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_startDate != null && _endDate != null) _buildFilterChip(),
                        SizedBox(height: 16),
                        _buildSummaryCards(),
                        SizedBox(height: 24),
                        _buildLastFuelCard(),
                        SizedBox(height: 24),
                        _buildDetailSection(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildFilterChip() {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, color: Colors.purple[700], size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}',
              style: TextStyle(
                color: Colors.purple[700],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20),
            onPressed: _clearFilter,
            color: Colors.purple[700],
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _summaryData?['summary'] ?? {};
    final totalPengisian = summary['totalPengisian'] ?? 0;
    final totalLiter = summary['totalLiter'] ?? 0.0;
    final totalBiaya = summary['totalBiaya'] ?? 0;
    final rataRataHarga = summary['rataRataHarga'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_gas_station_rounded,
                label: 'Total Pengisian',
                value: '$totalPengisian',
                subtitle: 'kali',
                color: Colors.orange,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.water_drop_rounded,
                label: 'Total Liter',
                value: NumberFormat('#,##0.0', 'id_ID').format(totalLiter),
                subtitle: 'Liter',
                color: Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.payments_rounded,
                label: 'Total Biaya',
                value: _formatCurrency(totalBiaya),
                subtitle: '',
                color: Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.trending_up_rounded,
                label: 'Rata-rata Harga',
                value: _formatCurrency(rataRataHarga),
                subtitle: 'per liter',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLastFuelCard() {
    final pengisianTerakhir = _summaryData?['summary']?['pengisianTerakhir'];
    
    if (pengisianTerakhir == null) {
      return SizedBox.shrink();
    }

    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final tanggal = pengisianTerakhir['tanggalPengisian'] != null
        ? DateTime.parse(pengisianTerakhir['tanggalPengisian'])
        : null;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1B4F9C).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.access_time_rounded, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Text(
                'Pengisian Terakhir',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildLastFuelRow(
            'Jenis',
            pengisianTerakhir['jenisBahanBakar'] ?? '-',
          ),
          SizedBox(height: 12),
          _buildLastFuelRow(
            'Jumlah',
            '${pengisianTerakhir['jumlahLiter'] ?? 0} Liter',
          ),
          SizedBox(height: 12),
          _buildLastFuelRow(
            'Total Biaya',
            _formatCurrency(pengisianTerakhir['totalHarga'] ?? 0),
          ),
          SizedBox(height: 12),
          _buildLastFuelRow(
            'Tanggal',
            tanggal != null ? dateFormat.format(tanggal) : '-',
          ),
          if (pengisianTerakhir['lokasiPengisian'] != null) ...[
            SizedBox(height: 12),
            _buildLastFuelRow(
              'Lokasi',
              pengisianTerakhir['lokasiPengisian'],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLastFuelRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection() {
    final details = _summaryData?['details'] as List? ?? [];
    
    if (details.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Riwayat Pengisian',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        ...details.map((fuel) => _buildDetailCard(fuel)).toList(),
      ],
    );
  }

  Widget _buildDetailCard(Map<String, dynamic> fuel) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final tanggal = fuel['tanggalPengisian'] != null
        ? DateTime.parse(fuel['tanggalPengisian'])
        : null;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.local_gas_station, color: Colors.orange, size: 22),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fuel['jenisBahanBakar'] ?? '-',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      tanggal != null ? dateFormat.format(tanggal) : '-',
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
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailInfo(
                  'Jumlah',
                  '${fuel['jumlahLiter'] ?? 0} L',
                  Icons.water_drop,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildDetailInfo(
                  'Total',
                  _formatCurrency(fuel['totalHarga'] ?? 0),
                  Icons.payments,
                  Colors.green,
                ),
              ),
            ],
          ),
          if (fuel['lokasiPengisian'] != null) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fuel['lokasiPengisian'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailInfo(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
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
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Belum ada data BBM',
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