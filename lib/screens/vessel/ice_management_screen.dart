import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api/vessel_service.dart';
import '../../services/api/document_service.dart';
import '../../services/realtime/realtime_update_service.dart';

class IceManagementScreen extends StatefulWidget {
  const IceManagementScreen({Key? key}) : super(key: key);

  @override
  State<IceManagementScreen> createState() => _IceManagementScreenState();
}

class _IceManagementScreenState extends State<IceManagementScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _jenisEs = 'Es Balok';
  final _jumlahController = TextEditingController();
  final _hargaPerUnitController = TextEditingController();
  final _totalHargaController = TextEditingController();
  DateTime? _tanggalPembelian;
  final _lokasiPembelianController = TextEditingController();
  final _keteranganController = TextEditingController();
  String? _buktiFilePath;
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
                      'Silakan lengkapi dokumen pribadi terlebih dahulu sebelum input data es.',
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

  @override
  void dispose() {
    _jumlahController.dispose();
    _hargaPerUnitController.dispose();
    _totalHargaController.dispose();
    _lokasiPembelianController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _calculateTotalHarga() {
    final jumlah = double.tryParse(_jumlahController.text) ?? 0;
    final harga = double.tryParse(_hargaPerUnitController.text) ?? 0;
    final total = jumlah * harga;
    _totalHargaController.text = total.toStringAsFixed(0);
  }

  String get _unitLabel => _jenisEs == 'Es Balok' ? 'Balok' : 'Kg';

  Future<void> _submitIceData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tanggalPembelian == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Tanggal pembelian harus diisi'),
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
      final jumlah = double.parse(_jumlahController.text);
      final hargaPerUnit = double.parse(_hargaPerUnitController.text);
      final totalHarga = double.parse(_totalHargaController.text);

      print('❄️ Submitting ice data:');
      print('   Jenis: $_jenisEs');
      print('   Jumlah: $jumlah');
      print('   Harga/Unit: $hargaPerUnit');
      print('   Total: $totalHarga');
      print('   Tanggal: ${_tanggalPembelian!.toIso8601String()}');

      final result = await VesselService().uploadIceData(
        jenisEs: _jenisEs,
        jumlahKg: jumlah,
        hargaPerKg: hargaPerUnit,
        totalHarga: totalHarga,
        tanggalPembelian: _tanggalPembelian!.toIso8601String(),
        lokasiPembelian: _lokasiPembelianController.text.isNotEmpty
            ? _lokasiPembelianController.text
            : null,
        keterangan: _keteranganController.text.isNotEmpty
            ? _keteranganController.text
            : null,
        buktiFilePath: _buktiFilePath,
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
                Text('Data es berhasil disimpan'),
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
      print('❌ Error uploading ice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Gagal menyimpan data: $e')),
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
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Input Pembelian Es',
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
          colors: [Colors.cyan.withOpacity(0.1), Colors.cyan.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.ac_unit_rounded, color: Colors.cyan[800], size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pembelian Es',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Isi data pembelian es dengan lengkap',
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
              'Detail Pembelian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 20),
            
            // Jenis Es
            DropdownButtonFormField<String>(
              value: _jenisEs,
              decoration: InputDecoration(
                labelText: 'Jenis Es',
                labelStyle: TextStyle(color: Colors.grey[700]),
                prefixIcon: Icon(Icons.ac_unit_rounded, color: Colors.cyan),
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
                  borderSide: BorderSide(color: Colors.cyan, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: ['Es Balok', 'Es Curah', 'Es Tube']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() {
                _jenisEs = value!;
                _calculateTotalHarga(); // Recalculate when unit changes
              }),
            ),
            SizedBox(height: 20),
            
            // Jumlah
            TextFormField(
              controller: _jumlahController,
              decoration: _buildInputDecoration(
                label: 'Jumlah',
                hint: 'Contoh: 50',
                suffix: _unitLabel,
                icon: Icons.inventory_2_rounded,
                iconColor: Colors.cyan,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => _calculateTotalHarga(),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Jumlah wajib diisi';
                if (double.tryParse(value!) == null) return 'Harus berupa angka';
                if (double.parse(value) <= 0) return 'Harus lebih dari 0';
                return null;
              },
            ),
            SizedBox(height: 20),
            
            // Harga per Unit
            TextFormField(
              controller: _hargaPerUnitController,
              decoration: _buildInputDecoration(
                label: 'Harga Per $_unitLabel',
                hint: 'Contoh: 25000',
                prefix: 'Rp ',
                icon: Icons.attach_money_rounded,
                iconColor: Colors.green,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _calculateTotalHarga(),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Harga wajib diisi';
                if (double.tryParse(value!) == null) return 'Harus berupa angka';
                if (double.parse(value) <= 0) return 'Harus lebih dari 0';
                return null;
              },
            ),
            SizedBox(height: 20),
            
            // Total Harga (auto-calculated)
            TextFormField(
              controller: _totalHargaController,
              decoration: _buildInputDecoration(
                label: 'Total Harga',
                prefix: 'Rp ',
                icon: Icons.payments_rounded,
                iconColor: Colors.purple,
              ).copyWith(
                filled: true,
                fillColor: Colors.grey[100],
              ),
              readOnly: true,
            ),
            SizedBox(height: 20),
            
            // Tanggal Pembelian
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(Duration(days: 1)),
                  firstDate: DateTime.now().subtract(Duration(days: 365)),
                  lastDate: DateTime.now().subtract(Duration(days: 1)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Colors.cyan,
                          onPrimary: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) setState(() => _tanggalPembelian = date);
              },
              child: InputDecorator(
                decoration: _buildInputDecoration(
                  label: 'Tanggal Pembelian',
                  icon: Icons.calendar_today_rounded,
                  iconColor: Colors.red,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _tanggalPembelian != null
                          ? '${_tanggalPembelian!.day}/${_tanggalPembelian!.month}/${_tanggalPembelian!.year}'
                          : 'Pilih tanggal pembelian',
                      style: TextStyle(
                        color: _tanggalPembelian != null ? Colors.black87 : Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Lokasi (Optional)
            TextFormField(
              controller: _lokasiPembelianController,
              decoration: _buildInputDecoration(
                label: 'Lokasi Pembelian (Opsional)',
                hint: 'Contoh: Pabrik Es Pelabuhan',
                icon: Icons.location_on_rounded,
                iconColor: Colors.red,
              ),
            ),
            SizedBox(height: 20),
            
            // Keterangan (Optional)
            TextFormField(
              controller: _keteranganController,
              decoration: _buildInputDecoration(
                label: 'Keterangan (Opsional)',
                hint: 'Catatan tambahan...',
                icon: Icons.note_alt_rounded,
                iconColor: Colors.grey[700]!,
              ),
              maxLines: 3,
            ),
            SizedBox(height: 24),
            
            // Bukti Upload
            _buildBuktiUpload(),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    String? hint,
    String? prefix,
    String? suffix,
    required IconData icon,
    required Color iconColor,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.grey[700]),
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixText: prefix,
      suffixText: suffix,
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
        borderSide: BorderSide(color: Colors.cyan, width: 2),
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

  Widget _buildBuktiUpload() {
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
              Icon(Icons.receipt_long_rounded, color: Colors.cyan[700], size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bukti Pembelian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Opsional',
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
          if (_buktiFilePath != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _buktiFilePath!.split('/').last,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green[900],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _buktiFilePath = null),
                    color: Colors.green[700],
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                    );
                    if (image != null) setState(() => _buktiFilePath = image.path);
                  },
                  icon: Icon(Icons.camera_alt_rounded, size: 20),
                  label: Text('Kamera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.cyan[700],
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.cyan[200]!),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (image != null) setState(() => _buktiFilePath = image.path);
                  },
                  icon: Icon(Icons.photo_library_rounded, size: 20),
                  label: Text('Galeri'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple[700],
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.purple[200]!),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitIceData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
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
                  Icon(Icons.save_rounded, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Simpan Data Es',
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