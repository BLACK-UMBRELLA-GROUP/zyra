import 'package:flutter/material.dart';

import '../data/zyra_membership_catalog.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';
import '../widgets/zyra_developer_title.dart';
import '../widgets/zyra_floating_surface.dart';
import '../widgets/zyra_tap_feedback.dart';
import 'zyra_one_journey_account_presentation.dart';

/// LOCK 42 §3b. Display-only local purchase sample, never receipt authority.
@immutable
class ZyraMembershipPreviewRecord {
  const ZyraMembershipPreviewRecord({
    required this.date,
    this.trial = false,
    this.freeFamilyPlaces = 1,
    this.paidMonths = 0,
  });

  factory ZyraMembershipPreviewRecord.sample() =>
      ZyraMembershipPreviewRecord(date: DateTime(2026, 12, 6), paidMonths: 2);

  final DateTime date;
  final bool trial;
  final int freeFamilyPlaces;
  final int paidMonths;

  String get dateLabel =>
      '${date.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]}';
}

/// Paid-plan page only. The Founder shell owns account and route freshness.
class ZyraMembershipPreview extends StatelessWidget {
  const ZyraMembershipPreview({
    super.key,
    required this.guardian,
    required this.record,
    required this.unlocks,
    required this.onUnlocks,
    required this.onFamily,
    required this.onCovered,
    required this.onCompare,
    required this.onRestore,
    required this.onCancel,
    this.familyPayer,
  });

  final bool guardian;
  final ZyraMembershipPreviewRecord? record;
  final int unlocks;
  final String? familyPayer;
  final VoidCallback onUnlocks, onFamily, onCovered, onCompare, onRestore;
  final VoidCallback onCancel;

  String get _plan => guardian
      ? ZyraMembershipCatalog.guardianOneTitle
      : ZyraMembershipCatalog.seekerOneTitle;
  bool get _trial => familyPayer == null && record?.trial == true;

  String get _billing {
    if (familyPayer case final payer?) return 'Paid by $payer · ZYRA Family';
    final price =
        '${ZyraMembershipCatalog.pounds(guardian ? ZyraMembershipCatalog.guardianOneMonthlyPence : ZyraMembershipCatalog.seekerOneMonthlyPence)} a month';
    final purchase = record;
    if (purchase == null) return price;
    if (purchase.trial) {
      final amount = ZyraMembershipCatalog.pounds(
        guardian
            ? ZyraMembershipCatalog.guardianOneMonthlyPence
            : ZyraMembershipCatalog.seekerOneMonthlyPence,
      );
      return 'Free trial · first payment of $amount on ${purchase.dateLabel}';
    }
    return '$price · renews ${purchase.dateLabel}';
  }

  @override
  Widget build(BuildContext context) => Material(
    key: const ValueKey('membership_paid_page'),
    color: Colors.transparent,
    child: DefaultTextStyle.merge(
      style: const TextStyle(letterSpacing: 0, height: 1.45),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            key: const ValueKey('membership_paid_scroll'),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight - 32),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: ZyraDeveloperTitle(
                        child: Text(
                          'Membership',
                          key: const ValueKey('membership_paid_title'),
                          style: ZyraText.pageTitle(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _planCard(),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 10),
                      child: Text(
                        'MORE',
                        style: ZyraText.body(
                          size: 10.5,
                          color: ZyraColors.secondaryText,
                        ).copyWith(letterSpacing: 1),
                      ),
                    ),
                    _more(),
                    const SizedBox(height: 14),
                    const Spacer(),
                    _footer(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _card(Widget child, {EdgeInsets padding = EdgeInsets.zero}) =>
      ZyraFloatingSurface(
        radius: 16,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: ZyraColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ZyraColors.surfaceBorder),
          ),
          child: child,
        ),
      );

