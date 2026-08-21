// Compatibility onboarding — two calm, separate modes over the existing
// Chapter 3/4 storage contract.
//
// Part 1 asks every private "About You" question, grouped into the 11
// Founder-approved sections. Part 2 then revisits those same sections as 11
// scrolling Partner Preference pages. The traffic-light map remains
// per-option, so score_candidates() and saved onboarding rows do not change.

import 'package:flutter/material.dart';

import '../../data/chapter3_categories.dart';
import '../../models/onboarding_question.dart';
import '../../services/zyra_onboarding_answers_service.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/onboarding_scaffold.dart';
import '../../widgets/privacy_indicator.dart';
import 'category_summary_screen.dart';
import 'compatibility_category_intro_screen.dart';
import 'generic_select_question_screen.dart';
import 'onboarding_stage_intro_screen.dart';
import 'profile_ready_screen.dart';
import 'traffic_light_question_screen.dart';

enum _FlowStepKind {
  categoryIntro,
  answer,
  summary,
  aboutYouComplete,
  preferencesIntro,
  preferenceGuide,
  preferenceSection,
}

class _FlowStep {
  final _FlowStepKind kind;
  final OnboardingCategory? category;
  final OnboardingQuestion? question;

  const _FlowStep(this.kind, {this.category, this.question});

  String get anchor => switch (kind) {
    _FlowStepKind.categoryIntro => 'intro:${category!.id}',
    _FlowStepKind.answer => 'answer:${question!.id}',
    _FlowStepKind.summary => 'summary:${category!.id}',
    _FlowStepKind.aboutYouComplete => 'about-complete',
    _FlowStepKind.preferencesIntro => 'preferences-intro',
    _FlowStepKind.preferenceGuide => 'preferences-guide',
    _FlowStepKind.preferenceSection => 'preferences:${category!.id}',
  };
}

class ValuesPreferencesFlow extends StatefulWidget {
  final String? gender;
  final bool devPreview;

  const ValuesPreferencesFlow({
    super.key,
    required this.gender,
    this.devPreview = false,
  });

  @override
  State<ValuesPreferencesFlow> createState() => _ValuesPreferencesFlowState();
}

class _ValuesPreferencesFlowState extends State<ValuesPreferencesFlow> {
  int _stepIndex = 0;

  final Map<String, dynamic> _ch3Answers = {};
  final Map<String, Map<String, TrafficLight>> _ch4Preferences = {};
  final Map<String, Set<String>> _ch4HardRequirement = {};

  ZyraBackgroundVariant get _background => switch (widget.gender) {
    'male' => ZyraBackgroundVariant.male,
    'female' => ZyraBackgroundVariant.female,
    _ => ZyraBackgroundVariant.neutral,
  };

  List<OnboardingQuestion> _visible(OnboardingCategory category) => category
      .questions
      .where((question) => question.visibleGiven(widget.gender, _ch3Answers))
      .toList(growable: false);

  List<OnboardingQuestion> _preferenceQuestions(OnboardingCategory category) =>
      _visible(category)
          .where((question) => question.ch4Status != Ch4Status.none)
          .toList(growable: false);

  late List<_FlowStep> _steps = _buildSteps();

  List<_FlowStep> _buildSteps() {
    final steps = <_FlowStep>[];

    for (final category in chapter3Categories) {
      final questions = _visible(category);
      if (questions.isEmpty) continue;
      steps.add(_FlowStep(_FlowStepKind.categoryIntro, category: category));
      for (final question in questions) {
        steps.add(
          _FlowStep(
            _FlowStepKind.answer,
            category: category,
            question: question,
          ),
        );
      }
      steps.add(_FlowStep(_FlowStepKind.summary, category: category));
    }

    steps.add(const _FlowStep(_FlowStepKind.aboutYouComplete));
    steps.add(const _FlowStep(_FlowStepKind.preferencesIntro));
    steps.add(const _FlowStep(_FlowStepKind.preferenceGuide));

    for (final category in chapter3Categories) {
      if (_preferenceQuestions(category).isEmpty) continue;
      steps.add(_FlowStep(_FlowStepKind.preferenceSection, category: category));
    }

    return steps;
  }

