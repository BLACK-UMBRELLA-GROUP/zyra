import '../../widgets/zyra_floating_surface.dart';
import '../../widgets/zyra_tap_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../dev/zyra_app_gold_preview.dart';

import '../../data/chapter3_categories.dart';
import '../../models/onboarding_question.dart';
import '../../models/journey_bio.dart';
import '../../services/zyra_onboarding_answers_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_preview_spacing.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_pull_down_back_scope.dart';
import '../onboarding/generic_select_question_screen.dart';
import '../onboarding/traffic_light_question_screen.dart';

enum CompatibilityEditorKind {
  aboutYou,
  lifestyle,
  marriagePreferences,
  trafficLights,
  hardRequirements,
}

extension CompatibilityEditorKindUi on CompatibilityEditorKind {
  String get label => switch (this) {
    CompatibilityEditorKind.aboutYou => 'About you',
    CompatibilityEditorKind.lifestyle => 'Lifestyle',
    CompatibilityEditorKind.marriagePreferences => 'Marriage preferences',
    CompatibilityEditorKind.trafficLights => 'Partner preferences',
    CompatibilityEditorKind.hardRequirements => 'Hard requirements',
  };

  String get description => switch (this) {
    CompatibilityEditorKind.aboutYou =>
      'Your faith, values, personality and connection style.',
    CompatibilityEditorKind.lifestyle =>
      'Your work, finances, wellbeing, digital life and daily choices.',
    CompatibilityEditorKind.marriagePreferences =>
      'Your intentions, family expectations, home life and communication.',
    CompatibilityEditorKind.trafficLights =>
      'How every possible partner answer feels to you.',
    CompatibilityEditorKind.hardRequirements =>
      'Answers that must prevent an introduction.',
  };

  IconData get icon => switch (this) {
    CompatibilityEditorKind.aboutYou => Icons.person_outline_rounded,
    CompatibilityEditorKind.lifestyle => Icons.wb_sunny_outlined,
    CompatibilityEditorKind.marriagePreferences => Icons.tune_rounded,
    CompatibilityEditorKind.trafficLights => Icons.traffic_outlined,
    CompatibilityEditorKind.hardRequirements => Icons.gpp_maybe_outlined,
  };

  List<String> get categoryIds => switch (this) {
    CompatibilityEditorKind.aboutYou => const [
      'deen_practice',
      'personality_connection',
    ],
    CompatibilityEditorKind.lifestyle => const [
      'finances_provision',
      'education_career',
      'lifestyle_wellbeing',
      'digital_boundaries',
    ],
    CompatibilityEditorKind.marriagePreferences => const [
      'marriage_intentions',
      'children_parenting',
      'family_in_laws',
      'home_roles',
      'communication_conflict',
    ],
    CompatibilityEditorKind.trafficLights ||
    CompatibilityEditorKind.hardRequirements => const [],
  };
}

class ZyraCompatibilityDraft {
  ZyraCompatibilityDraft({
    required this.gender,
    required this.answers,
    required this.preferences,
    required this.hardRequirements,
    Set<ZyraPreferenceOption> canonicalAmberOptions = const {},
  }) : canonicalAmberOptions = Set.of(canonicalAmberOptions);

  factory ZyraCompatibilityDraft.fromSnapshot({
    required String? gender,
    ZyraOnboardingAnswersSnapshot? snapshot,
  }) {
    final answers = <String, dynamic>{};
    final preferences = <String, Map<String, TrafficLight>>{};
    final hard = <String, Set<String>>{};
    final rawAnswers = <String, dynamic>{
      ...?snapshot?.journeyBio.toOnboardingAnswers(),
      ...?snapshot?.ch3Answers,
    };

    for (final entry in rawAnswers.entries) {
      if (entry.key.startsWith('bio_')) {
        answers[entry.key] = _copyAnswerValue(entry.value);
      }
    }
    final counterpart = _counterpartGender(gender);
    final preferenceKeys = <String, String>{};
    for (final category in chapter3Categories) {
      for (final question in category.questions) {
        if (question.visibleFor(gender) &&
            rawAnswers.containsKey(question.id)) {
          answers[question.responseKey] = _copyAnswerValue(
            rawAnswers[question.id],
          );
        }
        if (question.ch4Status != Ch4Status.none &&
            question.visibleFor(counterpart)) {
          preferenceKeys[question.id] = question.responseKey;
        }
      }
    }
    for (final entry
        in (snapshot?.ch4Preferences ??
                const <String, Map<String, TrafficLight>>{})
            .entries) {
      preferences[preferenceKeys[entry.key] ?? entry.key] = Map.of(entry.value);
    }
    for (final entry
        in (snapshot?.ch4HardRequirements ?? const <String, Set<String>>{})
            .entries) {
      hard[preferenceKeys[entry.key] ?? entry.key] = Set.of(entry.value);
    }

    final draft = ZyraCompatibilityDraft(
      gender: gender,
      answers: answers,
      preferences: preferences,
      hardRequirements: hard,
      canonicalAmberOptions: snapshot?.canonicalAmberOptions ?? const {},
    );
    draft.pruneHiddenAnswers();
    return draft;
  }

  final String? gender;
  final Map<String, dynamic> answers;
  final Map<String, Map<String, TrafficLight>> preferences;
  final Map<String, Set<String>> hardRequirements;
  final Set<ZyraPreferenceOption> canonicalAmberOptions;

  ZyraCompatibilityDraft copy() => ZyraCompatibilityDraft(
    gender: gender,
    answers: {
      for (final entry in answers.entries)
        entry.key: _copyAnswerValue(entry.value),
    },
    preferences: {
      for (final entry in preferences.entries)
        entry.key: Map<String, TrafficLight>.from(entry.value),
    },
    hardRequirements: {
      for (final entry in hardRequirements.entries)
        entry.key: Set<String>.from(entry.value),
    },
    canonicalAmberOptions: canonicalAmberOptions,
  );

  /// A detached own-draft checkpoint. Uses the established canonical question
  /// IDs without consulting AppState, a member ledger or a network service.
  ZyraOnboardingAnswersSnapshot toSnapshot() {
    final normalized = <String, dynamic>{
      for (final entry in answers.entries)
        ZyraOnboardingAnswersService.persistedQuestionId(entry.key):
            _copyAnswerValue(entry.value),
    };
    return ZyraOnboardingAnswersSnapshot(
      ch3Answers: normalized,
      ch4Preferences: {
        for (final entry in preferences.entries)
          ZyraOnboardingAnswersService.persistedQuestionId(entry.key):
              Map<String, TrafficLight>.from(entry.value),
      },
      ch4HardRequirements: {
        for (final entry in hardRequirements.entries)
          ZyraOnboardingAnswersService.persistedQuestionId(entry.key):
              Set<String>.from(entry.value),
      },
      journeyBio: JourneyBio.fromOnboardingAnswers(normalized),
      canonicalAmberOptions: Set.of(canonicalAmberOptions),
    );
  }

