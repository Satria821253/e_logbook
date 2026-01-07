import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.22:8000/api'; // Physical device
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Flutter App',
      'Connection': 'keep-alive',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // Auth endpoints
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      print('Registering to: $baseUrl/register');
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: await getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'remember_me': rememberMe,
        }),
      ).timeout(const Duration(seconds: 10));
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        await saveToken(data['token']);
      }
      
      return data;
    } catch (e) {
      print('Register error: $e');
      return {'error': 'Connection failed: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    // Dummy ABK accounts
    final dummyAccounts = {
      'rizki@abk.com': {
        'password': '123456',
        'user': {
          'id': 2,
          'name': 'Ahmad Rizki',
          'email': 'rizki@abk.com',
          'phone': '081234567890',
          'role': 'ABK',
        },
        'token': 'abk_token_rizki_123'
      },
      'sari@abk.com': {
        'password': '123456',
        'user': {
          'id': 3,
          'name': 'Sari Dewi',
          'email': 'sari@abk.com',
          'phone': '081234567891',
          'role': 'ABK',
        },
        'token': 'abk_token_sari_456'
      },
      'budi@abk.com': {
        'password': '123456',
        'user': {
          'id': 4,
          'name': 'Budi Santoso',
          'email': 'budi@abk.com',
          'phone': '081234567892',
          'role': 'ABK',
        },
        'token': 'abk_token_budi_789'
      },
      // Nahkoda accounts
      'nahkoda1@email.com': {
        'password': '123456',
        'user': {
          'id': 5,
          'name': 'Kapten Joko',
          'email': 'nahkoda1@email.com',
          'phone': '081234567893',
          'role': 'Nahkoda',
        },
        'token': 'nahkoda_token_joko_123'
      },
      'nahkoda2@email.com': {
        'password': '123456',
        'user': {
          'id': 6,
          'name': 'Kapten Sari',
          'email': 'nahkoda2@email.com',
          'phone': '081234567894',
          'role': 'Nahkoda',
        },
        'token': 'nahkoda_token_sari_456'
      },
      'nahkoda3@email.com': {
        'password': '123456',
        'user': {
          'id': 7,
          'name': 'Kapten Budi',
          'email': 'nahkoda3@email.com',
          'phone': '081234567895',
          'role': 'Nahkoda',
        },
        'token': 'nahkoda_token_budi_789'
      },
    };

    // Check dummy accounts first
    if (dummyAccounts.containsKey(login)) {
      final account = dummyAccounts[login]!;
      if (account['password'] == password) {
        await saveToken(account['token'] as String);
        return {
          'token': account['token'],
          'user': account['user'],
          'message': 'Login berhasil sebagai ${(account['user'] as Map)['role']}'
        };
      } else {
        return {'error': 'Password salah'};
      }
    }

    // For non-dummy accounts, return error if backend not available
    return {'error': 'Backend tidak tersedia. Gunakan akun dummy untuk testing.'};
  }
  
  static Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: await getHeaders(),
    );
    
    await removeToken();
    return jsonDecode(response.body);
  }
  
  // User endpoints
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: await getHeaders(),
    );
    
    return jsonDecode(response.body);
  }
  
  // Catches endpoints
  static Future<Map<String, dynamic>> getCatches({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/catches?page=$page'),
      headers: await getHeaders(),
    );
    
    return jsonDecode(response.body);
  }
  
  static Future<Map<String, dynamic>> createCatch(Map<String, dynamic> catchData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/catches'),
      headers: await getHeaders(),
      body: jsonEncode(catchData),
    );
    
    return jsonDecode(response.body);
  }
  
  static Future<Map<String, dynamic>> getCatch(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/catches/$id'),
      headers: await getHeaders(),
    );
    
    return jsonDecode(response.body);
  }
  
  // Statistics endpoints
  static Future<Map<String, dynamic>> getStatistics(String period) async {
    final response = await http.get(
      Uri.parse('$baseUrl/statistics/$period'),
      headers: await getHeaders(),
    );
    
    return jsonDecode(response.body);
  }
  
  static Future<Map<String, dynamic>> getStatisticsSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/statistics-summary'),
      headers: await getHeaders(),
    );
    
    return jsonDecode(response.body);
  }
  
  // Fishing zones endpoints
  static Future<List<dynamic>> getFishingZones() async {
    final response = await http.get(
      Uri.parse('$baseUrl/fishing-zones'),
      headers: await getHeaders(),
    );
    
    return jsonDecode(response.body);
  }
}