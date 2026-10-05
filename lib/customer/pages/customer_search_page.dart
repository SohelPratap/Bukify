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
  static const _primary = Color(0xFF0072FF);
  static const _primarySoft = Color(0xFFE6F4FF);
  static const _ink = Color(0xFF0F2C59);
  static const _bg = Color(0xFFF5FAFF);

  // Accent colours + icons cycled across the popular-skill cards
  static const List<Color> _skillColors = [
    Color(0xFF0072FF), // blue
    Color(0xFF8B5CF6), // purple
    Color(0xFF10B981), // green
    Color(0xFFF59E0B), // amber
    Color(0xFFEC4899), // pink
    Color(0xFF06B6D4), // cyan
    Color(0xFFEF4444), // red
    Color(0xFF6366F1), // indigo
  ];
  static const List<IconData> _skillIcons = [
    Icons.handyman_rounded,
    Icons.build_rounded,
    Icons.electrical_services_rounded,
    Icons.plumbing_rounded,
    Icons.cleaning_services_rounded,
    Icons.format_paint_rounded,
    Icons.construction_rounded,
    Icons.hardware_rounded,
  ];

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

  // ══════════════════════════════════════════════════
  //  UI ONLY BELOW THIS LINE
  // ══════════════════════════════════════════════════

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
    final hasResults = _results.isNotEmpty && !_loading;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Find a worker",
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _lat != null
                          ? Icons.location_on_rounded
                          : Icons.location_off_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _locationLoading
                          ? "Locating you…"
                          : _lat != null
                          ? "Using your current location"
                          : "Location unavailable",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (hasResults) ...[
                const SizedBox(width: 8),
                Text(
                  "${_results.length} found",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: TextField(
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
                    color: _primary.withOpacity(0.8), size: 22),
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
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: _primary, width: 1.5),
                ),
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
            CircularProgressIndicator(color: _primary, strokeWidth: 3),
            SizedBox(height: 16),
            Text("Getting your location…",
                style: TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.w500)),
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
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2), shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 38),
              ),
              const SizedBox(height: 18),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
      return _buildIdleState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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

  // Idle state: popular skills shown as tappable cards (from _allSkills)
  Widget _buildIdleState() {
    final suggestions = _allSkills.take(8).toList();
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("POPULAR SKILLS",
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500])),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: suggestions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
            ),
            itemBuilder: (_, i) {
              final s = suggestions[i];
              final accent = _skillColors[i % _skillColors.length];
              final accentIcon = _skillIcons[i % _skillIcons.length];
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _selectAutocomplete(s),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withOpacity(0.16),
                        accent.withOpacity(0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withOpacity(0.28)),
                    boxShadow: [
                      BoxShadow(
                          color: accent.withOpacity(0.14),
                          blurRadius: 14,
                          offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accent.withOpacity(0.75),
                                    accent,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: accent.withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3)),
                                ]),
                            child: Icon(accentIcon,
                                size: 18, color: Colors.white),
                          ),
                          Icon(Icons.north_east_rounded,
                              size: 16, color: accent),
                        ],
                      ),
                      Text(s,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
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

  static const _primary = Color(0xFF0072FF);
  static const _ink = Color(0xFF0F2C59);

  @override
  Widget build(BuildContext context) {
    final double distance =
        double.tryParse(worker['distance_km']?.toString() ?? '0') ?? 0;
    final bool isOnline = worker['is_online'].toString() == '1';
    final double rating =
        double.tryParse(worker['rating']?.toString() ?? '0') ?? 0;

    final String skillsRaw = (worker['skills_list'] ?? '').toString();
    final List<String> skills = skillsRaw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE3EEFB)),
          boxShadow: [
            BoxShadow(
                color: _primary.withOpacity(0.07),
                blurRadius: 18,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            _initials(worker['full_name'] ?? worker['email']),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 19),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFF22C55E)
                                : Colors.grey.shade400,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
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
                        Text(
                          worker['full_name'] ?? 'Worker',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: _ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(worker['email'] ?? '',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? const Color(0xFF22C55E)
                                    : Colors.grey.shade400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isOnline ? "Online now" : "Offline",
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isOnline
                                      ? const Color(0xFF16A34A)
                                      : Colors.grey[500]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFF59E0B), size: 15),
                        const SizedBox(width: 3),
                        Text(rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _ink)),
                      ],
                    ),
                  ),
                ],
              ),
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...skills.take(3).map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _primary)),
                    )),
                    if (skills.length > 3)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text("+${skills.length - 3}",
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[600])),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Pill(
                      icon: Icons.near_me_rounded,
                      label: "${distance.toStringAsFixed(1)} km away",
                      color: _primary),
                  const SizedBox(width: 8),
                  _Pill(
                      icon: Icons.work_history_rounded,
                      label: "${worker['experience_years'] ?? 0} yrs exp",
                      color: const Color(0xFFF59E0B)),
                  const Spacer(),
                  Row(
                    children: const [
                      Text("View",
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _primary)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded,
                          color: _primary, size: 20),
                    ],
                  ),
                ],
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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

  static const _primary = Color(0xFF0072FF);
  static const _ink = Color(0xFF0F2C59);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                              color: _primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(icon, size: 14, color: _primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(skill,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
        height: 150,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
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