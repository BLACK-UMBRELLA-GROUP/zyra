// Chapter 3 (Your Values) + Chapter 4 (Your Preferences) — walks all 9
// categories from chapter3_categories.dart. Chapter 3 asks every visible
// "About You" question; Chapter 4 auto-derives one traffic-light
// preference screen for every question with ch4Status != none, mirroring
// its own option list, per Chapter 3 Classification — Ch4 Mapping.md.
// A Category Summary screen follows each category, in both chapters.
// Progress bar is scoped to the whole chapter (resets at Ch3->Ch4), per
// Seeker Onboarding Summary.md §CHAPTER PROGRESS INDICATOR.

import 'package:flutter/material.dart';
import '../../data/chapter3_categories.dart';
import '../../models/onboarding_question.dart';
import '../../services/zyra_onboarding_answers_service.dart';
import '../../theme/zyra_colors.dart';
import '../../widgets/onboarding_scaffold.dart';
import '../../widgets/privacy_indicator.dart';
import 'category_summary_screen.dart';
import 'generic_select_question_screen.dart';
import 'traffic_light_question_screen.dart';
import 'profile_ready_screen.dart';
import 'transition_screen.dart';

class _FlowStep {
  final OnboardingCategory category;
  final OnboardingQuestion? question; // null => this step is the category summary
  const _FlowStep(this.category, this.question);
}

class ValuesPreferencesFlow extends StatefulWidget {
  final String? gender;

  const ValuesPreferencesFlow({super.key, required this.gender});

  @override
  State<ValuesPreferencesFlow> createState() => _ValuesPreferencesFlowState();
}

class _ValuesPreferencesFlowState extends State<ValuesPreferencesFlow> {
  int _chapter = 3; // 3 or 4
  int _stepIndex = 0;

  final Map<String, dynamic> _ch3Answers = {};
  final Map<String, Map<String, TrafficLight>> _ch4Preferences = {};
  final Map<String, bool> _ch4HardRequirement = {};

  ZyraBackgroundVariant get _background {
    if (widget.gender == 'male') return ZyraBackgroundVariant.male;
    if (widget.gender == 'female') return ZyraBackgroundVariant.female;
    return ZyraBackgroundVariant.neutral;
  }

  List<OnboardingQuestion> _visible(OnboardingCategory c) =>
      c.questions.where((q) => q.visibleFor(widget.gender)).toList();

  List<OnboardingQuestion> _visibleCh4(OnboardingCategory c) => _visible(c)
      .where((q) => q.ch4Status != Ch4Status.none)
      .toList();

  late List<_FlowStep> _steps = _buildSteps();

  List<_FlowStep> _buildSteps() {
    final steps = <_FlowStep>[];
    if (_chapter == 3) {
      for (final category in chapter3Categories) {
        final questions = _visible(category);
        if (questions.isEmpty) continue;
        for (final q in questions) {
          steps.add(_FlowStep(category, q));
        }
        steps.add(_FlowStep(category, null));
      }
    } else {
      for (final category in chapter3Categories) {
        final questions = _visibleCh4(category);
        if (questions.isEmpty) continue;
        for (final q in questions) {
          steps.add(_FlowStep(category, q));
        }
        steps.add(_FlowStep(category, null));
      }
    }
    return steps;
  }

  bool get _canContinue {
    final step = _steps[_stepIndex];
    if (step.question == null) return true; // summary screens always continuable
    if (_chapter == 3) {
      final v = _ch3Answers[step.question!.id];
      if (v is List) return v.isNotEmpty;
      return v != null;
    } else {
      final prefs = _ch4Preferences[step.question!.id] ?? {};
      final allAnswered = step.question!.options.every((o) => prefs.containsKey(o));
      final allRed = step.question!.options.isNotEmpty &&
          step.question!.options.every((o) => prefs[o] == TrafficLight.red);
      return allAnswered && !allRed;
    }
  }

  /// Swipe-right-to-go-back across the whole 174-question Chapter 3/4
  /// walk (Onboarding Rules & UX §SCREEN ANATOMY — see onboarding_
  /// scaffold.dart's onSwipeBack doc comment). Category summary screens
  /// aren't reachable via this scaffold (they render their own Scaffold
  /// directly), so this only needs to step back through question steps
  /// within the current chapter — going back across the Ch3->Ch4
  /// transition isn't supported, same boundary limitation as every other
  /// chapter transition in this build (the transition screen is pushed,
  /// not part of this step index).
  void _back() {
    if (_stepIndex > 0) setState(() => _stepIndex--);
  }

