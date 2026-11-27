import 'support/zyra_hidden_dev_controls_driver.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/dev/zyra_draft_safety_advice_presentation.dart';
import 'package:zyra/dev/zyra_membership_preview.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_subscription_wallet_preview.dart';
import 'package:zyra/dev/zyra_profile_small_pages_preview.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_tap_feedback.dart';

import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/subscription/zyra_one_upgrade_page.dart';

const _roles = [
  (guardian: false, one: true, label: 'Seeker One'),
  (guardian: false, one: false, label: 'Seeker Basic'),
  (guardian: true, one: true, label: 'Guardian One'),
  (guardian: true, one: false, label: 'Guardian Basic'),
];

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Profile tab contract fixtures must remain offline.');
  }
}

Finder _key(String value) => find.byKey(ValueKey(value));

ZyraConceptAccountData _data({
  required bool guardian,
  required bool one,
  String? name,
  String? familyPlacePayer,
}) => ZyraConceptAccountData(
  guardian: guardian,
  name: name ?? (guardian ? 'Hassan Rahman' : 'Adam Khan'),
  age: guardian ? '54' : '30',
  gender: 'Male',
  location: 'London',
  membership: '${guardian ? 'Guardian' : 'Seeker'} ${one ? 'One' : 'Basic'}',
  isOne: one,
  relationship: 'Father',
  linkedSeekers: '1',
  linkedSeekerSummary: 'Adam, Yusuf',
  familyPlacePayer: familyPlacePayer,
  guardianCount: '2',
  signedInWith: 'Apple',
  backgroundLabel: 'Ivory',
  hapticLabel: 'Subtle',
  gold: false,
  plusUnlocks: 3,
);

