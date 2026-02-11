import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthResponse {
  final String token;
  final String role;

  AuthResponse({required this.token, required this.role});
}

class AuthService {
  static final String baseUrl =
      dotenv.env['API_BASE_URL'] ?? '';

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Login failed');
    }

    final data = jsonDecode(res.body);
    return AuthResponse(
      token: data['token'],
      role: data['role'],
    );
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String role,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception('Register failed');
    }

    final data = jsonDecode(res.body);
    return AuthResponse(
      token: data['token'],
      role: data['role'],
    );
  }
}