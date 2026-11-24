import '../../widgets/zyra_developer_title.dart';
import 'package:flutter/material.dart';

import '../../data/zyra_membership_catalog.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_floating_surface.dart';
import '../../widgets/zyra_glass_dialog.dart';
import '../../widgets/zyra_tap_feedback.dart';
import '../../widgets/zyra_purchase_fine_print.dart';
import '../../dev/zyra_guardian_before_pay_preview.dart';

/// LOCK 25. Include only the exact plan differences supported in this build.
class ZyraOneUpgradePage extends StatelessWidget {
  const ZyraOneUpgradePage({
    super.key,
    required this.guardian,
    required this.canContinue,
    required this.onBack,
    this.includesPreviewComparisons = false,
    this.includesProfileVideo = false,
    this.founderPreview = false,
    this.seekerFirstName = 'Adam',
    this.onPurchaseNotice,
    this.childCanAct,
  });

  final bool guardian;
  final bool includesPreviewComparisons;
  final bool includesProfileVideo;
  final bool founderPreview;
  final String seekerFirstName;
  final ValueChanged<String>? onPurchaseNotice;

  /// Owner check for the pushed Before you pay route, where this page is covered.
  final bool Function()? childCanAct;
  final bool Function() canContinue;
  final VoidCallback onBack;

  List<(String, String, String)> get _seekerRows => [
    ('Journey places', '1', '3'),
    ('Browse profiles', '25 every 4 hours', 'Unlimited'),
    if (includesPreviewComparisons) ...[
      ('Compatibility score', 'Overall score', 'Every topic'),
      ('Filters', 'Age and location', 'All filters'),
    ],
    if (includesProfileVideo) ('Profile video', '—', '1 silent video'),
    ('Guardians', '1 on Guardian Basic', 'Any 10'),
    ('Look again at declined profiles', '—', 'Up to 10'),
    ('Chaperoned video calls', '—', 'Coming later'),
  ];

  List<(String, String, String)> get _guardianRows => [
    ('See the Journeys your Seeker allows', '✓', '✓'),
    ('Family Review (Main Guardian)', '✓', '✓'),
    ('Chat in a Journey, when your Seeker allows it', '—', '✓'),
    if (includesPreviewComparisons)
      ('Compatibility score', 'Overall score', 'Every topic'),
    ('Join chaperoned video calls', '—', 'Coming later'),
  ];

  String get _title => guardian
      ? ZyraMembershipCatalog.guardianOneTitle
      : ZyraMembershipCatalog.seekerOneTitle;

