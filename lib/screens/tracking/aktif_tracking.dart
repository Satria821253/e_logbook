import 'package:e_logbook/screens/tracking/raltime_zone_map.dart';
import 'package:e_logbook/screens/tracking/widgets/emergency_button.dart';
import 'package:e_logbook/screens/tracking/widgets/trip_statistics_card.dart';
import 'package:e_logbook/screens/tracking/widgets/vessel_header_card.dart';
import 'package:e_logbook/screens/tracking/widgets/wheater_detail_dialog.dart';
import 'package:e_logbook/screens/tracking/widgets/wheater_display_widget.dart';
import 'package:e_logbook/screens/tracking/widgets/zone_validation_dialog.dart';
import 'package:e_logbook/screens/zone_violation_detail_screen.dart';
import 'package:e_logbook/services/location_tracking_service.dart';
import 'package:e_logbook/services/zone_checker.dart';
import 'package:e_logbook/services/realtime_service.dart';
import 'package:e_logbook/services/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class ActiveTrackingScreen extends StatefulWidget {
  final String vesselName;
  final String vesselNumber;
  final String captainName;
  final int crewCount;
  final String selectedHarbor;
  final DateTime departureTime;
  final int estimatedDuration;
  final String emergencyContact;
  final double fuelAmount;
  final double iceStorage;
  final String? notes;
  final Map<String, dynamic>? harborCoordinates;
  final double zoneRadius;

  const ActiveTrackingScreen({
    super.key,
    required this.vesselName,
    required this.vesselNumber,
    required this.captainName,
    required this.crewCount,
    required this.selectedHarbor,
    required this.departureTime,
    required this.estimatedDuration,
    required this.emergencyContact,
    required this.fuelAmount,
    required this.iceStorage,
    this.notes,
    this.harborCoordinates,
    required this.zoneRadius,
  });

  @override
  State<ActiveTrackingScreen> createState() => _ActiveTrackingScreenState();
}

class _ActiveTrackingScreenState extends State<ActiveTrackingScreen> {
  // Zone tracking
  bool _isViolating = false;
  Position? _currentPosition;
  Map<String, dynamic>? _currentZoneInfo;

  // Trip data
  Duration _tripDuration = Duration.zero;
  Timer? _durationTimer;

  // Fuel management
  double _remainingFuel = 0;
  bool _hasShownFuelWarning = false;
  static const double FUEL_CONSUMPTION_RATE = 10.0;

  // Alarm
  bool _isAlarmPlaying = false;

  // Weather data
  WeatherData? _weatherData;
  bool _isLoadingWeather = true;
  DateTime? _lastWeatherUpdate;
  Timer? _weatherTimer;

  @override
  void initState() {
    super.initState();
    _remainingFuel = widget.fuelAmount;
    _initializeTracking();
  }

