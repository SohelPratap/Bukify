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

  Map<String, dynamic>? _profile;
  bool _loading = true;

  bool _isOnline = false;

  bool _editSkills = false;
  List<dynamic> _skills = [];

  Timer? _locationTimer;

  double _serviceRadius = 10; // default 10km
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

  /// LOAD PROFILE
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
        _startLocationUpdates(); // resume timer if already online
      }

    } catch (_) {
      setState(() => _loading = false);
    }
  }
  /// Online Offline toggle
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

  /// LOAD SKILLS FROM BACKEND
  Future<void> _loadSkills() async {

    try {

      final skills =
      await SkillService.getMySkills();

      setState(() {
        _skills = skills;
      });

    } catch (e) {

      debugPrint("Skill load error: $e");

    }
  }

  /// ADD SKILL
  Future<void> _addSkill(Map skill) async {

    try {

      await SkillService.addSkill(
        skill['id'],
      );

      await _loadSkills();

      setState(() {
        _editSkills = false;
      });

    } catch (e) {

      debugPrint("Add skill error: $e");

    }
  }

  /// service area
  Future<void> _saveServiceArea() async {
    setState(() {
      _savingRadius = true;
    });

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

    setState(() {
      _savingRadius = false;
    });
  }

  /// LOGOUT
  Future<void> _logout() async {

    await SessionService.clearSession();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const LoginPage(),
      ),
          (route) => false,
    );
  }
  ///Online toggle
  Widget _buildOnlineToggle() {
    return GestureDetector(
      onTap: _toggleOnline,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _isOnline
              ? Colors.green.withOpacity(0.15)
              : Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isOnline
                ? Colors.green
                : Colors.redAccent,
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
                color: _isOnline ? Colors.green : Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _isOnline ? "Online" : "Offline",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isOnline ? Colors.green : Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// SKILLS CARD
  Widget _buildSkillsCard() {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
      ),

      child: Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          /// HEADER
          Row(

            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

            children: [

              const Text(
                "Skills",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              IconButton(

                icon: Icon(
                  _editSkills
                      ? Icons.close
                      : Icons.edit,
                  color:
                  const Color(0xFF8B5CF6),
                ),

                onPressed: () {

                  setState(() {

                    _editSkills =
                    !_editSkills;

                  });

                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// SKILL CHIPS
          Wrap(

            spacing: 8,
            runSpacing: 8,

            children: [

              ..._skills.map((skill) {

                final approved =
                    skill['status'] == 'approved';

                return Stack(

                  children: [

                    Chip(

                      label:
                      Text(skill['name']),

                      avatar: Icon(
                        Icons.verified,
                        size: 18,
                        color:
                        approved
                            ? Colors.green
                            : Colors.grey,
                      ),

                      backgroundColor:
                      approved
                          ? Colors.green
                          .withOpacity(0.1)
                          : Colors.grey
                          .withOpacity(0.1),
                    ),

                    /// REMOVE BUTTON
                    if (_editSkills)

                      Positioned(

                        right: -6,
                        top: -6,

                        child:
                        GestureDetector(

                          onTap: () =>
                              _confirmRemoveSkill(
                                  skill),

                          child: Container(

                            decoration:
                            const BoxDecoration(
                              color: Colors.red,
                              shape:
                              BoxShape.circle,
                            ),

                            padding:
                            const EdgeInsets.all(
                                3),

                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                );

              }),

              /// ADD BUTTON
              if (_editSkills)

                GestureDetector(

                  onTap: () {

                    showDialog(

                      context: context,

                      builder: (_) =>
                          AlertDialog(

                            title:
                            const Text(
                                "Add Skill"),

                            content:
                            SkillSelector(

                              onSkillSelected:
                                  (skill) {

                                Navigator.pop(
                                    context);

                                _addSkill(
                                    skill);

                              },
                            ),
                          ),
                    );
                  },

                  child: Container(

                    padding:
                    const EdgeInsets.all(
                        8),

                    decoration:
                    BoxDecoration(

                      color:
                      const Color(
                          0xFF8B5CF6),

                      borderRadius:
                      BorderRadius
                          .circular(
                          20),
                    ),

                    child:
                    const Icon(
                      Icons.add,
                      color:
                      Colors.white,
                    ),
                  ),
                ),

            ],
          ),
        ],
      ),
    );
  }


///service area
  Widget _buildServiceAreaCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Service Radius",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            "${_serviceRadius.toStringAsFixed(0)} km",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B5CF6),
            ),
          ),

          Slider(
            min: 1,
            max: 50,
            divisions: 49,
            value: _serviceRadius,
            activeColor: const Color(0xFF8B5CF6),
            onChanged: (value) {
              setState(() {
                _serviceRadius = value;
              });
            },
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingRadius ? null : _saveServiceArea,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  : const Text("Save Area"),
            ),
          ),
        ],
      ),
    );
  }

  /// INFO CARD
  Widget _buildInfoCard(
      IconData icon,
      String title,
      String value,
      Color color
      ) {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),

        boxShadow: [

          BoxShadow(
            color:
            color.withOpacity(0.15),
            blurRadius: 15,
            offset:
            const Offset(0, 6),
          ),

        ],
      ),

      child: Row(

        children: [

          Container(

            padding:
            const EdgeInsets.all(14),

            decoration: BoxDecoration(

              gradient:
              LinearGradient(
                colors: [
                  color.withOpacity(0.8),
                  color,
                ],
              ),

              borderRadius:
              BorderRadius.circular(
                  14),
            ),

            child:
            Icon(icon,
                color:
                Colors.white),
          ),

          const SizedBox(width: 18),

          Expanded(

            child: Column(

              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [

                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                    Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (_loading) {

      return const Center(
          child:
          CircularProgressIndicator());

    }

    if (_profile == null) {

      return const Center(
          child:
          Text(
              'Failed to load profile'));

    }

    return SingleChildScrollView(

      child: Column(

        children: [

          /// HEADER
          Container(

            width: double.infinity,

            padding:
            const EdgeInsets.fromLTRB(
                20, 30, 20, 30),

            decoration:
            const BoxDecoration(

              gradient:
              LinearGradient(
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFFA855F7),
                ],
              ),

              borderRadius:
              BorderRadius.only(
                bottomLeft:
                Radius.circular(
                    30),
                bottomRight:
                Radius.circular(
                    30),
              ),
            ),

            child: Column(

              children: [

                Container(

                  padding:
                  const EdgeInsets.all(
                      24),

                  decoration:
                  BoxDecoration(

                    color:
                    Colors.white
                        .withOpacity(
                        0.2),

                    shape:
                    BoxShape.circle,
                  ),

                  child:
                  const Icon(
                    Icons.person,
                    size: 60,
                    color:
                    Colors.white,
                  ),
                ),

                const SizedBox(
                    height: 16),

                Text(

                  _profile![
                  'full_name'] ??
                      'Add your name',

                  style:
                  const TextStyle(
                    fontSize: 22,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    Colors.white,
                  ),
                ),

                const SizedBox(
                    height: 6),

                Text(

                  _profile![
                  'email'],

                  style:
                  const TextStyle(
                    fontSize: 14,
                    color:
                    Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                _buildOnlineToggle(),

              ],
            ),
          ),

          const SizedBox(height: 20),

          Padding(

            padding:
            const EdgeInsets
                .symmetric(
                horizontal: 20),

            child: Column(

              children: [

                _buildSkillsCard(),

                const SizedBox(
                    height: 16),
                _buildServiceAreaCard(),
                const SizedBox(height: 16),

                _buildInfoCard(
                  Icons.work_history,
                  "Experience",
                  "${_profile!['experience_years']} years",
                  const Color(
                      0xFFF59E0B),
                ),

                const SizedBox(
                    height: 16),

                _buildInfoCard(
                  Icons.star,
                  "Rating",
                  "${_profile!['rating']} ⭐",
                  const Color(
                      0xFF10B981),
                ),

                const SizedBox(
                    height: 40),

                SizedBox(

                  width:
                  double.infinity,

                  height: 55,

                  child:
                  ElevatedButton(

                    onPressed:
                    _logout,

                    style:
                    ElevatedButton
                        .styleFrom(

                      backgroundColor:
                      const Color(
                          0xFFEF4444),

                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                            15),
                      ),
                    ),

                    child:
                    const Text(
                      "Logout",
                      style:
                      TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight
                            .bold,
                        color:
                        Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                    height: 30),

              ],
            ),
          ),
        ],
      ),
    );
  }
  void reloadProfile() {
    _loadProfile();
  }
  void _confirmRemoveSkill(
      Map skill) {

    showDialog(

      context: context,

      builder: (_) =>
          AlertDialog(

            title: const Text(
                "Remove Skill"),

            content: Text(
                "Remove ${skill['name']} ?"),

            actions: [

              TextButton(

                onPressed:
                    () => Navigator.pop(
                    context),

                child:
                const Text(
                    "Cancel"),

              ),

              TextButton(

                onPressed: () async {

                  Navigator.pop(
                      context);

                  await SkillService
                      .removeSkill(
                      skill['id']);

                  _loadSkills();

                },

                child: const Text(
                  "Remove",
                  style: TextStyle(
                      color:
                      Colors.red),
                ),
              ),

            ],
          ),
    );

  }
  ///location update
  void _startLocationUpdates() {
    if (_locationTimer != null) return; // prevent duplicate timers

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
    _locationTimer = null; // important
  }
}