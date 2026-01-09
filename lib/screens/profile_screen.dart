import 'package:e_logbook/screens/Login/welcome_screen.dart';
import 'package:e_logbook/screens/nahkoda/screens/crew_attendance_screen.dart';
import 'package:e_logbook/screens/vessel_info_screen.dart';
import 'package:e_logbook/services/auth_service.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _currentAddress = "Mengambil lokasi...";
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah GPS hidup
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      safeSetState(() {
        _currentAddress = "GPS mati";
        _isLoadingLocation = false;
      });
      return;
    }

    // Cek permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        safeSetState(() {
          _currentAddress = "Izin lokasi ditolak";
          _isLoadingLocation = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      safeSetState(() {
        _currentAddress = "Izin lokasi permanen ditolak";
        _isLoadingLocation = false;
      });
      return;
    }

    // Ambil posisi GPS
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Konversi ke alamat manusia
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    Placemark place = placemarks.first;

    safeSetState(() {
      _currentAddress =
          "${place.subLocality}, ${place.locality}, ${place.administrativeArea}";
      _isLoadingLocation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        centerTitle: true, // ← ini akan bekerja dengan benar
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 20, tablet: 28)),
            _buildStatsCard(),
            SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 20, tablet: 28)),
            _buildMenuSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.responsivePadding(context, mobile: 24, tablet: 32),
      color: Colors.transparent,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveHelper.responsiveWidth(context, mobile: 4, tablet: 6)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black87, width: 2.w),
            ),
            child: CircleAvatar(
              radius: ResponsiveHelper.responsiveWidth(context, mobile: 50, tablet: 60),
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person_rounded,
                size: ResponsiveHelper.responsiveWidth(context, mobile: 60, tablet: 72),
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 16, tablet: 20)),
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.user;
              return Text(
                user?.name ?? 'Budi Santoso',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 24, tablet: 28),
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 4, tablet: 6)),
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.user;
              return Text(
                user?.role ?? 'Nelayan Profesional',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16),
                ),
              );
            },
          ),
          SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 8, tablet: 12)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.responsiveWidth(context, mobile: 12, tablet: 16),
              vertical: ResponsiveHelper.responsiveHeight(context, mobile: 6, tablet: 8),
            ),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(ResponsiveHelper.responsiveWidth(context, mobile: 20, tablet: 24)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: Colors.black87,
                  size: ResponsiveHelper.responsiveWidth(context, mobile: 16, tablet: 18),
                ),
                SizedBox(width: ResponsiveHelper.responsiveWidth(context, mobile: 4, tablet: 6)),
                Flexible(
                  child: Text(
                    _isLoadingLocation ? "Mengambil lokasi..." : _currentAddress,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 12, tablet: 14),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Padding(
      padding: ResponsiveHelper.responsiveHorizontalPadding(context, mobile: 16, tablet: 32),
      child: Container(
        padding: ResponsiveHelper.responsivePadding(context, mobile: 20, tablet: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveHelper.responsiveWidth(context, mobile: 16, tablet: 20)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: ResponsiveHelper.responsiveWidth(context, mobile: 10, tablet: 14),
              offset: Offset(0, ResponsiveHelper.responsiveHeight(context, mobile: 2, tablet: 3)),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total Trip', '145', Icons.directions_boat_rounded),
            Container(
              width: 1.w,
              height: ResponsiveHelper.responsiveHeight(context, mobile: 50, tablet: 60),
              color: Colors.grey[300],
            ),
            _buildStatItem('Total Tangkapan', '1.2 Ton', Icons.scale_rounded),
            Container(
              width: 1.w,
              height: ResponsiveHelper.responsiveHeight(context, mobile: 50, tablet: 60),
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
          size: ResponsiveHelper.responsiveWidth(context, mobile: 28, tablet: 32),
        ),
        SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 8, tablet: 12)),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 18, tablet: 20),
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4F9C),
          ),
        ),
        SizedBox(height: ResponsiveHelper.responsiveHeight(context, mobile: 4, tablet: 6)),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 11, tablet: 13),
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
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
              } else if (user?.isABK == true) {
                return SizedBox.shrink(); // Hapus menu untuk ABK
              }
              return SizedBox.shrink();
            },
          ),
          _buildMenuItem(
            icon: Icons.assessment_outlined,
            title: 'Laporan',
            subtitle: 'Lihat laporan statistik lengkap',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.help_outline_rounded,
            title: 'Bantuan',
            subtitle: 'Pusat bantuan dan FAQ',
            onTap: () {},
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
            onTap: () async {
              // Show confirmation dialog
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
                // Remove token
                await AuthService.logout();

                // Navigate to welcome screen and clear all previous routes
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
            },
          ),
        ],
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
