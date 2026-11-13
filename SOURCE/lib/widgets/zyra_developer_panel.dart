import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../state/zyra_developer_samples.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_motion.dart';
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
  });

  final int active, ended, received, sent, introductions;
  final ZyraDeveloperPast past;
}

ModalBottomSheetRoute<void> zyraDeveloperPanelRoute(
  BuildContext context, {
  required String email,
  required String planName,
  required int journeyPlaces,
  required ValueListenable<ZyraDeveloperPanelValues> values,
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
      return visibility == null
          ? panel
          : ListenableBuilder(
              listenable: visibility,
              child: panel,
              builder: (context, child) =>
                  isVisible?.call() == false ? const SizedBox.shrink() : child!,
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
    this.isVisible,
  });

  final String email, planName;
  final int journeyPlaces;
  final ValueListenable<ZyraDeveloperPanelValues> values;
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

  @override
  void dispose() {
    _clearToast?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final places = widget.journeyPlaces;
    final cap =
        '${widget.planName} has $places ${places == 1 ? 'place' : 'places'}';
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
                          builder: (context, values, _) => Column(
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
                                '${widget.email} · ${widget.planName}\n'
                                'Sample data on this account only. Members never see it.',
                                style: ZyraText.subtext(
                                  size: 12,
                                  color: ZyraColors.mutedText,
                                ).copyWith(height: 1.45),
                              ),
                              const _SectionLabel('JOURNEYS'),
                              _DeveloperSelector.count(
                                id: 'active',
                                label: 'Active Journeys',
                                subtitle: cap,
                                value: values.active,
                                max: places,
                                onChanged: widget.onActive,
                              ),
                              _DeveloperSelector.count(
                                id: 'ended',
                                label: 'Ended Journeys',
                                value: values.ended,
                                onChanged: widget.onEnded,
                              ),
                              const _SectionLabel('JOURNEY REQUESTS'),
                              _DeveloperSelector.count(
                                id: 'received',
                                label: 'Received',
                                value: values.received,
                                onChanged: widget.onReceived,
                              ),
                              _DeveloperSelector.count(
                                id: 'sent',
                                label: 'Sent',
                                value: values.sent,
                                onChanged: widget.onSent,
                              ),
                              _DeveloperSelector(
                                id: 'past',
                                label: 'Past',
                                subtitle: '“Same person” = 20 requests to Sara',
                                labels: const ['None', 'Mixed', 'Same person'],
                                value: values.past.index,
                                onChanged: (index) => widget.onPast(
                                  ZyraDeveloperPast.values[index],
                                ),
                              ),
                              const _SectionLabel('INTRODUCTIONS'),
                              _DeveloperSelector.count(
                                id: 'introductions',
                                label: 'From your Guardians',
                                value: values.introductions,
                                onChanged: widget.onIntroductions,
                              ),
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
                                  onPressed: ZyraTapFeedback.onTap(context, () {
                                    if (widget.isVisible?.call() != false &&
                                        ModalRoute.isCurrentOf(context) ==
                                            true) {
                                      Navigator.of(context).pop();
                                    }
                                  }),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    side: BorderSide(
                                      color: ZyraColors.surfaceBorder,
                                    ),
                                    shape: const StadiumBorder(),
                                    backgroundColor: ZyraColors.cardSurface,
                                    foregroundColor: ZyraColors.mutedText,
                                    textStyle: ZyraText.body(size: 15),
                                  ),
                                  child: const Text('Done'),
                                ),
                              ),
                            ],
                          ),
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
  }) : max = 2;

  const _DeveloperSelector.count({
    required this.id,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.max = 3,
  }) : labels = const ['0', '1', '2', '3'];

  final String id, label;
  final String? subtitle;
  final List<String> labels;
  final int value, max;
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
              color: ZyraColors.mutedText,
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
          if (constraints.maxWidth < 260 || scale > 1.4) {
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
                : ZyraColors.mutedText,
            disabledForegroundColor: ZyraColors.mutedText.withValues(
              alpha: .35,
            ),
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
