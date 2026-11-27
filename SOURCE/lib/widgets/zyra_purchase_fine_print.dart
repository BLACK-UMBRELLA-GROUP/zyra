import 'package:flutter/material.dart';

import '../data/zyra_membership_catalog.dart';
import '../theme/zyra_text.dart';

/// LOCK 38 purchase disclosure for the detached Founder preview.
///
/// The catalogue owns prices. This table owns purchase words and preview-only
/// actions; none of its links starts a purchase or opens a legal page.
enum ZyraPurchaseOffer {
  seekerOne,
  guardianOne,
  seekerBasic,
  compatibilityUnlocks,
  zyraFamily,
}

class ZyraPurchaseFinePrint extends StatelessWidget {
  const ZyraPurchaseFinePrint({
    super.key,
    required this.offer,
    this.familyMonthlyPence,
    this.onNotice,
    this.canAct,
    this.disclosureColor,
  }) : assert(
         offer != ZyraPurchaseOffer.zyraFamily || familyMonthlyPence != null,
       );

  final ZyraPurchaseOffer offer;
  final int? familyMonthlyPence;
  final ValueChanged<String>? onNotice;
  final bool Function()? canAct;

  /// Q241 opt-in for the actual Basic comparison paragraph only.
  final Color? disclosureColor;

  static const termsNotice = 'The terms of use open here.';
  static const privacyNotice = 'The privacy policy opens here.';
  static const restoreNotice =
      'ZYRA checks your Apple ID for earlier purchases.';
  static const appleNotice = "Apple's subscription sheet opens here.";

  static String copyFor(ZyraPurchaseOffer offer, {int? familyMonthlyPence}) {
    const renewal =
        ' a month, renewing monthly until you cancel. Cancel at least 24 '
        'hours before it renews, in Apple settings.';
    const trial = ' One free trial per person.';
    return switch (offer) {
      ZyraPurchaseOffer.seekerOne =>
        '14 days free, then ${ZyraMembershipCatalog.pounds(ZyraMembershipCatalog.seekerOneMonthlyPence)}$renewal$trial',
      ZyraPurchaseOffer.guardianOne =>
        '14 days free, then ${ZyraMembershipCatalog.pounds(ZyraMembershipCatalog.guardianOneMonthlyPence)}$renewal$trial',
      ZyraPurchaseOffer.seekerBasic =>
        'One payment of ${ZyraMembershipCatalog.pounds(ZyraMembershipCatalog.basicJoiningPence)}, charged to your Apple ID. Not a subscription.',
      ZyraPurchaseOffer.compatibilityUnlocks =>
        'Charged once to your Apple ID. Not a subscription.',
      ZyraPurchaseOffer.zyraFamily =>
        '${ZyraMembershipCatalog.pounds(familyMonthlyPence!)}$renewal',
    };
  }

  void _notice(BuildContext context, String message) {
    if (onNotice case final callback?) {
      callback(message);
    } else {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _link(BuildContext context, String label, String message) =>
      TextButton(
        key: ValueKey('purchase-${label.toLowerCase().replaceAll(' ', '-')}'),
        onPressed: () {
          if (canAct?.call() ?? true) _notice(context, message);
        },
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF845F24),
          minimumSize: const Size(0, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        child: Text(
          label,
          style: ZyraText.body(size: 12, color: const Color(0xFF845F24)),
        ),
      );

  Widget _separator() =>
      Text('·', style: ZyraText.body(size: 12, color: const Color(0xFF845F24)));

  Widget _linkWithSeparator(
    BuildContext context,
    String label,
    String message,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _separator(),
      const SizedBox(width: 2),
      Flexible(child: _link(context, label, message)),
    ],
  );

  @override
  Widget build(BuildContext context) => Column(
    key: ValueKey('purchase-fine-print-${offer.name}'),
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        copyFor(offer, familyMonthlyPence: familyMonthlyPence),
        textAlign: TextAlign.center,
        style: ZyraText.body(
          size: 11.5,
          color:
              disclosureColor ??
              (offer == ZyraPurchaseOffer.compatibilityUnlocks
                  ? const Color(0xFF4F443A)
                  : const Color(0xFF6E6257)),
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        children: [
          _link(context, 'Terms of use', termsNotice),
          _linkWithSeparator(context, 'Privacy policy', privacyNotice),
          if (offer != ZyraPurchaseOffer.compatibilityUnlocks) ...[
            _linkWithSeparator(context, 'Restore purchases', restoreNotice),
          ],
        ],
      ),
    ],
  );
}
