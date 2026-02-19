import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  final MapController _mapController = MapController();

  final LatLng _defaultLocation = const LatLng(21.2514, 81.6296);

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [

        /// FULL SCREEN MAP
        FlutterMap(

          mapController: _mapController,

          options: MapOptions(
            initialCenter: _defaultLocation,
            initialZoom: 13,
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
                  point: _defaultLocation,
                  width: 60,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFFA855F7),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.4),
                          blurRadius: 12,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.person_pin_circle,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),

          ],
        ),

        /// SEARCH BAR (FLOATING)
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
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            child: TextField(
              decoration: InputDecoration(
                hintText: "Search location or service...",
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF8B5CF6),
                ),
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14),
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
              _mapController.move(_defaultLocation, 15);
            },

            child: const Icon(Icons.my_location),
          ),
        ),

      ],
    );
  }
}