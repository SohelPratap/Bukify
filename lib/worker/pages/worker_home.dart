import 'package:flutter/material.dart';
import 'worker_profile_page.dart';
import '../../map/pages/map_page.dart';
import 'package:latlong2/latlong.dart';
import '../../services/worker_service.dart';

class HomeWorkerPage extends StatefulWidget {
  const HomeWorkerPage({super.key});

  @override
  State<HomeWorkerPage> createState() => _HomeWorkerPageState();
}

class _HomeWorkerPageState extends State<HomeWorkerPage> {
  int _currentIndex = 0;

  double? _serviceRadius;
  LatLng? _serviceCenter;

  final GlobalKey<WorkerProfilePageState> _profileKey =
  GlobalKey<WorkerProfilePageState>();

  @override
  void initState() {
    super.initState();
    _loadServiceArea();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "BukiFy Worker",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),

      body: [
        const RequestsPage(),

        MapPage(
          userRole: "worker",
          serviceRadius: _serviceRadius,
          serviceCenter: _serviceCenter,
        ),

        WorkerProfilePage(key: _profileKey),
      ][_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF8B5CF6),
        onTap: (index) async {
          setState(() => _currentIndex = index);

          if (index == 2) {
            _profileKey.currentState?.reloadProfile();
          }

          // When coming back to map, refresh area
          if (index == 1) {
            await _loadServiceArea();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: "Requests",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: "Map",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

// Requests Page
class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Service Requests",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 16),
            _buildRequestCard("House Cleaning", "Customer: Shrawan", "₹499/hr", Icons.cleaning_services, const Color(0xFF4F46E5)),
            const SizedBox(height: 12),
            _buildRequestCard("AC Repair", "Customer: Sohel", "₹599/visit", Icons.ac_unit, const Color(0xFF06B6D4)),
            const SizedBox(height: 12),
            _buildRequestCard("Plumbing", "Customer: Karmendra", "₹399/hr", Icons.plumbing, const Color(0xFFF59E0B)),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(String title, String subtitle, String price, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              price,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
