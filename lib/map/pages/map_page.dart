import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/map_search_service.dart';
import '../../services/skills_service.dart';
import '../../customer/pages/worker_public_profile_page.dart';

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

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  static const _violet = Color(0xFF8B5CF6);
  static const _violetMid = Color(0xFFA855F7);
  static const _violetSoft = Color(0xFFF3EEFF);
  static const _ink = Color(0xFF1E1B3A);

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _cardAnimController;
  late Animation<Offset> _cardSlideAnim;

  LatLng? _currentLocation;
  double _mapRotation = 0;

  List<dynamic> _markers = [];
  List<String> _allSkills = [];           // ← loaded from API
  List<String> _autocompleteResults = [];
  bool _searching = false;
  bool _showAutocomplete = false;
  dynamic _selectedItem;
  String? _startingJobId;

  @override
  void initState() {
    super.initState();

    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _cardSlideAnim = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimController,
      curve: Curves.easeOutCubic,
    ));

    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() => _showAutocomplete = false);
      }
    });

    _getLocation();
    _fetchSkills(); // ← fetch from DB on init
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _cardAnimController.dispose();
    super.dispose();
  }

  // ── fetch skill names from DB once ───────────────────
  Future<void> _fetchSkills() async {
    try {
      final skills = await SkillService.getSkills();
      if (!mounted) return;
      setState(() => _allSkills = skills);
    } catch (_) {
      // autocomplete silently unavailable; search still works
    }
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
    _loadMarkers();
  }

  // ── filter _allSkills as user types ──────────────────
  void _onSearchChanged() {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      setState(() {
        _autocompleteResults = [];
        _showAutocomplete = false;
      });
      return;
    }
    final lower = q.toLowerCase();
    final matches = _allSkills
        .where((s) =>
    s.toLowerCase().startsWith(lower) ||
        s.toLowerCase().contains(lower))
        .take(6)
        .toList();
    setState(() {
      _autocompleteResults = matches;
      _showAutocomplete = matches.isNotEmpty && _searchFocusNode.hasFocus;
    });
  }

  void _selectAutocomplete(String skill) {
    _searchController.text = skill;
    _searchFocusNode.unfocus();
    setState(() {
      _showAutocomplete = false;
      _autocompleteResults = [];
    });
    _loadMarkers(skill: skill);
  }

  Future<void> _loadMarkers({String? skill}) async {
    if (_currentLocation == null) return;
    setState(() {
      _searching = true;
      _selectedItem = null;
    });
    _cardAnimController.reverse();

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
      if (results.isNotEmpty) _fitMarkers(results);
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

  void _selectMarker(dynamic item) {
    HapticFeedback.selectionClick();
    final double lat = double.tryParse(item['latitude']?.toString() ?? '') ?? 0;
    final double lng = double.tryParse(item['longitude']?.toString() ?? '') ?? 0;
    setState(() => _selectedItem = item);
    _mapController.move(LatLng(lat, lng), 15);
    _cardAnimController.forward();
  }

  void _dismissCard() {
    _cardAnimController.reverse().then((_) {
      if (mounted) setState(() => _selectedItem = null);
    });
  }

  List<Marker> _buildMarkers() {
    final List<Marker> result = [];

    if (_currentLocation != null) {
      result.add(Marker(
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
      ));
    }

    for (final item in _markers) {
      final lat = double.tryParse(item['latitude']?.toString() ?? '') ?? 0;
      final lng = double.tryParse(item['longitude']?.toString() ?? '') ?? 0;
      if (lat == 0 && lng == 0) continue;

      final isSelected =
          _selectedItem != null && _selectedItem['id'] == item['id'];
      final isMatch = item['is_skill_match']?.toString() == '1';
      final isOnline = item['is_online']?.toString() == '1';

      Color markerColor;
      IconData markerIcon;

      if (widget.userRole == 'customer') {
        markerColor = isOnline ? const Color(0xFF10B981) : Colors.grey;
        markerIcon = Icons.person_rounded;
      } else {
        markerColor = isMatch ? _violet : const Color(0xFFF59E0B);
        markerIcon = Icons.work_rounded;
      }

      result.add(Marker(
        point: LatLng(lat, lng),
        width: isSelected ? 56 : 46,
        height: isSelected ? 56 : 46,
        child: GestureDetector(
          onTap: () => _selectMarker(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white70,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: markerColor.withOpacity(isSelected ? 0.6 : 0.3),
                  blurRadius: isSelected ? 18 : 8,
                  spreadRadius: isSelected ? 3 : 0,
                ),
              ],
            ),
            child: Icon(markerIcon,
                color: Colors.white, size: isSelected ? 26 : 20),
          ),
        ),
      ));
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
                  style: TextStyle(
                      color: _violet, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
        if (_selectedItem != null) _dismissCard();
      },
      child: Stack(
        children: [
          // ── MAP ──────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation!,
              initialZoom: 14,
              onTap: (_, __) {
                _searchFocusNode.unfocus();
                if (_selectedItem != null) _dismissCard();
              },
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

          // ── SEARCH BAR + AUTOCOMPLETE ─────────────────
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _buildSearchBar(),
                if (_showAutocomplete && _autocompleteResults.isNotEmpty)
                  _buildAutocompleteDropdown(),
              ],
            ),
          ),

          // ── RESULTS COUNT PILL ───────────────────────
          if (_markers.isNotEmpty && _selectedItem == null)
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

          // ── SELECTED ITEM CARD (animated) ────────────
          if (_selectedItem != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: SlideTransition(
                position: _cardSlideAnim,
                child: widget.userRole == 'customer'
                    ? _WorkerInfoCard(
                  item: _selectedItem!,
                  onClose: _dismissCard,
                  onViewProfile: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerPublicProfilePage(
                          worker: _selectedItem!,
                        ),
                      ),
                    );
                  },
                )
                    : _JobInfoCard(
                  item: _selectedItem!,
                  isStarting:
                  _startingJobId == _selectedItem!['id'],
                  onClose: _dismissCard,
                  onStart: () => _startJob(_selectedItem!['id']),
                ),
              ),
            ),

          // ── MY LOCATION BUTTON ───────────────────────
          Positioned(
            bottom: _selectedItem != null
                ? 230
                : (_markers.isNotEmpty ? 80 : 24),
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
      ),
    );
  }

  // ── SEARCH BAR ────────────────────────────────────────
  Widget _buildSearchBar() {
    final isCustomer = widget.userRole == 'customer';
    return Container(
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
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: (q) {
          _searchFocusNode.unfocus();
          setState(() => _showAutocomplete = false);
          _loadMarkers(skill: q.trim());
        },
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _ink,
        ),
        decoration: InputDecoration(
          hintText: isCustomer
              ? "Search workers by skill…"
              : "Search jobs by skill…",
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded,
              color: _violet.withOpacity(0.7), size: 20),
          suffixIcon: _searching
              ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _violet),
            ),
          )
              : _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded,
                color: Colors.grey, size: 18),
            onPressed: () {
              _searchController.clear();
              _searchFocusNode.unfocus();
              setState(() => _showAutocomplete = false);
              _loadMarkers();
            },
          )
              : IconButton(
            icon: Icon(Icons.arrow_forward_rounded,
                color: _violet, size: 18),
            onPressed: () {
              _searchFocusNode.unfocus();
              _loadMarkers(
                  skill: _searchController.text.trim());
            },
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
            borderSide: const BorderSide(color: _violet, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── AUTOCOMPLETE DROPDOWN ─────────────────────────────
  Widget _buildAutocompleteDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: _autocompleteResults.asMap().entries.map((entry) {
            final i = entry.key;
            final skill = entry.value;
            return Column(
              children: [
                if (i > 0) Divider(height: 1, color: Colors.grey.shade100),
                InkWell(
                  onTap: () => _selectAutocomplete(skill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _violet.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.userRole == 'customer'
                                ? Icons.person_search
                                : Icons.work_outline,
                            size: 14,
                            color: _violet,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _ink,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.north_west_rounded,
                            size: 14, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── START JOB (worker role) ───────────────────────────
  Future<void> _startJob(String jobId) async {
    HapticFeedback.mediumImpact();
    setState(() => _startingJobId = jobId);
    try {
      // await WorkerJobsService.startJob(jobId); // ← wire up your service
      await Future.delayed(const Duration(milliseconds: 800)); // placeholder
      if (!mounted) return;
      _dismissCard();
      setState(() => _markers.removeWhere((j) => j['id'] == jobId));
      _showSnack("Job started successfully!");
    } catch (_) {
      if (!mounted) return;
      _showSnack("Failed to start job", isError: true);
    }
    if (!mounted) return;
    setState(() => _startingJobId = null);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(msg),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  WORKER INFO CARD (customer role)
// ══════════════════════════════════════════════════════
class _WorkerInfoCard extends StatelessWidget {
  const _WorkerInfoCard({
    required this.item,
    required this.onClose,
    required this.onViewProfile,
  });

  final dynamic item;
  final VoidCallback onClose;
  final VoidCallback onViewProfile;

  static const _violet = Color(0xFF8B5CF6);
  static const _violetMid = Color(0xFFA855F7);
  static const _ink = Color(0xFF1E1B3A);

  @override
  Widget build(BuildContext context) {
    final bool isOnline = item['is_online']?.toString() == '1';
    final double rating =
        double.tryParse(item['rating']?.toString() ?? '0') ?? 0;
    final double distance =
        double.tryParse(item['distance_km']?.toString() ?? '0') ?? 0;
    final int experience =
        int.tryParse(item['experience_years']?.toString() ?? '0') ?? 0;
    final String skillsList = item['skills_list'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), _violetMid],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.5), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _initials(item['full_name'] ?? item['email']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.greenAccent : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['full_name'] ?? 'Worker',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOnline ? "Available now" : "Offline",
                        style: TextStyle(
                          color: isOnline
                              ? Colors.greenAccent
                              : Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _StatPill(
                        icon: Icons.star_rounded,
                        label: rating.toStringAsFixed(1),
                        color: const Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    _StatPill(
                        icon: Icons.work_history_rounded,
                        label: "$experience yrs exp",
                        color: const Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    _StatPill(
                        icon: Icons.near_me_rounded,
                        label: "${distance.toStringAsFixed(1)} km",
                        color: _violet),
                  ],
                ),
                if (skillsList.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.handyman_rounded,
                          size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          skillsList,
                          style: TextStyle(
                            fontSize: 12,
                            color: _violet.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: onViewProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _violet,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text("View Full Profile",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white70, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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

// ══════════════════════════════════════════════════════
//  JOB INFO CARD (worker role)
// ══════════════════════════════════════════════════════
class _JobInfoCard extends StatelessWidget {
  const _JobInfoCard({
    required this.item,
    required this.isStarting,
    required this.onClose,
    required this.onStart,
  });

  final dynamic item;
  final bool isStarting;
  final VoidCallback onClose;
  final VoidCallback onStart;

  static const _violet = Color(0xFF8B5CF6);
  static const _violetSoft = Color(0xFFF3EEFF);
  static const _ink = Color(0xFF1E1B3A);

  @override
  Widget build(BuildContext context) {
    final bool isMatch = item['is_skill_match']?.toString() == '1';
    final double distance =
        double.tryParse(item['distance_km']?.toString() ?? '0') ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: isMatch
            ? Border.all(color: _violet.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              color: isMatch ? _violetSoft : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isMatch
                          ? [
                        const Color(0xFF7C3AED),
                        const Color(0xFFA855F7)
                      ]
                          : [
                        Colors.orange.shade400,
                        Colors.orange.shade600
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.work_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? 'Job',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.handyman_rounded,
                              size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            item['skill_name'] ?? '—',
                            style: TextStyle(
                              fontSize: 12,
                              color: isMatch ? _violet : Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isMatch)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _violet,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            color: Colors.white, size: 10),
                        SizedBox(width: 3),
                        Text("Match",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close_rounded,
                        color: Colors.grey[600], size: 16),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatPill(
                        icon: Icons.near_me_rounded,
                        label: "${distance.toStringAsFixed(1)} km away",
                        color: _violet),
                    const SizedBox(width: 8),
                    _StatPill(
                        icon: Icons.person_outline_rounded,
                        label: item['customer_email']
                            ?.toString()
                            .split('@')[0] ??
                            '—',
                        color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isStarting ? null : onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isStarting ? Colors.grey.shade200 : _violet,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isStarting
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: _violet, strokeWidth: 2.5))
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text("Start This Job",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  SHARED STAT PILL
// ══════════════════════════════════════════════════════
class _StatPill extends StatelessWidget {
  const _StatPill(
      {required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}