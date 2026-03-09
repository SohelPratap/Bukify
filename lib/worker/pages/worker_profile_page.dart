import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../services/skill_service.dart';
import '../../../auth/services/session_service.dart';
import '../../../onboarding/pages/login.dart';
import '../../widgets/skill_selector.dart';
import '../../services/worker_service.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class WorkerProfilePage extends StatefulWidget {
  const WorkerProfilePage({super.key});

  @override
  State<WorkerProfilePage> createState() => WorkerProfilePageState();
}

class WorkerProfilePageState extends State<WorkerProfilePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ── palette ───────────────────────────────────────────
  static const _violet = Color(0xFF8B5CF6);
  static const _violetMid = Color(0xFFA855F7);
  static const _violetSoft = Color(0xFFF3EEFF);
  static const _ink = Color(0xFF1E1B3A);

  Map<String, dynamic>? _profile;
  bool _loading = true;

  bool _isOnline = false;

  bool _editSkills = false;
  List<dynamic> _skills = [];

  Timer? _locationTimer;

  double _serviceRadius = 10;
  bool _savingRadius = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSkills();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ProfileService.getProfile();
      final area = await WorkerService.getServiceArea();

      setState(() {
        _profile = data;
        _isOnline = data['is_online'] == 1;

        if (area != null) {
          _serviceRadius = (area['radius_km']).toDouble();
        }

        _loading = false;
      });

      if (_isOnline) {
        _startLocationUpdates();
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleOnline() async {
    final newStatus = !_isOnline;

    try {
      await WorkerService.toggleOnline(newStatus);

      setState(() {
        _isOnline = newStatus;
        _profile!['is_online'] = newStatus ? 1 : 0;
      });

      if (newStatus) {
        _startLocationUpdates();
      } else {
        _stopLocationUpdates();
      }
    } catch (e) {
      debugPrint("Toggle error: $e");
    }
  }

  Future<void> _loadSkills() async {
    try {
      final skills = await SkillService.getMySkills();
      setState(() {
        _skills = skills;
      });
    } catch (e) {
      debugPrint("Skill load error: $e");
    }
  }

  Future<void> _addSkill(Map skill) async {
    try {
      await SkillService.addSkill(skill['id']);
      await _loadSkills();
      setState(() {
        _editSkills = false;
      });
    } catch (e) {
      debugPrint("Add skill error: $e");
    }
  }

  Future<void> _saveServiceArea() async {
    setState(() => _savingRadius = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await WorkerService.updateServiceArea(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: _serviceRadius,
      );

      debugPrint("Service area saved");
    } catch (e) {
      debugPrint("Service area error: $e");
    }

    setState(() => _savingRadius = false);
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

  void _startLocationUpdates() {
    if (_locationTimer != null) return;

    _locationTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) async {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          await WorkerService.updateLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            heading: position.heading,
            speed: position.speed,
          );

          debugPrint("Location sent");
        } catch (e) {
          debugPrint("Location error: $e");
        }
      },
    );
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  void reloadProfile() {
    _loadProfile();
  }

  void _confirmRemoveSkill(Map skill) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Remove Skill",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _ink,
          ),
        ),
        content: Text(
          "Remove \"${skill['name']}\"?",
          style: TextStyle(color: Colors.grey[500]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await SkillService.removeSkill(skill['id']);
              _loadSkills();
            },
            child: const Text(
              "Remove",
              style: TextStyle(
                  color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _violet),
      );
    }

    if (_profile == null) {
      return const Center(child: Text('Failed to load profile'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [

          // ── HEADER ────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), _violetMid],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // Avatar with subtle ring
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  _profile!['full_name'] ?? 'Add your name',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _profile!['full_name'] != null
                        ? Colors.white
                        : Colors.white60,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _profile!['email'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 14),

                // Online toggle pill
                _buildOnlineToggle(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [

                // ── SKILLS CARD ───────────────────────
                _buildSkillsCard(),

                const SizedBox(height: 16),

                // ── SERVICE AREA CARD ─────────────────
                _buildServiceAreaCard(),

                const SizedBox(height: 16),

                // ── EXPERIENCE ────────────────────────
                _buildInfoCard(
                  icon: Icons.work_history_rounded,
                  title: "Experience",
                  value: "${_profile!['experience_years']} years",
                  color: const Color(0xFFF59E0B),
                ),

                const SizedBox(height: 16),

                // ── RATING ────────────────────────────
                _buildInfoCard(
                  icon: Icons.star_rounded,
                  title: "Rating",
                  value: "${_profile!['rating']} ⭐",
                  color: const Color(0xFF10B981),
                ),

                const SizedBox(height: 32),

                // ── LOGOUT ────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded,
                        color: Color(0xFFEF4444), size: 20),
                    label: const Text(
                      "Logout",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.red.shade200, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ONLINE TOGGLE ─────────────────────────────────────
  Widget _buildOnlineToggle() {
    return GestureDetector(
      onTap: _toggleOnline,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: _isOnline
              ? Colors.green.withOpacity(0.18)
              : Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _isOnline ? Colors.greenAccent : Colors.red.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _isOnline ? Colors.greenAccent : Colors.red.shade300,
                shape: BoxShape.circle,
                boxShadow: _isOnline
                    ? [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.6),
                    blurRadius: 6,
                  )
                ]
                    : [],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isOnline ? "Online" : "Offline",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _isOnline
                    ? Colors.greenAccent
                    : Colors.red.shade300,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.touch_app_rounded,
              size: 13,
              color: _isOnline
                  ? Colors.greenAccent.withOpacity(0.7)
                  : Colors.red.shade200,
            ),
          ],
        ),
      ),
    );
  }

  // ── SKILLS CARD ───────────────────────────────────────
  Widget _buildSkillsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _violet.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _violet.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.handyman_rounded,
                        color: _violet, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Skills",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _editSkills = !_editSkills),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _editSkills
                        ? Colors.grey.shade100
                        : _violetSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _editSkills ? Icons.close_rounded : Icons.edit_rounded,
                        color: _editSkills ? Colors.grey : _violet,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _editSkills ? "Done" : "Edit",
                        style: TextStyle(
                          color: _editSkills ? Colors.grey : _violet,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Skill chips
          _skills.isEmpty && !_editSkills
              ? Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Color(0xFFBBB0D6), size: 18),
                SizedBox(width: 10),
                Text(
                  "No skills added yet",
                  style: TextStyle(
                    color: Color(0xFFBBB0D6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
              : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._skills.map((skill) {
                final approved = skill['status'] == 'approved';
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: approved
                            ? Colors.green.withOpacity(0.08)
                            : Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: approved
                              ? Colors.green.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            approved
                                ? Icons.verified_rounded
                                : Icons.schedule_rounded,
                            size: 14,
                            color: approved
                                ? Colors.green
                                : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            skill['name'],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: approved
                                  ? const Color(0xFF1E1B3A)
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_editSkills)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: GestureDetector(
                          onTap: () => _confirmRemoveSkill(skill),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),

              // Add skill button
              if (_editSkills)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text(
                          "Add Skill",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _ink,
                          ),
                        ),
                        content: SkillSelector(
                          onSkillSelected: (skill) {
                            Navigator.pop(context);
                            _addSkill(skill);
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _violet,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          "Add",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SERVICE AREA CARD ─────────────────────────────────
  Widget _buildServiceAreaCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _violet.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _violet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.radar_rounded,
                    color: _violet, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                "Service Radius",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _violetSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${_serviceRadius.toStringAsFixed(0)} km",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _violet,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _violet,
              inactiveTrackColor: _violetSoft,
              thumbColor: _violet,
              overlayColor: _violet.withOpacity(0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8),
            ),
            child: Slider(
              min: 1,
              max: 50,
              divisions: 49,
              value: _serviceRadius,
              onChanged: (value) {
                setState(() => _serviceRadius = value);
              },
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("1 km",
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[400])),
              Text("50 km",
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[400])),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _savingRadius ? null : _saveServiceArea,
              style: ElevatedButton.styleFrom(
                backgroundColor: _violet,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _savingRadius
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                "Save Area",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── INFO CARD ─────────────────────────────────────────
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _ink,
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