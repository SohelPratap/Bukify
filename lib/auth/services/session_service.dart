import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SessionService {
  static const _secureStorage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role';

  /// Save session after login/register
  static Future<void> saveSession({
    required String token,
    required String role,
  }) async {
    await _secureStorage.write(
      key: _tokenKey,
      value: token,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  /// Get JWT
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Get role
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  /// Check if valid logged in session exists
  static Future<bool> hasSession() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    // Check if token expired
    final isExpired = JwtDecoder.isExpired(token);
    return !isExpired;
  }

  /// Clear everything
  static Future<void> clearSession() async {
    await _secureStorage.delete(key: _tokenKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
  }
}