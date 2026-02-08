import 'package:e_logbook/screens/splash_screen.dart';
import 'package:e_logbook/screens/page/edit_profile_screen.dart';
import 'package:e_logbook/screens/settings/settings_screen.dart';
import 'package:e_logbook/screens/help_screen.dart';
import 'package:e_logbook/screens/vessel/vessel_info_screen.dart';
import 'package:e_logbook/services/api/auth_service.dart';
import 'package:e_logbook/services/realtime/realtime_update_service.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/provider/navigation_provider.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:e_logbook/utils/navigation_helper.dart';
import 'package:e_logbook/utils/profile_photo_cache.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  String? _cachedPhotoPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Load cached photo dulu (instant)
    _loadCachedPhoto();
    
    // Baru load profile dari API di background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });

    // Register listener untuk auto-update profile
    RealtimeUpdateService.addListener('profile', () {
      if (mounted) {
        print('🔔 Profile changed, auto-refreshing...');
        _loadProfile();
      }
    });

    RealtimeUpdateService.addListener('documents', () {
      if (mounted) {
        print('🔔 Documents changed, refreshing profile...');
        _loadProfile();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RealtimeUpdateService.removeListener('profile');
    RealtimeUpdateService.removeListener('documents');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('🔄 App resumed, refreshing profile...');
      _loadProfile();
    }
  }

  /// Load cached photo first (instant)
  Future<void> _loadCachedPhoto() async {
    final cachedPath = await ProfilePhotoCache.getCachedPhotoPath();
    if (mounted && cachedPath != null) {
      setState(() {
        _cachedPhotoPath = cachedPath;
      });
      print('✅ Loaded cached photo: $cachedPath');
    }
  }

  Future<void> _loadProfile() async {
    try {
      print('🔄 Loading profile from API...');

      if (mounted) {
        final userProvider = Provider.of<UserProvider>(
          context,
          listen: false,
        );

        // Sync from API to get fresh data
        await userProvider.syncProfileFromAPI();
        print('✅ Profile synced from API');

        // Cache photo jika ada dan berbeda dari yang sekarang
        final photoUrl = userProvider.user?.profilePicture;
        if (photoUrl != null && photoUrl.startsWith('http')) {
          // Extract filename tanpa timestamp untuk comparison
          final newFileName = photoUrl.split('/').last.split('?').first; // e.g., "10-1769597437577.png"
          final cachedUrl = await ProfilePhotoCache.getCachedPhotoUrl();
          final cachedFileName = cachedUrl?.split('/').last.split('?').first;
          
          // Hanya download jika filename berbeda (foto benar-benar baru)
          if (cachedFileName != newFileName) {
            print('📥 New photo detected: $newFileName (old: $cachedFileName)');
            ProfilePhotoCache.cacheProfilePhoto(photoUrl).then((path) {
              if (mounted && path != null && path != _cachedPhotoPath) {
                setState(() {
                  _cachedPhotoPath = path;
                });
                print('✅ Photo updated: $path');
              }
            });
          } else {
            print('⏭️ Same photo ($newFileName), skipping download');
          }
        }

        // Force rebuild
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
    }
  }

  Future<void> _refreshProfile() async {
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    final orientation = MediaQuery.of(context).orientation;
    final isTablet = ResponsiveHelper.isTablet(context);

    print('📱 [RESPONSIVE] Profile Screen Build:');
    print('   Width: ${size.width.toStringAsFixed(1)}');
    print('   Height: ${size.height.toStringAsFixed(1)}');
    print('   ShortestSide: ${shortestSide.toStringAsFixed(1)}');
    print('   Orientation: $orientation');
    print('   IsTablet: $isTablet');
    print('   Layout: ${isTablet ? "TABLET" : "MOBILE"}');

    if (isTablet) {
      return _buildTabletLayout();
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              NavigationHelper.pushNoTransition(context, const SettingsScreen());
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(),
              SizedBox(
                height: ResponsiveHelper.height(
                  context,
                  mobile: 20,
                  tablet: 28,
                ),
              ),
              _buildStatsCard(),
              SizedBox(
                height: ResponsiveHelper.height(
                  context,
                  mobile: 20,
                  tablet: 28,
                ),
              ),
              _buildMenuSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFFF5F5F5),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  _buildStatsCard(),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _buildMenuSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    final isTablet = ResponsiveHelper.isTablet(context);
    
    print('👤 [HEADER] Building Profile Header:');
    print('   ShortestSide: ${shortestSide.toStringAsFixed(1)}');
    print('   IsTablet: $isTablet');
    print('   Using SizedBox width: ${shortestSide >= 540 ? "245 (tablet)" : "60 (mobile)"}');

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.padding(context, mobile: 24, tablet: 0),
      color: isTablet ? Colors.transparent : Colors.transparent,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final photoUrl = userProvider.user?.profilePicture;
              if (photoUrl != null && photoUrl.isNotEmpty) {
                _showPhotoPreview(photoUrl);
              }
            },
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1B4F9C),
                      width: ResponsiveHelper.width(
                        context,
                        mobile: 2,
                        tablet: 3,
                      ),
                    ),
                  ),
                  child: Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      final user = userProvider.user;
                      final photoUrl = user?.profilePicture;
                      print('🔍 [UI] Building CircleAvatar with photo: $photoUrl');
                      
                      final hasValidPhoto =
                          photoUrl != null &&
                          photoUrl.isNotEmpty &&
                          (photoUrl.startsWith('http') ||
                              photoUrl.startsWith('file://'));

                      final radius = ResponsiveHelper.width(
                        context,
                        mobile: 50,
                        tablet: 50,
                      );

                      // Prioritas: cached photo > URL dari API
                      ImageProvider? imageProvider;
                      
                      if (_cachedPhotoPath != null) {
                        // Gunakan cached photo (instant)
                        imageProvider = FileImage(File(_cachedPhotoPath!));
                      } else if (hasValidPhoto) {
                        // Fallback ke URL jika cache belum ada
                        if (photoUrl.startsWith('file://')) {
                          imageProvider = FileImage(
                            File(photoUrl.replaceFirst('file://', '')),
                          );
                        } else {
                          // Sementara gunakan NetworkImage sambil menunggu cache
                          imageProvider = NetworkImage(photoUrl);
                        }
                      }

                      return CircleAvatar(
                        key: ValueKey(_cachedPhotoPath ?? photoUrl ?? 'default'),
                        radius: radius,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: imageProvider,
                        child: !hasValidPhoto
                            ? Icon(
                                Icons.person_rounded,
                                size: radius * 1.2,
                                color: const Color(0xFF1B4F9C),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: ResponsiveHelper.height(context, mobile: 16, tablet: 14),
          ),
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.user;
              print('📝 [UI-Name] Consumer rebuild - Name: ${user?.name}');
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (MediaQuery.of(context).size.shortestSide >= 540)
                        SizedBox(width: 245)
                      else
                        SizedBox(width: 60),
                      Flexible(
                        child: Text(
                          user?.name ?? 'Nama Pengguna',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: ResponsiveHelper.font(
                              context,
                              mobile: 24,
                              tablet: 22,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.width(context, mobile: 8, tablet: 10)),
                      InkWell(
                        onTap: () async {
                          print('🖱️ [PROFILE] Edit TAPPED!');
                          await NavigationHelper.pushNoTransition(
                            context,
                            const EditProfileScreen(),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.width(
                              context,
                              mobile: 10,
                              tablet: 12,
                            ),
                            vertical: ResponsiveHelper.height(
                              context,
                              mobile: 6,
                              tablet: 7,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.width(
                                context,
                                mobile: 12,
                                tablet: 14,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit,
                                size: ResponsiveHelper.width(
                                  context,
                                  mobile: 14,
                                  tablet: 15,
                                ),
                                color: Colors.black,
                              ),
                              SizedBox(
                                width: ResponsiveHelper.width(
                                  context,
                                  mobile: 4,
                                  tablet: 5,
                                ),
                              ),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: ResponsiveHelper.font(
                                    context,
                                    mobile: 12,
                                    tablet: 13,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (MediaQuery.of(context).size.shortestSide >= 540)
                        Spacer(),
                    ],
                  ),
                  SizedBox(
                    height: ResponsiveHelper.height(
                      context,
                      mobile: 4,
                      tablet: 6,
                    ),
                  ),
                  Text(
                    '@${user?.username ?? 'username'}',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: ResponsiveHelper.font(
                        context,
                        mobile: 14,
                        tablet: 14,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveHelper.height(
                      context,
                      mobile: 4,
                      tablet: 6,
                    ),
                  ),
                  Text(
                    user?.role ?? 'Nahkoda',
                    style: TextStyle(
                      color: const Color(0xFF1B4F9C),
                      fontSize: ResponsiveHelper.font(
                        context,
                        mobile: 14,
                        tablet: 14,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final isTablet = ResponsiveHelper.isTablet(context);
    print('📊 [STATS] Building Stats Card - IsTablet: $isTablet');

    return Padding(
      padding: isTablet
          ? EdgeInsets.zero
          : ResponsiveHelper.paddingHorizontal(context, mobile: 16, tablet: 32),
      child: Container(
        padding: ResponsiveHelper.padding(context, mobile: 20, tablet: 20),
        decoration: BoxDecoration(
          color: isTablet ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.width(context, mobile: 16, tablet: 20),
          ),
          boxShadow: isTablet
              ? []
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: ResponsiveHelper.width(
                      context,
                      mobile: 10,
                      tablet: 14,
                    ),
                    offset: Offset(
                      0,
                      ResponsiveHelper.height(context, mobile: 2, tablet: 3),
                    ),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total Trip', '145', Icons.directions_boat_rounded),
            Container(
              width: ResponsiveHelper.width(context, mobile: 1, tablet: 2),
              height: ResponsiveHelper.height(context, mobile: 50, tablet: 60),
              color: Colors.grey[300],
            ),
            _buildStatItem('Total Tangkapan', '1.2 Ton', Icons.scale_rounded),
            Container(
              width: ResponsiveHelper.width(context, mobile: 1, tablet: 2),
              height: ResponsiveHelper.height(context, mobile: 50, tablet: 60),
              color: Colors.grey[300],
            ),
            _buildStatItem('Pengalaman', '8 Tahun', Icons.star_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF1B4F9C),
          size: ResponsiveHelper.width(context, mobile: 28, tablet: 26),
        ),
        SizedBox(
          height: ResponsiveHelper.height(context, mobile: 8, tablet: 8),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, mobile: 18, tablet: 16),
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4F9C),
          ),
        ),
        SizedBox(
          height: ResponsiveHelper.height(context, mobile: 4, tablet: 4),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveHelper.font(context, mobile: 11, tablet: 11),
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final shortestSide = size.shortestSide;
    final isTablet = ResponsiveHelper.isTablet(context); // FIX: Use ResponsiveHelper
    
    print('📋 [MENU] Building Menu Section:');
    print('   ScreenWidth: ${screenWidth.toStringAsFixed(1)}');
    print('   ShortestSide: ${shortestSide.toStringAsFixed(1)}');
    print('   IsTablet (ResponsiveHelper): $isTablet');
    print('   Layout: ${isTablet ? "GRID" : "LIST"}');

    return Padding(
      padding: isTablet ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, mobile: 16, tablet: 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveHelper.height(context, mobile: 8, tablet: 10)),
          isTablet ? _buildTabletMenuGrid() : _buildMobileMenuList(),
        ],
      ),
    );
  }

  Widget _buildMobileMenuList() {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.directions_boat_rounded,
          title: 'Informasi Kapal',
          subtitle: 'Kelola persediaan dan sertifikat',
          onTap: () => NavigationHelper.pushNoTransition(context, VesselInfoScreen()),
        ),
        SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.assessment_outlined,
          title: 'Laporan',
          subtitle: 'Lihat laporan statistik lengkap',
          onTap: () {
            Provider.of<NavigationProvider>(context, listen: false).setIndex(1);
          },
        ),
        SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.help_outline_rounded,
          title: 'Bantuan',
          subtitle: 'Pusat bantuan dan FAQ',
          onTap: () => NavigationHelper.pushNoTransition(context, const HelpScreen()),
        ),
        SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.info_outline_rounded,
          title: 'Tentang Aplikasi',
          subtitle: 'Versi 1.0',
          onTap: () {},
        ),
        const SizedBox(height: 24),
        _buildMenuItem(
          icon: Icons.logout_rounded,
          title: 'Keluar',
          subtitle: 'Keluar dari aplikasi',
          isLogout: true,
          onTap: () => _handleLogout(),
        ),
      ],
    );
  }

  Widget _buildTabletMenuGrid() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final menuItems = <Widget>[];

        menuItems.add(
          _buildMenuItem(
            icon: Icons.directions_boat_rounded,
            title: 'Informasi Kapal',
            subtitle: 'Kelola persediaan dan sertifikat',
            onTap: () => NavigationHelper.pushNoTransition(context, VesselInfoScreen()),
          ),
        );

        menuItems.addAll([
          _buildMenuItem(
            icon: Icons.settings,
            title: 'Pengaturan',
            subtitle: 'Kelola pengaturan aplikasi',
            onTap: () => NavigationHelper.pushNoTransition(context, const SettingsScreen()),
          ),
          _buildMenuItem(
            icon: Icons.assessment_outlined,
            title: 'Laporan',
            subtitle: 'Lihat laporan statistik lengkap',
            onTap: () {
              Provider.of<NavigationProvider>(
                context,
                listen: false,
              ).setIndex(1);
            },
          ),
          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            title: 'Bantuan',
            subtitle: 'Pusat bantuan dan FAQ',
            onTap: () => NavigationHelper.pushNoTransition(context, const HelpScreen()),
          ),
          _buildMenuItem(
            icon: Icons.info_outline_rounded,
            title: 'Tentang Aplikasi',
            subtitle: 'Versi 1.0',
            onTap: () {},
          ),
        ]);

        final isLandscape = ResponsiveHelper.isLandscape(context);
        final size = MediaQuery.of(context).size;
        final shortestSide = size.shortestSide;
        
        print('🏛️ [GRID] Building Menu Grid:');
        print('   IsLandscape: $isLandscape');
        print('   ShortestSide: ${shortestSide.toStringAsFixed(1)}');
        
        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: isLandscape ? 4.5 : (shortestSide < 800 ? 3.2 : 3.5),
            crossAxisSpacing: shortestSide < 800 ? 10 : 12,
            mainAxisSpacing: shortestSide < 800 ? 6 : 8,
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, i) => menuItems[i],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
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

    if (shouldLogout == true) {
      // Reset navigation ke home screen
      Provider.of<NavigationProvider>(context, listen: false).resetToHome();

      await AuthService.logout();
      if (mounted) {
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
  }

  void _showPhotoPreview(String photoUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: photoUrl.startsWith('file://')
                    ? Image.file(
                        File(photoUrl.replaceFirst('file://', '')),
                        fit: BoxFit.contain,
                      )
                    : Image.network(
                        photoUrl,
                        fit: BoxFit.contain,
                        headers: {'Cache-Control': 'no-cache'},
                      ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    final isSmallTablet = shortestSide < 800;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallTablet ? 12 : 16,
            vertical: isSmallTablet ? 10 : 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isSmallTablet ? 44 : 48,
                height: isSmallTablet ? 44 : 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isLogout
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFF1B4F9C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isLogout ? Colors.red : const Color(0xFF1B4F9C),
                  size: isSmallTablet ? 22 : 24,
                ),
              ),
              SizedBox(width: isSmallTablet ? 12 : 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isSmallTablet ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: isLogout ? Colors.red : Colors.black87,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: isSmallTablet ? 11 : 13,
                          color: Colors.grey[600],
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: isSmallTablet ? 14 : 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
