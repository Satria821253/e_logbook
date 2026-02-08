import 'dart:convert';
import 'dart:io';
import 'package:e_logbook/services/realtime/realtime_update_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:shared_preferences/shared_preferences.dart';

class VesselService {
  static const String baseUrl = 'https://elogbookipb.web.id';

  Future<Map<String, dynamic>> checkAssignmentStatus() async {
    try {
      print('🌐 [VesselService] Using baseUrl: $baseUrl');
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
          actualRole =
              userData['role'] ?? userData['user_role'] ?? userData['userRole'];
          print('📊 [DEBUG] user_data: $userData');
          print('👤 [DEBUG] Role extracted: $actualRole');
        } catch (e) {
          print('❌ Failed to parse user_data: $e');
        }
      }

      print('🎯 Role: $actualRole, Force refresh? $forceRefresh');

      // Gunakan endpoint /trip untuk semua role
      print('🌐 Using /trip endpoint...');
      return await _getVesselDataFromTrip(token, forceRefresh);
    } catch (e) {
      print('❌ Error in getVesselData: $e');
      print('========== getVesselData END (ERROR) ==========\n');
      return null;
    }
  }

  // Get vessel data from /trip endpoint
  Future<Map<String, dynamic>?> _getVesselDataFromTrip(
    String token,
    bool forceRefresh,
  ) async {
    try {
      print('\n========== VESSEL DATA FROM TRIP START ==========');
      print('🔑 [TRIP] Token: ${token.substring(0, 30)}...');
      print('🌐 [TRIP] URL: $baseUrl/api/trip');

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/trip'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('📥 [TRIP] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('📦 [TRIP] success: ${responseData['success']}');

        if (responseData['success'] == true && responseData['data'] != null) {
          final trips = responseData['data'] as List;
          print('🔍 [TRIP] Total trips: ${trips.length}');

          if (trips.isNotEmpty) {
            // Ambil trip pertama yang aktif atau terbaru
            final trip = trips[0];
            final kapal = trip['kapal'];
            final nahkoda = trip['nahkoda'];

            final vesselData = {
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
            };

            print('✅ [TRIP] Vessel data found');
            print('🚢 [TRIP] Kapal: ${kapal['namaKapal']}');
            print('👨✈️ [TRIP] Nahkoda: ${nahkoda?['nama'] ?? "null"}');

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('vessel_data', json.encode(vesselData));
            await prefs.setInt(
              'vessel_data_timestamp',
              DateTime.now().millisecondsSinceEpoch,
            );
            print('========== VESSEL DATA FROM TRIP END (SUCCESS) ==========\n');
            return vesselData;
          }
        }
      }

      print('❌ [TRIP] No vessel data found');
      print('========== VESSEL DATA FROM TRIP END (NULL) ==========\n');
      return null;
    } catch (e) {
      print('❌ [TRIP] Error: $e');
      print('========== VESSEL DATA FROM TRIP END (ERROR) ==========\n');
      return null;
    }
  }

  // Get vessel data from API (untuk semua role)
  Future<Map<String, dynamic>?> _getVesselDataFromAPI(
    String token,
    bool forceRefresh,
  ) async {
    try {
      print('\n========== VESSEL DATA FETCH START ==========');
      print('🔑 [API] Token: ${token.substring(0, 30)}...');
      print('🔄 [API] Force refresh: $forceRefresh');
      print('🔍 [API] Fetching from my-vessel endpoint...');
      print('🌐 [API] URL: $baseUrl/api/mobile/vessel/my-vessel');

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/mobile/vessel/my-vessel'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('\n--- API RESPONSE ---');
      print('📥 [API] Response status: ${response.statusCode}');
      print('📥 [API] Response body RAW: ${response.body}');
      print('--- END RESPONSE ---\n');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('📦 [API] Parsed response data:');
        print('   - success: ${responseData['success']}');
        print('   - message: ${responseData['message'] ?? "(no message)"}');
        print('   - data type: ${responseData['data']?.runtimeType}');

        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          
          // Handle both array and single object response
          List vessels;
          if (data is List) {
            vessels = data;
            print('\n🔍 [API] Data is List, vessels count: ${vessels.length}');
          } else if (data is Map) {
            vessels = [data];
            print('\n🔍 [API] Data is Map (single vessel), converting to List');
          } else {
            print('❌ [API] Unexpected data type: ${data.runtimeType}');
            throw Exception('Data kapal tidak ditemukan');
          }

          if (vessels.isNotEmpty) {
            final firstVessel = vessels[0];
            final vesselId = firstVessel['id'];

            print('🔍 [API] Fetching full vessel details for ID: $vesselId');

            // Fetch full vessel data including nahkoda
            final fullVesselData = await getVesselById(vesselId);

            final vesselData = {
              'kapal': {
                'id': firstVessel['id'],
                'namaKapal': firstVessel['namaKapal'],
                'nomorRegistrasi': firstVessel['nomorRegistrasi'],
              },
              'nahkoda': fullVesselData?['nahkoda'],
            };

            print('✅ [API] Vessel data found');
            print('🚢 [API] Kapal: ${firstVessel["namaKapal"]}');
            print(
              '👨✈️ [API] Nahkoda: ${fullVesselData?['nahkoda']?['nama'] ?? "null"}',
            );
            print('📋 [API] Total vessels: ${vessels.length}');

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('vessel_data', json.encode(vesselData));
            await prefs.setInt(
              'vessel_data_timestamp',
              DateTime.now().millisecondsSinceEpoch,
            );
            print('========== getVesselData END (SUCCESS) ==========\n');
            return vesselData;
          }
        }
      }

      print('❌ [API] No vessel data found from my-vessel');
      print(
        'ℹ️ [API] User is NOT assigned to any vessel in database',
      );
      print('========== getVesselData END (NULL) ==========\n');
      return null;
    } catch (e) {
      print('❌ [API] Error: $e');
      print('========== getVesselData END (ERROR) ==========\n');
      return null;
    }
  }

  // Get vessel data for NAHKODA using my-vessel endpoint (existing logic)
  Future<Map<String, dynamic>?> _getVesselDataForNahkoda(
    String token,
    bool forceRefresh,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final oneDayInMs = 24 * 60 * 60 * 1000;

      // Cek cache
      bool cacheExpired = false;
      final lastCacheTime = prefs.getInt('vessel_data_timestamp');

      if (lastCacheTime != null) {
        final timeDiff = now - lastCacheTime;
        cacheExpired = timeDiff > oneDayInMs;
        if (cacheExpired) {
          print(
            '⏰ Cache expired (${(timeDiff / (60 * 60 * 1000)).toStringAsFixed(1)} hours old)',
          );
        } else {
          print(
            '✅ Cache still valid (${(timeDiff / (60 * 60 * 1000)).toStringAsFixed(1)} hours old)',
          );
        }
      } else {
        cacheExpired = true;
        print('⚠️ No timestamp found, treating cache as expired');
      }

      // Return cache if valid and not force refresh
      if (!forceRefresh && !cacheExpired) {
        final vesselDataString = prefs.getString('vessel_data');
        if (vesselDataString != null) {
          print('💾 Found cached vessel_data');
          final cachedData = json.decode(vesselDataString);
          print('📋 [CACHE] Kapal: ${cachedData['kapal']}');
          print('📋 [CACHE] Nahkoda: ${cachedData['nahkoda']}');
          print('========== getVesselData END (NAHKODA-CACHE) ==========\n');
          return cachedData;
        }
      }

      // Fetch from API
      print('🌐 [NAHKODA] Fetching from my-vessel endpoint...');
      final vesselResponse = await http
          .get(
            Uri.parse('$baseUrl/api/mobile/vessels/my-vessel'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('📥 [NAHKODA] API Response status: ${vesselResponse.statusCode}');
      print('📥 [NAHKODA] API Response body: ${vesselResponse.body}');

      if (vesselResponse.statusCode == 200) {
        final responseData = json.decode(vesselResponse.body);
        print('📥 [NAHKODA] API Response success: ${responseData['success']}');

        if (responseData['success'] == true) {
          final vessels = responseData['data'] as List;
          print('🚢 [NAHKODA] Vessels count: ${vessels.length}');

          if (vessels.isNotEmpty) {
            final kapal = vessels[0];
            final vesselData = {
              'kapal': {
                'id': kapal['id'],
                'namaKapal': kapal['namaKapal'],
                'nomorRegistrasi': kapal['nomorRegistrasi'],
                'updatedAt': kapal['updatedAt'],
              },
              'nahkoda': kapal['nahkoda'],
            };

            print('💾 [NAHKODA] Saving to cache');
            await prefs.setString('vessel_data', json.encode(vesselData));
            await prefs.setInt('vessel_data_timestamp', now);
            print('========== getVesselData END (NAHKODA-API) ==========\n');
            return vesselData;
          }
        }
      }

      print('❌ [NAHKODA] No vessel data found');
      print('========== getVesselData END (NAHKODA-NULL) ==========\n');
      return null;
    } catch (e) {
      print('❌ [NAHKODA] Error: $e');
      print('========== getVesselData END (NAHKODA-ERROR) ==========\n');
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
      print(
        '🌐 [getVesselById] Calling: $baseUrl/api/mobile/vessels/$vesselId',
      );

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
          print(
            '📋 [getVesselById] Nomor Registrasi: ${data['nomorRegistrasi']}',
          );

          if (data['nahkoda'] != null) {
            print(
              '👨‍✈️ [getVesselById] Nahkoda found: ${data['nahkoda']['nama']}',
            );
            print('👨‍✈️ [getVesselById] Nahkoda ID: ${data['nahkoda']['id']}');
          } else {
            print('⚠️ [getVesselById] Nahkoda is NULL');
          }

          if (data['crewMembers'] != null) {
            print(
              '👥 [getVesselById] Crew members count: ${(data['crewMembers'] as List).length}',
            );
          }

          return data;
        } else {
          print(
            '❌ [getVesselById] Success is false: ${responseData['message']}',
          );
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
      print('\n========== UPLOAD BAHAN BAKAR START ==========');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print('❌ [uploadBahanBakar] Token tidak ditemukan');
        throw Exception('Token tidak ditemukan');
      }

      print('🔑 [uploadBahanBakar] Token found: ${token.substring(0, 20)}...');

      final vesselData = await getVesselData();

      if (vesselData == null) {
        print('❌ [uploadBahanBakar] Vessel data is null');
        throw Exception(
          'Tidak ada kapal yang di-assign. Hubungi admin untuk assign kapal.',
        );
      }

      final kapalId = vesselData['kapal']['id'];

      print('🚢 [uploadBahanBakar] Using kapal ID: $kapalId');
      print('📋 [uploadBahanBakar] Data yang akan dikirim:');
      print('   - jenisBahanBakar: $jenisBahanBakar');
      print('   - jumlahLiter: $jumlahLiter');
      print('   - hargaPerLiter: $hargaPerLiter');
      print('   - totalHarga: $totalHarga');
      print('   - tanggalPengisian: $tanggalPengisian');
      print('   - lokasiPengisian: ${lokasiPengisian ?? "(kosong)"}');
      print('   - keterangan: ${keterangan ?? "(kosong)"}');
      print('   - buktiFilePath: ${buktiFilePath ?? "(tidak ada)"}');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/mobile/vessel/$kapalId/fuel-data'),
      );

      print(
        '🌐 [uploadBahanBakar] URL: $baseUrl/mobile/vessel/$kapalId/fuel-data',
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['jenisBahanBakar'] = jenisBahanBakar;
      request.fields['jumlahLiter'] = jumlahLiter.toString();
      request.fields['hargaPerLiter'] = hargaPerLiter.toString();
      request.fields['totalHarga'] = totalHarga.toString();
      request.fields['tanggalPengisian'] = tanggalPengisian;

      // Kirim field optional sebagai empty string (bukan skip)
      request.fields['lokasiPengisian'] = lokasiPengisian ?? '';
      request.fields['keterangan'] = keterangan ?? '';

      if (buktiFilePath != null && buktiFilePath.isNotEmpty) {
        final file = File(buktiFilePath);
        if (await file.exists()) {
          String contentType = 'image/jpeg';
          if (buktiFilePath.toLowerCase().endsWith('.png')) {
            contentType = 'image/png';
          }

          print(
            '📎 [uploadBahanBakar] Uploading file: ${buktiFilePath.split('/').last}',
          );
          print('📎 [uploadBahanBakar] Content-Type: $contentType');
          print(
            '📎 [uploadBahanBakar] File size: ${await file.length()} bytes',
          );

          request.files.add(
            await http.MultipartFile.fromPath(
              'bukti',
              buktiFilePath,
              contentType: http_parser.MediaType.parse(contentType),
            ),
          );
        } else {
          print('⚠️ [uploadBahanBakar] File not found: $buktiFilePath');
        }
      } else {
        print('ℹ️ [uploadBahanBakar] No file to upload');
      }

      print('📤 [uploadBahanBakar] Sending request...');
      print('📤 [uploadBahanBakar] Request fields: ${request.fields}');
      print(
        '📤 [uploadBahanBakar] Request files: ${request.files.length} file(s)',
      );

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
      );
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 [uploadBahanBakar] Response status: ${response.statusCode}');
      print('📡 [uploadBahanBakar] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ [uploadBahanBakar] Upload successful!');
        print('========== UPLOAD BAHAN BAKAR END (SUCCESS) ==========\n');
        return result;
      } else if (response.statusCode == 404) {
        // Kapal tidak ditemukan, clear cache dan retry
        print('⚠️ [uploadBahanBakar] Kapal tidak ditemukan (404)');
        print(
          '🔄 [uploadBahanBakar] Clearing cache and refreshing vessel data...',
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('vessel_data');
        print('✅ [uploadBahanBakar] Cache cleared');

        print('========== UPLOAD BAHAN BAKAR END (CACHE CLEARED) ==========\n');
        throw Exception(
          'Data kapal tidak valid. Silakan logout dan login kembali untuk refresh data.',
        );
      } else {
        print('❌ [uploadBahanBakar] Backend error response: ${response.body}');
        print('========== UPLOAD BAHAN BAKAR END (FAILED) ==========\n');
        throw Exception(
          'Gagal upload bahan bakar: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print('❌ [uploadBahanBakar] Exception: $e');
      print('❌ [uploadBahanBakar] Stack trace: $stackTrace');
      print('========== UPLOAD BAHAN BAKAR END (EXCEPTION) ==========\n');
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
      print('\n========== UPLOAD ICE DATA START ==========');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print('❌ [uploadIceData] Token tidak ditemukan');
        throw Exception('Token tidak ditemukan');
      }

      print('🔑 [uploadIceData] Token found: ${token.substring(0, 20)}...');

      final vesselData = await getVesselData();

      if (vesselData == null) {
        print('❌ [uploadIceData] Vessel data is null');
        throw Exception(
          'Tidak ada kapal yang di-assign. Hubungi admin untuk assign kapal.',
        );
      }

      final kapalId = vesselData['kapal']['id'];
      print('🚢 [uploadIceData] Kapal ID: $kapalId');
      print(
        '🚢 [uploadIceData] Kapal Name: ${vesselData['kapal']['namaKapal']}',
      );
      print('📋 [uploadIceData] Data yang akan dikirim:');
      print('   - jenisEs: $jenisEs');
      print('   - jumlahKg: $jumlahKg');
      print('   - hargaPerKg: $hargaPerKg');
      print('   - totalHarga: $totalHarga');
      print('   - tanggalPembelian: $tanggalPembelian');
      print('   - lokasiPembelian: ${lokasiPembelian ?? "(kosong)"}');
      print('   - keterangan: ${keterangan ?? "(kosong)"}');
      print('   - buktiFilePath: ${buktiFilePath ?? "(tidak ada)"}');

      var url = '$baseUrl/api/mobile/vessel/$kapalId/ice-data';
      print('🌐 [uploadIceData] URL: $url');

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

          print(
            '📎 [uploadIceData] Uploading file: ${buktiFilePath.split('/').last}',
          );
          print('📎 [uploadIceData] Content-Type: $contentType');
          print('📎 [uploadIceData] File size: ${await file.length()} bytes');

          request.files.add(
            await http.MultipartFile.fromPath(
              'bukti',
              buktiFilePath,
              contentType: http_parser.MediaType.parse(contentType),
            ),
          );
        } else {
          print('⚠️ [uploadIceData] File not found: $buktiFilePath');
        }
      } else {
        print('ℹ️ [uploadIceData] No file to upload');
      }

      print('📤 [uploadIceData] Sending request...');
      print('📤 [uploadIceData] Request fields: ${request.fields}');
      print(
        '📤 [uploadIceData] Request files: ${request.files.length} file(s)',
      );

      var streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
      );
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 [uploadIceData] Response status: ${response.statusCode}');
      print('📥 [uploadIceData] Response body: ${response.body}');

      if (response.statusCode == 404) {
        print(
          '⚠️ [uploadIceData] First attempt failed (404), trying without /api prefix...',
        );
        url = '$baseUrl/mobile/vessel/$kapalId/ice-data';
        print('🌐 [uploadIceData] Retry URL: $url');

        request = http.MultipartRequest('POST', Uri.parse(url));
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

        print('📤 [uploadIceData] Sending retry request...');
        streamedResponse = await request.send().timeout(
          const Duration(minutes: 2),
        );
        response = await http.Response.fromStream(streamedResponse);

        print(
          '📥 [uploadIceData] Retry response status: ${response.statusCode}',
        );
        print('📥 [uploadIceData] Retry response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ [uploadIceData] Upload successful!');
        print('========== UPLOAD ICE DATA END (SUCCESS) ==========\n');

        RealtimeUpdateService.notifyListeners('ice');

        return result;
      } else {
        print('❌ [uploadIceData] Upload failed: ${response.statusCode}');
        print('❌ [uploadIceData] Error body: ${response.body}');
        print('========== UPLOAD ICE DATA END (FAILED) ==========\n');
        throw Exception(
          'Gagal upload data es: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print('❌ [uploadIceData] Exception: $e');
      print('❌ [uploadIceData] Stack trace: $stackTrace');
      print('========== UPLOAD ICE DATA END (EXCEPTION) ==========\n');
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>?> getIceData() async {
    try {
      print('\n========== GET ICE DATA START ==========');
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
      print('🚢 Kapal ID: $kapalId');

      // Use /api prefix (same as upload)
      final url = '$baseUrl/api/mobile/vessel/$kapalId/ice-data';
      print('🌐 [getIceData] URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print('✅ Ice data retrieved successfully');
          print('========== GET ICE DATA END ==========\n');
          return responseData['data'];
        }
      } else if (response.statusCode == 404) {
        print('⚠️ Ice data endpoint not found or no data (404)');
        print('========== GET ICE DATA END ==========\n');
        return null;
      } else if (response.statusCode == 500) {
        print('⚠️ Server error (500)');
        print('========== GET ICE DATA END ==========\n');
        return null;
      }

      print('❌ Failed to get ice data');
      print('========== GET ICE DATA END ==========\n');
      return null;
    } catch (e) {
      print('❌ Exception: $e');
      print('========== GET ICE DATA END ==========\n');
      return null;
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
              '$baseUrl/api/mobile/vessel/$kapalId/documents?t=$timestamp&_=${DateTime.now().microsecondsSinceEpoch}',
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
        print('📊 Full response: $responseData');

        if (responseData['success'] == true) {
          print('✅ Fresh data received from database');
          final data = responseData['data'];

          // Debug log untuk sertifikat
          if (data['sertifikatJalan'] != null) {
            final sertifikat = data['sertifikatJalan'] as List;
            print('📄 Documents data received:');
            print('   Sertifikat Jalan: ${sertifikat.length} items');
            if (sertifikat.isNotEmpty) {
              print('   First sertifikat FULL: ${sertifikat[0]}');
              print(
                '   First sertifikat tanggalBerlaku: ${sertifikat[0]['tanggalBerlaku']}',
              );
              print(
                '   First sertifikat tanggal_berlaku: ${sertifikat[0]['tanggal_berlaku']}',
              );
            }
          }

          return data;
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

  Future<Map<String, dynamic>> getFuelSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      print('\n========== GET FUEL SUMMARY START ==========');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print('❌ [getFuelSummary] Token tidak ditemukan');
        throw Exception('Token tidak ditemukan');
      }

      print('🔑 [getFuelSummary] Token found: ${token.substring(0, 20)}...');

      final vesselData = await getVesselData();

      if (vesselData == null) {
        print('❌ [getFuelSummary] Vessel data is null');
        throw Exception('Tidak ada kapal yang di-assign.');
      }

      final kapalId = vesselData['kapal']['id'];
      print('🚢 [getFuelSummary] Kapal ID: $kapalId');
      print(
        '🚢 [getFuelSummary] Kapal Name: ${vesselData['kapal']['namaKapal']}',
      );

      final url = '$baseUrl/mobile/vessel/$kapalId/fuel-summary';
      print('🌐 [getFuelSummary] Calling API: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('📥 [getFuelSummary] Response status: ${response.statusCode}');
      print(
        '📥 [getFuelSummary] Response body length: ${response.body.length} chars',
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('📊 [getFuelSummary] Response decoded successfully');
        print('📊 [getFuelSummary] Success: ${responseData['success']}');

        if (responseData['success'] == true) {
          final data = responseData['data'];
          print('✅ [getFuelSummary] Data structure:');
          print('   - kapal: ${data['kapal'] != null ? "Present" : "Missing"}');
          print(
            '   - summary: ${data['summary'] != null ? "Present" : "Missing"}',
          );
          print(
            '   - details: ${data['details'] != null ? "Present (${(data['details'] as List?)?.length ?? 0} items)" : "Missing"}',
          );

          if (data['summary'] != null) {
            print('📈 [getFuelSummary] Summary data:');
            print('   - totalPengisian: ${data['summary']['totalPengisian']}');
            print('   - totalLiter: ${data['summary']['totalLiter']}');
            print('   - totalBiaya: ${data['summary']['totalBiaya']}');
            print('   - rataRataHarga: ${data['summary']['rataRataHarga']}');
            print(
              '   - pengisianTerakhir: ${data['summary']['pengisianTerakhir'] != null ? "Present" : "Null"}',
            );
          }

          print('✅ [getFuelSummary] Fuel summary loaded successfully');
          print('========== GET FUEL SUMMARY END (SUCCESS) ==========\n');
          return data;
        } else {
          print('❌ [getFuelSummary] Response success is false');
          print('❌ [getFuelSummary] Message: ${responseData['message']}');
          print('========== GET FUEL SUMMARY END (FAILED) ==========\n');
          throw Exception('Response success is false');
        }
      } else {
        print('❌ [getFuelSummary] HTTP Error: ${response.statusCode}');
        print('❌ [getFuelSummary] Response body: ${response.body}');
        print('========== GET FUEL SUMMARY END (HTTP ERROR) ==========\n');
        throw Exception(
          'Gagal mengambil ringkasan BBM: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      print('❌ [getFuelSummary] Exception caught: $e');
      print('❌ [getFuelSummary] Stack trace: $stackTrace');
      print('========== GET FUEL SUMMARY END (EXCEPTION) ==========\n');
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> uploadSertifikatJalan({
    required String nama,
    required String nomorSertifikat,
    required String tanggalBerlaku,
    required String filePath,
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
        Uri.parse('$baseUrl/api/mobile/vessel/$kapalId/sertifikat-jalan'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['nama'] = nama;
      request.fields['nomorSertifikat'] = nomorSertifikat;
      request.fields['tanggalBerlaku'] = tanggalBerlaku; // Format: YYYY-MM-DD

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
            'sertifikat',
            filePath,
            contentType: http_parser.MediaType.parse(contentType),
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result;
      } else {
        throw Exception('Gagal upload sertifikat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> hasCertificate() async {
    try {
      final documents = await getVesselDocuments();
      final sertifikatJalan = documents['sertifikatJalan'] as List?;
      return sertifikatJalan != null && sertifikatJalan.isNotEmpty;
    } catch (e) {
      return true; // Default: bisa akses jika error
    }
  }

  Future<bool> canAddFuel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return true;

      final vesselData = await getVesselData();
      if (vesselData == null) return true;

      final kapalId = vesselData['kapal']['id'];

      // Gunakan endpoint documents yang sudah ada
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/mobile/vessel/$kapalId/documents'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final documents = data['data'];
          final dataBahanBakar = documents['dataBahanBakar'] as List?;

          // Jika ada data BBM, berarti sudah terisi
          if (dataBahanBakar != null && dataBahanBakar.isNotEmpty) {
            print(
              '⚠️ [canAddFuel] BBM sudah terisi: ${dataBahanBakar.length} record(s)',
            );
            return false; // Tidak bisa tambah BBM
          }

          print('✅ [canAddFuel] BBM belum terisi, bisa input');
          return true; // Bisa tambah BBM
        }
      }

      // Default: bisa input jika ada error
      return true;
    } catch (e) {
      print('⚠️ [canAddFuel] Error: $e');
      return true; // Default: bisa input jika error
    }
  }

  Future<bool> canAddIce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return true;

      final vesselData = await getVesselData();
      if (vesselData == null) return true;

      final kapalId = vesselData['kapal']['id'];

      // Gunakan endpoint documents yang sudah ada (sama seperti canAddFuel)
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/mobile/vessel/$kapalId/documents'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final documents = data['data'];
          final iceData = documents['iceData'] as List?;

          // Jika ada data Es, berarti sudah terisi
          if (iceData != null && iceData.isNotEmpty) {
            print(
              '⚠️ [canAddIce] Es sudah terisi: ${iceData.length} record(s)',
            );
            return false; // Tidak bisa tambah Es
          }

          print('✅ [canAddIce] Es belum terisi, bisa input');
          return true; // Bisa tambah Es
        }
      }

      // Default: bisa input jika ada error
      return true;
    } catch (e) {
      print('⚠️ [canAddIce] Error: $e');
      return true; // Default: bisa input jika error
    }
  }

  // NEW: Upload vessel document (Sertifikat Jalan, Surat Izin Berlayar, dll)
  Future<Map<String, dynamic>> uploadVesselDocument({
    required String jenisDokumen,
    required String filePath,
    String? nomorSertifikat,
    String? tanggalBerlaku,
  }) async {
    try {
      print('\n========== UPLOAD VESSEL DOCUMENT START ==========');
      print('📄 Jenis Dokumen: $jenisDokumen');
      print('📄 Nomor: $nomorSertifikat');
      print('📄 Tanggal Berlaku: $tanggalBerlaku');
      print('📄 File: $filePath');

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
      print('🚢 Kapal ID: $kapalId');

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
        print('📎 File added: ${file.path.split('/').last}');
      } else {
        throw Exception('File tidak ditemukan: $filePath');
      }

      print('📤 Sending request...');
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
      );
      final response = await http.Response.fromStream(streamedResponse);

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          print('✅ Document uploaded successfully');
          print('========== UPLOAD VESSEL DOCUMENT END ==========\n');
          return result;
        } else {
          throw Exception(result['message'] ?? 'Upload gagal');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error uploading document: $e');
      print('========== UPLOAD VESSEL DOCUMENT END ==========\n');
      throw Exception('Error: $e');
    }
  }
}
