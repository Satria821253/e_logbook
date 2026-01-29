import 'package:flutter/material.dart';
import 'step_sertifikat_jalan.dart';
import 'step_surat_izin_berlayar.dart';
import 'step_asuransi_kapal.dart';
import 'step_sertifikat_kelayakan.dart';
import '../../../services/api/vessel_service.dart';
import '../../../services/realtime/realtime_update_service.dart';

class CertificateStepperScreen extends StatefulWidget {
  const CertificateStepperScreen({Key? key}) : super(key: key);

  @override
  State<CertificateStepperScreen> createState() => _CertificateStepperScreenState();
}

class _CertificateStepperScreenState extends State<CertificateStepperScreen> {
  int _currentStep = 0;
  final int _totalSteps = 4;
  PageController? _pageController;
  Set<int> _uploadedSteps = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUploadedCertificates();
  }

  Future<void> _loadUploadedCertificates() async {
    try {
      final vesselDocs = await VesselService().getVesselDocuments();
      final sertifikatJalan = vesselDocs['sertifikatJalan'] as List? ?? [];
      
      if (sertifikatJalan.isNotEmpty) {
        _showAlreadyUploadedDialog();
        return;
      }

      _pageController = PageController();
      _pageController?.addListener(() {
        int newStep = _pageController?.page?.round() ?? 0;
        if (newStep != _currentStep) {
          setState(() => _currentStep = newStep);
        }
      });

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error loading certificates: $e');
      _pageController = PageController();
      setState(() => _isLoading = false);
    }
  }

  void _showAlreadyUploadedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue, size: 28),
              SizedBox(width: 12),
              Text('Sudah Upload'),
            ],
          ),
          content: Text('Anda sudah mengupload sertifikat untuk trip ini.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  void _goToNextStep() async {
    setState(() => _uploadedSteps.add(_currentStep));
    
    RealtimeUpdateService.notifyListeners('vessel');

    if (_currentStep < _totalSteps - 1) {
      _pageController?.animateToPage(
        _currentStep + 1,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
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
          'Upload Sertifikat Kapal',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                StepSertifikatJalan(onNext: _goToNextStep),
                StepSuratIzinBerlayar(onNext: _goToNextStep),
                StepAsuransiKapal(onNext: _goToNextStep),
                StepSertifikatKelayakan(onNext: _goToNextStep),
              ],
            ),
          ),
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_totalSteps, (index) {
            bool isActive = index == _currentStep;
            bool isCompleted = _uploadedSteps.contains(index);
            
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: isActive ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  gradient: isCompleted || isActive
                      ? LinearGradient(
                          colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                        )
                      : null,
                  color: !isCompleted && !isActive ? Colors.grey[300] : null,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
