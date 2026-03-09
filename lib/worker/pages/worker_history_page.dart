import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/worker_jobs_service.dart';

class WorkerHistoryPage extends StatefulWidget {
  const WorkerHistoryPage({super.key});

  @override
  State<WorkerHistoryPage> createState() => _WorkerHistoryPageState();
}

class _WorkerHistoryPageState extends State<WorkerHistoryPage>
    with SingleTickerProviderStateMixin {
  // ── palette ───────────────────────────────────────────
  static const _violet = Color(0xFF8B5CF6);
  static const _violetMid = Color(0xFFA855F7);
  static const _violetSoft = Color(0xFFF3EEFF);
  static const _ink = Color(0xFF1E1B3A);
  static const _bg = Color(0xFFF8F5FF);

  late TabController _tabController;

  List<dynamic> _activeJobs = [];
  List<dynamic> _completedJobs = [];

  bool _loadingActive = true;
  bool _loadingCompleted = true;

  String? _completingJobId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadActive();
    _loadCompleted();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActive() async {
    try {
      final jobs = await WorkerJobsService.getActiveJobs();
      if (!mounted) return;
      setState(() {
        _activeJobs = jobs;
        _loadingActive = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingActive = false);
    }
  }

  Future<void> _loadCompleted() async {
    try {
      final jobs = await WorkerJobsService.getCompletedJobs();
      if (!mounted) return;
      setState(() {
        _completedJobs = jobs;
        _loadingCompleted = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCompleted = false);
    }
  }

  Future<void> _completeJob(String id) async {
    HapticFeedback.mediumImpact();
    setState(() => _completingJobId = id);
    try {
      await WorkerJobsService.completeJob(id);
      await Future.wait([_loadActive(), _loadCompleted()]);
      if (!mounted) return;
      _showSnack("Job marked as complete!", isError: false);
    } catch (_) {
      if (!mounted) return;
      _showSnack("Could not complete job", isError: true);
    }
    if (!mounted) return;
    setState(() => _completingJobId = null);
  }

  void _showSnack(String msg, {required bool isError}) {
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

  // ─── BUILD ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveTab(),
                _buildCompletedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB BAR ───────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: _violetSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _violet,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: _violet.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: _violet,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              padding: const EdgeInsets.all(4),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pending_rounded, size: 16),
                      const SizedBox(width: 6),
                      const Text("Active"),
                      if (_activeJobs.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _CountBadge(count: _activeJobs.length),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 16),
                      const SizedBox(width: 6),
                      const Text("Completed"),
                      if (_completedJobs.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _CountBadge(count: _completedJobs.length),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ACTIVE TAB ────────────────────────────────────────
  Widget _buildActiveTab() {
    if (_loadingActive) return _buildShimmer();

    if (_activeJobs.isEmpty) {
      return _EmptyState(
        icon: Icons.pending_outlined,
        title: "No active jobs",
        subtitle: "Jobs you've started will appear here.",
      );
    }

    return RefreshIndicator(
      color: _violet,
      onRefresh: _loadActive,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _activeJobs.length,
        itemBuilder: (_, i) {
          final job = _activeJobs[i];
          return _JobCard(
            job: job,
            isCompleted: false,
            isCompleting: _completingJobId == job['id'],
            onComplete: () => _completeJob(job['id']),
          );
        },
      ),
    );
  }

  // ── COMPLETED TAB ─────────────────────────────────────
  Widget _buildCompletedTab() {
    if (_loadingCompleted) return _buildShimmer();

    if (_completedJobs.isEmpty) {
      return _EmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: "No completed jobs",
        subtitle: "Finished jobs will show up here.",
      );
    }

    return RefreshIndicator(
      color: _violet,
      onRefresh: _loadCompleted,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _completedJobs.length,
        itemBuilder: (_, i) => _JobCard(
          job: _completedJobs[i],
          isCompleted: true,
        ),
      ),
    );
  }

  // ── SHIMMER ───────────────────────────────────────────
  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        height: 150,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _ShimmerBox(),
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
    required this.isCompleted,
    this.isCompleting = false,
    this.onComplete,
  });

  final dynamic job;
  final bool isCompleted;
  final bool isCompleting;
  final VoidCallback? onComplete;

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
        border: !isCompleted
            ? Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.3),
          width: 1.5,
        )
            : null,
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? Colors.black.withOpacity(0.05)
                : const Color(0xFFF59E0B).withOpacity(0.1),
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
              color: isCompleted
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFFFBEB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.12)
                        : const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.pending_rounded,
                        size: 12,
                        color: isCompleted
                            ? Colors.green
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isCompleted ? "COMPLETED" : "IN PROGRESS",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? Colors.green
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Date
                Text(
                  _formatDate(job['updated_at'] ?? job['created_at']),
                  style: TextStyle(
                    fontSize: 11,
                    color: isCompleted
                        ? Colors.green.withOpacity(0.7)
                        : const Color(0xFFF59E0B).withOpacity(0.8),
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

                // Title
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

                // Skill badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _violet.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.handyman_rounded,
                          color: _violet, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        job['skill_name'] ?? '—',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _violet,
                        ),
                      ),
                    ],
                  ),
                ),

                // Mark complete button
                if (!isCompleted) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: isCompleting ? null : onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleting
                            ? Colors.grey.shade100
                            : const Color(0xFF10B981),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isCompleting
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Color(0xFF10B981),
                          strokeWidth: 2,
                        ),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            "Mark Complete",
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

                // Completed checkmark row
                if (isCompleted) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green.shade400, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        "Great work! Job done.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) return '${diff.inMinutes}m ago';
        return '${diff.inHours}h ago';
      }
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ══════════════════════════════════════════════════════
//  COUNT BADGE
// ══════════════════════════════════════════════════════
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
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
                height: 1.5,
              ),
            ),
          ],
        ),
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
              Color(0xFFE9E4F5),
              Color(0xFFF3F4F6),
            ],
          ),
        ),
      ),
    );
  }
}