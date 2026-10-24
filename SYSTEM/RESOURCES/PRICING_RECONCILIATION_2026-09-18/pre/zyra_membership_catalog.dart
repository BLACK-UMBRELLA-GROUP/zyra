/// Founder-directed catalogue, revised 2026-09-18. Product information is never
/// purchase proof, an entitlement grant, or a device-timed trial.
enum ZyraMembershipProduct {
  seekerOne,
  seekerBasic,
  guardianOne,
  guardianBasic,
}

class ZyraMembershipCatalog {
  ZyraMembershipCatalog._();

  static const trialDays = 14;
  static const checkoutAvailable = false;
  static const products = ZyraMembershipProduct.values;

  // Separate optional purchases, not additional membership subscriptions.
  // Founder clarification, 2026-09-13. No grant or checkout is performed here.
  static const compatibilityTerms =
      'Compatibility Unlock and Unlock Plus are separate optional purchases, '
      'charged separately from your membership.';
  static const compatibilityPrices =
      'Compatibility Unlock: £1.99 each or £7.99 for five.\n'
      'Unlock Plus: £2.99 each or £9.99 for five.';
  static const compatibilityAvailability =
      'Purchasing unlocks is not available in this build. Existing credits '
      'and previously unlocked access are kept.';

  static String title(ZyraMembershipProduct product) => switch (product) {
    ZyraMembershipProduct.seekerOne => 'ZYRA One — Seeker',
    ZyraMembershipProduct.seekerBasic => 'Seeker Basic',
    ZyraMembershipProduct.guardianOne => 'ZYRA One — Guardian',
    ZyraMembershipProduct.guardianBasic => 'Guardian Basic',
  };

  static String price(ZyraMembershipProduct product) => switch (product) {
    ZyraMembershipProduct.seekerOne => '£29.99 / month',
    ZyraMembershipProduct.seekerBasic => '£9.99 one-time',
    ZyraMembershipProduct.guardianOne => '£19.99 / month',
    ZyraMembershipProduct.guardianBasic => '£9.99 one-time',
  };

  static const availability =
      'Membership setup is being prepared. Payments, trial activation and '
      'paid access activation are not available in this build. No payment '
      'will be taken and no trial will start here.';

  /// Paid capability never becomes relationship or Journey authority.
  static const guardianAccessTerms =
      'Guardian One makes paid features available; it does not guarantee '
      'access to every Journey. For an Additional Guardian, the linked '
      'Seeker chooses View and Chat access for each Journey and may withdraw '
      'either permission. A Main Guardian\'s View and plan-enabled Chat access '
      'cannot be switched off while they remain Main. An accepted Guardian '
      'link and all Journey privacy rules still apply.';

  static const trialTerms =
      'The planned ZYRA One — Seeker membership begins with a 14-day trial, '
      'then a paid subscription. Verification must be completed before trial '
      'activation. A Guardian trial has not been approved. The store will '
      'show eligibility, renewal price and cancellation terms before you '
      'choose to subscribe.';
}
