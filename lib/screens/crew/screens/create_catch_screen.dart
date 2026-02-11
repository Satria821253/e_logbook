import 'dart:async';
import 'dart:io';
import 'package:e_logbook/models/catch_model.dart';
import 'package:e_logbook/provider/catch_provider.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/services/local/catch_submission_service.dart';
import 'package:e_logbook/services/ai/gemini_fish_detection_service.dart';
import 'package:e_logbook/services/api/trip_service.dart';
import 'package:e_logbook/widgets/ai_detection_loading_widget.dart';
import 'package:e_logbook/widgets/ai_detection_result_widget.dart';
import 'package:e_logbook/widgets/image_picker.dart';
import 'package:e_logbook/widgets/section_title.dart';
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
  final _quantityController = TextEditingController();

  final _waterDepthController = TextEditingController();
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

  // Trip Data
  Map<String, dynamic>? _tripData;
  bool _isLoadingTrip = true;

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  Future<void> _loadTripData() async {
    try {
      debugPrint('\n🚢 [CATCH_SCREEN] Loading trip data...');
      final result = await TripService.getMyTrips();
      
      if (result['success'] == true && result['data'] != null) {
        final trips = result['data'] as List;
        debugPrint('📊 [CATCH_SCREEN] Total trips: ${trips.length}');
        
        if (trips.isNotEmpty) {
          final trip = trips[0];
          debugPrint('🎯 [CATCH_SCREEN] Trip ID: ${trip['id']}');
          debugPrint('🆔 [CATCH_SCREEN] Kapal ID: ${trip['kapalId']}');
          debugPrint('👨✈️ [CATCH_SCREEN] Nahkoda ID: ${trip['nahkodaId']}');
          debugPrint('👥 [CATCH_SCREEN] Crew IDs: ${trip['awakKapal']}');
          
          // Fetch detail trip untuk mendapatkan data lengkap
          debugPrint('🔍 [CATCH_SCREEN] Fetching trip detail...');
          final detailResult = await TripService.getTripDetail(trip['id']);
          
          if (detailResult['success'] == true && detailResult['data'] != null) {
            final tripDetail = detailResult['data'];
            debugPrint('✅ [CATCH_SCREEN] Trip detail loaded');
            debugPrint('⚓ [CATCH_SCREEN] Vessel: ${tripDetail['kapal']?['namaKapal']}');
            debugPrint('👨✈️ [CATCH_SCREEN] Captain: ${tripDetail['nahkoda']?['nama']}');
            debugPrint('📅 [CATCH_SCREEN] Departure: ${tripDetail['tanggalBerangkat']}');
            debugPrint('📅 [CATCH_SCREEN] Return: ${tripDetail['estimasiPulang']}');
            
            safeSetState(() {
              _tripData = tripDetail;
              _isLoadingTrip = false;
              
              // Auto-fill waktu dari trip
              if (tripDetail['tanggalBerangkat'] != null) {
                try {
                  final departureDateTime = DateTime.parse(tripDetail['tanggalBerangkat']);
                  _departureDate = departureDateTime;
                  _departureTime = TimeOfDay(hour: departureDateTime.hour, minute: departureDateTime.minute);
                  debugPrint('✅ [CATCH_SCREEN] Auto-filled departure time:');
                  debugPrint('   Date: ${_departureDate.day}/${_departureDate.month}/${_departureDate.year}');
                  debugPrint('   Time: ${_departureTime.hour}:${_departureTime.minute}');
                } catch (e) {
                  debugPrint('❌ [CATCH_SCREEN] Failed to parse departure date: $e');
                }
              } else {
                debugPrint('⚠️ [CATCH_SCREEN] No departure date in trip data');
              }
              
              if (tripDetail['estimasiPulang'] != null) {
                try {
                  final returnDateTime = DateTime.parse(tripDetail['estimasiPulang']);
                  _arrivalDate = returnDateTime;
                  _arrivalTime = TimeOfDay(hour: returnDateTime.hour, minute: returnDateTime.minute);
                  debugPrint('✅ [CATCH_SCREEN] Auto-filled return time:');
                  debugPrint('   Date: ${_arrivalDate.day}/${_arrivalDate.month}/${_arrivalDate.year}');
                  debugPrint('   Time: ${_arrivalTime.hour}:${_arrivalTime.minute}');
                } catch (e) {
                  debugPrint('❌ [CATCH_SCREEN] Failed to parse return date: $e');
                }
              } else {
                debugPrint('⚠️ [CATCH_SCREEN] No return date in trip data');
              }
              
              // Calculate duration
              _calculateDuration();
              debugPrint('⏱️ [CATCH_SCREEN] Calculated duration: $_calculatedHours hours $_calculatedMinutes minutes');
            });
          } else {
            debugPrint('⚠️ [CATCH_SCREEN] Failed to load trip detail - will use UserProvider fallback');
            safeSetState(() => _isLoadingTrip = false);
          }
        } else {
          debugPrint('⚠️ [CATCH_SCREEN] No trips found - will use UserProvider fallback');
          safeSetState(() => _isLoadingTrip = false);
        }
      }
    } catch (e) {
      debugPrint('❌ [CATCH_SCREEN] Error: $e - will use UserProvider fallback');
      safeSetState(() => _isLoadingTrip = false);
    }
  }

  @override
  void dispose() {
    _fishNameController.dispose();
    _weightController.dispose();
    _quantityController.dispose();
    _waterDepthController.dispose();
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

      safeSetState(() => _catchImages.add(pickedFile));

      _showSnackBar('📸 Foto HD berhasil diambil! Memulai AI detection...');
      await _detectFishFromImage(pickedFile);
    }
  }

  void _removeImage(int index) {
    safeSetState(() => _catchImages.removeAt(index));
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

    String vesselName;
    String vesselNumber;
    String captainName;
    int crewCount;
    int kapalId;

    if (_tripData != null) {
      debugPrint('\n📦 [CATCH] Using trip data');
      final kapal = _tripData!['kapal'];
      final nahkoda = _tripData!['nahkoda'];
      final awakKapal = _tripData!['awakKapal'] as List?;
      
      vesselName = kapal['namaKapal'] ?? 'Unknown';
      vesselNumber = kapal['nomorRegistrasi'] ?? kapal['nomorKapal'] ?? 'Unknown';
      captainName = nahkoda['nama'] ?? 'Unknown';
      crewCount = awakKapal?.length ?? 0;
      kapalId = _tripData!['kapalId'] ?? 1;
    } else {
      debugPrint('\n⚠️ [CATCH] Using UserProvider fallback');
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      if (user?.vesselName == null) {
        _showSnackBar('⚠️ Silakan lengkapi data kapal di profil!');
        return;
      }
      
      vesselName = user!.vesselName!;
      vesselNumber = user.vesselNumber!;
      captainName = user.captainName!;
      crewCount = user.crewCount ?? 0;
      kapalId = 1;
    }
    
    debugPrint('⚓ [CATCH] Vessel: $vesselName');
    debugPrint('🆔 [CATCH] Kapal ID: $kapalId');
    debugPrint('👥 [CATCH] Crew: $crewCount');

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
      // Data mentah tangkapan (perhitungan di backend)
      final weight = double.tryParse(_weightController.text) ?? 0;

      // Buat data catch untuk submission (data mentah, perhitungan di backend)
      final catchId = DateTime.now().millisecondsSinceEpoch.toString();
      final catchData = {
        'id': catchId,
        'fish_name': _fishNameController.text,
        'fish_type': _selectedFishType,
        'weight': weight,
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'condition': _selectedCondition,
        'crew_count': crewCount,
        'departure_date': _departureDate.toIso8601String().split('T')[0],
        'departure_time': _departureTime.format(context),
        'arrival_date': _arrivalDate.toIso8601String().split('T')[0],
        'arrival_time': _arrivalTime.format(context),
        'trip_duration_hours': _calculatedHours,
        'trip_duration_minutes': _calculatedMinutes,
        'fishing_zone': _harborController.text.isEmpty ? 'WPP-NRI' : _harborController.text,
        'location_name': _fishingGearController.text.isEmpty ? 'Laut Jawa' : _fishingGearController.text,
        'latitude': 0.0, // TODO: Implement GPS
        'longitude': 0.0, // TODO: Implement GPS
        'water_depth': double.tryParse(_waterDepthController.text) ?? 0,
        'weather_condition': _selectedWeatherCondition,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'kapalId': kapalId,
        'tripId': _tripData?['id'], // Add tripId if available
        // Extra fields for local storage
        'vesselName': vesselName,
        'vesselNumber': vesselNumber,
        'captainName': captainName,
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
          vesselName: vesselName,
          vesselNumber: vesselNumber,
          captainName: captainName,
          crewCount: crewCount,
          pricePerKg: 0, // Dihitung di backend
          totalRevenue: 0, // Dihitung di backend
          departureDate: _departureDate,
          departureTime: _departureTime.format(context),
          arrivalDate: _arrivalDate,
          arrivalTime: _arrivalTime.format(context),
          tripDurationHours: _calculatedHours,
          tripDurationMinutes: _calculatedMinutes,
          fishingZone: _harborController.text.isEmpty ? 'WPP-NRI' : _harborController.text,
          locationName: _fishingGearController.text.isEmpty ? 'Laut Jawa' : _fishingGearController.text,
          latitude: 0.0,
          longitude: 0.0,
          waterDepth: double.tryParse(_waterDepthController.text) ?? 0,
          weatherCondition: _selectedWeatherCondition,
          fuelCost: 0, // Dihitung di backend
          operationalCost: 0, // Dihitung di backend
          tax: 0, // Dihitung di backend
          totalCost: 0, // Dihitung di backend
          netProfit: 0, // Dihitung di backend
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
    final isTablet = width >= 600;

    // Responsive scaling dengan batasan untuk tablet
    double fs(double size) {
      if (isTablet) {
        // Untuk tablet, gunakan scaling yang lebih konservatif
        return (size * (width / 768)).clamp(size * 0.9, size * 1.3);
      }
      // Untuk mobile
      return (size * (width / 390)).clamp(size * 0.8, size * 1.2);
    }
    
    double sp(double size) {
      if (isTablet) {
        // Untuk tablet, spacing lebih besar
        return (size * (width / 768)).clamp(size, size * 1.5);
      }
      // Untuk mobile
      return (size * (width / 390)).clamp(size * 0.8, size * 1.2);
    }

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

              // WAKTU KEBERANGKATAN & KEDATANGAN
              SectionTitle(
                title: 'Waktu Perjalanan',
                icon: Icons.schedule,
              ),
              SizedBox(height: sp(12)),
              _buildTripTimeSection(sp, fs),

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

              // LOKASI & CUACA
              SectionTitle(
                title: 'Lokasi & Kondisi',
                icon: Icons.location_on,
              ),
              SizedBox(height: sp(12)),
              _buildLocationWeatherSection(sp, fs),

              SizedBox(height: sp(24)),

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
    if (_isLoadingTrip) {
      return Container(
        padding: EdgeInsets.all(sp(16)),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(sp(12)),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: sp(12)),
              Text('Memuat data trip...', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    if (_tripData == null) {
      return Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;
          
          if (user?.vesselName == null) {
            return Container(
              padding: EdgeInsets.all(sp(16)),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(sp(12)),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700], size: fs(40)),
                  SizedBox(height: sp(12)),
                  Text('Data kapal belum lengkap', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold)),
                  SizedBox(height: sp(8)),
                  Text('Silakan lengkapi profil', style: TextStyle(color: Colors.orange[600], fontSize: fs(12))),
                ],
              ),
            );
          }
          
          return Container(
            padding: EdgeInsets.all(sp(16)),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(sp(12)),
              border: Border.all(color: Colors.blue[300]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    SizedBox(width: sp(8)),
                    Expanded(
                      child: Text(
                        'Menggunakan data profil (belum ada trip aktif)',
                        style: TextStyle(color: Colors.blue[700], fontSize: fs(12)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: sp(12)),
                _buildVesselCardContent(sp, fs,
                  vesselName: user!.vesselName!,
                  vesselNumber: user.vesselNumber!,
                  captainName: user.captainName!,
                  crewCount: user.crewCount!,
                ),
              ],
            ),
          );
        },
      );
    }

    final kapal = _tripData!['kapal'];
    final nahkoda = _tripData!['nahkoda'];
    final awakKapal = _tripData!['awakKapal'] as List?;

    return _buildVesselCardContent(sp, fs,
      vesselName: kapal['namaKapal'] ?? 'Unknown',
      vesselNumber: kapal['nomorRegistrasi'] ?? kapal['nomorKapal'] ?? 'Unknown',
      captainName: nahkoda['nama'] ?? 'Unknown',
      crewCount: awakKapal?.length ?? 0,
    );
  }

  Widget _buildVesselCardContent(
    double Function(double) sp,
    double Function(double) fs, {
    required String vesselName,
    required String vesselNumber,
    required String captainName,
    required int crewCount,
  }) {
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
                          vesselName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fs(16),
                            color: Color(0xFF1B4F9C),
                          ),
                        ),
                        Text(
                          'No. $vesselNumber',
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
                      value: captainName,
                      sp: sp,
                      fs: fs,
                    ),
                  ),
                  SizedBox(width: sp(16)),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.groups_outlined,
                      label: 'Jumlah ABK',
                      value: '$crewCount orang',
                      sp: sp,
                      fs: fs,
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  Widget _buildTripTimeSection(
    double Function(double) sp,
    double Function(double) fs,
  ) {
    return Container(
      padding: EdgeInsets.all(sp(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sp(12)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tanggal Berangkat',
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(sp(12)),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  child: Text(
                    '${_departureDate.day}/${_departureDate.month}/${_departureDate.year}',
                    style: TextStyle(fontSize: fs(14), color: Colors.grey[700]),
                  ),
                ),
              ),
              SizedBox(width: sp(8)),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _departureTime,
                    );
                    if (time != null) {
                      setState(() => _departureTime = time);
                      _calculateDuration();
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Jam Berangkat',
                      prefixIcon: Icon(Icons.access_time, color: Color(0xFF1B4F9C)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(sp(12)),
                      ),
                    ),
                    child: Text(
                      _departureTime.format(context),
                      style: TextStyle(fontSize: fs(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: sp(12)),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _arrivalDate,
                      firstDate: _departureDate,
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _arrivalDate = date);
                      _calculateDuration();
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tanggal Kembali',
                      prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF1B4F9C)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(sp(12)),
                      ),
                    ),
                    child: Text(
                      '${_arrivalDate.day}/${_arrivalDate.month}/${_arrivalDate.year}',
                      style: TextStyle(fontSize: fs(14)),
                    ),
                  ),
                ),
              ),
              SizedBox(width: sp(8)),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _arrivalTime,
                    );
                    if (time != null) {
                      setState(() => _arrivalTime = time);
                      _calculateDuration();
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Jam Kembali',
                      prefixIcon: Icon(Icons.access_time, color: Color(0xFF1B4F9C)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(sp(12)),
                      ),
                    ),
                    child: Text(
                      _arrivalTime.format(context),
                      style: TextStyle(fontSize: fs(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_calculatedHours > 0 || _calculatedMinutes > 0) ...[
            SizedBox(height: sp(12)),
            Container(
              padding: EdgeInsets.all(sp(12)),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(sp(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, color: Colors.blue[700], size: fs(18)),
                  SizedBox(width: sp(8)),
                  Text(
                    _calculatedHours >= 24
                        ? 'Durasi: ${(_calculatedHours / 24).floor()} hari ${_calculatedHours % 24} jam ${_calculatedMinutes} menit'
                        : 'Durasi: $_calculatedHours jam $_calculatedMinutes menit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                      fontSize: fs(14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _calculateDuration() {
    final departure = DateTime(
      _departureDate.year,
      _departureDate.month,
      _departureDate.day,
      _departureTime.hour,
      _departureTime.minute,
    );
    final arrival = DateTime(
      _arrivalDate.year,
      _arrivalDate.month,
      _arrivalDate.day,
      _arrivalTime.hour,
      _arrivalTime.minute,
    );
    final duration = arrival.difference(departure);
    setState(() {
      _calculatedHours = duration.inHours;
      _calculatedMinutes = duration.inMinutes.remainder(60);
    });
  }

  Widget _buildLocationWeatherSection(
    double Function(double) sp,
    double Function(double) fs,
  ) {
    return Container(
      padding: EdgeInsets.all(sp(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sp(12)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _harborController,
            decoration: InputDecoration(
              labelText: 'Zona Penangkapan',
              hintText: 'Contoh: WPP 711',
              prefixIcon: Icon(Icons.waves, color: Color(0xFF1B4F9C)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sp(12)),
              ),
            ),
          ),
          SizedBox(height: sp(12)),
          TextFormField(
            controller: _fishingGearController,
            decoration: InputDecoration(
              labelText: 'Nama Lokasi',
              hintText: 'Contoh: Laut Jawa',
              prefixIcon: Icon(Icons.location_on, color: Color(0xFF1B4F9C)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sp(12)),
              ),
            ),
          ),
          SizedBox(height: sp(12)),
          TextFormField(
            controller: _waterDepthController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Kedalaman Air (meter)',
              hintText: '0.0',
              prefixIcon: Icon(Icons.water, color: Color(0xFF1B4F9C)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sp(12)),
              ),
            ),
          ),
          SizedBox(height: sp(12)),
          DropdownButtonFormField<String>(
            value: _selectedWeatherCondition,
            decoration: InputDecoration(
              labelText: 'Kondisi Cuaca',
              prefixIcon: Icon(Icons.wb_sunny, color: Color(0xFF1B4F9C)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sp(12)),
              ),
            ),
            items: ['Cerah', 'Berawan', 'Hujan', 'Badai']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedWeatherCondition = value);
            },
          ),
          SizedBox(height: sp(12)),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Catatan (Opsional)',
              hintText: 'Tambahkan catatan...',
              prefixIcon: Icon(Icons.note, color: Color(0xFF1B4F9C)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sp(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
