// Generic traffic-light preference screen — mirrors a question's own option
// list and lets the Seeker mark 🟢 Open / 🟡 Flexible / 🔴 Not Preferred per
// option, per Onboarding Flow Diagram.md's Chapter 4 pattern.
//
// HARD REQUIREMENTS ARE PER-OPTION IN CHAPTER 4 SINCE 2026-08-10 (Onboarding
// Direction B, Founder decision; migration onboarding_b_stage1_hard_
// requirements_become_per_option). WAS: one checkbox per QUESTION reading
// "Never show me people matching the options I marked 🔴" — which meant a
// Seeker could not say
//
//     Currently Married — never.
//     Divorced        — I'd rather not, but I'd consider the right person.
//
// on the same question. Ticking the box excluded both; leaving it off excluded
// neither. There was no third position, and nothing on screen hinted that one
// checkbox reached past the option the user was looking at.
//
// The wire shape is {question_id: [option_label, ...]} and the database CHECK
// constraint onboarding_answers_ch4_hard_shape rejects the retired
// {question_id: bool} form outright — deliberately, because a silent
// old-shape write would read as "no hard requirement at all", failing OPEN on
// a promise the Seeker made.
//
// NOTE: the spec's Skip control (Onboarding Rules & UX §Global Traffic Light
// Rules — "Skip records 🟢 for every option") has never existed in this file,
// despite the rule being written as though it did. It is not being added
// here; it is superseded by tap-to-exclude, where 🟢 becomes the resting
// state and Continue is always enabled.

import 'package:flutter/material.dart';
import '../../models/onboarding_question.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';

// RETIRED 2026-08-10: `HardRequirementScope`. It existed for a few hours to
// let Chapter 2 keep a single question-wide checkbox while Chapter 4 moved to
// per-option exclusions, because seeker_details.preferences still stored
// {sect: {hard_requirement: bool}} across 144 live rows. Showing the
// per-option control over that storage would have let someone exclude Ibadi
// but not Shia while the engine still excluded both — a screen promising
// precision the server could not honour.
//
// Chapter 2 converged the same afternoon (OA-ZYRA-185): those rows were
// converted, a CHECK now rejects the boolean form, and score_candidates()
// tests the sect exclusion per-option and independently of the light. Both
// chapters use one model, so the enum and its branch are gone rather than
// left as a dormant fork nobody would remember the reason for.

class TrafficLightQuestionScreen extends StatefulWidget {
  final String yourAnswer; // "Your answer: ..." shown at the top
  final List<String> options;
  final bool hardRequirementSupported;
  final Map<String, TrafficLight> initialValues;

  /// Option labels this Seeker will never be introduced to, for THIS question.
  /// Under [HardRequirementScope.perQuestion] this is all-or-nothing: either
  /// empty, or exactly the set of 🔴 options.
  final Set<String> initialHardRequirement;

  /// TAP-TO-EXCLUDE (H1, Onboarding Direction B, 2026-08-10).
  ///
  /// When true, every option starts 🟢 and the Seeker touches only what they
  /// are NOT open to. Chapter 4 required all 325 lights to be set by hand
  /// before Continue would enable — measured from the live data file, and a
  /// floor rather than an average, because there was no Skip control despite
  /// the spec describing one.
  ///
  /// Green is the resting state, so most questions now cost zero taps.
  ///
  /// **Seeding happens on SHOW, never in advance** — Founder decision
  /// 2026-08-10. A question whose screen the Seeker never reached records
  /// nothing at all. Pre-seeding the whole chapter on entry would manufacture
  /// 71 questions of stated preference from someone who answered three, which
  /// is the same dishonesty as the old "Skip records green" rule, only larger.
  ///
  /// OFF for Chapter 2's sect matrix: five options on one screen is not the
  /// problem H1 solves, and changing that screen's completion rule was not in
  /// the approved scope.
  final bool greenIsResting;

  final ValueChanged<Map<String, TrafficLight>> onChanged;
  final ValueChanged<Set<String>> onHardRequirementChanged;

  const TrafficLightQuestionScreen({
    super.key,
    required this.yourAnswer,
    required this.options,
    required this.onChanged,
    required this.onHardRequirementChanged,
    this.hardRequirementSupported = true,
    this.initialValues = const {},
    this.initialHardRequirement = const {},
    this.greenIsResting = false,
  });

