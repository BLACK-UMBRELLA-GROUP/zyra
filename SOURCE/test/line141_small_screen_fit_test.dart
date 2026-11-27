import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/widgets/zyra_reference_label.dart';

import 'visual/baseline_capture_support.dart';

RenderParagraph _paragraph(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: text, matching: find.byType(RichText)),
    );

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null, useSystemSymbolFont: false));
  tearDownAll(baselineTearDown);
  testWidgets(
    'Long Journey request and Profile names wrap at word boundaries',
    (tester) async {
      const name = 'Amira Alexandria Henderson';
      const profile = SeekerProfile(
        id: 'test-141',
        firstName: 'Amira Alexandria',
        surnameLine: 'Henderson',
        age: 27,
        city: 'Birmingham',
        gender: 'female',
        photos: [],
      );

      Future<void> mount(Widget child) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(375, 667),
                textScaler: TextScaler.linear(1.3),
              ),
              child: Scaffold(
                body: Center(child: SizedBox(width: 375, child: child)),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      void expectWrapped() {
        final label = find.text(name);
        final text = tester.widget<Text>(label);
        expect(text.maxLines, isNull);
        expect(text.overflow, isNot(TextOverflow.ellipsis));
        final paragraph = _paragraph(tester, label);
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: name.length),
        );
        expect(boxes.map((box) => box.top).toSet(), hasLength(greaterThan(1)));
        for (final match in RegExp(r'\S+').allMatches(name)) {
          final word = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: match.start, extentOffset: match.end),
          );
          expect(word.map((box) => box.top).toSet(), hasLength(1));
        }
        expect(tester.takeException(), isNull);
      }

      await mount(
        const ZyraRequestActivityIdentity(
          profile: profile,
          subtitle: 'Received',
        ),
      );
      expectWrapped();
      await mount(
        const ZyraPastRequestActivityCard(
          profile: profile,
          subtitle: 'Ended',
          status: 'Not taken up',
          cardId: 'past-141',
        ),
      );
      expectWrapped();
      for (final guardian in [false, true]) {
        await mount(
          ZyraConceptProfilePresentation(
            data: ZyraConceptAccountData(
              guardian: guardian,
              name: name,
              age: '27',
              gender: 'Female',
              location: 'Birmingham',
              membership: guardian ? 'Guardian One' : 'Seeker One',
              isOne: true,
              relationship: 'Main Guardian',
              linkedSeekers: 'One',
              guardianCount: 'One',
              signedInWith: 'Apple',
              backgroundLabel: 'Ivory',
              hapticLabel: 'Off',
              gold: true,
            ),
            onAction: (_) {},
            onSwitchRole: () {},
          ),
        );
        expectWrapped();
        final pills = tester.getRect(
          find.byKey(const ValueKey('concept_profile_pills')),
        );
        for (final label in [
          if (!guardian) 'Preview',
          if (!guardian) 'Edit',
          'Switch',
        ]) {
          final bounds = tester.getRect(find.text(label));
          expect(bounds.intersect(pills), bounds);
        }
      }
    },
  );

  for (final code in ['ZV-20817', 'ZS-48213']) {
    testWidgets('Reference $code wraps before its prefix break opportunity', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 133,
              child: ZyraReferenceLabel(
                prefix: 'Reference:',
                code: code,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(ZyraReferenceLabel),
          matching: find.byType(Text),
        ),
      );
      expect(text.semanticsLabel, 'Reference: $code');
      final paragraph = _paragraph(tester, find.text(text.data!));
      final codeStart = text.data!.indexOf(code.substring(0, 2));
      final codeBoxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: codeStart, extentOffset: text.data!.length),
      );
      expect(codeBoxes.map((box) => box.top).toSet(), hasLength(1));
      expect(codeBoxes.first.top, greaterThan(0));
    });
  }
}