  /// Wires CategorySummaryScreen's existing (previously unused) onEdit
  /// hook for Chapter 3 summaries — tapping a question there used to be
  /// a dead tap (onTap: null whenever isPreferences is false). Jumps
  /// straight back to that question so an answer can be corrected
  /// without walking back through the whole category one swipe at a
  /// time. Chapter 4 summaries use onTap for the traffic-light expand/
  /// collapse instead, per CategorySummaryScreen's own isPreferences
  /// branch, so this only applies in Chapter 3.
  void _editQuestion(String questionId) {
    final index = _steps.indexWhere((s) => s.question?.id == questionId);
    if (index != -1) setState(() => _stepIndex = index);
  }

  /// Fire-and-forget checkpoint sync (DR-ZYRA-082, PROPOSED) — called
  /// whenever the user leaves a category summary screen, giving real
  /// crash/interruption resilience across the ~174-question walk
  /// without hitting the network on every single question answer.
  void _syncAnswers() {
    ZyraOnboardingAnswersService.syncAnswers(
      ch3Answers: _ch3Answers,
      ch4Preferences: _ch4Preferences,
      ch4HardRequirements: _ch4HardRequirement,
    );
  }

  void _next() {
    if (_steps[_stepIndex].question == null) _syncAnswers();
    if (_stepIndex < _steps.length - 1) {
      setState(() => _stepIndex++);
      return;
    }
    // End of this chapter — show the transition screen for the next one.
    if (_chapter == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TransitionScreen(
            background: _background,
            title: 'How Preferences Work',
            body: 'Now, teaching ZYRA who you are looking for. For every topic, mark each option '
                '🟢 Open, 🟡 Flexible, or 🔴 Not Preferred. Marking anything 🔴 lets you add it as a '
                'Hard Requirement — ZYRA will never show you a match on that basis.',
            buttonLabel: 'Continue',
            onContinue: () {
              Navigator.of(context).pop();
              setState(() {
                _chapter = 4;
                _stepIndex = 0;
                _steps = _buildSteps();
              });
            },
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TransitionScreen(
            background: _background,
            title: 'Chapter 4 Complete',
            body: "That's everything ZYRA needs to start finding compatible matches for you. "
                "Let's review your profile before it goes live.",
            buttonLabel: 'Review Your Profile',
            onContinue: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ProfileReadyScreen()),
            ),
          ),
        ),
      );
    }
  }

  String _ch3AnswerText(OnboardingQuestion q) {
    final v = _ch3Answers[q.id];
    if (v == null) return '—';
    if (v is List) return v.isEmpty ? '—' : v.join(', ');
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];
    final chapterName = _chapter == 3 ? 'Your Values' : 'Your Preferences';
    final progress = (_stepIndex + 1) / _steps.length;
    final complete = _stepIndex == _steps.length - 1;

    if (step.question == null) {
      // Category summary.
      final questions = _chapter == 3 ? _visible(step.category) : _visibleCh4(step.category);
      return CategorySummaryScreen(
        background: _background,
        categoryName: step.category.name,
        questions: questions,
        answers: _chapter == 3
            ? _ch3Answers
            : {for (final q in questions) q.id: _ch3AnswerText(q)},
        preferences: _chapter == 4 ? _ch4Preferences : null,
        onContinue: _next,
        onEdit: _chapter == 3 ? _editQuestion : null,
      );
    }

    final q = step.question!;

    if (_chapter == 3) {
      return OnboardingScaffold(
        background: _background,
        chapterName: chapterName,
        chapterProgress: progress,
        chapterComplete: complete,
        question: q.prompt,
        subtext: step.category.name,
        privacy: PrivacyLevel.private,
        fabActive: _canContinue,
        onContinue: _next,
        onSwipeBack: _stepIndex > 0 ? _back : null,
        content: GenericSelectQuestionScreen(
          key: ValueKey('ch3_${q.id}_${widget.gender}'),
          prompt: q.prompt,
          options: q.options,
          selectionType: q.selectionType,
          initialValue: _ch3Answers[q.id],
          onChanged: (value) => setState(() => _ch3Answers[q.id] = value),
        ),
      );
    } else {
      return OnboardingScaffold(
        background: _background,
        chapterName: chapterName,
        chapterProgress: progress,
        chapterComplete: complete,
        question: 'Who would you be comfortable with?',
        subtext: step.category.name,
        privacy: PrivacyLevel.private,
        fabActive: _canContinue,
        onContinue: _next,
        onSwipeBack: _stepIndex > 0 ? _back : null,
        content: TrafficLightQuestionScreen(
          key: ValueKey('ch4_${q.id}_${widget.gender}'),
          yourAnswer: _ch3AnswerText(q),
          options: q.options,
          hardRequirementSupported: q.hardRequirementSupported,
          initialValues: _ch4Preferences[q.id] ?? const {},
          initialHardRequirement: _ch4HardRequirement[q.id] ?? false,
          onChanged: (values) => setState(() => _ch4Preferences[q.id] = values),
          onHardRequirementChanged: (v) => setState(() => _ch4HardRequirement[q.id] = v),
        ),
      );
    }
  }
}
