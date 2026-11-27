import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/zyra_journey_stages.dart';
import '../models/zyra_developer_preview.dart';
import '../models/zyra_error_state.dart';
import '../models/zyra_offers_preview.dart';
import '../state/zyra_developer_samples.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_motion.dart';
import '../theme/zyra_interaction_style.dart';
import '../theme/zyra_text.dart';
import 'zyra_confirm_sheet.dart';
import 'zyra_tap_feedback.dart';

class ZyraDeveloperPanelValues {
  const ZyraDeveloperPanelValues({
    required this.active,
    required this.ended,
    required this.received,
    required this.sent,
    required this.past,
    required this.introductions,
    this.preview,
  });

  final int active, ended, received, sent, introductions;
  final ZyraDeveloperPast past;
  final ZyraDeveloperPreviewValues? preview;
}

ModalBottomSheetRoute<void> zyraDeveloperPanelRoute(
  BuildContext context, {
  required String email,
  required String planName,
  required int journeyPlaces,
  required ValueListenable<ZyraDeveloperPanelValues> values,
  ZyraDeveloperPreviewActions? previewActions,
  Listenable? visibilityListenable,
  bool Function()? isVisible,
  required ValueChanged<int> onActive,
  required ValueChanged<int> onEnded,
  required ValueChanged<int> onReceived,
  required ValueChanged<int> onSent,
  required ValueChanged<ZyraDeveloperPast> onPast,
  required ValueChanged<int> onIntroductions,
  required VoidCallback onClear,
}) {
  final hapticLevel = context
      .dependOnInheritedWidgetOfExactType<ZyraTapFeedback>()
      ?.level();
  return ModalBottomSheetRoute<void>(
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: Navigator.of(context, rootNavigator: true).context,
    ),
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    modalBarrierColor: const Color(0x611E1610),
    sheetAnimationStyle: ZyraMotion.reduceMotion(context)
        ? AnimationStyle.noAnimation
        : null,
    builder: (context) {
      final panel = _DeveloperPanel(
        email: email,
        planName: planName,
        journeyPlaces: journeyPlaces,
        values: values,
        previewActions: previewActions,
        onActive: onActive,
        onEnded: onEnded,
        onReceived: onReceived,
        onSent: onSent,
        onPast: onPast,
        onIntroductions: onIntroductions,
        onClear: onClear,
        isVisible: isVisible,
      );
      final visibility = visibilityListenable;
      final body = visibility == null
          ? panel
          : ListenableBuilder(
              listenable: visibility,
              child: panel,
              builder: (context, child) =>
                  isVisible?.call() == false ? const SizedBox.shrink() : child!,
            );
      // A captured preview feedback scope belongs to the covered page.
      // This sheet retains the chosen level and its own current-route gate.
      return ZyraTapFeedback(
        level: () => hapticLevel ?? ZyraInteractionStyle.hapticLevel,
        canAct: () =>
            isVisible?.call() != false &&
            ModalRoute.isCurrentOf(context) == true,
        child: body,
      );
    },
  );
}

class _DeveloperPanel extends StatefulWidget {
  const _DeveloperPanel({
    required this.email,
    required this.planName,
    required this.journeyPlaces,
    required this.values,
    required this.onActive,
    required this.onEnded,
    required this.onReceived,
    required this.onSent,
    required this.onPast,
    required this.onIntroductions,
    required this.onClear,
    this.previewActions,
    this.isVisible,
  });

  final String email, planName;
  final int journeyPlaces;
  final ValueListenable<ZyraDeveloperPanelValues> values;
  final ZyraDeveloperPreviewActions? previewActions;
  final ValueChanged<int> onActive,
      onEnded,
      onReceived,
      onSent,
      onIntroductions;
  final ValueChanged<ZyraDeveloperPast> onPast;
  final VoidCallback onClear;
  final bool Function()? isVisible;

  @override
  State<_DeveloperPanel> createState() => _DeveloperPanelState();
}

class _DeveloperPanelState extends State<_DeveloperPanel> {
  Timer? _clearToast;

