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

  /// question id -> the OPTION LABELS this Seeker will never be introduced
  /// to. Per-option since 2026-08-10 (Onboarding Direction B); was
  /// `Map<String, bool>`, one flag per question, which could not express
  /// "never X, but I'd consider Y" on the same question. The database now
  /// refuses the old shape outright — see
  /// onboarding_answers_ch4_hard_shape.
  final Map<String, Set<String>> _ch4HardRequirement = {};

  ZyraBackgroundVariant get _background {
    if (widget.gender == 'male') return ZyraBackgroundVariant.male;
    if (widget.gender == 'female') return ZyraBackgroundVariant.female;
    return ZyraBackgroundVariant.neutral;
  }

  /// Gender gate AND the conditional gate (H4, 2026-08-10). Chapter 4 derives
  /// from this, so a branched-away question disappears from both chapters.
  List<OnboardingQuestion> _visible(OnboardingCategory c) => c.questions
      .where((q) => q.visibleGiven(widget.gender, _ch3Answers))
      .toList();

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

  /// Records a Chapter 3 answer and re-derives the flow from it.
  ///
  /// An answer can now HIDE later questions (H4, 2026-08-10). Three things
  /// must follow, or the flow and the stored data drift apart:
  ///
  ///   1. the step list is rebuilt, because a question further down may have
  ///      just appeared or disappeared;
  ///   2. `_stepIndex` is re-anchored on the question actually on screen,
  ///      since its position may have shifted;
  ///   3. answers to questions that are now hidden are DISCARDED — with their
  ///      Chapter 4 preferences and hard requirements.
  ///
  /// (3) is the one that matters. Someone who says they want children, answers
  /// the family-timing question, then changes their mind would otherwise leave
  /// a stored preference behind on a screen they can no longer see or edit,
  /// and `score_candidates()` would go on matching against it. A hidden
  /// question must leave no trace. The cost is that toggling back re-asks the
  /// question — which is the right way round: re-answering is recoverable,
  /// scoring against invisible data is not.
  void _recordCh3Answer(String questionId, dynamic value) {
    setState(() {
      _ch3Answers[questionId] = value;

      final currentId = _steps[_stepIndex].question?.id;
      _steps = _buildSteps();

      final stillVisible = <String>{
        for (final category in chapter3Categories)
          for (final q in _visible(category)) q.id,
      };
      _ch3Answers.removeWhere((id, _) => !stillVisible.contains(id));
      _ch4Preferences.removeWhere((id, _) => !stillVisible.contains(id));
      _ch4HardRequirement.removeWhere((id, _) => !stillVisible.contains(id));

      if (currentId != null) {
        final index = _steps.indexWhere((s) => s.question?.id == currentId);
        if (index != -1) _stepIndex = index;
      }
      if (_stepIndex >= _steps.length) _stepIndex = _steps.length - 1;
    });
  }

  /// "Family · 4 of 10" rather than just "Family".
  ///
  /// Chapter-level progress alone tells someone they are 30% through 175
  /// questions, which is a discouraging thing to learn. Category-level
  /// progress gives them an end they can actually see from where they are
  /// standing — the categories run 8 to 19 questions, so the next finish line
  /// is never far.
  ///
  /// Counted from the VISIBLE list, so a branched-away question does not
  /// leave a gap ("3 of 10" followed by "5 of 10") and the total shrinks
  /// honestly when a question is skipped.
  String _categoryLabel(_FlowStep step) {
    final question = step.question;
    if (question == null) return step.category.name;
    final questions = _chapter == 3 ? _visible(step.category) : _visibleCh4(step.category);
    final index = questions.indexWhere((q) => q.id == question.id);
    if (index == -1 || questions.length <= 1) return step.category.name;
    return '${step.category.name} · ${index + 1} of ${questions.length}';
  }

  bool get _canContinue {
    final step = _steps[_stepIndex];
    if (step.question == null) return true; // summary screens always continuable
    if (_chapter == 3) {
      final v = _ch3Answers[step.question!.id];
      if (v is List) return v.isNotEmpty;
      return v != null;
    } else {
      // TAP-TO-EXCLUDE, 2026-08-10 (H1, Onboarding Direction B). Continue is
      // ALWAYS enabled in Chapter 4.
      //
      // WAS: `allAnswered && !allRed`, where allAnswered required every option
      // of every question to be set by hand. That is where the 325 mandatory
      // traffic-light taps came from — a floor, not an average, because the
      // Skip control the spec describes has never existed in this build.
      //
      // The !allRed half was worse than the tap count: it disabled the FAB
      // with no explanation, so a Seeker who genuinely wanted to rule out
      // every answer was stuck on the screen with nothing telling them why.
      // TrafficLightQuestionScreen now warns instead of blocking.
      //
      // 🟢 is the resting state and is seeded when the screen is SHOWN, so by
      // the time this runs there is always a complete map for a question the
      // Seeker has actually reached — and nothing at all for one they have not.
      return true;
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
            // Rewritten 2026-08-10 for tap-to-exclude. The old copy told
            // people to "mark each option", which was literally true and cost
            // 325 taps. It also described Hard Requirements as applying to the
            // whole question — exactly the ambiguity the reshape removed.
            //
            // Leading with "you don't have to touch anything" is deliberate:
            // the resting state IS the honest answer for most people, and if
            // the screen does not say so, the conscientious ones will still
            // set every light by hand.
            body: 'Now, teaching ZYRA who you are looking for.\n\n'
                "Every answer starts 🟢 Open — you don't have to touch a thing. Change only "
                'what you feel differently about: 🟡 Flexible if it depends on the person, '
                '🔴 Not Preferred if you would rather not.\n\n'
                'Anything you mark 🔴 can also be made a Hard Requirement on its own. ZYRA '
                'will never introduce someone with that particular answer — while your other '
                '🔴 answers simply count against a match rather than ruling it out.',
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
        subtext: _categoryLabel(step),
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
          onChanged: (value) => _recordCh3Answer(q.id, value),
        ),
      );
    } else {
      return OnboardingScaffold(
        background: _background,
        chapterName: chapterName,
        chapterProgress: progress,
        chapterComplete: complete,
        question: 'Who would you be comfortable with?',
        subtext: _categoryLabel(step),
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
          greenIsResting: true,
          initialHardRequirement: _ch4HardRequirement[q.id] ?? const <String>{},
          onChanged: (values) => setState(() => _ch4Preferences[q.id] = values),
          onHardRequirementChanged: (v) => setState(() {
            // Drop the key entirely rather than storing an empty set, so an
            // untouched question never appears in the payload at all.
            if (v.isEmpty) {
              _ch4HardRequirement.remove(q.id);
            } else {
              _ch4HardRequirement[q.id] = v;
            }
          }),
        ),
      );
    }
  }
}
