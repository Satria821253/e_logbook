class ApiConfig {
  // API Key perusahaan dengan akses penuh
  static const String geminiApiKey = 'AIzaSyCJ_wLcrTEKXRjVKBlBUUV41kQiifDq4YM';

  // BASE URL untuk Gemini API
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // Model terbaru dan terbaik: Gemini 1.5 Flash
  static const String geminiModel = 'gemini-2.5-flash';

  // Timeout yang cukup untuk processing gambar
  static const Duration requestTimeout = Duration(seconds: 60);
}
