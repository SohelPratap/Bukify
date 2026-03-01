import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../auth/services/session_service.dart';

class CustomerService {

  static final String baseUrl = dotenv.env['API_BASE_URL']!;

  /// ==============================
  /// GET PROFILE
  /// ==============================
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await SessionService.getToken();

    final res = await http.get(
      Uri.parse('$baseUrl/api/customer/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to load profile');
    }
  }

  /// ==============================
  /// GET ADDRESSES
  /// ==============================
  static Future<List<dynamic>> getAddresses() async {
    final token = await SessionService.getToken();

    final res = await http.get(
      Uri.parse('$baseUrl/api/customer/address'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to load addresses');
    }
  }

  /// ==============================
  /// ADD ADDRESS
  /// ==============================
  static Future<void> addAddress({
    required String label,
    required String address,
    required double latitude,
    required double longitude,
    bool isDefault = false,
  }) async {
    final token = await SessionService.getToken();

    final res = await http.post(
      Uri.parse('$baseUrl/api/customer/address'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'label': label,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to add address');
    }
  }

  /// ==============================
  /// DELETE ADDRESS
  /// ==============================
  static Future<void> deleteAddress(String id) async {
    final token = await SessionService.getToken();

    final res = await http.delete(
      Uri.parse('$baseUrl/api/customer/address/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to delete address');
    }
  }

  /// ==============================
  /// SET DEFAULT ADDRESS
  /// ==============================
  static Future<void> setDefaultAddress(String id) async {
    final token = await SessionService.getToken();

    final res = await http.put(
      Uri.parse('$baseUrl/api/customer/address/$id/default'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to set default address');
    }
  }

  static Future<List<dynamic>> getSkills() async {
    final token = await SessionService.getToken();

    final res = await http.get(
      Uri.parse('$baseUrl/api/skills'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load skills');
    }

    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> searchSkills(String query) async {
    final token = await SessionService.getToken();

    final res = await http.get(
      Uri.parse('$baseUrl/api/skills/search?q=$query'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Search failed');
    }

    return jsonDecode(res.body);
  }

  /// ==============================
  /// SEARCH ADDRESSES
  /// ==============================
  static Future<List<dynamic>> searchAddresses(String query) async {
    final token = await SessionService.getToken();

    final res = await http.get(
      Uri.parse('$baseUrl/api/customer/address/search?q=$query'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Address search failed');
    }

    return jsonDecode(res.body);
  }
}




