import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/job_search_service.dart';
import '../../services/worker_jobs_service.dart';

class WorkerSearchPage extends StatefulWidget {
  const WorkerSearchPage({super.key});

  @override
  State<WorkerSearchPage> createState() => _WorkerSearchPageState();
}

class _WorkerSearchPageState extends State<WorkerSearchPage> {
  static const _violet = Color(0xFF8B5CF6);
  static const _violetMid = Color(0xFFA855F7);
  static const _violetSoft = Color(0xFFF3EEFF);
  static const _ink = Color(0xFF1E1B3A);
  static const _bg = Color(0xFFF8F5FF);

  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _results = [];
  bool _loading = false;
  bool _locationLoading = true;
  String? _error;
  String? _startingJobId;

  double? _lat;
  double? _lng;

  final List<String> _quickSkills = [
    "Plumber", "Electrician", "Cleaner",
    "Painter", "Carpenter", "AC Repair",
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locationLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationLoading = false;
        _error = "Could not get your location.";
      });
    }
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty || _lat == null || _lng == null) return;

    HapticFeedback.selectionClick();
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    try {
      final results = await JobSearchService.searchJobs(
        skill: q,
        lat: _lat!,
        lng: _lng!,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Search failed. Try again.";
      });
    }
  }

  Future<void> _startJob(String id) async {
    HapticFeedback.mediumImpact();
    setState(() => _startingJobId = id);
    try {
      await WorkerJobsService.startJob(id);
      // remove from list immediately
      if (!mounted) return;
      setState(() {
        _results.removeWhere((j) => j['id'] == id);
      });
      _showSnack("Job started!", isError: false);
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          _buildQuickChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: _search,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _ink,
        ),
        decoration: InputDecoration(
          hintText: "Search jobs by skill — e.g. Plumber",
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded,
              color: _violet.withOpacity(0.7), size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded,
                color: Colors.grey, size: 20),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _results = [];
                _error = null;
              });
            },
          )
              : IconButton(
            icon: Icon(Icons.arrow_forward_rounded,
                color: _violet, size: 20),
            onPressed: () => _search(_searchController.text),
          ),
          filled: true,
          fillColor: const Color(0xFFF8F5FF),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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

  Widget _buildQuickChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _quickSkills.map((skill) {
            final isActive = _searchController.text.toLowerCase() ==
                skill.toLowerCase();
            return GestureDetector(
              onTap: () {
                _searchController.text = skill;
                _search(skill);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? _violet : _violetSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? _violet
                        : _violet.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  skill,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : _violet,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_locationLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _violet),
            SizedBox(height: 16),
            Text("Getting your location…",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_error != null && _results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 36),
              ),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: 5,
        itemBuilder: (_, __) => _ShimmerCard(),
      );
    }

    if (_results.isEmpty && _searchController.text.isNotEmpty) {
      return _EmptyState(
        icon: Icons.work_off_rounded,
        title: "No jobs found",
        subtitle:
        "No open \"${_searchController.text}\" jobs near you right now. Try another skill or check back later.",
      );
    }

    if (_results.isEmpty) {
      return _EmptyState(
        icon: Icons.manage_search_rounded,
        title: "Search nearby jobs",
        subtitle:
        "Search by skill above or tap a quick filter to find open jobs near you.",
      );
    }

    return RefreshIndicator(
      color: _violet,
      onRefresh: () => _search(_searchController.text),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _results.length,
        itemBuilder: (_, i) {
          final job = _results[i];
          final isMatch = job['is_skill_match'].toString() == '1';
          final double distance =
              double.tryParse(job['distance_km']?.toString() ?? '0') ?? 0;
          final bool isStarting = _startingJobId == job['id'];

          return _JobSearchCard(
            job: job,
            isMatch: isMatch,
            distance: distance,
            isStarting: isStarting,
            onStart: isStarting ? null : () => _startJob(job['id']),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  JOB SEARCH CARD
// ══════════════════════════════════════════════════════
class _JobSearchCard extends StatelessWidget {
  const _JobSearchCard({
    required this.job,
    required this.isMatch,
    required this.distance,
    required this.isStarting,
    required this.onStart,
  });

  final dynamic job;
  final bool isMatch;
  final double distance;
  final bool isStarting;
  final VoidCallback? onStart;

  static const _violet = Color(0xFF8B5CF6);
  static const _violetSoft = Color(0xFFF3EEFF);
  static const _ink = Color(0xFF1E1B3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isMatch
            ? Border.all(
          color: _violet.withOpacity(0.3),
          width: 1.5,
        )
            : null,
        boxShadow: [
          BoxShadow(
            color: isMatch
                ? _violet.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── TOP STRIP ──────────────────────────────
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMatch ? _violetSoft : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Skill badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMatch
                        ? _violet.withOpacity(0.12)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.handyman_rounded,
                          size: 12,
                          color: isMatch ? _violet : Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        job['skill_name'] ?? '—',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                          isMatch ? _violet : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Skill match badge
                if (isMatch)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _violet,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            color: Colors.white, size: 11),
                        SizedBox(width: 4),
                        Text(
                          "Skill Match",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Distance badge
                if (!isMatch)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.near_me_rounded,
                            size: 11, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          "${distance.toStringAsFixed(1)} km",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── BODY ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job['title'] ?? 'Untitled',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _ink,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 8),

                // Description
                if (job['description'] != null &&
                    (job['description'] as String).isNotEmpty)
                  Text(
                    job['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      height: 1.5,
                    ),
                  ),

                const SizedBox(height: 10),

                // Customer + distance row
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job['customer_email'] ?? '—',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.near_me_rounded,
                        size: 13, color: _violet.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      "${distance.toStringAsFixed(1)} km away",
                      style: TextStyle(
                        fontSize: 12,
                        color: _violet.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 12),

                // Start button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isStarting ? Colors.grey.shade200 : _violet,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isStarting
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: _violet,
                        strokeWidth: 2,
                      ),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          "Start Job",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
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
//  SHIMMER
// ══════════════════════════════════════════════════════
class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 170,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [
              (_anim.value - 0.3).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 0.3).clamp(0.0, 1.0),
            ],
            colors: const [
              Color(0xFFF3F4F6),
              Color(0xFFE9E4F5),
              Color(0xFFF3F4F6),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  EMPTY STATE
// ══════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF3EEFF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: const Color(0xFF8B5CF6)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1B3A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}