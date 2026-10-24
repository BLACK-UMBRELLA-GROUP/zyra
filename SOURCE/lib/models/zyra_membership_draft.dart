import '../data/zyra_membership_catalog.dart';

/// Navigation and unsubmitted choices only. Never a receipt or access grant.
enum ZyraMembershipSection { current, seeker, guardian, family, unlocks }

enum ZyraMembershipReviewKind { individual, family }

bool _isSeekerProduct(ZyraMembershipProduct product) =>
    product == ZyraMembershipProduct.seekerOne ||
    product == ZyraMembershipProduct.seekerBasic;

/// A defensive, immutable draft that a route owner can retain across review.
class ZyraMembershipDraft {
  final ZyraMembershipSection section;
  final int seekerPage;
  final int guardianPage;
  final int familySeekers;
  final int familyGuardians;
  final Set<ZyraMembershipProduct> selectedProducts;

  ZyraMembershipDraft({
    this.section = ZyraMembershipSection.seeker,
    this.seekerPage = 0,
    this.guardianPage = 0,
    this.familySeekers = 0,
    this.familyGuardians = 0,
    Iterable<ZyraMembershipProduct> selectedProducts = const [],
  }) : selectedProducts = Set.unmodifiable(_onePerRole(selectedProducts)) {
    RangeError.checkValueInInterval(seekerPage, 0, 1, 'seekerPage');
    RangeError.checkValueInInterval(guardianPage, 0, 1, 'guardianPage');
    ZyraMembershipCatalog.familyQuote(familySeekers, familyGuardians);
  }

  static Set<ZyraMembershipProduct> _onePerRole(
    Iterable<ZyraMembershipProduct> products,
  ) {
    final result = <ZyraMembershipProduct>{};
    for (final product in products) {
      result.removeWhere(
        (other) => _isSeekerProduct(other) == _isSeekerProduct(product),
      );
      result.add(product);
    }
    return result;
  }

  int get page => switch (section) {
    ZyraMembershipSection.seeker => seekerPage,
    ZyraMembershipSection.guardian => guardianPage,
    ZyraMembershipSection.current ||
    ZyraMembershipSection.family ||
    ZyraMembershipSection.unlocks => 0,
  };

  ZyraFamilyQuote get familyQuote =>
      ZyraMembershipCatalog.familyQuote(familySeekers, familyGuardians);

  ZyraMembershipDraft copyWith({
    ZyraMembershipSection? section,
    int? seekerPage,
    int? guardianPage,
    int? familySeekers,
    int? familyGuardians,
    Iterable<ZyraMembershipProduct>? selectedProducts,
  }) => ZyraMembershipDraft(
    section: section ?? this.section,
    seekerPage: seekerPage ?? this.seekerPage,
    guardianPage: guardianPage ?? this.guardianPage,
    familySeekers: familySeekers ?? this.familySeekers,
    familyGuardians: familyGuardians ?? this.familyGuardians,
    selectedProducts: selectedProducts ?? this.selectedProducts,
  );

  ZyraMembershipDraft selectProduct(
    ZyraMembershipProduct product, {
    Set<ZyraMembershipProduct> currentProducts = const {},
  }) {
    final next = selectedProducts.toSet()
      ..removeWhere(
        (other) => _isSeekerProduct(other) == _isSeekerProduct(product),
      );
    if (!currentProducts.contains(product)) next.add(product);
    return copyWith(selectedProducts: next);
  }

  ZyraMembershipDraft removeRoleSelection(ZyraMembershipSection role) =>
      copyWith(
        selectedProducts: selectedProducts.where(
          (product) => switch (role) {
            ZyraMembershipSection.seeker => !_isSeekerProduct(product),
            ZyraMembershipSection.guardian => _isSeekerProduct(product),
            ZyraMembershipSection.current ||
            ZyraMembershipSection.family ||
            ZyraMembershipSection.unlocks => true,
          },
        ),
      );

  @override
  bool operator ==(Object other) =>
      other is ZyraMembershipDraft &&
      section == other.section &&
      seekerPage == other.seekerPage &&
      guardianPage == other.guardianPage &&
      familySeekers == other.familySeekers &&
      familyGuardians == other.familyGuardians &&
      selectedProducts.length == other.selectedProducts.length &&
      selectedProducts.containsAll(other.selectedProducts);

  @override
  int get hashCode => Object.hash(
    section,
    seekerPage,
    guardianPage,
    familySeekers,
    familyGuardians,
    Object.hashAllUnordered(selectedProducts),
  );
}

/// Mutually exclusive review payloads. These never authorise store activity.
class ZyraMembershipReviewRequest {
  final ZyraMembershipReviewKind kind;
  final Set<ZyraMembershipProduct> products;
  final ZyraFamilyQuote? familyQuote;

  ZyraMembershipReviewRequest._({
    required this.kind,
    Iterable<ZyraMembershipProduct> products = const [],
    this.familyQuote,
  }) : products = Set.unmodifiable(products);

  static ZyraMembershipReviewRequest? fromDraft(
    ZyraMembershipDraft draft, {
    required Set<ZyraMembershipProduct> currentProducts,
    required ZyraMembershipPaymentHistory paymentHistory,
  }) {
    if (draft.section == ZyraMembershipSection.current ||
        draft.section == ZyraMembershipSection.unlocks) {
      return null;
    }
    if (draft.section == ZyraMembershipSection.family) {
      final quote = draft.familyQuote;
      return quote.hasMembers
          ? ZyraMembershipReviewRequest._(
              kind: ZyraMembershipReviewKind.family,
              familyQuote: quote,
            )
          : null;
    }
    final pending = draft.selectedProducts.where(
      (product) =>
          !currentProducts.contains(product) &&
          (!ZyraMembershipCatalog.isBasic(product) ||
              paymentHistory != ZyraMembershipPaymentHistory.unknown),
    );
    final products = pending.toSet();
    return products.isEmpty
        ? null
        : ZyraMembershipReviewRequest._(
            kind: ZyraMembershipReviewKind.individual,
            products: products,
          );
  }
}
