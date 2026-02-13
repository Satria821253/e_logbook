import 'package:e_logbook/screens/tracking/production_map.dart';
import 'package:e_logbook/screens/tracking/widgets/emergency_button.dart';
import 'package:e_logbook/screens/tracking/widgets/trip_statistics_card.dart';
import 'package:e_logbook/screens/tracking/widgets/vessel_header_card.dart';
import 'package:e_logbook/screens/tracking/widgets/wheater_detail_dialog.dart';
import 'package:e_logbook/screens/tracking/widgets/wheater_display_widget.dart';
import 'package:e_logbook/screens/tracking/widgets/zone_validation_dialog.dart';
import 'package:e_logbook/services/device/location_tracking_service.dart';
import 'package:e_logbook/services/device/foreground_tracking_service.dart';
import 'package:e_logbook/services/device/zone_checker.dart';
import 'package:e_logbook/services/realtime/realtime_service.dart';
import 'package:e_logbook/services/cuaca/weather_service.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:e_logbook/widgets/sos_alert_dialog.dart';
import 'package:e_logbook/widgets/tracking_minimized_overlay.dart';
import 'package:e_logbook/provider/tracking_minimize_provider.dart';
import 'package:e_logbook/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:e_logbook/utils/navigation_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class ActiveTrackingScreen extends StatefulWidget {
  final String vesselName;
  final String vesselNumber;
  final String captainName;
  final int crewCount;
  final String selectedHarbor;
  final DateTime departureTime;
  final DateTime? estimatedReturnDate; // ← BARU: Dari API estimasiPulang
  final int estimatedDuration;
  final String emergencyContact;
  final double fuelAmount;
  final double iceStorage;
  final String? notes;
  final Map<String, dynamic>? harborCoordinates;
  final double zoneRadius;
  final String userRole; // 'Nahkoda' or 'ABK'
  final String userName; // Nama user yang login

  const ActiveTrackingScreen({
    super.key,
    required this.vesselName,
    required this.vesselNumber,
    required this.captainName,
    required this.crewCount,
    required this.selectedHarbor,
    required this.departureTime,
    this.estimatedReturnDate, // ← BARU: Optional dari API
    required this.estimatedDuration,
    required this.emergencyContact,
    required this.fuelAmount,
    required this.iceStorage,
    this.notes,
    this.harborCoordinates,
    required this.zoneRadius,
    this.userRole = 'Nahkoda',
    this.userName = '',
  });

  @override
  State<ActiveTrackingScreen> createState() => _ActiveTrackingScreenState();
}

class _ActiveTrackingScreenState extends State<ActiveTrackingScreen> {
  // Zone tracking
  bool _isViolating = false;
  Position? _currentPosition;
  Map<String, dynamic>? _currentZoneInfo;
  String _zoneStatus = 'unknown';

  // Trip data
  Duration _tripDuration = Duration.zero;
  Timer? _durationTimer;

  // Fuel management
  double _remainingFuel = 0;
  bool _hasShownFuelWarning = false;
  static const double FUEL_CONSUMPTION_RATE = 8.0;

  // Alarm
  bool _isAlarmPlaying = false;

  // Weather data
  WeatherData? _weatherData;
  bool _isLoadingWeather = true;
  DateTime? _lastWeatherUpdate;
  Timer? _weatherTimer;
  
  // Provider reference
  TrackingMinimizeProvider? _minimizeProvider;

