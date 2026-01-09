import 'package:e_logbook/utils/responsive_helper.dart';
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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          ResponsiveHelper.height(
            context,
            mobile: 200,
            tablet: 250,
            mobileLandscape: 100,
            tabletLandscape: 120,
          ),
        ),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: Image.asset(
            "assets/bgipb.jpg",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: ResponsiveHelper.contentConstraints(context),
            child: Padding(
              padding: ResponsiveHelper.padding(
                context,
                mobile: 20,
                tablet: 32,
                mobileLandscape: 16,
                tabletLandscape: 24,
              ),
              child: Column(
                children: [
                  /// SCROLL AREA
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height: ResponsiveHelper.spacing(
                              context,
                              mobile: 20,
                              tablet: 40,
                              mobileLandscape: 12,
                              tabletLandscape: 16,
                            ),
                          ),

                          /// TITLE - font responsif
                          Text(
                            'Selamat Datang di E-Logbook',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.font(
                                context,
                                mobile: 26,
                                tablet: 32,
                                mobileLandscape: 20,
                                tabletLandscape: 24,
                              ),
                              height: 1.2,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),

                          SizedBox(
                            height: ResponsiveHelper.spacing(
                              context,
                              mobile: 30,
                              tablet: 50,
                              mobileLandscape: 16,
                              tabletLandscape: 30,
                            ),
                          ),

                          /// BUTTON MASUK - ukuran realistis di landscape
                          _SecondaryButton(
                            label: 'Masuk',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // foter
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: ResponsiveHelper.isLandscape(context)
                          ? ResponsiveHelper.spacing(
                              context,
                              mobile: 0,
                              tablet: 0,
                              mobileLandscape: 6,
                              tabletLandscape: 9,
                            )
                          : 0,
                    ),
                    child: const AppInfo(version: "1.0", releaseYear: "2025"),
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

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(
      ResponsiveHelper.width(
        context,
        mobile: 14,
        tablet: 20,
      ),
    );

    return SizedBox(
      width: ResponsiveHelper.buttonWidth(context),
      height: ResponsiveHelper.height(
        context,
        mobile: 52,
        tablet: 56,
        mobileLandscape: 38,
        tabletLandscape: 40,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: borderRadius, // ✅ INI YANG KURANG
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1B4F9C),
                  Color(0xFF2563EB),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveHelper.font(
                    context,
                    mobile: 18,
                    tablet: 20,
                    mobileLandscape: 16,
                    tabletLandscape: 17,
                  ),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
