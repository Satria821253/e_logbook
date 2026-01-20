import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:shared_preferences/shared_preferences.dart';

class VesselService {
  static const String baseUrl = 'http://210.79.191.17:5000';

  Future<Map<String, dynamic>> checkAssignmentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/mobile/vessels/assignment-status'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal cek status assignment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMyVessels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/mobile/vessels/my-vessel'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          return data.cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        throw Exception('Gagal mengambil data kapal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getVessels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/kapal'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

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

      // Ambil role dari user_data
      final userDataString = prefs.getString('user_data');
      String? actualRole;
      
      if (userDataString != null) {
        try {
          final userData = json.decode(userDataString);
          actualRole = userData['role'] ?? userData['user_role'] ?? userData['userRole'];
          print('📊 [DEBUG] user_data: $userData');
          print('👤 [DEBUG] Role extracted: $actualRole');
        } catch (e) {
          print('❌ Failed to parse user_data: $e');
        }
      }
      
      final isCrewRole = actualRole == 'ABK' || actualRole == 'crew' || actualRole == 'Crew';
      print('🎯 Role: $actualRole, Is crew? $isCrewRole, Force refresh? $forceRefresh');

      // Gunakan cache jika ada (untuk semua role)
      if (!forceRefresh) {
        final vesselDataString = prefs.getString('vessel_data');
        if (vesselDataString != null) {
          print('💾 Found cached vessel_data');
          final cachedData = json.decode(vesselDataString);
          print('📋 [CACHE] Kapal: ${cachedData['kapal']}');
          print('📋 [CACHE] Nahkoda: ${cachedData['nahkoda']}');
          
          // Jika crew dan cache tidak punya nahkoda, fetch ulang
          if (isCrewRole && cachedData['nahkoda'] == null) {
            print('⚠️ [CREW] Cache tidak punya nahkoda, fetch dari API...');
          } else {
            print('✅ Using cache');
            print('========== getVesselData END (CACHE) ==========\n');
            return cachedData;
          }
        } else {
          print('💾 No cache found');
        }
      } else {
        print('🔄 Force refresh enabled, skipping cache');
      }

      // Fetch dari API
      print('🌐 Fetching from API...');
      final vesselResponse = await http.get(
        Uri.parse('$baseUrl/api/mobile/vessels/my-vessel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 API Response status: ${vesselResponse.statusCode}');

      if (vesselResponse.statusCode == 200) {
        final responseData = json.decode(vesselResponse.body);
        print('📥 API Response success: ${responseData['success']}');
        
        if (responseData['success'] == true) {
          final vessels = responseData['data'] as List;
          print('🚢 Vessels count: ${vessels.length}');
          
          if (vessels.isNotEmpty) {
            final kapal = vessels[0];
            final vesselId = kapal['id'];
            print('🚢 Vessel ID: $vesselId');
            print('🚢 Vessel name: ${kapal['namaKapal']}');
            print('🚢 Nahkoda from my-vessel: ${kapal['nahkoda']}');
            
            // Untuk crew, ambil detail lengkap
            if (isCrewRole) {
              print('👥 [CREW] Fetching detailed data with nahkoda...');
              final detailData = await getVesselById(vesselId);
              
              if (detailData != null) {
                final vesselData = {
                  'kapal': {
                    'id': detailData['id'],
                    'namaKapal': detailData['namaKapal'],
                    'nomorRegistrasi': detailData['nomorRegistrasi'],
                  },
                  'nahkoda': detailData['nahkoda'],
                };
                
                print('💾 [CREW] Saving to cache with nahkoda: ${vesselData['nahkoda']?['nama']}');
                await prefs.setString('vessel_data', json.encode(vesselData));
                print('========== getVesselData END (API-CREW) ==========\n');
                return vesselData;
              }
            } else {
              // Untuk nahkoda
              final vesselData = {
                'kapal': {
                  'id': kapal['id'],
                  'namaKapal': kapal['namaKapal'],
                  'nomorRegistrasi': kapal['nomorRegistrasi'],
                },
                'nahkoda': kapal['nahkoda'],
              };
              
              print('💾 [NAHKODA] Saving to cache');
              await prefs.setString('vessel_data', json.encode(vesselData));
              print('========== getVesselData END (API-NAHKODA) ==========\n');
              return vesselData;
            }
          }
        }
      }

      print('❌ No vessel data found');
      print('========== getVesselData END (NULL) ==========\n');
      return null;
    } catch (e) {
      print('❌ Error in getVesselData: $e');
      print('========== getVesselData END (ERROR) ==========\n');
      return null;
    }
  }

