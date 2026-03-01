import 'package:flutter/material.dart';
import 'worker_profile_page.dart';
import '../../map/pages/map_page.dart';
import 'package:latlong2/latlong.dart';
import '../../services/worker_service.dart';
import 'latest_job_page.dart';
import 'worker_history_page.dart';

class HomeWorkerPage extends StatefulWidget {
  const HomeWorkerPage({super.key});

  @override
  State<HomeWorkerPage> createState() => _HomeWorkerPageState();
}

class _HomeWorkerPageState extends State<HomeWorkerPage> {
  int _currentIndex = 2; // default open Latest Jobs

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
    final pages = [
      const SearchJobsPage(),
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
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF8B5CF6),
        onTap: (index) async {
          setState(() => _currentIndex = index);

          if (index == 4) {
            _profileKey.currentState?.reloadProfile();
          }

          if (index == 1) {
            await _loadServiceArea();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Search",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: "Map",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.new_releases_outlined),
            label: "Latest",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "History",
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




class SearchJobsPage extends StatelessWidget {
  const SearchJobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Search Jobs Page",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8B5CF6),
        ),
      ),
    );
  }
}