  Map<String, dynamic> get _answersByQuestionId {
    final result = <String, dynamic>{};
    for (final category in chapter3Categories) {
      for (final question in category.questions) {
        if (answers.containsKey(question.responseKey)) {
          result[question.id] = answers[question.responseKey];
        }
      }
    }
    return result;
  }

  List<OnboardingQuestion> visibleQuestions(OnboardingCategory category) =>
      category.questions
          .where(
            (question) => question.visibleGiven(gender, _answersByQuestionId),
          )
          .toList(growable: false);

  static String? _counterpartGender(String? ownerGender) =>
      switch (ownerGender) {
        'male' => 'female',
        'female' => 'male',
        _ => null,
      };

  List<OnboardingQuestion> preferenceQuestions(OnboardingCategory category) {
    final counterpart = _counterpartGender(gender);
    final answersById = _answersByQuestionId;
    return category.questions
        .where(
          (question) =>
              question.ch4Status != Ch4Status.none &&
              question.visibleGiven(counterpart, answersById),
        )
        .toList(growable: false);
  }

  Iterable<OnboardingQuestion> get preferenceQuestionBank =>
      chapter3Categories.expand(preferenceQuestions);

  Map<String, TrafficLight> valuesFor(OnboardingQuestion question) {
    final saved = preferences[question.responseKey];
    return {
      for (final option in question.options)
        if (saved?[option] case final TrafficLight value) option: value,
    };
  }

  Set<String> hardRequirementsFor(OnboardingQuestion question) =>
      hardRequirements[question.responseKey]?.intersection(
        question.options.toSet(),
      ) ??
      {};

  void savePreferenceQuestion(
    OnboardingQuestion question,
    Map<String, TrafficLight> values,
    Set<String> hard,
  ) {
    final previous = preferences[question.responseKey] ?? const {};
    preferences[question.responseKey] = {
      for (final entry in previous.entries)
        if (!question.options.contains(entry.key)) entry.key: entry.value,
      ...values,
    };
    final previousHard =
        hardRequirements[question.responseKey] ?? const <String>{};
    final nextHard = {
      ...previousHard.difference(question.options.toSet()),
      ...hard,
    };
    if (nextHard.isEmpty) {
      hardRequirements.remove(question.responseKey);
    } else {
      hardRequirements[question.responseKey] = nextHard;
    }
  }

  void applyConfirmedPreference(
    OnboardingQuestion question,
    String option,
    TrafficLight light,
  ) {
    (preferences[question.responseKey] ??= {})[option] = light;
    final key = (questionId: question.id, optionValue: option);
    if (light == TrafficLight.yellow) {
      canonicalAmberOptions.add(key);
    } else {
      canonicalAmberOptions.remove(key);
    }
    if (light != TrafficLight.red) {
      hardRequirements[question.responseKey]?.remove(option);
    }
  }

  void setAnswer(OnboardingQuestion question, dynamic value) {
    answers[question.responseKey] = value;
    pruneHiddenAnswers();
  }

  void pruneHiddenAnswers() {
    final visibleKeys = <String>{
      for (final category in chapter3Categories)
        for (final question in visibleQuestions(category)) question.responseKey,
    };
    answers.removeWhere(
      (key, _) => !key.startsWith('bio_') && !visibleKeys.contains(key),
    );
    // Hidden preference values keep their original keys and are excluded from
    // the visible bank. A plain save must not clear an unmatched legacy light.
  }

  int answeredIn(Iterable<OnboardingCategory> categories) => categories
      .expand(visibleQuestions)
      .where((question) => _hasValue(answers[question.responseKey]))
      .length;

  int questionsIn(Iterable<OnboardingCategory> categories) =>
      categories.expand(visibleQuestions).length;

  int get preferenceAnswerCount => preferenceQuestionBank.fold<int>(
    0,
    (total, question) => total + valuesFor(question).length,
  );

  int get preferenceOptionCount => chapter3Categories
      .expand(preferenceQuestions)
      .fold<int>(0, (total, question) => total + question.options.length);

  int get hardRequirementCount => preferenceQuestionBank.fold<int>(
    0,
    (total, question) => total + hardRequirementsFor(question).length,
  );

  static bool _hasValue(dynamic value) => switch (value) {
    List<dynamic> values => values.isNotEmpty,
    String value => value.trim().isNotEmpty,
    null => false,
    _ => true,
  };
}

class ZyraPreferenceQuickCheck {
  ZyraPreferenceQuickCheck({
    required Set<ZyraPreferenceOption> items,
    required this.confirm,
    this.onConfirmed,
    this.setup,
  }) : _items = Set.of(items);

  final Set<ZyraPreferenceOption> _items;
  final Future<void> Function(ZyraPreferenceOption, TrafficLight) confirm;
  final void Function(OnboardingQuestion, String, TrafficLight)? onConfirmed;
  final ZyraSetupPreferenceLights? setup;

  Iterable<OnboardingQuestion> questionsFor(
    ZyraCompatibilityDraft draft,
  ) sync* {
    for (final category in chapter3Categories) {
      if (category.id == 'deen_practice') yield* setup?.questions ?? const [];
      yield* draft.preferenceQuestions(category);
    }
  }

  List<OnboardingQuestion> setupQuestionsFor(OnboardingCategory category) =>
      category.id == 'deen_practice' ? setup?.questions ?? const [] : const [];

  bool isSetup(OnboardingQuestion question) =>
      setup?.questions.contains(question) ?? false;

  ZyraPreferenceOption _key(OnboardingQuestion question, String option) =>
      isSetup(question)
      ? setup!.key(question, option)
      : (questionId: question.id, optionValue: option);

  Set<String> optionsFor(OnboardingQuestion question) => {
    for (final option in question.options)
      if (_items.contains(_key(question, option))) option,
  };

  int countFor(Iterable<OnboardingQuestion> questions) => questions.fold(
    0,
    (count, question) => count + optionsFor(question).length,
  );

  int countForDraft(ZyraCompatibilityDraft draft) =>
      countFor(questionsFor(draft));

