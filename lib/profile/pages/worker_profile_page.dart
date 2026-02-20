import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../services/skill_service.dart';
import '../../../auth/services/session_service.dart';
import '../../../onboarding/pages/login.dart';
import '../../widgets/skill_selector.dart';

class WorkerProfilePage extends StatefulWidget {
  const WorkerProfilePage({super.key});

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {

  Map<String, dynamic>? _profile;
  bool _loading = true;

  bool _editSkills = false;
  List<dynamic> _skills = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSkills();
  }

  /// LOAD PROFILE
  Future<void> _loadProfile() async {

    try {

      final data =
      await ProfileService.getProfile();

      setState(() {
        _profile = data;
        _loading = false;
      });

    } catch (_) {

      setState(() => _loading = false);

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
}