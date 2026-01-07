import 'package:e_logbook/screens/Login/login_screen.dart';
import 'package:e_logbook/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// ---------------- RESPONSIVE FUNCTION ----------------

  double responsiveSize(BuildContext context, double size) {
    double width = MediaQuery.of(context).size.width;

    if (width >= 1000) return size * 1.6; // Desktop besar
    if (width >= 800) return size * 1.4; // Tablet landscape
    if (width >= 600) return size * 1.2; // Tablet kecil
    return size; // Standard HP
  }

  /// ------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    double font14 = responsiveSize(context, 14);
    double font12 = responsiveSize(context, 12);
    double spacing16 = responsiveSize(context, 16);
    double spacing12 = responsiveSize(context, 12);

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
            padding: EdgeInsets.symmetric(
              horizontal: responsiveSize(context, 22),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width > 600
                  ? 500 // Card width di tablet/desktop
                  : double.infinity,
              padding: EdgeInsets.all(responsiveSize(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset(
                        "assets/OIPT.png",
                        width: responsiveSize(context, 150),
                      ),
                    ),
                    SizedBox(height: spacing12),
                    Center(
                      child: Text(
                        'Selamat datang di Desa Babakan Asem',
                        style: TextStyle(color: Colors.grey, fontSize: font12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      height: 1,
                      margin: EdgeInsets.only(top: spacing12),
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: spacing16),

                    // ================== NAMA ======================
                    Text(
                      "Nama Lengkap",
                      style: TextStyle(
                        fontSize: font12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spacing12 / 2),
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => v == null || v.isEmpty
                          ? "Nama tidak boleh kosong"
                          : null,
                      decoration: _inputDecoration("Masukkan Nama Lengkap"),
                    ),
                    SizedBox(height: spacing16),

                    // ================== EMAIL ======================
                    Text(
                      "Email",
                      style: TextStyle(
                        fontSize: font12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spacing12 / 2),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration("Masukkan Email"),
                    ),
                    SizedBox(height: spacing16),

                    // ================== NOMOR ======================
                    Text(
                      "Nomor Telepon",
                      style: TextStyle(
                        fontSize: font12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spacing12 / 2),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration("Masukkan Nomor Telepon"),
                    ),
                    SizedBox(height: spacing16),

                    // ================== PASSWORD ======================
                    Text(
                      "Password",
                      style: TextStyle(
                        fontSize: font12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spacing12 / 2),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _passwordInputDecoration(
                        "Masukkan Password",
                        true,
                      ),
                    ),
                    SizedBox(height: spacing16),

                    // ========== CONFIRM PASSWORD ============
                    Text(
                      "Konfirmasi Password",
                      style: TextStyle(
                        fontSize: font12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spacing12 / 2),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: _passwordInputDecoration(
                        "Ulangi Password",
                        false,
                      ),
                    ),
                    SizedBox(height: spacing16),

                    // ========== REMEMBER ME ============
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                        ),
                        Text(
                          "Ingatkan Saya",
                          style: TextStyle(fontSize: font12),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing16),

                    // ========== BUTTON REGISTER ============
                    SizedBox(
                      width: double.infinity,
                      height: responsiveSize(context, 45),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: _isLoading ? null : () async {
                          if (_formKey.currentState!.validate()) {
                            if (_passwordController.text != _confirmPasswordController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password tidak cocok'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            setState(() {
                              _isLoading = true;
                            });
                            
                            debugPrint('Starting registration...');
                            final result = await AuthService.register(
                              name: _nameController.text,
                              email: _emailController.text,
                              phone: _phoneController.text,
                              password: _passwordController.text,
                              rememberMe: _rememberMe,
                            );
                            
                            debugPrint('Registration result: $result');
                            
                            if (result['success'] == true) {
                              // Show success dialog
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Registrasi Berhasil'),
                                    content: const Text('Akun Anda berhasil dibuat. Silakan masuk dengan akun yang baru dibuat.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const LoginScreen(),
                                            ),
                                          );
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? 'Registrasi gagal'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B4F9C), Color(0xFF2563EB)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    "Daftar Sekarang",
                                    style: TextStyle(
                                      fontSize: font14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: spacing12),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "Atau",
                            style: TextStyle(fontSize: font12),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    SizedBox(height: spacing12),

                    // ========== ALREADY HAVE ACCOUNT ============
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Sudah punya akun? ",
                          style: TextStyle(fontSize: font12),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Masuk di sini",
                            style: TextStyle(
                              fontSize: font12,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =================== Input Decorations =====================

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  InputDecoration _passwordInputDecoration(String hint, bool isPassword) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      suffixIcon: IconButton(
        icon: Icon(
          isPassword
              ? (_obscurePassword ? Icons.visibility_off : Icons.visibility)
              : (_obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility),
        ),
        onPressed: () {
          setState(() {
            if (isPassword) {
              _obscurePassword = !_obscurePassword;
            } else {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            }
          });
        },
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