  Widget _planCard() {
    final perks = guardian
        ? const [
            (Icons.show_chart, 'See the Journeys your Seekers allow'),
            (
              Icons.chat_bubble_outline,
              'Chat in a Journey, when your Seeker allows it',
            ),
            (Icons.groups, 'Guardian Circle: read and write'),
            (
              Icons.diversity_3,
              'Network, Introductions and Connect with Guardian',
            ),
          ]
        : const [
            (Icons.people_outline, '3 Journey places'),
            (Icons.search, 'Unlimited profiles and every filter'),
            (Icons.auto_graph, 'Every Compatibility topic · 3 Unlocks a month'),
            (Icons.groups, '10 Guardians on any plan'),
          ];
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ZyraColors.journeyGold.withValues(alpha: .65),
                  ),
                ),
                child: Text(
                  'ONE',
                  style: ZyraText.body(
                    size: 11,
                    color: ZyraColors.goldText,
                  ).copyWith(letterSpacing: 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plan,
                      style: ZyraText.body(
                        size: 21,
                      ).copyWith(fontWeight: FontWeight.w300),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _billing,
                      key: const ValueKey('membership_billing'),
                      style: ZyraText.body(
                        size: 12.5,
                        color: _trial
                            ? ZyraColors.greenText
                            : ZyraColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: ZyraColors.divider),
          const SizedBox(height: 4),
          for (var i = 0; i < perks.length; i++) ...[
            if (i > 0) Divider(height: 1, color: ZyraColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(perks[i].$1, size: 20, color: ZyraColors.journeyGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(perks[i].$2, style: ZyraText.body(size: 14)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
    );
  }

  Widget _more() => _card(
    Column(
      children: [
        if (!guardian) ...[
          _row(
            'Compatibility Unlocks',
            'unlocks',
            onUnlocks,
            value: '$unlocks left',
          ),
          _row(
            'ZYRA Family places',
            'family',
            onFamily,
            value: record == null ? null : '${record!.freeFamilyPlaces} free',
          ),
        ] else
          _row(
            'Covered by a ZYRA Family?',
            'covered',
            onCovered,
            value: familyPayer == null ? null : 'Yes',
          ),
        _row('Compare plans', 'compare', onCompare),
        _row('Restore purchases', 'restore', onRestore),
      ],
    ),
  );

  Widget _row(String label, String id, VoidCallback action, {String? value}) =>
      ZyraSettingsRow(
        key: ValueKey('membership_more_$id'),
        label: label,
        value: value,
        smooth: false,
        onTap: action,
        wrapValue: true,
        valueSize: 13.5,
        verticalPadding: 14,
        horizontalPadding: 22,
      );

  Widget _footer(BuildContext context) {
    final payer = familyPayer;
    final covered = payer != null;
    final ink = covered ? ZyraColors.journeyGold : ZyraColors.destructive;
    final purchase = record;
    final title = covered
        ? 'Covered by $payer’s ZYRA Family'
        : 'Cancel membership';
    final detail = covered
        ? 'Only $payer can change or cancel this place.'
        : 'Turn off renewal in App Store.${purchase == null ? '' : ' You keep $_plan until ${purchase.dateLabel}.'}';
    final content = Container(
      key: ValueKey(
        covered ? 'membership_family_card' : 'concept_cancel_membership',
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ink.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(covered ? Icons.groups : Icons.close, size: 20, color: ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ZyraText.body(
                    size: 15,
                    color: covered
                        ? ZyraColors.espresso
                        : ZyraColors.dangerTextStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: ZyraText.body(
                    size: 12,
                    color: ZyraColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (!covered) ...[
            const SizedBox(width: 10),
            Icon(Icons.chevron_right, size: 18, color: ZyraColors.ink(.3)),
          ],
        ],
      ),
    );
    if (covered) return content;
    return InkWell(
      onTap: ZyraTapFeedback.onTap(context, onCancel),
      borderRadius: BorderRadius.circular(18),
      child: content,
    );
  }
}
