import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../auth/services/session_service.dart';

class ProfileService {
  static final String baseUrl = dotenv.env['API_BASE_URL']!;

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await SessionService.getToken();
    final role = await SessionService.getRole();

    final endpoint = role == 'worker'
        ? '/api/worker/profile'
        : '/api/customer/profile';

    final res = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load profile');
    }

    return jsonDecode(res.body);
  }
}