// Protected sample route coverage for the shared Profiles swipe. Generic
// card-motion comparison widgets are covered independently.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';

import 'support/profile_swipe_driver.dart';
import 'support/zyra_hidden_dev_controls_driver.dart';

const _sara = 'draft-sara';
const _aisha = 'draft-aisha';

Finder _key(String value) => find.byKey(ValueKey(value));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Profiles swipe tests must remain offline.');
  }
}

ZyraOneJourneyBrowseDesigns _browse(WidgetTester tester) =>
    tester.widget(find.byType(ZyraOneJourneyBrowseDesigns));

String _selectedId(WidgetTester tester) {
  final view = _browse(tester);
  return view.profiles[view.selectedIndex].id;
}

Future<void> _mount(
  WidgetTester tester, {
  bool quiet = false,
  bool accessible = false,
  bool Function()? canAct,
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          disableAnimations: quiet,
          accessibleNavigation: accessible,
        ),
        child: child!,
      ),
      home: ZyraOneJourneyConceptShell(
        fixture: ZyraShellTestFixture().fixture,
        canAct: canAct ?? () => true,
        onExit: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final browse = _browse(tester);
      if (browse.profiles.isNotEmpty &&
          browse.profiles.every((profile) => profile.photos.isNotEmpty)) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await tester.pump();
    }
    fail('The offline Browse deck did not publish prepared photo frames.');
  });
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

void main() {
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  setUp(() {
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousNetwork;
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });

  testWidgets('Profiles keeps Details first without a card-mode picker', (
    tester,
  ) async {
    await _mount(tester, quiet: true);
    final original = _browse(tester);
    final id = _selectedId(tester);
    final beforePeople = original.profiles
        .map((profile) => profile.id)
        .toList();
    final beforeSent = original.invitationSent!(
      original.profiles[original.selectedIndex],
    );
    expect(_key('concept_browse_details_$id'), findsOneWidget);
    await tester.tap(_key('concept_browse_photo_tap_$id'));
    await tester.pumpAndSettle();
    final before = tester.widget<PageView>(
      _key('concept_browse_photo_swipe_$id'),
    );
    expect(before.controller!.page, closeTo(1, .001));
    await openZyraDevControls(tester);
    expect(_key('concept_browse_gallery_mode'), findsNothing);
    expect(find.text('Profile cards'), findsNothing);
    expect(find.text('Original photos'), findsNothing);
    await closeZyraDevControls(tester);
    final updated = _browse(tester);
    expect(updated.profiles.map((profile) => profile.id), beforePeople);
    expect(_selectedId(tester), id);
    expect(
      updated.invitationSent!(updated.profiles[updated.selectedIndex]),
      beforeSent,
    );
    final after = tester.widget<PageView>(
      _key('concept_browse_photo_swipe_$id'),
    );
    expect(after.controller!.page, closeTo(1, .001));
    expect(_key('concept_browse_identity_$id'), findsNothing);
    expect(_key('concept_profile_swipe_track'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retained Next and request delegates cannot borrow a new owner', (
    tester,
  ) async {
    var allowed = true;
    await _mount(tester, quiet: true, canAct: () => allowed);
    final next = _browse(tester).onNext!;
    final request = _browse(tester).onRequest!;
    final oldPerson = _browse(tester).profiles.firstWhere((p) => p.id == _sara);
    await swipeProfileForControlKey(tester, 'concept_next_profile');
    next();
    request(oldPerson);
    await tester.pumpAndSettle();
    expect(_selectedId(tester), _aisha);
    expect(find.text('Request sent'), findsNothing);

    final currentNext = _browse(tester).onNext!;
    allowed = false;
    tester.element(find.byType(ZyraOneJourneyConceptShell)).markNeedsBuild();
    await tester.pumpAndSettle();
    currentNext();
    await tester.pumpAndSettle();
    expect(_selectedId(tester), _aisha);
  });

  testWidgets('revocation while dragging cancels the pending selection', (
    tester,
  ) async {
    var allowed = true;
    await _mount(tester, canAct: () => allowed);
    final track = _key('concept_profile_swipe_track');
    final title = tester.getRect(_key('concept_browse_title'));
    final dots = tester.getRect(_key('concept_browse_photo_pagination'));
    final gesture = await tester.startGesture(tester.getCenter(track));
    await gesture.moveBy(const Offset(-160, 0));
    await tester.pump();
    expect(_key('concept_browse_details_$_aisha'), findsOneWidget);
    expect(_selectedId(tester), _sara);
    expect(tester.getRect(_key('concept_browse_title')), title);
    expect(tester.getRect(_key('concept_browse_photo_pagination')), dots);
    await gesture.up();
    await tester.pump();
    allowed = false;
    await tester.pumpAndSettle();
    expect(_selectedId(tester), _sara);
    expect(_key('concept_browse_details_$_aisha'), findsNothing);
  });

  for (final quiet in [true, false]) {
    testWidgets('quiet Next still advances the exact profile $quiet', (
      tester,
    ) async {
      await _mount(tester, quiet: quiet, accessible: !quiet);
      final track = _key('concept_profile_swipe_track');
      final gesture = await tester.startGesture(tester.getCenter(track));
      await gesture.moveBy(const Offset(-160, 0));
      await tester.pump();
      expect(_selectedId(tester), _sara);
      expect(_key('concept_browse_details_$_aisha'), findsNothing);
      await gesture.up();
      await tester.pump();
      expect(_selectedId(tester), _aisha);
    });
  }
}