  void _clear() {
    if (widget.isVisible?.call() == false) return;
    widget.onClear();
    if (!mounted) return;
    _clearToast?.cancel();
    setState(() {
      _clearToast = Timer(const Duration(milliseconds: 1700), () {
        setState(() => _clearToast = null);
      });
    });
  }

  void _previewAction(VoidCallback action) {
    if (!mounted ||
        widget.isVisible?.call() == false ||
        ModalRoute.isCurrentOf(context) != true) {
      return;
    }
    action();
  }

  List<Widget> _previewBeginning(ZyraDeveloperPreviewValues preview) {
    final actions = widget.previewActions!;
    return [
      const _SectionLabel('VIEW AS'),
      _DeveloperSelector(
        id: 'view_as',
        label: 'View as',
        labels: [for (final view in ZyraDeveloperViewAs.values) view.label],
        value: preview.viewAs?.index ?? -1,
        stacked: true,
        onChanged: (index) => _previewAction(
          () => actions.onViewAs(ZyraDeveloperViewAs.values[index]),
        ),
      ),
      const _SectionLabel('SIGN UP'),
      TextButton(
        key: const ValueKey('dev_start_signup'),
        onPressed:
            preview.canActivate &&
                preview.signupAvailable &&
                actions.onStartSignup != null
            ? () => _previewAction(actions.onStartSignup!)
            : null,
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          minimumSize: const Size.fromHeight(44),
          foregroundColor: ZyraColors.espresso,
          textStyle: ZyraText.body(size: 14),
        ),
        child: const Text('Start sign-up'),
      ),
      _DeveloperSwitch(
        id: 'unverified',
        label: 'Unverified',
        value: preview.unverified,
        onChanged: preview.canActivate
            ? (value) => _previewAction(() => actions.onUnverified(value))
            : null,
      ),
      _DeveloperSwitch(
        id: 'setup_unfinished',
        label: 'Setup unfinished',
        value: preview.setupUnfinished,
        onChanged: preview.canActivate
            ? (value) => _previewAction(() => actions.onSetupUnfinished(value))
            : null,
      ),
    ];
  }

  List<Widget> _previewJourneys(ZyraDeveloperPreviewValues preview) {
    final actions = widget.previewActions!;
    final journeys = preview.journeys;
    final selectedIndex = journeys.indexWhere(
      (journey) => journey.id == preview.selectedJourneyId,
    );
    final stages = ZyraJourneyStages.previewAll;
    final selectedStage = selectedIndex < 0
        ? -1
        : stages.indexWhere(
            (stage) => stage.value == journeys[selectedIndex].stage,
          );
    return [
      _DeveloperSelector(
        id: 'journey',
        label: 'Open Journey',
        labels: journeys.isEmpty
            ? const ['—']
            : [for (final journey in journeys) journey.name],
        value: selectedIndex,
        max: preview.canActivate ? journeys.length - 1 : -1,
        stacked: true,
        onChanged: (index) =>
            _previewAction(() => actions.onJourney(journeys[index].id)),
      ),
      _DeveloperSelector(
        id: 'stage',
        label: 'Stage',
        labels: [for (final stage in stages) stage.label],
        value: selectedStage,
        max: !preview.canActivate || selectedIndex < 0 ? -1 : stages.length - 1,
        stacked: true,
        onChanged: (index) =>
            _previewAction(() => actions.onStage(stages[index].value)),
      ),
    ];
  }

  List<Widget> _previewEnding(ZyraDeveloperPreviewValues preview) {
    final actions = widget.previewActions!;
    return [
      const _SectionLabel('MY ZYRA'),
      _DeveloperSelector(
        id: 'preset',
        label: 'Preset',
        labels: [for (final preset in ZyraDeveloperPreset.values) preset.label],
        value: preview.preset?.index ?? -1,
        max: preview.canActivate ? 3 : -1,
        stacked: true,
        onChanged: (index) => _previewAction(
          () => actions.onPreset(ZyraDeveloperPreset.values[index]),
        ),
      ),
      if (preview.viewAs?.guardian != true) ...[
        const _SectionLabel('NOTICES'),
        _DeveloperSelector(
          id: 'notice',
          label: '2-year inactivity',
          labels: const [
            'None',
            'Email 1',
            'Email 2',
            'Email 3',
            'Email 4',
            'Email 5',
            'Welcome back',
          ],
          value: preview.notice,
          max: preview.canActivate ? 6 : -1,
          stacked: true,
          onChanged: (value) => _previewAction(() => actions.onNotice(value)),
        ),
      ],
      if (actions.onProfileSmallPage case final openSample?) ...[
        const _SectionLabel('PROFILE PAGES'),
        for (final sample in ZyraProfileSmallPageSample.values)
          _DeveloperAction(
            id: 'profile_small_page_${sample.name}',
            label: sample.label,
            onPressed: () => _previewAction(() => openSample(sample)),
          ),
      ],
      if (actions.onRetentionMode != null &&
          actions.onEid != null &&
          actions.onRamadan != null) ...[
        const _SectionLabel('OFFERS'),
        _DeveloperSelector(
          id: 'retention_offer',
          label: 'Offer mode',
          labels: [for (final mode in ZyraRetentionMode.values) mode.label],
          value: preview.offers.retentionMode.index,
          max: preview.canActivate ? ZyraRetentionMode.values.length - 1 : -1,
          stacked: true,
          onChanged: (index) => _previewAction(
            () => actions.onRetentionMode!(ZyraRetentionMode.values[index]),
          ),
        ),
        _DeveloperSelector(
          id: 'eid_gift',
          label: 'Eid gift',
          labels: [for (final eid in ZyraPreviewEid.values) eid.label],
          value: preview.offers.eid.index,
          max: preview.canActivate ? ZyraPreviewEid.values.length - 1 : -1,
          stacked: true,
          onChanged: (index) => _previewAction(
            () => actions.onEid!(ZyraPreviewEid.values[index]),
          ),
        ),
        _DeveloperSelector(
          id: 'ramadan_draw',
          label: 'Ramadan gift draw',
          labels: const ['Off', 'On'],
          value: preview.offers.ramadan ? 1 : 0,
          max: preview.canActivate ? 1 : -1,
          stacked: true,
          onChanged: (index) =>
              _previewAction(() => actions.onRamadan!(index == 1)),
        ),
      ],
      const _SectionLabel('ERROR PAGES'),
      for (final error in const [
        (label: 'Phone offline', kind: ZyraErrorKind.offline),
        (label: 'ZYRA server down', kind: ZyraErrorKind.serviceUnavailable),
        (label: 'Session ended', kind: ZyraErrorKind.sessionExpired),
      ])
        _DeveloperAction(
          id: 'error_${error.kind.name}',
          label: error.label,
          onPressed: () => _previewAction(() => actions.onError(error.kind)),
        ),
    ];
  }

  @override
  void dispose() {
    _clearToast?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .88,
      ),
      child: DecoratedBox(
        decoration: ZyraIvorySheet.decoration,
        child: ZyraIvorySheet(
          surfaceKey: const ValueKey('dev_panel'),
          child: SafeArea(
            top: false,
            minimum: ZyraIvorySheet.bottomPadding,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ZyraIvorySheetHandle(),
                    Flexible(
                      child: SingleChildScrollView(
                        primary: false,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ValueListenableBuilder(
                          valueListenable: widget.values,
                          builder: (context, values, _) {
                            final preview = widget.previewActions == null
                                ? null
                                : values.preview;
                            final places =
                                preview?.journeyPlaces ?? widget.journeyPlaces;
                            final plan = preview?.viewAs?.guardian == true
                                ? switch (places) {
                                    1 => ZyraDeveloperViewAs.seekerBasic.label,
                                    3 => ZyraDeveloperViewAs.seekerOne.label,
                                    _ => preview!.realPlanName,
                                  }
                                : preview?.viewAs?.label ??
                                      preview?.realPlanName ??
                                      widget.planName;
                            final cap =
                                '$plan has $places ${places == 1 ? 'place' : 'places'}';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    'Developer',
                                    style: ZyraText.heading(
                                      size: 21,
                                    ).copyWith(fontWeight: FontWeight.w300),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  preview == null
                                      ? '${widget.email} · ${widget.planName}\n'
                                            'Sample data on this account only. Members never see it.'
                                      : '${widget.email}\n'
                                            'Viewing as ${preview.viewAs?.label ?? preview.realPlanName} · real plan${preview.realPlanName == 'none' ? ':' : ''} ${preview.realPlanName}\n'
                                            'Sample data on this account only. Members never see it.',
                                  style: ZyraText.subtext(
                                    size: 12,
                                    color: ZyraColors.secondaryText,
                                  ).copyWith(height: 1.45),
                                ),
                                if (preview != null)
                                  ..._previewBeginning(preview),
                                const _SectionLabel('JOURNEYS'),
                                _DeveloperSelector.count(
                                  id: 'active',
                                  label: 'Active Journeys',
                                  subtitle: cap,
                                  value: values.active,
                                  max: preview?.canActivate == false
                                      ? -1
                                      : places,
                                  onChanged: widget.onActive,
                                ),
                                if (preview != null)
                                  ..._previewJourneys(preview),
                                _DeveloperSelector.count(
                                  id: 'ended',
                                  max: preview?.canActivate == false ? -1 : 3,
                                  label: 'Ended Journeys',
                                  value: values.ended,
                                  onChanged: widget.onEnded,
                                ),
                                const _SectionLabel('JOURNEY REQUESTS'),
                                _DeveloperSelector.count(
                                  id: 'received',
                                  max: preview?.canActivate == false ? -1 : 3,
                                  label: 'Received',
                                  value: values.received,
                                  onChanged: widget.onReceived,
                                ),
                                _DeveloperSelector.count(
                                  id: 'sent',
                                  max: preview?.canActivate == false ? -1 : 3,
                                  label: 'Sent',
                                  value: values.sent,
                                  onChanged: widget.onSent,
                                ),
                                _DeveloperSelector(
                                  id: 'past',
                                  max: preview?.canActivate == false ? -1 : 2,
                                  label: 'Past',
                                  subtitle:
                                      '“Same person” = 20 requests to Sara',
                                  labels: const [
                                    'None',
                                    'Mixed',
                                    'Same person',
                                  ],
                                  value: values.past.index,
                                  onChanged: (index) => widget.onPast(
                                    ZyraDeveloperPast.values[index],
                                  ),
                                ),
                                const _SectionLabel('INTRODUCTIONS'),
                                _DeveloperSelector.count(
                                  id: 'introductions',
                                  max: preview?.canActivate == false ? -1 : 3,
                                  label: 'From your Guardians',
                                  value: values.introductions,
                                  onChanged: widget.onIntroductions,
                                ),
                                if (preview != null) ..._previewEnding(preview),
                                const SizedBox(height: 14),
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: ZyraColors.divider,
                                ),
                                TextButton(
                                  key: const ValueKey('dev_clear'),
                                  onPressed: ZyraTapFeedback.onTap(
                                    context,
                                    _clear,
                                  ),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: ZyraColors.espresso,
                                    textStyle: ZyraText.body(size: 15),
                                  ),
                                  child: const Text('Clear sample data'),
                                ),
                                const SizedBox(height: 8),
                                DecoratedBox(
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(999),
                                    ),
                                    boxShadow: ZyraColors.cardShadows,
                                  ),
                                  child: OutlinedButton(
                                    key: const ValueKey('dev_done'),
                                    onPressed: ZyraTapFeedback.onTap(
                                      context,
                                      () {
                                        if (widget.isVisible?.call() != false &&
                                            ModalRoute.isCurrentOf(context) ==
                                                true) {
                                          Navigator.of(context).pop();
                                        }
                                      },
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(52),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      side: BorderSide(
                                        color: ZyraColors.surfaceBorder,
                                      ),
                                      shape: const StadiumBorder(),
                                      backgroundColor: ZyraColors.cardSurface,
                                      foregroundColor: ZyraColors.secondaryText,
                                      textStyle: ZyraText.body(size: 15),
                                    ),
                                    child: const Text('Done'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (_clearToast != null)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 68,
                    child: IgnorePointer(
                      child: Semantics(
                        liveRegion: true,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: ZyraColors.espresso.withValues(alpha: .94),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Text(
                              'Sample data cleared.',
                              textAlign: TextAlign.center,
                              style: ZyraText.body(
                                size: 12.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 2),
    child: Semantics(
      header: true,
      child: Text(
        label,
        style: ZyraText.chapterLabel(
          color: ZyraColors.goldText,
        ).copyWith(letterSpacing: 1.4, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _DeveloperSelector extends StatelessWidget {
  const _DeveloperSelector({
    required this.id,
    required this.label,
    required this.labels,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.max = 0x7fffffff,
    this.stacked = false,
  });

  const _DeveloperSelector.count({
    required this.id,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.max = 3,
  }) : labels = const ['0', '1', '2', '3'],
       stacked = false;

  final String id, label;
  final String? subtitle;
  final List<String> labels;
  final int value, max;
  final bool stacked;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final caption = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ZyraText.body(size: 14).copyWith(height: 1.3)),
        if (subtitle case final detail?) ...[
          const SizedBox(height: 1),
          Text(
            detail,
            style: ZyraText.subtext(
              size: 11.5,
              color: ZyraColors.secondaryText,
            ).copyWith(height: 1.3),
          ),
        ],
      ],
    );
    final track = DecoratedBox(
      decoration: BoxDecoration(
        color: ZyraColors.ink(.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Wrap(
          spacing: 3,
          runSpacing: 3,
          children: [
            for (var index = 0; index < labels.length; index++)
              _segment(context, index),
          ],
        ),
      ),
    );
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ZyraColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
          if (stacked || constraints.maxWidth < 260 || scale > 1.4) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [caption, const SizedBox(height: 8), track],
            );
          }
          return Row(
            children: [
              Expanded(child: caption),
              const SizedBox(width: 10),
              track,
            ],
          );
        },
      ),
    );
  }

  Widget _segment(BuildContext context, int index) {
    final selected = index == value;
    final enabled = index <= max;
    final textStyle = ZyraText.button(size: 12.5).copyWith(letterSpacing: 0);
    return Semantics(
      selected: selected,
      label: '$label ${labels[index]}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? ZyraColors.ivoryTop : null,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x293E2E1E),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: TextButton(
          key: ValueKey('dev_${id}_$index'),
          onPressed: ZyraTapFeedback.onTap(
            context,
            enabled ? () => onChanged(index) : null,
          ),
          style: TextButton.styleFrom(
            minimumSize: const Size(34, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            foregroundColor: selected
                ? ZyraColors.espresso
                : ZyraColors.secondaryText,
            disabledForegroundColor: ZyraColors.secondaryText,
            textStyle: textStyle,
            shape: const StadiumBorder(),
            visualDensity: VisualDensity.standard,
          ),
          child: ExcludeSemantics(child: Text(labels[index])),
        ),
      ),
    );
  }
}

class _DeveloperSwitch extends StatelessWidget {
  const _DeveloperSwitch({
    required this.id,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String id, label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: ZyraColors.divider)),
    ),
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: ZyraText.body(size: 14).copyWith(height: 1.3),
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            key: ValueKey('dev_$id'),
            value: value,
            activeTrackColor: ZyraColors.goldText,
            onChanged: ZyraTapFeedback.onChanged(context, onChanged),
          ),
        ],
      ),
    ),
  );
}

class _DeveloperAction extends StatelessWidget {
  const _DeveloperAction({
    required this.id,
    required this.label,
    required this.onPressed,
  });

  final String id, label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: ZyraColors.divider)),
    ),
    child: TextButton(
      key: ValueKey('dev_$id'),
      onPressed: ZyraTapFeedback.onTap(context, onPressed),
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: ZyraColors.espresso,
        textStyle: ZyraText.body(size: 14),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.centerLeft,
      ),
      child: Text(label),
    ),
  );
}
