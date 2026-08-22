// Combined compatibility category summary. Every card keeps the Seeker's own
// answer visible; scored questions can expand to show the traffic lights set
// immediately after that answer. Only one card expands at a time.

import 'package:flutter/material.dart';
import '../../models/onboarding_question.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';

class CategorySummaryScreen extends StatefulWidget {
  final ZyraBackgroundVariant background;
  final String categoryName;
  final List<OnboardingQuestion> questions;
  final Map<String, dynamic> answers; // question id -> String or List<String>
  final Map<String, Map<String, TrafficLight>>? preferences; // Ch4 only
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final void Function(String questionId)? onEdit;

  const CategorySummaryScreen({
    super.key,
    required this.background,
    required this.categoryName,
    required this.questions,
    required this.answers,
    required this.onContinue,
    this.preferences,
    this.onBack,
    this.onEdit,
  });

  @override
  State<CategorySummaryScreen> createState() => _CategorySummaryScreenState();
}

class _CategorySummaryScreenState extends State<CategorySummaryScreen> {
  String? _expandedId;

  String _answerText(OnboardingQuestion q) {
    final value = widget.answers[q.responseKey];
    if (value == null) return '—';
    if (value is List) return value.isEmpty ? '—' : value.join(', ');
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: ZyraColors.backgroundFor(widget.background),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  if (widget.onBack != null)
                    _SummaryUpCue(onTap: widget.onBack!),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF50B478),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.categoryName} Complete',
                            key: const ValueKey(
                              'compatibility_category_complete',
                            ),
                            style: ZyraText.heading(size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.preferences == null
                            ? 'Review your About You answers before continuing.'
                            : 'Review your answers. Open a scored question to check its traffic lights.',
                        style: ZyraText.subtext(
                          size: 11.5,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 104),
                      itemCount: widget.questions.length,
                      itemBuilder: (context, index) {
                        final q = widget.questions[index];
                        final expanded = _expandedId == q.responseKey;
                        final hasPreferences =
                            widget.preferences?[q.responseKey] != null;
                        return _SummaryCard(
                          question: q,
                          expanded: expanded && hasPreferences,
                          expandable: hasPreferences,
                          answerText: _answerText(q),
                          preferences: widget.preferences?[q.responseKey],
                          onTap: hasPreferences
                              ? () => setState(
                                  () => _expandedId = expanded
                                      ? null
                                      : q.responseKey,
                                )
                              : (widget.onEdit != null
                                    ? () => widget.onEdit!(q.id)
                                    : null),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: SafeArea(
                top: false,
                child: _SummaryDownCue(onTap: widget.onContinue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryUpCue extends StatelessWidget {
  final VoidCallback onTap;

  const _SummaryUpCue({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Return to the previous compatibility question',
      child: InkWell(
        key: const ValueKey('compatibility_summary_back'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white70,
                size: 21,
              ),
              Text(
                'Previous question',
                style: ZyraText.subtext(size: 9.5, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryDownCue extends StatelessWidget {
  final VoidCallback onTap;

  const _SummaryDownCue({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Continue to the next compatibility section',
      child: InkWell(
        key: const ValueKey('compatibility_summary_continue'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: ZyraColors.unlockText,
                size: 25,
              ),
              const SizedBox(height: 3),
              Text(
                'Continue',
                style: ZyraText.subtext(size: 11.5, color: Colors.white70),
              ),
            ],
          ),
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
                      Icon(
                        expanded ? Icons.expand_more : Icons.chevron_right,
                        color: Colors.white54,
                        size: 18,
                      ),
                    Expanded(
                      child: Text(
                        question.prompt,
                        style: ZyraText.body(size: 13.5),
                      ),
                    ),
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
                          Expanded(
                            child: Text(
                              option,
                              style: ZyraText.subtext(size: 12),
                            ),
                          ),
                          Text(
                            light?.emoji ?? '—',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(color: Colors.white12, height: 18),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Your Answer',
                      style: ZyraText.subtext(
                        size: 11.5,
                        color: Colors.white38,
                      ),
                    ),
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
