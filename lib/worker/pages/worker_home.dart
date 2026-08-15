import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'worker_profile_page.dart';
import '../../map/pages/map_page.dart';
import 'package:latlong2/latlong.dart';
import '../../services/worker_service.dart';
import 'latest_job_page.dart';
import 'worker_history_page.dart';
import 'worker_search_page.dart';

class HomeWorkerPage extends StatefulWidget {
  const HomeWorkerPage({super.key});

  @override
  State<HomeWorkerPage> createState() => _HomeWorkerPageState();
}

class _HomeWorkerPageState extends State<HomeWorkerPage>
    with TickerProviderStateMixin {
  int _currentIndex = 2;

  double? _serviceRadius;
  LatLng? _serviceCenter;

  final GlobalKey<WorkerProfilePageState> _profileKey =
  GlobalKey<WorkerProfilePageState>();

  late AnimationController _fabController;

  static const _primary = Color(0xFF0072FF); // Navy/Dark Blue
  static const _primaryMid = Color(0xFF00C6FF); // Bright Blue

  // Nav config
  static const _navItems = [
    _NavItem(icon: Icons.search_rounded, label: "Search"),
    _NavItem(icon: Icons.map_rounded, label: "Map"),
    _NavItem(icon: Icons.bolt_rounded, label: "Latest", isFeatured: true),
    _NavItem(icon: Icons.history_rounded, label: "History"),
    _NavItem(icon: Icons.person_rounded, label: "Profile"),
  ];

  static const _titles = [
    "Search Jobs",
    "Map",
    "Latest Jobs",
    "My History",
    "Profile",
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _loadServiceArea();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceArea() async {
    try {
      final area = await WorkerService.getServiceArea();
      if (area != null) {
        setState(() {
          _serviceRadius = double.parse(area['radius_km'].toString());
          _serviceCenter = LatLng(
            double.parse(area['center_lat'].toString()),
            double.parse(area['center_lng'].toString()),
          );
        });
      }
    } catch (e) {
      debugPrint("Service area load error: $e");
    }
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();

    _fabController.reset();
    _fabController.forward();

    setState(() => _currentIndex = index);

    if (index == 4) {
      _profileKey.currentState?.reloadProfile();
    }
    if (index == 1) {
      _loadServiceArea();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const WorkerSearchPage(),
      MapPage(
        userRole: "worker",
        serviceRadius: _serviceRadius,
        serviceCenter: _serviceCenter,
      ),
      const LatestJobsPage(),
      const WorkerHistoryPage(),
      WorkerProfilePage(key: _profileKey),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryMid, _primary],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
      ),
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Row(
          key: ValueKey(_currentIndex),
          children: [
            // Page icon
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _navItems[_currentIndex].icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _titles[_currentIndex],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // BukiFy branding pill
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.construction_rounded,
                  color: Colors.white, size: 13),
              SizedBox(width: 5),
              Text(
                "BukiFy",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isActive = _currentIndex == i;

              if (item.isFeatured) {
                return GestureDetector(
                  onTap: () => _onNavTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryMid, _primary],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(isActive ? 0.4 : 0.2),
                          blurRadius: isActive ? 14 : 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      item.icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                );
              }

              return GestureDetector(
                onTap: () => _onNavTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _primary.withOpacity(0.09)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isActive ? _primary : Colors.grey.shade400,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isActive
                              ? _primary
                              : Colors.grey.shade400,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final bool isFeatured;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isFeatured = false,
  });
}