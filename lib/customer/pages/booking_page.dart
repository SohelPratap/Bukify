import 'package:flutter/material.dart';
import '../../services/customer_jobs_service.dart';
import '../../services/customer_service.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {

  String? _selectedSkillId;
  String? _selectedAddressId;

  final TextEditingController _serviceSearchController =
  TextEditingController();

  final TextEditingController _addressSearchController =
  TextEditingController();

  final TextEditingController _titleController =
  TextEditingController();

  final TextEditingController _descriptionController =
  TextEditingController();

  bool _submitting = false;

  List<dynamic> _skillSuggestions = [];
  List<dynamic> _addressSuggestions = [];

  bool _searchingSkill = false;
  bool _searchingAddress = false;

  /// ================= SEARCH SKILLS =================
  Future<void> _searchSkills(String query) async {
    if (query.isEmpty) {
      setState(() => _skillSuggestions = []);
      return;
    }

    setState(() => _searchingSkill = true);

    try {
      final results =
      await CustomerService.searchSkills(query);

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

  /// ================= SEARCH ADDRESSES =================
  Future<void> _searchAddresses(String query) async {
    if (query.isEmpty) {
      setState(() => _addressSuggestions = []);
      return;
    }

    setState(() => _searchingAddress = true);

    try {
      final results =
      await CustomerService.searchAddresses(query);

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

  /// ================= SUBMIT =================
  Future<void> _submitBooking() async {

    if (_selectedSkillId == null ||
        _selectedAddressId == null ||
        _titleController.text.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(
        content: Text("Please fill required fields"),
      ));
      return;
    }

    setState(() => _submitting = true);

    try {

      await JobsService.createJob(
        skillId: _selectedSkillId!,
        addressId: _selectedAddressId!,
        title: _titleController.text,
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
        _selectedAddressId = null;
        _skillSuggestions = [];
        _addressSuggestions = [];
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(
        content: Text("Booking created successfully"),
      ));

    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(
        content: Text("Failed to create booking"),
      ));
    }

    if (!mounted) return;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Book a Service",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5CF6),
            ),
          ),

          const SizedBox(height: 20),

          /// ===== SERVICE SEARCH =====
          TextField(
            controller: _serviceSearchController,
            onChanged: _searchSkills,
            decoration: const InputDecoration(
              labelText: "Search Service",
              border: OutlineInputBorder(),
            ),
          ),

          if (_searchingSkill)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),

          if (_skillSuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: _skillSuggestions
                    .map((skill) => ListTile(
                  title: Text(skill['name']),
                  onTap: () {
                    setState(() {
                      _selectedSkillId = skill['id'];
                      _serviceSearchController.text =
                      skill['name'];
                      _skillSuggestions = [];
                    });
                  },
                ))
                    .toList(),
              ),
            ),

          const SizedBox(height: 20),

          /// ===== ADDRESS SEARCH =====
          TextField(
            controller: _addressSearchController,
            onChanged: _searchAddresses,
            decoration: const InputDecoration(
              labelText: "Search Address",
              border: OutlineInputBorder(),
            ),
          ),

          if (_searchingAddress)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),

          if (_addressSuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: _addressSuggestions
                    .map((addr) => ListTile(
                  title: Text(addr['label'] ?? "Address"),
                  subtitle: Text(addr['address'] ?? ""),
                  onTap: () {
                    setState(() {
                      _selectedAddressId = addr['id'];
                      _addressSearchController.text =
                          addr['label'] ?? "Address";
                      _addressSuggestions = [];
                    });
                  },
                ))
                    .toList(),
              ),
            ),

          const SizedBox(height: 20),

          /// ===== TITLE =====
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: "Job Title",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          /// ===== DESCRIPTION =====
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: "Describe the problem (optional)",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
              _submitting ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
              ),
              child: _submitting
                  ? const CircularProgressIndicator(
                  color: Colors.white)
                  : const Text(
                "Confirm Booking",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}