  Future<void> check(
    OnboardingQuestion question,
    String option,
    TrafficLight light,
  ) async {
    final key = _key(question, option);
    final setupQuestion = isSetup(question);
    if (!_items.contains(key)) return;
    await confirm(key, light);
    _items.remove(key);
    if (setupQuestion) {
      setup!.lights[key] = light;
    } else {
      onConfirmed?.call(question, option, light);
    }
  }
}

class ZyraSetupPreferenceLights {
  ZyraSetupPreferenceLights({
    Map<ZyraPreferenceOption, TrafficLight> lights = const {},
    this.otherSect = 'other',
  }) : lights = Map.of(lights);

  final Map<ZyraPreferenceOption, TrafficLight> lights;
  final String otherSect;

  static const _sect = OnboardingQuestion(
    id: 'ch2.sect.matrix',
    prompt: "Your partner's sect",
    options: ['Sunni', 'Shia', 'Other'],
    hardRequirementSupported: false,
  );
  static const _outside = OnboardingQuestion(
    id: 'ch2.sect.outside_flexibility',
    prompt: 'Someone from outside your preferred sect',
    options: ['Outside my preferred sect'],
    hardRequirementSupported: false,
  );
  static const _revert = OnboardingQuestion(
    id: 'ch2.revert.flexibility',
    prompt: 'Someone who reverted to Islam',
    options: ['A partner who reverted to Islam'],
    hardRequirementSupported: false,
  );

  static bool isSetupOption(ZyraPreferenceOption option) =>
      option.questionId == _sect.id ||
      (option.optionValue == '*' &&
          (option.questionId == _outside.id ||
              option.questionId == _revert.id));

  List<OnboardingQuestion> get questions => [_sect, _outside, _revert];

  ZyraPreferenceOption key(OnboardingQuestion question, String label) => (
    questionId: question.id,
    optionValue: question == _sect
        ? (label == 'Other' ? otherSect : label.toLowerCase())
        : '*',
  );

  Map<String, TrafficLight> valuesFor(OnboardingQuestion question) => {
    for (final label in question.options)
      if (lights[key(question, label)] case final TrafficLight light)
        label: light,
  };
}

dynamic _copyAnswerValue(dynamic value) => switch (value) {
  List<String> values => List<String>.from(values),
  Map<String, String> values => Map<String, String>.from(values),
  Set<String> values => Set<String>.from(values),
  List values => [for (final item in values) _copyAnswerValue(item)],
  Map values => {
    for (final entry in values.entries)
      entry.key: _copyAnswerValue(entry.value),
  },
  Set values => {for (final item in values) _copyAnswerValue(item)},
  _ => value,
};

class _CompatibilityPreviewOwner extends ChangeNotifier {
  _CompatibilityPreviewOwner(
    this.guard,
    this.gender,
    this.canEdit, {
    required this.preview,
  });
  final bool Function() guard;
  final String? gender;
  final bool Function() canEdit;
  final bool preview;
  bool revoked = false;
  bool _disposed = false;
  bool _notificationPending = false;

