import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/screens/crew/screens/create_catch_screen.dart';
import 'package:e_logbook/screens/nahkoda/widgets/nahkoda_floating_menu.dart';
import 'package:e_logbook/screens/nahkoda/widgets/nahkoda_tracking_button.dart';
import 'package:e_logbook/screens/crew/widgets/crew_floating_menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StatisticsScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  double rs(BuildContext context, double size) {
    double width = MediaQuery.of(context).size.width;

    if (width >= 1000) return size * 1.6;
    if (width >= 800) return size * 1.4;
    if (width >= 600) return size * 1.2;
    return size;
  }

  @override
  Widget build(BuildContext context) {
    double fabSize = rs(context, 70);
    double navHeight = rs(context, 65);
    double iconSize = rs(context, 26);
    double fontSize = rs(context, 11);

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final isABK = user?.isABK == true;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.white,

          body: Stack(
            children: [
              _screens[_selectedIndex],
              // Role-based floating menu
              if (!isABK) const NahkodaFloatingMenu(),
              if (isABK) const CrewFloatingMenu(),
            ],
          ),

          // FAB - role based
          floatingActionButton: isABK ? _buildCatchFAB(fabSize) : const NahkodaTrackingButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: rs(context, 10),
            elevation: 10,
            child: SizedBox(
              height: navHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, 'Beranda', 0, iconSize, fontSize),
                  _buildNavItem(Icons.bar_chart_rounded, 'Statistik', 1, iconSize, fontSize),
                  SizedBox(width: rs(context, 40)),
                  _buildNavItem(Icons.history_rounded, 'Riwayat', 2, iconSize, fontSize),
                  _buildNavItem(Icons.person_rounded, 'Profil', 3, iconSize, fontSize),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // NAVIGATION ITEM
  Widget _buildNavItem(IconData icon, String label, int index,
      double iconSize, double fontSize) {
    final bool isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => _onItemTapped(index),
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
            blurRadius: rs(context, 12),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateCatchScreen(),
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(
          Icons.add,
          size: rs(context, 36),
          color: Colors.white,
        ),
      ),
    );
  }
}