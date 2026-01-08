import 'dart:async';
import 'dart:io';
import 'package:e_logbook/models/catch_model.dart';
import 'package:e_logbook/provider/catch_provider.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/screens/map_piker_screen.dart';
import 'package:e_logbook/services/catch_submission_service.dart';
import 'package:e_logbook/services/gemini_fish_detection_service.dart';
import 'package:e_logbook/services/harbor_service.dart';
import 'package:e_logbook/services/weather_service.dart';
import 'package:e_logbook/widgets/ai_detection_loading_widget.dart';
import 'package:e_logbook/widgets/ai_detection_result_widget.dart';
import 'package:e_logbook/widgets/custom_text_field.dart';
import 'package:e_logbook/widgets/date_time_picker.dart';
import 'package:e_logbook/widgets/image_picker.dart';
import 'package:e_logbook/widgets/location_picker.dart';
import 'package:e_logbook/widgets/section_title.dart';
import 'package:e_logbook/widgets/vessel_info_display.dart';
import 'package:e_logbook/widgets/sync_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final _locationController = TextEditingController();
  final _waterDepthController = TextEditingController();
  final _fuelCostController = TextEditingController();
  final _operationalCostController = TextEditingController();
  final _taxController = TextEditingController();
  final _fishingGearController = TextEditingController();
  final _notesController = TextEditingController();
  final _harborController = TextEditingController();
  final _estimatedLengthController = TextEditingController();
  final _estimatedHeightController = TextEditingController();

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

  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  // Harbor search
  String? _selectedHarborName;
  Map<String, dynamic>? _selectedHarborCoords;
  bool _isLoadingHarbors = false;
  List<Map<String, dynamic>> _harborSuggestions = [];
  Timer? _debounce;
  Position? _currentPosition;

  // Weather
  WeatherData? _weatherData;
  bool _isLoadingWeather = false;

  // AI Detection
  bool _isDetectingFish = false;
  FishDetectionResult? _detectionResult;
  bool _showDetectionResult = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _fishNameController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _waterDepthController.dispose();
    _fuelCostController.dispose();
    _operationalCostController.dispose();
    _taxController.dispose();
    _fishingGearController.dispose();
    _notesController.dispose();
    _harborController.dispose();
    _estimatedLengthController.dispose();
    _estimatedHeightController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  // ==================== HARBOR SEARCH ====================
  Future<void> _searchHarbors(String query) async {
    if (query.isEmpty || query.length < 3) {
      safeSetState(() => _harborSuggestions = []);
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      safeSetState(() => _isLoadingHarbors = true);
      await _performHarborSearch(query);
    });
  }

  Future<void> _performHarborSearch(String query) async {
    try {
      final results = await HarborSearchService.searchHarbors(query);

      if (!mounted) return;

      // Tambahkan jarak jika ada posisi saat ini
      if (_currentPosition != null) {
        for (var harbor in results) {
          harbor['distance'] = HarborSearchService.calculateDistance(
            fromLat: _currentPosition!.latitude,
            fromLng: _currentPosition!.longitude,
            toLat: harbor['lat'],
            toLng: harbor['lng'],
          );
        }

        // Sort by distance
        results.sort(
          (a, b) =>
              (a['distance'] as double).compareTo(b['distance'] as double),
        );
      }

      safeSetState(() {
        _harborSuggestions = results;
        _isLoadingHarbors = false;
      });
    } catch (e) {
      safeSetState(() => _isLoadingHarbors = false);
      if (mounted) _showSnackBar('Gagal mencari pelabuhan: $e');
    }
  }

  double _calculateDistanceFromCoords() {
    if (_currentPosition == null || _selectedHarborCoords == null) return 0;
    return HarborSearchService.calculateDistance(
      fromLat: _currentPosition!.latitude,
      fromLng: _currentPosition!.longitude,
      toLat: _selectedHarborCoords!['lat'],
      toLng: _selectedHarborCoords!['lng'],
    );
  }

  // ==================== WEATHER ====================
  Future<void> _updateWeather() async {
    if (_latitude == null || _longitude == null) return;

    safeSetState(() => _isLoadingWeather = true);

    try {
      final weather = await WeatherService.getWeatherByCoordinates(
        lat: _latitude!,
        lon: _longitude!,
      );

      if (weather != null) {
        safeSetState(() {
          _weatherData = weather;
          _selectedWeatherCondition = _getWeatherConditionIndonesian(
            weather.condition,
          );
          _isLoadingWeather = false;
        });

        // Cek keamanan cuaca
        if (!WeatherService.isWeatherSafe(weather)) {
          _showWeatherWarningDialog(weather);
        }
      } else {
        safeSetState(() => _isLoadingWeather = false);
        _showSnackBar('⚠️ Tidak dapat mengambil data cuaca');
      }
    } catch (e) {
      safeSetState(() => _isLoadingWeather = false);
      _showSnackBar('Gagal mengambil data cuaca: $e');
    }
  }

  String _getWeatherConditionIndonesian(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('clear') || lower.contains('cerah')) return 'Cerah';
    if (lower.contains('cloud') || lower.contains('berawan')) return 'Berawan';
    if (lower.contains('rain') || lower.contains('hujan')) {
      if (lower.contains('light') || lower.contains('ringan'))
        return 'Hujan Ringan';
      if (lower.contains('heavy') || lower.contains('lebat'))
        return 'Hujan Lebat';
      return 'Hujan Ringan';
    }
    if (lower.contains('storm') || lower.contains('badai')) return 'Badai';
    return 'Berawan';
  }

  void _showWeatherWarningDialog(WeatherData weather) {
    final warningLevel = WeatherService.getWeatherWarningLevel(weather);
    Color warningColor = Colors.orange;

    if (warningLevel == 'BERBAHAYA') {
      warningColor = Colors.red;
    } else if (warningLevel == 'WASPADA') {
      warningColor = Colors.orange;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: warningColor),
            SizedBox(width: 8),
            Text('Peringatan Cuaca'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: warningColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LEVEL: $warningLevel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: warningColor,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Kondisi: ${weather.condition}'),
                  Text('Suhu: ${weather.temperature.toStringAsFixed(1)}°C'),
                  Text(
                    'Kecepatan Angin: ${weather.windSpeed.toStringAsFixed(1)} km/h',
                  ),
                  Text(
                    'Tinggi Ombak: ${weather.waveHeight.toStringAsFixed(1)} m',
                  ),
                  Text('Kelembaban: ${weather.humidity}%'),
                ],
              ),
            ),
            SizedBox(height: 12),
            if (warningLevel != 'AMAN')
              Text(
                '⚠️ Disarankan untuk menunda aktivitas melaut!',
                style: TextStyle(
                  color: warningColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  // ==================== LOCATION ====================
  Future<void> _getCurrentLocation() async {
    safeSetState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi tidak aktif. Silakan aktifkan GPS.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Izin lokasi ditolak permanen. Silakan aktifkan di pengaturan.',
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      _currentPosition = position;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        safeSetState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationController.text =
              "${place.subLocality ?? place.locality ?? 'Tidak diketahui'}, ${place.administrativeArea ?? ''}";
          _isLoadingLocation = false;
        });

        _showSnackBar('✅ Lokasi berhasil diambil!');

        // AUTO UPDATE WEATHER
        _updateWeather();
      }
    } catch (e) {
      safeSetState(() => _isLoadingLocation = false);
      _showSnackBar('Gagal mengambil lokasi: $e');
    }
  }

  Future<void> _pickLocationFromMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MapPickerScreen(initialLat: _latitude, initialLng: _longitude),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      safeSetState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _locationController.text = result['address'];
      });
      _showSnackBar('✅ Lokasi dipilih dari map!');

      // AUTO UPDATE WEATHER
      _updateWeather();
    }
  }

  Future<void> _openInGoogleMaps() async {
    if (_latitude == null || _longitude == null) return;

    final url =
        'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  // ==================== TRIP CALCULATIONS ====================
  void _calculateTripDuration() {
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

    // Validation removed as per request
    // if (duration.isNegative) {
    //   _showSnackBar('⚠️ Waktu kedatangan harus setelah keberangkatan!');
    //   return;
    // }

    setState(() {
      _calculatedHours = duration.inHours;
      _calculatedMinutes = duration.inMinutes.remainder(60);
    });
  }

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

    if (_selectedHarborName == null) {
      _showSnackBar('⚠️ Silakan pilih pelabuhan pangkalan!');
      return false;
    }

    if (_latitude == null || _longitude == null) {
      _showSnackBar('⚠️ Silakan tentukan lokasi penangkapan!');
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
        'fishingZone': _selectedHarborName!,
        'locationName': _locationController.text,
        'latitude': _latitude!,
        'longitude': _longitude!,
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
          fishingZone: _selectedHarborName!,
          locationName: _locationController.text,
          latitude: _latitude!,
          longitude: _longitude!,
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
              VesselInfoDisplay(),

              SizedBox(height: sp(24)),

              // WAKTU KEBERANGKATAN & KEDATANGAN (Removed as per request)
              // SectionTitle(
              //   title: 'Waktu Keberangkatan & Kedatangan',
              //   icon: Icons.schedule,
              // ),
              // SizedBox(height: sp(12)),

              // _buildDepartureArrivalSection(sp, fs),
              SizedBox(height: sp(24)),

              // PELABUHAN PANGKALAN
              SectionTitle(title: 'Pelabuhan Pangkalan', icon: Icons.anchor),
              SizedBox(height: sp(12)),

              _buildHarborSearchField(sp, fs),

              SizedBox(height: sp(24)),

              // LOKASI PENANGKAPAN
              SectionTitle(
                title: 'Lokasi Penangkapan',
                icon: Icons.location_on,
              ),
              SizedBox(height: sp(12)),

              LocationPickerWidget(
                locationController: _locationController,
                latitude: _latitude,
                longitude: _longitude,
                isLoading: _isLoadingLocation,
                onGetCurrentLocation: _getCurrentLocation,
                onPickFromMap: _pickLocationFromMap,
                onOpenInMaps: _openInGoogleMaps,
              ),

              SizedBox(height: sp(16)),

              // WEATHER INFO (Auto)
              if (_weatherData != null) _buildWeatherInfo(sp, fs),

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

  Widget _buildHarborSearchField(
    double Function(double) sp,
    double Function(double) fs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _harborController,
          decoration: InputDecoration(
            labelText: 'Cari Pelabuhan',
            hintText: 'Ketik nama pelabuhan...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF1B4F9C)),
            suffixIcon: _isLoadingHarbors
                ? Padding(
                    padding: EdgeInsets.all(sp(12)),
                    child: SizedBox(
                      width: sp(20),
                      height: sp(20),
                      child: const CircularProgressIndicator(strokeWidth: 2),
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
          onChanged: (value) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              _searchHarbors(value);
            });
          },
        ),

        // Selected Harbor
        if (_selectedHarborName != null) ...[
          SizedBox(height: sp(12)),
          Container(
            padding: EdgeInsets.all(sp(12)),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(sp(8)),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: sp(8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedHarborName!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fs(14),
                        ),
                      ),
                      if (_selectedHarborCoords != null &&
                          _currentPosition != null)
                        Text(
                          'Jarak: ${_calculateDistanceFromCoords().toStringAsFixed(2)} km',
                          style: TextStyle(
                            fontSize: fs(12),
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedHarborName = null;
                      _selectedHarborCoords = null;
                      _harborController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ],

        // Suggestions List
        if (_harborSuggestions.isNotEmpty && _selectedHarborName == null) ...[
          SizedBox(height: sp(8)),
          Container(
            constraints: BoxConstraints(maxHeight: sp(200)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(sp(12)),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _harborSuggestions.length,
              itemBuilder: (context, index) {
                final harbor = _harborSuggestions[index];
                final distance = harbor['distance'];
                return ListTile(
                  leading: const Icon(Icons.anchor, color: Color(0xFF1B4F9C)),
                  title: Text(
                    harbor['name'],
                    style: TextStyle(fontSize: fs(14)),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (harbor['fullAddress'] != null)
                        Text(
                          harbor['fullAddress'],
                          style: TextStyle(fontSize: fs(11)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (distance != null)
                        Text(
                          '${distance.toStringAsFixed(2)} km dari lokasi Anda',
                          style: TextStyle(
                            fontSize: fs(12),
                            color: const Color(0xFF1B4F9C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _selectedHarborName = harbor['name'];
                      _selectedHarborCoords = {
                        'lat': harbor['lat'],
                        'lng': harbor['lng'],
                      };
                      _harborController.text = harbor['name'];
                      _harborSuggestions = [];
                    });
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeatherInfo(
    double Function(double) sp,
    double Function(double) fs,
  ) {
    final warningLevel = WeatherService.getWeatherWarningLevel(_weatherData!);
    Color statusColor = Colors.green;

    if (warningLevel == 'BERBAHAYA') {
      statusColor = Colors.red;
    } else if (warningLevel == 'WASPADA') {
      statusColor = Colors.orange;
    }

    return Container(
      padding: EdgeInsets.all(sp(16)),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(sp(12)),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.wb_sunny, color: statusColor, size: fs(20)),
              SizedBox(width: sp(8)),
              Expanded(
                child: Text(
                  'Kondisi Cuaca',
                  style: TextStyle(
                    fontSize: fs(14),
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: sp(8),
                  vertical: sp(4),
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(sp(12)),
                ),
                child: Text(
                  warningLevel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fs(10),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: sp(16)),

          // Weather Grid
          Row(
            children: [
              Expanded(
                child: _buildWeatherCard(
                  '☁️',
                  '',
                  _weatherData!.condition,
                  fs,
                  sp,
                ),
              ),
              SizedBox(width: sp(8)),
              Expanded(
                child: _buildWeatherCard(
                  '🌡️',
                  'Suhu',
                  '${_weatherData!.temperature.toStringAsFixed(1)}°C',
                  fs,
                  sp,
                ),
              ),
            ],
          ),
          SizedBox(height: sp(8)),
          Row(
            children: [
              Expanded(
                child: _buildWeatherCard(
                  '💨',
                  'Angin',
                  '${_weatherData!.windSpeed.toStringAsFixed(1)} km/h',
                  fs,
                  sp,
                ),
              ),
              SizedBox(width: sp(8)),
              Expanded(
                child: _buildWeatherCard(
                  '🌊',
                  'Ombak',
                  '${_weatherData!.waveHeight.toStringAsFixed(1)}m',
                  fs,
                  sp,
                ),
              ),
            ],
          ),
          SizedBox(height: sp(8)),
          Row(
            children: [
              Expanded(
                child: _buildWeatherCard(
                  '💧',
                  'Kelembaban',
                  '${_weatherData!.humidity}%',
                  fs,
                  sp,
                ),
              ),
              SizedBox(width: sp(8)),
              Expanded(
                child: Container(), // Empty space for alignment
              ),
            ],
          ),

          if (_isLoadingWeather) ...[
            SizedBox(height: sp(12)),
            LinearProgressIndicator(
              color: statusColor,
              backgroundColor: statusColor.withOpacity(0.2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeatherCard(
    String emoji,
    String label,
    String value,
    double Function(double) fs,
    double Function(double) sp,
  ) {
    return Container(
      padding: EdgeInsets.all(sp(8)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(sp(8)),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: fs(16))),
          SizedBox(height: sp(4)),
          Text(
            label,
            style: TextStyle(
              fontSize: fs(10),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: sp(2)),
          Text(
            value,
            style: TextStyle(fontSize: fs(11), fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
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
              child: CustomTextField(
                controller: TextEditingController(
                  text: _detectionResult?.unitWeight.toStringAsFixed(2) ?? '',
                ),
                label: 'Berat Per Ikan (kg)',
                icon: Icons.scale_rounded,
                hint: '0.0',
                keyboardType: TextInputType.number,
                readOnly: true,
              ),
            ),
            SizedBox(width: sp(12)),
            Expanded(
              child: CustomTextField(
                controller: _weightController,
                label: 'Berat Total (kg)',
                icon: Icons.scale_rounded,
                hint: '0.0',
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateTax(),
              ),
            ),
          ],
        ),
        SizedBox(height: sp(16)),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _estimatedHeightController,
                label: 'Tinggi Estimasi (cm)',
                icon: Icons.height,
                hint: '0.0',
                keyboardType: TextInputType.number,
                readOnly: true,
              ),
            ),
            SizedBox(width: sp(12)),
            Expanded(
              child: CustomTextField(
                controller: _estimatedLengthController,
                label: 'Panjang Estimasi (cm)',
                icon: Icons.straighten,
                hint: '0.0',
                keyboardType: TextInputType.number,
                readOnly: true,
              ),
            ),
          ],
        ),
        SizedBox(height: sp(16)),
        CustomTextField(
          controller: _quantityController,
          label: 'Jumlah Ikan ',
          icon: Icons.format_list_numbered,
          hint: '0',
          keyboardType: TextInputType.number,
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
