import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../auth/services/session_service.dart';

class WorkerSearchService {
  static final String baseUrl = dotenv.env['API_BASE_URL']!;

  static Future<List<dynamic>> searchWorkers({
    required String skill,
    required double lat,
    required double lng,
  }) async {
    final token = await SessionService.getToken();

    final uri = Uri.parse('$baseUrl/api/worker/search').replace(
      queryParameters: {
        'skill': skill,
        'lat': lat.toString(),
        'lng': lng.toString(),
      },
    );

    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (res.statusCode != 200) {
      throw Exception('Search failed');
    }

    return jsonDecode(res.body);
  }
}