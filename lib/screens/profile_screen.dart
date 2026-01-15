import 'package:e_logbook/screens/Login/welcome_screen.dart';
import 'package:e_logbook/screens/page/edit_profile_screen.dart';
import 'package:e_logbook/screens/settings/settings_screen.dart';
import 'package:e_logbook/screens/help_screen.dart';

import 'package:e_logbook/screens/nahkoda/screens/crew_attendance_screen.dart';
import 'package:e_logbook/screens/vessel_info_screen.dart';
import 'package:e_logbook/services/getAPi/auth_service.dart';
import 'package:e_logbook/services/getAPi/profile_service.dart';
import 'package:e_logbook/services/getAPi/vessel_service.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/provider/navigation_provider.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _vesselName;
  String? _vesselNumber;
  bool _isLoadingVessel = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadVesselInfo();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await ProfileService.getProfile();
      if (result['success'] == true && result['user'] != null) {
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(result['user']);
        }
      }
    } catch (e) {
      // Clear corrupted cache if error occurs
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('user_profile');
      
      // Try to reload profile again
      try {
        final result = await ProfileService.getProfile();
        if (result['success'] == true && result['user'] != null && mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(result['user']);
        }
      } catch (e) {
        // Silent fail
      }
    }
  }

  Future<void> _loadVesselInfo() async {
    print('🚢 Starting to load vessel info...');
    setState(() => _isLoadingVessel = true);
    try {
      final vesselData = await VesselService().getVesselData();
      print('🚢 Vessel data received: $vesselData');
      
      if (mounted && vesselData['kapal'] != null) {
        final kapalInfo = vesselData['kapal'];
        print('🚢 Kapal info: $kapalInfo');
        print('🚢 Nama kapal: ${kapalInfo['namaKapal']}');
        print('🚢 Nomor registrasi: ${kapalInfo['nomorRegistrasi']}');
        
        setState(() {
          _vesselName = kapalInfo['namaKapal'];
          _vesselNumber = kapalInfo['nomorRegistrasi'];
        });
        
        print('🚢 State updated - Name: $_vesselName, Number: $_vesselNumber');
      } else {
        print('🚢 No kapal data in response');
      }
    } catch (e) {
      print('❌ Error loading vessel info: $e');
      // If error contains "Tidak ada kapal", it means user has no vessel assigned
      if (e.toString().contains('Tidak ada kapal')) {
        print('ℹ️ User has no vessel assigned');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingVessel = false);
        print('🚢 Loading finished');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);

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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
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
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      child: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  const SizedBox(height: 28),
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
    final isTablet = ResponsiveHelper.isTablet(context);
    
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.padding(
        context,
        mobile: 24,
        tablet: 0,
      ),
      color: isTablet ? Colors.transparent : Colors.transparent,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {},
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.width(
                      context,
                      mobile: 4,
                      tablet: 6,
                    ),
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black87,
                      width: ResponsiveHelper.width(context, mobile: 2, tablet: 3),
                    ),
                  ),
                  child: Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      final user = userProvider.user;
                      final photoUrl = user?.profilePicture;
                      final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
                      
                      return CircleAvatar(
                        radius: ResponsiveHelper.width(
                          context,
                          mobile: 50,
                          tablet: 60,
                        ),
                        backgroundColor: Colors.white,
                        backgroundImage: hasPhoto
                            ? (photoUrl.startsWith('file://')
                                ? FileImage(File(photoUrl.replaceFirst('file://', '')))
                                : NetworkImage(photoUrl)) as ImageProvider
                            : null,
                        child: !hasPhoto
                            ? Icon(
                                Icons.person_rounded,
                                size: ResponsiveHelper.width(
                                  context,
                                  mobile: 60,
                                  tablet: 72,
                                ),
                                color: Colors.black87,
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
            height: ResponsiveHelper.height(
              context,
              mobile: 16,
              tablet: 20,
            ),
          ),
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.user;
              return Column(
                children: [
                  Text(
                    user?.name ?? 'Budi Santoso',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: ResponsiveHelper.font(
                        context,
                        mobile: 24,
                        tablet: 28,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      ).then((_) => _loadProfile());
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.width(context, mobile: 12, tablet: 16),
                        vertical: ResponsiveHelper.height(context, mobile: 6, tablet: 8),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.width(context, mobile: 16, tablet: 20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            size: ResponsiveHelper.width(context, mobile: 14, tablet: 16),
                            color: Colors.black,
                          ),
                          SizedBox(width: ResponsiveHelper.width(context, mobile: 6, tablet: 8)),
                          Text(
                            'Edit Profil',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: ResponsiveHelper.font(context, mobile: 13, tablet: 15),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
                    '@${user?.username ?? 'username'}',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: ResponsiveHelper.font(
                        context,
                        mobile: 14,
                        tablet: 16,
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
                        tablet: 16,
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
    
    return Padding(
      padding: isTablet 
          ? EdgeInsets.zero
          : ResponsiveHelper.paddingHorizontal(
              context,
              mobile: 16,
              tablet: 32,
            ),
      child: Container(
        padding: ResponsiveHelper.padding(
          context,
          mobile: 20,
          tablet: 28,
        ),
        decoration: BoxDecoration(
          color: isTablet ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.width(context, mobile: 16, tablet: 20),
          ),
          boxShadow: isTablet ? [] : [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: ResponsiveHelper.width(
                context,
                mobile: 10,
                tablet: 14,
              ),
              offset: Offset(
                0,
                ResponsiveHelper.height(
                  context,
                  mobile: 2,
                  tablet: 3,
                ),
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
              height: ResponsiveHelper.height(
                context,
                mobile: 50,
                tablet: 60,
              ),
              color: Colors.grey[300],
            ),
            _buildStatItem('Total Tangkapan', '1.2 Ton', Icons.scale_rounded),
            Container(
              width: ResponsiveHelper.width(context, mobile: 1, tablet: 2),
              height: ResponsiveHelper.height(
                context,
                mobile: 50,
                tablet: 60,
              ),
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
          size: ResponsiveHelper.width(
            context,
            mobile: 28,
            tablet: 32,
          ),
        ),
        SizedBox(
          height: ResponsiveHelper.height(
            context,
            mobile: 8,
            tablet: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveHelper.font(
              context,
              mobile: 18,
              tablet: 20,
            ),
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4F9C),
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
          label,
          style: TextStyle(
            fontSize: ResponsiveHelper.font(
              context,
              mobile: 11,
              tablet: 13,
            ),
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          isTablet ? _buildTabletMenuGrid() : _buildMobileMenuList(),
        ],
      ),
    );
  }

  Widget _buildMobileMenuList() {
    return Column(
      children: [
        Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final user = userProvider.user;
            if (user?.isNahkoda == true) {
              return Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.directions_boat_rounded,
                    title: 'Informasi Kapal',
                    subtitle: 'Kelola persediaan dan sertifikat',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VesselInfoScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.people_outline_rounded,
                    title: 'Kehadiran Crew',
                    subtitle: 'Lihat kehadiran crew kapal',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CrewAttendanceScreen(),
                        ),
                      );
                    },
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.info_outline_rounded,
          title: 'Tentang Aplikasi',
          subtitle: 'Versi 1.0',
          onTap: () {},
        ),
        const SizedBox(height: 12),
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

        if (user?.isNahkoda == true) {
          menuItems.addAll([
            _buildMenuItem(
              icon: Icons.directions_boat_rounded,
              title: 'Informasi Kapal',
              subtitle: 'Kelola persediaan dan sertifikat',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VesselInfoScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.people_outline_rounded,
              title: 'Kehadiran Crew',
              subtitle: 'Lihat kehadiran crew kapal',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CrewAttendanceScreen(),
                  ),
                );
              },
            ),
          ]);
        }

        menuItems.addAll([
          _buildMenuItem(
            icon: Icons.settings,
            title: 'Pengaturan',
            subtitle: 'Kelola pengaturan aplikasi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.info_outline_rounded,
            title: 'Tentang Aplikasi',
            subtitle: 'Versi 1.0',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            title: 'Keluar',
            subtitle: 'Keluar dari aplikasi',
            isLogout: true,
            onTap: () => _handleLogout(),
          ),
        ]);

        final isLandscape = ResponsiveHelper.isLandscape(context);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: isLandscape ? 4.5 : 3.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
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
      await AuthService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const WelcomeScreen(),
          ),
          (route) => false,
        );
      }
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isLogout
                ? Colors.red.withOpacity(0.1)
                : const Color(0xFF1B4F9C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isLogout ? Colors.red : const Color(0xFF1B4F9C),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isLogout ? Colors.red : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
