import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../auth/services/session_service.dart';

class WorkerService {

  static final String baseUrl =
  dotenv.env['API_BASE_URL']!;

  static Future<void> toggleOnline(bool isOnline) async {

    final token = await SessionService.getToken();

    final res = await http.post(
      Uri.parse('$baseUrl/api/worker/toggle-online'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'is_online': isOnline,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update status');
    }
  }

  static Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? heading,
    double? speed,
  }) async {

    final token = await SessionService.getToken();

    await http.post(
      Uri.parse('$baseUrl/api/location/update'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'heading': heading,
        'speed': speed,
      }),
    );
  }
  static Future<void> updateServiceArea({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {

    final token = await SessionService.getToken();

    final res = await http.post(
      Uri.parse('$baseUrl/api/worker/service-area'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update service area');
    }
  }

  static Future<Map<String, dynamic>?> getServiceArea() async {

    final token = await SessionService.getToken();

    final res = await http.get(
      Uri.parse('$baseUrl/api/worker/service-area'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return null;
  }

}
