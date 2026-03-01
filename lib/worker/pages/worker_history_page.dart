import 'package:flutter/material.dart';
import '../../services/worker_jobs_service.dart';

class WorkerHistoryPage extends StatefulWidget {
  const WorkerHistoryPage({super.key});

  @override
  State<WorkerHistoryPage> createState() => _WorkerHistoryPageState();
}

class _WorkerHistoryPageState extends State<WorkerHistoryPage>
    with SingleTickerProviderStateMixin {

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
    setState(() => _completingJobId = id);

    try {
      await WorkerJobsService.completeJob(id);
      await _loadActive();
      await _loadCompleted();
    } catch (_) {}

    if (!mounted) return;
    setState(() => _completingJobId = null);
  }

  Widget _buildJobCard(dynamic job, {bool isCompleted = false}) {

    final bool isCompleting = _completingJobId == job['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            job['title'],
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(
            job['skill_name'],
            style: const TextStyle(
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 8),

          if (!isCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCompleting
                    ? null
                    : () => _completeJob(job['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                ),
                child: isCompleting
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  "Mark Complete",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

          if (isCompleted)
            const Text(
              "Completed",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [

        Container(
          color: const Color(0xFF8B5CF6),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            tabs: const [
              Tab(text: "Active"),
              Tab(text: "Completed"),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [

              _loadingActive
                  ? const Center(child: CircularProgressIndicator())
                  : _activeJobs.isEmpty
                  ? const Center(child: Text("No active jobs"))
                  : ListView(
                padding: const EdgeInsets.all(16),
                children: _activeJobs
                    .map((job) => _buildJobCard(job))
                    .toList(),
              ),

              _loadingCompleted
                  ? const Center(child: CircularProgressIndicator())
                  : _completedJobs.isEmpty
                  ? const Center(child: Text("No completed jobs"))
                  : ListView(
                padding: const EdgeInsets.all(16),
                children: _completedJobs
                    .map((job) =>
                    _buildJobCard(job, isCompleted: true))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}