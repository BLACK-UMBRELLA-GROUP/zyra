/// Founder-directed catalogue; Basic payment-history amendment 2026-10-18.
///
/// Product information is never purchase proof, an entitlement grant, or a
/// device-timed trial. StoreKit's verified transaction price remains the
/// billing authority when checkout is activated.
enum ZyraMembershipProduct {
  seekerOne,
  seekerBasic,
  guardianOne,
  guardianBasic,
}

/// A payment-history display projection, never a receipt or access grant.
///
/// A trusted, owner-bound membership history source must resolve this value.
/// A current plan, signup choice, compatibility purchase or unpaid trial is
/// not evidence that a membership payment was made. Unresolved history remains
/// [ZyraMembershipPaymentHistory.unknown]; it must not be treated as paid or
/// as a confirmed first payment.
enum ZyraMembershipPaymentHistory { unknown, neverPaid, paidBefore }

class ZyraFamilyQuote {
  final int seekers;
  final int guardians;
  final int members;
  final int discountPercent;
  final int individualMonthlyPence;
  final int formulaMonthlyPence;
  final int savingPence;

  const ZyraFamilyQuote._({
    required this.seekers,
    required this.guardians,
    required this.members,
    required this.discountPercent,
    required this.individualMonthlyPence,
    required this.formulaMonthlyPence,
    required this.savingPence,
  });

  bool get hasMembers => members > 0;

  /// Protected onboarding comparison, calculated from selected role places.
  /// This does not establish unique-person eligibility or a store charge.
  int get introFirstMonthPence =>
      members * ZyraMembershipCatalog.familyIntroMonthPerPlacePence;
}

class ZyraMembershipCatalog {
  ZyraMembershipCatalog._();

  static const trialDays = 14;
  static const checkoutAvailable = false;
  static const familyMaxPerRole = 10;
  static const seekerOneTitle = 'Seeker One';
  static const guardianOneTitle = 'Guardian One';

  /// Available choices are commercial information, never evidence of payment.
  static const products = [
    ZyraMembershipProduct.seekerOne,
    ZyraMembershipProduct.seekerBasic,
    ZyraMembershipProduct.guardianOne,
    ZyraMembershipProduct.guardianBasic,
  ];

  // Founder ruling, 2026-09-24: separate monthly role memberships.
  static const seekerOneMonthlyPence = 2999;
  static const guardianOneMonthlyPence = 1999;
  // First membership payment only; a confirmed previous membership payment
  // means no new Basic joining charge. This is not a monthly subscription.
  static const basicJoiningPence = 499;
  // Founder-requested Family onboarding comparison, not an active store offer.
  static const familyIntroMonthPerPlacePence = 499;

  static bool isBasic(ZyraMembershipProduct product) =>
      product == ZyraMembershipProduct.seekerBasic ||
      product == ZyraMembershipProduct.guardianBasic;

  static const basicTerms =
      'Seeker Basic and Guardian Basic have no monthly subscription. '
      'The £4.99 one-time joining fee applies only if you have never paid '
      'for a ZYRA membership. After a previous confirmed membership payment, '
      'there is no joining fee when choosing Basic. Compatibility Unlock '
      'purchases and unpaid trials do not count as membership payments. '
      'Choosing Basic does not confirm payment or identity verification. '
      'A current or selected plan is not payment history. '
      'Basic does not include a trial.';
  static const guardianBasicTerms =
      'Guardian Basic includes viewing permitted linked Journeys and their '
      'Timeline, with essential relationship, consent, Main Guardian review '
      'and safety controls. Conversation, compatibility answering and Network '
      'access are One features. Membership never creates a Guardian link or '
      'Main Guardian authority.';

  static String pounds(int pence) {
    if (pence < 0) throw RangeError.value(pence, 'pence');
    return '£${pence ~/ 100}.${(pence % 100).toString().padLeft(2, '0')}';
  }

  /// The governed formula price. App Store combinations must use the nearest
  /// supported price point at or above this amount. Once StoreKit is live,
  /// display its verified localised price rather than treating this estimate
  /// as the amount charged.
  static ZyraFamilyQuote familyQuote(int seekers, int guardians) {
    RangeError.checkValueInInterval(seekers, 0, familyMaxPerRole, 'seekers');
    RangeError.checkValueInInterval(
      guardians,
      0,
      familyMaxPerRole,
      'guardians',
    );
    final members = seekers + guardians;
    final discountPercent = ((members - 2) * 5).clamp(0, 40);
    final individualMonthlyPence =
        seekers * seekerOneMonthlyPence + guardians * guardianOneMonthlyPence;
    final formulaMonthlyPence =
        (individualMonthlyPence * (100 - discountPercent) + 50) ~/ 100;
    return ZyraFamilyQuote._(
      seekers: seekers,
      guardians: guardians,
      members: members,
      discountPercent: discountPercent,
      individualMonthlyPence: individualMonthlyPence,
      formulaMonthlyPence: formulaMonthlyPence,
      savingPence: individualMonthlyPence - formulaMonthlyPence,
    );
  }

