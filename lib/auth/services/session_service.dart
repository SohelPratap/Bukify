import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  // Secure storage (JWT)
  static const _secureStorage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  // Shared prefs (non-sensitive)
  static const _roleKey = 'user_role';

  /// Save session after login/register
  static Future<void> saveSession({
    required String token,
    required String role,
  }) async {
    // Save JWT securely
    await _secureStorage.write(
      key: _tokenKey,
      value: token,
    );

    // Save role in shared prefs
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  /// Get JWT (for API calls)
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Get role
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  /// Check if logged in
  static Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout
  static Future<void> clearSession() async {
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
  }
}