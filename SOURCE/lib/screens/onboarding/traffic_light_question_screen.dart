// Generic Chapter 4 "Your Preferences" screen — mirrors a Chapter 3
// question's own option list and lets the Seeker mark a traffic-light
// preference (🟢 Open / 🟡 Flexible / 🔴 Not Preferred) per option, per
// Onboarding Flow Diagram.md's Chapter 4 pattern. Skip = auto 🟢 for
// every option (Global Traffic Light Rule). Shows a dynamic Hard
// Requirement checkbox once at least one option is marked 🔴.

import 'package:flutter/material.dart';
import '../../models/onboarding_question.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';

class TrafficLightQuestionScreen extends StatefulWidget {
  final String yourAnswer; // "Your answer: ..." shown at the top
  final List<String> options;
  final bool hardRequirementSupported;
  final Map<String, TrafficLight> initialValues;
  final bool initialHardRequirement;
  final ValueChanged<Map<String, TrafficLight>> onChanged;
  final ValueChanged<bool> onHardRequirementChanged;

  const TrafficLightQuestionScreen({
    super.key,
    required this.yourAnswer,
    required this.options,
    required this.onChanged,
    required this.onHardRequirementChanged,
    this.hardRequirementSupported = true,
    this.initialValues = const {},
    this.initialHardRequirement = false,
  });

  @override
  State<TrafficLightQuestionScreen> createState() => _TrafficLightQuestionScreenState();
}

class _TrafficLightQuestionScreenState extends State<TrafficLightQuestionScreen> {
  late Map<String, TrafficLight> _values = Map<String, TrafficLight>.from(widget.initialValues);
  late bool _hardRequirement = widget.initialHardRequirement;

  bool get _anyRed => _values.values.any((v) => v == TrafficLight.red);

  void _set(String option, TrafficLight light) {
    setState(() {
      _values[option] = light;
      if (!_anyRed) _hardRequirement = false;
    });
    widget.onChanged(Map<String, TrafficLight>.from(_values));
    widget.onHardRequirementChanged(_hardRequirement);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.yourAnswer.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: ZyraColors.iconButtonBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
            ),
            child: Text('Your answer: ${widget.yourAnswer}', style: ZyraText.subtext(size: 12.5)),
          ),
          const SizedBox(height: 18),
        ],
        ...widget.options.map((option) {
          final current = _values[option];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(child: Text(option, style: ZyraText.option())),
                const SizedBox(width: 8),
                _LightButton(
                  light: TrafficLight.green,
                  active: current == TrafficLight.green,
                  onTap: () => _set(option, TrafficLight.green),
                ),
                _LightButton(
                  light: TrafficLight.yellow,
                  active: current == TrafficLight.yellow,
                  onTap: () => _set(option, TrafficLight.yellow),
                ),
                _LightButton(
                  light: TrafficLight.red,
                  active: current == TrafficLight.red,
                  onTap: () => _set(option, TrafficLight.red),
                ),
              ],
            ),
          );
        }),
        if (widget.hardRequirementSupported && _anyRed) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              setState(() => _hardRequirement = !_hardRequirement);
              widget.onHardRequirementChanged(_hardRequirement);
            },
            child: Row(
              children: [
                Icon(
                  _hardRequirement ? Icons.check_box : Icons.check_box_outline_blank,
                  color: Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Never show me people matching the options I marked 🔴.',
                    style: ZyraText.subtext(size: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _LightButton extends StatelessWidget {
  final TrafficLight light;
  final bool active;
  final VoidCallback onTap;

  const _LightButton({required this.light, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? ZyraColors.accentBg : Colors.transparent,
          border: Border.all(color: active ? ZyraColors.accentBorder : Colors.white12, width: 1),
        ),
        child: Text(light.emoji, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