  void _continue(BuildContext context) {
    if (!canContinue()) return;
    if (founderPreview) {
      if (guardian) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ZyraGuardianBeforePayPreview(
              seekerFirstName: seekerFirstName,
              canAct: childCanAct ?? canContinue,
              onNotice: onPurchaseNotice,
            ),
          ),
        );
      } else {
        _previewNotice(context, ZyraPurchaseFinePrint.appleNotice);
      }
      return;
    }
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
            style: ZyraText.subtext(color: ZyraColors.secondaryStrong),
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

  void _previewNotice(BuildContext context, String message) {
    if (onPurchaseNotice case final callback?) {
      callback(message);
    } else {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, bounds) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final content = _content(context);
        if (!founderPreview || scale <= 1.2 || bounds.maxHeight >= 800) {
          return content;
        }
        return SingleChildScrollView(
          child: SizedBox(
            height: bounds.maxHeight + 250 * scale,
            child: content,
          ),
        );
      },
    ),
  );

  Widget _content(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (!founderPreview) ...[
              IconButton(
                tooltip: 'Back',
                onPressed: ZyraTapFeedback.onTap(context, onBack),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Semantics(
                header: true,
                child: ZyraDeveloperTitle(
                  child: Text(_title, style: ZyraText.heading(size: 26)),
                ),
              ),
            ),
          ],
        ),
        if (founderPreview) ...[
          Text(
            '${ZyraMembershipCatalog.pounds(guardian ? ZyraMembershipCatalog.guardianOneMonthlyPence : ZyraMembershipCatalog.seekerOneMonthlyPence)} a month · 14 days free to start',
            style: ZyraText.body(size: 13, color: ZyraColors.secondaryText),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: _ComparisonCard(rows: guardian ? _guardianRows : _seekerRows),
        ),
        const SizedBox(height: 12),
        Text(
          guardian
              ? founderPreview
                    ? 'A Seeker can also cover you with a ZYRA Family place.'
                    : 'A Seeker can also cover you with a ZYRA Family place. Cancel any time in Apple settings.'
              : founderPreview
              ? 'You keep everything you have now.'
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: const StadiumBorder(),
            ),
            child: Text(founderPreview ? 'Start 14 days free' : 'Continue'),
          ),
        ),
        if (founderPreview) ...[
          const SizedBox(height: 8),
          ZyraPurchaseFinePrint(
            offer: guardian
                ? ZyraPurchaseOffer.guardianOne
                : ZyraPurchaseOffer.seekerOne,
            onNotice: (message) => _previewNotice(context, message),
            canAct: canContinue,
          ),
        ],
        TextButton(
          onPressed: ZyraTapFeedback.onTap(context, onBack),
          child: const Text('Not now'),
        ),
      ],
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
          builder: (context, constraints) {
            final rowWidth = constraints.maxWidth - 24;
            final stacked = _ComparisonRow.needsStacked(
              context,
              rows,
              rowWidth * .27 - 6,
            );
            final stackedPlanWidth = stacked ? rowWidth / 2 - 6 : null;
            return SingleChildScrollView(
              key: const ValueKey('one-upgrade-comparison'),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: _ComparisonRow(
                            '',
                            'BASIC',
                            'ONE',
                            header: true,
                            stackedPlanWidth: stackedPlanWidth,
                          ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: _ComparisonRow(
                                  label,
                                  basic,
                                  one,
                                  stackedPlanWidth: stackedPlanWidth,
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
          },
        ),
      ),
    ),
  );
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow(
    this.label,
    this.basic,
    this.one, {
    this.header = false,
    this.stackedPlanWidth,
  });

  final String label, basic, one;
  final bool header;
  final double? stackedPlanWidth;

  static TextStyle _basicStyle(bool header) =>
      ZyraText.body(size: header ? 11 : 13, color: ZyraColors.secondaryText);

  static TextStyle _oneStyle(bool header) => ZyraText.body(
    size: header ? 11 : 13,
    color: ZyraColors.goldText,
  ).copyWith(fontWeight: FontWeight.w500);

  static TextStyle _resolvedStyle(BuildContext context, TextStyle style) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    return MediaQuery.boldTextOf(context)
        ? effective.copyWith(fontWeight: FontWeight.bold)
        : effective;
  }

  static bool needsStacked(
    BuildContext context,
    List<(String, String, String)> rows,
    double planWidth,
  ) {
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    try {
      for (final row in [('', 'BASIC', 'ONE'), ...rows]) {
        final header = row.$1.isEmpty;
        for (final (value, style) in [
          (row.$2, _basicStyle(header)),
          (row.$3, _oneStyle(header)),
        ]) {
          for (final word in value.split(RegExp(r'\s+'))) {
            painter.text = TextSpan(
              text: word,
              style: _resolvedStyle(context, style),
            );
            painter.layout();
            if (painter.width > planWidth) return true;
          }
        }
      }
      return false;
    } finally {
      painter.dispose();
    }
  }

  String _wholeWords(BuildContext context, String value, TextStyle style) {
    final width = stackedPlanWidth;
    if (width == null) return value;
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    try {
      final lines = <String>[];
      var line = '';
      for (final word in value.split(RegExp(r'\s+'))) {
        final candidate = line.isEmpty ? word : '$line $word';
        painter.text = TextSpan(
          text: candidate,
          style: _resolvedStyle(context, style),
        );
        painter.layout();
        if (line.isNotEmpty && painter.width > width) {
          lines.add(line);
          line = word;
        } else {
          line = candidate;
        }
      }
      lines.add(line);
      return lines.join('\n');
    } finally {
      painter.dispose();
    }
  }

  Widget _planCell(BuildContext context, String value, TextStyle style) {
    final display = _wholeWords(context, value, style);
    return Expanded(
      flex: stackedPlanWidth == null ? 27 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Text(
          display,
          semanticsLabel: display == value ? null : value,
          textAlign: TextAlign.center,
          softWrap: stackedPlanWidth == null ? null : false,
          overflow: stackedPlanWidth == null ? null : TextOverflow.visible,
          style: style,
        ),
      ),
    );
  }

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
    child: stackedPlanWidth != null && !header
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: ZyraText.body(size: 13)),
              Row(
                children: [
                  _planCell(context, basic, _basicStyle(header)),
                  _planCell(context, one, _oneStyle(header)),
                ],
              ),
            ],
          )
        : Row(
            children: [
              if (stackedPlanWidth == null)
                Expanded(
                  flex: 46,
                  child: Text(label, style: ZyraText.body(size: 13)),
                ),
              _planCell(context, basic, _basicStyle(header)),
              _planCell(context, one, _oneStyle(header)),
            ],
          ),
  );
}
