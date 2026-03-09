import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../auth/services/session_service.dart';

class MapSearchService {
  static final String baseUrl = dotenv.env['API_BASE_URL']!;

  static Future<List<dynamic>> getJobsForMap({
    required double lat,
    required double lng,
    String? skill,
  }) async {
    final token = await SessionService.getToken();
    final params = {
      'lat': lat.toString(),
      'lng': lng.toString(),
      if (skill != null && skill.isNotEmpty) 'skill': skill,
    };
    final uri = Uri.parse('$baseUrl/api/jobs/map')
        .replace(queryParameters: params);
    final res = await http.get(uri,
        headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) throw Exception('Failed');
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getWorkersForMap({
    required double lat,
    required double lng,
    String? skill,
  }) async {
    final token = await SessionService.getToken();
    final params = {
      'lat': lat.toString(),
      'lng': lng.toString(),
      if (skill != null && skill.isNotEmpty) 'skill': skill,
    };
    final uri = Uri.parse('$baseUrl/api/worker/map')
        .replace(queryParameters: params);
    final res = await http.get(uri,
        headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) throw Exception('Failed');
    return jsonDecode(res.body);
  }
}