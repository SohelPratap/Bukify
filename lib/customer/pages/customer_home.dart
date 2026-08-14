import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'customer_profile_page.dart';
import '../../map/pages/map_page.dart';
import 'booking_page.dart';
import 'customer_history_page.dart';
import 'customer_search_page.dart';

class HomeCustomerPage extends StatefulWidget {
  const HomeCustomerPage({super.key});

  @override
  State<HomeCustomerPage> createState() => _HomeCustomerPageState();
}

class _HomeCustomerPageState extends State<HomeCustomerPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  static const _violet = Color(0xFF8B5CF6);
  static const _violetMid = Color(0xFFA855F7);

  static const _navItems = [
    _NavItem(icon: Icons.search_rounded, label: "Search"),
    _NavItem(icon: Icons.map_rounded, label: "Map"),
    _NavItem(icon: Icons.add_circle_rounded, label: "Book", isFeatured: true),
    _NavItem(icon: Icons.history_rounded, label: "History"),
    _NavItem(icon: Icons.person_rounded, label: "Profile"),
  ];

  static const _titles = [
    "Find Workers",
    "Map",
    "Book a Job",
    "My Bookings",
    "Profile",
  ];

  final List<Widget> _pages = const [
    CustomerSearchPage(),
    MapPage(userRole: "customer"),
    BookingPage(),
    CustomerHistoryPage(),
    CustomerProfilePage(),
  ];

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B5CF6), _violetMid],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Row(
          key: ValueKey(_currentIndex),
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _navItems[_currentIndex].icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _titles[_currentIndex],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.home_repair_service_rounded,
                  color: Colors.white, size: 13),
              SizedBox(width: 5),
              Text(
                "BukiFy",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _violet.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isActive = _currentIndex == i;

              if (item.isFeatured) {
                return GestureDetector(
                  onTap: () => _onNavTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), _violetMid],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _violet
                              .withOpacity(isActive ? 0.4 : 0.2),
                          blurRadius: isActive ? 14 : 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      item.icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                );
              }

              return GestureDetector(
                onTap: () => _onNavTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _violet.withOpacity(0.09)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isActive
                            ? _violet
                            : Colors.grey.shade400,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isActive
                              ? _violet
                              : Colors.grey.shade400,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final bool isFeatured;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isFeatured = false,
  });
}