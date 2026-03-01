import 'package:flutter/material.dart';
import '../../services/worker_jobs_service.dart';

class LatestJobsPage extends StatefulWidget {
  const LatestJobsPage({super.key});

  @override
  State<LatestJobsPage> createState() => _LatestJobsPageState();
}

class _LatestJobsPageState extends State<LatestJobsPage> {

  List<dynamic> _jobs = [];
  bool _loading = true;
  String? _startingJobId; // to disable button while starting

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
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
    setState(() => _startingJobId = id);

    try {
      await WorkerJobsService.startJob(id);
      await _loadJobs();
    } catch (_) {}

    if (!mounted) return;
    setState(() => _startingJobId = null);
  }

  @override
  Widget build(BuildContext context) {

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_jobs.isEmpty) {
      return const Center(
        child: Text(
          "No nearby jobs",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _jobs.length,
        itemBuilder: (context, index) {

          final job = _jobs[index];
          final isMatch = job['is_skill_match'] == 1;

          final double distance =
          (job['distance_km'] as num).toDouble();

          final bool isStarting =
              _startingJobId == job['id'];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMatch
                    ? const Color(0xFF8B5CF6)
                    : Colors.grey.shade300,
                width: isMatch ? 2 : 1,
              ),
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

                const SizedBox(height: 4),

                Text(
                  "${distance.toStringAsFixed(2)} km away",
                  style: TextStyle(color: Colors.grey[600]),
                ),

                const SizedBox(height: 4),

                Text(
                  "Posted by: ${job['customer_email']}",
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600]),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isStarting
                        ? null
                        : () => _startJob(job['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                    ),
                    child: isStarting
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      "Start Job",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}