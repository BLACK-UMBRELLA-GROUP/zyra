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
    CompatibilityEditorKind.trafficLights => 'Green / Yellow / Red',
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
  });

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
    for (final category in chapter3Categories) {
      for (final question in category.questions) {
        if (!question.visibleFor(gender)) continue;
        final persisted = ZyraOnboardingAnswersService.persistedQuestionId(
          question.responseKey,
        );
        if (rawAnswers.containsKey(persisted)) {
          answers[question.responseKey] = _copyAnswerValue(
            rawAnswers[persisted],
          );
        }
        final savedPreferences = snapshot?.ch4Preferences[persisted];
        if (savedPreferences != null) {
          preferences[question.responseKey] = Map<String, TrafficLight>.from(
            savedPreferences,
          );
        }
        final savedHard = snapshot?.ch4HardRequirements[persisted];
        if (savedHard != null) {
          hard[question.responseKey] = Set<String>.from(savedHard);
        }
      }
    }

    final draft = ZyraCompatibilityDraft(
      gender: gender,
      answers: answers,
      preferences: preferences,
      hardRequirements: hard,
    );
    draft.pruneHiddenAnswers();
    return draft;
  }

  final String? gender;
  final Map<String, dynamic> answers;
  final Map<String, Map<String, TrafficLight>> preferences;
  final Map<String, Set<String>> hardRequirements;

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

  List<OnboardingQuestion> preferenceQuestions(OnboardingCategory category) =>
      visibleQuestions(category)
          .where((question) => question.ch4Status != Ch4Status.none)
          .toList(growable: false);

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
    preferences.removeWhere((key, _) => !visibleKeys.contains(key));
    hardRequirements.removeWhere((key, _) => !visibleKeys.contains(key));
  }

  int answeredIn(Iterable<OnboardingCategory> categories) => categories
      .expand(visibleQuestions)
      .where((question) => _hasValue(answers[question.responseKey]))
      .length;

  int questionsIn(Iterable<OnboardingCategory> categories) =>
      categories.expand(visibleQuestions).length;

  int get preferenceAnswerCount =>
      preferences.values.fold<int>(0, (total, values) => total + values.length);

  int get preferenceOptionCount => chapter3Categories
      .expand(preferenceQuestions)
      .fold<int>(0, (total, question) => total + question.options.length);

  int get hardRequirementCount => hardRequirements.values.fold<int>(
    0,
    (total, values) => total + values.length,
  );

  static bool _hasValue(dynamic value) => switch (value) {
    List<dynamic> values => values.isNotEmpty,
    String value => value.trim().isNotEmpty,
    null => false,
    _ => true,
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
  }) : _preview = true,
       // Keep preview's guard non-nullable while ordinary callers may omit it.
       // ignore: prefer_initializing_formals
       canAct = canAct;

  final CompatibilityEditorKind kind;
  final ZyraCompatibilityDraft initialDraft;
  final Future<bool> Function(ZyraCompatibilityDraft draft) onPersist;
  final bool _preview;

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
            child: FilledButton(
              key: const ValueKey('compatibility-save'),
              onPressed: ZyraTapFeedback.onTap(context, _saving ? null : _save),
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

class _PreferenceGroups extends StatelessWidget {
  const _PreferenceGroups({
    required this.draft,
    required this.onChanged,
    this.owner,
  });

  final ZyraCompatibilityDraft draft;
  final VoidCallback onChanged;
  final _CompatibilityPreviewOwner? owner;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
    children: [
      _MeaningCard(),
      const SizedBox(height: 14),
      for (final category in chapter3Categories)
        if (draft.preferenceQuestions(category).isNotEmpty)
          _CategoryDoor(
            key: ValueKey('edit-preferences-${category.id}'),
            label: category.name,
            status: _preferenceCategoryStatus(draft, category),
            onTap: () async {
              if (!_editorCurrent(context, owner)) return;
              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => _PreferenceCategoryEditor(
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

class _PreferenceCategoryEditor extends StatefulWidget {
  const _PreferenceCategoryEditor({
    required this.category,
    required this.draft,
    this.owner,
  });

  final OnboardingCategory category;
  final ZyraCompatibilityDraft draft;
  final _CompatibilityPreviewOwner? owner;

  @override
  State<_PreferenceCategoryEditor> createState() =>
      _PreferenceCategoryEditorState();
}

class _PreferenceCategoryEditorState extends State<_PreferenceCategoryEditor> {
  @override
  Widget build(BuildContext context) {
    final questions = widget.draft.preferenceQuestions(widget.category);
    return _EditorScaffold(
      title: widget.category.name,
      owner: widget.owner,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          final values = widget.draft.preferences[question.responseKey];
          return _QuestionDoor(
            key: ValueKey('edit-lights-${question.responseKey}'),
            question: question.prompt,
            value: values == null
                ? 'Not set'
                : '${values.length} of ${question.options.length} set',
            onTap: () async {
              if (!_editorCurrent(context, widget.owner)) return;
              final result = await Navigator.of(context)
                  .push<_PreferenceEditResult>(
                    MaterialPageRoute(
                      builder: (_) => _PreferenceQuestionEditor(
                        question: question,
                        yourAnswers: _asStringSet(
                          widget.draft.answers[question.responseKey],
                        ),
                        initialValues: values ?? const {},
                        initialHard:
                            widget.draft.hardRequirements[question
                                .responseKey] ??
                            const {},
                        owner: widget.owner,
                      ),
                    ),
                  );
              if (result == null ||
                  !mounted ||
                  !context.mounted ||
                  !_editorCurrent(context, widget.owner)) {
                return;
              }
              setState(() {
                widget.draft.preferences[question.responseKey] = result.values;
                if (result.hard.isEmpty) {
                  widget.draft.hardRequirements.remove(question.responseKey);
                } else {
                  widget.draft.hardRequirements[question.responseKey] =
                      result.hard;
                }
              });
            },
          );
        },
      ),
    );
  }
}

class _PreferenceEditResult {
  const _PreferenceEditResult(this.values, this.hard);

  final Map<String, TrafficLight> values;
  final Set<String> hard;
}

class _PreferenceQuestionEditor extends StatefulWidget {
  const _PreferenceQuestionEditor({
    required this.question,
    required this.yourAnswers,
    required this.initialValues,
    required this.initialHard,
    this.owner,
  });

  final OnboardingQuestion question;
  final Set<String> yourAnswers;
  final Map<String, TrafficLight> initialValues;
  final Set<String> initialHard;
  final _CompatibilityPreviewOwner? owner;

  @override
  State<_PreferenceQuestionEditor> createState() =>
      _PreferenceQuestionEditorState();
}

class _PreferenceQuestionEditorState extends State<_PreferenceQuestionEditor> {
  late Map<String, TrafficLight> _values = Map.from(widget.initialValues);
  late Set<String> _hard = Set.from(widget.initialHard);

  bool get _complete => widget.question.options.every(_values.containsKey);

  @override
  Widget build(BuildContext context) => _EditorScaffold(
    title: 'Partner preference',
    owner: widget.owner,
    bottom: _BottomSave(
      enabled: _complete,
      onPressed: () {
        if (_editorCurrent(context, widget.owner)) {
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
          yourAnswers: widget.yourAnswers,
          options: widget.question.options,
          hardRequirementSupported: widget.question.hardRequirementSupported,
          initialValues: widget.initialValues,
          initialHardRequirement: widget.initialHard,
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
                'First mark an answer red in Green / Yellow / Red. You can then decide here whether it must block an introduction.',
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
  Widget build(BuildContext context) => Container(
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
  );
}

class _MeaningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
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
          child: _LightMeaning(color: ZyraColors.journeyGold, label: 'Neutral'),
        ),
        Expanded(
          child: _LightMeaning(
            color: ZyraColors.negativeRed,
            label: 'Not for me',
          ),
        ),
      ],
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
  });

  final String label;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
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
                      Text(status, style: ZyraText.subtext(size: 11.5)),
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
  );
}

class _QuestionDoor extends StatelessWidget {
  const _QuestionDoor({
    super.key,
    required this.question,
    required this.value,
    required this.onTap,
  });

  final String question;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
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
                          color: value == 'Not answered'
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
  );
}

class _EditorScaffold extends StatelessWidget {
  const _EditorScaffold({
    required this.title,
    required this.child,
    this.bottom,
    this.owner,
  });

  final String title;
  final Widget child;
  final Widget? bottom;
  final _CompatibilityPreviewOwner? owner;

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
              automaticallyImplyLeading: owner == null,
              leading: owner != null && Navigator.of(context).canPop()
                  ? BackButton(
                      onPressed: ZyraTapFeedback.onTap(context, () {
                        if (_editorCurrent(context, owner) &&
                            Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      }),
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
        if (_editorCurrent(context, owner) && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      enabled: owner!.alive,
      child: page,
    );
  }
}

class _BottomSave extends StatelessWidget {
  const _BottomSave({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ZyraColors.luxuryDarkPurple.withValues(alpha: 0),
          ZyraColors.luxuryDarkPurple.withValues(alpha: 0.94),
        ],
      ),
    ),
    child: SizedBox(
      width: double.infinity,
      child: FilledButton(
        key: const ValueKey('question-save'),
        onPressed: ZyraTapFeedback.onTap(context, enabled ? onPressed : null),
        child: const Text('Use this answer'),
      ),
    ),
  );
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
    (count, question) =>
        count + (draft.preferences[question.responseKey]?.length ?? 0),
  );
  return '$answered of $total preferences set';
}
