import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  final String userRole;
  final double? serviceRadius;
  final LatLng? serviceCenter;

  const MapPage({
    super.key,
    required this.userRole,
    this.serviceRadius,
    this.serviceCenter,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  LatLng? _currentLocation;
  double _mapRotation = 0;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final latLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _currentLocation = latLng;
    });

    _mapController.move(latLng, 15);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation!,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onPositionChanged: (position, hasGesture) {
          setState(() {
            _mapRotation = position.rotation;
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: "com.bukify.app",
        ),

        /// 🔥 Upright Marker
        MarkerLayer(
          markers: [
            Marker(
              point: _currentLocation!,
              width: 60,
              height: 60,
              child: Transform.rotate(
                angle: -_mapRotation * math.pi / 180,
                child: const Icon(
                  Icons.person_pin_circle,
                  color: Color(0xFF8B5CF6),
                  size: 50,
                ),
              ),
            ),
          ],
        ),

        /// 🔥 Service Radius Circle
        if (widget.userRole == "worker" &&
            widget.serviceRadius != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: widget.serviceCenter ?? _currentLocation!,
                radius: widget.serviceRadius! * 1000,
                useRadiusInMeter: true,
                color: const Color(0xFF8B5CF6).withOpacity(0.15),
                borderColor: const Color(0xFF8B5CF6),
                borderStrokeWidth: 2,
              ),
            ],
          ),
      ],
    );
  }
}