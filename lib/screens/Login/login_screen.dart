import 'dart:convert';
import 'package:e_logbook/screens/Login/register_screen.dart';
import 'package:e_logbook/screens/main_screen.dart';
import 'package:e_logbook/widgets/button_radio.dart';
import 'package:e_logbook/services/api_service.dart';
import 'package:e_logbook/models/user_model.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ButtonRadioController _LoginScreenMethodController =
      ButtonRadioController();

  final TextEditingController _emailPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: 400.w), // aman untuk tablet
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// LOGO
                  Image.asset(
                    "assets/OIPT.png",
                    width: 150.w,
                    height: 150.w,
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: 10.h),

                  /// TITLE
                  Text(
                    'Selamat datang Kembali di E-Logbook',
                    style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                    textAlign: TextAlign.left,
                  ),

                  SizedBox(height: 5.h),
                  Container(height: 1.h, color: Colors.grey.shade400),
                  SizedBox(height: 15.h),

                  /// LABEL EMAIL/PHONE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Email",
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ButtonRadioSelector(
                        controller: _LoginScreenMethodController,
                      ),
                    ],
                  ),

                  SizedBox(height: 10.h),

                  /// FIELD EMAIL / PHONE
                  ValueListenableBuilder<ButtonRadio>(
                    valueListenable: _LoginScreenMethodController,
                    builder: (context, value, _) {
                      return TextField(
                        controller: _emailPhoneController,
                        keyboardType: value == ButtonRadio.phone
                            ? TextInputType.number
                            : TextInputType.emailAddress,
                        inputFormatters: value == ButtonRadio.phone
                            ? [FilteringTextInputFormatter.digitsOnly]
                            : [],
                        decoration: InputDecoration(
                          hintText: value == ButtonRadio.email
                              ? "Masukkan Email"
                              : "Masukkan No. Telepon",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 20.h),

                  /// LABEL PASSWORD
                  Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  /// FIELD PASSWORD
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: "Masukkan Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20.sp,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  /// REMEMBER + FORGOT PASSWORD
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: const Color.fromARGB(
                                255,
                                23,
                                124,
                                207,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? false;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            "Ingatkan Saya",
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "Lupa Password?",
                          style: TextStyle(
                            color: const Color.fromARGB(255, 23, 124, 207),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  /// BUTTON LOGIN
                  SizedBox(
                    width: double.infinity,
                    height: 45.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() {
                                _isLoading = true;
                              });

                              try {
                                final result = await ApiService.login(
                                  login: _emailPhoneController.text,
                                  password: _passwordController.text,
                                );

                                if (result['token'] != null) {
                                  // Save user data if available
                                  if (result['user'] != null) {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setString(
                                      'user_data',
                                      jsonEncode(result['user']),
                                    );

                                    // Create UserModel and set to provider
                                    final userData =
                                        result['user'] as Map<String, dynamic>;
                                    final userModel = UserModel(
                                      id: userData['id'],
                                      name: userData['name'],
                                      email: userData['email'],
                                      phone: userData['phone'],
                                      role: userData['role'],
                                      token: result['token'],
                                    );

                                    // Set user to provider (this will also save to UserService)
                                    if (mounted) {
                                      final userProvider =
                                          Provider.of<UserProvider>(
                                            context,
                                            listen: false,
                                          );
                                      await userProvider.setUser(userModel);
                                    }
                                  }

                                  if (mounted) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MainScreen(),
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result['message'] ??
                                              result['error'] ??
                                              'Login gagal',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Terjadi kesalahan koneksi',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }

                              setState(() {
                                _isLoading = false;
                              });
                            },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: _isLoading
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.h,
                                  child: const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Masuk",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 25.h),

                  /// GARIS PEMBATAS
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.grey, thickness: 0.5.h),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text("Atau", style: TextStyle(fontSize: 12.sp)),
                      ),
                      Expanded(
                        child: Divider(color: Colors.grey, thickness: 0.5.h),
                      ),
                    ],
                  ),

                  SizedBox(height: 25.h),

                  /// LINK REGISTER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Belum Punya Akun? ",
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: Text(
                          "Daftar di sini",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 15.h),

                  /// ABK LOGIN INFO
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Login sebagai ABK:",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "• rizki@abk.com / 123456 (Ahmad Rizki)",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          "• sari@abk.com / 123456 (Sari Dewi)",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          "• budi@abk.com / 123456 (Budi Santoso)",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 15.h),

                  /// NAHKODA LOGIN INFO
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Login sebagai Nahkoda:",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "• nahkoda1@email.com / 123456 (Kapten Joko)",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          "• nahkoda2@email.com / 123456 (Kapten Sari)",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          "• nahkoda3@email.com / 123456 (Kapten Budi)",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
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
