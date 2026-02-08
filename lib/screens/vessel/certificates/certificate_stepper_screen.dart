import 'package:flutter/material.dart';
import 'step_surat_izin_berlayar.dart';
import 'step_dokumen_kapal.dart';
import 'step_asuransi_kapal.dart';
import '../../../services/api/trip_service.dart';
import '../../../services/realtime/realtime_update_service.dart';

class CertificateStepperScreen extends StatefulWidget {
  final int? tripId;
  
  const CertificateStepperScreen({Key? key, this.tripId}) : super(key: key);

  @override
  State<CertificateStepperScreen> createState() => _CertificateStepperScreenState();
}

class _CertificateStepperScreenState extends State<CertificateStepperScreen> {
  bool _isLoading = true;
  int _currentStep = 0;
  Map<String, bool> _uploadedDocs = {
    'izinMelaut': false,
    'dokumenKapal': false,
    'asuransi': false,
  };

  @override
  void initState() {
    super.initState();
    _checkUploadedDocuments();
  }

  Future<void> _checkUploadedDocuments() async {
    if (widget.tripId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      print('\n========== CHECK UPLOADED DOCUMENTS START ==========');
      print('🔍 Trip ID: ${widget.tripId}');
      
      final response = await TripService.getTripDocuments(widget.tripId!);
      print('📦 Response: $response');
      
      if (response['success'] == true && response['data'] != null) {
        final docs = response['data']['documents'] as Map<String, dynamic>?;
        if (docs != null) {
          setState(() {
            _uploadedDocs['izinMelaut'] = docs['izinMelaut'] == true;
            _uploadedDocs['dokumenKapal'] = docs['dokumenKapal'] == true;
            _uploadedDocs['asuransi'] = docs['asuransi'] == true;
          });
          
          print('✅ Izin Melaut: ${_uploadedDocs['izinMelaut']}');
          print('✅ Dokumen Kapal: ${_uploadedDocs['dokumenKapal']}');
          print('✅ Asuransi: ${_uploadedDocs['asuransi']}');
          
          if (_uploadedDocs.values.every((uploaded) => uploaded)) {
            print('✅ All documents uploaded!');
            _showAllDocumentsUploadedDialog();
            return;
          }
        }
      }
      
      print('========== CHECK UPLOADED DOCUMENTS END ==========\n');
      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error checking documents: $e');
      print('========== CHECK UPLOADED DOCUMENTS END (ERROR) ==========\n');
      setState(() => _isLoading = false);
    }
  }

  void _showAllDocumentsUploadedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Dokumen Lengkap'),
            ],
          ),
          content: Text(
            'Semua dokumen perizinan sudah diupload.\n\nStatus trip: Menunggu persetujuan admin.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  void _onStepContinue() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _onUploadSuccess(String docType) {
    print('\n🎉 [Upload Success] Document $docType uploaded!');
    setState(() {
      _uploadedDocs[docType] = true;
    });
    
    if (_uploadedDocs.values.every((uploaded) => uploaded)) {
      print('✅ All documents complete!');
      RealtimeUpdateService.notifyListeners('trip');
      _showAllDocumentsUploadedDialog();
    } else {
      _onStepContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
          'Upload Dokumen Perizinan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (context, details) => SizedBox.shrink(),
        steps: [
          Step(
            title: Text('Surat Izin Melaut'),
            subtitle: _uploadedDocs['izinMelaut']! 
                ? Text('✅ Sudah diupload', style: TextStyle(color: Colors.green))
                : null,
            content: StepSuratIzinBerlayar(
              tripId: widget.tripId,
              onNext: () => _onUploadSuccess('izinMelaut'),
            ),
            isActive: _currentStep >= 0,
            state: _uploadedDocs['izinMelaut']! 
                ? StepState.complete 
                : _currentStep == 0 
                    ? StepState.editing 
                    : StepState.indexed,
          ),
          Step(
            title: Text('Dokumen Kapal'),
            subtitle: _uploadedDocs['dokumenKapal']! 
                ? Text('✅ Sudah diupload', style: TextStyle(color: Colors.green))
                : null,
            content: StepDokumenKapal(
              tripId: widget.tripId,
              onNext: () => _onUploadSuccess('dokumenKapal'),
            ),
            isActive: _currentStep >= 1,
            state: _uploadedDocs['dokumenKapal']! 
                ? StepState.complete 
                : _currentStep == 1 
                    ? StepState.editing 
                    : StepState.indexed,
          ),
          Step(
            title: Text('Asuransi Kapal'),
            subtitle: _uploadedDocs['asuransi']! 
                ? Text('✅ Sudah diupload', style: TextStyle(color: Colors.green))
                : null,
            content: StepAsuransiKapal(
              onNext: () => _onUploadSuccess('asuransi'),
            ),
            isActive: _currentStep >= 2,
            state: _uploadedDocs['asuransi']! 
                ? StepState.complete 
                : _currentStep == 2 
                    ? StepState.editing 
                    : StepState.indexed,
          ),
        ],
      ),
    );
  }
}
