import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../auth/services/session_service.dart';

class WorkerJobsService {

  static final String baseUrl = dotenv.env['API_BASE_URL']!;

  /* ===============================
     GET NEARBY JOBS (open jobs)
  =============================== */
  static Future<List<dynamic>> getNearbyJobs() async {
    final token = await SessionService.getToken();

    final res = await http.get(
      Uri.parse('$baseUrl/api/jobs/nearby'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load nearby jobs");
    }

    return jsonDecode(res.body);
  }

  /* ===============================
     START JOB
     (open → in_progress)
  =============================== */
  static Future<void> startJob(String jobId) async {
    final token = await SessionService.getToken();

    final res = await http.put(
      Uri.parse('$baseUrl/api/jobs/$jobId/start'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to start job");
    }
  }

  /* ===============================
     GET ACTIVE JOBS
     (status = in_progress)
  =============================== */
  static Future<List<dynamic>> getActiveJobs() async {
    final token = await SessionService.getToken();

    final res = await http.get(
      Uri.parse('$baseUrl/api/jobs/worker/active'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load active jobs");
    }

    return jsonDecode(res.body);
  }

  /* ===============================
     COMPLETE JOB
     (in_progress → completed)
  =============================== */
  static Future<void> completeJob(String jobId) async {
    final token = await SessionService.getToken();

    final res = await http.put(
      Uri.parse('$baseUrl/api/jobs/$jobId/complete'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to complete job");
    }
  }

  /* ===============================
     GET COMPLETED JOBS
     (status = completed)
  =============================== */
  static Future<List<dynamic>> getCompletedJobs() async {
    final token = await SessionService.getToken();

    final res = await http.get(
      Uri.parse('$baseUrl/api/jobs/worker/completed'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load completed jobs");
    }

    return jsonDecode(res.body);
  }
}