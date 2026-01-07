import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:e_logbook/screens/Login/welcome_screen.dart';
import 'package:e_logbook/screens/main_screen.dart';
import 'package:e_logbook/services/auth_service.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToWelcomeScreen();
    });
  }

  Future<void> _navigateToWelcomeScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Load user data
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUser();

    // Set dummy user data if no user exists (for testing)
    if (userProvider.user == null) {
      final dummyUser = UserModel(
        id: 1,
        name: 'Budi Santoso',
        email: 'budi@example.com',
        phone: '081234567890',
        token: 'dummy_token',
        role: 'Nahkoda', // Default role
      );
      userProvider.setUser(dummyUser);
    }

    // Check if user is already logged in
    final token = await AuthService.getToken();

    Widget nextScreen;
    if (token != null && token.isNotEmpty) {
      // User has token, go to main screen
      nextScreen = MainScreen();
    } else {
      // No token, go to welcome screen
      nextScreen = const WelcomeScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// LOGO RESPONSIVE
                  Image.asset(
                    'assets/OIP.png',
                    width: 220.w, // otomatis menyesuaikan layar
                    height: 220.w, // pakai width supaya lebih stabil
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: 20.h),

                  /// TEXT TITLE RESPONSIVE
                  Text(
                    'e-Logbook',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),

                  SizedBox(height: 8.h),

                  /// VERSION RESPONSIVE
                  Text(
                    'V1.0',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
