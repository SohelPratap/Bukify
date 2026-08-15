import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/job_search_service.dart';
import '../../services/worker_jobs_service.dart';
import '../../services/skills_service.dart';

class WorkerSearchPage extends StatefulWidget {
  const WorkerSearchPage({super.key});

  @override
  State<WorkerSearchPage> createState() => _WorkerSearchPageState();
}

class _WorkerSearchPageState extends State<WorkerSearchPage> {
  static const _primary = Color(0xFF0072FF);
  static const _primarySoft = Color(0xFFE6F4FF);
  static const _ink = Color(0xFF0F2C59);
  static const _bg = Color(0xFFF5FAFF);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<dynamic> _results = [];
  List<String> _allSkills = [];           // ← loaded from API
  List<String> _autocompleteResults = [];
  bool _loading = false;
  bool _locationLoading = true;
  bool _showAutocomplete = false;
  String? _error;
  String? _startingJobId;

  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _fetchSkills();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() => _showAutocomplete = false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
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

  // ── filter _allSkills as user types ──────────────────
  void _onSearchChanged() {
    final q = _searchController.text.trim();
    setState(() {}); // refresh suffix icon
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
    _search(skill);
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
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
    _searchFocusNode.unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
      _showAutocomplete = false;
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
      if (!mounted) return;
      setState(() => _results.removeWhere((j) => j['id'] == id));
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
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _searchFocusNode.unfocus(),
      child: Container(
        color: _bg,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: _ink),
            decoration: InputDecoration(
              hintText: "Search jobs by skill…",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded,
                  color: _primary.withOpacity(0.7), size: 22),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.grey, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                  setState(() {
                    _results = [];
                    _error = null;
                    _showAutocomplete = false;
                  });
                },
              )
                  : IconButton(
                icon: Icon(Icons.arrow_forward_rounded,
                    color: _primary, size: 20),
                onPressed: () => _search(_searchController.text),
              ),
              filled: true,
              fillColor: const Color(0xFFF5FAFF),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
            ),
          ),

          if (_showAutocomplete && _autocompleteResults.isNotEmpty)
            _AutocompleteDropdown(
              items: _autocompleteResults,
              icon: Icons.work_outline,
              onSelect: _selectAutocomplete,
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_locationLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _primary),
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
                    color: Color(0xFFFEF2F2), shape: BoxShape.circle),
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
        itemBuilder: (_, __) => const _ShimmerCard(),
      );
    }

    if (_results.isEmpty && _searchController.text.isNotEmpty) {
      return _EmptyState(
        icon: Icons.work_off_rounded,
        title: "No jobs found",
        subtitle:
        'No open "${_searchController.text}" jobs near you right now.',
      );
    }

    if (_results.isEmpty) {
      return const _EmptyState(
        icon: Icons.manage_search_rounded,
        title: "Search nearby jobs",
        subtitle: "Type a skill above to find open jobs near you.",
      );
    }

    return RefreshIndicator(
      color: _primary,
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

  static const _primary = Color(0xFF0072FF);
  static const _primarySoft = Color(0xFFE6F4FF);
  static const _ink = Color(0xFF0F2C59);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isMatch
            ? Border.all(color: _primary.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isMatch
                ? _primary.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top strip
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMatch ? _primarySoft : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMatch
                        ? _primary.withOpacity(0.12)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.handyman_rounded,
                          size: 12,
                          color: isMatch ? _primary : Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        job['skill_name'] ?? '—',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isMatch ? _primary : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isMatch)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            color: Colors.white, size: 11),
                        SizedBox(width: 4),
                        Text("Skill Match",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.near_me_rounded,
                            size: 11, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text("${distance.toStringAsFixed(1)} km",
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600])),
                      ],
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
                Text(job['title'] ?? 'Untitled',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _ink,
                        height: 1.3)),
                const SizedBox(height: 8),
                if (job['description'] != null &&
                    (job['description'] as String).isNotEmpty)
                  Text(job['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          height: 1.5)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(job['customer_email'] ?? '—',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.near_me_rounded,
                        size: 13, color: _primary.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text("${distance.toStringAsFixed(1)} km away",
                        style: TextStyle(
                            fontSize: 12,
                            color: _primary.withOpacity(0.8),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isStarting ? Colors.grey.shade200 : _primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isStarting
                        ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: _primary, strokeWidth: 2))
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text("Start Job",
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
//  SHARED AUTOCOMPLETE DROPDOWN
// ══════════════════════════════════════════════════════
class _AutocompleteDropdown extends StatelessWidget {
  const _AutocompleteDropdown({
    required this.items,
    required this.icon,
    required this.onSelect,
  });

  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onSelect;

  static const _primary = Color(0xFF0072FF);
  static const _ink = Color(0xFF0F2C59);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final skill = entry.value;
            return Column(
              children: [
                if (i > 0) Divider(height: 1, color: Colors.grey.shade100),
                InkWell(
                  onTap: () => onSelect(skill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: _primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(icon, size: 14, color: _primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(skill,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _ink)),
                        ),
                        Icon(Icons.north_west_rounded,
                            size: 13, color: Colors.grey[400]),
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
}

// ══════════════════════════════════════════════════════
//  SHIMMER
// ══════════════════════════════════════════════════════
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

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
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
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
              Color(0xFFDCEEFC),
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
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

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
                  color: Color(0xFFE6F4FF), shape: BoxShape.circle),
              child:
              Icon(icon, size: 44, color: const Color(0xFF0072FF)),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2C59))),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey[500], height: 1.5)),
          ],
        ),
      ),
    );
  }
}