import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../auth/services/session_service.dart';

class SkillService {

  static final String baseUrl = dotenv.env['API_BASE_URL']!;

  /// SEARCH skills (autocomplete)
  static Future<List<dynamic>> searchSkills(String query) async {

    if (query.isEmpty) return [];

    final token = await SessionService.getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/api/skills/search?q=$query"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to search skills");
    }

    return jsonDecode(res.body);
  }


  /// ADD skill
  static Future<void> addSkill(String skillId) async {

    final token = await SessionService.getToken();

    final res = await http.post(
      Uri.parse("$baseUrl/api/skills/add"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "skill_id": skillId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to add skill");
    }
  }


  /// GET my skills
  static Future<List<dynamic>> getMySkills() async {

    final token = await SessionService.getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/api/skills/my"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load skills");
    }

    return jsonDecode(res.body);
  }


  static Future<void> removeSkill(String skillId) async {

    final token =
    await SessionService.getToken();

    await http.delete(

      Uri.parse(
        "$baseUrl/api/skills/remove/$skillId",
      ),

      headers: {
        "Authorization": "Bearer $token"
      },

    );
  }


  static final String _base = dotenv.env['API_BASE_URL']!;

  /// Returns a flat list of skill name strings from GET /api/skills
  /// Your existing endpoint already returns [{id, name}, ...] — we just extract names.
  static Future<List<String>> getSkills() async {
    final token = await SessionService.getToken();
    final res = await http.get(
      Uri.parse('$_base/api/skills'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) throw Exception('Failed to load skills');
    final List<dynamic> data = jsonDecode(res.body);
    return data
        .map<String>((s) => s['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

}

