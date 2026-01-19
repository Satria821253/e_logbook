import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/getAPi/vessel_service.dart';

class IceManagementScreen extends StatefulWidget {
  const IceManagementScreen({Key? key}) : super(key: key);

  @override
  State<IceManagementScreen> createState() => _IceManagementScreenState();
}

class _IceManagementScreenState extends State<IceManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  String _jenisEs = 'Balok';
  final _jumlahController = TextEditingController();
  final _hargaPerUnitController = TextEditingController();
  final _totalHargaController = TextEditingController();
  DateTime? _tanggalPembelian;
  final _lokasiPembelianController = TextEditingController();
  final _keteranganController = TextEditingController();
  String? _buktiFilePath;
  bool _isLoading = false;

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

  Future<void> _submitIceData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tanggalPembelian == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tanggal pembelian harus diisi'),
          backgroundColor: Colors.orange,
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
        jumlah: jumlah,
        hargaPerUnit: hargaPerUnit,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data es berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error uploading ice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.cyan, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Manajemen Es',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInputCard(),
              SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.ac_unit, color: Colors.cyan, size: 24),
                SizedBox(width: 12),
                Text(
                  'Input Pembelian Es',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan[800],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _jenisEs,
                  decoration: InputDecoration(
                    labelText: 'Jenis Es *',
                    prefixIcon: Icon(Icons.ac_unit, color: Colors.cyan),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Balok', 'Curah', 'Tube']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => _jenisEs = value!),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _jumlahController,
                  decoration: InputDecoration(
                    labelText: 'Jumlah *',
                    suffixText: _jenisEs == 'Balok' ? 'Balok' : 'Kg',
                    prefixIcon: Icon(Icons.ac_unit, color: Colors.cyan),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => _calculateTotalHarga(),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Wajib diisi';
                    if (double.tryParse(value!) == null) return 'Harus angka';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _hargaPerUnitController,
                  decoration: InputDecoration(
                    labelText: 'Harga Per ${_jenisEs == 'Balok' ? 'Balok' : 'Kg'} *',
                    prefixText: 'Rp ',
                    prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _calculateTotalHarga(),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Wajib diisi';
                    if (double.tryParse(value!) == null) return 'Harus angka';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _totalHargaController,
                  decoration: InputDecoration(
                    labelText: 'Total Harga *',
                    prefixText: 'Rp ',
                    prefixIcon: Icon(Icons.payments, color: Colors.purple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  readOnly: true,
                ),
                SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(Duration(days: 1)),
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now().subtract(Duration(days: 1)),
                    );
                    if (date != null) setState(() => _tanggalPembelian = date);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tanggal Pembelian *',
                      prefixIcon: Icon(Icons.calendar_today, color: Colors.red),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _tanggalPembelian != null
                          ? '${_tanggalPembelian!.day}/${_tanggalPembelian!.month}/${_tanggalPembelian!.year}'
                          : 'Pilih tanggal',
                      style: TextStyle(
                        color: _tanggalPembelian != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _lokasiPembelianController,
                  decoration: InputDecoration(
                    labelText: 'Lokasi Pembelian',
                    hintText: 'Contoh: Pabrik Es Pelabuhan',
                    prefixIcon: Icon(Icons.location_on, color: Colors.red),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _keteranganController,
                  decoration: InputDecoration(
                    labelText: 'Keterangan',
                    prefixIcon: Icon(Icons.note, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                _buildBuktiUpload(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuktiUpload() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt, color: Colors.cyan),
              SizedBox(width: 8),
              Text('Bukti Pembelian (Opsional)', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          if (_buktiFilePath != null) ...[
            SizedBox(height: 8),
            Text(_buktiFilePath!.split('/').last, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                    if (image != null) setState(() => _buktiFilePath = image.path);
                  },
                  icon: Icon(Icons.camera_alt, size: 18),
                  label: Text('Kamera'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                    if (image != null) setState(() => _buktiFilePath = image.path);
                  },
                  icon: Icon(Icons.photo_library, size: 18),
                  label: Text('Galeri'),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Simpan Data Es', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
      ),
    );
  }
}
