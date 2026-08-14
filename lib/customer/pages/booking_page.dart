import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/customer_jobs_service.dart';
import '../../services/customer_service.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage>
    with SingleTickerProviderStateMixin {
  // Step control
  int _currentStep = 0;
  late final PageController _pageController;
  late final AnimationController _progressController;

  // Form data
  String? _selectedSkillId;
  String? _selectedSkillName;
  String? _selectedAddressId;
  String? _selectedAddressLabel;
  String? _selectedAddressText;

  final TextEditingController _serviceSearchController =
  TextEditingController();
  final TextEditingController _addressSearchController =
  TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController =
  TextEditingController();

  bool _submitting = false;

  List<dynamic> _skillSuggestions = [];
  List<dynamic> _addressSuggestions = [];

  bool _searchingSkill = false;
  bool _searchingAddress = false;

  static const _purple = Color(0xFF8B5CF6);
  static const _purpleLight = Color(0xFFA855F7);
  static const _purpleSoft = Color(0xFFF3EEFF);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _serviceSearchController.dispose();
    _addressSearchController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    _progressController.animateTo(step / 2);
  }

  bool get _canAdvanceStep0 =>
      _selectedSkillId != null;
  bool get _canAdvanceStep1 =>
      _selectedAddressId != null;
  bool get _canAdvanceStep2 =>
      _titleController.text.trim().isNotEmpty;

  Future<void> _searchSkills(String query) async {
    if (query.isEmpty) {
      setState(() => _skillSuggestions = []);
      return;
    }
    setState(() => _searchingSkill = true);
    try {
      final results = await CustomerService.searchSkills(query);
      if (!mounted) return;
      setState(() {
        _skillSuggestions = results;
        _searchingSkill = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchingSkill = false);
    }
  }

  Future<void> _searchAddresses(String query) async {
    if (query.isEmpty) {
      setState(() => _addressSuggestions = []);
      return;
    }
    setState(() => _searchingAddress = true);
    try {
      final results = await CustomerService.searchAddresses(query);
      if (!mounted) return;
      setState(() {
        _addressSuggestions = results;
        _searchingAddress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchingAddress = false);
    }
  }

  Future<void> _submitBooking() async {
    if (!_canAdvanceStep2) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);

    try {
      await JobsService.createJob(
        skillId: _selectedSkillId!,
        addressId: _selectedAddressId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      _serviceSearchController.clear();
      _addressSearchController.clear();
      _titleController.clear();
      _descriptionController.clear();

      if (!mounted) return;

      setState(() {
        _selectedSkillId = null;
        _selectedSkillName = null;
        _selectedAddressId = null;
        _selectedAddressLabel = null;
        _selectedAddressText = null;
        _skillSuggestions = [];
        _addressSuggestions = [];
      });

      _goToStep(0);
      _showSuccessSheet();
    } catch (_) {
      if (!mounted) return;
      _showErrorSnack();
    }

    if (!mounted) return;
    setState(() => _submitting = false);
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(),
    );
  }

  void _showErrorSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Text("Failed to create booking. Try again."),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: Column(
        children: [
          _buildHeader(),
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep0Service(),
                _buildStep1Address(),
                _buildStep2Details(),
              ],
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    const titles = ["Choose Service", "Pick Location", "Job Details"];
    const subtitles = [
      "What do you need help with?",
      "Where should the worker come?",
      "Describe what needs to be done",
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              titles[_currentStep],
              key: ValueKey('title$_currentStep'),
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1B3A),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              subtitles[_currentStep],
              key: ValueKey('sub$_currentStep'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: GestureDetector(
              onTap: isDone ? () => _goToStep(i) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isActive
                      ? _purple
                      : isDone
                      ? _purpleLight.withOpacity(0.5)
                      : Colors.grey.shade200,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ────────── STEP 0: SERVICE ──────────
  Widget _buildStep0Service() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          _SearchField(
            controller: _serviceSearchController,
            hint: "e.g. Plumber, Electrician…",
            icon: Icons.construction_rounded,
            isLoading: _searchingSkill,
            onChanged: _searchSkills,
          ),
          const SizedBox(height: 12),

          // Suggestions
          if (_skillSuggestions.isNotEmpty)
            _SuggestionList(
              items: _skillSuggestions,
              titleKey: 'name',
              subtitleKey: null,
              onSelect: (item) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedSkillId = item['id'];
                  _selectedSkillName = item['name'];
                  _serviceSearchController.text = item['name'];
                  _skillSuggestions = [];
                });
              },
            ),

          const SizedBox(height: 20),

          // Selected chip
          if (_selectedSkillId != null)
            _SelectedBadge(
              label: _selectedSkillName!,
              icon: Icons.handyman_rounded,
              onClear: () => setState(() {
                _selectedSkillId = null;
                _selectedSkillName = null;
                _serviceSearchController.clear();
              }),
            ),

          const SizedBox(height: 24),

          // Quick picks label
          Text(
            "Popular Services",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),

          // Quick service grid — tapping pre-fills search
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              "Plumber",
              "Electrician",
              "Cleaner",
              "Painter",
              "Carpenter",
              "AC Repair",
            ]
                .map(
                  (s) => _QuickChip(
                label: s,
                isSelected: _selectedSkillName == s,
                onTap: () {
                  _serviceSearchController.text = s;
                  _searchSkills(s);
                },
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ────────── STEP 1: ADDRESS ──────────
  Widget _buildStep1Address() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchField(
            controller: _addressSearchController,
            hint: "Search your saved addresses…",
            icon: Icons.location_on_rounded,
            isLoading: _searchingAddress,
            onChanged: _searchAddresses,
          ),
          const SizedBox(height: 12),

          if (_addressSuggestions.isNotEmpty)
            _SuggestionList(
              items: _addressSuggestions,
              titleKey: 'label',
              subtitleKey: 'address',
              onSelect: (item) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedAddressId = item['id'];
                  _selectedAddressLabel = item['label'] ?? 'Address';
                  _selectedAddressText = item['address'] ?? '';
                  _addressSearchController.text =
                      item['label'] ?? 'Address';
                  _addressSuggestions = [];
                });
              },
            ),

          const SizedBox(height: 20),

          if (_selectedAddressId != null)
            _SelectedBadge(
              label: _selectedAddressLabel!,
              sublabel: _selectedAddressText,
              icon: Icons.location_on_rounded,
              onClear: () => setState(() {
                _selectedAddressId = null;
                _selectedAddressLabel = null;
                _selectedAddressText = null;
                _addressSearchController.clear();
              }),
            ),

          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _purpleSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _purple.withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: _purple.withOpacity(0.7), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Only addresses saved in your profile will appear. Add more from the Profile tab.",
                    style: TextStyle(
                      fontSize: 13,
                      color: _purple.withOpacity(0.8),
                      height: 1.5,
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

  // ────────── STEP 2: DETAILS ──────────
  Widget _buildStep2Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booking summary card
          _SummaryCard(
            skillName: _selectedSkillName ?? '—',
            addressLabel: _selectedAddressLabel ?? '—',
            addressText: _selectedAddressText ?? '',
          ),

          const SizedBox(height: 24),

          _FormLabel("Job Title *"),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E1B3A),
            ),
            decoration: _inputDeco(
              hint: "e.g. Leaking pipe in kitchen",
              icon: Icons.title_rounded,
            ),
          ),

          const SizedBox(height: 20),

          _FormLabel("Description (optional)"),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E1B3A),
            ),
            decoration: _inputDeco(
              hint:
              "Describe the problem in detail — what happened, what you need…",
              icon: null,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 14,
      ),
      prefixIcon: icon != null
          ? Icon(icon, color: _purple.withOpacity(0.6), size: 20)
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _purple, width: 1.5),
      ),
    );
  }

  // ────────── BOTTOM NAV ──────────
  Widget _buildBottomNav() {
    final bool canContinue = [
      _canAdvanceStep0,
      _canAdvanceStep1,
      _canAdvanceStep2,
    ][_currentStep];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          if (_currentStep > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _OutlineBtn(
                onTap: () => _goToStep(_currentStep - 1),
                child: const Icon(Icons.arrow_back_rounded,
                    color: _purple, size: 20),
              ),
            ),

          // Continue / Confirm button
          Expanded(
            child: AnimatedOpacity(
              opacity: canContinue ? 1 : 0.45,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: canContinue
                    ? () {
                  if (_currentStep < 2) {
                    _goToStep(_currentStep + 1);
                  } else {
                    _submitBooking();
                  }
                }
                    : null,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_purple, _purpleLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: canContinue
                        ? [
                      BoxShadow(
                        color: _purple.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ]
                        : [],
                  ),
                  child: Center(
                    child: _submitting
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : Text(
                      _currentStep < 2 ? "Continue" : "Confirm Booking",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════
//  SUB-WIDGETS
// ══════════════════════════════════════

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF4B4569),
        letterSpacing: 0.2,
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isLoading,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isLoading;
  final ValueChanged<String> onChanged;

  static const _purple = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1E1B3A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: _purple.withOpacity(0.6), size: 20),
        suffixIcon: isLoading
            ? const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _purple,
            ),
          ),
        )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _purple, width: 1.5),
        ),
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({
    required this.items,
    required this.titleKey,
    required this.subtitleKey,
    required this.onSelect,
  });

  final List<dynamic> items;
  final String titleKey;
  final String? subtitleKey;
  final ValueChanged<dynamic> onSelect;

  static const _purple = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (i > 0)
                  Divider(height: 1, color: Colors.grey.shade100),
                ListTile(
                  dense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _purple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: _purple,
                    ),
                  ),
                  title: Text(
                    item[titleKey] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1E1B3A),
                    ),
                  ),
                  subtitle: subtitleKey != null && item[subtitleKey] != null
                      ? Text(
                    item[subtitleKey],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                      : null,
                  onTap: () => onSelect(item),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge({
    required this.label,
    this.sublabel,
    required this.icon,
    required this.onClear,
  });

  final String label;
  final String? sublabel;
  final IconData icon;
  final VoidCallback onClear;

  static const _purple = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _purple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _purple, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E1B3A),
                  ),
                ),
                if (sublabel != null && sublabel!.isNotEmpty)
                  Text(
                    sublabel!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const _purple = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _purple : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? _purple : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: _purple.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF4B4569),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.skillName,
    required this.addressLabel,
    required this.addressText,
  });

  final String skillName;
  final String addressLabel;
  final String addressText;

  static const _purple = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.handyman_rounded,
            label: "Service",
            value: skillName,
          ),
          Divider(height: 20, color: Colors.white.withOpacity(0.2)),
          _SummaryRow(
            icon: Icons.location_on_rounded,
            label: "Location",
            value: addressLabel,
            sub: addressText,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (sub != null && sub!.isNotEmpty)
                Text(
                  sub!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Booking Created!",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1B3A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your job has been posted. A worker will pick it up soon.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Done",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}