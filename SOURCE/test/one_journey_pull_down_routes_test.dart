import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_journey_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/screens/profile/my_profile_preview_screen.dart';
import 'package:zyra/screens/profile/seeker_profile_screen.dart';
import 'package:zyra/screens/settings/personalisation_screen.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_journey_icon.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _sara = 'draft-sara';
const _scope = ValueKey('concept_pull_down_back_scope');

Finder _key(String value) => find.byKey(ValueKey(value));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Nested-route fixtures must remain local and offline.');
  }
}

// Test the injected, disposable shell, not a production admission override.
// The local photos are the existing bundled samples. No provider is initialized.
Future<void> _mount(
  WidgetTester tester, {
  bool guardian = false,
  bool reduce = true,
  bool prepareOwnPhotos = false,
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 44, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
          disableAnimations: reduce,
        ),
        child: child!,
      ),
      home: ZyraOneJourneyConceptShell(
        canAct: () => true,
        onExit: () => fail('A nested return must not exit the shell.'),
        initialGuardianRole: guardian,
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (prepareOwnPhotos) {
    expect(guardian, isFalse);
    // Preparing the retained local photo snapshot uses a genuine image codec
    // future. Fake frame time alone cannot complete it; keep the real wait
    // bounded and prove the prepared data before opening its retained viewer.
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        final browse = find.byType(ZyraOneJourneyBrowseDesigns);
        if (browse.evaluate().isNotEmpty) {
          final deck = tester.widget<ZyraOneJourneyBrowseDesigns>(browse);
          if (deck.profiles.isNotEmpty &&
              deck.profiles.first.photos.isNotEmpty) {
            return;
          }
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await tester.pump();
      }
      fail('Own-profile return requires the prepared, offline photo snapshot.');
    });
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
}

