import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/worker_jobs_service.dart';

class LatestJobsPage extends StatefulWidget {
  const LatestJobsPage({super.key});

  @override
  State<LatestJobsPage> createState() => _LatestJobsPageState();
}

class _LatestJobsPageState extends State<LatestJobsPage> {
  static const _primary = Color(0xFF0072FF);
  static const _primarySoft = Color(0xFFE6F4FF);
  static const _ink = Color(0xFF0F2C59);
  static const _bg = Color(0xFFF5FAFF);

  List<dynamic> _jobs = [];
  bool _loading = true;
  String? _startingJobId;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _loading = true);
    try {
      final jobs = await WorkerJobsService.getNearbyJobs();
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _startJob(String id) async {
    HapticFeedback.mediumImpact();
    setState(() => _startingJobId = id);
    try {
      await WorkerJobsService.startJob(id);
      await _loadJobs();
      if (!mounted) return;
      _showSnack("Job started successfully!");
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
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildShimmer();

    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadJobs,
      child: _jobs.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _jobs.length,
        itemBuilder: (_, i) {
          final job = _jobs[i];
          final isMatch = job['is_skill_match'] == 1;
          final double distance =
          (job['distance_km'] as num).toDouble();
          final bool isStarting = _startingJobId == job['id'];

          return _JobCard(
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

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        height: 160,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _ShimmerBox(),
      ),
    );
  }

  // Empty state wrapped in a scrollable so pull-to-refresh works
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: _primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_searching_rounded,
                      size: 44,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "No nearby jobs",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Pull down to refresh",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  JOB CARD
// ══════════════════════════════════════════════════════
class _JobCard extends StatelessWidget {
  const _JobCard({
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
            ? Border.all(
          color: _primary.withOpacity(0.3),
          width: 1.5,
        )
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

          // ── TOP STRIP ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

                const SizedBox(height: 10),

                Row(
                  children: [
                    if (isMatch) ...[
                      Icon(Icons.near_me_rounded,
                          size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        "${distance.toStringAsFixed(1)} km away",
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 14),
                    ],
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
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isStarting
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: _primary,
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
class _ShimmerBox extends StatefulWidget {
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
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