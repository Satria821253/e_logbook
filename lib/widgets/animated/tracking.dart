import 'package:e_logbook/screens/tracking/pre_trip_fromscreen.dart';
import 'package:e_logbook/services/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';

class TrackingAnimationButton extends StatefulWidget {
  const TrackingAnimationButton({super.key});

  @override
  State<TrackingAnimationButton> createState() =>
      _TrackingAnimationButtonState();
}

class _TrackingAnimationButtonState extends State<TrackingAnimationButton> {
  late String _currentAnimation;

  @override
  void initState() {
    super.initState();
    _updateAnimationBasedOnTime();
  }

  void _updateAnimationBasedOnTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final isDay = hour >= 6 && hour < 18;

    setState(() {
      _currentAnimation = isDay
          ? 'assets/animations/tripsiang.json'
          : 'assets/animations/tripmalam.json';
    });
  }

  // ========================= MODERN LOADING DIALOG =========================

  void _showModernLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade700],
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const Icon(Icons.cloud, color: Colors.white, size: 40),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Memeriksa Cuaca',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4F9C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Memastikan kondisi aman untuk melaut...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================= WEATHER CHECK =========================

  Future<void> _checkWeatherAndNavigate(BuildContext context) async {
    _showModernLoading(context);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final weather = await WeatherService.getWeatherByPosition(position);

      if (context.mounted) Navigator.pop(context);

      if (weather == null) {
        if (!context.mounted) return;
        _showModernErrorDialog(
          context,
          'Gagal Mendapatkan Data Cuaca',
          'Tidak dapat mengakses data cuaca saat ini. Coba lagi nanti.',
        );
        return;
      }

      final isExtreme = _isWeatherExtreme(weather);

      if (!context.mounted) return;

      if (isExtreme) {
        _showModernWeatherWarning(context, weather);
      } else {
        _showModernConfirmation(context, weather);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showModernErrorDialog(
          context,
          'Terjadi Kesalahan',
          'Tidak dapat memeriksa kondisi cuaca: ${e.toString()}',
        );
      }
    }
  }

  bool _isWeatherExtreme(WeatherData weather) {
    final condition = weather.condition.toLowerCase();
    if (condition.contains('petir') ||
        condition.contains('thunder') ||
        condition.contains('storm') ||
        condition.contains('badai')) {
      return true;
    }
    if (weather.windSpeed > 40) return true;
    if (weather.waveHeight > 2.5) return true;
    return false;
  }

  // ========================= MODERN WARNING DIALOG =========================

  void _showModernWeatherWarning(BuildContext context, WeatherData weather) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon dengan animasi
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade700],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Cuaca Tidak Aman',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4F9C),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Kondisi cuaca saat ini tidak mendukung untuk melaut',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),

            const SizedBox(height: 24),

            // Weather Info Cards
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.red.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade200, width: 2),
              ),
              child: Column(
                children: [
                  _buildModernWeatherRow(
                    Icons.wb_cloudy_rounded,
                    'Kondisi',
                    weather.condition,
                    Colors.red,
                  ),
                  const Divider(height: 24),
                  _buildModernWeatherRow(
                    Icons.air_rounded,
                    'Kecepatan Angin',
                    '${weather.windSpeed.toStringAsFixed(1)} km/h',
                    Colors.red,
                  ),
                  const Divider(height: 24),
                  _buildModernWeatherRow(
                    Icons.waves_rounded,
                    'Tinggi Ombak',
                    '${weather.waveHeight.toStringAsFixed(1)} m',
                    Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Demi keselamatan, tunda trip hingga cuaca membaik',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4F9C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  void _showModernConfirmation(BuildContext context, WeatherData weather) {
    final isWarning = weather.windSpeed > 25 || weather.waveHeight > 1.5;
    final bool isNight = DateTime.now().hour >= 18 || DateTime.now().hour < 6;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // ICON / LOTTIE
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isWarning
                      ? Colors.orange.shade600
                      : const Color(0xFF1B4F9C),
                  width: 6,
                ),

                /// ========== BACKGROUND SIANG VS MALAM ==========
                gradient: isWarning
                    ? null
                    : isNight
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF0D1B2A), // navy gelap
                          Color(0xFF1B263B), // biru malam
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [
                          Color(0xFFD0E8FF), // biru pagi soft
                          Color(0xFFBBD7FF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),

              child: Padding(
                padding: const EdgeInsets.all(6.0),
                  child: Lottie.asset(
                    isWarning
                        ? 'assets/animations/emergecy.json'
                        : isNight
                        ? 'assets/animations/siapmelautmalam.json'
                        : 'assets/animations/siapmelaut.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),

              ),
            ),

            const SizedBox(height: 24),

            Text(
              isWarning
                  ? 'Kondisi Waspada'
                  : (isNight ? 'Siap Melaut Malam' : 'Siap Melaut'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4F9C),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              isWarning
                  ? 'Cuaca dalam kondisi waspada, harap berhati-hati'
                  : (isNight
                        ? 'Kondisi malam hari, tetap perhatikan arah angin & visibilitas'
                        : 'Kondisi cuaca mendukung untuk melaut'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),

            const SizedBox(height: 24),

            // Weather Info Cards
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200, width: 2),
              ),
              child: Column(
                children: [
                  _buildModernWeatherRow(
                    Icons.wb_cloudy_rounded,
                    'Kondisi',
                    weather.condition,
                    Colors.blue,
                  ),
                  const Divider(height: 24),
                  _buildModernWeatherRow(
                    Icons.thermostat_rounded,
                    'Suhu',
                    '${weather.temperature.toStringAsFixed(1)}°C',
                    Colors.blue,
                  ),
                  const Divider(height: 24),
                  _buildModernWeatherRow(
                    Icons.air_rounded,
                    'Kecepatan Angin',
                    '${weather.windSpeed.toStringAsFixed(1)} km/h',
                    Colors.blue,
                  ),
                  const Divider(height: 24),
                  _buildModernWeatherRow(
                    Icons.waves_rounded,
                    'Tinggi Ombak',
                    '${weather.waveHeight.toStringAsFixed(1)} m',
                    Colors.blue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF1B4F9C),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4F9C),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PreTripFormScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4F9C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lanjutkan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  // ========================= MODERN ERROR DIALOG =========================

  void _showModernErrorDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade700],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4F9C),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4F9C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mengerti',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================= HELPER WIDGET =========================

  Widget _buildModernWeatherRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========================= UI BUTTON =========================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _checkWeatherAndNavigate(context),
      child: Center(
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFF1B4F9C), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B4F9C).withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: Lottie.asset(
                _currentAnimation,
                key: ValueKey(_currentAnimation),
                fit: BoxFit.cover,
                repeat: true,
                animate: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