  @override
  void initState() {
    super.initState();
    print('\n🟢🟢🟢 [ActiveTracking] ========== INIT STATE CALLED ==========');
    print('🟢 [ActiveTracking] Widget is being CREATED/REBUILT from scratch');
    print('🟢 [ActiveTracking] This should ONLY appear ONCE when tracking starts');
    print('🟢 [ActiveTracking] If you see this again, it means REBUILD happened!');
    print('🟢🟢🟢 [ActiveTracking] ==========================================\n');
    
    ForegroundTrackingService.initForegroundTask();
    
    print('⛽ [ActiveTracking] ===== INIT DATA =====');
    print('⛽ [ActiveTracking] userRole: ${widget.userRole}');
    print('⛽ [ActiveTracking] userName: ${widget.userName}');
    print('⛽ [ActiveTracking] vesselName: ${widget.vesselName}');
    print('⛽ [ActiveTracking] selectedHarbor: ${widget.selectedHarbor}');
    print('⛽ [ActiveTracking] harborCoordinates: ${widget.harborCoordinates}');
    print('⛽ [ActiveTracking] zoneRadius: ${widget.zoneRadius} km');
    print('⛽ [ActiveTracking] fuelAmount: ${widget.fuelAmount}');
    print('⛽ [ActiveTracking] iceStorage: ${widget.iceStorage}');
    print('⛽ [ActiveTracking] ===== END INIT =====');
    
    _remainingFuel = widget.fuelAmount;
    _initializeTracking();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _minimizeProvider ??= Provider.of<TrackingMinimizeProvider>(context, listen: false);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _minimizeProvider?.startTracking(
        data: {
          'vesselName': widget.vesselName,
          'vesselNumber': widget.vesselNumber,
          'captainName': widget.captainName,
          'crewCount': widget.crewCount,
          'selectedHarbor': widget.selectedHarbor,
          'departureTime': widget.departureTime,
          'estimatedReturnDate': widget.estimatedReturnDate,
          'estimatedDuration': widget.estimatedDuration,
          'emergencyContact': widget.emergencyContact,
          'fuelAmount': widget.fuelAmount,
          'iceStorage': widget.iceStorage,
          'notes': widget.notes,
          'harborCoordinates': widget.harborCoordinates,
          'zoneRadius': widget.zoneRadius,
          'userRole': widget.userRole,
          'userName': widget.userName,
        },
      );
      _minimizeProvider?.maximize();
    });
  }

  @override
  void dispose() {
    print('🗑️ [ActiveTracking] dispose() called');
    
    // Cleanup UI resources only
    _durationTimer?.cancel();
    _weatherTimer?.cancel();
    _stopAlarm();
    RealTimeService.stopListening();
    
    // Tracking service continues in background
    print('🔵 [ActiveTracking] Tracking continues in background');
    
    super.dispose();
  }

  // ==================== INITIALIZATION ====================

  Future<void> _initializeTracking() async {
    await _validateAndStartTracking();
    _startDurationTimer();
    _startWeatherUpdates();
  }

  Future<void> _validateAndStartTracking() async {
    if (widget.harborCoordinates == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showError('Data koordinat pelabuhan tidak tersedia');
          Navigator.pop(context);
        }
      });
      return;
    }

    try {
      await LocationTrackingService.startTrackingWithCoordinates(
        harborLat: widget.harborCoordinates!['lat'],
        harborLng: widget.harborCoordinates!['lng'],
        harborName: widget.selectedHarbor,
        vesselName: widget.vesselName,
        zoneRadius: widget.zoneRadius,
        onViolationDetected: _handleViolation,
        onBackToSafeZone: _handleBackToSafe,
        onLocationUpdate: _handleLocationUpdate,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSuccess('Tracking dimulai - Selamat berlayar!');
        }
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showError('Gagal memulai tracking: $e');
          Navigator.pop(context);
        }
      });
    }
  }

  // ==================== WEATHER MANAGEMENT ====================

  void _startWeatherUpdates() {
    // Fetch weather pertama kali langsung ambil posisi current
    _fetchWeatherDataInitial();

    // Kemudian update tiap 5 menit
    _weatherTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _fetchWeatherData();
    });
  }

  Future<void> _fetchWeatherDataInitial() async {
    try {
      // Ambil posisi langsung tanpa tunggu tracking service
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final weather = await WeatherService.getWeatherByPosition(position);

      if (mounted) {
        setState(() {
          _weatherData = weather;
          _isLoadingWeather = false;
          _lastWeatherUpdate = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  Future<void> _fetchWeatherData() async {
    // Gunakan posisi dari tracking service jika ada, atau ambil posisi baru
    Position? position = _currentPosition;

    if (position == null) {
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingWeather = false;
          });
        }
        return;
      }
    }

    try {
      final weather = await WeatherService.getWeatherByPosition(position);

      if (mounted) {
        setState(() {
          _weatherData = weather;
          _isLoadingWeather = false;
          _lastWeatherUpdate = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  void _showWeatherDialog() {
    if (_weatherData == null) {
      _showInfo('Data cuaca belum tersedia');
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => WeatherDetailDialog(
        weatherData: _weatherData!,
        locationAddress: widget.selectedHarbor,
        lastUpdate: _lastWeatherUpdate ?? DateTime.now(),
        onRefresh: _fetchWeatherData,
      ),
    );
  }

  // ==================== TRIP DURATION & FUEL ====================

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _tripDuration = DateTime.now().difference(widget.departureTime);
        _updateFuelConsumption();
      });
    });
  }

  void _updateFuelConsumption() {
    if (_tripDuration.inHours > 0) {
      _remainingFuel =
          widget.fuelAmount - (FUEL_CONSUMPTION_RATE * _tripDuration.inHours);
      if (_remainingFuel < 0) _remainingFuel = 0;

      if (_shouldShowFuelWarning()) {
        _showFuelWarning();
      }
    }
  }

  bool _shouldShowFuelWarning() {
    return _remainingFuel < (widget.fuelAmount * 0.2) &&
        _remainingFuel > 0 &&
        !_hasShownFuelWarning;
  }

  void _showFuelWarning() {
    _hasShownFuelWarning = true;
    final percentage = (_remainingFuel / widget.fuelAmount * 100)
        .toStringAsFixed(0);
    _showWarning(
      'BBM Tinggal ${_remainingFuel.toStringAsFixed(1)} L ($percentage%)',
    );
  }

  // ==================== ZONE VIOLATION HANDLING ====================

  void _handleLocationUpdate(Position position, Map<String, dynamic> zoneInfo) {
    if (!mounted) return;

    setState(() {
      _currentPosition = position;
      _currentZoneInfo = zoneInfo;
      _zoneStatus = _calculateZoneStatus(position);
    });
    
    // Update provider untuk minimize view
    _minimizeProvider?.updatePosition(
      position,
      isViolating: _isViolating,
      zoneStatus: _zoneStatus,
    );
  }

  String _calculateZoneStatus(Position position) {
    if (widget.harborCoordinates == null) return 'unknown';

    final harborLat = widget.harborCoordinates!['lat'];
    final harborLng = widget.harborCoordinates!['lng'];

    // Hitung jarak dari posisi kapal ke pusat zona (dalam meter)
    final distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      harborLat,
      harborLng,
    );

    // Konversi radius zona dari km ke meter
    final zoneRadiusInMeters = widget.zoneRadius * 1000;

    // Debug logging
    print('🎯 [ZoneStatus] ===== ZONE CALCULATION =====');
    print('🎯 [ZoneStatus] User Role: ${widget.userRole}');
    print('🎯 [ZoneStatus] Harbor: ${widget.selectedHarbor}');
    print('🎯 [ZoneStatus] Harbor Coords: ($harborLat, $harborLng)');
    print('🎯 [ZoneStatus] Current Position: (${position.latitude}, ${position.longitude})');
    print('🎯 [ZoneStatus] Distance: ${(distanceInMeters / 1000).toStringAsFixed(2)} km');
    print('🎯 [ZoneStatus] Zone Radius: ${widget.zoneRadius} km');
    print('🎯 [ZoneStatus] Zone Radius (meters): $zoneRadiusInMeters m');

    // Untuk perjalanan laut 7 hari, gunakan threshold realistis:
    // - Dalam zona: ≤ radius zona
    // - Menuju zona: radius zona sampai 3x radius (area operasi normal)
    // - Melewati zona: > 3x radius (terlalu jauh dari zona tangkap)
    String status;
    if (distanceInMeters <= zoneRadiusInMeters) {
      status = 'inside'; // Dalam zona tangkap
    } else if (distanceInMeters <= zoneRadiusInMeters * 3) {
      status = 'approaching'; // Menuju zona / dalam perjalanan
    } else {
      status = 'outside'; // Melewati zona / terlalu jauh
    }
    
    print('🎯 [ZoneStatus] Calculated Status: $status');
    print('🎯 [ZoneStatus] =============================\n');
    
    return status;
  }

  Future<void> _handleViolation() async {
    if (!mounted) return;

    setState(() {
      _isViolating = true;
    });

    if (!_isAlarmPlaying) {
      await _startAlarm();
    }

    _showViolationDialog();
  }

  void _handleBackToSafe() {
    if (!mounted) return;

    setState(() {
      _isViolating = false;
    });

    _stopAlarm();
    _showSuccess('Kembali ke zona aman');
  }

  void _showViolationDialog() {
    if (_currentZoneInfo == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => ZoneViolationDialog(
        zoneInfo: _currentZoneInfo!,
        onViewDetail: () {
          NavigationHelper.pushNamedNoTransition(
            context,
            '/zone-violation-detail',
            arguments: {
              'zoneInfo': _currentZoneInfo!,
              'onDismiss': () {},
            },
          );
        },
      ),
    );
  }

  // ==================== ALARM MANAGEMENT ====================

  Future<void> _startAlarm() async {
    if (_isAlarmPlaying) return;
    _isAlarmPlaying = true;
    await ZoneCheckerService.triggerAlarm();
  }

  void _stopAlarm() {
    if (!_isAlarmPlaying) return;
    _isAlarmPlaying = false;
    ZoneCheckerService.stopAlarm();
  }

  // ==================== EMERGENCY HANDLING ====================

  void _handleEmergency() async {
    final success = await showSosAlertDialog(context);
    if (success == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('🚨 Sinyal Darurat Terkirim!'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ==================== NAVIGATION ====================

  void _navigateToCatchScreen() async {
    try {
      final result = await Navigator.pushNamed(
        context,
        '/create-catch',
      );

      // Jika berhasil submit tangkapan, tampilkan notifikasi
      if (result == true && mounted) {
        _showSuccess('Tangkapan berhasil dicatat!');
      }
    } catch (e) {
      if (mounted) {
        _showError('Gagal membuka form tangkapan: $e');
      }
    }
  }
  // ==================== UI HELPERS ====================

  void _showTripSummary() {
    // Hitung BBM terpakai berdasarkan konsumsi aktual
    final fuelConsumed = widget.fuelAmount - _remainingFuel;
    final fuelConsumedPercentage = widget.fuelAmount > 0 
        ? (fuelConsumed / widget.fuelAmount * 100).clamp(0, 100)
        : 0.0;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ringkasan Trip',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSummaryRow(
              Icons.access_time,
              'Durasi Trip',
              _formatDuration(_tripDuration),
            ),
            _buildSummaryRow(
              Icons.calendar_today,
              'Estimasi Durasi',
              '${widget.estimatedDuration} hari',
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              Icons.local_gas_station,
              'BBM Awal',
              widget.fuelAmount > 0 ? '${widget.fuelAmount.toStringAsFixed(1)} L' : 'Tidak ada data',
            ),
            _buildSummaryRow(
              Icons.local_gas_station,
              'BBM Tersisa',
              widget.fuelAmount > 0 
                  ? '${_remainingFuel.toStringAsFixed(1)} L (${((_remainingFuel / widget.fuelAmount * 100).clamp(0, 100)).toStringAsFixed(0)}%)'
                  : 'Tidak ada data',
            ),
            _buildSummaryRow(
              Icons.local_gas_station,
              'BBM Terpakai',
              widget.fuelAmount > 0 
                  ? '${fuelConsumed.toStringAsFixed(1)} L (${fuelConsumedPercentage.toStringAsFixed(0)}%)'
                  : 'Tidak ada data',
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              Icons.ac_unit,
              'Kapasitas Es',
              widget.iceStorage > 0 ? '${widget.iceStorage.toStringAsFixed(0)} Kg' : 'Tidak ada data',
            ),
            if (widget.notes != null) ...[
              const Divider(height: 24),
              _buildSummaryRow(Icons.note, 'Catatan', widget.notes!),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4F9C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1B4F9C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    if (days > 0) {
      return '${days}h ${hours}j ${minutes}m';
    }
    return '${hours}j ${minutes}m';
  }

  // ==================== NOTIFICATION HELPERS ====================

  void _showSuccess(String message) {
    _showNotification(message, Colors.green, Icons.check_circle);
  }

  void _showError(String message) {
    _showNotification(message, Colors.red, Icons.error);
  }

  void _showWarning(String message) {
    _showNotification(message, Colors.orange, Icons.warning);
  }

  void _showInfo(String message) {
    _showNotification(message, Colors.blue, Icons.info);
  }


  void _showNotification(String message, Color color, IconData icon) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    print('\n🔵 [ActiveTracking] build() called - isMinimized check');
    return Consumer<TrackingMinimizeProvider>(
      builder: (context, minimizeProvider, child) {
        print('🔵 [ActiveTracking] Consumer builder - isMinimized: ${minimizeProvider.isMinimized}');
        
        if (minimizeProvider.isMinimized) {
          // Saat minimize, tampilkan MainScreen dengan overlay
          return WillPopScope(
            onWillPop: () async => false,
            child: Stack(
              children: [
                const MainScreen(),
                TrackingMinimizedOverlay(),
              ],
            ),
          );
        }
        
        // Saat maximize, tampilkan full tracking screen
        return WillPopScope(
          onWillPop: () async {
            minimizeProvider.minimize();
            return false;
          },
          child: _buildFullView(),
        );
      },
    );
  }

  Widget _buildFullView() {
    final width = MediaQuery.of(context).size.width;
    double sp(double size) => size * (width / 390);

    return Scaffold(
      appBar: _buildAppBar(sp),
      body: Stack(
        children: [
          _buildBody(sp),

          // Catch Button - Untuk semua role (Nahkoda dan ABK)
          Positioned(
            right: 35,
            bottom: 180,
            child: GestureDetector(
              onTap: _navigateToCatchScreen,
              child: SizedBox(
                width: ResponsiveHelper.width(context, mobile: 70, tablet: 80),
                height: ResponsiveHelper.height(context, mobile: 70, tablet: 80),
                child: Lottie.asset(
                  'assets/animations/catch.json',
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                ),
              ),
            ),
          ),

          // Emergency Button - Untuk semua role
          Positioned(
            right: 20,
            bottom: 100,
            child: EmergencyButtonWidget(onPressed: _handleEmergency),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(double Function(double) sp) {
    return AppBar(
      title: _buildUserBadge(sp),
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: Icon(Icons.remove, color: Colors.white),
          onPressed: () {
            final provider = Provider.of<TrackingMinimizeProvider>(context, listen: false);
            provider.minimize();
          },
          tooltip: 'Minimize',
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isViolating
                ? [Colors.red.shade700, Colors.red.shade900]
                : [const Color(0xFF1B4F9C), const Color(0xFF2563EB)],
          ),
        ),
      ),
    );
  }

  Widget _buildUserBadge(double Function(double) sp) {
    // Tentukan warna badge berdasarkan role
    final badgeColor = widget.userRole == 'Nahkoda' 
        ? Colors.amber.withOpacity(0.9)
        : Colors.blue.withOpacity(0.9);
    
    final iconData = widget.userRole == 'Nahkoda'
        ? Icons.anchor
        : Icons.person;

    // Gunakan userName jika ada dan tidak kosong, jika tidak gunakan captainName
    final displayName = (widget.userName.isNotEmpty && widget.userName != 'Nahkoda') 
        ? widget.userName 
        : widget.captainName;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, size: 14, color: Colors.white),
          ),
          SizedBox(width: 8),
          Text(
            'Role: ${widget.userRole}, Nama: $displayName',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(double Function(double) sp) {
    final fuelPercentage = widget.fuelAmount > 0 
        ? ((_remainingFuel / widget.fuelAmount) * 100).clamp(0, 100)
        : 0.0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: sp(16)),

                // Warning Banners
                if (fuelPercentage < 20) _buildFuelWarningBanner(sp),

                VesselHeaderCard(
                  vesselName: widget.vesselName,
                  vesselNumber: widget.vesselNumber,
                  onSummaryTap: _showTripSummary,
                ),

                SizedBox(height: sp(12)),

                // Trip Statistics
                TripStatisticsCard(
                  departureDate: widget.departureTime,
                  estimatedReturnDate: widget.estimatedReturnDate,
                  estimatedDurationDays: widget.estimatedDuration,
                  currentDistance: _currentZoneInfo?['distance'],
                  isViolating: _isViolating,
                  zoneStatus: _zoneStatus,
                ),

                SizedBox(height: sp(16)),

                // Weather Display
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: sp(16)),
                  child: WeatherDisplayWidget(
                    weatherData: _weatherData,
                    isLoading: _isLoadingWeather,
                    onTap: _showWeatherDialog,
                    lastUpdate: _lastWeatherUpdate,
                  ),
                ),

                SizedBox(height: sp(16)),

                // Fuel & Resources
                _buildResourcesCard(sp),

                SizedBox(height: sp(16)),

                // Map
                _buildMapSection(sp),

                SizedBox(height: sp(20)),
              ],
            ),
          ),
        ),

        // Bottom Actions
        _buildBottomActions(sp),
      ],
    );
  }

  Widget _buildFuelWarningBanner(double Function(double) sp) {
    final fuelPercentage = widget.fuelAmount > 0 
        ? ((_remainingFuel / widget.fuelAmount) * 100).clamp(0, 100)
        : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: sp(16)),
      padding: EdgeInsets.all(sp(12)),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(sp(8)),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.fuelAmount > 0 
                  ? 'BBM Rendah: ${fuelPercentage.toStringAsFixed(0)}%'
                  : 'BBM: Tidak ada data',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesCard(double Function(double) sp) {
    final fuelPercentage = widget.fuelAmount > 0 
        ? ((_remainingFuel / widget.fuelAmount) * 100).clamp(0, 100)
        : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: sp(16)),
      padding: EdgeInsets.all(sp(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sp(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Persediaan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.local_gas_station, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('BBM'),
                        Text(
                          widget.fuelAmount > 0 
                              ? '${_remainingFuel.toStringAsFixed(1)} / ${widget.fuelAmount.toStringAsFixed(0)} L'
                              : 'Tidak ada data',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fuelPercentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          fuelPercentage < 20 ? Colors.red : Colors.green,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.ac_unit, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kapasitas Es'),
                    Text(
                      widget.iceStorage > 0 
                          ? '${widget.iceStorage.toStringAsFixed(0)} Kg'
                          : 'Tidak ada data',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(double Function(double) sp) {
    if (_currentPosition != null && widget.harborCoordinates != null) {
      return Container(
        height: 700,
        margin: EdgeInsets.symmetric(horizontal: sp(16)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(sp(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ProductionTrackingMap(
          currentPosition: _currentPosition!,
          harborLat: widget.harborCoordinates!['lat'],
          harborLng: widget.harborCoordinates!['lng'],
          harborName: widget.selectedHarbor,
          zoneRadius: widget.zoneRadius,
          isViolating: _isViolating,
          selectedCatchZoneName: widget.selectedHarbor,
          zoneStatus: _zoneStatus,
        ),
      );
    }

    return Container(
      height: 300,
      margin: EdgeInsets.symmetric(horizontal: sp(16)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: sp(16)),
            Text(
              'Mendapatkan lokasi...',
              style: TextStyle(fontSize: sp(16), color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(double Function(double) sp) {
    return const SizedBox.shrink(); // Hilangkan container bottom sepenuhnya
  }
}


