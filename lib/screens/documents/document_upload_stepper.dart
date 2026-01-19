// lib/screens/document_upload/document_upload_stepper.dart

import 'package:flutter/material.dart';
import 'widgets/progress_indicator_widget.dart';
import 'pages/step_1_ktp.dart';
import 'pages/step_2_pas_foto.dart';
import 'pages/step_3_npwp.dart';
import 'pages/step_4_buku_pelaut.dart';
import 'pages/step_5_sertifikat_nahkoda.dart';
import 'pages/step_6_bst.dart';
import 'pages/step_7_surat_sehat.dart';
import 'pages/step_8_skck.dart';
import '../../services/getAPi/document_service.dart';

class DocumentUploadStepper extends StatefulWidget {
  final int initialStep;

  const DocumentUploadStepper({
    Key? key,
    this.initialStep = 1,
  }) : super(key: key);

  @override
  State<DocumentUploadStepper> createState() => _DocumentUploadStepperState();
}

class _DocumentUploadStepperState extends State<DocumentUploadStepper> {
  late int _currentStep;
  final int _totalSteps = 8;
  late PageController _pageController;
  Set<String> _uploadedDocs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _loadUploadedDocuments();
  }

  Future<void> _loadUploadedDocuments() async {
    try {
      final result = await DocumentService.getDocuments();
      
      if (result['success'] == true && result['documents'] != null) {
        final docs = result['documents'] as List;
        
        final uploadedTypes = <String>{};
        for (var doc in docs) {
          final jenis = doc['jenisDokumen'];
          if (jenis != null) {
            uploadedTypes.add(jenis.toString());
          }
        }
        
        _uploadedDocs = uploadedTypes;
        _currentStep = _findNextStep();
        
        _pageController = PageController(initialPage: _currentStep - 1);
        _pageController.addListener(() {
          int newStep = (_pageController.page?.round() ?? 0) + 1;
          if (newStep != _currentStep) {
            setState(() {
              _currentStep = newStep;
            });
          }
        });
        
        setState(() {
          _isLoading = false;
        });
      } else {
        _pageController = PageController();
        _pageController.addListener(() {
          int newStep = (_pageController.page?.round() ?? 0) + 1;
          if (newStep != _currentStep) {
            setState(() {
              _currentStep = newStep;
            });
          }
        });
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _pageController = PageController();
      _pageController.addListener(() {
        int newStep = (_pageController.page?.round() ?? 0) + 1;
        if (newStep != _currentStep) {
          setState(() {
            _currentStep = newStep;
          });
        }
      });
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _findNextStep() {
    final docTypes = ['KTP', 'Pas Foto', 'NPWP', 'Buku Pelaut', 'Sertifikat Nahkoda', 'BST', 'Surat Keterangan Sehat', 'SKCK'];
    for (int i = 0; i < docTypes.length; i++) {
      if (!_uploadedDocs.contains(docTypes[i])) {
        return i + 1;
      }
    }
    return 8;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    if (_currentStep < _totalSteps) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Upload Selesai!',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: const Text(
          'Semua dokumen berhasil diupload. Admin akan memverifikasi dokumen Anda.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close stepper
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Selesai',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Upload Dokumen',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Keluar?'),
                content: const Text(
                  'Dokumen yang sudah diupload akan tetap tersimpan. Lanjutkan keluar?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Step1KTP(onNext: _goToNextStep),
                Step2PasFoto(onNext: _goToNextStep),
                Step3NPWP(onNext: _goToNextStep),
                Step4BukuPelaut(onNext: _goToNextStep),
                Step5SertifikatNahkoda(onNext: _goToNextStep),
                Step6BST(onNext: _goToNextStep),
                Step7SuratSehat(onNext: _goToNextStep),
                Step8SKCK(onNext: _goToNextStep),
              ],
            ),
          ),
          ProgressIndicatorWidget(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
          ),
        ],
      ),
    );
  }
}