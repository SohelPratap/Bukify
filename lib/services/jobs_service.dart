import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../auth/services/session_service.dart';

class JobsService {

  static final String baseUrl = dotenv.env['API_BASE_URL']!;

  /* =========================================================
     CREATE JOB (Customer)
  ========================================================= */

  static Future<void> createJob({
    required String skillId,
    required String addressId,
    required String title,
    String? description,
  }) async {

    final token = await SessionService.getToken();

    final res = await http.post(
      Uri.parse('$baseUrl/api/jobs'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'skill_id': skillId,
        'address_id': addressId,
        'title': title,
        'description': description,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to create job');
    }
  }

  /// ==============================
  /// GET ACTIVE JOBS
  /// ==============================
  static Future<List<dynamic>> getActiveJobs() async {
    final token = await SessionService.getToken();

    final res = await http.get(
      Uri.parse('$baseUrl/api/jobs/my/active'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load active jobs');
    }

    return jsonDecode(res.body);
  }

  /// ==============================
  /// GET HISTORY JOBS
  /// ==============================
  static Future<List<dynamic>> getPastJobs() async {
    final token = await SessionService.getToken();

    final res = await http.get(
      Uri.parse('$baseUrl/api/jobs/my/history'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load job history');
    }

    return jsonDecode(res.body);
  }

  /// ==============================
  /// CANCEL JOB
  /// ==============================
  static Future<void> cancelJob(String jobId) async {
    final token = await SessionService.getToken();

    final res = await http.put(
      Uri.parse('$baseUrl/api/jobs/$jobId/cancel'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Cancel failed');
    }
  }

  /* =========================================================
     GET NEARBY JOBS (Worker)
  ========================================================= */

  static Future<List<dynamic>> getNearbyJobs() async {

    final token = await SessionService.getToken();

    final res = await http.get(
      Uri.parse('$baseUrl/api/jobs/nearby'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load nearby jobs');
    }

    return jsonDecode(res.body);
  }

  /* =========================================================
     ACCEPT JOB (Worker)
  ========================================================= */

  static Future<void> acceptJob(String jobId) async {

    final token = await SessionService.getToken();

    final res = await http.post(
      Uri.parse('$baseUrl/api/jobs/$jobId/accept'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to accept job');
    }
  }
}