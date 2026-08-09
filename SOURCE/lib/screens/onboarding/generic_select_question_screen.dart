// Generic single/multi-select question screen — renders any
// OnboardingQuestion (used for the ~104 Chapter 3 "About You" questions,
// and reused for Chapter 2's "About You" half of each topic). Keeps one
// well-tested renderer instead of one bespoke screen per question.

import 'package:flutter/material.dart';
import '../../models/onboarding_question.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';

class GenericSelectQuestionScreen extends StatefulWidget {
  final String prompt;
  final List<String> options;
  final QuestionSelectionType selectionType;
  final dynamic initialValue; // String for single, List<String> for multi
  final ValueChanged<dynamic> onChanged;

  const GenericSelectQuestionScreen({
    super.key,
    required this.prompt,
    required this.options,
    required this.selectionType,
    required this.onChanged,
    this.initialValue,
  });

  @override
  State<GenericSelectQuestionScreen> createState() => _GenericSelectQuestionScreenState();
}

class _GenericSelectQuestionScreenState extends State<GenericSelectQuestionScreen> {
  late String? _single = widget.initialValue is String ? widget.initialValue as String : null;
  late final List<String> _multi =
      widget.initialValue is List<String> ? List<String>.from(widget.initialValue as List<String>) : <String>[];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.options.map((option) {
        final selected =
            widget.selectionType == QuestionSelectionType.single ? _single == option : _multi.contains(option);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _OptionButton(
            label: option,
            selected: selected,
            onTap: () {
              setState(() {
                if (widget.selectionType == QuestionSelectionType.single) {
                  _single = option;
                  widget.onChanged(_single);
                } else {
                  if (_multi.contains(option)) {
                    _multi.remove(option);
                  } else {
                    _multi.add(option);
                  }
                  widget.onChanged(List<String>.from(_multi));
                }
              });
            },
          ),
        );
      }).toList(),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? ZyraColors.accentBg : ZyraColors.iconButtonBg,
          border: Border.all(color: selected ? ZyraColors.accentBorder : ZyraColors.iconButtonBorder, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: ZyraText.option())),
                  if (selected) const Icon(Icons.check_circle, color: Colors.white70, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
