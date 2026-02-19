import 'package:latlong2/latlong.dart';
import 'location_service.dart';

class MapDataService {

  /// Get user LatLng
  static Future<LatLng> getUserLatLng() async {
    final position = await LocationService.getCurrentLocation();

    return LatLng(
      position.latitude,
      position.longitude,
    );
  }

}