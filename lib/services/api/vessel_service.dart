import 'dart:convert';
import 'dart:io';
import 'package:e_logbook/services/realtime/realtime_update_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:shared_preferences/shared_preferences.dart';

class VesselService {
  static const String baseUrl = 'https://elogbookipb.web.id';

  Future<Map<String, dynamic>?> getVesselData({
    bool forceRefresh = false,
  }) async {
    try {
      print('\n========== getVesselData START ==========');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      // Ambil user data
      final userDataString = prefs.getString('user_data');
      int? currentUserId;
      String? actualRole;

      if (userDataString != null) {
        try {
          final userData = json.decode(userDataString);
          currentUserId = userData['id'];
          actualRole = userData['role'] ?? userData['user_role'] ?? userData['userRole'];
          print('📊 [DEBUG] user_data: $userData');
          print('👤 [DEBUG] Role: $actualRole, User ID: $currentUserId');
        } catch (e) {
          print('❌ Failed to parse user_data: $e');
        }
      }

      print('🎯 Role: $actualRole, Force refresh? $forceRefresh');

      // Prioritas 1: Cek trip aktif dulu
      print('🌐 Checking active trip...');
      final tripVessel = await _getVesselDataFromTrip(token, currentUserId, forceRefresh);
      
      if (tripVessel != null) {
        print('✅ Found vessel from active trip');
        return tripVessel;
      }
      
      // Prioritas 2: Ambil dari user settings jika tidak ada trip aktif
      print('🌐 No active trip, checking user settings...');
      return await _getVesselDataFromUserSettings(token, currentUserId);
    } catch (e) {
      print('❌ Error in getVesselData: $e');
      print('========== getVesselData END (ERROR) ==========\n');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getVesselDataFromUserSettings(
    String token,
    int? currentUserId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/user/$currentUserId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final userData = responseData['data'];
          final kapal = userData['kapal'];
          
          if (kapal != null) {
            print('✅ Found vessel from user settings');
            return {
              'kapal': {
                'id': kapal['id'],
                'namaKapal': kapal['namaKapal'],
                'nomorRegistrasi': kapal['nomorRegistrasi'],
              },
              'nahkoda': null, // Tidak ada info nahkoda dari settings
              'tripId': null,
              'tripStatus': null,
              'source': 'user_settings', // Marker untuk tahu dari mana datanya
            };
          }
        }
      }

      print('⚠️ No vessel found in user settings');
      return null;
    } catch (e) {
      print('❌ Error getting vessel from user settings: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getVesselDataFromTrip(
    String token,
    int? currentUserId,
    bool forceRefresh,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/trip'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final trips = responseData['data'] as List;

          if (trips.isNotEmpty) {
            Map<String, dynamic>? myActiveTrip;
            DateTime? latestUpdate;
            
            for (var trip in trips) {
              final nahkodaId = trip['nahkodaId'];
              final awakKapal = trip['awakKapal'] as List?;
              final status = trip['status']?.toString().toLowerCase();
              
              // Skip trip yang sudah selesai
              if (status == 'selesai' || status == 'completed') {
                continue;
              }
              
              // Cek apakah user adalah nahkoda atau crew
              final isNahkoda = currentUserId != null && nahkodaId == currentUserId;
              final isCrew = currentUserId != null && awakKapal != null && awakKapal.contains(currentUserId);
              
              if (isNahkoda || isCrew) {
                // Prioritaskan trip dengan status 'berlayar' atau 'sedang_melaut' (aktif tracking)
                if (status == 'berlayar' || status == 'sedang_melaut') {
                  myActiveTrip = trip;
                  break; // Langsung ambil yang sedang berlayar
                }
                
                // Jika belum ada trip atau trip ini lebih baru, simpan
                if (myActiveTrip == null) {
                  myActiveTrip = trip;
                  latestUpdate = DateTime.parse(trip['updatedAt'] ?? trip['createdAt']);
                } else {
                  final currentUpdate = DateTime.parse(trip['updatedAt'] ?? trip['createdAt']);
                  if (latestUpdate == null || currentUpdate.isAfter(latestUpdate)) {
                    myActiveTrip = trip;
                    latestUpdate = currentUpdate;
                  }
                }
              }
            }
            
            if (myActiveTrip == null) {
              return null;
            }
            
            final kapal = myActiveTrip['kapal'];
            final nahkoda = myActiveTrip['nahkoda'];

            return {
              'kapal': {
                'id': kapal['id'],
                'namaKapal': kapal['namaKapal'],
                'nomorRegistrasi': kapal['nomorRegistrasi'],
              },
              'nahkoda': nahkoda != null ? {
                'id': nahkoda['id'],
                'nama': nahkoda['nama'],
                'username': nahkoda['username'],
              } : null,
              'tripId': myActiveTrip['id'],
              'tripStatus': myActiveTrip['status'],
              'source': 'trip', // Marker untuk tahu dari mana datanya
            };
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
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

      final vesselData = await getVesselData();

      if (vesselData == null) {
        throw Exception('Tidak ada kapal yang di-assign.');
      }

      final kapalId = vesselData['kapal']['id'];

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/mobile/vessel/$kapalId/fuel-data'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['jenisBahanBakar'] = jenisBahanBakar;
      request.fields['jumlahLiter'] = jumlahLiter.toString();
      request.fields['hargaPerLiter'] = hargaPerLiter.toString();
      request.fields['totalHarga'] = totalHarga.toString();
      request.fields['tanggalPengisian'] = tanggalPengisian;
      request.fields['lokasiPengisian'] = lokasiPengisian ?? '';
      request.fields['keterangan'] = keterangan ?? '';

      if (buktiFilePath != null && buktiFilePath.isNotEmpty) {
        final file = File(buktiFilePath);
        if (await file.exists()) {
          String contentType = 'image/jpeg';
          if (buktiFilePath.toLowerCase().endsWith('.png')) {
            contentType = 'image/png';
          }

          request.files.add(
            await http.MultipartFile.fromPath(
              'bukti',
              buktiFilePath,
              contentType: http_parser.MediaType.parse(contentType),
            ),
          );
        }
      }

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal upload bahan bakar: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> uploadIceData({
    required String jenisEs,
    required double jumlahKg,
    required double hargaPerKg,
    required double totalHarga,
    required String tanggalPembelian,
    String? lokasiPembelian,
    String? keterangan,
    String? buktiFilePath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final vesselData = await getVesselData();

      if (vesselData == null) {
        throw Exception('Tidak ada kapal yang di-assign.');
      }

      final kapalId = vesselData['kapal']['id'];
      var url = '$baseUrl/api/mobile/vessel/$kapalId/ice-data';

      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['jenisEs'] = jenisEs;
      request.fields['jumlahKg'] = jumlahKg.toString();
      request.fields['hargaPerKg'] = hargaPerKg.toString();
      request.fields['totalHarga'] = totalHarga.toString();
      request.fields['tanggalPembelian'] = tanggalPembelian;

      if (lokasiPembelian != null && lokasiPembelian.isNotEmpty) {
        request.fields['lokasiPembelian'] = lokasiPembelian;
      }

      if (keterangan != null && keterangan.isNotEmpty) {
        request.fields['keterangan'] = keterangan;
      }

      if (buktiFilePath != null && buktiFilePath.isNotEmpty) {
        final file = File(buktiFilePath);
        if (await file.exists()) {
          String contentType = 'image/jpeg';
          if (buktiFilePath.toLowerCase().endsWith('.png')) {
            contentType = 'image/png';
          }

          request.files.add(
            await http.MultipartFile.fromPath(
              'bukti',
              buktiFilePath,
              contentType: http_parser.MediaType.parse(contentType),
            ),
          );
        }
      }

      var streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
      );
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        RealtimeUpdateService.notifyListeners('ice');
        return json.decode(response.body);
      } else {
        throw Exception('Gagal upload data es: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>?> getIceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final vesselData = await getVesselData();
      if (vesselData == null) {
        throw Exception('Tidak ada kapal yang di-assign.');
      }

      final kapalId = vesselData['kapal']['id'];
      final url = '$baseUrl/api/mobile/vessel/$kapalId/ice-data';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return responseData['data'];
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> updateBahanBakar({
    required String fuelId,
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

      final vesselData = await getVesselData();

      if (vesselData == null) {
        throw Exception('Tidak ada kapal yang di-assign.');
      }

      final kapalId = vesselData['kapal']['id'];
      final url = '$baseUrl/api/mobile/vessel/$kapalId/bahan-bakar/$fuelId';

      var request = http.MultipartRequest('PUT', Uri.parse(url));

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
          String contentType = 'image/jpeg';
          if (buktiFilePath.toLowerCase().endsWith('.png')) {
            contentType = 'image/png';
          }

          request.files.add(
            await http.MultipartFile.fromPath(
              'bukti',
              buktiFilePath,
              contentType: http_parser.MediaType.parse(contentType),
            ),
          );
        }
      }

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal update data BBM: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getVesselDocuments({
    bool forceRefresh = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final vesselData = await getVesselData(forceRefresh: forceRefresh);

      if (vesselData == null) {
        return {'sertifikatJalan': [], 'dataBahanBakar': []};
      }

      final kapalId = vesselData['kapal']['id'];
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/mobile/vessel/$kapalId/documents?t=$timestamp',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          return responseData['data'];
        }
        return {'sertifikatJalan': [], 'dataBahanBakar': []};
      } else {
        throw Exception('Gagal mengambil dokumen kapal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getFuelSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final vesselData = await getVesselData();

      if (vesselData == null) {
        throw Exception('Tidak ada kapal yang di-assign.');
      }

      final kapalId = vesselData['kapal']['id'];
      final url = '$baseUrl/mobile/vessel/$kapalId/fuel-summary';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          return responseData['data'];
        } else {
          throw Exception('Response success is false');
        }
      } else {
        throw Exception('Gagal mengambil ringkasan BBM: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> uploadVesselDocument({
    required String jenisDokumen,
    required String filePath,
    String? nomorSertifikat,
    String? tanggalBerlaku,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final vesselData = await getVesselData();
      if (vesselData == null) {
        throw Exception('Tidak ada kapal yang di-assign.');
      }

      final kapalId = vesselData['kapal']['id'];

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/mobile/vessel/$kapalId/documents'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['jenisDokumen'] = jenisDokumen;

      if (nomorSertifikat != null && nomorSertifikat.isNotEmpty) {
        request.fields['nomorSertifikat'] = nomorSertifikat;
      }

      if (tanggalBerlaku != null && tanggalBerlaku.isNotEmpty) {
        request.fields['tanggalBerlaku'] = tanggalBerlaku;
      }

      final file = File(filePath);
      if (await file.exists()) {
        String contentType = 'application/pdf';
        if (filePath.toLowerCase().endsWith('.jpg') ||
            filePath.toLowerCase().endsWith('.jpeg')) {
          contentType = 'image/jpeg';
        } else if (filePath.toLowerCase().endsWith('.png')) {
          contentType = 'image/png';
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            filePath,
            contentType: http_parser.MediaType.parse(contentType),
          ),
        );
      } else {
        throw Exception('File tidak ditemukan: $filePath');
      }

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          return result;
        } else {
          throw Exception(result['message'] ?? 'Upload gagal');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
