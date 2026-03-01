import 'package:flutter/material.dart';
import '../../services/jobs_service.dart';

class CustomerHistoryPage extends StatefulWidget {
  const CustomerHistoryPage({super.key});

  @override
  State<CustomerHistoryPage> createState() =>
      _CustomerHistoryPageState();
}

class _CustomerHistoryPageState
    extends State<CustomerHistoryPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  List<dynamic> _activeJobs = [];
  List<dynamic> _pastJobs = [];

  bool _loadingActive = true;
  bool _loadingPast = true;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this);

    _loadActive();
    _loadPast();
  }

  Future<void> _loadActive() async {
    try {
      final jobs =
      await JobsService.getActiveJobs();

      if (!mounted) return;

      setState(() {
        _activeJobs = jobs;
        _loadingActive = false;
      });
    } catch (_) {
      setState(() => _loadingActive = false);
    }
  }

  Future<void> _loadPast() async {
    try {
      final jobs =
      await JobsService.getPastJobs();

      if (!mounted) return;

      setState(() {
        _pastJobs = jobs;
        _loadingPast = false;
      });
    } catch (_) {
      setState(() => _loadingPast = false);
    }
  }

  Future<void> _cancelJob(String id) async {
    try {
      await JobsService.cancelJob(id);
      _loadActive();
      _loadPast();

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(
        content: Text("Job cancelled"),
      ));
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(
        content: Text("Cancel failed"),
      ));
    }
  }

  Widget _buildJobCard(dynamic job,
      {bool showCancel = false}) {

    final statusColor = job['status'] == 'completed'
        ? Colors.green
        : job['status'] == 'cancelled'
        ? Colors.red
        : Colors.orange;

    return Container(
      margin:
      const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
            Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          Text(
            job['title'],
            style: const TextStyle(
                fontWeight:
                FontWeight.bold,
                fontSize: 16),
          ),

          const SizedBox(height: 4),

          Text(
            job['skill_name'],
            style: TextStyle(
                color: Colors.grey[600]),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
            children: [
              Text(
                job['status'],
                style: TextStyle(
                    color: statusColor,
                    fontWeight:
                    FontWeight.bold),
              ),
              if (showCancel)
                TextButton(
                  onPressed: () =>
                      _cancelJob(job['id']),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                        color: Colors.red),
                  ),
                )
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [

        TabBar(
          controller: _tabController,
          labelColor:
          const Color(0xFF8B5CF6),
          tabs: const [
            Tab(text: "Active"),
            Tab(text: "History"),
          ],
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [

              /// ACTIVE TAB
              _loadingActive
                  ? const Center(
                  child:
                  CircularProgressIndicator())
                  : ListView(
                padding:
                const EdgeInsets.all(
                    16),
                children:
                _activeJobs
                    .map((job) =>
                    _buildJobCard(
                        job,
                        showCancel:
                        job['status'] ==
                            'open' ||
                            job['status'] ==
                                'accepted'))
                    .toList(),
              ),

              /// HISTORY TAB
              _loadingPast
                  ? const Center(
                  child:
                  CircularProgressIndicator())
                  : ListView(
                padding:
                const EdgeInsets.all(
                    16),
                children:
                _pastJobs
                    .map((job) =>
                    _buildJobCard(
                        job))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}