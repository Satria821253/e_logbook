import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Load API Key from environment
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // BASE URL untuk Gemini API
  static String get geminiBaseUrl => 
      dotenv.env['GEMINI_BASE_URL'] ?? 
      'https://generativelanguage.googleapis.com/v1beta/models';

  // Model terbaru dan terbaik: Gemini 1.5 Flash
  static String get geminiModel => dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash';

  // Timeout yang cukup untuk processing gambar
  static const Duration requestTimeout = Duration(seconds: 60);
}
