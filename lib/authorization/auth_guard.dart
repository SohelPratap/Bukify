import '../auth/services/session_service.dart';

class AuthGuard {
  static Future<bool> canActivate() async {
    return await SessionService.hasSession();
  }
}