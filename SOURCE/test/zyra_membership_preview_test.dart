import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_membership_catalog.dart';
import 'package:zyra/dev/zyra_membership_preview.dart';
import 'package:zyra/theme/zyra_colors.dart';

import 'visual/baseline_capture_support.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _mount(
  WidgetTester tester, {
  required bool guardian,
  required ZyraMembershipPreviewRecord? record,
  String? familyPayer,
  List<String>? actions,
  double width = 430,
  double height = 932,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: ZyraMembershipPreview(
          guardian: guardian,
          record: record,
          unlocks: 7,
          familyPayer: familyPayer,
          onUnlocks: () => actions?.add('unlocks'),
          onFamily: () => actions?.add('family'),
          onCovered: () => actions?.add('covered'),
          onCompare: () => actions?.add('compare'),
          onRestore: () => actions?.add('restore'),
          onCancel: () => actions?.add('cancel'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _expectReadableText(WidgetTester tester, double width) {
  final page = _key('membership_paid_page');
  for (final element
      in find.descendant(of: page, matching: find.byType(Text)).evaluate()) {
    final text = element.widget as Text;
    expect(text.overflow, isNot(TextOverflow.ellipsis), reason: text.data);
    expect(text.softWrap, isNot(false), reason: text.data);
    final finder = find.byWidget(text);
    final paragraphFinder = find.descendant(
      of: finder,
      matching: find.byType(RichText),
    );
    final paragraph = tester.renderObject<RenderParagraph>(paragraphFinder);
    expect(paragraph.didExceedMaxLines, isFalse, reason: text.data);
    final origin = tester.getTopLeft(paragraphFinder);
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(
        baseOffset: 0,
        extentOffset: paragraph.text.toPlainText().length,
      ),
    );
    for (final box in boxes) {
      expect(
        origin.dx + box.left,
        greaterThanOrEqualTo(19.9),
        reason: text.data,
      );
      expect(
        origin.dx + box.right,
        lessThanOrEqualTo(width - 19.9),
        reason: text.data,
      );
    }
  }
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  for (final guardian in [false, true]) {
    final role = guardian ? 'Guardian' : 'Seeker';
    final plan = guardian
        ? ZyraMembershipCatalog.guardianOneTitle
        : ZyraMembershipCatalog.seekerOneTitle;

    for (final trial in [false, true]) {
      testWidgets('$role billing follows its catalogue and purchase record '
          'with trial $trial', (tester) async {
        await _mount(
          tester,
          guardian: guardian,
          record: ZyraMembershipPreviewRecord(
            date: DateTime(2031, 4, 14),
            trial: trial,
          ),
        );
        final amount = ZyraMembershipCatalog.pounds(
          guardian
              ? ZyraMembershipCatalog.guardianOneMonthlyPence
              : ZyraMembershipCatalog.seekerOneMonthlyPence,
        );
        final billing = tester.widget<Text>(_key('membership_billing'));
        expect(
          billing.data,
          trial
              ? 'Free trial · first payment of $amount on 14 Apr'
              : '${ZyraMembershipCatalog.pounds(guardian ? ZyraMembershipCatalog.guardianOneMonthlyPence : ZyraMembershipCatalog.seekerOneMonthlyPence)} a month · renews 14 Apr',
        );
        expect(
          billing.style!.color,
          trial ? ZyraColors.greenText : ZyraColors.secondaryText,
        );
        expect(find.text(plan), findsOneWidget);
        expect(find.textContaining('6 Dec'), findsNothing);
        expect(
          find.text(
            'Turn off renewal in App Store. You keep $plan until 14 Apr.',
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('$role without a purchase record never guesses dates or trial', (
      tester,
    ) async {
      final actions = <String>[];
      await _mount(tester, guardian: guardian, record: null, actions: actions);
      expect(
        tester.widget<Text>(_key('membership_billing')).data,
        '${ZyraMembershipCatalog.pounds(guardian ? ZyraMembershipCatalog.guardianOneMonthlyPence : ZyraMembershipCatalog.seekerOneMonthlyPence)} a month',
      );
      for (final wording in [
        'Free trial',
        'first payment',
        'renews',
        'until',
      ]) {
        expect(find.textContaining(wording), findsNothing);
      }
      expect(find.text('Turn off renewal in App Store.'), findsOneWidget);
      expect(find.text('Cancel membership'), findsOneWidget);
      await _tap(tester, _key('concept_cancel_membership'));
      expect(actions, ['cancel']);
    });

    testWidgets('$role Family place suppresses trial and cannot cancel', (
      tester,
    ) async {
      final actions = <String>[];
      await _mount(
        tester,
        guardian: guardian,
        record: ZyraMembershipPreviewRecord(
          date: DateTime(2031, 4, 14),
          trial: true,
        ),
        familyPayer: 'Adam',
        actions: actions,
      );
      expect(find.text('Paid by Adam · ZYRA Family'), findsOneWidget);
      expect(find.textContaining('Free trial'), findsNothing);
      expect(find.textContaining('14 Apr'), findsNothing);
      expect(find.text('Covered by Adam’s ZYRA Family'), findsOneWidget);
      expect(
        find.text('Only Adam can change or cancel this place.'),
        findsOneWidget,
      );
      expect(_key('concept_cancel_membership'), findsNothing);
      expect(find.text('Cancel membership'), findsNothing);
      expect(
        find.ancestor(
          of: _key('membership_family_card'),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      if (guardian) expect(find.text('Yes'), findsOneWidget);
      await _tap(tester, _key('membership_family_card'));
      expect(actions, isEmpty);
    });

    testWidgets('$role MORE rows dispatch only their own actions', (
      tester,
    ) async {
      final actions = <String>[];
      await _mount(
        tester,
        guardian: guardian,
        record: ZyraMembershipPreviewRecord(
          date: DateTime(2026, 12, 6),
          freeFamilyPlaces: 4,
        ),
        actions: actions,
      );
      final perks = guardian
          ? [
              'See the Journeys your Seekers allow',
              'Chat in a Journey, when your Seeker allows it',
              'Guardian Circle: read and write',
              'Network, Introductions and Connect with Guardian',
            ]
          : [
              '3 Journey places',
              'Unlimited profiles and every filter',
              'Every Compatibility topic · 3 Unlocks a month',
              '10 Guardians on any plan',
            ];
      for (final perk in perks) {
        expect(find.text(perk), findsOneWidget);
      }
      if (guardian) {
        expect(find.text('Covered by a ZYRA Family?'), findsOneWidget);
        expect(_key('membership_more_unlocks'), findsNothing);
        expect(_key('membership_more_family'), findsNothing);
      } else {
        expect(find.text('7 left'), findsOneWidget);
        expect(find.text('4 free'), findsOneWidget);
        expect(_key('membership_more_covered'), findsNothing);
      }
      final expected = [
        if (guardian) 'covered' else ...['unlocks', 'family'],
        'compare',
        'restore',
        'cancel',
      ];
      for (var i = 0; i < expected.length; i++) {
        final action = expected[i];
        await _tap(
          tester,
          _key(
            action == 'cancel'
                ? 'concept_cancel_membership'
                : 'membership_more_$action',
          ),
        );
        expect(actions, expected.take(i + 1).toList());
      }
    });

    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('$role at 375 points and text scale $scale wraps and keeps '
          'the footer after MORE', (tester) async {
        await _mount(
          tester,
          guardian: guardian,
          record: ZyraMembershipPreviewRecord.sample(),
          width: 375,
          height: 667,
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        _expectReadableText(tester, 375);
        final footer = _key('concept_cancel_membership');
        final restore = _key('membership_more_restore');
        expect(
          tester.getRect(footer).top - tester.getRect(restore).bottom,
          greaterThanOrEqualTo(13.9),
        );
        if (!guardian) {
          for (final (id, label, value) in [
            ('unlocks', 'Compatibility Unlocks', '7 left'),
            ('family', 'ZYRA Family places', '1 free'),
          ]) {
            final row = _key('membership_more_$id');
            final labelRect = tester.getRect(
              find.descendant(of: row, matching: find.text(label)),
            );
            final valueRect = tester.getRect(
              find.descendant(of: row, matching: find.text(value)),
            );
            expect(labelRect.right, lessThanOrEqualTo(valueRect.left + .1));
          }
        }
        await tester.ensureVisible(footer);
        await tester.pumpAndSettle();
        final footerRect = tester.getRect(footer);
        expect(footerRect.top, greaterThanOrEqualTo(0));
        expect(footerRect.bottom, lessThanOrEqualTo(667));
        expect(footer.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