  void revoke() {
    if (revoked || _disposed) return;
    revoked = true;
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      notifyListeners();
      return;
    }
    if (_notificationPending) return;
    _notificationPending = true;
    binding.addPostFrameCallback((_) {
      _notificationPending = false;
      if (!_disposed) notifyListeners();
    });
    binding.ensureVisualUpdate();
  }

  bool get alive {
    if (revoked || _disposed) return false;
    try {
      if (guard()) return true;
    } catch (_) {
      // A failed caller-owner check is permanent denial, not live fallback.
    }
    revoke();
    return false;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

bool _editorCurrent(
  BuildContext context,
  _CompatibilityPreviewOwner? owner, {
  bool editing = true,
}) {
  if (!context.mounted) return false;
  final routeCurrent = ModalRoute.of(context)?.isCurrent;
  return (owner == null ? routeCurrent ?? true : routeCurrent == true) &&
      (owner == null || (owner.alive && (!editing || owner.canEdit())));
}

List<OnboardingCategory> categoriesForKind(CompatibilityEditorKind kind) {
  final ids = kind.categoryIds;
  if (ids.isEmpty) return chapter3Categories;
  return [
    for (final id in ids)
      chapter3Categories.firstWhere((category) => category.id == id),
  ];
}

class CompatibilityEditorScreen extends StatefulWidget {
  const CompatibilityEditorScreen({
    super.key,
    required this.kind,
    required this.initialDraft,
    required this.onPersist,
    this.canAct,
    this.canActChanges,
    this.quickCheck,
    this.openQuickCheck = false,
  }) : _preview = false,
       onPreviewReturn = null;

  const CompatibilityEditorScreen.preview({
    super.key,
    required this.kind,
    required this.initialDraft,
    required this.onPersist,
    required bool Function() canAct,
    this.canActChanges,
    this.onPreviewReturn,
    this.quickCheck,
    this.openQuickCheck = false,
  }) : _preview = true,
       // Keep preview's guard non-nullable while ordinary callers may omit it.
       // ignore: prefer_initializing_formals
       canAct = canAct;

  final CompatibilityEditorKind kind;
  final ZyraCompatibilityDraft initialDraft;
  final Future<bool> Function(ZyraCompatibilityDraft draft) onPersist;
  final bool _preview;
  final ZyraPreferenceQuickCheck? quickCheck;
  final bool openQuickCheck;

  /// Local standalone preview owners return through their own page stack.
  /// Existing hub-pushed editors keep Navigator.pop as their default.
  final ValueChanged<ZyraCompatibilityDraft?>? onPreviewReturn;

  /// Optional deny-only ordinary ownership; no account or save authority is
  /// conferred by the guard. Unbound callers retain their existing behavior.
  final bool Function()? canAct;
  final Listenable? canActChanges;

  @override
  State<CompatibilityEditorScreen> createState() =>
      _CompatibilityEditorScreenState();
}

class _CompatibilityEditorScreenState extends State<CompatibilityEditorScreen> {
  late final CompatibilityEditorScreen _opening;
  late final ZyraCompatibilityDraft _draft;
  late final bool _previewMode;
  late final _CompatibilityPreviewOwner? _owner;
  bool _bindingRevoked = false;
  bool _saving = false;
  int _saveEpoch = 0;
  bool get _current =>
      mounted &&
      !_bindingRevoked &&
      _editorCurrent(context, _owner, editing: false);

  bool get _openingBindingsCurrent =>
      widget._preview == _previewMode &&
      widget.kind == _opening.kind &&
      identical(widget.initialDraft, _opening.initialDraft) &&
      widget.onPersist == _opening.onPersist &&
      widget.onPreviewReturn == _opening.onPreviewReturn &&
      identical(widget.quickCheck, _opening.quickCheck) &&
      widget.openQuickCheck == _opening.openQuickCheck &&
      widget.canAct == _opening.canAct &&
      identical(widget.canActChanges, _opening.canActChanges);

  bool _openingAdmission() =>
      mounted &&
      !_bindingRevoked &&
      _openingBindingsCurrent &&
      _opening.canAct?.call() == true &&
      widget.canAct?.call() == true;

  @override
  void initState() {
    super.initState();
    _opening = widget;
    _draft = widget.initialDraft.copy();
    _previewMode = widget._preview;
    _owner = widget.canAct == null
        ? null
        : _CompatibilityPreviewOwner(
            _openingAdmission,
            _draft.gender,
            () => mounted && !_saving,
            preview: _previewMode,
          );
    _opening.canActChanges?.addListener(_ownerChanged);
    _ownerChanged();
  }

  void _withdrawDraft() {
    ++_saveEpoch;
    _saving = false;
    _draft.answers.clear();
    _draft.preferences.clear();
    _draft.hardRequirements.clear();
    _draft.canonicalAmberOptions.clear();
  }

  void _ownerChanged() {
    if (!mounted || _owner == null || _owner.alive) return;
    _withdrawDraft();
  }

  @override
  void didUpdateWidget(covariant CompatibilityEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._preview != _previewMode ||
        (_owner == null && widget.canAct != null) ||
        (_owner != null && !_openingBindingsCurrent)) {
      _bindingRevoked = true;
      _owner?.revoke();
      _withdrawDraft();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_owner != null &&
        _saving &&
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      ++_saveEpoch;
      if (_previewMode) _saving = false;
    }
  }

  @override
  void dispose() {
    ++_saveEpoch;
    _bindingRevoked = true;
    _opening.canActChanges?.removeListener(_ownerChanged);
    _owner?.revoke();
    _owner?.dispose();
    super.dispose();
  }

  void _back() {
    if (!_current || _saving) return;
    if (_previewMode && _opening.onPreviewReturn != null) {
      _opening.onPreviewReturn!(null);
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    if (_saving || !_current) return;
    final epoch = ++_saveEpoch;
    final route = ModalRoute.of(context);
    final candidate = _draft.copy();
    setState(() => _saving = true);
    bool saved;
    try {
      final persist = _owner == null ? widget.onPersist : _opening.onPersist;
      saved = await persist(candidate).timeout(const Duration(seconds: 10));
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    if (epoch != _saveEpoch) {
      // A cover invalidates navigation, not a write already dispatched. The
      // guarded ordinary editor keeps one flight until its acknowledgement
      // settles, then becomes usable without popping an unrelated route.
      if (!_previewMode && _owner?.alive == true && _saving) {
        setState(() => _saving = false);
      }
      return;
    }
    setState(() => _saving = false);
    if (!_current || !identical(route, ModalRoute.of(context))) return;
    if (saved) {
      if (_previewMode && _opening.onPreviewReturn != null) {
        _opening.onPreviewReturn!(candidate);
      } else {
        Navigator.of(context).pop(candidate);
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your changes could not be saved. Please try again.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _owner == null
      ? _buildEditor(context)
      : AnimatedBuilder(
          animation: _owner,
          builder: (context, _) => _buildEditor(context),
        );

  Widget _buildEditor(BuildContext context) {
    if (_bindingRevoked || (_owner != null && !_owner.alive)) {
      return SizedBox.shrink(
        key: ValueKey(
          _previewMode
              ? 'compatibility_editor_preview_denied'
              : 'compatibility_editor_owner_unavailable',
        ),
      );
    }
    final kind = _owner == null ? widget.kind : _opening.kind;
    final content = Column(
      children: [
        if (_previewMode)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(kind.label, style: ZyraText.heading(size: 28)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              kind.description,
              style: ZyraText.subtext(size: 12.5, color: ZyraColors.ink(0.56)),
            ),
          ),
        ),
        Expanded(
          child: IgnorePointer(
            ignoring: _saving,
            child: switch (kind) {
              CompatibilityEditorKind.aboutYou ||
              CompatibilityEditorKind.lifestyle ||
              CompatibilityEditorKind.marriagePreferences => _AnswerGroups(
                kind: kind,
                draft: _draft,
                owner: _owner,
                onChanged: () {
                  if (mounted && _editorCurrent(context, _owner)) {
                    setState(() {});
                  }
                },
              ),
              CompatibilityEditorKind.trafficLights => _PreferenceGroups(
                draft: _draft,
                owner: _owner,
                quickCheck: _opening.quickCheck,
                openQuickCheck: _opening.openQuickCheck,
                plannedSpacing: _previewMode,
                onChanged: () {
                  if (mounted && _editorCurrent(context, _owner)) {
                    setState(() {});
                  }
                },
              ),
              CompatibilityEditorKind.hardRequirements =>
                _HardRequirementsEditor(
                  draft: _draft,
                  owner: _owner,
                  onChanged: () {
                    if (mounted && _editorCurrent(context, _owner)) {
                      setState(() {});
                    }
                  },
                ),
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: SizedBox(
            width: double.infinity,
            child: ZyraFloatingSurface(
              radius: 999,
              child: FilledButton(
                key: const ValueKey('compatibility-save'),
                onPressed: ZyraTapFeedback.onTap(
                  context,
                  _saving ? null : _save,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : const Text('Save changes'),
              ),
            ),
          ),
        ),
      ],
    );
    final page = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _previewMode
          ? null
          : AppBar(
              automaticallyImplyLeading: _owner == null,
              leading: _owner != null && Navigator.of(context).canPop()
                  ? BackButton(onPressed: ZyraTapFeedback.onTap(context, _back))
                  : null,
              title: Text(kind.label, style: ZyraText.heading(size: 17)),
              iconTheme: IconThemeData(color: ZyraColors.ink(0.70)),
            ),
      body: Container(
        decoration: _previewMode
            ? BoxDecoration(gradient: ZyraColors.genderGradient(_draft.gender))
            : ZyraAppGoldDecoration(
                gradient: ZyraColors.genderGradient(AppState.instance.gender),
              ),
        child: SafeArea(top: _previewMode, child: content),
      ),
    );
    return _previewMode
        ? ZyraPullDownBackScope(
            onBack: _back,
            routeIdentity: this,
            enabled: !_saving && _owner!.alive,
            child: page,
          )
        : page;
  }
}

class _AnswerGroups extends StatelessWidget {
  const _AnswerGroups({
    required this.kind,
    required this.draft,
    required this.onChanged,
    this.owner,
  });

  final CompatibilityEditorKind kind;
  final ZyraCompatibilityDraft draft;
  final VoidCallback onChanged;
  final _CompatibilityPreviewOwner? owner;

  @override
  Widget build(BuildContext context) {
    final categories = categoriesForKind(kind);
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        for (final category in categories)
          _CategoryDoor(
            key: ValueKey('edit-category-${category.id}'),
            label: category.name,
            status:
                '${draft.answeredIn([category])} of '
                '${draft.questionsIn([category])} answered',
            onTap: () async {
              if (!_editorCurrent(context, owner)) return;
              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => _AnswerCategoryEditor(
                    category: category,
                    draft: draft,
                    owner: owner,
                  ),
                ),
              );
              if (context.mounted && _editorCurrent(context, owner)) {
                onChanged();
              }
            },
          ),
      ],
    );
  }
}

class _AnswerCategoryEditor extends StatefulWidget {
  const _AnswerCategoryEditor({
    required this.category,
    required this.draft,
    this.owner,
  });

  final OnboardingCategory category;
  final ZyraCompatibilityDraft draft;
  final _CompatibilityPreviewOwner? owner;

  @override
  State<_AnswerCategoryEditor> createState() => _AnswerCategoryEditorState();
}

class _AnswerCategoryEditorState extends State<_AnswerCategoryEditor> {
  @override
  Widget build(BuildContext context) {
    final questions = widget.draft.visibleQuestions(widget.category);
    return _EditorScaffold(
      title: widget.category.name,
      owner: widget.owner,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          return _QuestionDoor(
            key: ValueKey('edit-answer-${question.responseKey}'),
            question: question.prompt,
            value: _answerLabel(widget.draft.answers[question.responseKey]),
            onTap: () async {
              if (!_editorCurrent(context, widget.owner)) return;
              final value = await Navigator.of(context).push<dynamic>(
                MaterialPageRoute(
                  builder: (_) => _AnswerQuestionEditor(
                    question: question,
                    initialValue: widget.draft.answers[question.responseKey],
                    owner: widget.owner,
                  ),
                ),
              );
              if (value == null ||
                  !mounted ||
                  !context.mounted ||
                  !_editorCurrent(context, widget.owner)) {
                return;
              }
              setState(() => widget.draft.setAnswer(question, value));
            },
          );
        },
      ),
    );
  }
}

