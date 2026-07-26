// Category Summary — shown after each Chapter 3/4 category per Onboarding
// Rules & UX / Seeker Onboarding Summary.md §CATEGORY SUMMARY. Chapter 3
// summary shows only "Your Answer"; Chapter 4 summary shows the traffic
// light per option, expandable. Only one card expands at a time.

import 'package:flutter/material.dart';
import '../../models/onboarding_question.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/fab_continue_button.dart';

class CategorySummaryScreen extends StatefulWidget {
  final ZyraBackgroundVariant background;
  final String categoryName;
  final List<OnboardingQuestion> questions;
  final Map<String, dynamic> answers; // question id -> String or List<String>
  final Map<String, Map<String, TrafficLight>>? preferences; // Ch4 only
  final VoidCallback onContinue;
  final void Function(String questionId)? onEdit;

  const CategorySummaryScreen({
    super.key,
    required this.background,
    required this.categoryName,
    required this.questions,
    required this.answers,
    required this.onContinue,
    this.preferences,
    this.onEdit,
  });

  @override
  State<CategorySummaryScreen> createState() => _CategorySummaryScreenState();
}

class _CategorySummaryScreenState extends State<CategorySummaryScreen> {
  String? _expandedId;

  String _answerText(OnboardingQuestion q) {
    final value = widget.answers[q.id];
    if (value == null) return '—';
    if (value is List) return value.isEmpty ? '—' : value.join(', ');
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isPreferences = widget.preferences != null;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: ZyraColors.backgroundFor(widget.background)),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF50B478), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('${widget.categoryName} Complete', style: ZyraText.heading(size: 18)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
                      itemCount: widget.questions.length,
                      itemBuilder: (context, index) {
                        final q = widget.questions[index];
                        final expanded = _expandedId == q.id;
                        return _SummaryCard(
                          question: q,
                          expanded: expanded && isPreferences,
                          expandable: isPreferences,
                          answerText: _answerText(q),
                          preferences: widget.preferences?[q.id],
                          onTap: isPreferences
                              ? () => setState(() => _expandedId = expanded ? null : q.id)
                              : (widget.onEdit != null ? () => widget.onEdit!(q.id) : null),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            FabContinueButton(active: true, onPressed: widget.onContinue),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final OnboardingQuestion question;
  final bool expanded;
  final bool expandable;
  final String answerText;
  final Map<String, TrafficLight>? preferences;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.question,
    required this.expanded,
    required this.expandable,
    required this.answerText,
    required this.preferences,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ZyraColors.iconButtonBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (expandable)
                      Icon(expanded ? Icons.expand_more : Icons.chevron_right, color: Colors.white54, size: 18),
                    Expanded(child: Text(question.prompt, style: ZyraText.body(size: 13.5))),
                  ],
                ),
                if (expanded && preferences != null) ...[
                  const SizedBox(height: 10),
                  ...question.options.map((option) {
                    final light = preferences![option];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(child: Text(option, style: ZyraText.subtext(size: 12))),
                          Text(light?.emoji ?? '—', style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }),
                  const Divider(color: Colors.white12, height: 18),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('Your Answer', style: ZyraText.subtext(size: 11.5, color: Colors.white38)),
                    const Spacer(),
                    Text(answerText, style: ZyraText.body(size: 12.5)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
