import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../services/api/trip_service.dart';

class StepSuratIzinBerlayar extends StatefulWidget {
  final int? tripId;
  final VoidCallback onNext;
  
  const StepSuratIzinBerlayar({Key? key, this.tripId, required this.onNext}) : super(key: key);
  
  @override
  State<StepSuratIzinBerlayar> createState() => _StepSuratIzinBerlayarState();
}

class _StepSuratIzinBerlayarState extends State<StepSuratIzinBerlayar> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();
  
  String? _filePath;
  String? _fileName;
  String? _fileType;
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
    if (!_formKey.currentState!.validate()) return;
    
    if (_filePath == null) {
      _showSnackBar('File dokumen wajib diupload', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('\n========== UPLOAD IZIN MELAUT START ==========');
      print('📤 [Upload] Trip ID: ${widget.tripId ?? "(general vessel doc)"}');
      print('📤 [Upload] Jenis Dokumen: izinMelaut');
      print('📤 [Upload] File Path: $_filePath');
      print('📤 [Upload] Keterangan: ${_keteranganController.text.trim()}');
      
      // Jika tidak ada tripId, upload sebagai dokumen kapal umum
      if (widget.tripId == null) {
        // TODO: Implement upload dokumen kapal umum (tanpa trip)
        // Sementara tampilkan pesan bahwa fitur ini untuk trip
        _showSnackBar(
          'Upload dokumen perizinan hanya untuk trip yang sudah diterima. Silakan terima trip terlebih dahulu.',
          Colors.orange,
        );
        setState(() => _isLoading = false);
        return;
      }
      
      final response = await TripService.uploadTripDocument(
        tripId: widget.tripId!,
        jenisDokumen: 'izinMelaut',
        filePath: _filePath!,
        keterangan: _keteranganController.text.trim().isEmpty 
            ? null 
            : _keteranganController.text.trim(),
      );

      print('📦 [Upload] Backend response:');
      print('   Success: ${response['success']}');
      print('   Message: ${response['message']}');
      print('   All Documents Complete: ${response['data']?['allDocumentsComplete']}');
      print('   Trip Status: ${response['data']?['tripStatus']}');
      print('========== UPLOAD IZIN MELAUT END ==========\n');

      _showSnackBar(
        response['message'] ?? 'Berhasil upload Surat Izin Melaut!', 
        Colors.green,
      );
      widget.onNext();
    } catch (e) {
      print('❌ [UPLOAD IZIN MELAUT] ERROR: $e\n');
      _showSnackBar(
        'Gagal upload: ${e.toString().replaceAll('Exception: ', '')}', 
        Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _keteranganController.dispose();
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
                              Text('Surat Izin Melaut', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4F9C))),
                              SizedBox(height: 2),
                              Text('Izin berlayar dari otoritas pelabuhan', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Keterangan
                  TextFormField(
                    controller: _keteranganController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      labelText: 'Keterangan (Opsional)',
                      hintText: 'Contoh: Izin melaut berlaku sampai 31 Des 2026',
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
                            child: Icon(Icons.note, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