  static const familyTerms =
      'Choose 0–10 Seeker One and 0–10 Guardian One places. One or two '
      'places use their individual monthly prices. From three places, the '
      'saving rises by five percentage points per place to a maximum of 40% '
      'from ten places onward. All places are billed monthly. Zero places '
      'cannot be purchased.';
  static const familyAvailability =
      'This is an estimate, not checkout. The App Store will show the exact '
      'local monthly price before purchase; it is rounded upward to a '
      'supported price point where required. Family checkout, allocation and '
      'paid access activation are not available yet.';

  // Separate optional purchases, not membership subscriptions.
  static const compatibilitySinglePence = 299;
  static const compatibilityThreePence = 699;
  static const compatibilityFivePence = 999;
  static const compatibilityTerms =
      'Compatibility Unlock is an optional purchase, '
      'charged separately from your membership.';
  static const compatibilityPrices =
      'Compatibility Unlocks: £2.99 for one, £6.99 for three or £9.99 for five.';
  static const compatibilityAvailability =
      'Purchasing unlocks is not available in this build. Existing credits '
      'and previously unlocked access are kept.';

  static String title(ZyraMembershipProduct product) => switch (product) {
    ZyraMembershipProduct.seekerOne => seekerOneTitle,
    ZyraMembershipProduct.seekerBasic => 'Seeker Basic',
    ZyraMembershipProduct.guardianOne => guardianOneTitle,
    ZyraMembershipProduct.guardianBasic => 'Guardian Basic',
  };

  /// Base catalogue terms for a first membership payment, not an individual
  /// member's fee quote. Membership management must use [membershipPrice]
  /// with its separately confirmed payment-history projection.
  static String price(ZyraMembershipProduct product) => switch (product) {
    ZyraMembershipProduct.seekerOne =>
      '${pounds(seekerOneMonthlyPence)} / month',
    ZyraMembershipProduct.seekerBasic => '${pounds(basicJoiningPence)} once',
    ZyraMembershipProduct.guardianOne =>
      '${pounds(guardianOneMonthlyPence)} / month',
    ZyraMembershipProduct.guardianBasic => '${pounds(basicJoiningPence)} once',
  };

  /// A null fee deliberately withholds a quote until history is confirmed.
  /// Zero waives only the joining charge; it does not activate Basic access.
  static int? basicJoiningDuePence(ZyraMembershipPaymentHistory history) =>
      switch (history) {
        ZyraMembershipPaymentHistory.unknown => null,
        ZyraMembershipPaymentHistory.neverPaid => basicJoiningPence,
        ZyraMembershipPaymentHistory.paidBefore => 0,
      };

  static String membershipPrice(
    ZyraMembershipProduct product, {
    ZyraMembershipPaymentHistory history = ZyraMembershipPaymentHistory.unknown,
  }) {
    if (!isBasic(product)) return price(product);
    return switch (history) {
      ZyraMembershipPaymentHistory.unknown => 'Joining fee not confirmed',
      ZyraMembershipPaymentHistory.neverPaid =>
        '${pounds(basicJoiningPence)} once',
      ZyraMembershipPaymentHistory.paidBefore => 'No joining fee',
    };
  }

  static String membershipChoiceSummary(ZyraMembershipPaymentHistory history) =>
      switch (history) {
        ZyraMembershipPaymentHistory.unknown =>
          'Basic has no monthly subscription. The joining fee depends on '
              'confirmed membership payment history. Review your choice '
              'before continuing.',
        ZyraMembershipPaymentHistory.neverPaid =>
          'Choose Basic with a £4.99 one-time joining fee or One with a '
              'monthly subscription. Review your choice before continuing.',
        ZyraMembershipPaymentHistory.paidBefore =>
          'Basic has no joining fee after a previous membership payment, '
              'and no monthly subscription. Choose One for monthly access.',
      };

  static const availability =
      'Membership setup is being prepared. Payments, trial activation and '
      'paid access activation are not available in this build. No payment '
      'will be taken and no trial will start here.';

  /// Paid capability never becomes relationship or Journey authority.
  static const guardianAccessTerms =
      'Guardian One makes paid Guardian features available; it does not '
      'guarantee access to every Journey. A Main Guardian has View and Chat '
      'for every Active Journey while they remain Main. An Additional '
      'Guardian starts with View and Chat enabled for each Active Journey; '
      'the linked Seeker may switch either permission off. Chat requires '
      'View. An accepted Guardian link and all Journey privacy rules still '
      'apply.';

  static const trialTerms =
      'Seeker One includes one 14-day trial per verified person for life, '
      'then continues as a paid monthly subscription unless cancelled. The '
      'trial starts only after identity verification and App Store payment '
      'authorisation succeed. Guardian One and ZYRA Family do not include a '
      'trial. The store will show eligibility, renewal price and cancellation '
      'terms before subscription.';
}