  void _recordCh3Answer(String questionId, dynamic value) {
    setState(() {
      _ch3Answers[questionId] = value;

      final anchor = _steps[_stepIndex].anchor;
      _steps = _buildSteps();

      final stillVisible = <String>{
        for (final category in chapter3Categories)
          for (final question in _visible(category)) question.id,
      };
      _ch3Answers.removeWhere((id, _) => !stillVisible.contains(id));
      _ch4Preferences.removeWhere((id, _) => !stillVisible.contains(id));
      _ch4HardRequirement.removeWhere((id, _) => !stillVisible.contains(id));

      final reanchored = _steps.indexWhere((step) => step.anchor == anchor);
      if (reanchored != -1) _stepIndex = reanchored;
      if (_stepIndex >= _steps.length) _stepIndex = _steps.length - 1;
    });
  }

  void _back() {
    if (_stepIndex > 0) setState(() => _stepIndex--);
  }

  void _syncAnswers() {
    if (widget.devPreview) return;
    ZyraOnboardingAnswersService.syncAnswers(
      ch3Answers: _ch3Answers,
      ch4Preferences: _ch4Preferences,
      ch4HardRequirements: _ch4HardRequirement,
    );
  }

  void _next() {
    final step = _steps[_stepIndex];
    if (step.kind == _FlowStepKind.summary ||
        step.kind == _FlowStepKind.preferenceSection) {
      _syncAnswers();
    }

    if (_stepIndex < _steps.length - 1) {
      setState(() => _stepIndex++);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (stageContext) => OnboardingStageIntroScreen(
          stage: SeekerOnboardingStage.review,
          onContinue: () => Navigator.of(stageContext).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProfileReadyScreen()),
          ),
        ),
      ),
    );
  }

  Set<String> _answerOptions(OnboardingQuestion question) {
    final answer = _ch3Answers[question.id];
    if (answer == null) return const {};
    if (answer is List) {
      return answer.map((value) => value.toString()).toSet();
    }
    return {answer.toString()};
  }

  bool _answerComplete(OnboardingQuestion question) {
    final value = _ch3Answers[question.id];
    if (value is List) return value.isNotEmpty;
    return value != null;
  }

  bool _preferenceSectionComplete(OnboardingCategory category) =>
      _preferenceQuestions(category).every((question) {
        final values = _ch4Preferences[question.id];
        return values != null && question.options.every(values.containsKey);
      });

  bool get _canContinue {
    final step = _steps[_stepIndex];
    return switch (step.kind) {
      _FlowStepKind.answer => _answerComplete(step.question!),
      _FlowStepKind.preferenceSection => _preferenceSectionComplete(
        step.category!,
      ),
      _ => true,
    };
  }

  int _sectionIndex(OnboardingCategory category) =>
      chapter3Categories.indexWhere((item) => item.id == category.id) + 1;

  Widget _buildPreferenceSection(_FlowStep step) {
    final category = step.category!;
    final questions = _preferenceQuestions(category);
    final sectionIndex = _sectionIndex(category);

    return OnboardingScaffold(
      background: _background,
      chapterName: 'Compatibility · Part 2',
      chapterProgress: sectionIndex / chapter3Categories.length,
      chapterComplete: sectionIndex == chapter3Categories.length,
      question: category.name,
      subtext:
          'Section $sectionIndex of ${chapter3Categories.length} · '
          '${questions.length} partner ${questions.length == 1 ? 'preference' : 'preferences'}',
      privacy: PrivacyLevel.private,
      privacyOverrideText:
          'Private. Used to calculate your compatibility score.',
      fabActive: _canContinue,
      onContinue: _next,
      devPreview: widget.devPreview,
      onDevSkip: _next,
      devSkipLabel: 'Skip section',
      onSwipeBack: _back,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < questions.length; index++) ...[
            _PreferenceQuestionBlock(
              question: questions[index],
              position: index + 1,
              total: questions.length,
              yourAnswers: _answerOptions(questions[index]),
              initialValues: _ch4Preferences[questions[index].id] ?? const {},
              initialHardRequirement:
                  _ch4HardRequirement[questions[index].id] ?? const {},
              onChanged: (values) =>
                  setState(() => _ch4Preferences[questions[index].id] = values),
              onHardRequirementChanged: (values) => setState(() {
                if (values.isEmpty) {
                  _ch4HardRequirement.remove(questions[index].id);
                } else {
                  _ch4HardRequirement[questions[index].id] = values;
                }
              }),
            ),
            if (index != questions.length - 1) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];

    if (step.kind == _FlowStepKind.categoryIntro) {
      final category = step.category!;
      return CompatibilityCategoryIntroScreen(
        category: category,
        sectionIndex: _sectionIndex(category),
        totalSections: chapter3Categories.length,
        questionCount: _visible(category).length,
        onContinue: _next,
        onBack: _stepIndex > 0 ? _back : null,
      );
    }

    if (step.kind == _FlowStepKind.summary) {
      final category = step.category!;
      return CategorySummaryScreen(
        background: _background,
        categoryName: category.name,
        questions: _visible(category),
        answers: _ch3Answers,
        onContinue: _next,
        onBack: _back,
      );
    }

    if (step.kind == _FlowStepKind.aboutYouComplete) {
      return _CompatibilityBoundaryScreen(
        eyebrow: 'COMPATIBILITY · PART 1 COMPLETE',
        title: 'About You saved.',
        description:
            'Your private answers across all 11 sections are complete.',
        count: '104',
        countLabel: 'about-you answers',
        continueLabel: 'Continue',
        onContinue: _next,
        onBack: _back,
      );
    }

    if (step.kind == _FlowStepKind.preferencesIntro) {
      return _CompatibilityBoundaryScreen(
        eyebrow: 'COMPATIBILITY · PART 2',
        title: 'Partner Preferences',
        description:
            'Move through the same sections again and set what you prefer, feel neutral about or would rather avoid.',
        count: '11',
        countLabel: 'scrolling sections',
        continueLabel: 'Begin Partner Preferences',
        onContinue: _next,
        onBack: _back,
      );
    }

    if (step.kind == _FlowStepKind.preferenceGuide) {
      return _PreferenceGuideScreen(onContinue: _next, onBack: _back);
    }

    if (step.kind == _FlowStepKind.preferenceSection) {
      return _buildPreferenceSection(step);
    }

    final question = step.question!;
    final category = step.category!;
    final visibleQuestions = _visible(category);
    final questionIndex =
        visibleQuestions.indexWhere((item) => item.id == question.id) + 1;
    final sectionIndex = _sectionIndex(category);

    return OnboardingScaffold(
      background: _background,
      chapterName: 'Compatibility · Part 1',
      chapterProgress: questionIndex / visibleQuestions.length,
      chapterComplete:
          sectionIndex == chapter3Categories.length &&
          questionIndex == visibleQuestions.length,
      question: question.prompt,
      subtext:
          'Section $sectionIndex of ${chapter3Categories.length} · '
          'Question $questionIndex of ${visibleQuestions.length}',
      privacy: PrivacyLevel.private,
      privacyOverrideText:
          'Private. Used to calculate your compatibility score.',
      fabActive: _canContinue,
      onContinue: _next,
      devPreview: widget.devPreview,
      onDevSkip: _next,
      onSwipeBack: _stepIndex > 0 ? _back : null,
      content: GenericSelectQuestionScreen(
        key: ValueKey('ch3_${question.id}_${widget.gender}'),
        prompt: question.prompt,
        options: question.options,
        selectionType: question.selectionType,
        initialValue: _ch3Answers[question.id],
        onChanged: (value) => _recordCh3Answer(question.id, value),
      ),
    );
  }
}

