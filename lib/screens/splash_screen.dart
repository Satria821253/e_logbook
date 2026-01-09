import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_logbook/screens/Login/welcome_screen.dart';
import 'package:e_logbook/screens/main_screen.dart';
import 'package:e_logbook/services/auth_service.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/models/user_model.dart';
import 'package:e_logbook/utils/responsive_helper.dart';

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

    final token = await AuthService.getToken();
    
    Widget nextScreen;
    if (token != null && token.isNotEmpty) {
      nextScreen = const MainScreen();
    } else {
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
              child: SingleChildScrollView(
                child: Padding(
                  padding: ResponsiveHelper.padding(
                    context,
                    mobile: 20,
                    tablet: 32,
                    mobileLandscape: 16,
                    tabletLandscape: 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// LOGO RESPONSIVE - ukuran menyesuaikan screen
                      Image.asset(
                        'assets/OIP.png',
                        width: ResponsiveHelper.imageSize(
                          context,
                          mobile: 200,
                          tablet: 280,
                          mobileLandscape: 140,
                          tabletLandscape: 180,
                        ),
                        height: ResponsiveHelper.imageSize(
                          context,
                          mobile: 200,
                          tablet: 280,
                          mobileLandscape: 140,
                          tabletLandscape: 180,
                        ),
                        fit: BoxFit.contain,
                      ),

                      SizedBox(
                        height: ResponsiveHelper.spacing(
                          context,
                          mobile: 20,
                          tablet: 30,
                          mobileLandscape: 12,
                          tabletLandscape: 16,
                        ),
                      ),

                      /// TEXT TITLE RESPONSIVE
                      Text(
                        'e-Logbook',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.font(
                            context,
                            mobile: 28,
                            tablet: 36,
                            mobileLandscape: 24,
                            tabletLandscape: 30,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),

                      SizedBox(
                        height: ResponsiveHelper.spacing(
                          context,
                          mobile: 8,
                          tablet: 12,
                          mobileLandscape: 6,
                          tabletLandscape: 8,
                        ),
                      ),

                      /// VERSION RESPONSIVE
                      Text(
                        'V1.0',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.font(
                            context,
                            mobile: 16,
                            tablet: 20,
                            mobileLandscape: 14,
                            tabletLandscape: 16,
                          ),
                          color: Colors.grey[600],
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
    );
  }
}