class _AnswerQuestionEditor extends StatefulWidget {
  const _AnswerQuestionEditor({
    required this.question,
    required this.initialValue,
    this.owner,
  });

  final OnboardingQuestion question;
  final dynamic initialValue;
  final _CompatibilityPreviewOwner? owner;

  @override
  State<_AnswerQuestionEditor> createState() => _AnswerQuestionEditorState();
}

class _AnswerQuestionEditorState extends State<_AnswerQuestionEditor> {
  late dynamic _value = _copyAnswerValue(widget.initialValue);

  bool get _complete => ZyraCompatibilityDraft._hasValue(_value);

  @override
  Widget build(BuildContext context) => _EditorScaffold(
    title: 'Edit answer',
    owner: widget.owner,
    bottom: _BottomSave(
      enabled: _complete,
      onPressed: () {
        if (_editorCurrent(context, widget.owner)) {
          Navigator.of(context).pop(_value);
        }
      },
    ),
    child: ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        Text(widget.question.prompt, style: ZyraText.heading(size: 21)),
        const SizedBox(height: 20),
        GenericSelectQuestionScreen(
          key: ValueKey('answer-options-${widget.question.responseKey}'),
          prompt: widget.question.prompt,
          options: widget.question.options,
          selectionType: widget.question.selectionType,
          initialValue: _copyAnswerValue(widget.initialValue),
          onChanged: (value) {
            if (mounted && _editorCurrent(context, widget.owner)) {
              setState(() => _value = _copyAnswerValue(value));
            }
          },
        ),
      ],
    ),
  );
}

class _PreferenceGroups extends StatefulWidget {
  const _PreferenceGroups({
    required this.draft,
    required this.onChanged,
    required this.plannedSpacing,
    required this.quickCheck,
    required this.openQuickCheck,
    this.owner,
  });

  final ZyraCompatibilityDraft draft;
  final VoidCallback onChanged;
  final bool plannedSpacing;
  final ZyraPreferenceQuickCheck? quickCheck;
  final bool openQuickCheck;
  final _CompatibilityPreviewOwner? owner;

  @override
  State<_PreferenceGroups> createState() => _PreferenceGroupsState();
}

class _PreferenceGroupsState extends State<_PreferenceGroups> {
  @override
  void initState() {
    super.initState();
    if (widget.openQuickCheck) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkNow());
    }
  }

  Future<void> _checkNow() async {
    if (!mounted || !_editorCurrent(context, widget.owner)) return;
    final quickCheck = widget.quickCheck;
    if (quickCheck == null) return;
    for (final question in quickCheck.questionsFor(widget.draft)) {
      if (quickCheck.optionsFor(question).isEmpty) continue;
      await _openPreferenceQuestion(
        context,
        widget.draft,
        question,
        widget.owner,
        quickCheck,
      );
      if (mounted && _editorCurrent(context, widget.owner)) widget.onChanged();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final quickCheck = widget.quickCheck;
    final count = quickCheck?.countForDraft(draft) ?? 0;
    final categories = chapter3Categories
        .where((category) => draft.preferenceQuestions(category).isNotEmpty)
        .toList();
    final gap = widget.plannedSpacing ? ZyraPreviewSpacing.cardToCard : 14.0;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        if (count > 0) ...[
          _QuickCheckCard(count: count, onCheck: _checkNow),
          const SizedBox(height: 14),
        ],
        _MeaningCard(),
        if (!widget.plannedSpacing || categories.isNotEmpty)
          SizedBox(height: gap),
        for (final (index, category) in categories.indexed)
          _CategoryDoor(
            key: ValueKey('edit-preferences-${category.id}'),
            bottomGap: widget.plannedSpacing && index < categories.length - 1
                ? ZyraPreviewSpacing.cardToCard
                : 11,
            label: category.name,
            status: _preferenceCategoryStatus(draft, category),
            toCheck:
                quickCheck?.countFor([
                  ...quickCheck.setupQuestionsFor(category),
                  ...draft.preferenceQuestions(category),
                ]) ??
                0,
            onTap: () async {
              if (!_editorCurrent(context, widget.owner)) return;
              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => _PreferenceCategoryEditor(
                    category: category,
                    draft: draft,
                    owner: widget.owner,
                    quickCheck: quickCheck,
                  ),
                ),
              );
              if (context.mounted && _editorCurrent(context, widget.owner)) {
                widget.onChanged();
              }
            },
          ),
      ],
    );
  }
}

