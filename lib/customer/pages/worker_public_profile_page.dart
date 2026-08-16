import 'package:flutter/material.dart';

class WorkerPublicProfilePage extends StatelessWidget {
  const WorkerPublicProfilePage({super.key, required this.worker});

  final dynamic worker;

  static const _primary = Color(0xFF0072FF);
  static const _primaryMid = Color(0xFF00C6FF);
  static const _primarySoft = Color(0xFFE6F4FF);
  static const _ink = Color(0xFF0F2C59);

  @override
  Widget build(BuildContext context) {
    final bool isOnline = worker['is_online'].toString() == '1';
    final double rating = double.tryParse(worker['rating']?.toString() ?? '0') ?? 0;
    final double distance = double.tryParse(worker['distance_km']?.toString() ?? '0') ?? 0;
    final int experience = int.tryParse(worker['experience_years']?.toString() ?? '0') ?? 0;
    final String skillsList = worker['skills_list'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),
      body: CustomScrollView(
        slivers: [
          // ── APP BAR ───────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: _primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryMid, _primary],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Avatar
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2),
                          ),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _initials(worker['full_name'] ??
                                    worker['email']),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? Colors.greenAccent
                                : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      worker['full_name'] ?? 'Worker',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      worker['email'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Online pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? Colors.green.withOpacity(0.2)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOnline
                              ? Colors.greenAccent
                              : Colors.white30,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? Colors.greenAccent
                                  : Colors.white38,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline ? "Available" : "Offline",
                            style: TextStyle(
                              color: isOnline
                                  ? Colors.greenAccent
                                  : Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── CONTENT ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.star_rounded,
                          value: rating.toStringAsFixed(1),
                          label: "Rating",
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.work_history_rounded,
                          value: "$experience yrs",
                          label: "Experience",
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.near_me_rounded,
                          value:
                          "${distance.toStringAsFixed(1)} km",
                          label: "Distance",
                          color: _primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Skills card
                  if (skillsList.isNotEmpty)
                    _InfoCard(
                      icon: Icons.handyman_rounded,
                      title: "Skills & Services",
                      color: _primary,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skillsList
                            .split(', ')
                            .map((skill) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primarySoft,
                            borderRadius:
                            BorderRadius.circular(20),
                            border: Border.all(
                              color:
                              _primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded,
                                  color: _primary, size: 13),
                              const SizedBox(width: 5),
                              Text(
                                skill.trim(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _primary,
                                ),
                              ),
                            ],
                          ),
                        ))
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Service area card
                  _InfoCard(
                    icon: Icons.radar_rounded,
                    title: "Service Area",
                    color: const Color(0xFF3B82F6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Works within ${double.tryParse(worker['radius_km']?.toString() ?? '')?.toStringAsFixed(0) ?? '—'} km radius",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Contact card
                  _InfoCard(
                    icon: Icons.email_rounded,
                    title: "Contact",
                    color: const Color(0xFFF59E0B),
                    child: Row(
                      children: [
                        Icon(Icons.alternate_email_rounded,
                            size: 16,
                            color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Text(
                          worker['email'] ?? '—',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
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

// ── STAT CARD ─────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2C59),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ── INFO CARD ─────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2C59),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}