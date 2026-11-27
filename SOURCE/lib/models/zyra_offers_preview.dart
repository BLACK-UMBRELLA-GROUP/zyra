import 'package:flutter/foundation.dart';

import '../data/zyra_membership_catalog.dart';

enum ZyraRetentionMode {
  growth('Growth', 3, 6),
  normal('Normal', 1, 12);

  const ZyraRetentionMode(this.label, this.discountMonths, this.waitMonths);

  final String label;
  final int discountMonths, waitMonths;
}

enum ZyraPreviewEid {
  none('None'),
  fitr('Eid al-Fitr'),
  adha('Eid al-Adha');

  const ZyraPreviewEid(this.label);

  final String label;
}

/// Local Founder preview inputs. No entitlement, payment or live draw uses them.
@immutable
class ZyraPreviewOfferChoices {
  const ZyraPreviewOfferChoices({
    this.retentionMode = ZyraRetentionMode.growth,
    this.eid = ZyraPreviewEid.none,
    this.ramadan = false,
  });

  final ZyraRetentionMode retentionMode;
  final ZyraPreviewEid eid;
  final bool ramadan;

  ZyraPreviewOfferChoices copyWith({
    ZyraRetentionMode? retentionMode,
    ZyraPreviewEid? eid,
    bool? ramadan,
  }) => ZyraPreviewOfferChoices(
    retentionMode: retentionMode ?? this.retentionMode,
    eid: eid ?? this.eid,
    ramadan: ramadan ?? this.ramadan,
  );
}

@immutable
class ZyraRetentionOfferPreview {
  const ZyraRetentionOfferPreview({required this.mode, required this.guardian});

  final ZyraRetentionMode mode;
  final bool guardian;

  int get fullPrice => guardian
      ? ZyraMembershipCatalog.guardianOneMonthlyPence
      : ZyraMembershipCatalog.seekerOneMonthlyPence;
  String get fullAmount => ZyraMembershipCatalog.pounds(fullPrice);
  String get halfAmount => ZyraMembershipCatalog.pounds(fullPrice ~/ 2);
  bool get growth => mode == ZyraRetentionMode.growth;
  String get title =>
      growth ? 'Half price for 3 months?' : 'Stay for half price?';
  String get amountLine => growth
      ? '$halfAmount a month for the next 3 months.'
      : 'Your next month is $halfAmount instead of $fullAmount.';
  String get afterLine => 'After that it’s $fullAmount a month, as now.';
  String get timing => growth ? 'once every 6 months' : 'once a year';
  String get stayLabel => 'Stay for $halfAmount${growth ? ' a month' : ''}';

  bool isActive({required DateTime now, required DateTime accepted}) =>
      now.isBefore(_calendarMonthsAfter(accepted, mode.discountMonths));

  bool isEligible({
    required bool trial,
    required int paidMonths,
    required DateTime now,
    DateTime? lastAccepted,
  }) =>
      !trial &&
      paidMonths >= 2 &&
      (lastAccepted == null ||
          !now.isBefore(_calendarMonthsAfter(lastAccepted, mode.waitMonths)));
}

DateTime _calendarMonthsAfter(DateTime time, int months) {
  final date = time.toUtc();
  final month = date.month + months;
  final lastDay = DateTime.utc(date.year, month + 1, 0).day;
  return DateTime.utc(
    date.year,
    month,
    date.day > lastDay ? lastDay : date.day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
}

ZyraEidGiftPreview? zyraEidGiftPreview({
  required ZyraPreviewEid eid,
  required bool guardian,
  required bool one,
  required bool paid,
}) {
  if (eid == ZyraPreviewEid.none || (one && !paid)) return null;
  if (!one) {
    return guardian
        ? const ZyraEidGiftPreview(
            '3 days of Guardian One',
            'For 3 days from Eid day you can chat in your Seekers’ Journeys and write in the Guardian Circle. It stops by itself — nothing to pay.',
          )
        : const ZyraEidGiftPreview(
            '1 Compatibility Unlock',
            'A small Eid gift. Use it on your Journey — see how you match on one topic.',
          );
  }
  if (!guardian && eid == ZyraPreviewEid.fitr) {
    return const ZyraEidGiftPreview(
      '3 Compatibility Unlocks',
      'Added to your account. Use them on any Journey, any time.',
    );
  }
  final plan = guardian ? 'Guardian One' : 'Seeker One';
  final fullPrice = guardian
      ? ZyraMembershipCatalog.guardianOneMonthlyPence
      : ZyraMembershipCatalog.seekerOneMonthlyPence;
  final full = ZyraMembershipCatalog.pounds(fullPrice);
  final discount = ZyraMembershipCatalog.pounds(fullPrice * 3 ~/ 4);
  return ZyraEidGiftPreview(
    '25% off your next month',
    'Your next $plan payment is $discount instead of $full. Nothing to do — it applies by itself.',
    appliesDiscount: true,
  );
}

@immutable
class ZyraEidGiftPreview {
  const ZyraEidGiftPreview(
    this.title,
    this.detail, {
    this.appliesDiscount = false,
  });
  final String title, detail;
  final bool appliesDiscount;
}
