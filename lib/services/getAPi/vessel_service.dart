import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VesselService {
  static const String baseUrl = 'http://192.168.1.12:5000';

  Future<List<Map<String, dynamic>>> getVessels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/kapal'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Gagal mengambil data kapal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getVesselData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('🔑 Checking for token...');
      final token = prefs.getString('auth_token');
      print('🔑 Token found: ${token != null ? "YES (${token.substring(0, 20)}...)" : "NO"}');

      if (token == null) {
        // Debug: print all keys in SharedPreferences
        final keys = prefs.getKeys();
        print('🔑 Available keys in SharedPreferences: $keys');
        throw Exception('Token tidak ditemukan');
      }

      // Get list kapal dari /api/kapal
      final kapalResponse = await http.get(
        Uri.parse('$baseUrl/api/kapal'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (kapalResponse.statusCode != 200) {
        throw Exception('Gagal mengambil data kapal: ${kapalResponse.statusCode}');
      }

      final List<dynamic> kapalList = json.decode(kapalResponse.body);
      
      if (kapalList.isEmpty) {
        throw Exception('Tidak ada kapal yang di-assign ke user ini');
      }

      // Ambil kapal pertama dan return sebagai data
      final kapal = kapalList[0];
      
      return {
        'kapal': {
          'id': kapal['id'],
          'namaKapal': kapal['namaKapal'],
          'nomorRegistrasi': kapal['nomorRegistrasi'],
        },
        'nahkoda': kapal['nahkoda'],
      };
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> saveSelectedVessel(Map<String, dynamic> vessel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_vessel', json.encode(vessel));
  }

  Future<Map<String, dynamic>?> getSelectedVessel() async {
    final prefs = await SharedPreferences.getInstance();
    final vesselString = prefs.getString('selected_vessel');
    if (vesselString != null) {
      return json.decode(vesselString);
    }
    return null;
  }

  Future<Map<String, dynamic>> uploadBahanBakar({
    required String jenisBahanBakar,
    required double jumlahLiter,
    required double hargaPerLiter,
    required double totalHarga,
    required String tanggalPengisian,
    String? lokasiPengisian,
    String? keterangan,
    String? buktiFilePath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      // Get kapalId dari /api/kapal
      final kapalResponse = await http.get(
        Uri.parse('$baseUrl/api/kapal'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (kapalResponse.statusCode != 200) {
        throw Exception('Gagal mengambil data kapal: ${kapalResponse.statusCode}');
      }

      final List<dynamic> kapalList = json.decode(kapalResponse.body);
      
      if (kapalList.isEmpty) {
        throw Exception('Tidak ada kapal yang di-assign ke user ini');
      }

      final kapalId = kapalList[0]['id'];

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/mobile/vessel/$kapalId/bahan-bakar'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['jenisBahanBakar'] = jenisBahanBakar;
      request.fields['jumlahLiter'] = jumlahLiter.toString();
      request.fields['hargaPerLiter'] = hargaPerLiter.toString();
      request.fields['totalHarga'] = totalHarga.toString();
      request.fields['tanggalPengisian'] = tanggalPengisian;
      
      if (lokasiPengisian != null && lokasiPengisian.isNotEmpty) {
        request.fields['lokasiPengisian'] = lokasiPengisian;
      }
      
      if (keterangan != null && keterangan.isNotEmpty) {
        request.fields['keterangan'] = keterangan;
      }

      if (buktiFilePath != null && buktiFilePath.isNotEmpty) {
        final file = File(buktiFilePath);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('bukti', buktiFilePath),
          );
        }
      }

      final streamedResponse = await request.send().timeout(const Duration(minutes: 2));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result;
      } else {
        throw Exception('Gagal upload bahan bakar: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
