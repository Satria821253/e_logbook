import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Base URL untuk backend API
  static String get baseUrl => 
      dotenv.env['API_BASE_URL'] ?? 'https://elogbookipb.web.id/api';

  // ========== GEMINI AI ==========
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

  // ========== GOOGLE MAPS ==========
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // ========== OPENWEATHER ==========
  static String get openWeatherApiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';
}
