import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../config/api_config.dart';

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
  static const String _baseUrl =
      '${ApiConfig.geminiBaseUrl}/${ApiConfig.geminiModel}:generateContent';

  static Future<FishDetectionResult> detectFish(File image) async {
    try {
      final Uint8List imageBytes = await image.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // PROMPT OPTIMASI TINGGI
      final String prompt = """
Analisis gambar ikan ini dengan teliti dan berikan informasi dalam format JSON. PENTING: Gunakan bahasa Indonesia untuk semua field.

IDENTIFIKASI BERDASARKAN CIRI FISIK & UKURAN STANDAR:
- IKAN TONGKOL: Ukuran 15-30cm, tubuh torpedo PENDEK dan BULAT (seperti peluru), corak "batik" atau garis miring gelap di punggung belakang, perut putih bersih, TIDAK memiliki gigi tajam panjang
- IKAN TENGGIRI: Ukuran 30-60cm, tubuh sangat PANJANG dan PIPIH ke samping (seperti cerutu), memiliki GIGI tajam yang terlihat jelas (predator), garis-garis vertikal tipis samar di samping tubuh, warna abu-abu keperakan
- IKAN CAKALANG: Ukuran 25-40cm, tubuh torpedo, 4-6 garis horizontal gelap di perut/samping, punggung gelap
- IKAN KEMBUNG: Ukuran 12-20cm, tubuh pipih perak mengkilap, mata besar
- IKAN LAYANG: Ukuran 10-18cm, tubuh ramping perak, mata besar, ekor bercabang
- IKAN SELAR: Ukuran 15-25cm, mirip kembung tapi ada garis kuning di samping
- IKAN KAKAP: Ukuran 25-50cm, warna merah/pink, mulut besar
- IKAN KERAPU: Ukuran 30-60cm, tubuh tebal, mulut besar, warna belang-belang
- IKAN KUWE: Ukuran 40-80cm, tubuh tinggi pipih, warna keperakan
- IKAN BANDENG: Ukuran 20-35cm, perak mengkilap, mulut kecil, tubuh memanjang
- IKAN BAWAL: Ukuran 15-30cm, pipih bulat, perak, bentuk oval
- IKAN BARONANG: Ukuran 20-35cm, tubuh pipih, warna kuning/coklat, duri beracun
- CUMI-CUMI: Ukuran 15-40cm (termasuk tentakel), tubuh lunak, tentakel, mata besar
- UDANG: Ukuran 8-20cm, tubuh melengkung, antena panjang, kaki renang

PERBEDAAN KRITIS TONGKOL vs TENGGIRI:
- TONGKOL: Tubuh pendek bulat seperti peluru, corak batik di punggung, gigi kecil
- TENGGIRI: Tubuh panjang pipih seperti cerutu, garis vertikal tipis, gigi tajam besar
- UKURAN: Jika ikan terlihat sangat panjang (>35cm), kemungkinan besar TENGGIRI

PENTING - Format fishType:
- Tongkol, Cakalang, Tuna, Tenggiri: "Ikan Pelagis Besar"
- Kembung, Layang, Selar, Lemuru: "Ikan Pelagis Kecil"
- Kakap, Kerapu, Kuwe, Baronang: "Ikan Karang"
- Bandeng: "Ikan Air Payau"
- Bawal: "Ikan Laut"
- Cumi-cumi: "Moluska"
- Udang: "Krustasea"

ESTIMASI TINGGI/PANJANG BERDASARKAN PROPORSI TUBUH:
- Perhatikan proporsi kepala terhadap tubuh (kepala ikan umumnya 1/4-1/5 panjang total)
- Gunakan objek referensi jika ada (tangan manusia ~18-20cm)
- Bandingkan dengan ukuran standar species yang teridentifikasi
- Untuk ikan pipih (bawal, pari): ukur panjang terpanjang
- Untuk cumi-cumi: ukur dari ujung tubuh ke ujung tentakel

ESTIMASI BERAT BERDASARKAN UKURAN:
- Tongkol (15-30cm): 0.2-1.0kg per ekor
- Cakalang (25-40cm): 0.5-2.0kg per ekor
- Tuna (40-80cm): 2.0-15.0kg per ekor
- Kembung/Layang (10-20cm): 0.1-0.4kg per ekor
- Kakap/Kerapu (25-50cm): 0.8-4.0kg per ekor
- Cumi-cumi (15-40cm): 0.2-1.2kg per ekor
- Udang (8-20cm): 0.05-0.3kg per ekor

Jawab HANYA dengan JSON valid:
{
  "fishName": "string (nama Indonesia, contoh: Ikan Tongkol)",
  "fishType": "string (kategori dari daftar di atas)",
  "condition": "string (Segar/Cukup Segar/Kurang Segar)",
  "estimatedLength": number,
  "estimatedWeight": number,
  "estimatedQuantity": number,
  "confidence": number,
  "freshness": "string (deskripsi kesegaran)",
  "notes": "string (penjelasan identifikasi dan estimasi ukuran)"
}
""";

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
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl?key=${ApiConfig.geminiApiKey}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String? generatedText =
            responseData['candidates']?[0]['content']?['parts']?[0]['text'];

        if (generatedText == null) throw Exception('Respons AI kosong');

        // Extract JSON dengan lebih aman
        String jsonText = generatedText.trim();
        if (jsonText.contains('```')) {
          final regExp = RegExp(r'```(?:json)?([\s\S]*?)```');
          final match = regExp.firstMatch(jsonText);
          if (match != null) {
            jsonText = match.group(1)!.trim();
          }
        }

        final Map<String, dynamic> fishData = json.decode(jsonText);

        // Ekstraksi nilai dengan fallback
        double rawWeight = (fishData['estimatedWeight'] ?? 0.5).toDouble();
        double rawLength = (fishData['estimatedLength'] ?? 20.0).toDouble();
        int quantity = (fishData['estimatedQuantity'] ?? 1).toInt();
        String fishName = fishData['fishName'] ?? 'Ikan Tidak Teridentifikasi';

        // Normalisasi berat per ekor
        double unitWeight = _validateAndNormalizeWeight(
          rawWeight / quantity,
          rawLength,
          fishName,
        );

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
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      rethrow;
    }
  }

  static double _validateAndNormalizeWeight(double weightPerFish, double length, String fishName) {
    // Rasio berat (kg) per cm panjang - Data akurat dengan range tinggi yang diperluas
    Map<String, List<double>> speciesData = {
      // PELAGIS BESAR (High-value commercial fish)
      'tongkol': [0.012, 0.028],   // 15-30cm range
      'cakalang': [0.020, 0.045],  // 25-40cm range
      'tuna': [0.045, 0.180],      // 40-80cm+ range (expanded for large tuna)
      'tenggiri': [0.015, 0.040],  // 30-60cm range
      
      // PELAGIS KECIL (Volume tinggi, harga rendah)
      'layang': [0.007, 0.012],    // 10-18cm range
      'kembung': [0.009, 0.018],   // 12-20cm range
      'selar': [0.008, 0.014],     // 15-25cm range
      'lemuru': [0.007, 0.012],    // Similar to layang
      'siro': [0.006, 0.010],      // Small anchovy
      
      // IKAN KARANG & DEMERSAL (High-value)
      'kerapu': [0.035, 0.080],    // 30-60cm range - very dense
      'kakap': [0.025, 0.060],     // 25-50cm range
      'kuwe': [0.030, 0.070],      // 40-80cm range - large trevally
      'baronang': [0.020, 0.045],  // 20-35cm range
      'kurisi': [0.018, 0.035],    // Threadfin bream
      
      // LAINNYA
      'bandeng': [0.010, 0.025],   // 20-35cm range
      'bawal': [0.025, 0.055],     // 15-30cm range - flat but dense
      'pari': [0.015, 0.040],      // Variable size stingray
      
      // NON-FISH (dengan ukuran yang diperluas)
      'cumi': [0.005, 0.020],      // 15-40cm range (including tentacles)
      'udang': [0.003, 0.015],     // 8-20cm range (larger prawns)
      'kepiting': [0.008, 0.025],  // Variable size crabs
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
      debugPrint('⚖️ Koreksi: $fishName terlalu ringan → ${minWeight.toStringAsFixed(2)}kg');
      return minWeight;
    }
    if (weightPerFish > maxWeight) {
      debugPrint('⚖️ Koreksi: $fishName terlalu berat → ${maxWeight.toStringAsFixed(2)}kg');
      return maxWeight;
    }

    return weightPerFish;
  }
}
