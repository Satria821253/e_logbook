import 'dart:convert';
import 'package:e_logbook/screens/main_screen.dart';
import 'package:e_logbook/widgets/button_radio.dart';
import 'package:e_logbook/services/api_service.dart';
import 'package:e_logbook/models/user_model.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:e_logbook/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            padding: ResponsiveHelper.paddingHorizontal(
              context,
              mobile: 20,
              tablet: 40,
              mobileLandscape: 16,
              tabletLandscape: 32,
            ),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.value(
                  context,
                  mobile: 400,
                  tablet: 500,
                ),
              ),
              padding: ResponsiveHelper.padding(
                context,
                mobile: 20,
                tablet: 28,
                mobileLandscape: 16,
                tabletLandscape: 24,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.width(
                    context,
                    mobile: 16,
                    tablet: 20,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// LOGO - ukuran responsif
                  Center(
                    child: Image.asset(
                      "assets/OIPT.png",
                      width: ResponsiveHelper.imageSize(
                        context,
                        mobile: 120,
                        tablet: 160,
                        mobileLandscape: 80,
                        tabletLandscape: 100,
                      ),
                      height: ResponsiveHelper.imageSize(
                        context,
                        mobile: 120,
                        tablet: 160,
                        mobileLandscape: 80,
                        tabletLandscape: 100,
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(
                    height: ResponsiveHelper.spacing(
                      context,
                      mobile: 10,
                      tablet: 16,
                      mobileLandscape: 8,
                      tabletLandscape: 12,
                    ),
                  ),

                  /// TITLE
                  Text(
                    'Selamat datang Kembali di E-Logbook',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: ResponsiveHelper.font(
                        context,
                        mobile: 12,
                        tablet: 14,
                        mobileLandscape: 11,
                        tabletLandscape: 13,
                      ),
                    ),
                    textAlign: TextAlign.left,
                  ),

                  SizedBox(
                    height: ResponsiveHelper.spacing(
                      context,
                      mobile: 5,
                      tablet: 8,
                      mobileLandscape: 4,
                      tabletLandscape: 6,
                    ),
                  ),
                  
                  Container(
                    height: 1,
                    color: Colors.grey.shade400,
                  ),
                  
                  SizedBox(
                    height: ResponsiveHelper.spacing(
                      context,
                      mobile: 15,
                      tablet: 20,
                      mobileLandscape: 10,
                      tabletLandscape: 12,
                    ),
                  ),

                  /// LABEL EMAIL/PHONE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Email",
                        style: TextStyle(
                          fontSize: ResponsiveHelper.font(
                            context,
                            mobile: 12,
                            tablet: 14,
                            mobileLandscape: 11,
                            tabletLandscape: 13,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ButtonRadioSelector(
                        controller: _LoginScreenMethodController,
                      ),
                    ],
                  ),

                  SizedBox(
                    height: ResponsiveHelper.spacing(
                      context,
                      mobile: 10,
                      tablet: 12,
                      mobileLandscape: 8,
                      tabletLandscape: 10,
                    ),
                  ),

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
                        style: TextStyle(
                          fontSize: ResponsiveHelper.font(
                            context,
                            mobile: 13,
                            tablet: 15,
                            mobileLandscape: 12,
                            tabletLandscape: 14,
                          ),
                        ),
                        decoration: InputDecoration(
                          hintText: value == ButtonRadio.email
                              ? "Masukkan Email"
                              : "Masukkan No. Telepon",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.width(
                                context,
                                mobile: 8,
                                tablet: 10,
                              ),
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.width(
                              context,
                              mobile: 12,
                              tablet: 16,
                            ),
                            vertical: ResponsiveHelper.height(
                              context,
                              mobile: 10,
                              tablet: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(
                    height: ResponsiveHelper.spacing(
                      context,
                      mobile: 15,
                      tablet: 20,
                      mobileLandscape: 10,
                      tabletLandscape: 12,
                    ),
                  ),

                  /// LABEL PASSWORD
                  Text(
                    'Password',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(
                        context,
                        mobile: 12,
                        tablet: 14,
                        mobileLandscape: 11,
                        tabletLandscape: 13,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(
                    height: ResponsiveHelper.spacing(
                      context,
                      mobile: 8,
                      tablet: 10,
                      mobileLandscape: 6,
                      tabletLandscape: 8,
                    ),
                  ),

                  /// FIELD PASSWORD
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.font(
                        context,
                        mobile: 13,
                        tablet: 15,
                        mobileLandscape: 12,
                        tabletLandscape: 14,
                      ),
                    ),
                    decoration: InputDecoration(
                      hintText: "Masukkan Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.width(
                            context,
                            mobile: 8,
                            tablet: 10,
                          ),
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: ResponsiveHelper.imageSize(
                            context,
                            mobile: 20,
                            tablet: 24,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.width(
                          context,
                          mobile: 12,
                          tablet: 16,
                        ),
                        vertical: ResponsiveHelper.height(
                          context,
                          mobile: 10,
                          tablet: 12,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    height: ResponsiveHelper.spacing(
                      context,
                      mobile: 10,
                      tablet: 12,
                      mobileLandscape: 8,
                      tabletLandscape: 10,
                    ),
                  ),

                  /// REMEMBER + FORGOT PASSWORD
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: ResponsiveHelper.imageSize(
                              context,
                              mobile: 18,
                              tablet: 22,
                            ),
                            height: ResponsiveHelper.imageSize(
                              context,
                              mobile: 18,
                              tablet: 22,
                            ),
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: const Color.fromARGB(255, 23, 124, 207),
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? false;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: ResponsiveHelper.width(
                              context,
                              mobile: 5,
                              tablet: 8,
                            ),
                          ),
                          Text(
                            "Ingatkan Saya",
                            style: TextStyle(
                              fontSize: ResponsiveHelper.font(
                                context,
                                mobile: 12,
                                tablet: 13,
                                mobileLandscape: 11,
                                tabletLandscape: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "Lupa Password?",
                          style: TextStyle(
                            color: const Color.fromARGB(255, 23, 124, 207),
                            fontSize: ResponsiveHelper.font(
                              context,
                              mobile: 12,
                              tablet: 13,
                              mobileLandscape: 11,
                              tabletLandscape: 12,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: ResponsiveHelper.spacing(
                      context,
                      mobile: 15,
                      tablet: 20,
                      mobileLandscape: 10,
                      tabletLandscape: 12,
                    ),
                  ),

                  /// BUTTON LOGIN - ukuran widget responsif
                  SizedBox(
                    width: double.infinity,
                    height: ResponsiveHelper.height(
                      context,
                      mobile: 45,
                      tablet: 52,
                      mobileLandscape: 40,
                      tabletLandscape: 45,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.width(
                              context,
                              mobile: 8,
                              tablet: 10,
                            ),
                          ),
                        ),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: _isLoading ? null : () async {
                        setState(() => _isLoading = true);
                        
                        try {
                          final result = await ApiService.login(
                            login: _emailPhoneController.text,
                            password: _passwordController.text,
                          );
                          
                          if (result['token'] != null) {
                            if (result['user'] != null) {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('user_data', jsonEncode(result['user']));
                              
                              final userData = result['user'] as Map<String, dynamic>;
                              final userModel = UserModel(
                                id: userData['id'],
                                name: userData['name'],
                                email: userData['email'],
                                phone: userData['phone'],
                                role: userData['role'],
                                token: result['token'],
                              );
                              
                              if (mounted) {
                                final userProvider = Provider.of<UserProvider>(context, listen: false);
                                await userProvider.setUser(userModel);
                              }
                            }
                            
                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MainScreen(),
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? result['error'] ?? 'Login gagal'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Terjadi kesalahan koneksi'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                        
                        setState(() => _isLoading = false);
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.width(
                              context,
                              mobile: 8,
                              tablet: 10,
                            ),
                          ),
                        ),
                        child: Center(
                          child: _isLoading
                              ? SizedBox(
                                  height: ResponsiveHelper.imageSize(
                                    context,
                                    mobile: 20,
                                    tablet: 24,
                                  ),
                                  width: ResponsiveHelper.imageSize(
                                    context,
                                    mobile: 20,
                                    tablet: 24,
                                  ),
                                  child: const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Masuk",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveHelper.font(
                                      context,
                                      mobile: 14,
                                      tablet: 16,
                                      mobileLandscape: 13,
                                      tabletLandscape: 15,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    height: ResponsiveHelper.spacing(
                      context,
                      mobile: 20,
                      tablet: 25,
                      mobileLandscape: 12,
                      tabletLandscape: 16,
                    ),
                  ),

                  /// GARIS PEMBATAS
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.width(
                            context,
                            mobile: 8,
                            tablet: 12,
                          ),
                        ),
                        child: Text(
                          "Atau",
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(
                              context,
                              mobile: 12,
                              tablet: 13,
                              mobileLandscape: 11,
                              tabletLandscape: 12,
                            ),
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                    ],
                  ),

                  SizedBox(
                    height: ResponsiveHelper.spacing(
                      context,
                      mobile: 20,
                      tablet: 25,
                      mobileLandscape: 12,
                      tabletLandscape: 16,
                    ),
                  ),

                  /// LINK REGISTER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Belum Punya Akun? ",
                        style: TextStyle(
                          fontSize: ResponsiveHelper.font(
                            context,
                            mobile: 12,
                            tablet: 13,
                            mobileLandscape: 11,
                            tabletLandscape: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: ResponsiveHelper.spacing(
                      context,
                      mobile: 15,
                      tablet: 20,
                      mobileLandscape: 10,
                      tabletLandscape: 12,
                    ),
                  ),

                  /// ABK LOGIN INFO - Compact di landscape
                  Container(
                    padding: EdgeInsets.all(
                      ResponsiveHelper.width(
                        context,
                        mobile: 12,
                        tablet: 16,
                        mobileLandscape: 8,
                        tabletLandscape: 10,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.width(
                          context,
                          mobile: 8,
                          tablet: 10,
                        ),
                      ),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Login sebagai ABK:",
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(
                              context,
                              mobile: 11,
                              tablet: 12,
                              mobileLandscape: 10,
                              tabletLandscape: 11,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveHelper.spacing(
                            context,
                            mobile: 3,
                            tablet: 4,
                            mobileLandscape: 2,
                            tabletLandscape: 3,
                          ),
                        ),
                        Text(
                          "• rizki@abk.com / 123456",
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(
                              context,
                              mobile: 9,
                              tablet: 10,
                              mobileLandscape: 8,
                              tabletLandscape: 9,
                            ),
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          "• sari@abk.com / 123456",
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(
                              context,
                              mobile: 9,
                              tablet: 10,
                              mobileLandscape: 8,
                              tabletLandscape: 9,
                            ),
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          "• budi@abk.com / 123456",
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(
                              context,
                              mobile: 9,
                              tablet: 10,
                              mobileLandscape: 8,
                              tabletLandscape: 9,
                            ),
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: ResponsiveHelper.spacing(
                      context,
                      mobile: 10,
                      tablet: 12,
                      mobileLandscape: 6,
                      tabletLandscape: 8,
                    ),
                  ),

                  /// NAHKODA LOGIN INFO - Compact di landscape
                  Container(
                    padding: EdgeInsets.all(
                      ResponsiveHelper.width(
                        context,
                        mobile: 12,
                        tablet: 16,
                        mobileLandscape: 8,
                        tabletLandscape: 10,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.width(
                          context,
                          mobile: 8,
                          tablet: 10,
                        ),
                      ),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Login sebagai Nahkoda:",
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(
                              context,
                              mobile: 11,
                              tablet: 12,
                              mobileLandscape: 10,
                              tabletLandscape: 11,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveHelper.spacing(
                            context,
                            mobile: 3,
                            tablet: 4,
                            mobileLandscape: 2,
                            tabletLandscape: 3,
                          ),
                        ),
                        Text(
                          "• nahkoda1@email.com / 123456",
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(
                              context,
                              mobile: 9,
                              tablet: 10,
                              mobileLandscape: 8,
                              tabletLandscape: 9,
                            ),
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          "• nahkoda2@email.com / 123456",
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(
                              context,
                              mobile: 9,
                              tablet: 10,
                              mobileLandscape: 8,
                              tabletLandscape: 9,
                            ),
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          "• nahkoda3@email.com / 123456",
                          style: TextStyle(
                            fontSize: ResponsiveHelper.font(
                              context,
                              mobile: 9,
                              tablet: 10,
                              mobileLandscape: 8,
                              tabletLandscape: 9,
                            ),
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