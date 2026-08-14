import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/customer_jobs_service.dart';

class CustomerHistoryPage extends StatefulWidget {
  const CustomerHistoryPage({super.key});

  @override
  State<CustomerHistoryPage> createState() => _CustomerHistoryPageState();
}

class _CustomerHistoryPageState extends State<CustomerHistoryPage>
    with SingleTickerProviderStateMixin {
  static const _violet = Color(0xFF8B5CF6);
  static const _violetMid = Color(0xFFA855F7);
  static const _violetSoft = Color(0xFFF3EEFF);
  static const _ink = Color(0xFF1E1B3A);
  static const _bg = Color(0xFFF8F5FF);

  late TabController _tabController;

  List<dynamic> _activeJobs = [];
  List<dynamic> _pastJobs = [];

  bool _loadingActive = true;
  bool _loadingPast = true;

  String? _cancellingId;
  String? _completingId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadActive();
    _loadPast();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActive() async {
    try {
      final jobs = await JobsService.getActiveJobs();
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

  Future<void> _loadPast() async {
    try {
      final jobs = await JobsService.getPastJobs();
      if (!mounted) return;
      setState(() {
        _pastJobs = jobs;
        _loadingPast = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPast = false);
    }
  }

  Future<void> _cancelJob(String id) async {
    final confirmed = await _showCancelDialog();
    if (confirmed != true) return;

    HapticFeedback.mediumImpact();
    setState(() => _cancellingId = id);

    try {
      await JobsService.cancelJob(id);
      await Future.wait([_loadActive(), _loadPast()]);
      if (!mounted) return;
      _showSnack("Job cancelled", isError: false);
    } catch (_) {
      if (!mounted) return;
      _showSnack("Could not cancel job", isError: true);
    }

    if (!mounted) return;
    setState(() => _cancellingId = null);
  }

  Future<void> _completeJob(String id) async {
    final confirmed = await _showCompleteDialog();
    if (confirmed != true) return;

    HapticFeedback.mediumImpact();
    setState(() => _completingId = id);

    try {
      await JobsService.completeJob(id);
      await Future.wait([_loadActive(), _loadPast()]);
      if (!mounted) return;
      _showSnack("Job marked as complete!", isError: false);
    } catch (_) {
      if (!mounted) return;
      _showSnack("Could not complete job", isError: true);
    }

    if (!mounted) return;
    setState(() => _completingId = null);
  }

  Future<bool?> _showCancelDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Cancel this job?",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _ink),
        ),
        content: Text(
          "The job will be removed from active listings and workers won't be able to accept it.",
          style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Keep it", style: TextStyle(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Cancel job",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showCompleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Mark job as complete?",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _ink),
        ),
        content: Text(
          "Confirm that the worker has finished the job to your satisfaction.",
          style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Not yet", style: TextStyle(color: Colors.grey[500])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, complete",
                style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildActiveTab(),
              _buildHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              padding: const EdgeInsets.all(4),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 16),
                      const SizedBox(width: 6),
                      const Text("Active"),
                      if (_activeJobs.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _CountBadge(count: _activeJobs.length),
                      ]
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 16),
                      SizedBox(width: 6),
                      Text("History"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    if (_loadingActive) return _LoadingState();
    if (_activeJobs.isEmpty) {
      return _EmptyState(
        icon: Icons.bolt_outlined,
        title: "No active jobs",
        subtitle: "Jobs you've booked will appear here.",
      );
    }

    return RefreshIndicator(
      color: _violet,
      onRefresh: () async {
        await Future.wait([_loadActive(), _loadPast()]);
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _activeJobs.length,
        itemBuilder: (_, i) {
          final job = _activeJobs[i];
          final status = job['status'] as String? ?? 'open';
          final canCancel = status == 'open' || status == 'accepted';
          final canComplete = status == 'in_progress';

          return _JobCard(
            job: job,
            isCancelling: _cancellingId == job['id'],
            isCompleting: _completingId == job['id'],
            showCancelButton: canCancel,
            showCompleteButton: canComplete,
            onCancel: canCancel ? () => _cancelJob(job['id']) : null,
            onComplete: canComplete ? () => _completeJob(job['id']) : null,
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_loadingPast) return _LoadingState();
    if (_pastJobs.isEmpty) {
      return _EmptyState(
        icon: Icons.history_rounded,
        title: "No past jobs",
        subtitle: "Completed and cancelled jobs will show up here.",
      );
    }

    return RefreshIndicator(
      color: _violet,
      onRefresh: _loadPast,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _pastJobs.length,
        itemBuilder: (_, i) => _JobCard(job: _pastJobs[i]),
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
    this.showCancelButton = false,
    this.showCompleteButton = false,
    this.isCancelling = false,
    this.isCompleting = false,
    this.onCancel,
    this.onComplete,
  });

  final dynamic job;
  final bool showCancelButton;
  final bool showCompleteButton;
  final bool isCancelling;
  final bool isCompleting;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;

  static const _violet = Color(0xFF8B5CF6);
  static const _ink = Color(0xFF1E1B3A);

  @override
  Widget build(BuildContext context) {
    final status = job['status'] as String? ?? 'open';
    final cfg = _statusConfig(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: status == 'in_progress'
            ? Border.all(
          color: const Color(0xFF10B981).withOpacity(0.35),
          width: 1.5,
        )
            : null,
        boxShadow: [
          BoxShadow(
            color: status == 'in_progress'
                ? const Color(0xFF10B981).withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── STATUS STRIP ──────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cfg.bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(cfg.icon, color: cfg.color, size: 14),
                const SizedBox(width: 6),
                Text(
                  cfg.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cfg.color,
                    letterSpacing: 0.3,
                  ),
                ),
                if (status == 'in_progress') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Awaiting your confirmation",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _formatDate(job['created_at']),
                  style: TextStyle(fontSize: 11, color: cfg.color.withOpacity(0.7)),
                ),
              ],
            ),
          ),

          // ── BODY ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job['title'] ?? 'Untitled',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _ink,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 8),

                // Skill badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _violet.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.handyman_rounded, color: _violet, size: 13),
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

                if (job['description'] != null &&
                    (job['description'] as String).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    job['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
                  ),
                ],

                // ── MARK COMPLETE button (in_progress) ──
                if (showCompleteButton) ...[
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isCompleting
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF10B981),
                        ),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            "Mark as Complete",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // ── CANCEL button (open / accepted) ──
                if (showCancelButton) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton(
                      onPressed: isCancelling ? null : onCancel,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isCancelling
                              ? Colors.grey.shade300
                              : Colors.red.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isCancelling
                          ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red.shade300,
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel_outlined,
                              color: Colors.red.shade400, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "Cancel Job",
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _statusConfig(String status) {
    switch (status) {
      case 'open':
        return _StatusConfig(
          label: 'OPEN',
          icon: Icons.radio_button_unchecked_rounded,
          color: const Color(0xFF8B5CF6),
          bgColor: const Color(0xFFF3EEFF),
        );
      case 'accepted':
        return _StatusConfig(
          label: 'ACCEPTED',
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF3B82F6),
          bgColor: const Color(0xFFEFF6FF),
        );
      case 'in_progress':
        return _StatusConfig(
          label: 'IN PROGRESS',
          icon: Icons.pending_rounded,
          color: const Color(0xFF10B981),
          bgColor: const Color(0xFFECFDF5),
        );
      case 'completed':
        return _StatusConfig(
          label: 'COMPLETED',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF10B981),
          bgColor: const Color(0xFFECFDF5),
        );
      case 'cancelled':
        return _StatusConfig(
          label: 'CANCELLED',
          icon: Icons.cancel_rounded,
          color: const Color(0xFFEF4444),
          bgColor: const Color(0xFFFEF2F2),
        );
      default:
        return _StatusConfig(
          label: status.toUpperCase(),
          icon: Icons.circle_outlined,
          color: Colors.grey,
          bgColor: Colors.grey.shade100,
        );
    }
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

class _StatusConfig {
  const _StatusConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
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
//  LOADING STATE
// ══════════════════════════════════════════════════════
class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        height: 130,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _Shimmer(),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
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
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_anim.value - 0.3).clamp(0, 1),
                _anim.value.clamp(0, 1),
                (_anim.value + 0.3).clamp(0, 1),
              ],
              colors: const [
                Color(0xFFF3F4F6),
                Color(0xFFE5E7EB),
                Color(0xFFF3F4F6),
              ],
            ),
          ),
        );
      },
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
              style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}