class _PreferenceQuestionBlock extends StatelessWidget {
  final OnboardingQuestion question;
  final int position;
  final int total;
  final Set<String> yourAnswers;
  final Map<String, TrafficLight> initialValues;
  final Set<String> initialHardRequirement;
  final ValueChanged<Map<String, TrafficLight>> onChanged;
  final ValueChanged<Set<String>> onHardRequirementChanged;

  const _PreferenceQuestionBlock({
    required this.question,
    required this.position,
    required this.total,
    required this.yourAnswers,
    required this.initialValues,
    required this.initialHardRequirement,
    required this.onChanged,
    required this.onHardRequirementChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(
        color: ZyraColors.iconButtonBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ZyraColors.iconButtonBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 22,
                decoration: BoxDecoration(
                  color: ZyraColors.unlockDot,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'QUESTION $position OF $total',
                style: ZyraText.chapterLabel(color: ZyraColors.unlockText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(question.prompt, style: ZyraText.heading(size: 18)),
          const SizedBox(height: 16),
          TrafficLightQuestionScreen(
            key: ValueKey('ch4_grouped_${question.id}'),
            yourAnswer: '',
            yourAnswers: yourAnswers,
            options: question.options,
            hardRequirementSupported: question.hardRequirementSupported,
            initialValues: initialValues,
            initialHardRequirement: initialHardRequirement,
            onChanged: onChanged,
            onHardRequirementChanged: onHardRequirementChanged,
          ),
        ],
      ),
    );
  }
}

class _PreferenceGuideScreen extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _PreferenceGuideScreen({
    required this.onContinue,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(27, 16, 27, 22),
            child: Column(
              children: [
                _BoundaryCue(
                  key: const ValueKey('preference_guide_back'),
                  icon: Icons.keyboard_arrow_up_rounded,
                  label: 'Partner Preferences above',
                  onTap: onBack,
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'COMPATIBILITY · PART 2',
                    style: ZyraText.chapterLabel(color: ZyraColors.unlockText),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose how each answer feels.',
                    style: ZyraText.heading(size: 27),
                  ),
                ),
                const SizedBox(height: 11),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Each question has several possible answers. Choose one response for every answer.',
                    style: ZyraText.body(size: 14),
                  ),
                ),
                const SizedBox(height: 24),
                const _PreferenceMeaningRow(
                  color: Color(0xFF84D0A8),
                  title: 'Prefer this',
                  description:
                      'This is something you would welcome in a partner.',
                ),
                const SizedBox(height: 10),
                const _PreferenceMeaningRow(
                  color: Color(0xFFE8C98A),
                  title: 'No preference',
                  description: 'You neither prefer nor avoid this.',
                ),
                const SizedBox(height: 10),
                const _PreferenceMeaningRow(
                  color: Color(0xFFE18A91),
                  title: 'Not for me',
                  description: 'This would not suit what you are looking for.',
                ),
                const SizedBox(height: 21),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: PrivacyIndicator(
                    level: PrivacyLevel.private,
                    overrideText:
                        'Private. Used to calculate your compatibility score.',
                  ),
                ),
                const Spacer(flex: 2),
                _BoundaryCue(
                  key: const ValueKey('preference_guide_continue'),
                  icon: Icons.keyboard_arrow_down_rounded,
                  label: 'Start with Deen & Islamic Practice',
                  onTap: onContinue,
                  accent: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreferenceMeaningRow extends StatelessWidget {
  final Color color;
  final String title;
  final String description;

  const _PreferenceMeaningRow({
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: ZyraColors.iconButtonBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZyraColors.iconButtonBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ZyraText.option(size: 13.5)),
                const SizedBox(height: 3),
                Text(description, style: ZyraText.subtext(size: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompatibilityBoundaryScreen extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final String count;
  final String countLabel;
  final String continueLabel;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _CompatibilityBoundaryScreen({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.count,
    required this.countLabel,
    required this.continueLabel,
    required this.onContinue,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(27, 16, 27, 22),
            child: Column(
              children: [
                _BoundaryCue(
                  key: const ValueKey('compatibility_boundary_back'),
                  icon: Icons.keyboard_arrow_up_rounded,
                  label: 'Previous page',
                  onTap: onBack,
                ),
                const Spacer(flex: 2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    eyebrow,
                    style: ZyraText.chapterLabel(color: ZyraColors.unlockText),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title, style: ZyraText.heading(size: 29)),
                ),
                const SizedBox(height: 13),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(description, style: ZyraText.body(size: 14.5)),
                ),
                const SizedBox(height: 25),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ZyraColors.unlockDot,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          count,
                          style: ZyraText.heading(
                            size: 15,
                            color: ZyraColors.unlockText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(countLabel, style: ZyraText.subtext(size: 12.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: PrivacyIndicator(
                    level: PrivacyLevel.private,
                    overrideText:
                        'Private. Used to calculate your compatibility score.',
                  ),
                ),
                const Spacer(flex: 3),
                _BoundaryCue(
                  key: const ValueKey('compatibility_boundary_continue'),
                  icon: Icons.keyboard_arrow_down_rounded,
                  label: continueLabel,
                  onTap: onContinue,
                  accent: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BoundaryCue extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  const _BoundaryCue({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ? ZyraColors.unlockText : Colors.white70;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: ZyraText.subtext(size: 11.5, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
