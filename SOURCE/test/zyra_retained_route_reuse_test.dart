import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_code_entry.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_request_help_content.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

class _DenyNetwork extends HttpOverrides {
  int calls = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    ++calls;
    throw StateError('Retained routes must stay offline.');
  }
}

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _mount(WidgetTester tester, {bool guardian = false}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (_, child) => MediaQuery(
        data: const MediaQueryData(
          size: Size(393, 852),
          padding: EdgeInsets.only(top: 44, bottom: 34),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: ZyraOneJourneyConceptShell(
        canAct: () => true,
        onExit: () => fail('A leaf return must not exit the app.'),
        initialGuardianRole: guardian,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = _key(key);
  if (target.evaluate().isEmpty) {
    final owner = [
      'concept-current-profile-scroll',
      'concept-current-settings-scroll',
    ].map(_key).firstWhere((finder) => finder.evaluate().isNotEmpty);
    final scrollable = find.descendant(
      of: owner,
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(target, 180, scrollable: scrollable.first);
  }
  await Scrollable.ensureVisible(tester.element(target), alignment: .45);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, String title) async {
  final finder = find.byType(ZyraShellNavigation);
  final nav = tester.widget<ZyraShellNavigation>(finder);
  final item = nav.items.singleWhere((item) => item.label == title);
  await tester.tapAt(
    tester.getCenter(
      find.descendant(of: finder, matching: find.byIcon(item.icon)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  final scope = _key('concept_pull_down_back_scope');
  expect(scope, findsOneWidget);
  expect(find.byType(BackButton), findsNothing);
  await returnZyraPreviewPage(tester);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test(
    'request Help never includes retired matching or restart instructions',
    () {
      final all = zyraRequestHelpCategories
          .expand((category) => category.entries)
          .map((entry) => '${entry.question} ${entry.answer}')
          .join('\n');
      expect(all, isNot(contains('Potential Journey')));
      expect(all, isNot(contains('Consider')));
      expect(all, isNot(contains('Paused Journey')));
      expect(all, contains('not as invitations to restart'));
      expect(all, contains('Received and Sent'));
      expect(all, contains('How do I sign in?'));
    },
  );

  testWidgets('Browse Scan uses retained entry and returns one parent', (
    tester,
  ) async {
    final network = _DenyNetwork();
    var memberChanges = 0;
    void changed() => ++memberChanges;
    AppState.instance.addListener(changed);
    addTearDown(() => AppState.instance.removeListener(changed));
    await HttpOverrides.runWithHttpOverrides(() async {
      await _mount(tester);
      await _tap(tester, 'concept_browse_menu');
      await _nav(tester, 'Scan');
      expect(find.byType(ZyraDraftCodeEntry), findsOneWidget);
      expect(_key('known-person-code-field'), findsOneWidget);
      expect(find.text('Scanning isn’t available yet.'), findsNothing);
      await _back(tester);
      expect(find.byType(ZyraDraftCodeEntry), findsNothing);
      expect(find.text('Profiles'), findsOneWidget);
      expect(_key('concept_pull_down_back_scope'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }, network);
    expect(network.calls, 0);
    expect(memberChanges, 0);
  });

  testWidgets('code lookup finds exact person without sending a Journey', (
    tester,
  ) async {
    final network = _DenyNetwork();
    await HttpOverrides.runWithHttpOverrides(() async {
      await _mount(tester);
      await _tap(tester, 'concept_browse_menu');
      await _nav(tester, 'Scan');
      await tester.enterText(
        _key('known-person-code-field'),
        'ZYRA-DRAFT-SARA',
      );
      await _tap(tester, 'known-person-check-code');
      expect(find.text('Sara'), findsOneWidget);
      expect(find.text('27 · Birmingham'), findsOneWidget);
      expect(find.text('Consider'), findsNothing);
      await _tap(tester, 'draft_known_person_view');
      expect(find.text('Sara'), findsOneWidget);
      expect(find.text('Request a Journey'), findsOneWidget);
      expect(find.text('Request sent'), findsNothing);
      await _back(tester);
      expect(find.byType(ZyraDraftCodeEntry), findsOneWidget);
      await _back(tester);
      expect(find.text('Profiles'), findsOneWidget);
      expect(_key('concept_pull_down_back_scope'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }, network);
    expect(network.calls, 0);
  });

  for (final guardian in [false, true]) {
    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} Help uses original FAQ and returns to Settings',
      (tester) async {
        final network = _DenyNetwork();
        await HttpOverrides.runWithHttpOverrides(() async {
          await _mount(tester, guardian: guardian);
          await _nav(tester, 'Profile');
          await _tap(tester, 'concept_settings');
          await _tap(tester, 'concept_settings_helpSupport');
          expect(find.byType(HelpSupportScreen), findsOneWidget);
          expect(_key('concept_account_action_scroll'), findsNothing);
          await tester.enterText(find.byType(TextField), 'sign in');
          await tester.pumpAndSettle();
          await tester.tap(find.text('How do I sign in?'));
          await tester.pumpAndSettle();
          expect(find.textContaining('With Apple or Google.'), findsOneWidget);
          expect(_key('support-safety-case-status'), findsNothing);
          await _back(tester);
          expect(find.byType(HelpSupportScreen), findsNothing);
          expect(find.byType(ZyraConceptSettingsPresentation), findsOneWidget);
          await _back(tester);
          expect(find.byType(ZyraConceptProfilePresentation), findsOneWidget);
          expect(_key('concept_pull_down_back_scope'), findsNothing);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }, network);
        expect(network.calls, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