class _PreferenceCategoryEditor extends StatefulWidget {
  const _PreferenceCategoryEditor({
    required this.category,
    required this.draft,
    this.owner,
    this.quickCheck,
  });

  final OnboardingCategory category;
  final ZyraCompatibilityDraft draft;
  final _CompatibilityPreviewOwner? owner;
  final ZyraPreferenceQuickCheck? quickCheck;

  @override
  State<_PreferenceCategoryEditor> createState() =>
      _PreferenceCategoryEditorState();
}

class _PreferenceCategoryEditorState extends State<_PreferenceCategoryEditor> {
  @override
  Widget build(BuildContext context) {
    final setupQuestions =
        widget.quickCheck?.setupQuestionsFor(widget.category) ??
        const <OnboardingQuestion>[];
    final questions = [
      ...setupQuestions,
      ...widget.draft.preferenceQuestions(widget.category),
    ];
    return _EditorScaffold(
      title: widget.category.name,
      owner: widget.owner,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          final isSetup = index < setupQuestions.length;
          final values = isSetup
              ? widget.quickCheck!.setup!.valuesFor(question)
              : widget.draft.valuesFor(question);
          final toCheck = widget.quickCheck?.optionsFor(question).length ?? 0;
          final door = _QuestionDoor(
            key: ValueKey('edit-lights-${question.responseKey}'),
            question: question.prompt,
            value: toCheck > 0
                ? '$toCheck to check'
                : values.isEmpty
                ? 'Not set'
                : '${values.length} of ${question.options.length} set',
            needsCheck: toCheck > 0,
            onTap: () async {
              await _openPreferenceQuestion(
                context,
                widget.draft,
                question,
                widget.owner,
                widget.quickCheck,
              );
              if (mounted &&
                  context.mounted &&
                  _editorCurrent(context, widget.owner)) {
                setState(() {});
              }
            },
          );
          if (setupQuestions.isEmpty ||
              (index != 0 && index != setupQuestions.length)) {
            return door;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(2, isSetup ? 2 : 14, 2, 8),
                child: Text(
                  isSetup ? 'FROM YOUR PROFILE SET-UP' : 'PARTNER PREFERENCES',
                  style: ZyraText.subtext(
                    size: 11,
                    color: isSetup ? _quickCheckInk : null,
                  ).copyWith(letterSpacing: 1.2),
                ),
              ),
              door,
            ],
          );
        },
      ),
    );
  }
}

Future<void> _openPreferenceQuestion(
  BuildContext context,
  ZyraCompatibilityDraft draft,
  OnboardingQuestion question,
  _CompatibilityPreviewOwner? owner,
  ZyraPreferenceQuickCheck? quickCheck,
) async {
  if (!_editorCurrent(context, owner)) return;
  final result = await Navigator.of(context).push<_PreferenceEditResult>(
    MaterialPageRoute(
      builder: (_) => _PreferenceQuestionEditor(
        question: question,
        draft: draft,
        owner: owner,
        quickCheck: quickCheck,
      ),
    ),
  );
  if (result == null ||
      !context.mounted ||
      !_editorCurrent(context, owner) ||
      quickCheck?.isSetup(question) == true) {
    return;
  }
  draft.savePreferenceQuestion(question, result.values, result.hard);
}

class _PreferenceEditResult {
  const _PreferenceEditResult(this.values, this.hard);

  final Map<String, TrafficLight> values;
  final Set<String> hard;
}

class _PreferenceQuestionEditor extends StatefulWidget {
  const _PreferenceQuestionEditor({
    required this.question,
    required this.draft,
    this.owner,
    this.quickCheck,
  });

  final OnboardingQuestion question;
  final ZyraCompatibilityDraft draft;
  final _CompatibilityPreviewOwner? owner;
  final ZyraPreferenceQuickCheck? quickCheck;

  @override
  State<_PreferenceQuestionEditor> createState() =>
      _PreferenceQuestionEditorState();
}

class _PreferenceQuestionEditorState extends State<_PreferenceQuestionEditor> {
  bool get _setup => widget.quickCheck?.isSetup(widget.question) == true;
  late Map<String, TrafficLight> _values = Map.of(
    _setup
        ? widget.quickCheck!.setup!.valuesFor(widget.question)
        : widget.draft.valuesFor(widget.question),
  );
  late Set<String> _hard = Set.of(
    widget.draft.hardRequirementsFor(widget.question),
  );
  bool _confirming = false;

  bool get _complete =>
      (widget.quickCheck?.optionsFor(widget.question).isEmpty ?? true) &&
      widget.question.options.every(_values.containsKey);

