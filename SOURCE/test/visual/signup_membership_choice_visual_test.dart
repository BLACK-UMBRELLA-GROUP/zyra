// Candidate captures only; no approved goldens, account, billing or IDV calls.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_signup_membership_choice.dart';
import 'package:zyra/screens/onboarding/signup_membership_choice_screen.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';

const capture = bool.fromEnvironment('ZYRA_SIGNUP_MEMBERSHIP_CAPTURE');
const boundaryKey = ValueKey('signup-membership-candidate');

Future<void> _reach(WidgetTester tester, Finder target) async {
  // BASELINE/SIGNUP_CAPTURE_BRIEF_2026-10-29.md §2 keeps both roles'
  // membership screens. At 200 percent the scaffold lazily builds lower
  // content, so reach it through the actual scroll instead of an absent element.
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      160,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsMembershipAudit');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final wordmark = FontLoader('SyneMembershipAudit')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsMembershipAudit';
    ZyraText.testWordmarkFontFamily = 'SyneMembershipAudit';
  });

  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });

  for (final role in ZyraSignupRole.values) {
    for (final layout in [
      (name: 'standard', size: const Size(390, 844), scale: 1.0),
      (name: 'compact140', size: const Size(320, 568), scale: 1.4),
      (name: 'compact200', size: const Size(320, 568), scale: 2.0),
    ]) {
      testWidgets('${role.name} Membership real fonts ${layout.name}', (
        tester,
      ) async {
        tester.view.physicalSize = layout.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        ZyraSignupMembershipChoice? choice;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(
              textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(layout.scale),
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
                disableAnimations: layout.scale > 1,
              ),
              child: OnboardingPreviewStyle(
                directionName: 'luma',
                child: RepaintBoundary(key: boundaryKey, child: child!),
              ),
            ),
            home: StatefulBuilder(
              builder: (context, setState) => SignupMembershipChoiceScreen(
                role: role,
                devPreview: true,
                choice: choice,
                onChanged: (value) => setState(() => choice = value),
                onContinue: () {},
                onBack: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (capture) {
          await _candidate(tester, '${role.name}_${layout.name}_entry');
        }
        tester
            .widget<SignupMembershipChoiceScreen>(
              find.byType(SignupMembershipChoiceScreen),
            )
            .onChanged(
              const ZyraSignupMembershipChoice(
                kind: ZyraSignupMembershipKind.basic,
              ),
            );
        await tester.pumpAndSettle();
        expect(
          find
              .byKey(const ValueKey('signup_membership_continue'))
              .hitTestable(),
          findsOneWidget,
        );
        if (capture) {
          await _candidate(tester, '${role.name}_${layout.name}_basic');
        }
        if (role == ZyraSignupRole.seeker) {
          final suggestion = find.byKey(
            const ValueKey('signup_membership_try_one'),
          );
          await tester.ensureVisible(suggestion);
          await tester.pumpAndSettle();
          expect(tester.getSize(suggestion).height, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
          if (capture) {
            await _candidate(tester, '${role.name}_${layout.name}_suggestion');
          }
          await tester.tap(suggestion);
        } else {
          await tester.ensureVisible(
            find.byKey(const ValueKey('signup_membership_one')),
          );
          await tester.tap(find.byKey(const ValueKey('signup_membership_one')));
        }
        await tester.pumpAndSettle();
        expect(choice?.kind, ZyraSignupMembershipKind.one);
        expect(tester.takeException(), isNull);
        if (capture) {
          await _candidate(tester, '${role.name}_${layout.name}_one');
        }
        // At 200 percent this card is taller than the free viewport. Its
        // centre can lie behind Continue; press its visible title instead.
        final familyTitle = find.descendant(
          of: find.byKey(const ValueKey('signup_membership_family')),
          matching: find.text('ZYRA Family'),
        );
        await _reach(tester, familyTitle);
        expect(familyTitle.hitTestable(), findsOneWidget);
        await tester.tap(familyTitle);
        await tester.pumpAndSettle();
        expect(choice?.kind, ZyraSignupMembershipKind.family);
        expect(choice?.isValidFor(role), isTrue);
        await _reach(
          tester,
          find.byKey(const ValueKey('signup_membership_family_estimate')),
        );
        await tester.pumpAndSettle();
        expect(
          find
              .byKey(const ValueKey('signup_membership_continue'))
              .hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        if (capture) {
          await _candidate(tester, '${role.name}_${layout.name}_family');
        }
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -1000),
        );
        await tester.pumpAndSettle();
        expect(
          find
              .byKey(const ValueKey('signup_membership_continue'))
              .hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        if (capture) {
          await _candidate(tester, '${role.name}_${layout.name}_family_end');
        }
      });
    }
  }
}

Future<void> _candidate(WidgetTester tester, String name) async {
  expect(autoUpdateGoldenFiles, isTrue);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(boundaryKey),
  );
  final image = await tester.runAsync(() => boundary.toImage());
  try {
    final data = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    await tester.runAsync(
      () => expectLater(
        data!.buffer.asUint8List(),
        matchesGoldenFile(
          'candidates/signup_membership_offer_2026_10_03/$name.png',
        ),
      ),
    );
  } finally {
    image?.dispose();
  }
}
