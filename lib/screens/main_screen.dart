import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/screens/crew/screens/create_catch_screen.dart';
import 'package:e_logbook/screens/nahkoda/widgets/nahkoda_floating_menu.dart';
import 'package:e_logbook/screens/nahkoda/widgets/nahkoda_tracking_button.dart';
import 'package:e_logbook/screens/crew/widgets/crew_floating_menu.dart';
import 'package:e_logbook/provider/navigation_provider.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:e_logbook/services/getAPi/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'dart:math' show sin;
import 'home_screen.dart';
import 'statistics_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const StatisticsScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];
  
  String _currentAddress = "Mendeteksi lokasi...";
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    AuthService.addAccountStatusInterceptor(context);
  }
  
  Future<void> _getCurrentLocation() async {
    if (kIsWeb) {
      setState(() {
        _currentAddress = "Lokasi tidak ditemukan";
      });
      return;
    }
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = "Lokasi tidak aktif";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = "Izin lokasi ditolak";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentAddress = "Izin lokasi ditolak permanen";
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _currentAddress = "${p.subLocality ?? p.locality ?? 'Tidak diketahui'}, ${p.administrativeArea ?? ''}";
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = "Gagal mendapatkan lokasi";
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    // Gunakan ResponsiveHelper untuk konsistensi
    double fabSize = ResponsiveHelper.width(context, mobile: 70, tablet: 90);
    double navHeight = ResponsiveHelper.height(context, mobile: 65, tablet: 75);
    double iconSize = ResponsiveHelper.width(context, mobile: 26, tablet: 30);
    double fontSize = ResponsiveHelper.font(context, mobile: 11, tablet: 13);

    return Consumer2<UserProvider, NavigationProvider>(
      builder: (context, userProvider, navProvider, child) {
        final user = userProvider.user;
        final isABK = user?.isABK == true;
        final selectedIndex = navProvider.selectedIndex;
        final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

        if (isTablet) {
          return _buildTabletLayout(userProvider, navProvider, selectedIndex, isABK);
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.white,

          body: Stack(
            children: [
              _screens[selectedIndex],
              // Role-based floating menu
              if (!isABK) const NahkodaFloatingMenu(),
              if (isABK) const CrewFloatingMenu(),
            ],
          ),

          // FAB - role based
          floatingActionButton: isABK
              ? _buildCatchFAB(fabSize)
              : const NahkodaTrackingButton(),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,

          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: ResponsiveHelper.width(context, mobile: 10, tablet: 12),
            elevation: 10,
            child: SizedBox(
              height: navHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    Icons.home_rounded,
                    'Beranda',
                    0,
                    iconSize,
                    fontSize,
                    navProvider,
                  ),
                  _buildNavItem(
                    Icons.bar_chart_rounded,
                    'Statistik',
                    1,
                    iconSize,
                    fontSize,
                    navProvider,
                  ),
                  SizedBox(width: ResponsiveHelper.width(context, mobile: 40, tablet: 50)),
                  _buildNavItem(
                    Icons.history_rounded,
                    'Riwayat',
                    2,
                    iconSize,
                    fontSize,
                    navProvider,
                  ),
                  _buildNavItem(
                    Icons.person_rounded,
                    'Profil',
                    3,
                    iconSize,
                    fontSize,
                    navProvider,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // NAVIGATION ITEM
  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    double iconSize,
    double fontSize,
    NavigationProvider navProvider,
  ) {
    final bool isSelected = navProvider.selectedIndex == index;

    return InkWell(
      onTap: () => navProvider.setIndex(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: isSelected ? const Color(0xFF1B4F9C) : Colors.grey[500],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF1B4F9C) : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Catch FAB untuk Crew
  Widget _buildCatchFAB(double fabSize) {
    return Container(
      width: fabSize,
      height: fabSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4F9C).withOpacity(0.4),
            blurRadius: ResponsiveHelper.width(context, mobile: 12, tablet: 16),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateCatchScreen()),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(Icons.add, size: ResponsiveHelper.width(context, mobile: 36, tablet: 42), color: Colors.white),
      ),
    );
  }

  Widget _buildTabletLayout(UserProvider userProvider, NavigationProvider navProvider, int selectedIndex, bool isABK) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar Navigation
              Container(
                width: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header with logo
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: 
                          Column(
                            children: [
                              SizedBox(height: 16),
                              // Logo oipb
                              Image.asset(
                                'assets/oipb.png',
                                height: 120,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.school,
                                    size: 50,
                                    color: Color(0xFF1B4F9C),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              
                              // E-LogBook Title
                              const Text(
                                'E-LogBook',
                                style: TextStyle(
                                  color: Color(0xFF1B4F9C),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Version
                              const Text(
                                'v1.0.0',
                                style: TextStyle(
                                  color: Color(0xFF1B4F9C),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),

                    ),
                    
                    // Navigation Items
                    Expanded(
                      child: Column(
                        children: [
                          _buildSidebarItem(Icons.home_rounded, 'Beranda', 0, selectedIndex, navProvider),
                          _buildSidebarItem(Icons.bar_chart_rounded, 'Statistik', 1, selectedIndex, navProvider),
                          _buildSidebarItem(Icons.history_rounded, 'Riwayat', 2, selectedIndex, navProvider),
                          _buildSidebarItem(Icons.person_rounded, 'Profil', 3, selectedIndex, navProvider),
                          
                          if (isABK) ...[
                            _buildActionItem(Icons.storage, 'Data Raw', () {}),
                            _buildActionItem(Icons.check_circle, 'Daftar Hadir', () {}),
                          ] else ...[
                            _buildActionItem(Icons.assignment_ind, 'Kehadiran Crew', () {}),
                            _buildActionItem(Icons.analytics, 'Data Raw', () {}),
                            _buildActionItem(Icons.info_outline, 'Info Trip', () {}),
                          ],
                          
                          _buildActionItem(Icons.emergency, 'Emergency', () {}, isEmergency: true),
                          
                          const Spacer(),
                          
                          // Logout Button
                          Container(
                            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(11),
                                onTap: () {
                                  // Handle logout
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.logout,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 14),
                                      const Text(
                                        'Logout',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main Content with Header
              Expanded(
                child: Stack(
                  children: [
                    // Header at the back
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _buildTabletHeader(userProvider),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Body content overlaying navbar
          Positioned(
            top: 80,
            left: 240,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                ),
                child: _screens[selectedIndex],
              ),
            ),
          ),
          // FAB floating kanan bawah dengan animasi
          if (isABK) Positioned(
            right: 30,
            bottom: 50,
            child: _buildAnimatedFAB(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateCatchScreen()),
                );
              },
              icon: Icons.add,
            ),
          ),
          // FAB untuk Nahkoda
          if (!isABK) Positioned(
            right: 30,
            bottom: 50,
            child: _buildAnimatedFAB(
              onTap: () => _handleTripPreparation(context),
              isLottie: true,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabletHeader(UserProvider userProvider) {
    return Container(
      height: 100,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      padding: const EdgeInsets.only(left: 32, right: 32, bottom: 20),
      child: Row(
        children: [
          // Search Bar - Simple with blue border rectangle
          Expanded(
            flex: 2,
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF1B4F9C),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF1B4F9C), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari tangkapan...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (value) {
                        // Handle search
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Geolocation Display - Simple
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                size: 18,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  _currentAddress,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          // User Info Section
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, Selamat Datang',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 1),
              Text(
                userProvider.user?.name ?? 'User',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4F9C),
                ),
              ),
              const SizedBox(height: 2),
              // Points below name
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 10,
                        color: Color(0xFF1B4F9C),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Total Point: 28',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Avatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1B4F9C), width: 2),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              backgroundImage: userProvider.user?.profilePicture != null
                  ? FileImage(File(userProvider.user!.profilePicture!))
                  : null,
              child: userProvider.user?.profilePicture == null
                  ? const Icon(
                      Icons.person,
                      color: Color(0xFF1B4F9C),
                      size: 28,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSidebarItem(IconData icon, String label, int index, int selectedIndex, NavigationProvider navProvider) {
    final isSelected = selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => navProvider.setIndex(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : const Color(0xFF1B4F9C),
                  size: 16,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1B4F9C),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  
  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap, {bool isEmergency = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          splashColor: isEmergency ? Colors.red.withOpacity(0.2) : const Color(0xFF1B4F9C).withOpacity(0.1),
          highlightColor: isEmergency ? Colors.red.withOpacity(0.1) : const Color(0xFF1B4F9C).withOpacity(0.05),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isEmergency ? Colors.red : const Color(0xFF1B4F9C),
                  size: 16,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: isEmergency ? Colors.red : const Color(0xFF1B4F9C),
                    fontSize: 12,
                    fontWeight: isEmergency ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedFAB({
    required VoidCallback onTap,
    IconData? icon,
    bool isLottie = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, scaleValue, child) {
        return Transform.scale(
          scale: scaleValue,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeInOut,
            builder: (context, pulseValue, child) {
              return AnimatedBuilder(
                animation: AlwaysStoppedAnimation(pulseValue),
                builder: (context, child) {
                  final pulse = (pulseValue * 2 * 3.14159);
                  final shadowOpacity = 0.3 + (0.3 * (1 + sin(pulse)) / 2);
                  final shadowBlur = 12.0 + (8.0 * (1 + sin(pulse)) / 2);
                  
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withOpacity(shadowOpacity),
                          blurRadius: shadowBlur,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onTap,
                        customBorder: const CircleBorder(),
                        splashColor: Colors.white.withOpacity(0.3),
                        highlightColor: Colors.white.withOpacity(0.1),
                        child: isLottie ? _buildLottieFAB() : _buildIconFAB(icon!),
                      ),
                    ),
                  );
                },
              );
            },
            onEnd: () {
              if (mounted) {
                setState(() {});
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildIconFAB(IconData icon) {
    return Ink(
      width: 70,
      height: 70,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildLottieFAB() {
    final now = DateTime.now();
    final isNight = now.hour >= 18 || now.hour < 6;
    final lottieAsset = isNight 
        ? 'assets/animations/tripmalam.json'
        : 'assets/animations/tripsiang.json';

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1565C0), width: 4),
      ),
      child: ClipOval(
        child: Lottie.asset(
          lottieAsset,
          fit: BoxFit.cover,
          repeat: true,
          animate: true,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.directions_boat,
              color: Color(0xFF1565C0),
              size: 40,
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getTripData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'vesselName': 'KM Bahari Jaya',
      'vesselNumber': 'KP-12345-JKT',
      'crewCount': 8,
      'departureHarbor': 'Pelabuhan Muara Baru',
      'estimatedDuration': 5,
      'departureDate': DateTime.now().add(const Duration(days: 2)),
      'estimatedReturnDate': DateTime.now().add(const Duration(days: 7)),
      'fuelSupply': 500.0,
      'iceSupply': 1000.0,
      'status': 'scheduled',
    };
  }

  void _showNoTripDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.schedule,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Belum Ada Penjadwalan Trip',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Admin belum mengirim informasi trip. Silakan hubungi admin untuk penjadwalan trip atau cek Info Trip untuk melihat jadwal terbaru.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to trip info
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4F9C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cek Info Trip'),
          ),
        ],
      ),
    );
  }

  void _handleTripPreparation(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final tripData = await _getTripData();
      Navigator.pop(context);
      
      if (tripData == null) {
        _showNoTripDialog(context);
      } else {
        Navigator.pushNamed(
          context,
          '/pre-trip-form',
          arguments: tripData,
        );
      }
    } catch (e) {
      Navigator.pop(context);
      _showNoTripDialog(context);
    }
  }
}