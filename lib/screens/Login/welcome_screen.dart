import 'package:flutter/material.dart';
import 'package:e_logbook/screens/Login/login_screen.dart';
import 'package:e_logbook/widgets/app_info.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final isLandscape = size.width > size.height;
    
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Scaffold(
        body: _buildLayout(isTablet, isLandscape),
      ),
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
    return Column(
      children: [
        _buildHeader(false, false),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        _buildTitle(false, false),
                        const SizedBox(height: 32),
                        _buildLoginButton(false, false),
                      ],
                    ),
                  ),
                ),
                _buildFooter(false, false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(bool isTablet, bool isLandscape) {
    final imageFlex = isTablet ? 3 : 2;
    final contentFlex = isTablet ? 2 : 3;
    final maxWidth = isTablet ? 400.0 : 350.0;
    final padding = isTablet ? 40.0 : 24.0;
    
    return Stack(
      children: [
        Row(
          children: [
            // Left side - Image
            Expanded(
              flex: imageFlex,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/bgipb.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Right side - Spacer
            Expanded(
              flex: contentFlex,
              child: const SizedBox(),
            ),
          ],
        ),
        // White content container overlaying
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          left: MediaQuery.of(context).size.width * (imageFlex / (imageFlex + contentFlex)) - 30,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTitle(isTablet, isLandscape),
                      SizedBox(height: isTablet ? 40 : 24),
                      _buildLoginButton(isTablet, isLandscape),
                      SizedBox(height: isTablet ? 60 : 32),
                      _buildFooter(isTablet, isLandscape),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isTablet, bool isLandscape) {
    final height = isLandscape ? 120.0 : 300.0;
    
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/bgipb.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(bool isTablet, bool isLandscape) {
    final fontSize = isTablet ? 32.0 : (isLandscape ? 24.0 : 26.0);
    
    return Text(
      'Selamat Datang di\nE-Logbook',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.2,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1B4F9C),
      ),
    );
  }

  Widget _buildLoginButton(bool isTablet, bool isLandscape) {
    final height = isTablet ? 56.0 : (isLandscape ? 48.0 : 52.0);
    final fontSize = isTablet ? 20.0 : (isLandscape ? 16.0 : 18.0);
    final borderRadius = isTablet ? 16.0 : 14.0;
    final buttonWidth = isTablet ? 280.0 : (isLandscape ? 240.0 : double.infinity);
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
        child: Container(
          width: buttonWidth,
          height: height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Center(
            child: Text(
              'Masuk',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isTablet, bool isLandscape) {
    final bottomPadding = isTablet ? 0.0 : (isLandscape ? 8.0 : 16.0);
    
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: const AppInfo(version: "1.0", releaseYear: "2025"),
    );
  }
}