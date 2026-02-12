import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/provider/notification_provider.dart';
import 'package:e_logbook/screens/crew/screens/create_catch_screen.dart';
import 'package:e_logbook/screens/nahkoda/widgets/nahkoda_floating_menu.dart';
import 'package:e_logbook/screens/tracking/animated/tracking.dart';
import 'package:e_logbook/screens/crew/widgets/crew_floating_menu.dart';
import 'package:e_logbook/provider/navigation_provider.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:e_logbook/utils/navigation_helper.dart';
import 'package:e_logbook/utils/profile_photo_cache.dart';
import 'package:e_logbook/services/api/auth_service.dart';
import 'package:e_logbook/services/nitification/local_notification_service.dart';
import 'package:e_logbook/widgets/sos_alert_dialog.dart';
import 'package:e_logbook/routes/crew_routes.dart';
import 'package:e_logbook/routes/nahkoda_routes.dart';
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
import 'splash_screen.dart';

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
  ImageProvider? _cachedImageProvider;
  
  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _getCurrentLocation();
    AuthService.addAccountStatusInterceptor(context);
    AuthService.addTokenInterceptor(context);
    _loadUserData();
    _initCachedPhoto();
  }
  
  Future<void> _requestNotificationPermission() async {
    await LocalNotificationService.requestPermissions();
  }
  
  Future<void> _initCachedPhoto() async {
    final cachedPath = await ProfilePhotoCache.getCachedPhotoPath();
    if (mounted && cachedPath != null) {
      setState(() {
        _cachedImageProvider = FileImage(File(cachedPath));
      });
    }
  }
  
  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUserFromStorage();
    print('DEBUG MainScreen: Loading user data...');
    print('DEBUG MainScreen: Current user = ${userProvider.user}');
    print('DEBUG MainScreen: Profile picture = ${userProvider.user?.profilePicture}');
  }
  
  Future<void> _getCurrentLocation() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _currentAddress = "Lokasi tidak ditemukan";
        });
      }
      return;
    }
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _currentAddress = "Lokasi tidak aktif";
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _currentAddress = "Izin lokasi ditolak";
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _currentAddress = "Izin lokasi ditolak permanen";
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        setState(() {
          _currentAddress = "${p.subLocality ?? p.locality ?? 'Tidak diketahui'}, ${p.administrativeArea ?? ''}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = "Gagal mendapatkan lokasi";
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    // Gunakan ResponsiveHelper untuk konsistensi
    double fabSize = ResponsiveHelper.width(context, mobile: 70, tablet: 90);
    double navHeight = 70;
    double iconSize = ResponsiveHelper.width(context, mobile: 24, tablet: 28);
    double fontSize = ResponsiveHelper.font(context, mobile: 10, tablet: 12);

    return Consumer2<UserProvider, NavigationProvider>(
      builder: (context, userProvider, navProvider, child) {
        final user = userProvider.user;
        final isABK = user?.isABK == true;
        final selectedIndex = navProvider.selectedIndex;
        final isTablet = ResponsiveHelper.isTablet(context);

        if (isTablet) {
          return _buildTabletLayout(userProvider, navProvider, selectedIndex, isABK);
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.white,

          body: IndexedStack(
            index: selectedIndex,
            children: [
              Stack(
                children: [
                  _screens[0],
                  if (!isABK) const NahkodaFloatingMenu(),
                  if (isABK) const CrewFloatingMenu(),
                ],
              ),
              _screens[1],
              _screens[2],
              _screens[3],
            ],
          ),

          floatingActionButton: isABK
              ? _buildCatchFAB(fabSize)
              : const TrackingAnimationButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            elevation: 10,
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
                const SizedBox(width: 80),
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

    return Expanded(
      child: InkWell(
        onTap: () => navProvider.setIndex(index),
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
        onPressed: () => NavigationHelper.pushNoTransition(context, const CreateCatchScreen()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(Icons.add, size: ResponsiveHelper.width(context, mobile: 36, tablet: 42), color: Colors.white),
      ),
    );
  }

  Widget _buildTabletLayout(UserProvider userProvider, NavigationProvider navProvider, int selectedIndex, bool isABK) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth < 800 ? 180.0 : 200.0;
    final headerHeight = screenWidth < 800 ? 80.0 : 90.0;
    final bodyTopOffset = headerHeight - 4;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar Navigation
              Container(
                width: sidebarWidth,
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
                      padding: EdgeInsets.only(
                        top: ResponsiveHelper.height(context, mobile: 21, tablet: 25),
                        bottom: ResponsiveHelper.height(context, mobile: 14, tablet: 18),
                        left: 8,
                        right: 8,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          // Logo oipb
                          Image.asset(
                            'assets/oipb.png',
                            height: ResponsiveHelper.height(context, mobile: 50, tablet: 70),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.school,
                                size: 40,
                                color: Color(0xFF1B4F9C),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          
                          // E-LogBook Title
                          Text(
                            'E-LogBook',
                            style: TextStyle(
                              color: const Color(0xFF1B4F9C),
                              fontSize: ResponsiveHelper.font(context, mobile: 12, tablet: 14),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.height(context, mobile: 3, tablet: 4)),
                          
                          // Version
                          Text(
                            'v1.0.0',
                            style: TextStyle(
                              color: const Color(0xFF1B4F9C),
                              fontSize: ResponsiveHelper.font(context, mobile: 8, tablet: 9),
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
                            _buildActionItem(Icons.storage, 'Data Raw', () {
                              CrewRoutes.navigateToDataRaw(context);
                            }),
                            _buildActionItem(Icons.calendar_today, 'Jadwal Tugas', () {
                              CrewRoutes.navigateToMySchedules(context);
                            }),
                            _buildActionItem(Icons.support_agent, 'WhatsApp CS', () {
                              CrewRoutes.navigateToCustomerService(context);
                            }),
                          ] else ...[
                            _buildActionItem(Icons.sailing, 'Info Trip', () {
                              NahkodaRoutes.navigateToTripInfo(context);
                            }),
                            _buildActionItem(Icons.calendar_today, 'Jadwal Tugas', () {
                              NahkodaRoutes.navigateToMySchedules(context);
                            }),
                            _buildActionItem(Icons.support_agent, 'WhatsApp CS', () {
                              NahkodaRoutes.navigateToCustomerService(context);
                            }),
                          ],
                          
                          const Spacer(),
                          
                          // Logout Button
                          Padding(
                            padding: const EdgeInsets.only(left: 12, right: 24, bottom: 12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 200 - 12 - 24,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                clipBehavior: Clip.hardEdge,
                                child: Ink(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      print('🖱️ Logout button clicked');
                                      final shouldLogout = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Konfirmasi Logout'),
                                          content: const Text('Apakah Anda yakin ingin keluar?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Batal'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Keluar'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (shouldLogout == true && context.mounted) {
                                        navProvider.resetToHome();
                                        await AuthService.logout();
                                        if (context.mounted) {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation, secondaryAnimation) => const SplashScreen(),
                                              transitionDuration: Duration.zero,
                                              reverseTransitionDuration: Duration.zero,
                                            ),
                                            (route) => false,
                                          );
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.logout,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Logout',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
                      child: _buildTabletHeader(userProvider, headerHeight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Body content overlaying navbar
          Positioned(
            top: bodyTopOffset,
            left: sidebarWidth - 15,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                ),
                child: _screens[selectedIndex],
              ),
            ),
          ),
          // Emergency FAB (untuk semua role)
          Positioned(
            right: ResponsiveHelper.width(context, mobile: 20, tablet: 30),
            bottom: ResponsiveHelper.height(context, mobile: 100, tablet: 120),
            child: _buildEmergencyFAB(),
          ),
          // FAB floating kanan bawah dengan animasi
          if (isABK) Positioned(
            right: ResponsiveHelper.width(context, mobile: 20, tablet: 30),
            bottom: ResponsiveHelper.height(context, mobile: 35, tablet: 50),
            child: _buildAnimatedFAB(
              onTap: () => NavigationHelper.pushNoTransition(context, const CreateCatchScreen()),
              icon: Icons.add,
            ),
          ),
          // FAB untuk Nahkoda
          if (!isABK) Positioned(
            right: ResponsiveHelper.width(context, mobile: 20, tablet: 30),
            bottom: ResponsiveHelper.height(context, mobile: 35, tablet: 50),
            child: _buildAnimatedFAB(
              onTap: () => _handleTripPreparation(context),
              isLottie: true,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabletHeader(UserProvider userProvider, double headerHeight) {
    final screenWidth = MediaQuery.of(context).size.width;
    final searchBarWidth = screenWidth < 800 ? 240.0 : 280.0;
    final avatarRadius = screenWidth < 800 ? 16.0 : 18.0;
    
    return Container(
      height: headerHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      padding: const EdgeInsets.only(left: 0, right: 12, top: 14, bottom: 0),
      child: Row(
        children: [
          // Search Bar - Simple, full rounded, compact, fixed width
          SizedBox(
            width: searchBarWidth,
            child: Container(
              height: ResponsiveHelper.height(context, mobile: 32, tablet: 36),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF1B4F9C),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.search, color: const Color(0xFF1B4F9C), size: ResponsiveHelper.width(context, mobile: 16, tablet: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: ResponsiveHelper.font(context, mobile: 11, tablet: 12),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: TextStyle(fontSize: ResponsiveHelper.font(context, mobile: 11, tablet: 12)),
                      onSubmitted: (value) {
                        // Handle search
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          
          // Geolocation - Compact
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: ResponsiveHelper.width(context, mobile: 12, tablet: 14),
                color: Colors.redAccent,
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: screenWidth < 800 ? 80 : 100),
                child: Text(
                  _currentAddress,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.font(context, mobile: 9, tablet: 10),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Notification Icon
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, child) {
              return IconButton(
                icon: Stack(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: ResponsiveHelper.width(context, mobile: 20, tablet: 22),
                      color: const Color(0xFF1B4F9C),
                    ),
                    // Badge untuk unread notifications
                    if (notifProvider.unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: ResponsiveHelper.width(context, mobile: 14, tablet: 16),
                            minHeight: ResponsiveHelper.height(context, mobile: 14, tablet: 16),
                          ),
                          child: Center(
                            child: Text(
                              notifProvider.unreadCount > 99 ? '99+' : '${notifProvider.unreadCount}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveHelper.font(context, mobile: 7, tablet: 8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/notification');
                },
                tooltip: 'Notifikasi',
              );
            },
          ),
          const SizedBox(width: 8),
          
          // User Info - Compact
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Halo, Selamat Datang',
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, mobile: 8, tablet: 9),
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 1),
              Text(
                userProvider.user?.name ?? 'User',
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(context, mobile: 11, tablet: 12),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B4F9C),
                ),
              ),
              const SizedBox(height: 2),
              // Points - Compact
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.width(context, mobile: 5, tablet: 6),
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star,
                        size: ResponsiveHelper.width(context, mobile: 7, tablet: 8),
                        color: const Color(0xFF1B4F9C),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Point: 28',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.font(context, mobile: 8, tablet: 9),
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          
          // Avatar - Compact with click functionality
          GestureDetector(
            onTap: () {
              // Navigate to profile screen
              final navProvider = Provider.of<NavigationProvider>(context, listen: false);
              navProvider.setIndex(3); // Profile screen index
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1B4F9C), width: 1.5),
              ),
              child: Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final profilePicture = userProvider.user?.profilePicture;
                  ImageProvider? imageProvider;
                  
                  if (profilePicture != null && profilePicture.isNotEmpty) {
                    imageProvider = NetworkImage(profilePicture);
                  } else if (_cachedImageProvider != null) {
                    imageProvider = _cachedImageProvider;
                  }
                  
                  return CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? Icon(
                            Icons.person_rounded,
                            color: const Color(0xFF1B4F9C),
                            size: avatarRadius * 1.2,
                          )
                        : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSidebarItem(IconData icon, String label, int index, int selectedIndex, NavigationProvider navProvider) {
    final isSelected = selectedIndex == index;
    final screenWidth = MediaQuery.of(context).size.width;
    final rightMargin = screenWidth < 800 ? 20.0 : 24.0;
    final iconSize = screenWidth < 800 ? 13.0 : 14.0;
    final fontSize = screenWidth < 800 ? 10.0 : 11.0;
    
    print('🔧 Building sidebar item: $label, selected: $isSelected, right margin: $rightMargin');
    
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: rightMargin,
        top: 3,
        bottom: 3,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 200 - 12 - rightMargin,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.hardEdge,
          child: Ink(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () {
                print('🖱️ Sidebar item clicked: $label');
                navProvider.setIndex(index);
              },
              splashColor: const Color(0xFF1B4F9C).withOpacity(0.1),
              highlightColor: const Color(0xFF1B4F9C).withOpacity(0.05),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? Colors.white : const Color(0xFF1B4F9C),
                      size: iconSize,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1B4F9C),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: fontSize,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  
  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap, {bool isEmergency = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rightMargin = screenWidth < 800 ? 20.0 : 24.0;
    final iconSize = screenWidth < 800 ? 13.0 : 14.0;
    final fontSize = screenWidth < 800 ? 10.0 : 11.0;
    
    print('🔧 Building action item: $label with right margin: $rightMargin');
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: rightMargin,
        top: 3,
        bottom: 3,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 200 - 12 - rightMargin,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.hardEdge,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () {
                print('🖱️ Action item clicked: $label');
                onTap();
              },
              splashColor: isEmergency ? Colors.red.withOpacity(0.2) : const Color(0xFF1B4F9C).withOpacity(0.1),
              highlightColor: isEmergency ? Colors.red.withOpacity(0.1) : const Color(0xFF1B4F9C).withOpacity(0.05),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: isEmergency ? Colors.red : const Color(0xFF1B4F9C),
                      size: iconSize,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        color: isEmergency ? Colors.red : const Color(0xFF1B4F9C),
                        fontSize: fontSize,
                        fontWeight: isEmergency ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final fabSize = screenWidth < 800 ? 48.0 : 54.0;
    final iconSize = screenWidth < 800 ? 22.0 : 26.0;
    
    return Ink(
      width: fabSize,
      height: fabSize,
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
        size: iconSize,
      ),
    );
  }

  Widget _buildLottieFAB() {
    final screenWidth = MediaQuery.of(context).size.width;
    final fabSize = screenWidth < 800 ? 50.0 : 56.0;
    final borderWidth = screenWidth < 800 ? 2.5 : 3.0;
    
    final now = DateTime.now();
    final isNight = now.hour >= 18 || now.hour < 6;
    final lottieAsset = isNight 
        ? 'assets/animations/tripmalam.json'
        : 'assets/animations/tripsiang.json';

    return Container(
      width: fabSize,
      height: fabSize,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1565C0), width: borderWidth),
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

  Widget _buildEmergencyFAB() {
    final screenWidth = MediaQuery.of(context).size.width;
    final fabSize = screenWidth < 800 ? 48.0 : 54.0;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, scaleValue, child) {
        return Transform.scale(
          scale: scaleValue,
          child: GestureDetector(
            onTap: () async {
              final success = await showSosAlertDialog(context);
              if (success == true && context.mounted) {
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
                  ),
                );
              }
            },
            child: Container(
              width: fabSize,
              height: fabSize,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Lottie.asset(
                  'assets/animations/alert.json',
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                ),
              ),
            ),
          ),
        );
      },
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