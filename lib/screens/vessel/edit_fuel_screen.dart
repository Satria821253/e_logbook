import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api/vessel_service.dart';
import '../../services/realtime/realtime_update_service.dart';

class EditFuelScreen extends StatefulWidget {
  final Map<String, dynamic> fuelData;

  const EditFuelScreen({Key? key, required this.fuelData}) : super(key: key);

  @override
  State<EditFuelScreen> createState() => _EditFuelScreenState();
}

class _EditFuelScreenState extends State<EditFuelScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _jenisBahanBakar;
  late TextEditingController _jumlahLiterController;
  late TextEditingController _hargaPerLiterController;
  late TextEditingController _totalHargaController;
  DateTime? _tanggalPengisian;
  late TextEditingController _lokasiPengisianController;
  late TextEditingController _keteranganController;
  String? _buktiFilePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _jenisBahanBakar = widget.fuelData['jenisBahanBakar'] ?? 'Solar';
    _jumlahLiterController = TextEditingController(text: widget.fuelData['jumlahLiter']?.toString() ?? '');
    _hargaPerLiterController = TextEditingController(text: widget.fuelData['hargaPerLiter']?.toString() ?? '');
    _totalHargaController = TextEditingController(text: widget.fuelData['totalHarga']?.toString() ?? '');
    _lokasiPengisianController = TextEditingController(text: widget.fuelData['lokasiPengisian'] ?? '');
    _keteranganController = TextEditingController(text: widget.fuelData['keterangan'] ?? '');
    
    if (widget.fuelData['tanggalPengisian'] != null) {
      _tanggalPengisian = DateTime.parse(widget.fuelData['tanggalPengisian']);
    }
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

  Future<void> _updateFuelData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tanggalPengisian == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tanggal pengisian harus diisi'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final jumlahLiter = double.parse(_jumlahLiterController.text);
      final hargaPerLiter = double.parse(_hargaPerLiterController.text);
      final totalHarga = double.parse(_totalHargaController.text);

      print('📝 Update BBM Request:');
      print('   Fuel ID: ${widget.fuelData['id']}');
      print('   Jenis: $_jenisBahanBakar');
      print('   Jumlah: $jumlahLiter L');
      print('   Harga/L: Rp $hargaPerLiter');
      print('   Total: Rp $totalHarga');

      final result = await VesselService().updateBahanBakar(
        fuelId: widget.fuelData['id'].toString(),
        jenisBahanBakar: _jenisBahanBakar,
        jumlahLiter: jumlahLiter,
        hargaPerLiter: hargaPerLiter,
        totalHarga: totalHarga,
        tanggalPengisian: _tanggalPengisian!.toIso8601String(),
        lokasiPengisian: _lokasiPengisianController.text.isNotEmpty ? _lokasiPengisianController.text : null,
        keterangan: _keteranganController.text.isNotEmpty ? _keteranganController.text : null,
        buktiFilePath: _buktiFilePath,
      );

      print('✅ Update result: $result');

      if (mounted) {
        // Trigger auto-refresh di parent screen
        RealtimeUpdateService.notifyListeners('vessel');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data BBM berhasil diupdate'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Update error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update data: $e'), backgroundColor: Colors.red),
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
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('Edit Data BBM', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1B4F9C).withOpacity(0.1),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.local_gas_station, color: Color(0xFF1B4F9C), size: 24),
                SizedBox(width: 12),
                Text('Edit Data BBM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4F9C))),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _jenisBahanBakar,
                  decoration: InputDecoration(
                    labelText: 'Jenis Bahan Bakar *',
                    prefixIcon: Icon(Icons.local_gas_station, color: Color(0xFF1B4F9C)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Solar', 'Bensin', 'Pertamax'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (value) => setState(() => _jenisBahanBakar = value!),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _jumlahLiterController,
                  decoration: InputDecoration(
                    labelText: 'Jumlah Liter *',
                    suffixText: 'Liter',
                    prefixIcon: Icon(Icons.water_drop, color: Colors.blue),
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
                  controller: _hargaPerLiterController,
                  decoration: InputDecoration(
                    labelText: 'Harga Per Liter *',
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
                    final now = DateTime.now();
                    final existingDate = _tanggalPengisian ?? now.subtract(Duration(days: 1));
                    final date = await showDatePicker(
                      context: context,
                      initialDate: existingDate.isAfter(now) ? now.subtract(Duration(days: 1)) : existingDate,
                      firstDate: DateTime(2020),
                      lastDate: now.subtract(Duration(days: 1)),
                    );
                    if (date != null) setState(() => _tanggalPengisian = date);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tanggal Pengisian *',
                      prefixIcon: Icon(Icons.calendar_today, color: Colors.red),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _tanggalPengisian != null
                          ? '${_tanggalPengisian!.day}/${_tanggalPengisian!.month}/${_tanggalPengisian!.year}'
                          : 'Pilih tanggal',
                      style: TextStyle(color: _tanggalPengisian != null ? Colors.black : Colors.grey),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _lokasiPengisianController,
                  decoration: InputDecoration(
                    labelText: 'Lokasi Pengisian',
                    hintText: 'Contoh: SPBU Pelabuhan',
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
              Icon(Icons.receipt, color: Colors.blue),
              SizedBox(width: 8),
              Text('Bukti Pengisian (Opsional)', style: TextStyle(fontWeight: FontWeight.w500)),
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
        onPressed: _isLoading ? null : _updateFuelData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1B4F9C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Update Data BBM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
      ),
    );
  }
}
