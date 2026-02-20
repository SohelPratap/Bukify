import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  final MapController _mapController = MapController();

  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  /// GET REAL GPS LOCATION
  Future<void> _getLocation() async {

    LocationPermission permission;

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final latLng = LatLng(
      position.latitude,
      position.longitude,
    );

    setState(() {
      _currentLocation = latLng;
    });

    _mapController.move(latLng, 15);
  }

  @override
  Widget build(BuildContext context) {

    if (_currentLocation == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [

        /// MAP
        FlutterMap(

          mapController: _mapController,

          options: MapOptions(
            initialCenter: _currentLocation!,
            initialZoom: 15,
            minZoom: 3,
            maxZoom: 19,
          ),

          children: [

            TileLayer(
              urlTemplate:
              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: "com.bukify.app",
            ),

            MarkerLayer(
              markers: [

                Marker(
                  point: _currentLocation!,
                  width: 60,
                  height: 60,

                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Color(0xFF8B5CF6),
                    size: 50,
                  ),
                ),

              ],
            ),

          ],
        ),

        /// SEARCH BAR
        Positioned(
          top: 16,
          left: 16,
          right: 16,

          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                ),
              ],
            ),

            child: const TextField(
              decoration: InputDecoration(
                hintText: "Search location or service...",
                prefixIcon: Icon(
                  Icons.search,
                  color: Color(0xFF8B5CF6),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ),

        /// MY LOCATION BUTTON
        Positioned(
          bottom: 20,
          right: 20,

          child: FloatingActionButton(
            backgroundColor: const Color(0xFF8B5CF6),

            onPressed: () {

              if (_currentLocation != null) {

                _mapController.move(
                  _currentLocation!,
                  15,
                );

              }

            },

            child: const Icon(Icons.my_location),
          ),
        ),

      ],
    );
  }
}