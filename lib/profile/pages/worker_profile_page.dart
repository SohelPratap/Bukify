import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../../auth/services/session_service.dart';
import '../../../onboarding/pages/login.dart';

class WorkerProfilePage extends StatefulWidget {
  const WorkerProfilePage({super.key});

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ProfileService.getProfile();
      setState(() {
        _profile = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await SessionService.clearSession();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profile == null) {
      return const Center(child: Text('Failed to load profile'));
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _profile!['full_name'] ?? 'Add your name',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_profile!['email']),
          const SizedBox(height: 8),
          Text("Skills: ${_profile!['skills'] ?? 'Not added'}"),
          const SizedBox(height: 8),
          Text("Experience: ${_profile!['experience_years']} years"),
          const SizedBox(height: 8),
          Text("Rating: ${_profile!['rating']} ⭐"),
          const Spacer(),
          ElevatedButton(
            onPressed: _logout,
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}