Map<String, ZyraConceptAccountAction> _rows(bool guardian) => {
  if (guardian)
    'concept_your_seekers': ZyraConceptAccountAction.yourSeekers
  else
    'concept_manage_photos': ZyraConceptAccountAction.managePhotos,
  'concept_membership': ZyraConceptAccountAction.membership,
  if (!guardian)
    'concept_compatibility_buy_more':
        ZyraConceptAccountAction.compatibilityStore,
  'concept_subscriptions': ZyraConceptAccountAction.subscriptions,
  if (!guardian) 'concept_guardian_info': ZyraConceptAccountAction.guardianInfo,
  'concept_safety_advice': ZyraConceptAccountAction.safetyAdvice,
  'concept_invite': ZyraConceptAccountAction.invite,
  'concept_settings': ZyraConceptAccountAction.settings,
  'concept_sign_out': ZyraConceptAccountAction.signOut,
};

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(430, 932),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: page!,
      ),
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _tap(WidgetTester tester, String key) async {
  if (await pressZyraDevControlKey(tester, key)) return;
  final control = _key(key);
  expect(control, findsOneWidget);
  await tester.ensureVisible(control);
  await tester.pumpAndSettle();
  expect(control.hitTestable(), findsOneWidget);
  await tester.tap(control);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _mountShell(
  WidgetTester tester, {
  required bool guardian,
  required bool one,
  required bool Function() canAct,
  required VoidCallback onExit,
}) async {
  var ready = false;
  await _mount(
    tester,
    ZyraOneJourneyConceptShell(
      fixture: ZyraShellTestFixture().fixture,
      key: UniqueKey(),
      canAct: canAct,
      onExit: onExit,
      initialGuardianRole: guardian,
      initialSeekerBasic: !one,
      initialGuardianBasic: !one,
      initialCheckpoint: ZyraPreviewNavigationCheckpoint(
        guardian: guardian,
        model: ViewRequestDraftModel(capacity: one ? 3 : 1).snapshot(),
        tab: 4,
        pages: const [],
        personId: null,
        seekerMembership: one ? 'Seeker One' : 'Seeker Basic',
        guardianMembership: one ? 'Guardian One' : 'Guardian Basic',
      ),
      onPresentationReady: () => ready = true,
    ),
  );
  for (var frame = 0; frame < 150 && !ready; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  expect(ready, isTrue, reason: 'Bundled sample photos must prepare.');
  await tester.pumpAndSettle();
  expect(find.byType(ZyraConceptProfilePresentation), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final oldHttp = HttpOverrides.current;
  final oldStubs = ZyraText.useTestFontStubs;
  final oldFamily = ZyraText.testReadingFontFamily;
  late _NoNetwork network;
  final haptics = <Object?>[];

  setUpAll(() async {
    final font = FontLoader('PoppinsProfileMonogram');
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await font.load();
  });

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsProfileMonogram';
    SharedPreferences.setMockInitialValues({});
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraAccountState.resetForTesting();
    AppState.instance.resetForAccountChange();
    network = _NoNetwork();
    HttpOverrides.global = network;
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        });
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = oldHttp;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = oldStubs;
    ZyraText.testReadingFontFamily = oldFamily;
    ZyraAccountState.resetForTesting();
    AppState.instance.resetForAccountChange();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final role in _roles) {
    testWidgets('${role.label} keeps locked row order and caller actions', (
      tester,
    ) async {
      final actions = <ZyraConceptAccountAction>[];
      var switches = 0;
      await _mount(
        tester,
        ZyraConceptProfilePresentation(
          data: _data(guardian: role.guardian, one: role.one),
          onAction: actions.add,
          onSwitchRole: () => switches++,
        ),
      );
      expect(
        tester.getSize(_key('concept_profile_avatar')),
        const Size(84, 84),
      );
      expect(
        tester.getTopLeft(_key('concept_profile_name')).dx -
            tester.getTopRight(_key('concept_profile_avatar')).dx,
        closeTo(16, .01),
      );
      expect(
        tester.widget<Text>(_key('concept_profile_name')).style?.fontSize,
        24,
      );
      // LOCK 47 shows the plan name alone in the Profile header.
      expect(find.text(role.label.toUpperCase()), findsOneWidget);
      expect(find.text('Your places'), findsOneWidget);
      expect(find.text('Membership'), findsOneWidget);
      expect(find.text(role.label), findsOneWidget);
      expect(find.text('See One'), findsNothing);
      for (final id in [
        if (!role.guardian) ...[
          'concept_preview_profile',
          'concept_edit_profile',
        ],
        'switch-account-button',
      ]) {
        final painted = tester.getRect(_key('${id}_surface'));
        final target = tester.getRect(_key(id));
        expect(painted.height, closeTo(34, .01), reason: id);
        expect(target.height, greaterThanOrEqualTo(44), reason: id);
        expect(target.width, greaterThanOrEqualTo(44), reason: id);
        expect(target.center, painted.center, reason: id);
      }
      if (role.guardian) {
        expect(find.text('Adam, Yusuf'), findsOneWidget);
        expect(_key('concept_preview_profile'), findsNothing);
        expect(_key('concept_edit_profile'), findsNothing);
      } else {
        expect(find.text('3 left'), findsOneWidget);
        await _tap(tester, 'concept_preview_profile');
        await _tap(tester, 'concept_edit_profile');
      }
      for (final removed in [
        'ABOUT ME',
        'About me',
        'Age',
        'Gender',
        'Location',
        'Relationship',
        'Linked Seekers',
        'MEMBERSHIP',
        'COMPATIBILITY',
        'YOUR PROFILE',
        'SAFETY & SHARING',
        'PERSONALISATION',
        'Preview my profile',
        'Edit profile',
        'Your subscriptions',
        'Past Journeys',
        'Manage membership',
        'See Guardian One',
        'See Seeker One',
        '3 left · 3 more each month',
        'Who your membership covers',
        'Account, privacy, notifications, haptics',
      ]) {
        expect(find.text(removed), findsNothing, reason: removed);
      }
      final rows = _rows(role.guardian);
      final y = rows.keys
          .map((key) => tester.getTopLeft(_key(key)).dy)
          .toList();
      expect(y, orderedEquals([...y]..sort()));
      final signOut = _key('concept_sign_out');
      final signOutText = find.descendant(
        of: signOut,
        matching: find.text('Sign out'),
      );
      expect(
        tester.widget<Text>(signOutText).style?.color,
        const Color(0xFFAC453E),
      );
      expect(
        find.descendant(
          of: signOut,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Icon &&
                (widget.icon == Icons.chevron_right ||
                    widget.icon == Icons.chevron_right_rounded),
          ),
        ),
        findsNothing,
      );
      for (final key in rows.keys) {
        await _tap(tester, key);
      }
      expect(actions, [
        if (!role.guardian) ...[
          ZyraConceptAccountAction.previewProfile,
          ZyraConceptAccountAction.editProfile,
        ],
        ...rows.values,
      ]);
      await _tap(tester, 'switch-account-button');
      expect(switches, 1);
      final switchTarget = tester.getRect(_key('switch-account-button'));
      await tester.tapAt(Offset(switchTarget.center.dx, switchTarget.top + 2));
      await tester.pumpAndSettle();
      expect(switches, 2, reason: 'The area above the visible pill also taps.');
    });

    testWidgets('${role.label} Larger Text keeps targets and action labels', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await _mount(
          tester,
          ZyraConceptProfilePresentation(
            data: _data(guardian: role.guardian, one: role.one),
            onAction: (_) {},
            onSwitchRole: () {},
          ),
          size: const Size(320, 568),
          scale: 2,
        );
        final pills = [
          if (!role.guardian) ...[
            'concept_preview_profile',
            'concept_edit_profile',
          ],
          'switch-account-button',
        ];
        final rects = pills.map((key) => tester.getRect(_key(key))).toList();
        if (!role.guardian) {
          expect(
            rects.map((rect) => rect.top).toSet().length,
            greaterThan(1),
            reason: 'The three Seeker pills wrap at 320px and 200% text.',
          );
        }
        for (final rect in rects) {
          expect(rect.width, greaterThanOrEqualTo(44));
          expect(rect.height, greaterThanOrEqualTo(44));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(320));
        }
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            expect(rects[i].overlaps(rects[j]), isFalse);
          }
        }
        for (final key in [...pills, ..._rows(role.guardian).keys]) {
          final row = _key(key);
          await tester.ensureVisible(row);
          await tester.pumpAndSettle();
          final label = tester.getSemantics(row).getSemanticsData().label;
          final isPill = pills.contains(key);
          final textRoot = isPill ? _key('${key}_surface') : row;
          expect(textRoot, findsOneWidget, reason: key);
          for (final element
              in find
                  .descendant(of: textRoot, matching: find.byType(Text))
                  .evaluate()) {
            final text = element.widget as Text;
            expect(label, contains(text.data!), reason: key);
            final paragraph = tester.renderObject<RenderParagraph>(
              find.byWidget(text),
            );
            if (isPill) {
              expect(paragraph.didExceedMaxLines, isFalse, reason: key);
            } else {
              expect(text.maxLines, 1, reason: key);
            }
          }
          expect(tester.takeException(), isNull);
        }
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
      '${role.label} retains membership, places and settings destinations',
      (tester) async {
        Future<void> start() => _mountShell(
          tester,
          guardian: role.guardian,
          one: role.one,
          canAct: () => true,
          onExit: () => fail('A destination cannot exit.'),
        );
        await start();
        await _tap(tester, 'concept_membership');
        if (role.one) {
          final membership = tester.widget<ZyraMembershipPreview>(
            find.byType(ZyraMembershipPreview),
          );
          expect(membership.guardian, role.guardian);
        } else {
          final upgrade = tester.widget<ZyraOneUpgradePage>(
            find.byType(ZyraOneUpgradePage),
          );
          expect(upgrade.guardian, role.guardian);
        }
        await start();
        await _tap(tester, 'concept_subscriptions');
        expect(
          find.byType(
            role.guardian ? ZyraGuardianPlacesPreview : ZyraSeekerPlacesPreview,
          ),
          findsOneWidget,
        );
        await start();
        await _tap(tester, 'concept_settings');
        expect(find.byType(ZyraConceptSettingsPresentation), findsOneWidget);
        expect(find.text('Appearance & haptics'), findsNothing);
        await start();
        await _tap(tester, 'concept_safety_advice');
        expect(
          find.byType(ZyraDraftSafetyAdvicePresentation),
          findsOneWidget,
          reason: 'LOCK22 V5/V6 provides advice for each role.',
        );
        await start();
        await _tap(tester, 'concept_invite');
        final invite = tester.widget<ZyraInvitePreview>(
          find.byType(ZyraInvitePreview),
        );
        expect(invite.guardian, role.guardian);
        expect(_key('small_pages_invite_scroll'), findsOneWidget);
        expect(find.text('Invite someone to ZYRA'), findsOneWidget);
        expect(
          find.text(
            role.guardian ? 'zyra.app/i/HASSAN3K' : 'zyra.app/i/ADAM7Q',
          ),
          findsOneWidget,
        );
        expect(_key('small_pages_copy_link'), findsOneWidget);
        expect(_key('small_pages_share_link'), findsOneWidget);
        if (role.guardian) {
          await start();
          await _tap(tester, 'concept_your_seekers');
          expect(
            tester
                .widget<ZyraGuardianTabsPresentation>(
                  find.byType(ZyraGuardianTabsPresentation),
                )
                .page,
            'seekers',
          );
        }
      },
    );
  }

  for (final guardian in [false, true]) {
    testWidgets(
      'Profile wraps long ${guardian ? 'Guardian' : 'Seeker'} names',
      (tester) async {
        const name = 'A Longer Name That Wraps on Profile';
        await _mount(
          tester,
          ZyraConceptProfilePresentation(
            data: _data(
              guardian: guardian,
              one: true,
              name: name,
              familyPlacePayer: guardian ? 'Adam' : null,
            ),
            onAction: (_) {},
            onSwitchRole: () {},
          ),
        );
        final label = _key('concept_profile_name');
        final text = tester.widget<Text>(label);
        expect(text.data, name);
        expect(text.maxLines, isNull);
        expect(text.overflow, isNot(TextOverflow.ellipsis));
        final paragraph = tester.renderObject<RenderParagraph>(label);
        expect(paragraph.didExceedMaxLines, isFalse);
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: name.length),
        );
        expect(boxes.map((box) => box.top).toSet().length, greaterThan(1));
        expect(
          find.descendant(
            of: _key('concept_membership'),
            matching: find.text('Paid by Adam'),
          ),
          guardian ? findsOneWidget : findsNothing,
        );
      },
    );
  }

  for (final level in [ZyraHapticLevel.off, ZyraHapticLevel.subtle]) {
    testWidgets(
      'Profile controls obey ${level.label} and revoke disabled taps',
      (tester) async {
        var allowed = true;
        final actions = <ZyraConceptAccountAction>[];
        var switches = 0;
        await _mount(
          tester,
          ZyraTapFeedback(
            level: () => level,
            canAct: () => allowed,
            child: ZyraConceptProfilePresentation(
              data: _data(guardian: false, one: true),
              onAction: actions.add,
              onSwitchRole: () => switches++,
            ),
          ),
        );
        final controls = [
          'concept_preview_profile',
          'concept_edit_profile',
          ..._rows(false).keys,
          'switch-account-button',
        ];
        for (final key in controls) {
          await _tap(tester, key);
        }
        expect(actions.length, controls.length - 1);
        expect(switches, 1);
        expect(
          haptics,
          level == ZyraHapticLevel.off
              ? isEmpty
              : List.filled(
                  controls.length,
                  'HapticFeedbackType.selectionClick',
                ),
        );
        allowed = false;
        final before = actions.length;
        haptics.clear();
        for (final key in controls) {
          await _tap(tester, key);
        }
        expect(actions.length, before);
        expect(switches, 1);
        expect(haptics, isEmpty);
      },
    );
  }

  for (final change in ['revoked admission', 'account generation', 'route']) {
    testWidgets('retained Profile actions reject changed $change owner', (
      tester,
    ) async {
      var allowed = true;
      var exits = 0;
      await _mountShell(
        tester,
        guardian: false,
        one: true,
        canAct: () => allowed,
        onExit: () => exits++,
      );
      final presentation = tester.widget<ZyraConceptProfilePresentation>(
        find.byType(ZyraConceptProfilePresentation),
      );
      if (change == 'revoked admission') {
        allowed = false;
      } else if (change == 'account generation') {
        ZyraAccountState.resetForTesting();
      } else {
        await _tap(tester, 'concept_settings');
        expect(find.byType(ZyraConceptSettingsPresentation), findsOneWidget);
      }
      for (final action in [
        ZyraConceptAccountAction.previewProfile,
        ZyraConceptAccountAction.editProfile,
        ..._rows(false).values,
      ]) {
        presentation.onAction(action);
      }
      presentation.onSwitchRole();
      await tester.pumpAndSettle();
      expect(exits, 0);
      expect(find.byType(ZyraSubscriptionWalletPreview), findsNothing);
      expect(find.byType(ZyraSeekerPlacesPreview), findsNothing);
      expect(find.byType(ZyraGuardianPlacesPreview), findsNothing);
      expect(find.byType(ZyraInvitePreview), findsNothing);
      expect(find.byType(ZyraConceptMembershipPresentation), findsNothing);
      expect(
        find.byType(ZyraConceptSettingsPresentation),
        change == 'route' ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(ZyraConceptProfilePresentation),
        change == 'route' ? findsNothing : findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
