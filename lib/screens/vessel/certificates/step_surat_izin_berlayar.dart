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
  final _namaController = TextEditingController();
  final _nomorController = TextEditingController();
  DateTime? _tanggalBerlaku;
  String? _filePath, _fileName, _fileType;
  bool _isLoading = false;

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
    if (_namaController.text.trim().isEmpty || _nomorController.text.trim().isEmpty || _tanggalBerlaku == null || _filePath == null) {
      _showSnackBar('Semua field wajib diisi', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final tanggal = '${_tanggalBerlaku!.year}-${_tanggalBerlaku!.month.toString().padLeft(2, '0')}-${_tanggalBerlaku!.day.toString().padLeft(2, '0')}';
      await VesselService().uploadVesselDocument(
        jenisDokumen: 'Surat Izin Berlayar',
        filePath: _filePath!,
        nomorSertifikat: _nomorController.text.trim(),
        tanggalBerlaku: tanggal,
      );
      _showSnackBar('Berhasil upload!', Colors.green);
      widget.onNext();
    } catch (e) {
      _showSnackBar('Gagal upload: ${e.toString().replaceAll('Exception: ', '')}', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
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
                TextField(
                  controller: _namaController,
                  decoration: InputDecoration(
                    labelText: 'Nama Sertifikat',
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
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _nomorController,
                  decoration: InputDecoration(
                    labelText: 'Nomor Sertifikat',
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
                ),
                SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 3650)),
                    );
                    if (date != null) setState(() => _tanggalBerlaku = date);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tanggal Berlaku',
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
                            child: Icon(Icons.event, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _tanggalBerlaku != null ? '${_tanggalBerlaku!.day}/${_tanggalBerlaku!.month}/${_tanggalBerlaku!.year}' : 'Pilih tanggal',
                      style: TextStyle(color: _tanggalBerlaku != null ? Colors.black87 : Colors.grey),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (_filePath != null) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(_fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image, color: Colors.green[700]),
                        SizedBox(width: 12),
                        Expanded(child: Text(_fileName ?? '')),
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
