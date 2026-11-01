// LOCK 8 V6. Display facts and leased actions supplied by the admitted shell.
import 'package:flutter/material.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';
import '../widgets/zyra_journey_icon.dart';

class ZyraGuardianSeekerPage extends StatelessWidget {
  const ZyraGuardianSeekerPage({
    super.key,
    required this.name,
    required this.gender,
    required this.main,
    required this.linkedDate,
    required this.journeys,
    required this.requests,
    required this.currentJourney,
    required this.onJourney,
    required this.onCircle,
  });
  final String name, gender, linkedDate, journeys, requests;
  final bool main;
  final String? currentJourney;
  final VoidCallback? onJourney;
  final VoidCallback onCircle;

  Text _text(String value, {bool muted = false, double size = 14}) => Text(
    value,
    style: ZyraText.body(
      size: size,
      color: muted ? ZyraColors.ink(.55) : ZyraColors.foreground,
    ).copyWith(height: 1.45),
  );

  Widget _card(Widget child, String key) => ZyraFloatingSurface(
    radius: 20,
    child: Container(
      key: ValueKey(key),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZyraColors.surfaceFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ZyraColors.surfaceBorder),
      ),
      child: child,
    ),
  );

  Widget _fact(String label, Widget value, bool expanded) {
    if (expanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _text(label, muted: true),
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerRight, child: value),
          ],
        ),
      );
    }
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _text(label, muted: true),
          const SizedBox(width: 12),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
    return Expanded(child: Center(child: row));
  }

  Widget _divider() => Divider(height: 1, color: ZyraColors.surfaceBorder);

  Widget _access(bool expanded) => _card(
    Column(
      mainAxisSize: expanded ? MainAxisSize.min : MainAxisSize.max,
      children: [
        _fact(
          'Status',
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '✓ Active',
                  style: TextStyle(color: ZyraColors.goldText),
                ),
                TextSpan(text: ' · linked $linkedDate'),
              ],
            ),
            style: ZyraText.body(size: 14).copyWith(height: 1.45),
          ),
          expanded,
        ),
        _divider(),
        _fact(
          'Role',
          _text(main ? 'Main Guardian' : 'Additional Guardian'),
          expanded,
        ),
        _divider(),
        _fact('Journeys', _text(journeys), expanded),
        _divider(),
        _fact('Journey requests', _text(requests), expanded),
        _divider(),
        _fact('Past summaries', _text('Not shared'), expanded),
      ],
    ),
    'guardian_seeker_access',
  );

  Widget _target(
    BuildContext context,
    String label,
    String key,
    Widget icon,
    VoidCallback action, {
    String? detail,
  }) => InkWell(
    key: ValueKey(key),
    onTap: ZyraTapFeedback.onTap(context, action),
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _text(label),
                if (detail != null) ...[
                  const SizedBox(height: 3),
                  _text(detail, size: 12, muted: true),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 20, color: ZyraColors.ink(.3)),
        ],
      ),
    ),
  );

  Widget _targets(BuildContext context) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (currentJourney != null && onJourney != null)
          _target(
            context,
            'Current Journey',
            'guardian_journey',
            ZyraJourneyIcon(size: 22, color: ZyraColors.journeyGold),
            onJourney!,
            detail: currentJourney,
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _text('No current Journey', muted: true),
          ),
        Padding(padding: const EdgeInsets.only(left: 38), child: _divider()),
        _target(
          context,
          '$name’s Guardian Circle',
          'guardian_circle',
          Icon(Icons.people_outline, size: 22, color: ZyraColors.journeyGold),
          onCircle,
        ),
      ],
    ),
    'guardian_seeker_targets',
  );

  Widget _head() => Column(
    children: [
      Container(
        key: const ValueKey('guardian_seeker_monogram'),
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ZyraColors.journeyGold),
        ),
        alignment: Alignment.center,
        child: Text(
          name.characters.firstOrNull ?? '',
          textScaler: TextScaler.noScaling,
          style: ZyraText.heading(size: 40, color: ZyraColors.journeyGold),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        name,
        textAlign: TextAlign.center,
        style: ZyraText.heading(size: 24).copyWith(fontWeight: FontWeight.w300),
      ),
      const SizedBox(height: 6),
      Text(
        main
            ? 'YOU ARE ${gender.toLowerCase() == 'female' ? 'HER' : 'HIS'} MAIN GUARDIAN'
            : 'YOU ARE AN ADDITIONAL GUARDIAN',
        textAlign: TextAlign.center,
        style: ZyraText.body(
          size: 11,
          color: ZyraColors.goldText,
        ).copyWith(letterSpacing: 1.1, height: 1.45),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final expanded =
            MediaQuery.textScalerOf(context).scale(14) > 16 ||
            constraints.maxWidth < 360 ||
            constraints.maxHeight < 700;
        if (expanded) {
          return ZyraShadowScrollView(
            key: const PageStorageKey('guardian_seeker_scroll'),
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 110),
            child: Column(
              children: [
                _head(),
                const SizedBox(height: 20),
                _access(true),
                const SizedBox(height: 16),
                _targets(context),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 75, 22, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _head(),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, cards) {
                    // V6 cards grow 5:2 above their content heights.
                    final free = (cards.maxHeight - 16 - 292 - 144).clamp(
                      0.0,
                      double.infinity,
                    );
                    return Column(
                      children: [
                        SizedBox(
                          height: 292 + free * 5 / 7,
                          child: _access(false),
                        ),
                        const SizedBox(height: 16),
                        Expanded(child: _targets(context)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
