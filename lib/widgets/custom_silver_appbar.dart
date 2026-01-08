import 'dart:async';
import 'package:e_logbook/services/weather_service.dart';
import 'package:e_logbook/screens/notification_screen.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/widgets/custom_e_icon.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class CustomSliverAppBar extends StatefulWidget {
  const CustomSliverAppBar({super.key});

  @override
  State<CustomSliverAppBar> createState() => _CustomSliverAppBarState();
}

class _CustomSliverAppBarState extends State<CustomSliverAppBar>
    with TickerProviderStateMixin {
  String _userName = "Nelayan IPB";
  bool _isLoading = false;
  String _currentAddress = "Mendeteksi lokasi...";
  Position? _currentPosition;

  // Weather data
  WeatherData? _weatherData;
  bool _isLoadingWeather = true;
  Timer? _weatherTimer;
  Timer? _dialogUpdateTimer;
  DateTime? _lastWeatherUpdate;
  bool _isDialogOpen = false;

  // Animation controllers
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  Timer? _shakeTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startWeatherUpdates();
    
    // Initialize shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    // Start shake timer
    _startShakeTimer();
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    _dialogUpdateTimer?.cancel();
    _shakeController.dispose();
    _shakeTimer?.cancel();
    super.dispose();
  }
  void safeSetState(VoidCallback fn) {
  if (!mounted) return;
  setState(fn);
 }

  void _startShakeTimer() {
    _shakeTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _shakeController.forward().then((_) {
          _shakeController.reverse();
        });
      }
    });
  }

  Future<int> _getPendingRegistrationsCount(String nahkodaEmail) async {
    // Crew registration is now handled via web, return 0
    return 0;
  }

  void _startWeatherUpdates() {
    // Update weather setiap 5 menit (lebih cepat untuk real-time)
    _weatherTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_currentPosition != null) {
        _fetchWeatherData();
      }
    });
  }

  void _startDialogAutoUpdate() {
    // Auto-refresh di dalam dialog setiap 30 detik
    _dialogUpdateTimer?.cancel();
    _dialogUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isDialogOpen && _currentPosition != null) {
        _fetchWeatherData(silent: true); // Silent update tanpa loading
      }
    });
  }

  void _stopDialogAutoUpdate() {
    _dialogUpdateTimer?.cancel();
    _isDialogOpen = false;
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      safeSetState(() {
        _currentAddress = "Lokasi tidak aktif";
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        safeSetState(() {
          _currentAddress = "Izin lokasi ditolak";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      safeSetState(() {
        _currentAddress = "Izin lokasi ditolak permanen";
      });
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      safeSetState(() {
        _currentPosition = pos;
      });
      await _getAddressFromLatLng(pos);
      await _fetchWeatherData();
    } catch (e) {
      safeSetState(() {
        _currentAddress = "Gagal mendapatkan lokasi";
      });
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        safeSetState(() {
          _currentAddress =
              "${p.subLocality ?? p.locality ?? 'Tidak diketahui'}, ${p.administrativeArea ?? ''}";
        });
      } else {
        safeSetState(() {
          _currentAddress = "Alamat tidak ditemukan";
        });
      }
    } catch (e) {
      safeSetState(() {
        _currentAddress = "Gagal mendapatkan alamat";
      });
    }
  }

  Future<void> _fetchWeatherData({bool silent = false}) async {
    if (_currentPosition == null) return;

    if (!silent) {
      safeSetState(() {
        _isLoadingWeather = true;
      });
    }

    try {
      final weather = await WeatherService.getWeatherByPosition(
        _currentPosition!,
      );

      if (mounted) {
        safeSetState(() {
          _weatherData = weather;
          _isLoadingWeather = false;
          _lastWeatherUpdate = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        safeSetState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  // Fungsi untuk mendapatkan animasi Lottie berdasarkan cuaca dan waktu
  String _getWeatherAnimation() {
    if (_weatherData == null) return 'assets/animations/cloudy.json'; // Default: Berawan siang

    final condition = _weatherData!.condition.toLowerCase();
    final hour = DateTime.now().hour;
    final isNight = hour >= 18 || hour < 6; // Malam: 18:00 - 05:59

    // Cerah / Sunny
    if (condition.contains('cerah') ||
        condition.contains('clear') ||
        condition.contains('sunny')) {
      if (isNight) {
        return 'assets/animations/night_sky.json'; // Langit malam cerah
      } else {
        return 'assets/animations/sunnynew.json'; // Cerah siang
      }
    }
    // Hujan
    else if (condition.contains('hujan') || condition.contains('rain')) {
      if (isNight) {
        return 'assets/animations/rainynight.json'; // Hujan malam
      } else {
        return 'assets/animations/rain.json'; // Hujan siang
      }
    }
    // Berawan / Cloudy
    else if (condition.contains('berawan') || condition.contains('cloud')) {
      if (isNight) {
        return 'assets/animations/cloudynight.json'; // Berawan malam
      } else {
        return 'assets/animations/cloudy.json'; // Berawan siang
      }
    }
    // Petir / Thunderstorm
    else if (condition.contains('petir') ||
        condition.contains('thunder') ||
        condition.contains('storm')) {
      if (isNight) {
        return 'assets/animations/nightthunderstorm.json'; // Petir malam
      } else {
        return 'assets/animations/thunderstorm.json'; // Petir siang
      }
    }
    // Kabut / Fog
    else if (condition.contains('kabut') || condition.contains('fog') || condition.contains('mist')) {
      if (isNight) {
        return 'assets/animations/nightfog.json'; // Kabut malam
      } else {
        return 'assets/animations/mist.json'; // Kabut siang
      }
    }

    // Default berdasarkan waktu
    if (isNight) {
      return 'assets/animations/cloudynight.json'; // Default malam: Berawan malam
    } else {
      return 'assets/animations/cloudy.json'; // Default siang: Berawan siang
    }
  }

  Color _getWeatherColor() {
    if (_weatherData == null) return Colors.white;

    final condition = _weatherData!.condition.toLowerCase();

    if (condition.contains('cerah') ||
        condition.contains('clear') ||
        condition.contains('sunny')) {
      return Colors.amber;
    } else if (condition.contains('hujan') || condition.contains('rain')) {
      return Colors.lightBlue;
    } else if (condition.contains('petir') ||
        condition.contains('thunder') ||
        condition.contains('storm')) {
      return Colors.red;
    }

    return Colors.white;
  }

  String _getFormattedUpdateTime() {
    if (_lastWeatherUpdate == null) return 'Belum tersedia';
    return DateFormat('HH:mm').format(_lastWeatherUpdate!);
  }

  // ========================= MODERN WEATHER DIALOG =========================

  void _showWeatherDialog() {
    if (_weatherData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Data cuaca belum tersedia'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    _isDialogOpen = true;
    _startDialogAutoUpdate(); // Mulai auto-update saat dialog dibuka

    final isWeatherSafe = WeatherService.isWeatherSafe(_weatherData!);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => WillPopScope(
        onWillPop: () async {
          _stopDialogAutoUpdate();
          return true;
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              // Listen to state changes for real-time update in dialog
              return Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1B4F9C),
                      const Color(0xFF2563EB).withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header dengan gradient
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Kondisi Cuaca',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Row(
                                children: [
                                  // Live indicator
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          color: Colors.white,
                                          size: 8,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'LIVE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      _stopDialogAutoUpdate();
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 200,
                                    child: Text(
                                      _currentAddress,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              // Auto-update indicator
                              Row(
                                children: [
                                  Icon(
                                    Icons.autorenew,
                                    size: 12,
                                    color: Colors.greenAccent.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '30s',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.greenAccent.withOpacity(0.8),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Animasi Lottie cuaca besar
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                              boxShadow: [
                                BoxShadow(
                                  color: _getWeatherColor().withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Lottie.asset(
                              _getWeatherAnimation(),
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Kondisi cuaca utama
                          Text(
                            _weatherData!.condition,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 8),

                          // Suhu besar
                          Text(
                            '${_weatherData!.temperature.toStringAsFixed(1)}°C',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Grid info cuaca dengan card transparan
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _buildWeatherInfoCard(
                                      Icons.air_rounded,
                                      'Angin',
                                      '${_weatherData!.windSpeed.toStringAsFixed(1)} km/h',
                                    ),
                                    const SizedBox(width: 12),
                                    _buildWeatherInfoCard(
                                      Icons.water_drop_outlined,
                                      'Kelembaban',
                                      '${_weatherData!.humidity}%',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildWeatherInfoCard(
                                      Icons.waves_rounded,
                                      'Tinggi Ombak',
                                      '${_weatherData!.waveHeight.toStringAsFixed(1)} m',
                                    ),
                                    const SizedBox(width: 12),
                                    _buildWeatherInfoCard(
                                      Icons.update,
                                      'Update',
                                      _getFormattedUpdateTime(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Status keamanan compact
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isWeatherSafe
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isWeatherSafe
                                    ? Colors.greenAccent.withOpacity(0.5)
                                    : Colors.redAccent.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isWeatherSafe
                                      ? Icons.check_circle
                                      : Icons.warning_amber,
                                  color: isWeatherSafe
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isWeatherSafe ? 'Aman Melaut' : 'Tidak Aman',
                                  style: TextStyle(
                                    color: isWeatherSafe
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ).then((_) {
      _stopDialogAutoUpdate(); // Stop auto-update saat dialog ditutup
    });
  }

  Widget _buildWeatherInfoCard(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    
    return SliverAppBar(
      pinned: true,
      expandedHeight: isTablet ? 250.h : 200.h,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FlexibleSpaceBar(
          background: Padding(
            padding: EdgeInsets.only(
              top: isTablet ? 60.h : 50.h,
              left: ResponsiveHelper.responsiveWidth(context, mobile: 16, tablet: 24),
              right: ResponsiveHelper.responsiveWidth(context, mobile: 16, tablet: 24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul + lokasi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "E-Logbook",
                      style: TextStyle(
                        fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 20, tablet: 24),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: ResponsiveHelper.responsiveWidth(context, mobile: 18, tablet: 20),
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: Text(
                              _currentAddress.length > (isTablet ? 30 : 20)
                                  ? '${_currentAddress.substring(0, isTablet ? 30 : 20)}...'
                                  : _currentAddress,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 13, tablet: 15),
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 16, tablet: 20)),

                // Avatar + sapaan + notif
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.w),
                            ),
                            child: CircleAvatar(
                              radius: ResponsiveHelper.responsiveWidth(context, mobile: 28, tablet: 32),
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: ResponsiveHelper.responsiveWidth(context, mobile: 32, tablet: 38),
                                color: Color(0xFF1B4F9C),
                              ),
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Halo, Selamat Datang",
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16),
                                    color: Color.fromARGB(255, 230, 230, 230),
                                  ),
                                ),
                                _isLoading
                                    ? SizedBox(
                                        width: ResponsiveHelper.responsiveWidth(context, mobile: 100, tablet: 120),
                                        height: ResponsiveHelper.responsiveHeight(context, mobile: 16, tablet: 18),
                                        child: const LinearProgressIndicator(
                                          backgroundColor: Colors.white24,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        _userName,
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 16, tablet: 18),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                Row(
                                  children: [
                                    CustomEIcon(
                                      size: ResponsiveHelper.responsiveWidth(context, mobile: 14, tablet: 16),
                                      backgroundColor: Colors.white.withOpacity(0.9),
                                      textColor: Color(0xFF1B4F9C),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      "Total Point: 28",
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 12, tablet: 14),
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        final user = userProvider.user;
                        if (user?.isNahkoda == true) {
                          return FutureBuilder<int>(
                            future: _getPendingRegistrationsCount(user!.email),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              return AnimatedBuilder(
                                animation: _shakeAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: count > 0 
                                        ? Offset(_shakeAnimation.value, 0)
                                        : Offset.zero,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => NotificationScreen(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        height: ResponsiveHelper.responsiveHeight(context, mobile: 45, tablet: 50),
                                        width: ResponsiveHelper.responsiveWidth(context, mobile: 45, tablet: 50),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        child: Stack(
                                          children: [
                                            Center(
                                              child: Icon(
                                                Icons.notifications_none,
                                                size: ResponsiveHelper.responsiveWidth(context, mobile: 28, tablet: 32),
                                                color: Color(0xFF1B4F9C),
                                              ),
                                            ),
                                            if (count > 0)
                                              Positioned(
                                                right: ResponsiveHelper.responsiveWidth(context, mobile: 8, tablet: 10),
                                                top: ResponsiveHelper.responsiveHeight(context, mobile: 8, tablet: 10),
                                                child: Container(
                                                  padding: EdgeInsets.all(ResponsiveHelper.responsiveWidth(context, mobile: 4, tablet: 5)),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  constraints: BoxConstraints(
                                                    minWidth: ResponsiveHelper.responsiveWidth(context, mobile: 16, tablet: 18),
                                                    minHeight: ResponsiveHelper.responsiveHeight(context, mobile: 16, tablet: 18),
                                                  ),
                                                  child: Text(
                                                    '$count',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 10, tablet: 11),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        } else {
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NotificationScreen(),
                                ),
                              );
                            },
                            child: Container(
                              height: ResponsiveHelper.responsiveHeight(context, mobile: 45, tablet: 50),
                              width: ResponsiveHelper.responsiveWidth(context, mobile: 45, tablet: 50),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: Icon(
                                Icons.notifications_none,
                                size: ResponsiveHelper.responsiveWidth(context, mobile: 28, tablet: 32),
                                color: Color(0xFF1B4F9C),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(ResponsiveHelper.responsiveHeight(context, mobile: 70, tablet: 80)),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.responsiveWidth(context, mobile: 16, tablet: 24),
            vertical: ResponsiveHelper.responsiveHeight(context, mobile: 10, tablet: 15),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(ResponsiveHelper.responsiveWidth(context, mobile: 30, tablet: 35)),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Cari tangkapan...",
                      border: InputBorder.none,
                      icon: Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: ResponsiveHelper.responsiveWidth(context, mobile: 20, tablet: 24),
                      ),
                      hintStyle: TextStyle(
                        fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16)),
              // Weather Animation Button dengan Lottie dan Badge
              InkWell(
                onTap: _showWeatherDialog,
                child: Stack(
                  children: [
                    SizedBox(
                      width: ResponsiveHelper.responsiveWidth(context, mobile: 60, tablet: 70),
                      height: ResponsiveHelper.responsiveHeight(context, mobile: 60, tablet: 70),
                      child: _isLoadingWeather
                          ? Center(
                              child: SizedBox(
                                width: ResponsiveHelper.responsiveWidth(context, mobile: 20, tablet: 24),
                                height: ResponsiveHelper.responsiveHeight(context, mobile: 20, tablet: 24),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Lottie.asset(
                              _getWeatherAnimation(),
                              fit: BoxFit.contain,
                            ),
                    ),
                    // Live badge indicator
                    if (_lastWeatherUpdate != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(ResponsiveHelper.responsiveWidth(context, mobile: 4, tablet: 5)),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: ResponsiveHelper.responsiveWidth(context, mobile: 2, tablet: 2.5),
                            ),
                          ),
                          child: Icon(
                            Icons.circle,
                            size: ResponsiveHelper.responsiveWidth(context, mobile: 6, tablet: 8),
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}