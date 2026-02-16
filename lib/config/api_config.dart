import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Base URL untuk backend API
  static String get baseUrl => 
      dotenv.env['API_BASE_URL'] ?? 'https://elogbookipb.web.id/api';

  // Load API Key from environment
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // BASE URL untuk Gemini API
  static String get geminiBaseUrl => 
      dotenv.env['GEMINI_BASE_URL'] ?? 
      'https://generativelanguage.googleapis.com/v1beta';

  // Model terbaru dan terbaik: Gemini 1.5 Flash
  static String get geminiModel => dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';

  // Timeout yang cukup untuk processing gambar
  static const Duration requestTimeout = Duration(seconds: 60);
}
