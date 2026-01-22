import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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

      // Cek apakah cache sudah expired (lebih dari 1 hari)
      final lastCacheTime = prefs.getInt('vessel_data_timestamp');
      final now = DateTime.now().millisecondsSinceEpoch;
      final oneDayInMs = 24 * 60 * 60 * 1000; // 1 hari dalam milliseconds
      
      bool cacheExpired = false;
      if (lastCacheTime != null) {
        final timeDiff = now - lastCacheTime;
        cacheExpired = timeDiff > oneDayInMs;
        if (cacheExpired) {
          print('⏰ Cache expired (${(timeDiff / (60 * 60 * 1000)).toStringAsFixed(1)} hours old)');
        } else {
          print('✅ Cache still valid (${(timeDiff / (60 * 60 * 1000)).toStringAsFixed(1)} hours old)');
        }
      } else {
        // Jika tidak ada timestamp, anggap cache expired (untuk backward compatibility)
        cacheExpired = true;
        print('⚠️ No timestamp found, treating cache as expired');
      }

      // Jika tidak force refresh dan cache belum expired, cek versi data dari backend
      if (!forceRefresh && !cacheExpired) {
        final vesselDataString = prefs.getString('vessel_data');
        if (vesselDataString != null) {
          print('💾 Found cached vessel_data');
          final cachedData = json.decode(vesselDataString);
          
          // Jika crew dan nahkoda null di cache, force refresh
          if (isCrewRole && cachedData['nahkoda'] == null) {
            print('⚠️ [CREW] Cache has null nahkoda, forcing refresh...');
            cacheExpired = true;
          }
          
          // Cek versi data dari backend (lightweight check)
          if (!cacheExpired) {
            try {
              print('🔍 Checking data version from backend...');
              final versionResponse = await http.get(
              Uri.parse('$baseUrl/api/mobile/vessels/my-vessel'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            ).timeout(const Duration(seconds: 10));

            if (versionResponse.statusCode == 200) {
              final responseData = json.decode(versionResponse.body);
              if (responseData['success'] == true) {
                final vessels = responseData['data'] as List;
                if (vessels.isNotEmpty) {
                  final latestKapal = vessels[0];
                  final cachedKapalId = cachedData['kapal']['id'];
                  final latestKapalId = latestKapal['id'];
                  
                  // Cek apakah kapal ID berubah atau updatedAt berubah
                  final cachedUpdatedAt = cachedData['kapal']['updatedAt'];
                  final latestUpdatedAt = latestKapal['updatedAt'];
                  
                  // Cek perubahan data nahkoda
                  final cachedNahkodaId = cachedData['nahkoda']?['id'];
                  final latestNahkodaId = latestKapal['nahkoda']?['id'];
                  
                  if (cachedKapalId != latestKapalId) {
                    print('🔄 Kapal ID changed: $cachedKapalId -> $latestKapalId');
                    print('🔄 Forcing refresh due to vessel change');
                    cacheExpired = true;
                  } else if (cachedNahkodaId != latestNahkodaId) {
                    print('🔄 Nahkoda changed: $cachedNahkodaId -> $latestNahkodaId');
                    print('🔄 Forcing refresh due to nahkoda change');
                    cacheExpired = true;
                  } else if (cachedUpdatedAt != null && latestUpdatedAt != null && cachedUpdatedAt != latestUpdatedAt) {
                    print('🔄 Kapal data updated: $cachedUpdatedAt -> $latestUpdatedAt');
                    print('🔄 Forcing refresh due to data update');
                    cacheExpired = true;
                  } else {
                    print('✅ Data version matches, using cache');
                    print('📋 [CACHE] Kapal: ${cachedData['kapal']}');
                    print('📋 [CACHE] Nahkoda: ${cachedData['nahkoda']}');
                    print('========== getVesselData END (CACHE) ==========\n');
                    return cachedData;
                  }
                }
              }
            }
            } catch (e) {
              print('⚠️ Failed to check version, using cache: $e');
              print('📋 [CACHE] Kapal: ${cachedData['kapal']}');
              print('📋 [CACHE] Nahkoda: ${cachedData['nahkoda']}');
              print('========== getVesselData END (CACHE) ==========\n');
              return cachedData;
            }
          }
        } else {
          print('💾 No cache found');
        }
      } else {
        if (forceRefresh) {
          print('🔄 Force refresh enabled, skipping cache');
        } else if (cacheExpired) {
          print('🔄 Cache expired, refreshing from API');
        }
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
                    'updatedAt': detailData['updatedAt'],
                  },
                  'nahkoda': detailData['nahkoda'],
                };
                
                print('💾 [CREW] Saving to cache with nahkoda: ${vesselData['nahkoda']?['nama']}');
                await prefs.setString('vessel_data', json.encode(vesselData));
                await prefs.setInt('vessel_data_timestamp', now);
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
                  'updatedAt': kapal['updatedAt'],
                },
                'nahkoda': kapal['nahkoda'],
              };
              
              print('💾 [NAHKODA] Saving to cache');
              await prefs.setString('vessel_data', json.encode(vesselData));
              await prefs.setInt('vessel_data_timestamp', now);
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
        Uri.parse('$baseUrl/api/mobile/vessel/$kapalId/bahan-bakar'),
      );

      print('🌐 [uploadBahanBakar] URL: $baseUrl/api/mobile/vessel/$kapalId/bahan-bakar');

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['jenisBahanBakar'] = jenisBahanBakar;
      request.fields['jumlahLiter'] = jumlahLiter.toString();
      request.fields['hargaPerLiter'] = hargaPerLiter.toString();
      request.fields['totalHarga'] = totalHarga.toString();
      request.fields['tanggalPengisian'] = tanggalPengisian;

      if (lokasiPengisian != null && lokasiPengisian.isNotEmpty) {
        request.fields['lokasiPengisian'] = lokasiPengisian;
        print('📍 [uploadBahanBakar] Lokasi added: $lokasiPengisian');
      }

      if (keterangan != null && keterangan.isNotEmpty) {
        request.fields['keterangan'] = keterangan;
        print('📝 [uploadBahanBakar] Keterangan added: $keterangan');
      }

      if (buktiFilePath != null && buktiFilePath.isNotEmpty) {
        final file = File(buktiFilePath);
        if (await file.exists()) {
          String contentType = 'image/jpeg';
          if (buktiFilePath.toLowerCase().endsWith('.png')) {
            contentType = 'image/png';
          }

          print('📎 [uploadBahanBakar] Uploading file: ${buktiFilePath.split('/').last}');
          print('📎 [uploadBahanBakar] Content-Type: $contentType');
          print('📎 [uploadBahanBakar] File size: ${await file.length()} bytes');

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
      print('📤 [uploadBahanBakar] Request files: ${request.files.length} file(s)');

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
        print('🔄 [uploadBahanBakar] Clearing cache and refreshing vessel data...');
        
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
        throw Exception('Token tidak ditemukan');
      }

      final vesselData = await getVesselData();

      if (vesselData == null) {
        throw Exception(
          'Tidak ada kapal yang di-assign. Hubungi admin untuk assign kapal.',
        );
      }

      final kapalId = vesselData['kapal']['id'];
      print('🚢 Kapal ID: $kapalId');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/mobile/vessel/$kapalId/ice-data'),
      );

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

      print('📤 Sending ice data...');
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
      );
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Ice data uploaded successfully');
        print('========== UPLOAD ICE DATA END ==========\n');
        return result;
      } else {
        print('❌ Upload failed: ${response.body}');
        print('========== UPLOAD ICE DATA END ==========\n');
        throw Exception('Gagal upload data es: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('========== UPLOAD ICE DATA END ==========\n');
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getIceData() async {
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

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/mobile/vessel/$kapalId/ice-data'),
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
      }
      print('❌ Failed to get ice data');
      print('========== GET ICE DATA END ==========\n');
      throw Exception('Gagal mengambil data es: ${response.statusCode}');
    } catch (e) {
      print('❌ Exception: $e');
      print('========== GET ICE DATA END ==========\n');
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
      print('🚢 [getFuelSummary] Kapal Name: ${vesselData['kapal']['namaKapal']}');
      
      String url = '$baseUrl/api/mobile/vessel/$kapalId/fuel-summary';

      if (startDate != null && endDate != null) {
        final dateFormat = DateFormat('yyyy-MM-dd');
        final startStr = dateFormat.format(startDate);
        final endStr = dateFormat.format(endDate);
        url += '?startDate=$startStr&endDate=$endStr';
        print('📅 [getFuelSummary] Filter applied:');
        print('   Start Date: $startStr');
        print('   End Date: $endStr');
      } else {
        print('📅 [getFuelSummary] No date filter (all data)');
      }

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
      print('📥 [getFuelSummary] Response body length: ${response.body.length} chars');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('📊 [getFuelSummary] Response decoded successfully');
        print('📊 [getFuelSummary] Success: ${responseData['success']}');
        
        if (responseData['success'] == true) {
          final data = responseData['data'];
          print('✅ [getFuelSummary] Data structure:');
          print('   - kapal: ${data['kapal'] != null ? "Present" : "Missing"}');
          print('   - summary: ${data['summary'] != null ? "Present" : "Missing"}');
          print('   - details: ${data['details'] != null ? "Present (${(data['details'] as List?)?.length ?? 0} items)" : "Missing"}');
          
          if (data['summary'] != null) {
            print('📈 [getFuelSummary] Summary data:');
            print('   - totalPengisian: ${data['summary']['totalPengisian']}');
            print('   - totalLiter: ${data['summary']['totalLiter']}');
            print('   - totalBiaya: ${data['summary']['totalBiaya']}');
            print('   - rataRataHarga: ${data['summary']['rataRataHarga']}');
            print('   - pengisianTerakhir: ${data['summary']['pengisianTerakhir'] != null ? "Present" : "Null"}');
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
      print('📄 Uploading sertifikat jalan...');
      print('   Input nama: "$nama" (length: ${nama.length})');
      print('   Input nomorSertifikat: "$nomorSertifikat" (length: ${nomorSertifikat.length})');
      print('   Input tanggalBerlaku: "$tanggalBerlaku"');
      print('   Input filePath: "$filePath"');
      
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
        Uri.parse('$baseUrl/api/mobile/vessel/$kapalId/sertifikat-jalan'),
      );

      // Convert date to ISO 8601 datetime format
      final dateTime = DateTime.parse(tanggalBerlaku);
      final isoDateTime = dateTime.toUtc().toIso8601String();
      print('   Converted to ISO: "$isoDateTime"');

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['nama'] = nama;
      request.fields['nomor_sertifikat'] = nomorSertifikat;
      request.fields['tanggal_berlaku'] = isoDateTime;
      
      print('📤 Request fields:');
      print('   nama: "${request.fields['nama']}"');
      print('   nomor_sertifikat: "${request.fields['nomor_sertifikat']}"');
      print('   tanggal_berlaku: "${request.fields['tanggal_berlaku']}"');

      final file = File(filePath);
      if (await file.exists()) {
        String contentType = 'application/pdf';
        if (filePath.toLowerCase().endsWith('.jpg') || filePath.toLowerCase().endsWith('.jpeg')) {
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

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Sertifikat uploaded successfully');
        return result;
      } else {
        throw Exception('Gagal upload sertifikat: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error uploading sertifikat: $e');
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
            print('⚠️ [canAddFuel] BBM sudah terisi: ${dataBahanBakar.length} record(s)');
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
}
