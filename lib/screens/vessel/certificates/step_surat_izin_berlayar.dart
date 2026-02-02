import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../services/api/vessel_service.dart';

class StepSuratIzinBerlayar extends StatefulWidget {
  final VoidCallback onNext;
  const StepSuratIzinBerlayar({Key? key, required this.onNext}) : super(key: key);
  
  @override
  State<StepSuratIzinBerlayar> createState() => _StepSuratIzinBerlayarState();
}

class _StepSuratIzinBerlayarState extends State<StepSuratIzinBerlayar> {
  final _formKey = GlobalKey<FormState>();
  final _nomorSIBController = TextEditingController();
  final _pelabuhanKeberangkatanController = TextEditingController();
  final _tanggalBerlayarController = TextEditingController();
  final _masaBerlakuController = TextEditingController();
  final _statusController = TextEditingController();
  
  String? _namaKapal;
  String? _nomorRegistrasi;
  DateTime? _tanggalBerlayar;
  DateTime? _masaBerlaku;
  String? _filePath;
  String? _fileName;
  String? _fileType;
  bool _isLoading = false;
  
  String _getStatusText() {
    if (_masaBerlaku == null) return '';
    final now = DateTime.now();
    
    if (_masaBerlaku!.isBefore(now)) {
      return 'Kadaluarsa';
    }
    
    final duration = _masaBerlaku!.difference(now);
    final totalHours = duration.inHours;
    final totalDays = duration.inDays;
    
    if (totalHours < 24) {
      final hours = totalHours;
      final minutes = duration.inMinutes % 60;
      if (hours == 0) {
        return 'Aktif $minutes menit';
      }
      return minutes > 0 ? 'Aktif $hours jam $minutes menit' : 'Aktif $hours jam';
    }
    
    if (totalDays < 7) {
      final days = totalDays;
      final hours = totalHours % 24;
      return hours > 0 ? 'Aktif $days hari $hours jam' : 'Aktif $days hari';
    }
    
    if (totalDays < 30) {
      final weeks = (totalDays / 7).floor();
      final days = totalDays % 7;
      return days > 0 ? 'Aktif $weeks minggu $days hari' : 'Aktif $weeks minggu';
    }
    
    if (totalDays < 365) {
      final months = (totalDays / 30).floor();
      final days = totalDays % 30;
      return days > 0 ? 'Aktif $months bulan $days hari' : 'Aktif $months bulan';
    }
    
    final years = (totalDays / 365).floor();
    final remainingDays = totalDays % 365;
    final months = (remainingDays / 30).floor();
    return months > 0 ? 'Aktif $years tahun $months bulan' : 'Aktif $years tahun';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final vesselData = await VesselService().getVesselData();
      if (vesselData != null && vesselData['kapal'] != null) {
        setState(() {
          _namaKapal = vesselData['kapal']['namaKapal'];
          _nomorRegistrasi = vesselData['kapal']['nomorRegistrasi'];
        });
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        if (file.size > 10 * 1024 * 1024) {
          _showSnackBar('Ukuran file maksimal 10MB', Colors.red);
          return;
        }
        setState(() {
          _filePath = file.path;
          _fileName = file.name;
          _fileType = file.extension?.toLowerCase() == 'pdf' ? 'pdf' : 'image';
        });
      }
    } catch (e) {
      _showSnackBar('Gagal memilih file', Colors.red);
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (image != null) {
        final file = File(image.path);
        if (await file.length() > 10 * 1024 * 1024) {
          _showSnackBar('Ukuran file maksimal 10MB', Colors.red);
          return;
        }
        setState(() {
          _filePath = image.path;
          _fileName = image.path.split('/').last;
          _fileType = 'image';
        });
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil foto', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_namaKapal == null || _nomorRegistrasi == null || _pelabuhanKeberangkatanController.text.trim().isEmpty ||
        _tanggalBerlayar == null || _masaBerlaku == null || _filePath == null) {
      _showSnackBar('Semua field wajib diisi', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final masaBerlakuStr = '${_masaBerlaku!.year}-${_masaBerlaku!.month.toString().padLeft(2, '0')}-${_masaBerlaku!.day.toString().padLeft(2, '0')} ${_masaBerlaku!.hour.toString().padLeft(2, '0')}:${_masaBerlaku!.minute.toString().padLeft(2, '0')}';
      final status = _getStatusText();
      
      print('\n📤 [UPLOAD SIB] START (MOCK MODE)');
      print('📝 Nomor SIB: ${_nomorSIBController.text.trim()}');
      print('📝 Nama Kapal: $_namaKapal');
      print('📝 Nomor Registrasi: $_nomorRegistrasi');
      print('📝 Pelabuhan Keberangkatan: ${_pelabuhanKeberangkatanController.text.trim()}');
      print('📝 Tanggal Berlayar: ${_tanggalBerlayar!.year}-${_tanggalBerlayar!.month.toString().padLeft(2, '0')}-${_tanggalBerlayar!.day.toString().padLeft(2, '0')}');
      print('📝 Masa Berlaku: $masaBerlakuStr');
      print('📝 Status: $status');
      
      // TODO: Uncomment saat backend siap
      // await VesselService().uploadVesselDocument(
      //   jenisDokumen: 'Surat Izin Berlayar',
      //   filePath: _filePath!,
      //   nomorSertifikat: _nomorSIBController.text.trim(),
      //   tanggalBerlaku: masaBerlakuStr,
      // );
      
      await Future.delayed(Duration(seconds: 2));
      
      print('✅ [UPLOAD SIB] SUCCESS (MOCK)\n');
      _showSnackBar('Berhasil upload Surat Izin Berlayar! (Mock Mode)', Colors.green);
      widget.onNext();
    } catch (e) {
      print('❌ [UPLOAD SIB] ERROR: $e\n');
      _showSnackBar('Gagal upload: ${e.toString().replaceAll('Exception: ', '')}', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nomorSIBController.dispose();
    _pelabuhanKeberangkatanController.dispose();
    _tanggalBerlayarController.dispose();
    _masaBerlakuController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1B4F9C).withOpacity(0.1), Color(0xFF2563EB).withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.sailing_rounded, color: Colors.white, size: 18),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Surat Izin Berlayar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4F9C))),
                              SizedBox(height: 2),
                              Text('Data surat izin berlayar kapal', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Nomor SIB
                  TextFormField(
                    controller: _nomorSIBController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Nomor SIB *',
                      hintText: 'Contoh: SIB-001/2024',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                            ).createShader(bounds),
                            child: Icon(Icons.confirmation_number, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Nomor SIB wajib diisi' : null,
                  ),
                  SizedBox(height: 16),
                  
                  // Nama Kapal (Read-only)
                  TextFormField(
                    initialValue: _namaKapal ?? 'Loading...',
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Nama Kapal *',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                            ).createShader(bounds),
                            child: Icon(Icons.directions_boat, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Nomor Registrasi (Read-only)
                  TextFormField(
                    initialValue: _nomorRegistrasi ?? 'Loading...',
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Nomor Registrasi *',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                            ).createShader(bounds),
                            child: Icon(Icons.badge, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Pelabuhan Keberangkatan (Manual input)
                  TextFormField(
                    controller: _pelabuhanKeberangkatanController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Pelabuhan Keberangkatan *',
                      hintText: 'Contoh: Tanjung Priok',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                            ).createShader(bounds),
                            child: Icon(Icons.anchor, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Pelabuhan keberangkatan wajib diisi' : null,
                  ),
                  SizedBox(height: 16),
                  
                  // Tanggal Berlayar
                  TextFormField(
                    controller: _tanggalBerlayarController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Tanggal Berlayar *',
                      hintText: 'Pilih tanggal berlayar',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                            ).createShader(bounds),
                            child: Icon(Icons.calendar_today, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onTap: () async {
                      final now = DateTime.now();
                      final initialDate = _tanggalBerlayar ?? now;
                      final date = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime(2000),
                        lastDate: now.add(Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _tanggalBerlayar = date;
                          _tanggalBerlayarController.text = '${date.day}/${date.month}/${date.year}';
                        });
                      }
                    },
                    validator: (value) => _tanggalBerlayar == null ? 'Tanggal berlayar wajib diisi' : null,
                  ),
                  SizedBox(height: 16),
                  
                  // Masa Berlaku
                  TextFormField(
                    controller: _masaBerlakuController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Masa Berlaku *',
                      hintText: 'Pilih masa berlaku',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                            ).createShader(bounds),
                            child: Icon(Icons.event_available, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onTap: () async {
                      final now = DateTime.now();
                      final initialDate = _masaBerlaku ?? now.add(Duration(days: 1));
                      
                      final date = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: now,
                        lastDate: now.add(Duration(days: 3650)),
                      );
                      if (date != null) {
                        setState(() {
                          _masaBerlaku = DateTime(date.year, date.month, date.day, 23, 59);
                          _masaBerlakuController.text = '${date.day}/${date.month}/${date.year}';
                          _statusController.text = _getStatusText();
                        });
                      }
                    },
                    validator: (value) {
                      if (_masaBerlaku == null) return 'Masa berlaku wajib diisi';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Status (Auto-calculated)
                  if (_masaBerlaku != null)
                    TextFormField(
                      controller: _statusController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(12),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                              ).createShader(bounds),
                              child: Icon(Icons.info_outline, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _getStatusText().contains('Aktif') ? Colors.green : Colors.red,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _getStatusText().contains('Aktif') ? Colors.green : Colors.red,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      style: TextStyle(
                        color: _getStatusText().contains('Aktif') ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  SizedBox(height: 20),
                  
                  // File Upload
                  if (_filePath != null) ...[
                    GestureDetector(
                      onTap: () {
                        if (_fileType == 'image') {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    children: [
                                      Image.file(File(_filePath!)),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: IconButton(
                                          icon: Icon(Icons.close, color: Colors.white),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.black54,
                                          ),
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            if (_fileType == 'image')
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_filePath!),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Icon(Icons.picture_as_pdf, color: Colors.green[700]),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_fileName ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  if (_fileType == 'image')
                                    Text('Tap untuk preview', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, size: 20),
                              onPressed: () => setState(() {
                                _filePath = null;
                                _fileName = null;
                                _fileType = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: Icon(Icons.folder),
                          label: Text('Pilih File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            side: BorderSide(color: Colors.blue[200]!),
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickImageFromCamera,
                          icon: Icon(Icons.camera_alt),
                          label: Text('Foto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.purple,
                            side: BorderSide(color: Colors.purple[200]!),
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Upload & Lanjut', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
