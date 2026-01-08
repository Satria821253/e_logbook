import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:e_logbook/screens/Login/login_screen.dart';
import 'package:e_logbook/screens/Login/register_screen.dart';
import 'package:e_logbook/widgets/app_info.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Responsive breakpoints
    final isTablet = MediaQuery.of(context).size.width > 600;
    final maxWidth = isTablet ? 500.0 : double.infinity;
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isTablet ? 250.h : 200.h),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: ClipRRect(
            child: Image.asset(
              "assets/bgipb.jpg",
              fit: BoxFit.cover,
              width: double.infinity,
              height: isTablet ? 250.h : 200.h,
            ),
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 40.w : 20.w,
              vertical: 20.h,
            ),
            child: Column(
              children: [
                /// SCROLL AREA
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: isTablet ? 40.h : 20.h),

                        /// TITLE
                        Text(
                          'Selamat Datang di E-Logbook',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: isTablet ? 32.sp : 28.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: isTablet ? 50.h : 30.h),

                        /// BUTTON DAFTAR
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const RegisterPage()),
                            );
                          },
                          child: Container(
                            height: isTablet ? 60.h : 50.h,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 57, 114, 199),
                                  Color(0xFF2563EB),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Text(
                              'Daftar',
                              style: TextStyle(
                                fontSize: isTablet ? 20.sp : 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: isTablet ? 20.h : 12.h),

                        /// BUTTON MASUK
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                            );
                          },
                          child: Container(
                            height: isTablet ? 60.h : 50.h,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              color: const Color(0xFFE0E0E0),
                            ),
                            child: Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: isTablet ? 20.sp : 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// FOOTER
                Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: AppInfo(version: "1.0", releaseYear: "2025"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
