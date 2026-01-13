import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_logbook/screens/Login/welcome_screen.dart';
import 'package:e_logbook/screens/main_screen.dart';
import 'package:e_logbook/services/getAPi/auth_service.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _navigateAfterDelay();
  }

  void _initAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    await _initializeUser();
    final nextScreen = await _determineNextScreen();
    _navigateToScreen(nextScreen);
  }

  Future<void> _initializeUser() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUser();
    
    if (userProvider.user == null) {
      final dummyUser = UserModel(
        id: 1,
        name: 'Budi Santoso',
        email: 'budi@example.com',
        phone: '081234567890',
        token: 'dummy_token',
        role: 'Nahkoda',
      );
      userProvider.setUser(dummyUser);
    }
  }

  Future<Widget> _determineNextScreen() async {
    final token = await AuthService.getToken();
    return (token != null && token.isNotEmpty) 
        ? const MainScreen() 
        : const WelcomeScreen();
  }

  void _navigateToScreen(Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => screen,
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final isLandscape = size.width > size.height;
    
    return Scaffold(
      body: _buildLayout(isTablet, isLandscape),
    );
  }

  Widget _buildLayout(bool isTablet, bool isLandscape) {
    if (!isTablet && !isLandscape) {
      return _buildMobilePortraitLayout();
    } else {
      return _buildHorizontalLayout(isTablet, isLandscape);
    }
  }

  Widget _buildMobilePortraitLayout() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF8FAFC)],
        ),
      ),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(false, false),
                  const SizedBox(height: 24),
                  _buildTitle(false, false),
                  const SizedBox(height: 8),
                  _buildVersion(false, false),
                  const SizedBox(height: 32),
                  _buildLoadingIndicator(false, false),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalLayout(bool isTablet, bool isLandscape) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF8FAFC)],
        ),
      ),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 400 : 300,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 40 : 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogo(isTablet, isLandscape),
                    SizedBox(height: isTablet ? 20 : 12),
                    _buildTitle(isTablet, isLandscape),
                    SizedBox(height: isTablet ? 8 : 4),
                    _buildVersion(isTablet, isLandscape),
                    SizedBox(height: isTablet ? 24 : 16),
                    _buildLoadingIndicator(isTablet, isLandscape),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isTablet, bool isLandscape) {
    final logoSize = isTablet ? 300.0 : (isLandscape ? 120.0 : 250.0);
    
    return Image.asset(
      'assets/OIP.png',
      width: logoSize,
      height: logoSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
          child: Icon(
            Icons.school,
            size: logoSize * 0.5,
            color: Colors.grey[600],
          ),
        );
      },
    );
  }

  Widget _buildTitle(bool isTablet, bool isLandscape) {
    final fontSize = isTablet ? 28.0 : (isLandscape ? 22.0 : 24.0);
    
    return Text(
      'e-Logbook',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1B4F9C),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildVersion(bool isTablet, bool isLandscape) {
    final fontSize = isTablet ? 14.0 : (isLandscape ? 11.0 : 12.0);
    final padding = isTablet ? 12.0 : (isLandscape ? 8.0 : 10.0);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding + 4,
        vertical: padding - 2,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Versi 1.0',
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(bool isTablet, bool isLandscape) {
    final size = isTablet ? 28.0 : (isLandscape ? 20.0 : 24.0);
    
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4F9C)),
      ),
    );
  }
}