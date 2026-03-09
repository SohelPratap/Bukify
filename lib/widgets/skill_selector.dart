import 'package:flutter/material.dart';
import '../services/skills_service.dart';

class SkillSelector extends StatefulWidget {

  final Function(Map skill) onSkillSelected;

  const SkillSelector({
    super.key,
    required this.onSkillSelected,
  });

  @override
  State<SkillSelector> createState() => _SkillSelectorState();
}

class _SkillSelectorState extends State<SkillSelector> {

  final TextEditingController _controller = TextEditingController();

  List<dynamic> _suggestions = [];

  bool _loading = false;

  Future<void> _search(String value) async {

    if (value.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _loading = true);

    try {

      final results =
      await SkillService.searchSkills(value);

      setState(() {
        _suggestions = results;
        _loading = false;
      });

    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _selectSkill(Map skill) {

    widget.onSkillSelected(skill);

    _controller.clear();

    setState(() {
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        TextField(
          controller: _controller,
          onChanged: _search,

          decoration: InputDecoration(
            hintText: "Search skills...",
            prefixIcon: const Icon(Icons.search),

            filled: true,
            fillColor: Colors.grey[100],

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 10),

        if (_loading)
          const Padding(
            padding: EdgeInsets.all(10),
            child: CircularProgressIndicator(),
          ),

        if (_suggestions.isNotEmpty)
          Container(
            constraints:
            const BoxConstraints(maxHeight: 200),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(12),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                )
              ],
            ),

            child: ListView.builder(
              shrinkWrap: true,

              itemCount: _suggestions.length,

              itemBuilder: (context, index) {

                final skill =
                _suggestions[index];

                return ListTile(

                  title:
                  Text(skill['name']),

                  onTap:
                      () =>
                      _selectSkill(skill),
                );
              },
            ),
          ),

      ],
    );
  }
}