  // Get vessel detail by ID (untuk crew yang ingin lihat detail kapal)
  Future<Map<String, dynamic>?> getVesselById(int vesselId) async {
    try {
      print('🔍 [getVesselById] Starting request for vessel ID: $vesselId');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print('❌ [getVesselById] Token tidak ditemukan');
        throw Exception('Token tidak ditemukan');
      }

      print('🔑 [getVesselById] Token found: ${token.substring(0, 20)}...');
      print('🌐 [getVesselById] Calling: $baseUrl/api/mobile/vessels/$vesselId');

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/mobile/vessels/$vesselId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('📥 [getVesselById] Response status: ${response.statusCode}');
      print('📥 [getVesselById] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ [getVesselById] Response decoded successfully');
        print('📊 [getVesselById] Success: ${responseData['success']}');
        
        if (responseData['success'] == true) {
          final data = responseData['data'];
          print('🚢 [getVesselById] Vessel data found');
          print('📋 [getVesselById] Nama Kapal: ${data['namaKapal']}');
          print('📋 [getVesselById] Nomor Registrasi: ${data['nomorRegistrasi']}');
          
          if (data['nahkoda'] != null) {
            print('👨‍✈️ [getVesselById] Nahkoda found: ${data['nahkoda']['nama']}');
            print('👨‍✈️ [getVesselById] Nahkoda ID: ${data['nahkoda']['id']}');
          } else {
            print('⚠️ [getVesselById] Nahkoda is NULL');
          }
          
          if (data['crewMembers'] != null) {
            print('👥 [getVesselById] Crew members count: ${(data['crewMembers'] as List).length}');
          }
          
          return data;
        } else {
          print('❌ [getVesselById] Success is false: ${responseData['message']}');
        }
      } else {
        print('❌ [getVesselById] HTTP error: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('❌ [getVesselById] Exception: $e');
      print('❌ [getVesselById] Stack trace: ${StackTrace.current}');
      return null;
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

      final vesselData = await getVesselData();

      if (vesselData == null) {
        throw Exception(
          'Tidak ada kapal yang di-assign. Hubungi admin untuk assign kapal.',
        );
      }

      final kapalId = vesselData['kapal']['id'];

      print('🚢 Using kapal ID: $kapalId');

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
          String contentType = 'image/jpeg';
          if (buktiFilePath.toLowerCase().endsWith('.png')) {
            contentType = 'image/png';
          }

          print('📎 Uploading file: ${buktiFilePath.split('/').last}');
          print('📎 Content-Type: $contentType');

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

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result;
      } else {
        print('❌ Backend error response: ${response.body}');
        throw Exception(
          'Gagal upload bahan bakar: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> uploadIceData({
    required String jenisEs,
    required double jumlah,
    required double hargaPerUnit,
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
        throw Exception(
          'Tidak ada kapal yang di-assign. Hubungi admin untuk assign kapal.',
        );
      }

      final kapalId = vesselData['kapal']['id'];

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/mobile/vessel/$kapalId/ice-data'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['jenisEs'] = jenisEs;
      request.fields['jumlah'] = jumlah.toString();
      request.fields['hargaPerUnit'] = hargaPerUnit.toString();
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

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result;
      } else {
        throw Exception('Gagal upload data es: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> deleteBahanBakar(String fuelId) async {
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

      print('🗑️ DELETE Request URL: $url');
      print('🗑️ Kapal ID: $kapalId');
      print('🗑️ Fuel ID: $fuelId');

      final response = await http
          .delete(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Gagal hapus data BBM: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Delete error in service: $e');
      throw Exception('Error: $e');
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

      print('📝 PUT Request URL: $url');
      print('📝 Kapal ID: $kapalId');
      print('📝 Fuel ID: $fuelId');
      print('📝 Data: $jenisBahanBakar, $jumlahLiter L, Rp $hargaPerLiter');

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

      print('📊 Update Response status: ${response.statusCode}');
      print('📊 Update Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Gagal update data BBM: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Update error in service: $e');
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

      print('🔄 Fetching fresh documents from database...');
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/mobile/vessel/$kapalId/documents?t=$timestamp',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
              'Expires': '0',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('📊 Documents Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print('✅ Fresh data received from database');
          return responseData['data'];
        }
        return {'sertifikatJalan': [], 'dataBahanBakar': []};
      } else {
        throw Exception(
          'Gagal mengambil dokumen kapal: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error fetching documents: $e');
      throw Exception('Error: $e');
    }
  }
}
