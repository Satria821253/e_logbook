import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api/vessel_service.dart';
import '../../services/api/document_service.dart';
import '../../services/realtime/realtime_update_service.dart';

class FuelManagementScreen extends StatefulWidget {
  const FuelManagementScreen({Key? key}) : super(key: key);

  @override
  State<FuelManagementScreen> createState() => _FuelManagementScreenState();
}

class _FuelManagementScreenState extends State<FuelManagementScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _jenisBahanBakar = 'Solar';
  final _jumlahLiterController = TextEditingController();
  final _hargaPerLiterController = TextEditingController();
  final _totalHargaController = TextEditingController();
  DateTime? _tanggalPengisian;
  final _lokasiPengisianController = TextEditingController();
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
                      'Silakan lengkapi dokumen pribadi terlebih dahulu sebelum input data BBM.',
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
    _jumlahLiterController.dispose();
    _hargaPerLiterController.dispose();
    _totalHargaController.dispose();
    _lokasiPengisianController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _calculateTotalHarga() {
    final jumlah = double.tryParse(_jumlahLiterController.text) ?? 0;
    final harga = double.tryParse(_hargaPerLiterController.text) ?? 0;
    final total = jumlah * harga;
    _totalHargaController.text = total.toStringAsFixed(0);
  }

  Future<void> _submitFuelData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tanggalPengisian == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Tanggal pengisian harus diisi'),
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
      final jumlahLiter = double.parse(_jumlahLiterController.text);
      final hargaPerLiter = double.parse(_hargaPerLiterController.text);
      final totalHarga = double.parse(_totalHargaController.text);

      // Convert to UTC and format as ISO 8601 with Z
      final tanggalISO = _tanggalPengisian!.toUtc().toIso8601String();

      print('🔥 Submitting fuel data:');
      print('   Jenis: $_jenisBahanBakar');
      print('   Jumlah: $jumlahLiter');
      print('   Harga/L: $hargaPerLiter');
      print('   Total: $totalHarga');
      print('   Tanggal (Local): $_tanggalPengisian');
      print('   Tanggal (ISO UTC): $tanggalISO');

      final result = await VesselService().uploadBahanBakar(
        jenisBahanBakar: _jenisBahanBakar,
        jumlahLiter: jumlahLiter,
        hargaPerLiter: hargaPerLiter,
        totalHarga: totalHarga,
        tanggalPengisian: tanggalISO,
        lokasiPengisian: _lokasiPengisianController.text.isNotEmpty
            ? _lokasiPengisianController.text
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
                Text('Data BBM berhasil disimpan'),
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
      print('❌ Error uploading fuel: $e');
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
          'Input Bahan Bakar',
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
          colors: [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.info_outline, color: Colors.orange[800], size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengisian Bahan Bakar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Isi data dengan lengkap dan akurat',
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
              'Detail Pengisian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 20),
            
            // Jenis BBM
            DropdownButtonFormField<String>(
              value: _jenisBahanBakar,
              decoration: InputDecoration(
                labelText: 'Jenis Bahan Bakar',
                labelStyle: TextStyle(color: Colors.grey[700]),
                prefixIcon: Icon(Icons.local_gas_station_rounded, color: Colors.orange),
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
                  borderSide: BorderSide(color: Colors.orange, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: ['Solar', 'Bensin', 'Pertamax']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => _jenisBahanBakar = value!),
            ),
            SizedBox(height: 20),
            
            // Jumlah Liter
            TextFormField(
              controller: _jumlahLiterController,
              decoration: _buildInputDecoration(
                label: 'Jumlah Liter',
                hint: 'Contoh: 500',
                suffix: 'Liter',
                icon: Icons.water_drop_rounded,
                iconColor: Colors.blue,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => _calculateTotalHarga(),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Jumlah liter wajib diisi';
                if (double.tryParse(value!) == null) return 'Harus berupa angka';
                if (double.parse(value) <= 0) return 'Harus lebih dari 0';
                return null;
              },
            ),
            SizedBox(height: 20),
            
            // Harga per Liter
            TextFormField(
              controller: _hargaPerLiterController,
              decoration: _buildInputDecoration(
                label: 'Harga Per Liter',
                hint: 'Contoh: 6800',
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
            
            // Tanggal Pengisian
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
                          primary: Colors.orange,
                          onPrimary: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) setState(() => _tanggalPengisian = date);
              },
              child: InputDecorator(
                decoration: _buildInputDecoration(
                  label: 'Tanggal Pengisian',
                  icon: Icons.calendar_today_rounded,
                  iconColor: Colors.red,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _tanggalPengisian != null
                          ? '${_tanggalPengisian!.day}/${_tanggalPengisian!.month}/${_tanggalPengisian!.year}'
                          : 'Pilih tanggal pengisian',
                      style: TextStyle(
                        color: _tanggalPengisian != null ? Colors.black87 : Colors.grey[500],
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
              controller: _lokasiPengisianController,
              decoration: _buildInputDecoration(
                label: 'Lokasi Pengisian (Opsional)',
                hint: 'Contoh: SPBU Pelabuhan Muara Baru',
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
        borderSide: BorderSide(color: Colors.orange, width: 2),
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
        border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: Colors.blue[700], size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bukti Pengisian',
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
                    foregroundColor: Colors.blue[700],
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.blue[200]!),
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
        onPressed: _isLoading ? null : _submitFuelData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1B4F9C),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          shadowColor: Color(0xFF1B4F9C).withOpacity(0.4),
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
                    'Simpan Data BBM',
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