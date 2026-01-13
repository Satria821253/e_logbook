import 'dart:convert';
import 'package:e_logbook/screens/main_screen.dart';
import 'package:e_logbook/widgets/button_radio.dart';
import 'package:e_logbook/services/api_service.dart';
import 'package:e_logbook/models/user_model.dart';
import 'package:e_logbook/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ButtonRadioController _loginMethodController = ButtonRadioController();
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
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final isLandscape = size.width > size.height;
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _buildResponsiveLayout(isTablet, isLandscape),
    );
  }

  Widget _buildResponsiveLayout(bool isTablet, bool isLandscape) {
    // Mobile Portrait - Full gradient background
    if (!isTablet && !isLandscape) {
      return _buildMobilePortrait();
    }
    
    // Mobile Landscape atau Tablet - Split layout
    return _buildSplitLayout(isTablet, isLandscape);
  }

  // ==========================================
  // MOBILE PORTRAIT LAYOUT
  // ==========================================
  Widget _buildMobilePortrait() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildLoginCard(
                logoSize: 180,
                padding: 24,
                fontSize: 13,
                inputFontSize: 14,
                buttonHeight: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SPLIT LAYOUT (Landscape Mobile & Tablet)
  // ==========================================
  Widget _buildSplitLayout(bool isTablet, bool isLandscape) {
    final imageFlex = isTablet ? 5 : 3;
    final contentFlex = isTablet ? 5 : 7;
    
    return Stack(
      children: [
        Row(
          children: [
            // LEFT SIDE - Brand/Logo Section
            Expanded(
              flex: imageFlex,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 12 : 9),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo IPB dengan background putih lebih kecil
                          Container(
                            width: isTablet ? 180 : 120,
                            height: isTablet ? 180 : 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: isTablet ? 4 : 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Lottie.asset(
                                DateTime.now().hour >= 18 || DateTime.now().hour < 6
                                    ? 'assets/animations/tripmalam.json'
                                    : 'assets/animations/tripsiang.json',
                                width: isTablet ? 180 : 120,
                                height: isTablet ? 180 : 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: isTablet ? 24 : 16),
                          
                          // Title
                          Text(
                            'E-Logbook',
                            style: TextStyle(
                              fontSize: isTablet ? 32 : 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                          
                          SizedBox(height: isTablet ? 8 : 6),
                          
                          // Subtitle
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: isTablet ? 280 : 200,
                            ),
                            child: Text(
                              'Sistem Manajemen Logbook Digital untuk Pelayaran Modern',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 11,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.4,
                              ),
                            ),
                          ),
                          

                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // RIGHT SIDE - Spacer
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
          left: MediaQuery.of(context).size.width * (imageFlex / (imageFlex + contentFlex)) - 25,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32 : 20,
                    vertical: isTablet ? 40 : 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 480 : 380,
                    ),
                    child: _buildLoginCard(
                      logoSize: isTablet ? 220 : 90,
                      padding: isTablet ? 40 : 24,
                      fontSize: isTablet ? 14 : 12,
                      inputFontSize: isTablet ? 15 : 13,
                      buttonHeight: isTablet ? 54 : 46,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  // ==========================================
  // LOGIN CARD (Reusable)
  // ==========================================
  Widget _buildLoginCard({
    required double logoSize,
    required double padding,
    required double fontSize,
    required double inputFontSize,
    required double buttonHeight,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo IPB di dalam form (hanya untuk tablet)
          if (logoSize <= 90) ...[
            Center(
              child: Image.asset(
                "assets/OIPT.png",
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school,
                    size: logoSize * 0.5,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Logo IPB di dalam form (untuk mobile portrait)
          if (logoSize > 90) ...[
            Center(
              child: Image.asset(
                "assets/OIPT.png",
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school,
                    size: logoSize * 0.5,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
          
          // Welcome text dengan garis untuk semua ukuran
          Text(
            logoSize > 90 ? 'Selamat datang kembali di E-Logbook' : 'Hi Selamat Datang di E-Logbook',
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 1,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 15),
          
          // Email/Phone Label yang berubah sesuai pilihan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: ValueListenableBuilder<ButtonRadio>(
                  valueListenable: _loginMethodController,
                  builder: (context, value, _) {
                    return Text(
                      value == ButtonRadio.email ? "Email" : "No Telepon",
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    );
                  },
                ),
              ),
              ButtonRadioSelector(controller: _loginMethodController),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Input Field
          ValueListenableBuilder<ButtonRadio>(
            valueListenable: _loginMethodController,
            builder: (context, value, _) {
              return TextField(
                controller: _emailPhoneController,
                keyboardType: value == ButtonRadio.phone
                    ? TextInputType.number
                    : TextInputType.emailAddress,
                inputFormatters: value == ButtonRadio.phone
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : [],
                style: TextStyle(fontSize: inputFontSize),
                decoration: InputDecoration(
                  hintText: value == ButtonRadio.email
                      ? "contoh@email.com"
                      : "08123456789",
                  prefixIcon: Icon(
                    value == ButtonRadio.email ? Icons.email_outlined : Icons.phone_outlined,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1B4F9C), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Password Label
          Text(
            "Password",
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Password Field
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(fontSize: inputFontSize),
            decoration: InputDecoration(
              hintText: "Masukkan password",
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1B4F9C), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Remember & Forgot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: const Color(0xFF1B4F9C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => setState(() => _rememberMe = val ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text("Ingat saya", style: TextStyle(fontSize: fontSize - 1)),
                ],
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "Lupa password?",
                  style: TextStyle(
                    fontSize: fontSize - 1,
                    color: const Color(0xFF1B4F9C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Login Button
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4F9C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      "Masuk",
                      style: TextStyle(
                        fontSize: fontSize + 2,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
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
            MaterialPageRoute(builder: (context) => const MainScreen()),
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
  }
}