import 'package:dio/dio.dart';
import 'package:e_logbook/utils/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/Login/login_screen.dart';

class TokenInterceptor extends Interceptor {
  final BuildContext? context;

  TokenInterceptor({this.context});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final message = err.response?.data['message']?.toString().toLowerCase() ?? '';
      
      // Check if token expired
      if (message.contains('expired') || message.contains('invalid token')) {
        debugPrint('🔐 Token expired, logging out...');
        await _handleTokenExpired();
        return;
      }
    }
    
    handler.next(err);
  }

  Future<void> _handleTokenExpired() async {
    // Clear all stored data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('🧹 Cleared all data due to token expiration');

    // Navigate to login if context available
    if (context != null && context!.mounted) {
      NavigationHelper.pushAndRemoveUntilNoTransition(
        context!,
        const LoginScreen(),
        (route) => false,
      );
      
      // Show snackbar
      ScaffoldMessenger.of(context!).showSnackBar(
        const SnackBar(
          content: Text('Sesi Anda telah berakhir. Silakan login kembali.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
