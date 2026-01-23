import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NetworkSecurityConfig {
  static Dio createSecureDio({
    required String baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout ?? const Duration(seconds: 30),
        receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    dio.interceptors.add(_SecurityInterceptor());
    
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }

    // TODO: Add certificate pinning for production
    // dio.httpClientAdapter = IOHttpClientAdapter(
    //   createHttpClient: () {
    //     final client = HttpClient();
    //     client.badCertificateCallback = (cert, host, port) {
    //       // Verify certificate fingerprint
    //       return _verifyCertificate(cert);
    //     };
    //     return client;
    //   },
    // );

    return dio;
  }

  // TODO: Implement certificate pinning
  // static bool _verifyCertificate(X509Certificate cert) {
  //   const expectedFingerprint = 'YOUR_CERT_FINGERPRINT';
  //   final certFingerprint = sha256.convert(cert.der).toString();
  //   return certFingerprint == expectedFingerprint;
  // }
}

class _SecurityInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add security headers
    options.headers['X-Requested-With'] = 'XMLHttpRequest';
    options.headers['X-App-Version'] = '1.0.0';
    
    // Prevent caching sensitive data
    if (options.path.contains('auth') || options.path.contains('user')) {
      options.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
      options.headers['Pragma'] = 'no-cache';
    }
    
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Don't expose internal error details in production
    if (!kDebugMode) {
      debugPrint('Network error: ${err.type}');
    }
    super.onError(err, handler);
  }
}
