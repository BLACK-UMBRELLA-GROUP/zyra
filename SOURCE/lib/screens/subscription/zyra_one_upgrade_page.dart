import 'package:flutter/material.dart';

import '../../data/zyra_membership_catalog.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_floating_surface.dart';
import '../../widgets/zyra_glass_dialog.dart';
import '../../widgets/zyra_tap_feedback.dart';

/// LOCK 25. Include only the exact plan differences supported in this build.
class ZyraOneUpgradePage extends StatelessWidget {
  const ZyraOneUpgradePage({
    super.key,
    required this.guardian,
    required this.canContinue,
    required this.onBack,
  });

  final bool guardian;
  final bool Function() canContinue;
  final VoidCallback onBack;

  static const _seekerRows = [
    ('Journey places', '1', '3'),
    ('Browse profiles', '25 every 4 hours', 'Unlimited'),
    ('Guardians', '1 on Guardian Basic', 'Any 10'),
    ('Look again at declined profiles', '—', 'Up to 10'),
    ('Chaperoned video calls', '—', 'Coming later'),
  ];

  static const _guardianRows = [
    ('See the Journeys your Seeker allows', '✓', '✓'),
    ('Family Review (Main Guardian)', '✓', '✓'),
    ('Chat in a Journey', '—', '✓'),
    ('Join chaperoned video calls', '—', 'Coming later'),
  ];

  String get _title => guardian
      ? ZyraMembershipCatalog.guardianOneTitle
      : ZyraMembershipCatalog.seekerOneTitle;

  void _continue(BuildContext context) {
    if (!canContinue()) return;
    // The current catalogue has no purchasable store product. Keep its
    // unavailable path and omit both price and introductory offer claims.
    showZyraGlassDialog<void>(
      context: context,
      builder: (dialogContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_title, style: ZyraText.heading(size: 18)),
          const SizedBox(height: 8),
          Text(
            ZyraMembershipCatalog.availability,
            textAlign: TextAlign.center,
            style: ZyraText.subtext(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (ModalRoute.of(dialogContext)?.isCurrent ?? false) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: ZyraTapFeedback.onTap(context, onBack),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(_title, style: ZyraText.heading(size: 26)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _ComparisonCard(
              rows: guardian ? _guardianRows : _seekerRows,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            guardian
                ? 'A Seeker can also cover you with a ZYRA Family place. Cancel any time in Apple settings.'
                : 'You keep everything you have now. Cancel any time in Apple settings.',
            style: ZyraText.subtext(size: 12, color: ZyraColors.secondaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ZyraFloatingSurface(
            gold: true,
            radius: 28,
            child: FilledButton(
              key: const ValueKey('one-upgrade-continue'),
              onPressed: ZyraTapFeedback.onTap(
                context,
                () => _continue(context),
                canAct: canContinue,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: ZyraColors.primaryAction,
                foregroundColor: ZyraColors.espresso,
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: const StadiumBorder(),
              ),
              child: const Text('Continue'),
            ),
          ),
          TextButton(
            onPressed: ZyraTapFeedback.onTap(context, onBack),
            child: const Text('Not now'),
          ),
        ],
      ),
    ),
  );
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.rows});

  final List<(String, String, String)> rows;

  @override
  Widget build(BuildContext context) => ZyraFloatingSurface(
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: ZyraColors.cardSurface,
        border: Border.all(color: ZyraColors.surfaceBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            key: const ValueKey('one-upgrade-comparison'),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: _ComparisonRow('', 'BASIC', 'ONE', header: true),
                      ),
                      for (final (label, basic, one) in rows)
                        Expanded(
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: ZyraColors.divider),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: _ComparisonRow(label, basic, one),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow(this.label, this.basic, this.one, {this.header = false});

  final String label, basic, one;
  final bool header;

  String _readable(String value) => switch (value) {
    '✓' => 'Included',
    '—' => 'Unavailable',
    _ => value,
  };

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    excludeSemantics: !header,
    label: header
        ? null
        : '$label. Basic, ${_readable(basic)}. One, ${_readable(one)}.',
    child: Row(
      children: [
        Expanded(flex: 46, child: Text(label, style: ZyraText.body(size: 13))),
        Expanded(
          flex: 27,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              basic,
              textAlign: TextAlign.center,
              style: ZyraText.body(
                size: header ? 11 : 13,
                color: ZyraColors.secondaryText,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 27,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              one,
              textAlign: TextAlign.center,
              style: ZyraText.body(
                size: header ? 11 : 13,
                color: ZyraColors.goldText,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    ),
  );
}
