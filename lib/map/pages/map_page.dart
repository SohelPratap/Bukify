import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/map_search_service.dart';

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
  static const _violet = Color(0xFF8B5CF6);
  static const _violetMid = Color(0xFFA855F7);
  static const _violetSoft = Color(0xFFF3EEFF);
  static const _ink = Color(0xFF1E1B3A);

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _currentLocation;
  double _mapRotation = 0;

  List<dynamic> _markers = [];
  bool _searching = false;
  dynamic _selectedItem;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    if (!mounted) return;
    final latLng = LatLng(position.latitude, position.longitude);
    setState(() => _currentLocation = latLng);
    _mapController.move(latLng, 14);

    // Auto-load on open with no filter
    _loadMarkers();
  }

  Future<void> _loadMarkers({String? skill}) async {
    if (_currentLocation == null) return;
    setState(() {
      _searching = true;
      _selectedItem = null;
    });

    try {
      List<dynamic> results;
      if (widget.userRole == 'customer') {
        results = await MapSearchService.getWorkersForMap(
          lat: _currentLocation!.latitude,
          lng: _currentLocation!.longitude,
          skill: skill,
        );
      } else {
        results = await MapSearchService.getJobsForMap(
          lat: _currentLocation!.latitude,
          lng: _currentLocation!.longitude,
          skill: skill,
        );
      }
      if (!mounted) return;
      setState(() {
        _markers = results;
        _searching = false;
      });

      // Fit map to show all markers
      if (results.isNotEmpty) {
        _fitMarkers(results);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  void _fitMarkers(List<dynamic> items) {
    if (items.isEmpty || _currentLocation == null) return;

    double minLat = _currentLocation!.latitude;
    double maxLat = _currentLocation!.latitude;
    double minLng = _currentLocation!.longitude;
    double maxLng = _currentLocation!.longitude;

    for (final item in items) {
      final lat = double.tryParse(item['latitude']?.toString() ?? '') ?? 0;
      final lng = double.tryParse(item['longitude']?.toString() ?? '') ?? 0;
      if (lat == 0 && lng == 0) continue;
      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLng = math.min(minLng, lng);
      maxLng = math.max(maxLng, lng);
    }

    final bounds = LatLngBounds(
      LatLng(minLat - 0.01, minLng - 0.01),
      LatLng(maxLat + 0.01, maxLng + 0.01),
    );
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
    );
  }

  List<Marker> _buildMarkers() {
    final List<Marker> result = [];

    // My location marker
    if (_currentLocation != null) {
      result.add(
        Marker(
          point: _currentLocation!,
          width: 50,
          height: 50,
          child: Transform.rotate(
            angle: -_mapRotation * math.pi / 180,
            child: Container(
              decoration: BoxDecoration(
                color: _violet,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: _violet.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.my_location_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ),
      );
    }

    // Result markers
    for (final item in _markers) {
      final lat = double.tryParse(item['latitude']?.toString() ?? '') ?? 0;
      final lng = double.tryParse(item['longitude']?.toString() ?? '') ?? 0;
      if (lat == 0 && lng == 0) continue;

      final isSelected = _selectedItem != null &&
          _selectedItem['id'] == item['id'];
      final isMatch = item['is_skill_match']?.toString() == '1';
      final isOnline = item['is_online']?.toString() == '1';

      result.add(
        Marker(
          point: LatLng(lat, lng),
          width: isSelected ? 52 : 44,
          height: isSelected ? 52 : 44,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() =>
              _selectedItem = _selectedItem == item ? null : item);
              _mapController.move(LatLng(lat, lng), 15);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: widget.userRole == 'customer'
                    ? (isOnline ? Colors.green : Colors.grey)
                    : (isMatch ? _violet : Colors.orange),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white70,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.userRole == 'customer'
                        ? (isOnline ? Colors.green : Colors.grey)
                        : (isMatch ? _violet : Colors.orange))
                        .withOpacity(isSelected ? 0.6 : 0.3),
                    blurRadius: isSelected ? 14 : 6,
                    spreadRadius: isSelected ? 2 : 0,
                  ),
                ],
              ),
              child: Icon(
                widget.userRole == 'customer'
                    ? Icons.person_rounded
                    : Icons.work_rounded,
                color: Colors.white,
                size: isSelected ? 24 : 20,
              ),
            ),
          ),
        ),
      );
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLocation == null) {
      return Container(
        color: _violetSoft,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _violet),
              SizedBox(height: 16),
              Text("Getting your location…",
                  style: TextStyle(color: _violet,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // ── MAP ──────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation!,
            initialZoom: 14,
            onTap: (_, __) => setState(() => _selectedItem = null),
            onPositionChanged: (position, hasGesture) {
              setState(() => _mapRotation = position.rotation);
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: "com.bukify.app",
            ),

            // Service radius for worker
            if (widget.userRole == "worker" &&
                widget.serviceRadius != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: widget.serviceCenter ?? _currentLocation!,
                    radius: widget.serviceRadius! * 1000,
                    useRadiusInMeter: true,
                    color: _violet.withOpacity(0.08),
                    borderColor: _violet.withOpacity(0.4),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

            MarkerLayer(markers: _buildMarkers()),
          ],
        ),

        // ── SEARCH BAR ───────────────────────────────
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (q) => _loadMarkers(skill: q.trim()),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _ink,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.userRole == 'customer'
                        ? "Search workers by skill…"
                        : "Search jobs by skill…",
                    hintStyle: TextStyle(
                        color: Colors.grey[400], fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: _violet.withOpacity(0.7), size: 20),
                    suffixIcon: _searching
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _violet,
                        ),
                      ),
                    )
                        : _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.grey, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _loadMarkers();
                      },
                    )
                        : IconButton(
                      icon: Icon(
                          Icons.arrow_forward_rounded,
                          color: _violet, size: 18),
                      onPressed: () => _loadMarkers(
                          skill: _searchController.text
                              .trim()),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                      const BorderSide(color: _violet, width: 1.5),
                    ),
                  ),
                ),
              ),

              // Quick chips
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ["Plumber", "Electrician", "Cleaner",
                    "Painter", "Carpenter"]
                      .map((s) {
                    final isActive =
                        _searchController.text.toLowerCase() ==
                            s.toLowerCase();
                    return GestureDetector(
                      onTap: () {
                        _searchController.text = s;
                        _loadMarkers(skill: s);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                          isActive ? _violet : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                              Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF4B4569),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // ── RESULTS COUNT PILL ───────────────────────
        if (_markers.isNotEmpty)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _violet,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _violet.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.userRole == 'customer'
                          ? Icons.person_rounded
                          : Icons.work_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${_markers.length} ${widget.userRole == 'customer' ? 'worker' : 'job'}${_markers.length != 1 ? 's' : ''} nearby",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── SELECTED ITEM CARD ───────────────────────
        if (_selectedItem != null)
          Positioned(
            bottom: 70,
            left: 16,
            right: 16,
            child: _buildInfoCard(_selectedItem!),
          ),

        // ── MY LOCATION BUTTON ───────────────────────
        Positioned(
          bottom: _markers.isNotEmpty ? 80 : 24,
          right: 16,
          child: GestureDetector(
            onTap: () {
              if (_currentLocation != null) {
                _mapController.move(_currentLocation!, 14);
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.my_location_rounded,
                  color: _violet, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(dynamic item) {
    final isCustomer = widget.userRole == 'customer';
    final distance =
        double.tryParse(item['distance_km']?.toString() ?? '0') ?? 0;
    final isMatch = item['is_skill_match']?.toString() == '1';
    final isOnline = item['is_online']?.toString() == '1';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Avatar / icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCustomer
                        ? (isOnline
                        ? [Colors.green.shade400, Colors.green.shade600]
                        : [Colors.grey.shade400, Colors.grey.shade600])
                        : (isMatch
                        ? [_violet, _violetMid]
                        : [Colors.orange.shade400,
                      Colors.orange.shade600]),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCustomer
                      ? Text(
                    _initials(item['full_name'] ?? item['email']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  )
                      : const Icon(Icons.work_rounded,
                      color: Colors.white, size: 20),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCustomer
                          ? (item['full_name'] ?? 'Worker')
                          : (item['title'] ?? 'Job'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCustomer
                          ? (item['email'] ?? '')
                          : (item['skill_name'] ?? ''),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Distance pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _violet.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.near_me_rounded,
                        size: 11, color: _violet),
                    const SizedBox(width: 4),
                    Text(
                      "${distance.toStringAsFixed(1)} km",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _violet,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Extra info
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 10),

          Row(
            children: [
              if (isCustomer) ...[
                _InfoPill(
                  icon: Icons.star_rounded,
                  label:
                  "${double.tryParse(item['rating']?.toString() ?? '0')?.toStringAsFixed(1)} ★",
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  icon: Icons.work_history_rounded,
                  label: "${item['experience_years'] ?? 0} yrs",
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  icon: isOnline
                      ? Icons.circle
                      : Icons.circle_outlined,
                  label: isOnline ? "Online" : "Offline",
                  color: isOnline ? Colors.green : Colors.grey,
                ),
              ] else ...[
                _InfoPill(
                  icon: Icons.handyman_rounded,
                  label: item['skill_name'] ?? '—',
                  color: isMatch ? _violet : Colors.orange,
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  icon: Icons.person_outline_rounded,
                  label: item['customer_email']
                      ?.toString()
                      .split('@')[0] ??
                      '—',
                  color: Colors.grey,
                ),
                if (isMatch) ...[
                  const SizedBox(width: 8),
                  _InfoPill(
                    icon: Icons.verified_rounded,
                    label: "Skill Match",
                    color: _violet,
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}