Future<void> _tapFinder(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    final owners = [
      'concept-current-profile-scroll',
      'concept-current-settings-scroll',
      'concept-current-membership-scroll',
      'draft_scroll',
    ];
    final owner = owners.map(_key).where((f) => f.evaluate().isNotEmpty).first;
    final scrollable = find
        .descendant(of: owner, matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(target, 180, scrollable: scrollable);
  }
  expect(target, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(target), alignment: .45);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _tap(WidgetTester tester, String key) =>
    _tapFinder(tester, _key(key));

Future<void> _tapNav(WidgetTester tester, String label) async {
  await expandZyraPreviewTabBarIfIdle(tester);
  final navigation = find.byType(ZyraShellNavigation);
  expect(navigation, findsOneWidget);
  final widget = tester.widget<ZyraShellNavigation>(navigation);
  final index = widget.items.indexWhere((item) => item.label == label);
  expect(index, greaterThanOrEqualTo(0));
  final item = widget.items[index];
  final icon = find.descendant(
    of: navigation,
    matching: item.useJourneyGlyph
        ? find.byType(ZyraJourneyIcon)
        : find.byIcon(item.icon),
  );
  expect(icon, findsOneWidget);
  // The real bar-wide detector owns these icon cells; do not invoke onTap.
  final bar = find
      .ancestor(
        of: icon,
        matching: find.byWidgetPredicate(
          (w) => w is GestureDetector && w.onTapDown != null,
        ),
      )
      .first;
  expect(bar.hitTestable(), findsOneWidget);
  await tester.tapAt(tester.getCenter(icon));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _pullFrom(WidgetTester tester, Offset point) async {
  await tester.timedDragFrom(
    point,
    const Offset(0, 230),
    const Duration(milliseconds: 450),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _returnHeader(WidgetTester tester) async {
  final scope = find.byKey(_scope);
  expect(scope, findsOneWidget);
  final owner = tester.widget<ZyraPullDownBackScope>(scope);
  if (!owner.enabled) {
    expect(
      find.byKey(const ValueKey('zyra_visible_back_button')),
      findsNothing,
    );
    final rect = tester.getRect(scope);
    await _pullFrom(tester, Offset(rect.left + 30, rect.top + 65));
    return;
  }
  await returnZyraPreviewPage(tester);
}

void _oneMemberBack() {
  final scope = find.byKey(_scope);
  expect(scope, findsOneWidget);
  expect(
    find.descendant(
      of: scope,
      matching: find.byKey(const ValueKey('zyra_visible_back_button')),
    ),
    findsNothing,
  );
  expect(find.byKey(const ValueKey('zyra_pull_down_bottom_cue')), findsNothing);
  expect(find.byKey(const ValueKey('zyra_back_swipe_edge')), findsOneWidget);
}

void _rootProfile(WidgetTester tester, {bool guardian = false}) {
  expect(find.byKey(_scope), findsNothing);
  expect(find.byType(ZyraConceptProfilePresentation), findsOneWidget);
  final navigation = tester.widget<ZyraShellNavigation>(
    find.byType(ZyraShellNavigation),
  );
  expect(navigation.currentIndex, guardian ? 3 : 4);
}

Future<void> _openOneJourney(WidgetTester tester) async {
  // Explicit local scenario selection, never used as a return shortcut.
  await _tapNav(tester, 'Journey');
  await openZyraDevControls(tester);
  expect(find.text('Page options'), findsOneWidget);
  expect(
    tester.widget<Text>(_key('concept_page_options_context')).data,
    'Journey',
  );
  await _tap(tester, 'concept_journey_preview_1');
  await _tap(tester, 'draft_journey_$_sara');
  expect(find.byType(ZyraConceptJourneyPresentation), findsOneWidget);
  expect(
    tester
        .widget<ZyraConceptJourneyPresentation>(
          find.byType(ZyraConceptJourneyPresentation),
        )
        .stage
        .value,
    'salam_exchange',
  );
}

void _case(String description, Future<void> Function(WidgetTester) body) {
  testWidgets(description, (tester) async {
    final network = _NoNetwork();
    final member = AppState.instance;
    final saved = List.of(member.saved);
    final potential = List.of(member.potentialJourneys);
    final active = List.of(member.activeJourneys);
    final photos = List.of(member.photos);
    final plan = member.plan;
    var memberChanges = 0;
    void changed() => memberChanges++;
    member.addListener(changed);
    addTearDown(() => member.removeListener(changed));
    await HttpOverrides.runWithHttpOverrides(() async {
      await body(tester);
      expect(member.saved, saved);
      expect(member.potentialJourneys, potential);
      expect(member.activeJourneys, active);
      expect(member.photos, photos);
      expect(member.plan, plan);
      expect(memberChanges, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }, network);
    expect(network.attempts, 0);
    expect(tester.takeException(), isNull);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    ZyraText.useTestFontStubs = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    final fatal = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = fatal);
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  _case('Settings nested action Back returns exactly one parent at a time', (
    tester,
  ) async {
    await _mount(tester);
    await _tapNav(tester, 'Profile');
    await _tap(tester, 'concept_settings');
    expect(find.byType(ZyraConceptSettingsPresentation), findsOneWidget);
    _oneMemberBack();
    await _tap(tester, 'concept_settings_signInSecurity');
    expect(find.text('Sign-in & security'), findsOneWidget);
    expect(_key('concept_account_action_scroll'), findsOneWidget);
    _oneMemberBack();
    await _returnHeader(tester);
    expect(_key('concept_account_action_scroll'), findsNothing);
    expect(find.byType(ZyraConceptSettingsPresentation), findsOneWidget);
    await _returnHeader(tester);
    _rootProfile(tester);
  });

  _case('paced Settings edge return keeps its route until the 240ms finish', (
    tester,
  ) async {
    await _mount(tester, reduce: false);
    await _tapNav(tester, 'Profile');
    await _tap(tester, 'concept_settings');
    await _tap(tester, 'concept_settings_signInSecurity');
    expect(find.text('Sign-in & security'), findsOneWidget);
    _oneMemberBack();
    final scope = find.byKey(_scope);
    final rect = tester.getRect(scope);
    final surface = find.descendant(
      of: scope,
      matching: _key('zyra_back_swipe_translation'),
    );
    expect(surface, findsOneWidget);
    double offset() => tester.widget<Transform>(surface).transform.storage[12];
    final finger = await tester.startGesture(
      Offset(rect.left + 8, rect.top + rect.height * .35),
    );
    for (var step = 0; step < 6; step++) {
      await finger.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 200));
    final dragged = offset();
    expect(dragged, closeTo(180, .01));
    await finger.up();
    await tester.pump();
    expect(offset(), closeTo(dragged, .01));
    await tester.pump(const Duration(milliseconds: 120));
    expect(offset(), inExclusiveRange(dragged, rect.width));
    expect(find.text('Sign-in & security'), findsOneWidget);
    expect(_key('concept_account_action_scroll'), findsOneWidget);
    expect(find.byType(ZyraConceptSettingsPresentation), findsNothing);
    await tester.pump(const Duration(milliseconds: 140));
    expect(_key('concept_account_action_scroll'), findsNothing);
    expect(find.byType(ZyraConceptSettingsPresentation), findsOneWidget);
    expect(find.byKey(_scope), findsOneWidget);
    expect(offset(), 0);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ZyraConceptSettingsPresentation), findsOneWidget);
    await _returnHeader(tester);
    _rootProfile(tester);
  });

  _case(
    'Personalisation Back returns to Profile without changing preferences',
    (tester) async {
      await _mount(tester);
      await _tapNav(tester, 'Profile');
      await _tap(tester, 'concept_personalisation');
      final page = tester.widget<PersonalisationScreen>(
        find.byType(PersonalisationScreen),
      );
      final gold = page.goldEnabled;
      final haptic = page.hapticLevel;
      _oneMemberBack();
      await _returnHeader(tester);
      _rootProfile(tester);
      await _tap(tester, 'concept_personalisation');
      final reopened = tester.widget<PersonalisationScreen>(
        find.byType(PersonalisationScreen),
      );
      expect(reopened.goldEnabled, gold);
      expect(reopened.hapticLevel, haptic);
      await _returnHeader(tester);
      _rootProfile(tester);
    },
  );

  _case('Review then Membership Back restores both real local parents', (
    tester,
  ) async {
    await _mount(tester);
    await _tapNav(tester, 'Profile');
    await _tap(tester, 'concept_membership');
    expect(find.byType(ZyraConceptMembershipPresentation), findsOneWidget);
    _oneMemberBack();
    await _tap(tester, 'membership-section-seeker');
    await _tap(tester, 'membership-next');
    await _tap(tester, 'membership-select-seekerBasic');
    await _tap(tester, 'membership-review-selection');
    expect(find.text('Review selection'), findsOneWidget);
    _oneMemberBack();
    await _returnHeader(tester);
    expect(find.byType(ZyraConceptMembershipPresentation), findsOneWidget);
    expect(_key('concept_account_action_scroll'), findsNothing);
    await _returnHeader(tester);
    _rootProfile(tester);
  });

  _case(
    'own Seeker photo preview Back returns to Profile without a Back menu',
    (tester) async {
      await _mount(tester, prepareOwnPhotos: true);
      await _tapNav(tester, 'Profile');
      await _tap(tester, 'concept_preview_profile');
      expect(find.byType(MyProfilePreviewScreen), findsOneWidget);
      expect(find.byType(SeekerProfileScreen), findsNothing);
      expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
      final profile = tester
          .widget<ZyraBrowseDesigns>(find.byType(ZyraBrowseDesigns))
          .profiles
          .single;
      expect(profile.id, 'draft-self');
      expect(profile.photos, isNotEmpty);
      expect(
        profile.photos.every(
          (photo) => photo.startsWith('data:image/jpeg;base64,'),
        ),
        isTrue,
      );
      expect(_key('seeker-profile-close'), findsNothing);
      _oneMemberBack();
      await _returnHeader(tester);
      expect(find.byType(MyProfilePreviewScreen), findsNothing);
      expect(find.byType(SeekerProfileScreen), findsNothing);
      _rootProfile(tester);
      // A completed return must not produce a second navigation on a later
      // frame, nor reopen the discarded photo route.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(MyProfilePreviewScreen), findsNothing);
      _rootProfile(tester);
    },
  );

  _case('Guardian linked-Seeker photo returns to its actual Dashboard', (
    tester,
  ) async {
    await _mount(tester, guardian: true);
    await _tap(tester, 'guardian-dashboard-view-profile-draft-self');
    expect(find.byType(ZyraOneJourneyBrowsePresentation), findsOneWidget);
    expect(
      tester
          .widget<ZyraOneJourneyBrowsePresentation>(
            find.byType(ZyraOneJourneyBrowsePresentation),
          )
          .profile
          .id,
      'draft-self',
    );
    _oneMemberBack();
    await _returnHeader(tester);
    expect(find.byKey(_scope), findsNothing);
    expect(_key('guardian-dashboard-view-profile-draft-self'), findsOneWidget);
    expect(
      tester
          .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
          .currentIndex,
      0,
    );
  });

  _case('Guardian Network photo returns without changing its people or tab', (
    tester,
  ) async {
    await _mount(tester, guardian: true);
    await _tapNav(tester, 'Network');
    final before = tester.widget<ZyraOneJourneyGuardianNetworkPresentation>(
      find.byType(ZyraOneJourneyGuardianNetworkPresentation),
    );
    final ids = before.profiles.map((p) => p.id).toList();
    final photo = find
        .descendant(
          of: find.byType(ZyraOneJourneyGuardianNetworkPresentation),
          matching: find.byType(ZyraProfileImage),
        )
        .first;
    final open = find
        .ancestor(
          of: photo,
          matching: find.byWidgetPredicate(
            (w) => w is GestureDetector && w.onTap != null,
          ),
        )
        .first;
    await _tapFinder(tester, open);
    expect(
      tester
          .widget<ZyraOneJourneyBrowsePresentation>(
            find.byType(ZyraOneJourneyBrowsePresentation),
          )
          .profile
          .id,
      ids.first,
    );
    _oneMemberBack();
    await _returnHeader(tester);
    final after = tester.widget<ZyraOneJourneyGuardianNetworkPresentation>(
      find.byType(ZyraOneJourneyGuardianNetworkPresentation),
    );
    expect(after.profiles.map((p) => p.id), ids);
    expect(after.sentProfiles, isEmpty);
    expect(after.selectedIndex, before.selectedIndex);
    expect(find.byKey(_scope), findsNothing);
  });

  _case('Filters Back discards the uncommitted draft, preserving Browse', (
    tester,
  ) async {
    await _mount(tester);
    ZyraOneJourneyBrowseDesigns browse() =>
        tester.widget<ZyraOneJourneyBrowseDesigns>(
          find.byType(ZyraOneJourneyBrowseDesigns),
        );
    final ids = browse().profiles.map((p) => p.id).toList();
    final selected = browse().profiles[browse().selectedIndex].id;
    final design = browse().design;
    await _tap(tester, 'concept_browse_menu');
    await _tapNav(tester, 'Filters');
    await _tap(tester, 'concept_age_1');
    expect(_key('concept_age_range'), findsOneWidget);
    _oneMemberBack();
    await _returnHeader(tester);
    expect(browse().profiles.map((p) => p.id), ids);
    expect(browse().profiles[browse().selectedIndex].id, selected);
    expect(browse().design, design);
    await _tap(tester, 'concept_browse_menu');
    await _tapNav(tester, 'Filters');
    expect(_key('concept_age_range'), findsNothing);
    await _returnHeader(tester);
    expect(browse().profiles.map((p) => p.id), ids);
  });

  _case(
    'Journey body retains vertical stage traversal; Back returns one route',
    (tester) async {
      await _mount(tester, reduce: false);
      await _openOneJourney(tester);
      _oneMemberBack();
      final pages = _key('concept_current_journey_pages');
      await tester.timedDrag(
        pages,
        Offset(0, -tester.getSize(pages).height * .8),
        const Duration(milliseconds: 650),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<PageView>(pages).controller!.page, closeTo(1, .01));
      await tester.timedDrag(
        pages,
        Offset(0, tester.getSize(pages).height * .75),
        const Duration(milliseconds: 650),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ZyraConceptJourneyPresentation), findsOneWidget);
      expect(tester.widget<PageView>(pages).controller!.page, closeTo(0, .01));
      expect(
        tester
            .widget<ZyraConceptJourneyPresentation>(
              find.byType(ZyraConceptJourneyPresentation),
            )
            .stage
            .value,
        'salam_exchange',
      );
      await _returnHeader(tester);
      expect(find.byType(ZyraConceptJourneyPresentation), findsNothing);
      expect(find.byKey(_scope), findsNothing);
      expect(_key('draft_journey_$_sara'), findsOneWidget);
      expect(find.text('Continue Journey'), findsOneWidget);
      expect(
        tester
            .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
            .currentIndex,
        1,
      );
    },
  );

  _case('modal rebuild and Cancel retain a fresh one-route Back return', (
    tester,
  ) async {
    await _mount(tester);
    await _openOneJourney(tester);
    await _tap(tester, 'concept_journey_menu');
    expect(find.byType(ZyraConceptJourneyOptions), findsOneWidget);
    final scopeBeforeResize = tester.widget(
      find.byKey(_scope, skipOffstage: false),
    );
    // Rebuild the parent while the modal flag is true. Closing Cancel must
    // not leave a stale build-time disabled scope after that flag is cleared.
    tester.view.physicalSize = const Size(393, 880);
    tester.element(find.byType(ZyraOneJourneyConceptShell)).markNeedsBuild();
    await tester.pumpAndSettle();
    expect(
      tester.widget(find.byKey(_scope, skipOffstage: false)),
      isNot(same(scopeBeforeResize)),
    );
    expect(find.byType(ZyraConceptJourneyOptions), findsOneWidget);
    await _pullFrom(tester, const Offset(30, 65));
    expect(find.byType(ZyraConceptJourneyOptions), findsOneWidget);
    expect(find.byType(ZyraConceptJourneyPresentation), findsOneWidget);
    final cancel = find.descendant(
      of: find.byType(ZyraConceptJourneyOptions),
      matching: find.widgetWithText(TextButton, 'Cancel'),
    );
    await _tapFinder(tester, cancel);
    expect(find.byType(ZyraConceptJourneyOptions), findsNothing);
    expect(find.byType(ZyraConceptJourneyPresentation), findsOneWidget);
    await _returnHeader(tester);
    expect(find.byType(ZyraConceptJourneyPresentation), findsNothing);
    expect(find.byKey(_scope), findsNothing);
    expect(find.text('Continue Journey'), findsOneWidget);
    expect(
      tester
          .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
          .currentIndex,
      1,
    );
  });

  _case('end confirmation pull is inert and Keep this Journey still works', (
    tester,
  ) async {
    await _mount(tester);
    await _openOneJourney(tester);
    await _tap(tester, 'concept_journey_menu');
    await _tap(tester, 'draft_options_end_$_sara');
    expect(_key('draft_journey_action_$_sara'), findsOneWidget);
    expect(_key('draft_confirm_end_$_sara'), findsOneWidget);
    expect(_key('draft_cancel_end_$_sara'), findsOneWidget);
    await _returnHeader(tester);
    expect(_key('draft_journey_action_$_sara'), findsOneWidget);
    expect(_key('draft_confirm_end_$_sara'), findsOneWidget);
    expect(_key('draft_cancel_end_$_sara'), findsOneWidget);
    await _tap(tester, 'draft_cancel_end_$_sara');
    expect(_key('draft_journey_action_$_sara'), findsNothing);
    expect(find.byType(ZyraConceptJourneyPresentation), findsOneWidget);
    expect(
      tester
          .widget<ZyraConceptJourneyPresentation>(
            find.byType(ZyraConceptJourneyPresentation),
          )
          .stage
          .value,
      'salam_exchange',
    );
    await _returnHeader(tester);
    expect(find.text('Continue Journey'), findsOneWidget);
  });
}
