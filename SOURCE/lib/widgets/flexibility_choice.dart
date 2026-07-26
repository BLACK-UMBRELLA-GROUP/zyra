// Reusable "Flexibility" question — the single 🟢/🟡/🔴 sentence-choice
// pattern used throughout Chapter 2 (Questions Section 2 Profile
// Information.md), distinct from Chapter 4's per-option traffic-light
// matrix (traffic_light_question_screen.dart handles that one instead).

import 'package:flutter/material.dart';
import '../models/onboarding_question.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

class FlexibilityChoice extends StatelessWidget {
  final String greenText;
  final String yellowText;
  final String redText;
  final TrafficLight? value;
  final ValueChanged<TrafficLight> onChanged;

  const FlexibilityChoice({
    super.key,
    required this.greenText,
    required this.yellowText,
    required this.redText,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final entries = [
      (TrafficLight.green, greenText),
      (TrafficLight.yellow, yellowText),
      (TrafficLight.red, redText),
    ];
    return Column(
      children: entries.map((e) {
        final selected = value == e.$1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
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
                  onTap: () => onChanged(e.$1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Text(e.$1.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(e.$2, style: ZyraText.option())),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
