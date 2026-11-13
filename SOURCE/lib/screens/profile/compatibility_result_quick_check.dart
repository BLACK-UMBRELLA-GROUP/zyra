import 'package:flutter/material.dart';

import '../../data/chapter3_categories.dart';
import '../../dev/zyra_app_gold_preview.dart';
import '../../models/onboarding_question.dart';
import '../../services/zyra_onboarding_answers_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_developer_title.dart';
import '../../widgets/zyra_loading.dart';
import '../../widgets/zyra_state_widgets.dart';
import '../../widgets/zyra_tap_feedback.dart';
import 'compatibility_editors.dart';

class ZyraCompatibilityCheckCard extends StatelessWidget {
  const ZyraCompatibilityCheckCard({
    super.key,
    required this.personName,
    required this.onCheck,
  });

  final String personName;
  final VoidCallback? onCheck;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.hasBoundedHeight ? constraints.maxHeight : 0,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ZyraColors.surfaceFill,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: ZyraColors.surfaceBorder),
            boxShadow: [
              BoxShadow(
                color: ZyraColors.ink(.12),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: _checkBorder,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 28,
                      color: ZyraColors.journeyGold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'One quick check first',
                    textAlign: TextAlign.center,
                    style: ZyraText.heading(size: 24),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 290),
                    child: Text(
                      'Some of your partner preferences were saved before amber meant “Open to this”. '
                      'Confirm them and your result with $personName is ready. Your Unlock is kept.',
                      textAlign: TextAlign.center,
                      style: ZyraText.subtext(size: 13).copyWith(height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _GoldButton(label: 'Check my answers', onPressed: onCheck),
                  const SizedBox(height: 10),
                  Text(
                    'The same check for every result. It never shows anything about $personName.',
                    textAlign: TextAlign.center,
                    style: ZyraText.subtext(size: 11.5),
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

typedef ZyraPreferenceCheckLists = ({
  Set<ZyraPreferenceOption> visible,
  Set<ZyraPreferenceOption> hidden,
  Set<ZyraPreferenceOption> missing,
});
typedef ZyraPreferenceSelections = Map<ZyraPreferenceOption, TrafficLight>;

/// The route takes the owner's lifetime guard only. The check itself has no
/// subject or match, and none of its selections can spend an Unlock.
Future<bool> openZyraCompatibilityResultCheck({
  required BuildContext context,
  required String ownerId,
  required bool Function() isOwnerCurrent,
}) async {
  if (!isOwnerCurrent() || ModalRoute.of(context)?.isCurrent != true) {
    return false;
  }
  final completed = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => ZyraCompatibilityResultQuickCheck(
        isOwnerCurrent: isOwnerCurrent,
        load: () async {
          final checks =
              await ZyraOnboardingAnswersService.visiblePreferenceChecks(
                expectedUserId: ownerId,
              );
          if (!isOwnerCurrent()) throw StateError('The setup account changed.');
          final hidden =
              await ZyraOnboardingAnswersService.lightsNeededForCompatibility(
                expectedUserId: ownerId,
              );
          return (
            visible: checks.legacyAmber,
            hidden: hidden,
            missing: checks.missing,
          );
        },
        confirm: (selections) =>
            ZyraOnboardingAnswersService.confirmPreferenceLights(
              expectedUserId: ownerId,
              selections: selections,
            ),
      ),
    ),
  );
  return completed == true && isOwnerCurrent();
}

enum _CheckGroup {
  setup('FROM YOUR PROFILE SET-UP'),
  preferences('PARTNER PREFERENCES'),
  compatibility('ALSO USED FOR COMPATIBILITY');

  const _CheckGroup(this.title);
  final String title;
}

typedef _CheckItem = ({
  ZyraPreferenceOption key,
  String question,
  String option,
  _CheckGroup group,
  bool missing,
});

List<_CheckItem> _items(ZyraPreferenceCheckLists lists) {
  final items = <_CheckItem>[];
  // A visibility change between the two reads can briefly put an item in both.
  // Use the current hidden classification, and never submit a duplicate key.
  final visible = {...lists.visible, ...lists.missing}.difference(lists.hidden);
  final remaining = {...visible, ...lists.hidden};
  void add(
    ZyraPreferenceOption key,
    String question,
    String option,
    _CheckGroup group,
  ) {
    if (remaining.remove(key)) {
      items.add((
        key: key,
        question: question,
        option: option,
        group: group,
        missing: lists.missing.contains(key),
      ));
    }
  }

  final otherSect = visible
      .where(
        (key) =>
            key.questionId == 'ch2.sect.matrix' &&
            !const {'sunni', 'shia'}.contains(key.optionValue),
      )
      .firstOrNull;
  final setup = ZyraSetupPreferenceLights(
    otherSect: otherSect?.optionValue ?? 'other',
  );
  for (final question in setup.questions) {
    for (final option in question.options) {
      final key = setup.key(question, option);
      if (visible.contains(key)) {
        add(key, question.prompt, option, _CheckGroup.setup);
      }
    }
  }
  for (final category in chapter3Categories) {
    for (final question in category.questions) {
      if (question.ch4Status == Ch4Status.none) continue;
      for (final option in question.options) {
        final key = (questionId: question.id, optionValue: option);
        add(
          key,
          question.prompt,
          option,
          lists.hidden.contains(key)
              ? _CheckGroup.compatibility
              : _CheckGroup.preferences,
        );
      }
    }
  }
  const hiddenSetup = {
    'ch2.country_of_birth.flexibility': (
      'Country of birth',
      'Someone born outside your preferred countries',
    ),
    'ch2.nationality.flexibility': (
      'Nationality',
      'Someone outside your preferred nationalities',
    ),
    'ch2.ethnicity.flexibility': (
      'Ethnic background',
      'Someone outside your preferred ethnic backgrounds',
    ),
    'ch2.languages.flexibility': (
      'Languages',
      'Someone who speaks none of your preferred languages',
    ),
  };
  for (final entry in hiddenSetup.entries) {
    final key = (questionId: entry.key, optionValue: '*');
    if (lists.hidden.contains(key)) {
      add(key, entry.value.$1, entry.value.$2, _CheckGroup.compatibility);
    }
  }
  if (remaining.isNotEmpty) {
    throw const FormatException('Unknown preference check item.');
  }
  final hiddenByKey = {
    for (final item in items)
      if (item.group == _CheckGroup.compatibility) item.key: item,
  };
  return [
    for (final item in items)
      if (item.group != _CheckGroup.compatibility) item,
    for (final key in lists.hidden) hiddenByKey[key]!,
  ];
}

class ZyraCompatibilityResultQuickCheck extends StatefulWidget {
  const ZyraCompatibilityResultQuickCheck({
    super.key,
    required this.isOwnerCurrent,
    required this.load,
    required this.confirm,
  });

  final bool Function() isOwnerCurrent;
  final Future<ZyraPreferenceCheckLists> Function() load;
  final Future<void> Function(ZyraPreferenceSelections) confirm;

  @override
  State<ZyraCompatibilityResultQuickCheck> createState() =>
      _ZyraCompatibilityResultQuickCheckState();
}

class _ZyraCompatibilityResultQuickCheckState
    extends State<ZyraCompatibilityResultQuickCheck> {
  List<_CheckItem>? _itemsToCheck;
  final _selections = ZyraPreferenceSelections();
  bool _busy = false;
  bool _saving = false;
  bool _refreshBeforeRetry = false;
  String? _error;

  bool get _canAct =>
      mounted &&
      widget.isOwnerCurrent() &&
      ModalRoute.of(context)?.isCurrent == true;
  int get _left => (_itemsToCheck?.length ?? 0) - _selections.length;

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_ownerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_canAct) _load();
    });
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_ownerChanged);
    super.dispose();
  }

  void _ownerChanged() {
    if (mounted && !widget.isOwnerCurrent()) setState(() {});
  }

  Future<void> _load() async {
    if (!_canAct || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final items = _items(await widget.load());
      if (!_canAct) return;
      final pendingKeys = {for (final item in items) item.key};
      final recovered =
          _refreshBeforeRetry &&
          _selections.keys.any((key) => !pendingKeys.contains(key));
      setState(() {
        _itemsToCheck = items;
        _selections.removeWhere((key, _) => !pendingKeys.contains(key));
        _refreshBeforeRetry = false;
      });
      if (recovered) {
        ZyraOnboardingAnswersService.preferenceConfirmationRevision.value++;
      }
    } catch (_) {
      if (_canAct) {
        setState(
          () => _error = 'Could not load your answers. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _done() async {
    if (!_canAct || _busy || _itemsToCheck == null) return;
    // An acknowledgement can be lost after commit. Reconcile with both owner
    // lists before a retry, since a confirmed hidden item may no longer be writable.
    if (_refreshBeforeRetry) {
      await _load();
      if (!mounted || !_canAct || _error != null) return;
    }
    if (_left > 0) {
      showZyraPreferenceToast(context, '$_left left to check.');
      return;
    }
    setState(() {
      _busy = true;
      _saving = true;
      _error = null;
    });
    try {
      if (_selections.isNotEmpty) await widget.confirm(Map.of(_selections));
      if (!mounted || !_canAct) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      Navigator.of(context).pop(true);
    } catch (_) {
      if (_canAct) {
        setState(() {
          _refreshBeforeRetry = true;
          _error = 'Could not save your answers. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerCurrent = widget.isOwnerCurrent();
    final items = ownerCurrent ? _itemsToCheck : null;
    return PopScope(
      canPop: !_saving || !ownerCurrent,
      child: DecoratedBox(
        decoration: ZyraAppGoldDecoration(
          gradient: ZyraColors.genderGradient(AppState.instance.gender),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: ZyraDeveloperTitle(
              child: Text('Quick check', style: ZyraText.heading(size: 26)),
            ),
            centerTitle: false,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: !ownerCurrent
                  ? const Center(child: Text('Your account or result changed.'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (items?.any((item) => item.missing) != true)
                          Text(
                            'These were saved before amber meant “Open to this”. '
                            'Tap a light on each, even if it stays amber, so it counts.',
                            style: ZyraText.subtext(size: 12.5),
                          ),
                        if (_error case final message?) ...[
                          const SizedBox(height: 8),
                          ZyraErrorBanner(
                            message: message,
                            onRetry: _busy
                                ? null
                                : items == null
                                ? _load
                                : _done,
                          ),
                        ],
                        if (items == null && _busy)
                          const Expanded(child: ZyraLoading()),
                        if (items != null) ...[
                          Expanded(
                            child: ListView(
                              physics: const ScrollPhysics(),
                              children: [
                                for (final group in _CheckGroup.values)
                                  if (items.any(
                                    (item) => item.group == group,
                                  )) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        2,
                                        12,
                                        2,
                                        4,
                                      ),
                                      child: Text(
                                        group.title,
                                        style: ZyraText.body(
                                          size: 11,
                                          color: ZyraColors.goldText,
                                        ).copyWith(letterSpacing: 1.2),
                                      ),
                                    ),
                                    if (group == _CheckGroup.compatibility)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          2,
                                          0,
                                          2,
                                          8,
                                        ),
                                        child: Text(
                                          'Not shown in your Partner preferences, but they can apply to some people.',
                                          style: ZyraText.subtext(size: 11.5),
                                        ),
                                      ),
                                    for (final item in items.where(
                                      (item) => item.group == group,
                                    ))
                                      _ItemCard(
                                        key: ValueKey(item.key),
                                        item: item,
                                        selected: _selections[item.key],
                                        onTap: _busy || _refreshBeforeRetry
                                            ? null
                                            : (light) {
                                                if (!_canAct || _busy) return;
                                                setState(
                                                  () => _selections[item.key] =
                                                      light,
                                                );
                                              },
                                      ),
                                  ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _GoldButton(
                            label: _left == 0 ? 'Done' : 'Done · $_left left',
                            onPressed: _busy ? null : _done,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

final _checkBorder = Border.all(
  color: ZyraColors.journeyGold.withValues(alpha: .6),
);

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final _CheckItem item;
  final TrafficLight? selected;
  final ValueChanged<TrafficLight>? onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFBF7F0),
      borderRadius: BorderRadius.circular(14),
      border: selected == null
          ? _checkBorder
          : Border.all(color: ZyraColors.surfaceBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.question,
                style: ZyraText.subtext(size: 11.5).copyWith(height: 1.35),
              ),
            ),
            const SizedBox(width: 8),
            if (selected == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: _checkBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  item.missing ? 'Not set' : 'Check',
                  style: ZyraText.subtext(
                    size: 10.5,
                    color: ZyraColors.goldText,
                  ),
                ),
              )
            else
              Text('✓ Done', style: ZyraText.subtext(size: 10.5)),
          ],
        ),
        const SizedBox(height: 4),
        Text(item.option, style: ZyraText.body(size: 14.5)),
        const SizedBox(height: 9),
        Row(
          spacing: 7,
          children: [
            for (final light in TrafficLight.values)
              Expanded(
                child: _CheckLight(
                  key: ValueKey((item.key, light)),
                  light: light,
                  selected: selected == light,
                  option: item.option,
                  onTap: onTap == null ? null : () => onTap!(light),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _CheckLight extends StatelessWidget {
  const _CheckLight({
    super.key,
    required this.light,
    required this.selected,
    required this.option,
    required this.onTap,
  });
  final TrafficLight light;
  final bool selected;
  final String option;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (light) {
      TrafficLight.green => ('Prefer this', ZyraColors.positiveGreen),
      TrafficLight.yellow => ('Open to this', ZyraColors.journeyGold),
      TrafficLight.red => ('Not for me', ZyraColors.negativeRed),
    };
    final radius = BorderRadius.circular(11);
    final action = ZyraTapFeedback.onTap(context, onTap);
    return Semantics(
      button: true,
      enabled: action != null,
      selected: selected,
      label: '$label: $option',
      onTap: action,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: action,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: radius,
              color: selected ? color.withValues(alpha: .14) : null,
              border: Border.all(
                color: selected ? color : ZyraColors.ink(.13),
                width: selected ? 1.2 : .8,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: ZyraText.subtext(
                    size: 10.5,
                    color: selected
                        ? ZyraColors.espresso
                        : ZyraColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: ZyraTapFeedback.onTap(context, onPressed),
    style: FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      backgroundColor: ZyraColors.goldTextFill,
      foregroundColor: ZyraColors.onPrimaryAction,
      shape: const StadiumBorder(),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: ZyraText.button(size: 14),
    ),
  );
}
