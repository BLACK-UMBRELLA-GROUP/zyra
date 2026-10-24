// Real protected-shell input, captured native feedback, and member isolation.
// These offline checks do not establish physical motor feel or live authority.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_personalisation_content.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

class _NoNetwork extends HttpOverrides {
  int calls = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    ++calls;
    throw StateError('Haptic parity fixtures must stay offline.');
  }
}

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _mount(WidgetTester tester, Widget body) async {
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
      home: body,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _mountShell(WidgetTester tester) async {
  await _mount(
    tester,
    ZyraOneJourneyConceptShell(canAct: () => true, onExit: () {}),
  );
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
        find.byType(ZyraOneJourneyBrowseDesigns),
      );
      if (browse.profiles.every((person) => person.photos.isNotEmpty)) return;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await tester.pump();
    }
    fail('The local Browse photo snapshot did not finish preparing.');
  });
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = _key(key);
  if (target.evaluate().isEmpty) {
    final owner = [
      'concept-current-profile-scroll',
      'personalisation-scroll',
    ].map(_key).firstWhere((finder) => finder.evaluate().isNotEmpty);
    await tester.scrollUntilVisible(
      target,
      180,
      scrollable: find
          .descendant(of: owner, matching: find.byType(Scrollable))
          .first,
    );
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _tapNavigation(WidgetTester tester, String label) async {
  final finder = find.byType(ZyraShellNavigation);
  final navigation = tester.widget<ZyraShellNavigation>(finder);
  final index = navigation.items.indexWhere((item) => item.label == label);
  expect(index, greaterThanOrEqualTo(0));
  final icon = find.descendant(
    of: finder,
    matching: find.byIcon(navigation.items[index].icon),
  );
  expect(icon, findsOneWidget);
  // The canonical pill recognizer owns input, not the IgnorePointer icon.
  await tester.tapAt(tester.getCenter(icon));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _chooseLocalHaptic(
  WidgetTester tester,
  ZyraHapticLevel level,
) async {
  await _tapNavigation(tester, 'Profile');
  await _tap(tester, 'concept_personalisation');
  await _tap(tester, 'personalisation_haptic');
  await tester.tap(
    find.descendant(
      of: find.byType(ZyraPersonalisationChoiceSheet<ZyraHapticLevel>),
      matching: find.text(level.label),
    ),
  );
  await tester.pumpAndSettle();
  expect(
    find.descendant(
      of: _key('personalisation_haptic'),
      matching: find.text(level.label),
    ),
    findsOneWidget,
  );
  await _returnPage(tester);
  await _tapNavigation(tester, 'Profiles');
}

Future<void> _returnPage(WidgetTester tester) => returnZyraPreviewPage(tester);

List<Object?> _vibrations(List<MethodCall> calls) => calls
    .where((call) => call.method == 'HapticFeedback.vibrate')
    .map((call) => call.arguments)
    .toList();

void main() {
  final calls = <MethodCall>[];
  late ZyraHapticLevel originalHaptic;

  setUp(() {
    originalHaptic = ZyraInteractionStyle.hapticLevel;
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.light);
    ZyraText.useTestFontStubs = true;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraInteractionStyle.selectHapticLevel(originalHaptic);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final level in [ZyraHapticLevel.off, ZyraHapticLevel.strong]) {
    testWidgets(
      '${level.label} locally governs photo, tab and Browse action feedback without preference writes',
      (tester) async {
        const owner = 'request-haptic-parity-member';
        SharedPreferences.setMockInitialValues({
          'zyra.cached_account_owner': owner,
          'zyra.haptic_level': ZyraHapticLevel.light.name,
          'haptic-parity-sentinel': 'unchanged',
        });
        await tester.runAsync(() async {
          await ZyraLocalPrefs.init();
          await ZyraLocalPrefs.bindAccount(owner);
        });
        addTearDown(() => ZyraLocalPrefs.bindAccount(null));
        final expected = level == ZyraHapticLevel.off
            ? <Object?>[]
            : <Object?>['HapticFeedbackType.heavyImpact'];
        final network = _NoNetwork();
        await HttpOverrides.runWithHttpOverrides(() async {
          await _mountShell(tester);
          await _chooseLocalHaptic(tester, level);
          final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
            find.byType(ZyraOneJourneyBrowseDesigns),
          );
          expect(browse.hapticLevel, level);
          final person = browse.profiles[browse.selectedIndex];
          expect(person.photos.length, greaterThan(1));
          final photo = _key('concept_browse_photo_tap_${person.id}');
          calls.clear();
          await tester.tap(photo);
          await tester.pumpAndSettle();
          expect(_vibrations(calls), expected);
          final pager = tester.widget<PageView>(
            _key('concept_browse_photo_swipe_${person.id}'),
          );
          expect(pager.controller!.page, 1);

          // Finger paging uses the same feedback seam as tap advancement.
          calls.clear();
          await tester.drag(photo, const Offset(260, 0));
          await tester.pumpAndSettle();
          expect(pager.controller!.page, 0);
          expect(_vibrations(calls), expected);

          calls.clear();
          await _tapNavigation(tester, 'My ZYRA');
          expect(_vibrations(calls), expected);
          expect(
            tester
                .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
                .currentIndex,
            2,
          );
          calls.clear();
          await _tapNavigation(tester, 'My ZYRA');
          expect(_vibrations(calls), isEmpty);

          await _tapNavigation(tester, 'Profiles');
          await _tap(tester, 'concept_browse_menu');
          calls.clear();
          await _tapNavigation(tester, 'Filters');
          expect(_vibrations(calls), expected);
          expect(find.text('Filters'), findsWidgets);
          await _returnPage(tester);
          await _tap(tester, 'concept_browse_menu');
          await _tapNavigation(tester, 'Hide profile');
          expect(_key('browse-hide-cancel'), findsOneWidget);
          calls.clear();
          await _tap(tester, 'browse-hide-cancel');
          expect(_vibrations(calls), expected);
          expect(_key('concept_browse_options_navigation'), findsOneWidget);
          await _tapNavigation(tester, 'Hide profile');
          calls.clear();
          await _tap(tester, 'browse-hide-confirm');
          expect(_vibrations(calls), expected);
          expect(_key('concept_browse_options_navigation'), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }, network);
        expect(network.calls, 0);
        expect(ZyraInteractionStyle.hapticLevel, ZyraHapticLevel.light);
        expect(
          ZyraLocalPrefs.cachedHapticLevelName,
          ZyraHapticLevel.light.name,
        );
        final persisted = await tester.runAsync(() async {
          await ZyraLocalPrefs.bindAccount(owner);
          final preferences = await SharedPreferences.getInstance();
          await preferences.reload();
          return {
            for (final key in preferences.getKeys()) key: preferences.get(key),
          };
        });
        expect(persisted, {
          'zyra.cached_account_owner': owner,
          'zyra.haptic_level': ZyraHapticLevel.light.name,
          'haptic-parity-sentinel': 'unchanged',
        });
      },
    );
  }

  testWidgets(
    'omitted shared Browse haptic choice uses the member preference',
    (tester) async {
      final person = SeekerProfile(
        id: 'ordinary-rendering-fixture',
        firstName: 'Person',
        age: 28,
        city: 'London',
        gender: 'female',
        photos: const ['first', 'second'],
      );
      await _mount(
        tester,
        Scaffold(
          body: ZyraBrowseDesigns(
            profiles: [person],
            selectedIndex: 0,
            design: ZyraOneJourneyBrowseDesign.portraitCard,
            showSave: false,
            photoBuilder:
                (
                  _,
                  source, {
                  required width,
                  required height,
                  required alignment,
                }) => SizedBox(
                  width: width,
                  height: height,
                  child: ColoredBox(
                    color: source == 'first' ? Colors.blue : Colors.green,
                  ),
                ),
          ),
        ),
      );
      expect(
        tester
            .widget<ZyraBrowseDesigns>(find.byType(ZyraBrowseDesigns))
            .hapticLevel,
        isNull,
      );
      calls.clear();
      await tester.tap(_key('concept_browse_photo_tap_${person.id}'));
      await tester.pumpAndSettle();
      expect(_vibrations(calls), ['HapticFeedbackType.lightImpact']);
      expect(ZyraInteractionStyle.hapticLevel, ZyraHapticLevel.light);
      expect(tester.takeException(), isNull);
    },
  );
}
