import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/screens/profile/profile_screen.dart';
import 'package:zyra/screens/subscription/upgrade_screen.dart';
import 'package:zyra/screens/wali/wali_profile_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_notification_prefs_service.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_one_profile_avatar.dart';

const _ordinaryGuardianId = '00000000-0000-4000-8000-000000003771';
const _ordinaryGuardianHost = 'profile-hierarchy.invalid';

int _tapActions(SemanticsNode node) {
  var count = node.getSemanticsData().hasAction(ui.SemanticsAction.tap) ? 1 : 0;
  node.visitChildren((child) {
    count += _tapActions(child);
    return true;
  });
  return count;
}

Future<void> _tapStoreBack(WidgetTester tester, {bool arrow = false}) async {
  final back = find.byKey(const ValueKey('compatibility-store-back'));
  expect(back, findsOneWidget);
  expect(tester.widget<TextButton>(back).onPressed, isNotNull);
  final target = find.descendant(
    of: back,
    matching: arrow ? find.byIcon(Icons.arrow_back) : find.text('Back'),
  );
  expect(target, findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

class _NoExternalNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Ordinary Guardian hierarchy fixtures must stay offline.');
  }
}

Future<void> _ordinaryGuardianSession() async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await Supabase.instance.client.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': _ordinaryGuardianId, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': _ordinaryGuardianId,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-18T00:00:00Z',
      },
    }),
  );
  await ZyraAccountState.synchronize(_ordinaryGuardianId);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    AppState.instance.resetForAccountChange();
  });

  tearDown(() {
    AppState.instance.resetForAccountChange();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = false;
  });

  Future<void> pumpProfile(WidgetTester tester, Widget profile) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: profile)));
    await tester.pump();
  }

  testWidgets('Seeker orders membership, compatibility, profile and about', (
    tester,
  ) async {
    AppState.instance.plan = ZyraPlan.one;
    await pumpProfile(tester, const ProfileScreen());

    final list = tester.widget<ListView>(find.byType(ListView));
    final sectionLabels = (list.childrenDelegate as SliverChildListDelegate)
        .children
        .whereType<Text>()
        .map((text) => text.data)
        .whereType<String>()
        .toList();
    expect(
      sectionLabels.where(
        (label) => const {
          'MEMBERSHIP',
          'COMPATIBILITY',
          'YOUR PROFILE',
          'ABOUT ME',
        }.contains(label),
      ),
      orderedEquals(const [
        'MEMBERSHIP',
        'COMPATIBILITY',
        'YOUR PROFILE',
        'ABOUT ME',
      ]),
    );

    expect(
      find.byKey(const ValueKey('seeker-profile-membership')),
      findsOneWidget,
    );
    expect(find.text('MEMBERSHIP'), findsOneWidget);
    expect(find.text('Seeker One'), findsOneWidget);
    expect(find.byKey(const ValueKey('membership-manage')), findsOneWidget);
    expect(
      tester
          .widget<ZyraOneProfileAvatar>(find.byType(ZyraOneProfileAvatar))
          .isOne,
      isTrue,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profile-compatibility-balances')),
      240,
    );
    expect(
      find.byKey(const ValueKey('profile-compatibility-balances')),
      findsOneWidget,
    );
    expect(find.text('Use these from another member’s profile'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('profile-compatibility-balances')),
        matching: find.byIcon(Icons.chevron_right_rounded),
      ),
      findsOneWidget,
    );
    final buyMore = find.byKey(
      const ValueKey('profile-compatibility-buy-more'),
    );
    expect(buyMore, findsOneWidget);
    expect(tester.widget<InkWell>(buyMore).onTap, isNotNull);
    await tester.tap(find.text('Compatibility unlocks'));
    await tester.pumpAndSettle();
    expect(find.byType(CompatibilityUnlockStoreScreen), findsOneWidget);
    expect(find.text('Compatibility Unlocks'), findsWidgets);
    expect(find.text('See your overall match score'), findsNothing);
    expect(
      find.byKey(const ValueKey('draft_compatibility_store_use_unlocks')),
      findsNothing,
    );
    // LOCK 22 V1, UNITY_PASS/MASTERS/x02–x03 replaces the info sheet
    // with the eight-page illustrated preview on the store itself.
    final previewPosition = find.byKey(
      const ValueKey('draft_compatibility_store_preview_position'),
    );
    expect(tester.widget<Text>(previewPosition).data, '1 / 8');
    final nextPreview = find.byKey(
      const ValueKey('draft_compatibility_store_preview_next'),
    );
    await tester.ensureVisible(nextPreview);
    await tester.pumpAndSettle();
    await tester.tap(nextPreview);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(previewPosition).data, '2 / 8');
    expect(
      find.byKey(const ValueKey('draft_compatibility_store_example_1')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('draft_compatibility_store_preview_previous')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(previewPosition).data, '1 / 8');
    expect(find.text('Current membership'), findsNothing);
    // LOCK 22 V1, UNITY_PASS/MASTERS/x02: the default pack stays 3 Unlocks.
    expect(find.text('3 Unlocks'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('draft_compatibility_store_unlock_single')),
      findsOneWidget,
    );
    await _tapStoreBack(tester);
    expect(find.byType(CompatibilityUnlockStoreScreen), findsNothing);
    expect(find.byType(ProfileScreen), findsOneWidget);
    await tester.ensureVisible(buyMore);
    await tester.pumpAndSettle();
    final arrow = find.descendant(
      of: buyMore,
      matching: find.byIcon(Icons.chevron_right_rounded),
    );
    await tester.tap(arrow);
    await tester.pumpAndSettle();
    expect(find.byType(CompatibilityUnlockStoreScreen), findsOneWidget);
    await _tapStoreBack(tester, arrow: true);
    expect(find.byType(CompatibilityUnlockStoreScreen), findsNothing);
    expect(find.byType(ProfileScreen), findsOneWidget);
    await tester.scrollUntilVisible(find.text('SAFETY & SHARING'), 240);
    expect(find.text('SAFETY & SHARING'), findsOneWidget);
    expect(find.text('SAFETY & SUPPORT'), findsNothing);
    expect(find.text('Safety & advice'), findsOneWidget);
    expect(find.text('Invite someone to ZYRA'), findsOneWidget);
  });

  for (final viewport in const [
    (size: Size(393, 852), scale: 1.0),
    (size: Size(320, 568), scale: 2.0),
  ]) {
    testWidgets(
      'Seeker Profile Unlocks word, arrow and padding open the same page once at ${viewport.size.width}/${viewport.scale}',
      (tester) async {
        final network = _NoExternalNetwork();
        final semantics = tester.ensureSemantics();
        try {
          await HttpOverrides.runWithHttpOverrides(() async {
            tester.view.physicalSize = viewport.size;
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = viewport.scale;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            AppState.instance.plan = ZyraPlan.one;
            final app = AppState.instance;
            List<Object?> memberState() => [
              app.name,
              app.plan,
              app.waliHasWaliOne,
              List.of(app.photos),
              List.of(app.saved),
              List.of(app.potentialJourneys),
              List.of(app.activeJourneys),
            ];
            final beforeMember = memberState();
            await tester.pumpWidget(
              const MaterialApp(home: Scaffold(body: ProfileScreen())),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: 'The actual Profile header must fit before navigation.',
            );
            final membership = find.byKey(const ValueKey('membership-manage'));
            await tester.scrollUntilVisible(membership, 180);
            final membershipArrow = find.descendant(
              of: membership,
              matching: find.byIcon(Icons.chevron_right_rounded),
            );
            final membershipIcon = tester.widget<Icon>(membershipArrow);
            final membershipRight = tester.getRect(membershipArrow).right;
            expect(membershipIcon.size, 18);
            expect(membershipIcon.color, ZyraColors.ink(.28));
            final edit = find.byKey(const ValueKey('edit-profile-action'));
            await tester.scrollUntilVisible(edit, 180);
            final editArrow = find.descendant(
              of: edit,
              matching: find.byIcon(Icons.chevron_right_rounded),
            );
            final editIcon = tester.widget<Icon>(editArrow);
            expect(editIcon.size, membershipIcon.size);
            expect(editIcon.color, membershipIcon.color);
            expect(
              tester.getRect(editArrow).right,
              closeTo(membershipRight, .01),
            );
            final row = find.byKey(
              const ValueKey('profile-compatibility-balances'),
            );
            final action = find.byKey(
              const ValueKey('profile-compatibility-buy-more'),
            );
            await tester.scrollUntilVisible(row, -180);
            await tester.ensureVisible(action);
            await tester.pumpAndSettle();
            List<String> balanceCopy() => tester
                .widgetList<Text>(
                  find.descendant(of: row, matching: find.byType(Text)),
                )
                .where((text) => text.textSpan != null)
                .map((text) => text.textSpan!.toPlainText())
                .toList();
            final beforeBalance = balanceCopy();
            expect(beforeBalance, isNotEmpty);
            final accessible = tester.getSemantics(action);
            expect(
              accessible.getSemanticsData().label,
              contains('View compatibility unlocks'),
            );
            for (final copy in beforeBalance) {
              expect(accessible.getSemanticsData().label, contains(copy));
            }
            expect(_tapActions(accessible), 1);
            expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
            expect(tester.widget<InkWell>(action).onTap, isNotNull);
            expect(
              find.byTooltip('View compatibility unlocks'),
              findsOneWidget,
            );
            final arrow = find.descendant(
              of: action,
              matching: find.byIcon(Icons.chevron_right_rounded),
            );
            final icon = tester.widget<Icon>(arrow);
            expect(icon.size, 18);
            expect(icon.color, ZyraColors.ink(.28));
            expect(tester.getRect(arrow).right, closeTo(membershipRight, .01));
            expect(find.text('Buy more'), findsNothing);
            for (final target in ['word', 'arrow', 'padding']) {
              await tester.ensureVisible(action);
              await tester.pumpAndSettle();
              if (target == 'word') {
                await tester.tap(find.text('Compatibility unlocks'));
              } else if (target == 'arrow') {
                await tester.tap(arrow);
              } else {
                await tester.tapAt(
                  tester.getRect(action).topLeft + const Offset(2, 2),
                );
              }
              await tester.pumpAndSettle();
              expect(
                find.byType(CompatibilityUnlockStoreScreen),
                findsOneWidget,
              );
              expect(find.text('See your overall match score'), findsNothing);
              expect(find.text('Your match, revealed'), findsOneWidget);
              expect(
                find.byKey(
                  const ValueKey('draft_compatibility_store_use_unlocks'),
                ),
                findsNothing,
              );
              expect(
                tester
                    .widget<FilledButton>(
                      find.byKey(
                        const ValueKey('draft_compatibility_store_continue'),
                      ),
                    )
                    .onPressed,
                isNull,
              );
              await _tapStoreBack(tester, arrow: target == 'arrow');
              expect(find.byType(CompatibilityUnlockStoreScreen), findsNothing);
              expect(find.byType(ProfileScreen), findsOneWidget);
              expect(balanceCopy(), beforeBalance);
              expect(memberState(), beforeMember);
            }
            expect(tester.takeException(), isNull);
          }, network);
          expect(network.attempts, 0);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets('inactive profile offers membership without a One avatar ring', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      AppState.instance.plan = ZyraPlan.basic;
      await pumpProfile(tester, const ProfileScreen());

      expect(find.byKey(const ValueKey('membership-upgrade')), findsOneWidget);
      expect(find.text('View your options'), findsOneWidget);
      expect(find.text('No active membership'), findsOneWidget);
      expect(find.text('Seeker Basic · Preview'), findsNothing);
      expect(
        tester
            .widget<ZyraOneProfileAvatar>(find.byType(ZyraOneProfileAvatar))
            .isOne,
        isFalse,
      );
      expect(
        tester.getSemantics(find.byType(ZyraOneProfileAvatar)),
        matchesSemantics(
          label: 'Profile\nYour Profile\nSwitch Account',
          isButton: true,
          isImage: true,
        ),
      );
    } finally {
      semantics.dispose();
    }
  });

  for (final guardian in [false, true]) {
    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} Profile and Settings keep the canonical paid role label and avatar semantics',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          AppState.instance.plan = guardian ? ZyraPlan.basic : ZyraPlan.one;
          AppState.instance.setWaliOne(guardian);
          final originalPlan = AppState.instance.plan;
          final originalGuardianOne = AppState.instance.waliHasWaliOne;
          final title = guardian ? 'Guardian One' : 'Seeker One';
          final otherTitle = guardian ? 'Seeker One' : 'Guardian One';
          await pumpProfile(
            tester,
            guardian
                ? WaliProfileScreen(
                    loadNotificationPreferences: () async => const {},
                  )
                : const ProfileScreen(),
          );
          expect(find.text(title), findsOneWidget);
          expect(find.text(otherTitle), findsNothing);
          expect(find.textContaining('ZYRA One'), findsNothing);
          final membershipArrow = find.descendant(
            of: find.byKey(const ValueKey('membership-manage')),
            matching: find.byIcon(Icons.chevron_right_rounded),
          );
          expect(tester.widget<Icon>(membershipArrow).size, 18);
          expect(
            tester.widget<Icon>(membershipArrow).color,
            ZyraColors.ink(.28),
          );
          final avatar = find.byType(ZyraOneProfileAvatar);
          expect(avatar, findsOneWidget);
          expect(tester.widget<ZyraOneProfileAvatar>(avatar).isOne, isTrue);
          expect(
            tester.widget<ZyraOneProfileAvatar>(avatar).guardian,
            guardian,
          );
          expect(
            tester.getSemantics(avatar),
            matchesSemantics(
              label: '$title profile\nYour Profile\nSwitch Account',
              isButton: true,
              isImage: true,
            ),
          );
          await tester.scrollUntilVisible(find.text('Settings'), 240);
          await tester.tap(find.text('Settings'));
          await tester.pumpAndSettle();
          expect(find.text(title), findsWidgets);
          expect(find.text(otherTitle), findsNothing);
          expect(find.textContaining('ZYRA One'), findsNothing);
          expect(AppState.instance.plan, originalPlan);
          expect(AppState.instance.waliHasWaliOne, originalGuardianOne);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets('Profile account rows adapt to narrow large-text layouts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    AppState.instance.plan = ZyraPlan.one;

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfileScreen())),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('membership-manage')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profile-compatibility-balances')),
      240,
    );
    expect(
      find.byKey(const ValueKey('profile-compatibility-balances')),
      findsOneWidget,
    );
  });

  testWidgets('Seeker and Guardian details wrap at narrow large-text sizes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    AppState.instance.location = 'West Midlands, United Kingdom';
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfileScreen())),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('West Midlands, United Kingdom'),
      180,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WaliProfileScreen(
            loadNotificationPreferences: () async => const {},
          ),
        ),
      ),
    );
    await tester.pump();
    AppState.instance.setWaliRealLinkedSeekers(const [
      WaliLinkedPerson(id: 'one', firstName: 'A', relationship: 'uncle'),
      WaliLinkedPerson(
        id: 'two',
        firstName: 'B',
        relationship: 'legal_guardian',
      ),
      WaliLinkedPerson(
        id: 'three',
        firstName: 'C',
        relationship: 'family_representative',
      ),
    ]);
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Paternal Uncle, Legal Guardian, Family Representative'),
      180,
    );
    expect(tester.takeException(), isNull);
  });

  group('ordinary Guardian Settings navigation', () {
    final unexpected = <String>[];
    final network = _NoExternalNetwork();
    HttpOverrides? previousNetwork;

    setUpAll(() async {
      previousNetwork = HttpOverrides.current;
      HttpOverrides.global = network;
      SharedPreferences.setMockInitialValues({});
      await ZyraLocalPrefs.init();
      await Supabase.initialize(
        url: 'https://$_ordinaryGuardianHost',
        publishableKey: 'synthetic-test-only',
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: false,
          detectSessionInUri: false,
        ),
        httpClient: MockClient((request) async {
          if (request.url.host == _ordinaryGuardianHost &&
              request.method == 'POST' &&
              request.url.path == '/rest/v1/rpc/wali_has_wali_one') {
            return http.Response(
              'true',
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.host == _ordinaryGuardianHost &&
              request.method == 'GET' &&
              request.url.path == '/rest/v1/wali_links' &&
              request.url.queryParameters['wali_id'] ==
                  'eq.$_ordinaryGuardianId' &&
              request.url.queryParameters['status'] == 'eq.active') {
            return http.Response(
              '[]',
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          unexpected.add('${request.method} ${request.url.path}');
          throw StateError('Unexpected synthetic Guardian hierarchy request.');
        }),
      );
    });

    setUp(() async {
      unexpected.clear();
      network.attempts = 0;
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      ZyraAccountState.resetForTesting();
      ZyraAccountState.clearImagesForTesting = () async {};
      await _ordinaryGuardianSession();
    });

    tearDown(() {
      expect(unexpected, isEmpty);
      expect(network.attempts, 0);
      ZyraAccountState.clearImagesForTesting = null;
      ZyraAccountState.resetForTesting();
    });

    tearDownAll(() async {
      try {
        await Supabase.instance.dispose();
      } finally {
        HttpOverrides.global = previousNetwork;
      }
    });

    void expectOrdinaryBinding() {
      expect(ZyraDeveloperAccess.isAuthorizedOperator, isFalse);
      expect(ZyraDeveloperAccess.isMainAppFounderPreview, isFalse);
      expect(
        Supabase.instance.client.auth.currentUser?.id,
        _ordinaryGuardianId,
      );
      expect(
        ZyraAccountState.isCurrent(
          _ordinaryGuardianId,
          ZyraAccountState.generation,
        ),
        isTrue,
      );
    }

    void disposeFixtureAfter(WidgetTester tester) {
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }

    testWidgets('Guardian follows the Seeker profile section hierarchy', (
      tester,
    ) async {
      expectOrdinaryBinding();
      disposeFixtureAfter(tester);
      AppState.instance.waliName = 'Ibrahim';
      AppState.instance.setWaliOne(true);
      await pumpProfile(
        tester,
        WaliProfileScreen(
          loadNotificationPreferences: () async => {
            for (final category in ZyraNotifyCategory.values)
              category: !category.isConsent,
          },
        ),
      );
      await tester.pumpAndSettle();

      final membership = find.byKey(
        const ValueKey('guardian-profile-membership'),
      );
      expect(membership, findsOneWidget);
      expect(find.text('Manage membership'), findsOneWidget);
      expect(find.text('Guardian One'), findsOneWidget);
      expect(find.text('SAFETY & SHARING'), findsOneWidget);
      expect(find.text('SAFETY & SUPPORT'), findsNothing);
      expect(find.text('Safety & advice'), findsOneWidget);
      expect(find.text('Invite someone to ZYRA'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Notifications'), findsNothing);
      expect(find.text('App lock'), findsNothing);
      expect(find.text('Delete Account'), findsNothing);
      expect(find.text('LEGAL'), findsNothing);
      expect(find.text('ABOUT YOU'), findsNothing);

      final list = tester.widget<ListView>(find.byType(ListView));
      final sectionLabels = (list.childrenDelegate as SliverChildListDelegate)
          .children
          .whereType<Text>()
          .map((text) => text.data)
          .whereType<String>()
          .toList();
      expect(
        sectionLabels.where(
          (label) => const {
            'MEMBERSHIP',
            'ABOUT ME',
            'SAFETY & SHARING',
            'PERSONALISATION',
          }.contains(label),
        ),
        orderedEquals(const [
          'MEMBERSHIP',
          'ABOUT ME',
          'SAFETY & SHARING',
          'PERSONALISATION',
        ]),
      );

      await tester.scrollUntilVisible(find.text('Settings'), 240);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Guardian One'), findsWidgets);
      expect(find.text('Linked Seekers'), findsOneWidget);
      expect(find.text('Guardian privacy'), findsOneWidget);
      expect(find.text('Pause My Profile'), findsOneWidget);
      expect(find.text('Discovery & visibility'), findsNothing);
      expect(find.text('Hidden Profiles'), findsNothing);
      expect(find.text('App lock'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('Delete Account'), findsNothing);

      await tester.scrollUntilVisible(find.text('Notifications & emails'), 240);
      expect(find.text('Notifications & emails'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Privacy & data'), 240);
      expect(find.text('Privacy & data'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Advanced'), -240);
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();
      expect(find.text('Reset profile'), findsOneWidget);
      expect(find.text('Delete account'), findsOneWidget);
      expect(find.textContaining('Ends every Seeker link'), findsNothing);
      expect(
        find.textContaining('not available from this version'),
        findsOneWidget,
      );
      await tester.tap(find.text('Reset profile'));
      await tester.pumpAndSettle();
      expect(find.text('Reset Profile'), findsOneWidget);
      expect(
        find.textContaining('Guardian profile reset is not available'),
        findsOneWidget,
      );
      expect(find.byType(FilledButton), findsNothing);
      await tester.tap(find.byKey(const ValueKey('account-control-info-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Account'), findsOneWidget);
      expect(
        find.textContaining('does not delete your account'),
        findsOneWidget,
      );
      expect(find.byType(FilledButton), findsNothing);
      await tester.tap(find.byKey(const ValueKey('account-control-info-back')));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Privacy & data'), 240);
      await tester.tap(find.text('Privacy & data'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Guardian accounts never appear in Profiles'),
        findsOneWidget,
      );
      expect(find.textContaining('Your profile and photographs'), findsNothing);
      expectOrdinaryBinding();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Guardian opens the shared notification controls through Settings',
      (tester) async {
        expectOrdinaryBinding();
        disposeFixtureAfter(tester);
        final values = {
          for (final category in ZyraNotifyCategory.values)
            category: !category.isConsent,
        };
        final saved = <(ZyraNotifyCategory, bool)>[];

        await pumpProfile(
          tester,
          WaliProfileScreen(
            loadNotificationPreferences: () async => Map.of(values),
            saveNotificationPreference: (category, enabled) async {
              saved.add((category, enabled));
              values[category] = enabled;
              return true;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.text('Settings'), 240);
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Notifications & emails'),
          240,
        );
        await tester.tap(find.text('Notifications & emails'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Seeker links'), findsOneWidget);
        final toggle = find.byType(Switch).first;
        expect(tester.widget<Switch>(toggle).value, isTrue);
        await tester.tap(toggle);
        await tester.pump();

        expect(saved, [(ZyraNotifyCategory.matchesJourneys, false)]);
        expect(tester.widget<Switch>(toggle).value, isFalse);
        expectOrdinaryBinding();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
