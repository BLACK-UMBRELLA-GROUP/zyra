// Opt-in captures of actual line 120 app routes; no reference pictures changed.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/settings/privacy_and_data_screen.dart';
import 'package:zyra/screens/welcome_screen.dart';

import 'baseline_capture_support.dart';

const _output = String.fromEnvironment('ZYRA_LINE120_OUTPUT');

ZyraPreviewNavigationCheckpoint _checkpoint({bool security = false}) =>
    ZyraPreviewNavigationCheckpoint(
      guardian: false,
      model: ViewRequestDraftModel(capacity: 3).snapshot(),
      tab: 4,
      pages: security ? const ['settings', 'account_action'] : const [],
      accountDestination: security
          ? ZyraConceptAccountAction.signInSecurity.name
          : null,
    );

BaselineHarness _harness(
  WidgetTester tester, {
  Size size = const Size(430, 932),
  EdgeInsets safePadding = const EdgeInsets.only(top: 59, bottom: 34),
}) => BaselineHarness(
  tester,
  group: 'line120',
  outputRoot: _output,
  evidenceRoot: _output,
  flatOutput: true,
  logicalSize: size,
  safePadding: safePadding,
  reduceMotion: true,
);

void _noRecoveryText() => expect(
  find.textContaining(RegExp('recovery', caseSensitive: false)),
  findsNothing,
);

Future<void> _capture(BaselineHarness harness, String name) => harness.capture(
  'phone_access',
  name,
  'removed',
  'Actual app route after the Founder-approved recovery email removal.',
  fileName: '$name.png',
);

void main() {
  setUpAll(() async {
    if (_output.isEmpty) return;
    await baselineSetUp(
      evidenceRoot: null,
      useSystemSymbolFont: Platform.isMacOS,
    );
  });
  tearDownAll(() async {
    if (_output.isNotEmpty) await baselineTearDown();
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    final ios = platform == TargetPlatform.iOS;
    final name = ios ? 'welcome_ios' : 'welcome_android';
    testWidgets(
      'line 120 actual $name has only native-ordered provider entry',
      (tester) async {
        final harness = _harness(
          tester,
          size: ios ? const Size(430, 932) : const Size(390, 844),
          safePadding: ios
              ? const EdgeInsets.only(top: 59, bottom: 34)
              : const EdgeInsets.only(top: 24, bottom: 24),
        );
        await harness.mountPresentation(
          child: const WelcomeScreen(),
          checkpoint: _checkpoint(),
        );
        final first = find.byKey(
          ValueKey(ios ? 'welcome_apple' : 'welcome_google'),
        );
        final second = find.byKey(
          ValueKey(ios ? 'welcome_google' : 'welcome_apple'),
        );
        expect(first, findsOneWidget);
        expect(second, findsOneWidget);
        expect(
          tester.getTopLeft(first).dy,
          lessThan(tester.getTopLeft(second).dy),
        );
        expect(
          find.byKey(const ValueKey('welcome_recovery_email')),
          findsNothing,
        );
        expect(find.byType(TextButton), findsNothing);
        _noRecoveryText();
        await _capture(harness, name);
      },
      skip: _output.isEmpty,
      variant: TargetPlatformVariant.only(platform),
    );
  }

  testWidgets(
    'line 120 Founder Sign-in and security has no recovery destination',
    (tester) async {
      final harness = _harness(tester);
      await harness.mount(checkpoint: _checkpoint(security: true));
      harness.assertPage('account_action');
      expect(find.text('Sign-in & security'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('concept_settings_open_signInSecurity_recovery'),
        ),
        findsNothing,
      );
      _noRecoveryText();
      await _capture(harness, 'founder_sign_in_security');
    },
    skip: _output.isEmpty,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'line 120 actual Privacy and data describes provider sign-in only',
    (tester) async {
      final harness = _harness(tester);
      await harness.mountPresentation(
        child: const PrivacyAndDataScreen(),
        checkpoint: _checkpoint(),
      );
      final signInText = find.textContaining('Use Apple or Google to sign in.');
      await Scrollable.ensureVisible(tester.element(signInText), alignment: .5);
      await harness.flush();
      expect(signInText.hitTestable(), findsOneWidget);
      _noRecoveryText();
      await _capture(harness, 'privacy_and_data');
    },
    skip: _output.isEmpty,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