  @override
  State<TrafficLightQuestionScreen> createState() => _TrafficLightQuestionScreenState();
}

class _TrafficLightQuestionScreenState extends State<TrafficLightQuestionScreen> {
  late final Map<String, TrafficLight> _values = Map<String, TrafficLight>.from(widget.initialValues);
  late final Set<String> _hard = Set<String>.from(widget.initialHardRequirement);

  Set<String> get _redOptions =>
      widget.options.where((o) => _values[o] == TrafficLight.red).toSet();

  bool get _allRed =>
      widget.options.isNotEmpty && _redOptions.length == widget.options.length;

  @override
  void initState() {
    super.initState();
    if (!widget.greenIsResting) return;

    // THIS is the moment a Chapter 4 question counts as "shown". The widget
    // only exists because the Seeker navigated to it, so seeding here — and
    // nowhere earlier — is exactly the rule the Founder set: a screen they
    // never reached records nothing.
    //
    // Only fills gaps, so coming back to a question does not wipe what they
    // already said.
    final missing = widget.options.where((o) => !_values.containsKey(o)).toList();
    if (missing.isEmpty) return;
    for (final option in missing) {
      _values[option] = TrafficLight.green;
    }
    // Deferred: initState runs mid-build, and onChanged calls setState on the
    // parent flow. Calling it inline throws
    // "setState() or markNeedsBuild() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged(Map<String, TrafficLight>.from(_values));
    });
  }

  void _set(String option, TrafficLight light) {
    setState(() {
      _values[option] = light;

      if (light != TrafficLight.red) {
        // An exclusion cannot outlive the 🔴 that justified it. Without this,
        // a Seeker who marks Divorced 🔴, ticks "never", then changes back to
        // 🟢 would keep an invisible permanent exclusion — and the server now
        // enforces exclusions INDEPENDENTLY of the lights, so it would
        // genuinely bind with nothing on screen to explain it.
        _hard.remove(option);
      }
    });
    widget.onChanged(Map<String, TrafficLight>.from(_values));
    widget.onHardRequirementChanged(Set<String>.from(_hard));
  }

  void _toggleHardOption(String option) {
    setState(() {
      if (!_hard.remove(option)) _hard.add(option);
    });
    widget.onHardRequirementChanged(Set<String>.from(_hard));
  }

  @override
  Widget build(BuildContext context) {
    final showHard = widget.hardRequirementSupported;
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
          final isRed = current == TrafficLight.red;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                      active: isRed,
                      onTap: () => _set(option, TrafficLight.red),
                    ),
                  ],
                ),
                // The exclusion belongs to the option, not the question, so it
                // renders under the option — indented, so it reads as a
                // qualifier on the row above rather than a new question.
                if (showHard && isRed) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _toggleHardOption(option),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2, top: 2, bottom: 2),
                      child: Row(
                        children: [
                          Icon(
                            _hard.contains(option) ? Icons.check_box : Icons.check_box_outline_blank,
                            color: Colors.white54,
                            size: 17,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Never introduce anyone who answered "$option".',
                              style: ZyraText.subtext(size: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),

        // ALL-RED — a WARNING, NOT A BLOCK (changed 2026-08-10, H1).
        //
        // Continue used to be disabled here, which stranded people mid-
        // question with no explanation of what they had done wrong: the FAB
        // simply stopped working. The old copy ("At least one option must
        // remain 🟢 or 🟡") was a rule the screen never showed until you had
        // already broken it.
        //
        // Marking everything 🔴 is a legitimate thing to mean. The Seeker is
        // told what it costs and allowed to proceed.
        if (_allRed) ...[
          const SizedBox(height: 4),
          Text(
            _hard.length == widget.options.length
                ? 'You have ruled out every answer to this question, so nobody who '
                    'answers it can be introduced to you.'
                : "You're not open to any answer here. ZYRA can still introduce "
                    'people, but this question will count against every one of them.',
            style: ZyraText.subtext(size: 11.5),
          ),
          const SizedBox(height: 4),
        ],

        // Chapter 4 — a plain-language confirmation of what was just promised.
        if (showHard && _hard.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            _hard.length == 1
                ? 'ZYRA will never introduce someone with that answer.'
                : 'ZYRA will never introduce someone with any of those ${_hard.length} answers.',
            style: ZyraText.subtext(size: 11.5),
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
