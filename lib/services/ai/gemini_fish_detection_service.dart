import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../config/api_config.dart';

class FishDetectionResult {
  final String fishName;
  final String fishType;
  final String condition;
  final double estimatedLength;
  final double estimatedHeight;
  final double estimatedWeight;
  final int estimatedQuantity;
  final double confidence;
  final String freshness;
  final double estimatedPrice;
  final String notes;
  final double unitWeight;

  FishDetectionResult({
    required this.fishName,
    required this.fishType,
    required this.condition,
    required this.estimatedLength,
    required this.estimatedHeight,
    required this.estimatedWeight,
    required this.estimatedQuantity,
    required this.confidence,
    required this.freshness,
    required this.estimatedPrice,
    this.notes = '',
    double? unitWeight,
  }) : unitWeight = unitWeight ?? (estimatedWeight / estimatedQuantity);
}

class GeminiFishDetectionService {
  static String get _baseUrl {
    // Format: https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent
    return '${ApiConfig.geminiBaseUrl}/models/${ApiConfig.geminiModel}:generateContent';
  }

  static Future<FishDetectionResult> detectFish(File image) async {
    try {
      debugPrint('\n🔍 ========== GEMINI AI DETECTION START ==========');
      debugPrint('📁 Image path: ${image.path}');
      
      // VALIDASI API KEY
      if (ApiConfig.geminiApiKey.isEmpty) {
        debugPrint('❌ GEMINI_API_KEY tidak ditemukan di .env file!');
        throw Exception('API Key Gemini tidak dikonfigurasi. Tambahkan GEMINI_API_KEY di file .env');
      }
      
      debugPrint('🔑 API Key: ${ApiConfig.geminiApiKey.substring(0, 10)}...${ApiConfig.geminiApiKey.substring(ApiConfig.geminiApiKey.length - 4)}');
      debugPrint('🤖 Model: ${ApiConfig.geminiModel}');
      debugPrint('🌐 Base URL: ${ApiConfig.geminiBaseUrl}');
      
      final Uint8List imageBytes = await image.readAsBytes();
      final fileSizeMB = (imageBytes.length / (1024 * 1024)).toStringAsFixed(2);
      debugPrint('📦 Image size: ${fileSizeMB}MB (${imageBytes.length} bytes)');
      
      final String base64Image = base64Encode(imageBytes);
      final base64SizeKB = (base64Image.length / 1024).toStringAsFixed(2);
      debugPrint('🔐 Base64 size: ${base64SizeKB}KB');

      // PROMPT SEDERHANA - FOKUS CIRI VISUAL JELAS
      final String prompt = """
Anda ahli identifikasi ikan Indonesia. PERHATIKAN DENGAN TELITI!

🔴 PERBEDAAN KRITIS KEMBUNG vs SELAR:

**KEMBUNG** (12-20cm):
- Tubuh OVAL LEBAR gemuk
- Sisik BESAR terlihat jelas
- Warna perak mengkilap
- ❌ TIDAK ADA GARIS KUNING di samping tubuh
- Jika TIDAK ada garis kuning = PASTI KEMBUNG

**SELAR** (15-25cm):
- Mirip kembung
- ✅ ADA GARIS KUNING TEGAS di samping dari kepala ke ekor
- Jika ADA garis kuning = PASTI SELAR

🔍 IKAN LAIN:

**LAYANG** (10-18cm):
- Tubuh LANGSING memanjang (bukan oval)
- Ekor bercabang SANGAT DALAM
- Lebih KURUS dari kembung

**TONGKOL** (15-30cm):
- Tubuh torpedo BULAT
- Corak gelap di punggung
- Perut putih

**TENGGIRI** (30-60cm):
- Tubuh PANJANG seperti cerutu
- GIGI TAJAM terlihat

**CAKALANG** (25-40cm):
- 4-6 GARIS HORIZONTAL di perut

⚠️ INSTRUKSI PENTING:
1. Lihat apakah ada GARIS KUNING di samping tubuh
2. Jika ADA garis kuning = SELAR
3. Jika TIDAK ada garis kuning + tubuh oval gemuk = KEMBUNG
4. Jangan asal tebak!

Jawab HANYA JSON (tanpa markdown):
{
  "fishName": "Ikan [Nama]",
  "fishType": "Ikan Pelagis Kecil",
  "condition": "Segar",
  "estimatedLength": 15,
  "estimatedWeight": 0.2,
  "estimatedQuantity": 1,
  "confidence": 0.9,
  "freshness": "Segar",
  "notes": "Ciri khas: [jelaskan apa yang terlihat]"
}
""";

      debugPrint('📝 Prompt length: ${prompt.length} chars');

      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {"mime_type": "image/jpeg", "data": base64Image},
              },
            ],
          },
        ],
        "generationConfig": {
          "temperature": 0.2,  // Lower = more consistent
          "topK": 20,
          "topP": 0.7,
          "maxOutputTokens": 1024,
        },
      };
      
      debugPrint('⚙️ Generation config: temp=0.4, topK=32, topP=0.8');

      final apiUrl = '$_baseUrl?key=${ApiConfig.geminiApiKey}';
      debugPrint('🌐 API URL: ${apiUrl.replaceAll(ApiConfig.geminiApiKey, "***KEY***")}');
      debugPrint('📤 Sending request to Gemini API...');
      
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(ApiConfig.requestTimeout);
      
      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ API Response OK');
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String? generatedText =
            responseData['candidates']?[0]['content']?['parts']?[0]['text'];

        if (generatedText == null) {
          debugPrint('❌ Empty AI response');
          throw Exception('Respons AI kosong');
        }
        
        debugPrint('📝 AI Response length: ${generatedText.length} chars');
        debugPrint('📄 FULL AI Response:');
        debugPrint(generatedText);
        debugPrint('=' * 60);

        // Extract JSON dengan lebih aman
        String jsonText = generatedText.trim();
        
        // Remove markdown code blocks
        if (jsonText.contains('```')) {
          final regExp = RegExp(r'```(?:json)?([\s\S]*?)```');
          final match = regExp.firstMatch(jsonText);
          if (match != null) {
            jsonText = match.group(1)!.trim();
          }
        }
        
        // Sanitize JSON - fix unterminated strings
        jsonText = _sanitizeJson(jsonText);
        
        debugPrint('🔧 Sanitized JSON:');
        debugPrint(jsonText);
        debugPrint('=' * 60);

        final Map<String, dynamic> fishData = json.decode(jsonText);
        debugPrint('✅ JSON parsed successfully');
        debugPrint('🐟 Detected fish: ${fishData['fishName']}');
        debugPrint('📊 Raw data: $fishData');

        // Ekstraksi nilai dengan fallback
        double rawWeight = (fishData['estimatedWeight'] ?? 0.5).toDouble();
        double rawLength = (fishData['estimatedLength'] ?? 20.0).toDouble();
        int quantity = (fishData['estimatedQuantity'] ?? 1).toInt();
        String fishName = fishData['fishName'] ?? 'Ikan Tidak Teridentifikasi';
        
        debugPrint('⚖️ Raw weight: ${rawWeight}kg, Length: ${rawLength}cm, Qty: $quantity');

        // Normalisasi berat per ekor
        double unitWeight = _validateAndNormalizeWeight(
          rawWeight / quantity,
          rawLength,
          fishName,
        );
        
        debugPrint('✅ Normalized unit weight: ${unitWeight.toStringAsFixed(2)}kg');
        debugPrint('✅ Total weight: ${(unitWeight * quantity).toStringAsFixed(2)}kg');
        debugPrint('========== GEMINI AI DETECTION SUCCESS ==========\n');

        return FishDetectionResult(
          fishName: fishName,
          fishType: fishData['fishType'] ?? 'Ikan Laut',
          condition: fishData['condition'] ?? 'Normal',
          estimatedLength: rawLength,
          estimatedHeight: rawLength * 0.3, // Estimasi tinggi ~30% dari panjang
          estimatedWeight: unitWeight * quantity,
          estimatedQuantity: quantity,
          confidence: (fishData['confidence'] ?? 0.0).toDouble(),
          freshness: fishData['freshness'] ?? 'Tidak terdeteksi',
          estimatedPrice: 0.0,
          notes: fishData['notes'] ?? 'Analisis visual AI selesai.',
          unitWeight: unitWeight,
        );
      } else {
        debugPrint('❌ ========== SERVER ERROR ${response.statusCode} ==========');
        debugPrint('📄 Full Response Body:');
        debugPrint(response.body);
        debugPrint('=' * 60);
        
        // Parse error message dari Gemini API
        String userFriendlyMessage = 'Error tidak diketahui';
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
          final errorStatus = errorData['error']?['status'];
          final errorCode = errorData['error']?['code'];
          final errorDetails = errorData['error']?['details'];
          
          debugPrint('🔴 Error Message: $errorMessage');
          debugPrint('🔴 Error Status: $errorStatus');
          debugPrint('🔴 Error Code: $errorCode');
          debugPrint('🔴 Error Details: $errorDetails');
          
          // Cek apakah ada reason di details
          String? errorReason;
          if (errorDetails != null && errorDetails is List && errorDetails.isNotEmpty) {
            errorReason = errorDetails[0]['reason'];
            debugPrint('🔴 Error Reason: $errorReason');
          }
          
          // Handle berbagai error code
          if (response.statusCode == 400) {
            userFriendlyMessage = '❌ Request tidak valid: $errorMessage';
            if (errorMessage.contains('API key')) {
              userFriendlyMessage = '❌ Format API Key salah. Periksa GEMINI_API_KEY di file .env';
            }
          } else if (response.statusCode == 403) {
            if (errorReason == 'CONSUMER_SUSPENDED') {
              userFriendlyMessage = '🚫 API Key telah DI-SUSPEND oleh Google!\n\n'
                  '📝 Solusi:\n'
                  '1. Buka: https://aistudio.google.com/app/apikey\n'
                  '2. Generate API Key BARU\n'
                  '3. Update GEMINI_API_KEY di file .env\n'
                  '4. Restart aplikasi';
            } else if (errorMessage.contains('API key not valid')) {
              userFriendlyMessage = '❌ API Key TIDAK VALID!\n\n'
                  '📝 Solusi:\n'
                  '1. Periksa GEMINI_API_KEY di file .env\n'
                  '2. Pastikan tidak ada spasi atau karakter tambahan\n'
                  '3. Generate key baru di: https://aistudio.google.com/app/apikey';
            } else {
              userFriendlyMessage = '🚫 Akses ditolak: $errorMessage';
            }
          } else if (response.statusCode == 429) {
            userFriendlyMessage = '⏱️ Quota API habis atau terlalu banyak request.\n'
                'Tunggu beberapa menit atau upgrade quota.';
          } else if (response.statusCode == 404) {
            userFriendlyMessage = '❌ Model "${ApiConfig.geminiModel}" tidak ditemukan!\n\n'
                '📝 Solusi:\n'
                '1. Ubah GEMINI_MODEL di .env menjadi: gemini-1.5-flash\n'
                '2. Model yang tersedia: gemini-1.5-flash, gemini-1.5-pro\n'
                '3. Restart aplikasi';
          } else if (response.statusCode == 500) {
            userFriendlyMessage = '🔧 Server Gemini sedang bermasalah. Coba lagi nanti.';
          } else {
            userFriendlyMessage = '❌ Error ${response.statusCode}: $errorMessage';
          }
          
        } catch (e) {
          debugPrint('⚠️ Could not parse error response: $e');
          userFriendlyMessage = '❌ Error ${response.statusCode}: ${response.body}';
        }
        
        debugPrint('========== GEMINI AI DETECTION FAILED ==========\n');
        throw Exception(userFriendlyMessage);
      }
    } catch (e) {
      debugPrint('❌ Exception caught: $e');
      debugPrint('📍 Stack trace: ${StackTrace.current}');
      debugPrint('========== GEMINI AI DETECTION ERROR ==========\n');
      rethrow;
    }
  }

  static String _sanitizeJson(String jsonText) {
    // Remove newlines and carriage returns
    jsonText = jsonText.replaceAll('\n', ' ');
    jsonText = jsonText.replaceAll('\r', '');
    jsonText = jsonText.trim();
    
    // Check if JSON is complete
    int openBraces = '{'.allMatches(jsonText).length;
    int closeBraces = '}'.allMatches(jsonText).length;
    
    debugPrint('🔍 JSON validation: { count=$openBraces, } count=$closeBraces');
    
    // If truncated, try to complete it
    if (openBraces > closeBraces) {
      debugPrint('⚠️ JSON truncated, attempting to fix...');
      
      // Find last complete field
      int lastComma = jsonText.lastIndexOf(',');
      int lastColon = jsonText.lastIndexOf(':');
      
      // If there's an incomplete field after last comma
      if (lastColon > lastComma) {
        // Find the field name
        int fieldStart = jsonText.lastIndexOf('"', lastColon - 1);
        if (fieldStart > 0) {
          int fieldNameStart = jsonText.lastIndexOf('"', fieldStart - 1);
          String fieldName = jsonText.substring(fieldNameStart + 1, fieldStart);
          debugPrint('⚠️ Incomplete field: $fieldName');
          
          // Check if value is started but not closed
          String afterColon = jsonText.substring(lastColon + 1).trim();
          if (afterColon.startsWith('"')) {
            // String value not closed, close it
            jsonText = jsonText.substring(0, lastColon) + ': ""';
            debugPrint('✅ Removed incomplete string field');
          } else {
            // Number or other value, remove the incomplete field
            jsonText = jsonText.substring(0, fieldNameStart);
            debugPrint('✅ Removed incomplete field');
          }
        }
      }
      
      // Remove trailing comma if exists
      jsonText = jsonText.trimRight();
      if (jsonText.endsWith(',')) {
        jsonText = jsonText.substring(0, jsonText.length - 1);
      }
      
      // Close all open braces
      while (openBraces > closeBraces) {
        jsonText += '}';
        closeBraces++;
      }
      
      debugPrint('✅ JSON fixed: $jsonText');
    }
    
    // Escape internal quotes in string values
    final fieldRegex = RegExp(r'"(\w+)"\s*:\s*"([^"]*?)"');
    jsonText = fieldRegex.allMatches(jsonText).fold(jsonText, (text, match) {
      String fieldName = match.group(1) ?? '';
      String value = match.group(2) ?? '';
      // Only escape if there are unescaped quotes
      if (value.contains('"') && !value.contains('\\"')) {
        value = value.replaceAll('"', '\\"');
        return text.replaceRange(
          match.start,
          match.end,
          '"$fieldName": "$value"',
        );
      }
      return text;
    });
    
    return jsonText;
  }

  static double _validateAndNormalizeWeight(
    double weightPerFish,
    double length,
    String fishName,
  ) {
    // Rasio berat (kg) per cm panjang - Data akurat dengan range tinggi yang diperluas
    Map<String, List<double>> speciesData = {
      // PELAGIS BESAR (High-value commercial fish)
      'tongkol': [0.012, 0.028], // 15-30cm range
      'cakalang': [0.020, 0.045], // 25-40cm range
      'tuna': [0.045, 0.180], // 40-80cm+ range (expanded for large tuna)
      'tenggiri': [0.015, 0.040], // 30-60cm range
      // PELAGIS KECIL (Volume tinggi, harga rendah)
      'layang': [0.007, 0.012], // 10-18cm range
      'kembung': [0.009, 0.018], // 12-20cm range
      'selar': [0.008, 0.014], // 15-25cm range
      'lemuru': [0.007, 0.012], // Similar to layang
      'siro': [0.006, 0.010], // Small anchovy
      // IKAN KARANG & DEMERSAL (High-value)
      'kerapu': [0.035, 0.080], // 30-60cm range - very dense
      'kakap': [0.025, 0.060], // 25-50cm range
      'kuwe': [0.030, 0.070], // 40-80cm range - large trevally
      'baronang': [0.020, 0.045], // 20-35cm range
      'kurisi': [0.018, 0.035], // Threadfin bream
      // LAINNYA
      'bandeng': [0.010, 0.025], // 20-35cm range
      'bawal': [0.025, 0.055], // 15-30cm range - flat but dense
      'pari': [0.015, 0.040], // Variable size stingray
      // NON-FISH (dengan ukuran yang diperluas)
      'cumi': [0.005, 0.020], // 15-40cm range (including tentacles)
      'udang': [0.003, 0.015], // 8-20cm range (larger prawns)
      'kepiting': [0.008, 0.025], // Variable size crabs
    };

    String fishKey = fishName.toLowerCase();
    double minRatio = 0.010; // Default konservatif
    double maxRatio = 0.040;

    // Cari species yang cocok
    for (String species in speciesData.keys) {
      if (fishKey.contains(species)) {
        minRatio = speciesData[species]![0];
        maxRatio = speciesData[species]![1];
        break;
      }
    }

    double minWeight = length * minRatio;
    double maxWeight = length * maxRatio;

    // Koreksi jika di luar range
    if (weightPerFish < minWeight) {
      debugPrint(
        '⚖️ Koreksi: $fishName terlalu ringan → ${minWeight.toStringAsFixed(2)}kg',
      );
      return minWeight;
    }
    if (weightPerFish > maxWeight) {
      debugPrint(
        '⚖️ Koreksi: $fishName terlalu berat → ${maxWeight.toStringAsFixed(2)}kg',
      );
      return maxWeight;
    }

    return weightPerFish;
  }
}
