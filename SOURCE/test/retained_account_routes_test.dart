import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_request_account_session.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/screens/profile/edit_photos_screen.dart';
import 'package:zyra/screens/profile/edit_profile_screen.dart';
import 'package:zyra/screens/profile/my_profile_preview_screen.dart';
import 'package:zyra/screens/settings/personalisation_screen.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'package:zyra/widgets/zyra_personalisation_content.dart';
import 'package:zyra/widgets/zyra_loading.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

class _NoNetwork extends HttpOverrides {
  int calls = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    ++calls;
    throw StateError('Account reuse must stay offline.');
  }
}

Finder _key(String name) => find.byKey(ValueKey(name));

Future<void> _mount(
  WidgetTester tester, {
  bool guardian = false,
  bool waitForPhotos = true,
}) async {
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
        onExit: () => fail('Account return must not exit the app.'),
        initialGuardianRole: guardian,
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (!guardian && waitForPhotos) {
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        final deck = tester.widget<ZyraOneJourneyBrowseDesigns>(
          find.byType(ZyraOneJourneyBrowseDesigns),
        );
        if (deck.profiles.isNotEmpty && deck.profiles.first.photos.isNotEmpty) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await tester.pump();
      }
      fail(
        'Retained account routes require the prepared local photo snapshot.',
      );
    });
    await tester.pumpAndSettle();
  }
}

Finder _visibleVerticalScroll() => find
    .byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
    )
    .hitTestable();

