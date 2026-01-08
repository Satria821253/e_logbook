import 'package:e_logbook/screens/tracking/aktif_tracking.dart';
import 'package:e_logbook/services/weather_service.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PreTrackingScreen extends StatefulWidget {
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

  const PreTrackingScreen({
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
  });

  @override
  State<PreTrackingScreen> createState() => _PreTrackingScreenState();
}

class _PreTrackingScreenState extends State<PreTrackingScreen> {
  WeatherData? _weatherData;
  bool _isStartingTracking = false;

  static const double DEFAULT_ZONE_RADIUS = 50.0;

  Future<void> _startTracking() async {
    if (widget.harborCoordinates == null) {
      _showSnackBar('❌ Data koordinat pelabuhan tidak tersedia', Colors.red);
      return;
    }

    // Cek keamanan cuaca
    if (_weatherData != null && !WeatherService.isWeatherSafe(_weatherData!)) {
      final shouldContinue = await _showWeatherWarningDialog();
      if (shouldContinue != true) return;
    }

    setState(() => _isStartingTracking = true);

    try {
      // Pindah ke ActiveTrackingScreen
      if (mounted) {
        final result = await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveTrackingScreen(
              vesselName: widget.vesselName,
              vesselNumber: widget.vesselNumber,
              captainName: widget.captainName,
              crewCount: widget.crewCount,
              selectedHarbor: widget.selectedHarbor,
              departureTime: widget.departureTime,
              estimatedDuration: widget.estimatedDuration,
              emergencyContact: widget.emergencyContact,
              fuelAmount: widget.fuelAmount,
              iceStorage: widget.iceStorage,
              notes: widget.notes,
              harborCoordinates: {
                'lat': widget.harborCoordinates?['latitude'] ?? -6.1944,
                'lng': widget.harborCoordinates?['longitude'] ?? 106.8229,
                'name': widget.harborCoordinates?['name'] ?? widget.selectedHarbor,
              },
              zoneRadius: DEFAULT_ZONE_RADIUS,
            ),
          ),
        );

        // Kembalikan hasil ke screen sebelumnya
        if (mounted && result != null) {
          Navigator.pop(context, result);
        }
      }
    } catch (e) {
      setState(() => _isStartingTracking = false);
      _showSnackBar('❌ Gagal memulai tracking: $e', Colors.red);
    }
  }

  Future<bool?> _showWeatherWarningDialog() {
    final warningLevel = WeatherService.getWeatherWarningLevel(_weatherData!);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: warningLevel == 'BERBAHAYA' ? Colors.red : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('Peringatan Cuaca'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status cuaca: $warningLevel',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: warningLevel == 'BERBAHAYA' ? Colors.red : Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '🌊 Tinggi ombak: ${_weatherData!.waveHeight.toStringAsFixed(1)} m',
            ),
            Text(
              '💨 Kecepatan angin: ${_weatherData!.windSpeed.toStringAsFixed(1)} km/h',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ Kondisi cuaca tidak ideal untuk berlayar. Apakah Anda yakin ingin melanjutkan?',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Fungsi untuk mendapatkan animasi Lottie berdasarkan cuaca dan waktu
  String _getWeatherAnimation() {
    if (_weatherData == null) return 'assets/animations/cloudy.json';

    final condition = _weatherData!.condition.toLowerCase();
    final hour = DateTime.now().hour;
    final isNight = hour >= 18 || hour < 6;

    // Cerah / Sunny
    if (condition.contains('cerah') ||
        condition.contains('clear') ||
        condition.contains('sunny')) {
      if (isNight) {
        return 'assets/animations/night_sky.json';
      } else {
        return 'assets/animations/sunnynew.json';
      }
    }
    // Hujan
    else if (condition.contains('hujan') || condition.contains('rain')) {
      if (isNight) {
        return 'assets/animations/rainynight.json';
      } else {
        return 'assets/animations/rain.json';
      }
    }
    // Berawan / Cloudy
    else if (condition.contains('berawan') || condition.contains('cloud')) {
      if (isNight) {
        return 'assets/animations/cloudynight.json';
      } else {
        return 'assets/animations/cloudy.json';
      }
    }
    // Petir / Thunderstorm
    else if (condition.contains('petir') ||
        condition.contains('thunder') ||
        condition.contains('storm')) {
      if (isNight) {
        return 'assets/animations/nightthunderstorm.json';
      } else {
        return 'assets/animations/thunderstorm.json';
      }
    }
    // Kabut / Fog
    else if (condition.contains('kabut') ||
        condition.contains('fog') ||
        condition.contains('mist')) {
      if (isNight) {
        return 'assets/animations/nightfog.json';
      } else {
        return 'assets/animations/mist.json';
      }
    }

    // Default berdasarkan waktu
    if (isNight) {
      return 'assets/animations/cloudynight.json';
    } else {
      return 'assets/animations/cloudy.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double fs(double size) => size * (width / 390);
    double sp(double size) => size * (width / 390);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Persiapan Tracking',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 18, tablet: 20),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: sp(16)),

                  // Vessel Info Card
                  Container(
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
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(sp(12)),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B4F9C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(sp(12)),
                              ),
                              child: Icon(
                                Icons.directions_boat,
                                color: const Color(0xFF1B4F9C),
                                size: ResponsiveHelper.responsiveWidth(context, mobile: 28, tablet: 32),
                              ),
                            ),
                            SizedBox(width: sp(12)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.vesselName,
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 16, tablet: 18),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.vesselNumber,
                                    style: TextStyle(
                                      fontSize: fs(13),
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Spacer(),
                            Lottie.asset(
                              _getWeatherAnimation(),
                              width: ResponsiveHelper.responsiveWidth(context, mobile: 60, tablet: 72),
                              height: ResponsiveHelper.responsiveHeight(context, mobile: 60, tablet: 72),
                              fit: BoxFit.cover,
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          Icons.person,
                          'Nahkoda',
                          widget.captainName,
                          sp,
                          fs,
                        ),
                        SizedBox(height: sp(8)),
                        _buildInfoRow(
                          Icons.groups,
                          'ABK',
                          '${widget.crewCount} orang',
                          sp,
                          fs,
                        ),
                        SizedBox(height: sp(8)),
                        _buildInfoRow(
                          Icons.anchor,
                          'Pelabuhan',
                          widget.selectedHarbor,
                          sp,
                          fs,
                        ),
                        SizedBox(height: sp(8)),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Estimasi',
                          '${widget.estimatedDuration} hari',
                          sp,
                          fs,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: sp(16)),

                  // Resources Card
                  Container(
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.local_gas_station,
                          'BBM',
                          '${widget.fuelAmount.toStringAsFixed(0)} L',
                          sp,
                          fs,
                        ),
                        SizedBox(height: sp(8)),
                        _buildInfoRow(
                          Icons.ac_unit,
                          'Kapasitas Es',
                          '${widget.iceStorage.toStringAsFixed(0)} Kg',
                          sp,
                          fs,
                        ),
                        if (widget.notes != null) ...[
                          const Divider(height: 24),
                          _buildInfoRow(
                            Icons.note,
                            'Catatan',
                            widget.notes!,
                            sp,
                            fs,
                          ),
                        ],
                      ],
                    ),
                  ),            // Ready to Start
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: sp(16)),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: sp(24)),
                          Text(
                            'Siap Memulai Trip?',
                            style: TextStyle(
                              fontSize: fs(20),
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                            Lottie.asset(
                              'assets/animations/GPS.json', // ganti sesuai asset kamu
                              fit: BoxFit.contain,
                              repeat: true,
                          ),
                          SizedBox(height: sp(8)),
                          Text(
                            'Tracking lokasi dan cuaca real-time\nEstimasi: ${widget.estimatedDuration} hari',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: fs(14),
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: sp(100)),
                ],
              ),
            ),
          ),

          // Bottom Button
          Container(
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isStartingTracking ? null : _startTracking,
                icon: _isStartingTracking
                    ? SizedBox(
                        width: fs(24),
                        height: fs(24),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : SizedBox(
                        width: fs(50),
                        height: fs(50),
                        child: Lottie.asset(
                          'assets/animations/livetracking.json', // ganti sesuai asset kamu
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                      ),
                label: Text(
                  _isStartingTracking ? 'MEMULAI...' : 'MULAI TRACKING',
                  style: TextStyle(
                    fontSize: fs(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4F9C),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: sp(5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(sp(12)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    double Function(double) sp,
    double Function(double) fs,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1B4F9C)),
        SizedBox(width: sp(12)),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: fs(14), color: Colors.grey[600]),
              ),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: fs(12),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
