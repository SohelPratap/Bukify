import 'package:geolocator/geolocator.dart';

class LocationService {

  /// Request permission
  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    return true;
  }

  /// Get current position
  static Future<Position> getCurrentLocation() async {
    await requestPermission();

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}