  Future<bool> _reconfirm(String option, TrafficLight light) async {
    final quickCheck = widget.quickCheck;
    if (quickCheck == null ||
        _confirming ||
        !_editorCurrent(context, widget.owner)) {
      return false;
    }
    setState(() => _confirming = true);
    final wasFlagged = quickCheck.optionsFor(widget.question).contains(option);
    try {
      await quickCheck.check(widget.question, option, light);
      if (widget.owner?.alive == false) return false;
      if (!_setup) {
        widget.draft.applyConfirmedPreference(widget.question, option, light);
      }
      if (!mounted || !_editorCurrent(context, widget.owner)) return false;
      if (wasFlagged && quickCheck.optionsFor(widget.question).isEmpty) {
        final left = quickCheck.countForDraft(widget.draft);
        _message(
          left == 0 ? 'All checked. Thank you.' : 'Saved. $left left to check.',
          confirmed: true,
        );
      }
      return true;
    } catch (_) {
      if (mounted && _editorCurrent(context, widget.owner)) {
        _message('Your changes could not be saved. Please try again.');
      }
      return false;
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  void _message(String text, {bool confirmed = false}) {
    final message = confirmed
        ? SnackBar(
            content: Text(
              text,
              textAlign: TextAlign.center,
              style: ZyraText.subtext(
                size: 12.5,
                color: const Color(0xFFFFFFFE),
              ),
            ),
            duration: const Duration(milliseconds: 1700),
            backgroundColor: const Color(0xF02B2420),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              100 - MediaQuery.viewPaddingOf(context).bottom,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          )
        : SnackBar(content: Text(text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(message);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_confirming,
    child: _EditorScaffold(
      title: 'Partner preference',
      owner: widget.owner,
      allowBack: !_confirming,
      bottom: _BottomSave(
        enabled: _complete && !_confirming,
        onPressed: () {
          if (!_confirming && _editorCurrent(context, widget.owner)) {
            Navigator.of(
              context,
            ).pop(_PreferenceEditResult(Map.from(_values), Set.from(_hard)));
          }
        },
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Text(widget.question.prompt, style: ZyraText.heading(size: 21)),
          const SizedBox(height: 20),
          TrafficLightQuestionScreen(
            key: ValueKey('edit-preference-${widget.question.responseKey}'),
            yourAnswer: '',
            yourAnswers: _asStringSet(
              widget.draft.answers[widget.question.responseKey],
            ),
            options: widget.question.options,
            hardRequirementSupported: widget.question.hardRequirementSupported,
            initialValues: _values,
            initialHardRequirement: _hard,
            optionsToCheck:
                widget.quickCheck?.optionsFor(widget.question) ?? const {},
            onlyCheckOptions: _setup,
            confirming: _confirming,
            onReconfirm: _reconfirm,
            onChanged: (values) {
              if (mounted && _editorCurrent(context, widget.owner)) {
                setState(() => _values = Map.from(values));
              }
            },
            onHardRequirementChanged: (values) {
              if (mounted && _editorCurrent(context, widget.owner)) {
                setState(() => _hard = Set.from(values));
              }
            },
          ),
        ],
      ),
    ),
  );
}

class _HardRequirementsEditor extends StatelessWidget {
  const _HardRequirementsEditor({
    required this.draft,
    required this.onChanged,
    this.owner,
  });

  final ZyraCompatibilityDraft draft;
  final VoidCallback onChanged;
  final _CompatibilityPreviewOwner? owner;

  @override
  Widget build(BuildContext context) {
    final eligible = <(OnboardingCategory, OnboardingQuestion, List<String>)>[];
    for (final category in chapter3Categories) {
      for (final question in draft.preferenceQuestions(category)) {
        if (!question.hardRequirementSupported) continue;
        final reds = question.options
            .where(
              (option) =>
                  draft.preferences[question.responseKey]?[option] ==
                  TrafficLight.red,
            )
            .toList(growable: false);
        if (reds.isNotEmpty) eligible.add((category, question, reds));
      }
    }

    if (eligible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.gpp_good_outlined,
                size: 30,
                color: ZyraColors.ink(0.42),
              ),
              const SizedBox(height: 14),
              Text('No hard requirements', style: ZyraText.heading(size: 18)),
              const SizedBox(height: 8),
              Text(
                'First mark an answer Not for me in Partner preferences. You can then decide here whether it must block an introduction.',
                textAlign: TextAlign.center,
                style: ZyraText.subtext(size: 12.5),
              ),
            ],
          ),
        ),
      );
    }

    final children = <Widget>[];
    String? previousCategory;
    for (final item in eligible) {
      if (previousCategory != item.$1.id) {
        if (previousCategory != null) children.add(const SizedBox(height: 18));
        children
          ..add(
            Text(
              item.$1.name.toUpperCase(),
              style: ZyraText.chapterLabel(color: ZyraColors.ink(0.54)),
            ),
          )
          ..add(const SizedBox(height: 10));
        previousCategory = item.$1.id;
      }
      final question = item.$2;
      final selected =
          draft.hardRequirements[question.responseKey] ?? const <String>{};
      children
        ..add(
          _HardQuestionCard(
            question: question,
            redOptions: item.$3,
            selected: selected,
            onToggle: (option) {
              if (!_editorCurrent(context, owner)) return;
              final next = Set<String>.from(selected);
              if (!next.remove(option)) next.add(option);
              if (next.isEmpty) {
                draft.hardRequirements.remove(question.responseKey);
              } else {
                draft.hardRequirements[question.responseKey] = next;
              }
              onChanged();
            },
          ),
        )
        ..add(const SizedBox(height: 12));
    }
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: children,
    );
  }
}

class _HardQuestionCard extends StatelessWidget {
  const _HardQuestionCard({
    required this.question,
    required this.redOptions,
    required this.selected,
    required this.onToggle,
  });

  final OnboardingQuestion question;
  final List<String> redOptions;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    radius: 16,
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZyraColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.prompt, style: ZyraText.body(size: 13.5)),
          const SizedBox(height: 12),
          for (final option in redOptions)
            InkWell(
              key: ValueKey('hard-option-${question.responseKey}-$option'),
              onTap: ZyraTapFeedback.onTap(context, () => onToggle(option)),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      selected.contains(option)
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 19,
                      color: selected.contains(option)
                          ? ZyraColors.negativeRed
                          : ZyraColors.ink(0.50),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(option, style: ZyraText.subtext(size: 12.5)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

const _quickCheckInk = Color(0xFF845F24);

class _QuickCheckCard extends StatelessWidget {
  const _QuickCheckCard({required this.count, required this.onCheck});

  final int count;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFBF7F0),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFA9792E).withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF3E2E1E).withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'QUICK CHECK',
          style: ZyraText.subtext(
            size: 11,
            color: _quickCheckInk,
          ).copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: 6),
        Text(
          '$count ${count == 1 ? 'answer' : 'answers'} to check',
          style: ZyraText.heading(size: 17),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'The amber light now means '),
              TextSpan(
                text: '“Open to this”',
                style: ZyraText.subtext(
                  size: 12.5,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
              const TextSpan(
                text:
                    '. Tap a light again on each one, even if it stays amber, so it counts.',
              ),
            ],
          ),
          style: ZyraText.subtext(size: 12.5),
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const ValueKey('partner-preferences-check-now'),
          onPressed: ZyraTapFeedback.onTap(context, onCheck),
          style: FilledButton.styleFrom(
            fixedSize: const Size.fromHeight(44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: ZyraColors.goldTextFill,
            foregroundColor: ZyraColors.espresso,
          ),
          child: const Text('Check now'),
        ),
      ],
    ),
  );
}

class _MeaningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    radius: 16,
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZyraColors.surfaceBorder),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _LightMeaning(
              color: ZyraColors.positiveGreen,
              label: 'Prefer',
            ),
          ),
          Expanded(
            child: _LightMeaning(
              color: ZyraColors.journeyGold,
              label: 'Open to this',
            ),
          ),
          Expanded(
            child: _LightMeaning(
              color: ZyraColors.negativeRed,
              label: 'Not for me',
            ),
          ),
        ],
      ),
    ),
  );
}

