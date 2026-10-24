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

const capture = bool.fromEnvironment('ZYRA_FAMILY_INTRO_CAPTURE');
const boundaryKey = ValueKey('signup-family-intro-candidate');

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
      testWidgets('${role.name} Family intro real fonts ${layout.name}', (
        tester,
      ) async {
        tester.view.physicalSize = layout.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        ZyraSignupMembershipChoice choice = const ZyraSignupMembershipChoice(
          kind: ZyraSignupMembershipKind.family,
          seekers: 1,
          guardians: 1,
        );
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
                disableAnimations: true,
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
        await tester.ensureVisible(
          find.byKey(const ValueKey('signup_membership_family')),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('£4.99 per person for the first month'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        if (capture) {
          await _candidate(tester, '${role.name}_${layout.name}_card');
        }
        await tester.ensureVisible(
          find.byKey(const ValueKey('signup_family_first_month_total')),
        );
        await tester.pumpAndSettle();
        expect(find.text('£9.98 first month total'), findsOneWidget);
        expect(find.text('Then £49.98 / month estimate'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (capture) {
          await _candidate(tester, '${role.name}_${layout.name}_total');
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
          await _candidate(tester, '${role.name}_${layout.name}_end');
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
          'candidates/signup_family_intro_2026_10_04/$name.png',
        ),
      ),
    );
  } finally {
    image?.dispose();
  }
}
