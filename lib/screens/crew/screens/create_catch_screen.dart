import 'dart:async';
import 'dart:io';
import 'package:e_logbook/models/catch_model.dart';
import 'package:e_logbook/provider/catch_provider.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/services/local/catch_submission_service.dart';
import 'package:e_logbook/services/ai/gemini_fish_detection_service.dart';
import 'package:e_logbook/widgets/ai_detection_loading_widget.dart';
import 'package:e_logbook/widgets/ai_detection_result_widget.dart';
import 'package:e_logbook/widgets/image_picker.dart';
import 'package:e_logbook/widgets/section_title.dart';
import 'package:e_logbook/widgets/vessel_info_display.dart';
import 'package:e_logbook/widgets/sync_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class CreateCatchScreen extends StatefulWidget {
  const CreateCatchScreen({super.key});

  @override
  State<CreateCatchScreen> createState() => _CreateCatchScreenState();
}

class _CreateCatchScreenState extends State<CreateCatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Controllers
  final _fishNameController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  final _waterDepthController = TextEditingController();
  final _fuelCostController = TextEditingController();
  final _operationalCostController = TextEditingController();
  final _taxController = TextEditingController();
  final _fishingGearController = TextEditingController();
  final _notesController = TextEditingController();
  final _harborController = TextEditingController();
  final _estimatedLengthController = TextEditingController();
  final _estimatedHeightController = TextEditingController();
  final _unitWeightController = TextEditingController();

  // State variables
  final List<XFile> _catchImages = [];
  DateTime _departureDate = DateTime.now();
  TimeOfDay _departureTime = TimeOfDay.now();
  DateTime _arrivalDate = DateTime.now();
  TimeOfDay _arrivalTime = TimeOfDay.now();
  int _calculatedHours = 0;
  int _calculatedMinutes = 0;

  String _selectedCondition = '';
  String _selectedFishType = '';
  String _selectedWeatherCondition = 'Cerah';

  // AI Detection
  bool _isDetectingFish = false;
  FishDetectionResult? _detectionResult;
  bool _showDetectionResult = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _fishNameController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _waterDepthController.dispose();
    _fuelCostController.dispose();
    _operationalCostController.dispose();
    _taxController.dispose();
    _fishingGearController.dispose();
    _notesController.dispose();
    _harborController.dispose();
    _estimatedLengthController.dispose();
    _estimatedHeightController.dispose();
    _unitWeightController.dispose();
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }





  // ==================== TRIP CALCULATIONS ====================
  void _calculateTax() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final tax = weight * 1000; // Contoh: Rp 1000 per kg

    setState(() {
      _taxController.text = tax.toStringAsFixed(0);
    });
  }

  // ==================== AI DETECTION ====================
  Future<void> _detectFishFromImage(XFile imageFile) async {
    debugPrint('🔍 Starting AI detection for: ${imageFile.path}');

    safeSetState(() {
      _isDetectingFish = true;
      _showDetectionResult = false;
      _detectionResult = null;
    });

    try {
      debugPrint('📡 Calling Gemini AI...');
      final result = await GeminiFishDetectionService.detectFish(
        File(imageFile.path),
      ).timeout(Duration(seconds: 120));

      debugPrint('✅ AI detection successful: ${result.fishName}');

      if (mounted) {
        safeSetState(() {
          _detectionResult = result;
          _isDetectingFish = false;
          _showDetectionResult = true;
        });

        // Show success message
        _showSnackBar('🎉 AI berhasil mendeteksi ikan! Periksa hasil deteksi.');
      }
    } catch (e) {
      debugPrint('❌ AI detection failed: $e');

      if (mounted) {
        safeSetState(() => _isDetectingFish = false);
        // Hanya tampilkan pesan singkat, tidak perlu error detail
        _showSnackBar('⚠️ Deteksi AI tidak berhasil. Silakan isi data manual.');
      }
    }
  }

  void _acceptDetectionResult() {
    if (_detectionResult == null) return;

    safeSetState(() {
      // Auto fill form dengan hasil AI
      _fishNameController.text = _detectionResult!.fishName;
      _selectedFishType = _detectionResult!.fishType;
      _selectedCondition = _detectionResult!.condition;
      _unitWeightController.text = _detectionResult!.unitWeight.toStringAsFixed(2);
      _weightController.text = _detectionResult!.estimatedWeight.toString();
      _quantityController.text = _detectionResult!.estimatedQuantity.toString();
      _estimatedLengthController.text = _detectionResult!.estimatedLength
          .toString();
      _estimatedHeightController.text = _detectionResult!.estimatedHeight
          .toString();

      _showDetectionResult = false;
    });

    // Auto calculate tax
    _calculateTax();

    _showSnackBar('✅ Data AI berhasil diterapkan!');
  }

  void _retryDetection() {
    if (_catchImages.isNotEmpty) {
      _detectFishFromImage(_catchImages.first);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source != ImageSource.camera) {
      _showSnackBar('⚠️ Hanya kamera yang diizinkan untuk deteksi AI ikan!');
      return;
    }

    // OPTIMAL settings untuk AI detection
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85, // ✅ OPTIMAL: Balance quality & size
      maxWidth: 1920, // ✅ OPTIMAL: Full HD sufficient
      maxHeight: 1920, // ✅ OPTIMAL: Full HD sufficient
      preferredCameraDevice: CameraDevice.rear,
    );

    if (pickedFile != null) {
      // Optional: Show file size for debugging
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

      debugPrint('📸 Image captured: ${fileSizeMB}MB');

      setState(() => _catchImages.add(pickedFile));

      _showSnackBar('📸 Foto HD berhasil diambil! Memulai AI detection...');
      await _detectFishFromImage(pickedFile);
    }
  }

  void _removeImage(int index) {
    setState(() => _catchImages.removeAt(index));
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==================== VALIDATION ====================
  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('⚠️ Mohon lengkapi semua field yang wajib diisi!');
      return false;
    }

    if (_fishNameController.text.trim().isEmpty) {
      _showSnackBar('⚠️ Nama ikan harus diisi!');
      return false;
    }

    if (_weightController.text.trim().isEmpty ||
        (double.tryParse(_weightController.text) ?? 0) <= 0) {
      _showSnackBar('⚠️ Berat ikan harus diisi dan lebih dari 0!');
      return false;
    }

    if (_priceController.text.trim().isEmpty ||
        (double.tryParse(_priceController.text) ?? 0) <= 0) {
      _showSnackBar('⚠️ Harga per kg harus diisi dan lebih dari 0!');
      return false;
    }

    if (_catchImages.isEmpty) {
      _showSnackBar('⚠️ Minimal upload 1 foto tangkapan ikan!');
      return false;
    }

    if (_calculatedHours == 0 && _calculatedMinutes == 0) {
      _showSnackBar('⚠️ Silakan atur waktu keberangkatan & kedatangan!');
      return false;
    }

    if (_fishingGearController.text.trim().isEmpty) {
      _showSnackBar('⚠️ Alat tangkap harus diisi!');
      return false;
    }

    return true;
  }

  // ==================== SAVE CATCH ====================
  void _saveCatch() async {
    if (!_validateForm()) return;

    // Get vessel info from UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user?.vesselName == null) {
      _showSnackBar(
        '⚠️ Silakan atur informasi kapal di profil terlebih dahulu!',
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Mengirim data...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Hitung nilai
      final weight = double.tryParse(_weightController.text) ?? 0;
      final totalRevenue = 0; // Tidak ada harga per kg lagi
      final fuelCost = double.tryParse(_fuelCostController.text) ?? 0;
      final operationalCost =
          double.tryParse(_operationalCostController.text) ?? 0;
      final tax = double.tryParse(_taxController.text) ?? 0;
      final totalCost = fuelCost + operationalCost + tax;
      final netProfit = totalRevenue - totalCost;

      // Buat data catch untuk submission dengan ID unik
      final catchId = DateTime.now().millisecondsSinceEpoch.toString();
      final catchData = {
        'id': catchId, // ID unik untuk tracking
        'fishName': _fishNameController.text,
        'fishType': _selectedFishType,
        'weight': weight,
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'condition': _selectedCondition,
        'vesselName': user!.vesselName!,
        'vesselNumber': user.vesselNumber!,
        'captainName': user.captainName!,
        'crewCount': user.crewCount!,
        'pricePerKg': 0,
        'totalRevenue': 0,
        'departureDate': _departureDate.toIso8601String(),
        'departureTime': _departureTime.format(context),
        'arrivalDate': _arrivalDate.toIso8601String(),
        'arrivalTime': _arrivalTime.format(context),
        'tripDurationHours': _calculatedHours,
        'tripDurationMinutes': _calculatedMinutes,
        'fishingZone': 'N/A',
        'locationName': 'N/A',
        'latitude': 0.0,
        'longitude': 0.0,
        'waterDepth': double.tryParse(_waterDepthController.text) ?? 0,
        'weatherCondition': _selectedWeatherCondition,
        'fuelCost': fuelCost,
        'operationalCost': operationalCost,
        'tax': tax,
        'totalCost': totalCost,
        'netProfit': netProfit,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Submit dengan offline fallback
      final result = await CatchSubmissionService.submitCatch(
        catchData: catchData,
        imageFile: File(_catchImages[0].path),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show result
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.isOffline ? Colors.orange : Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Update provider dengan status sync
      if (result.success && mounted) {
        final newCatch = CatchModel(
          id: int.tryParse(catchId),
          fishName: _fishNameController.text,
          fishType: _selectedFishType,
          weight: weight,
          quantity: int.tryParse(_quantityController.text) ?? 0,
          condition: _selectedCondition,
          photoPath: _catchImages[0].path,
          vesselName: user.vesselName!,
          vesselNumber: user.vesselNumber!,
          captainName: user.captainName!,
          crewCount: user.crewCount!,
          pricePerKg: 0,
          totalRevenue: 0,
          departureDate: _departureDate,
          departureTime: _departureTime.format(context),
          arrivalDate: _arrivalDate,
          arrivalTime: _arrivalTime.format(context),
          tripDurationHours: _calculatedHours,
          tripDurationMinutes: _calculatedMinutes,
          fishingZone: 'N/A',
          locationName: 'N/A',
          latitude: 0.0,
          longitude: 0.0,
          waterDepth: double.tryParse(_waterDepthController.text) ?? 0,
          weatherCondition: _selectedWeatherCondition,
          fuelCost: fuelCost,
          operationalCost: operationalCost,
          tax: tax,
          totalCost: totalCost,
          netProfit: netProfit,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          syncStatus: result.isOffline ? 'pending' : 'synced',
          lastSyncAttempt: DateTime.now(),
        );

        Provider.of<CatchProvider>(context, listen: false).addCatch(newCatch);
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Allow both Nahkoda and Crew to access catch management
        return _buildCreateCatchScreen(context);
      },
    );
  }

  Widget _buildCreateCatchScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;

    // Improved responsive scaling with constraints
    double fs(double size) =>
        (size * (width / 390)).clamp(size * 0.8, size * 1.2);
    double sp(double size) =>
        (size * (width / 390)).clamp(size * 0.8, size * 1.2);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Catat Tangkapan Baru',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: fs(18),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(sp(16)),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SYNC STATUS WIDGET
              SyncStatusWidget(),

              // INFORMASI KAPAL DARI PROFIL
              SectionTitle(
                title: 'Informasi Kapal',
                icon: Icons.directions_boat,
              ),
              SizedBox(height: sp(12)),
              _buildVesselInfoCard(sp, fs),

              SizedBox(height: sp(24)),

              // WAKTU KEBERANGKATAN & KEDATANGAN (Removed as per request)
              // SectionTitle(
              //   title: 'Waktu Keberangkatan & Kedatangan',
              //   icon: Icons.schedule,
              // ),
              // SizedBox(height: sp(12)),

              // _buildDepartureArrivalSection(sp, fs),
              SizedBox(height: sp(24)),

              // INFORMASI HASIL TANGKAPAN (AI DETECTION)
              Row(
                children: [
                  Image.asset(
                    'assets/icons/icon_ai.png',
                    width: fs(22),
                    height: fs(22),
                    color: Color(0xFF1B4F9C),
                  ),
                  SizedBox(width: sp(8)),
                  Expanded(
                    child: Text(
                      'Hasil Tangkapan Dengan AI Detection',
                      style: TextStyle(
                        fontSize: fs(18),
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4F9C),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: sp(12)),

              _buildFishInfoSection(sp),

              SizedBox(height: sp(24)),

              // FOTO TANGKAPAN & AI DETECTION
              Row(
                children: [
                  Icon(
                    Icons.camera_enhance,
                    color: Color(0xFF1B4F9C),
                    size: fs(22),
                  ),
                  SizedBox(width: sp(6)),
                  Expanded(
                    child: Text(
                      'Upload Foto Hasil Tangkapan',
                      style: TextStyle(
                        fontSize: fs(18),
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4F9C),
                      ),
                    ),
                  ),
                  SizedBox(width: sp(4)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: sp(6),
                      vertical: sp(3),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(sp(10)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icons/icon_ai.png',
                          width: 12,
                          height: 12,
                          color: Colors.blue.shade700,
                        ),
                        SizedBox(width: sp(3)),
                        Text(
                          'AI',
                          style: TextStyle(
                            fontSize: fs(9),
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: sp(12)),

              // AI Detection Loading
              if (_isDetectingFish) const AIDetectionLoadingWidget(),

              // AI Detection Result
              if (_showDetectionResult && _detectionResult != null)
                AIDetectionResultWidget(
                  result: _detectionResult!,
                  onAccept: _acceptDetectionResult,
                  onRetry: _retryDetection,
                ),

              // Image Picker
              ImagePickerWidget(
                images: _catchImages,
                onPickImage: _pickImage,
                onRemoveImage: _removeImage,
              ),

              // Manual AI Detection Button
              if (_catchImages.isNotEmpty &&
                  !_isDetectingFish &&
                  !_showDetectionResult)
                Padding(
                  padding: EdgeInsets.only(top: sp(12)),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _detectFishFromImage(_catchImages.first),
                      icon: Image.asset(
                        'assets/icons/icon_ai.png',
                        width: 16,
                        height: 16,
                      ),
                      label: const Text('Deteksi Ikan dengan AI'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade300),
                        padding: EdgeInsets.symmetric(vertical: sp(12)),
                      ),
                    ),
                  ),
                ),

              SizedBox(height: sp(24)),

              // _buildCostSection(sp, fs),
              SizedBox(height: sp(32)),

              // TOMBOL KIRIM
              SizedBox(
                width: double.infinity,
                height: sp(56),
                child: ElevatedButton.icon(
                  onPressed: _saveCatch,
                  icon: Icon(Icons.send_rounded, size: fs(20)),
                  label: Text(
                    'Kirim Data Tangkapan',
                    style: TextStyle(
                      fontSize: fs(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4F9C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(sp(16)),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
              SizedBox(height: sp(20)),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== BUILD WIDGETS ====================

  Widget _buildVesselInfoCard(
    double Function(double) sp,
    double Function(double) fs,
  ) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        // Jika data kapal belum ada, gunakan VesselInfoDisplay
        if (user?.vesselName == null) {
          return VesselInfoDisplay();
        }

        // Jika data kapal sudah ada, tampilkan card custom
        return Container(
          padding: EdgeInsets.all(sp(16)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1B4F9C).withOpacity(0.1),
                Color(0xFF2563EB).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(sp(12)),
            border: Border.all(color: Color(0xFF1B4F9C).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(sp(8)),
                    decoration: BoxDecoration(
                      color: Color(0xFF1B4F9C),
                      borderRadius: BorderRadius.circular(sp(8)),
                    ),
                    child: Icon(
                      Icons.directions_boat,
                      color: Colors.white,
                      size: fs(20),
                    ),
                  ),
                  SizedBox(width: sp(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user!.vesselName!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fs(16),
                            color: Color(0xFF1B4F9C),
                          ),
                        ),
                        Text(
                          'No. ${user.vesselNumber}',
                          style: TextStyle(
                            fontSize: fs(12),
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: sp(8),
                      vertical: sp(4),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(sp(12)),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[700],
                          size: fs(14),
                        ),
                        SizedBox(width: sp(4)),
                        Text(
                          'Aktif',
                          style: TextStyle(
                            fontSize: fs(11),
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: sp(16)),
              Divider(height: 1, color: Colors.grey[300]),
              SizedBox(height: sp(16)),

              // Info Grid
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.person_outline,
                      label: 'Nahkoda',
                      value: user.captainName!,
                      sp: sp,
                      fs: fs,
                    ),
                  ),
                  SizedBox(width: sp(16)),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.groups_outlined,
                      label: 'Jumlah ABK',
                      value: '${user.crewCount} orang',
                      sp: sp,
                      fs: fs,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required double Function(double) sp,
    required double Function(double) fs,
  }) {
    return Container(
      padding: EdgeInsets.all(sp(12)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(sp(8)),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: fs(16), color: Color(0xFF1B4F9C)),
              SizedBox(width: sp(6)),
              Text(
                label,
                style: TextStyle(
                  fontSize: fs(11),
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: sp(6)),
          Text(
            value,
            style: TextStyle(
              fontSize: fs(13),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFishInfoSection(double Function(double) sp) {
    return Column(
      children: [
        // Special Fish Name Field
        TextFormField(
          controller: _fishNameController,
          readOnly: true,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _fishNameController.text.isNotEmpty
                ? Colors.blue[800]
                : Colors.grey[600],
          ),
          decoration: InputDecoration(
            labelText: 'Nama Ikan (AI)',
            hintText: _fishNameController.text.isEmpty ? 'Nama Ikan' : null,
            prefixIcon: Icon(MdiIcons.fish, color: Colors.blue[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(sp(12)),
              borderSide: BorderSide(
                width: 2,
                color: _fishNameController.text.isNotEmpty
                    ? Colors.blue[600]!
                    : Colors.blue.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(sp(12)),
              borderSide: BorderSide(
                width: 2,
                color: _fishNameController.text.isNotEmpty
                    ? Colors.blue[600]!
                    : Colors.blue.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(sp(12)),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        SizedBox(height: sp(16)),

        // Jenis Ikan Field - Format seperti TextFormField
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: _selectedFishType.isNotEmpty ? 'Jenis Ikan' : null,
            hintText: _selectedFishType.isEmpty ? 'Jenis Ikan' : null,
            prefixIcon: Icon(Icons.category, color: Color(0xFF1B4F9C)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(sp(12)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(sp(12)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(sp(12)),
              borderSide: const BorderSide(color: Color(0xFF1B4F9C), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          controller: TextEditingController(text: _selectedFishType),
        ),

        SizedBox(height: sp(16)),

        // Kondisi Kesegaran Field - Format seperti TextFormField
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: _selectedCondition.isNotEmpty
                ? 'Kondisi Kesegaran'
                : null,
            hintText: _selectedCondition.isEmpty ? 'Kondisi Kesegaran' : null,
            prefixIcon: Icon(Icons.health_and_safety, color: Color(0xFF1B4F9C)),
            suffixIcon: _selectedCondition.isNotEmpty
                ? Container(
                    margin: EdgeInsets.all(sp(12)),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getConditionColor(),
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(sp(12)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(sp(12)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(sp(12)),
              borderSide: const BorderSide(color: Color(0xFF1B4F9C), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          controller: TextEditingController(text: _selectedCondition),
        ),

        SizedBox(height: sp(16)),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _unitWeightController,
                readOnly: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Berat Per Ikan (kg)',
                  hintText: '0.0',
                  prefixIcon: Icon(Icons.scale_rounded, color: Color(0xFF1B4F9C)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sp(12)),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sp(12)),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sp(12)),
                    borderSide: const BorderSide(color: Color(0xFF1B4F9C), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            SizedBox(width: sp(8)),
            Expanded(
              child: TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateTax(),
                decoration: InputDecoration(
                  labelText: 'Berat Total (kg)',
                  hintText: '0.0',
                  prefixIcon: Icon(Icons.scale_rounded, color: Color(0xFF1B4F9C)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sp(12)),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sp(12)),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sp(12)),
                    borderSide: const BorderSide(color: Color(0xFF1B4F9C), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: sp(16)),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _estimatedHeightController,
                readOnly: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tinggi Estimasi (cm)',
                  hintText: '0.0',
                  prefixIcon: Icon(Icons.height, color: Color(0xFF1B4F9C)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sp(12)),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sp(12)),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sp(12)),
                    borderSide: const BorderSide(color: Color(0xFF1B4F9C), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            SizedBox(width: sp(8)),
            Expanded(
              child: TextFormField(
                controller: _estimatedLengthController,
                readOnly: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Panjang Estimasi (cm)',
                  hintText: '0.0',
                  prefixIcon: Icon(Icons.straighten, color: Color(0xFF1B4F9C)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sp(12)),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sp(12)),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sp(12)),
                    borderSide: const BorderSide(color: Color(0xFF1B4F9C), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: sp(16)),
        TextFormField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Jumlah Ikan',
            hintText: '0',
            prefixIcon: Icon(Icons.format_list_numbered, color: Color(0xFF1B4F9C)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(sp(12)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(sp(12)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(sp(12)),
              borderSide: const BorderSide(color: Color(0xFF1B4F9C), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Color _getConditionColor() {
    switch (_selectedCondition) {
      case 'Segar':
        return Colors.green;
      case 'Cukup Segar':
        return Colors.orange;
      case 'Kurang Segar':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