class _LightMeaning extends StatelessWidget {
  const _LightMeaning({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(height: 6),
      Text(label, style: ZyraText.subtext(size: 10.5)),
    ],
  );
}

class _CategoryDoor extends StatelessWidget {
  const _CategoryDoor({
    super.key,
    required this.label,
    required this.status,
    required this.onTap,
    this.bottomGap = 11,
    this.toCheck = 0,
  });

  final String label;
  final String status;
  final VoidCallback onTap;
  final double bottomGap;
  final int toCheck;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: bottomGap),
    child: ZyraFloatingSurface(
      radius: 16,
      child: Material(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ZyraColors.surfaceBorder),
          ),
          child: InkWell(
            onTap: ZyraTapFeedback.onTap(context, onTap),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: ZyraText.body(size: 14)),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              if (toCheck > 0)
                                TextSpan(
                                  text: '$toCheck to check',
                                  style: ZyraText.subtext(
                                    size: 11.5,
                                    color: _quickCheckInk,
                                  ),
                                ),
                              TextSpan(
                                text: toCheck > 0
                                    ? ' · ${status.replaceFirst(' preferences set', ' set')}'
                                    : status,
                              ),
                            ],
                          ),
                          style: ZyraText.subtext(size: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 19,
                    color: ZyraColors.ink(0.48),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _QuestionDoor extends StatelessWidget {
  const _QuestionDoor({
    super.key,
    required this.question,
    required this.value,
    required this.onTap,
    this.needsCheck = false,
  });

  final String question;
  final String value;
  final VoidCallback onTap;
  final bool needsCheck;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: ZyraFloatingSurface(
      radius: 16,
      child: Material(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: ZyraColors.surfaceBorder),
          ),
          child: InkWell(
            onTap: ZyraTapFeedback.onTap(context, onTap),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(question, style: ZyraText.body(size: 13.5)),
                        const SizedBox(height: 6),
                        Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ZyraText.subtext(
                            size: 11.5,
                            color: needsCheck
                                ? _quickCheckInk
                                : value == 'Not answered'
                                ? ZyraColors.negativeRed
                                : ZyraColors.ink(0.58),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: ZyraColors.ink(0.44),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _EditorScaffold extends StatelessWidget {
  const _EditorScaffold({
    required this.title,
    required this.child,
    this.bottom,
    this.owner,
    this.allowBack = true,
  });

  final String title;
  final Widget child;
  final Widget? bottom;
  final _CompatibilityPreviewOwner? owner;
  final bool allowBack;

  @override
  Widget build(BuildContext context) => owner == null
      ? _buildScaffold(context)
      : AnimatedBuilder(
          animation: owner!,
          builder: (context, _) => _buildScaffold(context),
        );

  Widget _buildScaffold(BuildContext context) {
    if (owner != null && !owner!.alive) {
      return SizedBox.shrink(
        key: ValueKey(
          owner!.preview
              ? 'compatibility_editor_preview_denied'
              : 'compatibility_editor_owner_unavailable',
        ),
      );
    }
    final preview = owner?.preview ?? false;
    final content = Stack(
      // The fixed footer keeps its box while its gold glow fades through
      // the bottom SafeArea instead of stopping at that painting boundary.
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: child),
        if (bottom != null)
          Positioned(left: 0, right: 0, bottom: 0, child: bottom!),
      ],
    );
    final page = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: preview
          ? null
          : AppBar(
              automaticallyImplyLeading: owner == null && allowBack,
              leading: owner != null && Navigator.of(context).canPop()
                  ? BackButton(
                      onPressed: ZyraTapFeedback.onTap(
                        context,
                        allowBack
                            ? () {
                                if (_editorCurrent(context, owner) &&
                                    Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              }
                            : null,
                      ),
                    )
                  : null,
              title: Text(title, style: ZyraText.heading(size: 17)),
              iconTheme: IconThemeData(color: ZyraColors.ink(0.70)),
            ),
      body: Container(
        decoration: preview
            ? BoxDecoration(gradient: ZyraColors.genderGradient(owner!.gender))
            : ZyraAppGoldDecoration(
                gradient: ZyraColors.genderGradient(AppState.instance.gender),
              ),
        child: SafeArea(
          top: preview,
          child: preview
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Text(title, style: ZyraText.heading(size: 28)),
                    ),
                    Expanded(child: content),
                  ],
                )
              : content,
        ),
      ),
    );
    if (!preview) return page;
    return ZyraPullDownBackScope(
      routeIdentity: (ModalRoute.of(context), owner),
      onBack: () {
        if (allowBack &&
            _editorCurrent(context, owner) &&
            Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      enabled: allowBack && owner!.alive,
      child: page,
    );
  }
}

class _BottomSave extends StatelessWidget {
  const _BottomSave({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CustomPaint(
    // Continue the existing fade beneath the SafeArea. Painting clearance
    // does not change the footer box, hit area or scroll padding.
    painter: const _FooterFadePainter(),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      child: SizedBox(
        width: double.infinity,
        child: ZyraFloatingSurface(
          radius: 999,
          gold: true,
          child: FilledButton(
            key: const ValueKey('question-save'),
            style: FilledButton.styleFrom(
              backgroundColor: ZyraColors.goldTextFill,
              foregroundColor: ZyraColors.espresso,
            ),
            onPressed: ZyraTapFeedback.onTap(
              context,
              enabled ? onPressed : null,
            ),
            child: const Text('Use this answer'),
          ),
        ),
      ),
    ),
  );
}

class _FooterFadePainter extends CustomPainter {
  const _FooterFadePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        ZyraColors.ivoryBottom.withValues(alpha: 0),
        ZyraColors.ivoryBottom.withValues(alpha: 0.94),
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, size.height + 64),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_FooterFadePainter oldDelegate) => false;
}

String _answerLabel(dynamic value) {
  if (value is List) return value.isEmpty ? 'Not answered' : value.join(', ');
  if (value == null || value.toString().trim().isEmpty) return 'Not answered';
  return value.toString();
}

Set<String> _asStringSet(dynamic value) {
  if (value is List) return value.map((item) => item.toString()).toSet();
  if (value == null) return const {};
  return {value.toString()};
}

String _preferenceCategoryStatus(
  ZyraCompatibilityDraft draft,
  OnboardingCategory category,
) {
  final questions = draft.preferenceQuestions(category);
  final total = questions.fold<int>(
    0,
    (count, question) => count + question.options.length,
  );
  final answered = questions.fold<int>(
    0,
    (count, question) => count + draft.valuesFor(question).length,
  );
  return '$answered of $total preferences set';
}