  @override
  void dispose() {
    _cleanupResources();
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

  void _cleanupResources() {
    _durationTimer?.cancel();
    _weatherTimer?.cancel();
    _stopAlarm();
    LocationTrackingService.stopTracking();
    RealTimeService.stopListening();
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
      if (!mounted) return;

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
    });
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ZoneViolationDetailScreen(
                zoneInfo: _currentZoneInfo!,
                onDismiss: () {},
              ),
            ),
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

  void _handleEmergency() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Sinyal Darurat'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin mengirim sinyal darurat ke admin?\n\nSinyal ini akan segera diterima oleh pusat kontrol.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendEmergencySignal();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Kirim Darurat'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmergencySignal() async {
    if (_currentPosition == null) {
      _showError('Lokasi tidak tersedia');
      return;
    }

    try {
      await RealTimeService.sendEmergencySignal(
        vesselName: widget.vesselName,
        vesselNumber: widget.vesselNumber,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        message: 'DARURAT - Kapal membutuhkan bantuan segera!',
      );
      _showEmergency('SINYAL DARURAT TERKIRIM KE ADMIN!');
    } catch (e) {
      _showError('Gagal kirim sinyal: $e');
    }
  }

  // ==================== TRIP COMPLETION ====================

  Future<void> _stopTracking() async {
    final shouldStop = await _showConfirmStopDialog();
    if (shouldStop != true) return;

    await LocationTrackingService.stopTracking();
    _cleanupResources();

    if (mounted) {
      Navigator.pop(context, _buildTripResult());
    }
  }

  Map<String, dynamic> _buildTripResult() {
    return {
      'vesselName': widget.vesselName,
      'vesselNumber': widget.vesselNumber,
      'captainName': widget.captainName,
      'crewCount': widget.crewCount,
      'selectedHarbor': widget.selectedHarbor,
      'departureTime': widget.departureTime,
      'arrivalTime': DateTime.now(),
      'duration': _tripDuration,
      'finalPosition': _currentPosition,
      'harborCoordinates': widget.harborCoordinates,
      'initialFuel': widget.fuelAmount,
      'remainingFuel': _remainingFuel,
      'fuelConsumed': widget.fuelAmount - _remainingFuel,
      'iceStorage': widget.iceStorage,
      'estimatedDuration': widget.estimatedDuration,
      'emergencyContact': widget.emergencyContact,
      'notes': widget.notes,
      'wasViolating': _isViolating,
    };
  }

  Future<bool?> _showConfirmStopDialog() {
    final estimatedEnd = widget.departureTime.add(
      Duration(days: widget.estimatedDuration),
    );
    final isEarly = DateTime.now().isBefore(estimatedEnd);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Akhiri Trip?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Durasi trip: ${_formatDuration(_tripDuration)}'),
            Text('Estimasi awal: ${widget.estimatedDuration} hari'),
            const SizedBox(height: 8),
            if (isEarly)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⚠️ Trip berakhir lebih cepat dari estimasi',
                  style: TextStyle(fontSize: 13, color: Colors.orange),
                ),
              ),
            const SizedBox(height: 12),
            const Text('Apakah Anda yakin ingin mengakhiri tracking?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Akhiri Trip'),
          ),
        ],
      ),
    );
  }

  // ==================== UI HELPERS ====================

  void _showTripSummary() {
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
              'Durasi',
              _formatDuration(_tripDuration),
            ),
            _buildSummaryRow(
              Icons.local_gas_station,
              'BBM Tersisa',
              '${_remainingFuel.toStringAsFixed(1)} L',
            ),
            _buildSummaryRow(
              Icons.local_gas_station,
              'BBM Terpakai',
              '${(widget.fuelAmount - _remainingFuel).toStringAsFixed(1)} L',
            ),
            _buildSummaryRow(
              Icons.ac_unit,
              'Kapasitas Es',
              '${widget.iceStorage.toStringAsFixed(0)} Kg',
            ),
            if (widget.notes != null)
              _buildSummaryRow(Icons.note, 'Catatan', widget.notes!),
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

  void _showEmergency(String message) {
    _showNotification(message, Colors.red.shade900, Icons.emergency);
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
    final width = MediaQuery.of(context).size.width;
    double sp(double size) => size * (width / 390);

    return WillPopScope(
      onWillPop: () async {
        _showWarning('Hentikan tracking terlebih dahulu');
        return false;
      },
      child: Scaffold(
        appBar: _buildAppBar(sp),
        body: Stack(
          children: [
            _buildBody(sp),

            // Emergency Button Mengambang
            Positioned(
              right: 20,
              bottom: 100,
              child: EmergencyButtonWidget(onPressed: _handleEmergency),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(double Function(double) sp) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tracking Aktif',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: sp(18),
            ),
          ),
          Text(
            widget.vesselName,
            style: TextStyle(
              fontSize: sp(12),
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      iconTheme: const IconThemeData(color: Colors.white),
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

  Widget _buildBody(double Function(double) sp) {
    final fuelPercentage = ((_remainingFuel / widget.fuelAmount) * 100).clamp(
      0,
      100,
    );
    final estimatedEnd = widget.departureTime.add(
      Duration(days: widget.estimatedDuration),
    );
    final remainingTime = estimatedEnd.difference(DateTime.now());
    final isOvertime = remainingTime.isNegative;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: sp(16)),

                // Warning Banners
                if (fuelPercentage < 20) _buildFuelWarningBanner(sp),
                if (isOvertime) _buildOvertimeBanner(sp),

                VesselHeaderCard(
                  vesselName: widget.vesselName,
                  vesselNumber: widget.vesselNumber,
                  onSummaryTap: _showTripSummary,
                ),

                SizedBox(height: sp(12)),

                // Trip Statistics
                TripStatisticsCard(
                  tripDuration: _tripDuration,
                  currentDistance: _currentZoneInfo?['distance'],
                  isViolating: _isViolating,
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
    final fuelPercentage = ((_remainingFuel / widget.fuelAmount) * 100).clamp(
      0,
      100,
    );

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
              'BBM Rendah: ${fuelPercentage.toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOvertimeBanner(double Function(double) sp) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: sp(16), vertical: sp(8)),
      padding: EdgeInsets.all(sp(12)),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(sp(8)),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Trip melebihi estimasi ${widget.estimatedDuration} hari',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesCard(double Function(double) sp) {
    final fuelPercentage = ((_remainingFuel / widget.fuelAmount) * 100).clamp(
      0,
      100,
    );

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
                          '${_remainingFuel.toStringAsFixed(1)} / ${widget.fuelAmount.toStringAsFixed(0)} L',
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
                      '${widget.iceStorage.toStringAsFixed(0)} Kg',
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
        child: RealTimeZoneMapWithCoordinates(
          currentPosition: _currentPosition!,
          harborLat: widget.harborCoordinates!['lat'],
          harborLng: widget.harborCoordinates!['lng'],
          harborName: widget.selectedHarbor,
          zoneRadius: widget.zoneRadius,
          isViolating: _isViolating,
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
    return Container(
      padding: EdgeInsets.all(sp(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _stopTracking,
              icon: const Icon(Icons.stop),
              label: const Text('Akhiri Trip'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 2),
                padding: EdgeInsets.symmetric(vertical: sp(14)),
              ),
            ),
          ),
          if (_currentZoneInfo != null) ...[
            SizedBox(width: sp(12)),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ZoneViolationDetailScreen(
                        zoneInfo: _currentZoneInfo!,
                        onDismiss: () {},
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('Detail Zona'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1B4F9C),
                  side: const BorderSide(color: Color(0xFF1B4F9C), width: 2),
                  padding: EdgeInsets.symmetric(vertical: sp(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