Future<void> _reveal(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    // The current page may own a lazy ListView or a shadow-clearance wrapper.
    // Its visible vertical Scrollable remains the authority for finding rows.
    final scroll = _visibleVerticalScroll();
    expect(scroll, findsOneWidget);
    final position = tester.state<ScrollableState>(scroll).position;
    position.jumpTo(position.minScrollExtent);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      target,
      180,
      scrollable: scroll,
      maxScrolls: 40,
    );
  }
  expect(target, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = _key(key);
  await _reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _profile(WidgetTester tester) => _tapTab(tester, 'Profile');

Future<void> _tapTab(WidgetTester tester, String label) async {
  await expandZyraPreviewTabBarIfIdle(tester);
  final navigation = find.byType(ZyraShellNavigation);
  final nav = tester.widget<ZyraShellNavigation>(navigation);
  final index = nav.items.indexWhere((item) => item.label == label);
  expect(index, greaterThanOrEqualTo(0));
  final icon = find.descendant(
    of: navigation,
    matching: find.byIcon(nav.items[index].icon),
  );
  expect(icon, findsOneWidget);
  // The floating bar intentionally ignores per-icon hit tests and handles
  // taps/scrubs in its shared parent recognizer. Tap the real visible cell.
  final rect = tester.getRect(icon);
  expect(rect.isEmpty, isFalse);
  expect(
    (Offset.zero & (tester.view.physicalSize / tester.view.devicePixelRatio))
        .contains(rect.center),
    isTrue,
  );
  await tester.tapAt(rect.center);
  await tester.pumpAndSettle();
  expect(tester.widget<ZyraShellNavigation>(navigation).currentIndex, index);
  expect(tester.takeException(), isNull);
}

Future<void> _returnPage(WidgetTester tester) => returnZyraPreviewPage(tester);

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
    'session keeps owner roles separate, rejects remote photos and revokes',
    () {
      var allowed = true;
      final session = ZyraRequestAccountSession(
        canAct: () => allowed,
        palette: ZyraDevPalette.midnightPlum,
        hapticLevel: ZyraHapticLevel.subtle,
        goldEnabled: false,
      );
      final photos = ['data:image/jpeg;base64,YQ=='];
      expect(session.seedPhotos(false, photos), isTrue);
      photos.add('data:image/jpeg;base64,Yg==');
      expect(session.photos(false), hasLength(1));
      expect(session.photos(true), isEmpty);
      expect(
        session.setPhotos(false, ['https://example.invalid/photo']),
        isFalse,
      );
      expect(session.setPhotos(false, []), isFalse);
      expect(session.setAvatar(false, const Offset(2, -3)), isTrue);
      expect(session.avatar(false), const Offset(1, -1));
      allowed = false;
      expect(session.setGoldEnabled(true), isFalse);
      allowed = true;
      expect(session.current, isFalse);
      expect(session.setPalette(ZyraDevPalette.deepEmerald), isFalse);
      session.dispose();
    },
  );

  test(
    'compatibility repository detaches and canonicalises without a global merge',
    () async {
      final repository = ZyraRequestCompatibilityRepository(canAct: () => true);
      final values = <String>['A'];
      final draft = ZyraCompatibilityDraft(
        gender: 'male',
        answers: {
          'ch3_q26::male': values,
          'bio_intro': 'Only this local draft',
        },
        preferences: {
          'ch3_q26::male': {'A': TrafficLight.green},
        },
        hardRequirements: {
          'ch3_q26::male': {'B'},
        },
      );
      expect(await repository.save('draft-self', draft), isTrue);
      values.add('B');
      draft.preferences.clear();
      final loaded = (await repository.load('draft-self'))!;
      expect(loaded.ch3Answers['ch3_q26'], ['A']);
      expect(loaded.ch4Preferences['ch3_q26'], {'A': TrafficLight.green});
      loaded.ch3Answers['ch3_q26'].add('changed');
      expect((await repository.load('draft-self'))!.ch3Answers['ch3_q26'], [
        'A',
      ]);
      expect(await repository.load('another-account'), isNull);
      repository.close();
      expect(await repository.save('draft-self', draft), isFalse);
    },
  );

  for (final destination in ['concept_edit_profile', 'concept_manage_photos']) {
    testWidgets(
      '$destination opens the retained editor and returns one parent',
      (tester) async {
        final network = _NoNetwork();
        var writes = 0;
        void changed() => ++writes;
        AppState.instance.addListener(changed);
        addTearDown(() => AppState.instance.removeListener(changed));
        await HttpOverrides.runWithHttpOverrides(() async {
          await _mount(tester);
          await _profile(tester);
          await _tap(tester, destination);
          expect(
            find.byType(
              destination == 'concept_edit_profile'
                  ? EditProfileScreen
                  : EditPhotosScreen,
            ),
            findsOneWidget,
          );
          expect(_key('concept_account_action_scroll'), findsNothing);
          expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
          await _returnPage(tester);
          expect(find.byType(ZyraShellNavigation), findsOneWidget);
          expect(find.text('Profile'), findsOneWidget);
          await tester.pumpWidget(const SizedBox.shrink());
        }, network);
        expect(network.calls, 0);
        expect(writes, 0);
      },
    );
  }

  for (final guardian in [false, true]) {
    testWidgets(
      'retained ${guardian ? 'Guardian' : 'Seeker'} Profile and Settings keep their own paid label and avatar semantics',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final network = _NoNetwork();
          final originalPlan = AppState.instance.plan;
          final originalGuardianOne = AppState.instance.waliHasWaliOne;
          var writes = 0;
          void changed() => ++writes;
          AppState.instance.addListener(changed);
          addTearDown(() => AppState.instance.removeListener(changed));
          final title = guardian ? 'Guardian One' : 'Seeker One';
          final otherTitle = guardian ? 'Seeker One' : 'Guardian One';
          final accountName = guardian ? 'Hassan Rahman' : 'Adam Khan';
          await HttpOverrides.runWithHttpOverrides(() async {
            await _mount(tester, guardian: guardian);
            await _tapTab(tester, 'Profile');
            await _reveal(tester, find.text(title));
            expect(find.text(title), findsOneWidget);
            expect(find.text(otherTitle), findsNothing);
            expect(find.textContaining('ZYRA One'), findsNothing);
            expect(
              find.descendant(
                of: _key('concept_membership'),
                matching: find.text(title),
              ),
              findsOneWidget,
            );
            await _reveal(tester, find.text(accountName));
            final avatar = _key('concept_profile_avatar');
            expect(avatar, findsOneWidget);
            expect(tester.getSize(avatar), const Size(104, 104));
            if (guardian) expect(find.text('H'), findsOneWidget);
            expect(find.text(accountName), findsOneWidget);
            expect(
              tester.getSemantics(avatar),
              matchesSemantics(label: '$title profile', isImage: true),
            );
            final switchSemantics = tester
                .getSemantics(_key('switch-account-button'))
                .getSemanticsData();
            expect(switchSemantics.label, 'Switch');
            expect(switchSemantics.hasAction(ui.SemanticsAction.tap), isTrue);
            expect(switchSemantics.flagsCollection.isButton, isTrue);
            await _tap(tester, 'concept_settings');
            expect(find.text('Settings'), findsOneWidget);
            expect(find.text(title), findsWidgets);
            expect(find.text(otherTitle), findsNothing);
            expect(find.textContaining('ZYRA One'), findsNothing);
            await _returnPage(tester);
            expect(find.text('Profile'), findsOneWidget);
            await _reveal(tester, find.text(title));
            expect(find.text(title), findsOneWidget);
            await tester.pumpWidget(const SizedBox.shrink());
          }, network);
          expect(network.calls, 0);
          expect(writes, 0);
          expect(AppState.instance.plan, originalPlan);
          expect(AppState.instance.waliHasWaliOne, originalGuardianOne);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  for (final destination in [
    'concept_manage_photos',
    'concept_preview_profile',
  ]) {
    testWidgets(
      '$destination uses the canonical reduced-motion loader only while its actual photo preparation is pending',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          const firstAsset = 'assets/dev/one_journey_photos/zyra1a.jpg';
          // Hold one genuine bundled-file response, not the shell's private
          // state or a fabricated route clock. All other assets keep using
          // their real test-engine bundle through the messenger delegate.
          final original = await tester.runAsync(
            () => rootBundle.load(firstAsset),
          );
          expect(original, isNotNull);
          final heldResponse = Completer<ByteData?>();
          var heldLoads = 0;
          final messenger =
              TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
          messenger.setMockMessageHandler('flutter/assets', (message) {
            final asset = const StringCodec().decodeMessage(message);
            if (asset == firstAsset) {
              ++heldLoads;
              return heldResponse.future;
            }
            return messenger.delegate.send('flutter/assets', message);
          });
          addTearDown(() {
            if (!heldResponse.isCompleted) heldResponse.complete(original);
            messenger.setMockMessageHandler('flutter/assets', null);
          });
          final network = _NoNetwork();
          var writes = 0;
          void changed() => ++writes;
          AppState.instance.addListener(changed);
          addTearDown(() => AppState.instance.removeListener(changed));
          await HttpOverrides.runWithHttpOverrides(() async {
            await _mount(tester, waitForPhotos: false);
            expect(heldLoads, 1);
            await _tapTab(tester, 'Profile');
            await _tap(tester, destination);
            expect(find.byType(ZyraLoading), findsOneWidget);
            expect(_key('zyra_loading_cometLoop'), findsOneWidget);
            expect(find.bySemanticsLabel('Loading'), findsOneWidget);
            expect(find.byType(CircularProgressIndicator), findsNothing);
            expect(find.byType(EditPhotosScreen), findsNothing);
            expect(find.byType(MyProfilePreviewScreen), findsNothing);
            expect(tester.binding.transientCallbackCount, 0);
            await tester.pump(const Duration(milliseconds: 700));
            expect(find.byType(ZyraLoading), findsOneWidget);
            expect(tester.binding.transientCallbackCount, 0);

            heldResponse.complete(original);
            final retainedType = destination == 'concept_manage_photos'
                ? EditPhotosScreen
                : MyProfilePreviewScreen;
            await tester.runAsync(() async {
              final deadline = DateTime.now().add(const Duration(seconds: 5));
              while (DateTime.now().isBefore(deadline)) {
                await tester.pump();
                if (find.byType(retainedType).evaluate().isNotEmpty) return;
                await Future<void>.delayed(const Duration(milliseconds: 5));
              }
              fail(
                'The retained leaf must appear when real photo preparation completes.',
              );
            });
            await tester.pumpAndSettle();
            expect(find.byType(retainedType), findsOneWidget);
            expect(find.byType(ZyraLoading), findsNothing);
            expect(_key('my-profile-preview-unavailable'), findsNothing);
            expect(tester.takeException(), isNull);
            await _returnPage(tester);
            expect(find.text('Profile'), findsOneWidget);
            expect(find.byType(ZyraShellNavigation), findsOneWidget);
            await tester.pumpWidget(const SizedBox.shrink());
          }, network);
          expect(network.calls, 0);
          expect(writes, 0);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets(
    'local Personalisation applies and survives reopening without global writes',
    (tester) async {
      final palette = ZyraColors.devPalette;
      final haptics = ZyraInteractionStyle.hapticLevel;
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        await _profile(tester);
        await _tap(tester, 'concept_personalisation');
        expect(find.byType(PersonalisationScreen), findsOneWidget);
        expect(_key('personalisation_background'), findsNothing);
        expect(
          tester
              .widget<ZyraPersonalisationContent>(
                find.byType(ZyraPersonalisationContent),
              )
              .snapshot
              .palette,
          ZyraDevPalette.ivory,
        );
        await _tap(tester, 'personalisation_gold_toggle');
        expect(
          tester.widget<Switch>(_key('personalisation_gold_toggle')).value,
          isTrue,
        );
        await _tap(tester, 'personalisation_haptic');
        await tester.tap(find.text('Strong'));
        await tester.pumpAndSettle();
        expect(find.text('Strong'), findsOneWidget);
        await _returnPage(tester);
        await _tap(tester, 'concept_personalisation');
        expect(_key('personalisation_background'), findsNothing);
        expect(
          tester.widget<Switch>(_key('personalisation_gold_toggle')).value,
          isTrue,
        );
        expect(find.text('Strong'), findsOneWidget);
        await _returnPage(tester);
        await _tap(tester, 'concept_preview_profile');
        expect(find.byType(MyProfilePreviewScreen), findsOneWidget);
        expect(find.text('Adam'), findsOneWidget);
        await _returnPage(tester);
        expect(find.byType(ZyraShellNavigation), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      }, network);
      expect(network.calls, 0);
      expect(ZyraColors.devPalette, palette);
      expect(ZyraInteractionStyle.hapticLevel, haptics);
    },
  );

  for (final level in [ZyraHapticLevel.off, ZyraHapticLevel.strong]) {
    testWidgets(
      'local ${level.label} governs actual Browse invitation haptics without changing member preferences',
      (tester) async {
        const owner = 'retained-haptic-member';
        final originalHaptic = ZyraInteractionStyle.hapticLevel;
        final network = _NoNetwork();
        SharedPreferences.setMockInitialValues({
          'zyra.cached_account_owner': owner,
          'zyra.haptic_level': ZyraHapticLevel.light.name,
          'retained-haptic-sentinel': 'unchanged',
        });
        await tester.runAsync(() async {
          await ZyraLocalPrefs.init();
          await ZyraLocalPrefs.bindAccount(owner);
        });
        ZyraInteractionStyle.restoreHapticLevel(ZyraHapticLevel.light.name);
        addTearDown(() async {
          ZyraInteractionStyle.restoreHapticLevel(originalHaptic.name);
          await ZyraLocalPrefs.bindAccount(null);
        });
        final calls = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              calls.add(call);
              return null;
            });
        await HttpOverrides.runWithHttpOverrides(() async {
          await _mount(tester);
          await _tapTab(tester, 'Profile');
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
          await _tapTab(tester, 'Profiles');
          final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
            find.byType(ZyraOneJourneyBrowseDesigns),
          );
          final person = browse.profiles[browse.selectedIndex];
          expect(browse.requestLabel!(person), 'Request a Journey');
          calls.clear();
          await _tap(tester, 'draft_profile_${person.id}');
          final requested = tester.widget<ZyraOneJourneyBrowseDesigns>(
            find.byType(ZyraOneJourneyBrowseDesigns),
          );
          expect(requested.profiles[requested.selectedIndex].id, person.id);
          expect(requested.requestLabel!(person), 'Request sent');
          expect(
            calls
                .where((call) => call.method == 'HapticFeedback.vibrate')
                .map((call) => call.arguments)
                .toList(),
            level == ZyraHapticLevel.off
                ? isEmpty
                : equals(['HapticFeedbackType.heavyImpact']),
          );
          calls.clear();
          await _tap(tester, 'draft_profile_${person.id}');
          final cancelled = tester.widget<ZyraOneJourneyBrowseDesigns>(
            find.byType(ZyraOneJourneyBrowseDesigns),
          );
          expect(cancelled.requestLabel!(person), 'Request a Journey');
          expect(
            calls
                .where((call) => call.method == 'HapticFeedback.vibrate')
                .map((call) => call.arguments)
                .toList(),
            level == ZyraHapticLevel.off
                ? isEmpty
                : equals(['HapticFeedbackType.heavyImpact']),
          );
          await tester.pumpWidget(const SizedBox.shrink());
        }, network);
        expect(network.calls, 0);
        expect(ZyraInteractionStyle.hapticLevel, ZyraHapticLevel.light);
        expect(
          ZyraLocalPrefs.cachedHapticLevelName,
          ZyraHapticLevel.light.name,
        );
        final persisted = await tester.runAsync(() async {
          // Same-owner binding drains any queued writes without changing the
          // synthetic member's preference owner or its existing values.
          await ZyraLocalPrefs.bindAccount(owner);
          final prefs = await SharedPreferences.getInstance();
          await prefs.reload();
          return {for (final key in prefs.getKeys()) key: prefs.get(key)};
        });
        expect(persisted, {
          'zyra.cached_account_owner': owner,
          'zyra.haptic_level': ZyraHapticLevel.light.name,
          'retained-haptic-sentinel': 'unchanged',
        });
      },
    );
  }

  testWidgets(
    'own profile preview survives harmless shell rebuilds and repeatedly returns one parent',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(tester);
        await _profile(tester);
        for (var visit = 0; visit < 2; ++visit) {
          await _tap(tester, 'concept_preview_profile');
          final preview = find.byType(MyProfilePreviewScreen);
          expect(preview, findsOneWidget);
          final state = tester.state(preview);
          tester
              .element(find.byType(ZyraOneJourneyConceptShell))
              .markNeedsBuild();
          await tester.pumpAndSettle();
          expect(preview, findsOneWidget);
          expect(identical(tester.state(preview), state), isTrue);
          expect(find.text('Adam'), findsOneWidget);
          expect(_key('my-profile-preview-unavailable'), findsNothing);
          await _returnPage(tester);
          expect(preview, findsNothing);
          expect(find.byType(ZyraShellNavigation), findsOneWidget);
          expect(find.text('Profile'), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }, network);
      expect(network.calls, 0);
    },
  );
}
