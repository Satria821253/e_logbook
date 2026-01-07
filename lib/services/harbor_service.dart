import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class HarborSearchService {
  // Menggunakan Nominatim OpenStreetMap (FREE, NO API KEY)
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org/search';

  /// Search pelabuhan di Indonesia
  static Future<List<Map<String, dynamic>>> searchHarbors(String query) async {
    if (query.isEmpty || query.length < 3) {
      return [];
    }

    try {
      final url = Uri.parse(
        '$_nominatimUrl?'
        'q=$query pelabuhan'
        '&countrycodes=id'
        '&format=json'
        '&limit=10'
        '&addressdetails=1',
      );

      print('🔍 Harbor Search: $url');

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'E-LogbookApp/1.0 (nagarasatria104@gmail.com)',
          'Accept-Language': 'id',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;

        return data.map((place) {
          return {
            'name': place['display_name'].split(',')[0],
            'fullAddress': place['display_name'],
            'lat': double.parse(place['lat']),
            'lng': double.parse(place['lon']),
            'type': place['type'] ?? 'harbour',
            'importance': place['importance'] ?? 0.0,
          };
        }).toList();
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Harbor Search Error: $e');
      return [];
    }
  }

  /// Hitung jarak dari posisi saat ini
  static double calculateDistance({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng) / 1000; // km
  }

  /// Get pelabuhan terdekat
  static Map<String, dynamic>? findNearestHarbor({
    required List<Map<String, dynamic>> harbors,
    required double currentLat,
    required double currentLng,
  }) {
    if (harbors.isEmpty) return null;

    Map<String, dynamic>? nearest;
    double minDistance = double.infinity;

    for (var harbor in harbors) {
      final distance = calculateDistance(
        fromLat: currentLat,
        fromLng: currentLng,
        toLat: harbor['lat'],
        toLng: harbor['lng'],
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = {...harbor, 'distance': distance};
      }
    }

    return nearest;
  }

  /// Format harbor untuk display
  static String formatHarborName(Map<String, dynamic> harbor) {
    return harbor['name'] ?? 'Unknown Harbor';
  }

  static String formatHarborDetails(Map<String, dynamic> harbor) {
    String details = harbor['fullAddress'] ?? '';
    if (harbor.containsKey('distance')) {
      details += '\n${harbor['distance'].toStringAsFixed(2)} km dari lokasi Anda';
    }
    return details;
  }
}