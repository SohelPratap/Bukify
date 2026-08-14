import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/worker_search_service.dart';
import '../../services/skills_service.dart';
import 'worker_public_profile_page.dart';

class CustomerSearchPage extends StatefulWidget {
  const CustomerSearchPage({super.key});

  @override
  State<CustomerSearchPage> createState() => _CustomerSearchPageState();
}

class _CustomerSearchPageState extends State<CustomerSearchPage> {
  static const _violet = Color(0xFF8B5CF6);
  static const _violetSoft = Color(0xFFF3EEFF);
  static const _ink = Color(0xFF1E1B3A);
  static const _bg = Color(0xFFF8F5FF);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<dynamic> _results = [];
  List<String> _allSkills = [];           // ← loaded from API
  List<String> _autocompleteResults = [];
  bool _loading = false;
  bool _locationLoading = true;
  bool _showAutocomplete = false;
  String? _error;

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
      final results = await WorkerSearchService.searchWorkers(
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
              hintText: "Search workers by skill…",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded,
                  color: _violet.withOpacity(0.7), size: 22),
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
                    color: _violet, size: 20),
                onPressed: () => _search(_searchController.text),
              ),
              filled: true,
              fillColor: const Color(0xFFF8F5FF),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 14),
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

          if (_showAutocomplete && _autocompleteResults.isNotEmpty)
            _AutocompleteDropdown(
              items: _autocompleteResults,
              icon: Icons.person_search_rounded,
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
            CircularProgressIndicator(color: _violet),
            SizedBox(height: 16),
            Text("Getting your location…",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_error != null) {
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
        icon: Icons.person_search_rounded,
        title: "No workers found",
        subtitle:
        'No workers offering "${_searchController.text}" are in your area right now.',
      );
    }

    if (_results.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_rounded,
        title: "Find nearby workers",
        subtitle: "Type a skill above to find available workers near you.",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final w = _results[i];
        return _WorkerCard(
          worker: w,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => WorkerPublicProfilePage(worker: w)),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════
//  WORKER CARD
// ══════════════════════════════════════════════════════
class _WorkerCard extends StatelessWidget {
  const _WorkerCard({required this.worker, required this.onTap});

  final dynamic worker;
  final VoidCallback onTap;

  static const _violet = Color(0xFF8B5CF6);
  static const _ink = Color(0xFF1E1B3A);

  @override
  Widget build(BuildContext context) {
    final double distance =
        double.tryParse(worker['distance_km']?.toString() ?? '0') ?? 0;
    final bool isOnline = worker['is_online'].toString() == '1';
    final double rating =
        double.tryParse(worker['rating']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _initials(worker['full_name'] ?? worker['email']),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? Colors.greenAccent
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            worker['full_name'] ?? 'Worker',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFF59E0B), size: 14),
                            const SizedBox(width: 3),
                            Text(rating.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _ink)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(worker['email'] ?? '',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    if (worker['skills_list'] != null &&
                        (worker['skills_list'] as String).isNotEmpty)
                      Text(
                        worker['skills_list'],
                        style: TextStyle(
                            fontSize: 12,
                            color: _violet.withOpacity(0.8),
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Pill(
                            icon: Icons.near_me_rounded,
                            label: "${distance.toStringAsFixed(1)} km away",
                            color: _violet),
                        const SizedBox(width: 8),
                        _Pill(
                            icon: Icons.work_history_rounded,
                            label:
                            "${worker['experience_years'] ?? 0} yrs exp",
                            color: const Color(0xFFF59E0B)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade300, size: 22),
            ],
          ),
        ),
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

class _Pill extends StatelessWidget {
  const _Pill(
      {required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
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

  static const _violet = Color(0xFF8B5CF6);
  static const _ink = Color(0xFF1E1B3A);

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
                              color: _violet.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(icon, size: 14, color: _violet),
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
        height: 110,
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
                  color: Color(0xFFF3EEFF), shape: BoxShape.circle),
              child:
              Icon(icon, size: 44, color: const Color(0xFF8B5CF6)),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1B3A))),
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