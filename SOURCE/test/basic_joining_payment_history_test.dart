import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/help_content.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';

void main() {
  const basicProducts = [
    ZyraMembershipProduct.seekerBasic,
    ZyraMembershipProduct.guardianBasic,
  ];

  test('unknown history withholds a fee rather than guessing paid or new', () {
    expect(
      ZyraMembershipCatalog.basicJoiningDuePence(
        ZyraMembershipPaymentHistory.unknown,
      ),
      isNull,
    );
    for (final product in basicProducts) {
      expect(
        ZyraMembershipCatalog.membershipPrice(product),
        'Joining fee not confirmed',
      );
      expect(
        ZyraMembershipCatalog.membershipPrice(
          product,
          history: ZyraMembershipPaymentHistory.unknown,
        ),
        isNot(anyOf('£4.99 once', 'No joining fee')),
      );
    }
  });

  test('confirmed first membership payment keeps the £4.99 once charge', () {
    expect(
      ZyraMembershipCatalog.basicJoiningDuePence(
        ZyraMembershipPaymentHistory.neverPaid,
      ),
      499,
    );
    for (final product in basicProducts) {
      expect(
        ZyraMembershipCatalog.membershipPrice(
          product,
          history: ZyraMembershipPaymentHistory.neverPaid,
        ),
        '£4.99 once',
      );
    }
  });

  test(
    'confirmed previous membership payment waives either Basic joining fee',
    () {
      expect(
        ZyraMembershipCatalog.basicJoiningDuePence(
          ZyraMembershipPaymentHistory.paidBefore,
        ),
        0,
      );
      for (final product in basicProducts) {
        expect(
          ZyraMembershipCatalog.membershipPrice(
            product,
            history: ZyraMembershipPaymentHistory.paidBefore,
          ),
          'No joining fee',
        );
      }
    },
  );

  test('history never changes One prices or the base signup catalogue', () {
    for (final history in ZyraMembershipPaymentHistory.values) {
      expect(
        ZyraMembershipCatalog.membershipPrice(
          ZyraMembershipProduct.seekerOne,
          history: history,
        ),
        '£29.99 / month',
      );
      expect(
        ZyraMembershipCatalog.membershipPrice(
          ZyraMembershipProduct.guardianOne,
          history: history,
        ),
        '£19.99 / month',
      );
    }
    for (final product in basicProducts) {
      expect(ZyraMembershipCatalog.price(product), '£4.99 once');
    }
    expect(ZyraMembershipCatalog.basicJoiningPence, 499);
    expect(ZyraMembershipCatalog.checkoutAvailable, isFalse);
    expect(ZyraMembershipCatalog.trialDays, 14);
    expect(ZyraMembershipCatalog.compatibilitySinglePence, 299);
    expect(ZyraMembershipCatalog.compatibilityFivePence, 999);
    final family = ZyraMembershipCatalog.familyQuote(2, 1);
    expect(family.formulaMonthlyPence, 7597);
    expect(family.introFirstMonthPence, 1497);
  });

  test('choice summaries distinguish unknown first and previous payments', () {
    final unknown = ZyraMembershipCatalog.membershipChoiceSummary(
      ZyraMembershipPaymentHistory.unknown,
    );
    expect(unknown, contains('confirmed membership payment history'));
    expect(unknown, isNot(contains('£4.99')));
    expect(unknown, isNot(contains('no joining fee')));
    final first = ZyraMembershipCatalog.membershipChoiceSummary(
      ZyraMembershipPaymentHistory.neverPaid,
    );
    expect(first, contains('£4.99 one-time joining fee'));
    final paid = ZyraMembershipCatalog.membershipChoiceSummary(
      ZyraMembershipPaymentHistory.paidBefore,
    );
    expect(
      paid,
      contains('no joining fee after a previous membership payment'),
    );
    expect(paid, contains('no monthly subscription'));
    expect(paid, isNot(contains('£4.99')));
  });

  test('terms exclude compatibility and unpaid trials from the fee waiver', () {
    const terms = ZyraMembershipCatalog.basicTerms;
    expect(terms, contains('£4.99 one-time joining fee applies only'));
    expect(terms, contains('previous confirmed membership payment'));
    expect(terms, contains('Compatibility Unlock purchases and unpaid trials'));
    expect(terms, contains('do not count as membership payments'));
    expect(
      terms,
      contains('A current or selected plan is not payment history'),
    );
    expect(terms, contains('Choosing Basic does not confirm payment'));
    expect(terms, contains('no monthly subscription'));
    expect(ZyraMembershipCatalog.availability, contains('No payment'));
  });

  test(
    'Help shares the waiver without claiming automatic Basic activation',
    () {
      final answer = zyraHelpCategories
          .expand((category) => category.entries)
          .singleWhere((entry) => entry.question == 'What does ZYRA cost?')
          .answer;
      expect(answer, contains(ZyraMembershipCatalog.basicTerms));
      expect(answer, contains('does not require another joining fee'));
      expect(
        answer,
        contains('Unlock purchases and unpaid trials do not waive'),
      );
      expect(answer, contains('Payment history and Basic access still need'));
      expect(
        answer,
        contains('subscription expiry alone is not payment proof'),
      );
      expect(
        answer,
        isNot(contains('fee must have been separately confirmed')),
      );
      expect(answer, contains(ZyraMembershipCatalog.familyTerms));
      expect(answer, contains(ZyraMembershipCatalog.guardianAccessTerms));
    },
  );

  test(
    'One feature guidance also offers Basic without another joining fee',
    () {
      final answer = zyraHelpCategories
          .expand((category) => category.entries)
          .singleWhere(
            (entry) =>
                entry.question ==
                'What do Seeker One and Guardian One include?',
          )
          .answer;
      expect(answer, contains('Basic with no new joining fee'));
      expect(answer, contains('Basic access must still be confirmed'));
      expect(answer, contains('subscription expiry alone'));
      expect(
        answer,
        contains('A membership change does not erase relationships'),
      );
    },
  );
}
