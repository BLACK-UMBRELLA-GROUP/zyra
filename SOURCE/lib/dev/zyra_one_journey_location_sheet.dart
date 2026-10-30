import 'package:flutter/material.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_tap_feedback.dart';

/// Inline modal inside the admitted preview. A foreign Navigator cover still
/// revokes the caller; this sheet never weakens the host's route admission.
class ZyraOneJourneyLocationSheet extends StatelessWidget {
  const ZyraOneJourneyLocationSheet({
    super.key,
    required this.explain,
    required this.town,
    required this.currentArea,
    required this.canAct,
    required this.onHome,
    required this.onCurrent,
    required this.onContinue,
    required this.onClose,
  });
  final bool explain, currentArea;
  final String town;
  final bool Function() canAct;
  final VoidCallback onHome, onCurrent, onContinue, onClose;

  Text _text(
    String value, {
    double size = 13,
    Color? color,
    TextAlign? align,
    FontWeight weight = FontWeight.w300,
  }) => Text(
    value,
    textAlign: align,
    style: ZyraText.body(
      size: size,
      color: color ?? ZyraColors.ink(.68),
    ).copyWith(fontWeight: weight, height: 1.4, letterSpacing: 0),
  );
  VoidCallback? _tap(BuildContext context, VoidCallback action) =>
      ZyraTapFeedback.onTap(context, () {
        if (canAct()) action();
      });

  Widget _option(BuildContext context, bool area) {
    final selected = area == currentArea;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        key: ValueKey(area ? 'location_current' : 'location_home'),
        onTap: _tap(context, area ? onCurrent : onHome),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ZyraColors.ink(.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? ZyraColors.journeyGold.withValues(alpha: .65)
                  : ZyraColors.ink(.16),
            ),
          ),
          child: Row(
            children: [
              Icon(
                area ? Icons.my_location : Icons.home_outlined,
                size: 20,
                color: ZyraColors.journeyGold,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _text(
                      area ? 'My current area' : 'Home town',
                      size: 15,
                      color: ZyraColors.ink(.95),
                    ),
                    const SizedBox(height: 5),
                    _text(
                      area
                          ? 'Uses your phone’s location, roughly — never your exact spot.'
                          : '$town — from your profile. No permission needed.',
                      size: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 22,
                color: selected ? ZyraColors.journeyGold : ZyraColors.ink(.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlockSemantics(
    child: Stack(
      children: [
        Positioned.fill(
          child: ModalBarrier(
            color: Colors.black.withValues(alpha: .58),
            onDismiss: _tap(context, onClose),
            semanticsLabel: 'Close location choices',
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Semantics(
            scopesRoute: true,
            explicitChildNodes: true,
            namesRoute: true,
            label: explain
                ? 'Use your current area?'
                : 'Where should distance start?',
            child: Container(
              key: const ValueKey('location_sheet_surface'),
              width: double.infinity,
              // Measured live LOCK11 masters at 430 pt: 400 / 332 pt sheets.
              // Larger Text uses natural content height within the scroll cap.
              height: MediaQuery.textScalerOf(context).scale(1) > 1.3
                  ? null
                  : (explain ? 332 : 400),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .9,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2C1F3B), Color(0xFF191123)],
                ),
                border: Border.all(color: ZyraColors.ink(.12)),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(34),
                ),
              ),
              child: SingleChildScrollView(
                key: ValueKey(('location_sheet_scroll', explain)),
                primary: false,
                padding: const EdgeInsets.fromLTRB(21, 10, 21, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: ZyraColors.ink(.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (explain) ...[
                      const Icon(
                        Icons.my_location,
                        size: 38,
                        color: ZyraColors.journeyGold,
                      ),
                      const SizedBox(height: 12),
                      _text(
                        'Use your current area?',
                        size: 21,
                        color: ZyraColors.ink(.95),
                        align: TextAlign.center,
                        weight: FontWeight.w300,
                      ),
                      const SizedBox(height: 12),
                      _text(
                        'ZYRA uses your approximate area only to measure distance in Filters. '
                        'It is never shown on your profile or to anyone else, and you can '
                        'switch it off in Phone access.',
                        size: 12.5,
                        align: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        key: const ValueKey('location_continue'),
                        onPressed: _tap(context, onContinue),
                        style: FilledButton.styleFrom(
                          backgroundColor: ZyraColors.journeyGold,
                          foregroundColor: ZyraColors.luxuryDarkPurple,
                          minimumSize: const Size(44, 52),
                        ),
                        child: _text(
                          'Continue',
                          size: 14,
                          weight: FontWeight.w500,
                          color: ZyraColors.luxuryDarkPurple,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      _text(
                        'Where should distance start?',
                        size: 20,
                        color: ZyraColors.ink(.95),
                        weight: FontWeight.w300,
                      ),
                      const SizedBox(height: 10),
                      _text(
                        'Only used to sort and filter by distance. Nobody else ever sees it.',
                      ),
                      const SizedBox(height: 20),
                      _option(context, false),
                      const SizedBox(height: 10),
                      _option(context, true),
                      const SizedBox(height: 12),
                    ],
                    TextButton(
                      key: ValueKey(
                        explain ? 'location_not_now' : 'filter_origin_done',
                      ),
                      onPressed: _tap(context, onClose),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: _text(
                        explain ? 'Not now' : 'Done',
                        size: 13,
                        color: ZyraColors.ink(.95),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
