// Protected local presentation only: no real signup, role or membership write.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_switch_signup_preview.dart';
import 'package:zyra/dev/zyra_subscription_wallet_draft.dart';
import 'package:zyra/dev/zyra_subscription_wallet_preview.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'package:zyra/widgets/zyra_membership_choices.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _font = 'PoppinsSwitchSignupPreview';
const _captures = String.fromEnvironment('ZYRA_SWITCH_SIGNUP_CAPTURE_DIR');
const _captureKey = ValueKey('switch-signup-capture');

Finder _key(String value) => find.byKey(ValueKey(value));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Switch setup examples must remain offline.');
  }
}

Widget _app(Widget child, {bool compact = false}) => MaterialApp(
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
      textScaler: TextScaler.linear(compact ? 2 : 1),
      disableAnimations: true,
    ),
    child: RepaintBoundary(key: _captureKey, child: child!),
  ),
  home: Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
      child: child,
    ),
  ),
);

void _size(WidgetTester tester, {bool compact = false}) {
  tester.view.physicalSize = compact
      ? const Size(320, 568)
      : const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = _key(key);
  if (target.evaluate().isEmpty) {
    final owner = _key('dev_controls_scroll');
    expect(owner, findsOneWidget);
    await tester.scrollUntilVisible(
      target,
      150,
      scrollable: find.descendant(of: owner, matching: find.byType(Scrollable)),
      maxScrolls: 30,
    );
  }
  expect(target, findsOneWidget);
  final scroller = find.ancestor(of: target, matching: find.byType(Scrollable));
  if (scroller.evaluate().isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, String label) async {
  final navigation = find.byType(ZyraShellNavigation);
  final bar = tester.widget<ZyraShellNavigation>(navigation);
  final item = bar.items.singleWhere((item) => item.label == label);
  final icon = find.descendant(
    of: navigation,
    matching: find.byIcon(item.icon),
  );
  expect(icon, findsOneWidget);
  // Floating navigation deliberately ignores pointer events on glyphs. The
  // owning gesture target receives a real tap at the selected icon's centre.
  final barTarget = find
      .ancestor(
        of: icon,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTapDown != null,
        ),
      )
      .first;
  expect(barTarget.hitTestable(), findsOneWidget);
  await tester.tapAt(tester.getCenter(icon));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

class _Owner {
  bool allowed = true;
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];
  final roleChanges = <bool>[];

  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;

  Future<void> mount(WidgetTester tester, {bool guardian = false}) async {
    _size(tester);
    final ready = Completer<void>();
    await tester.pumpWidget(
      _app(
        ZyraOneJourneyConceptShell(
          key: UniqueKey(),
          canAct: () => allowed,
          onExit: () => fail('Switch setup must stay inside its app owner.'),
          initialGuardianRole: guardian,
          initialCheckpoint: ZyraPreviewNavigationCheckpoint(
            guardian: guardian,
            model: ViewRequestDraftModel(capacity: 3).snapshot(),
            tab: guardian ? 3 : 4,
            pages: const [],
          ),
          onRoleChanged: roleChanges.add,
          onCheckpoint: checkpoints.add,
          onPresentationReady: () {
            if (!ready.isCompleted) ready.complete();
          },
        ),
      ),
    );
    for (var frame = 0; frame < 100 && !ready.isCompleted; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(ready.isCompleted, isTrue, reason: 'Actual local assets prepare');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(checkpoints, isNotEmpty);
  }
}

Object _modelFacts(ZyraPreviewNavigationCheckpoint value) => [
  value.model.capacity,
  value.model.states,
  value.model.busyPeers,
  value.model.hiddenPeers,
  value.model.blockedPeers,
  value.model.acknowledgedReceivedRequestIds,
  value.model.progress,
  value.model.peerMainGuardianOverrides,
  value.model.guardianMemberships,
  value.model.guardianAccess,
  value.model.ownMainGuardianPresent,
  value.model.peerMainGuardianPresent,
  value.seekerMembership,
  value.guardianMembership,
];

Future<void> _missing(WidgetTester tester) async {
  await openZyraDevControls(tester);
  expect(find.text('Switch account'), findsOneWidget);
  await _tap(tester, 'concept_switch_needs_signup');
  await closeZyraDevControls(tester);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captures.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captures/$name.png');
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  late Map<String, Object?> beforePreferences;
  late List<Object?> beforeMember;
  late _NoNetwork network;
  final oldHttp = HttpOverrides.current;
  final oldStubs = ZyraText.useTestFontStubs;
  final oldFamily = ZyraText.testReadingFontFamily;

  Map<String, Object?> preferenceState() => {
    for (final key in preferences.getKeys()) key: preferences.get(key),
  };
  List<Object?> memberState() => [
    AppState.instance.name,
    AppState.instance.gender,
    AppState.instance.dob,
    AppState.instance.location,
    List.of(AppState.instance.saved),
    List.of(AppState.instance.activeJourneys),
    List.of(AppState.instance.potentialJourneys),
    List.of(AppState.instance.photos),
    AppState.instance.plan,
  ];

  setUpAll(() async {
    if (_captures.isNotEmpty) {
      if (!_captures.startsWith('/')) {
        throw StateError('Capture output must be an absolute directory.');
      }
      var path = '';
      for (final component
          in _captures.split('/').where((part) => part.isNotEmpty)) {
        if (component == '.' || component == '..') {
          throw StateError('Capture aliases are not accepted.');
        }
        path += '/$component';
        if (FileSystemEntity.typeSync(path, followLinks: false) !=
            FileSystemEntityType.directory) {
          throw StateError('Captures require existing nonlinked directories.');
        }
      }
    }
    final reading = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'switch-signup-sentinel': 'keep'});
    preferences = await SharedPreferences.getInstance();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    beforePreferences = preferenceState();
    beforeMember = memberState();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    final fatal = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = fatal);
  });

  tearDown(() {
    expect(network.attempts, 0);
    expect(preferenceState(), beforePreferences);
    expect(memberState(), beforeMember);
    HttpOverrides.global = oldHttp;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = oldStubs;
    ZyraText.testReadingFontFamily = oldFamily;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final guardian in [false, true]) {
    for (final overview in [false, true]) {
      for (final compact in [false, true]) {
        testWidgets(
          '${guardian ? 'Seeker' : 'Guardian'} ${overview ? 'setup' : 'signup'} example fits ${compact ? '320px200%' : '393px'}',
          (tester) async {
            _size(tester, compact: compact);
            var starts = 0;
            var returns = 0;
            await tester.pumpWidget(
              _app(
                ZyraSwitchSignupPreview(
                  guardian: guardian,
                  setupOverview: overview,
                  currentMembership: guardian ? 'Guardian One' : 'Seeker One',
                  onStartSetup: () => starts++,
                  onReturnToProfile: () => returns++,
                ),
                compact: compact,
              ),
            );
            await tester.pumpAndSettle();
            final root = _key(
              overview ? 'concept_switch_setup' : 'concept_switch_signup',
            );
            expect(root, findsOneWidget);
            final role = guardian ? 'Seeker' : 'Guardian';
            expect(
              find.text(
                overview ? 'Set up your $role profile' : 'Switch Account',
              ),
              findsOneWidget,
            );
            if (overview) {
              expect(_key('concept_switch_setup_steps'), findsOneWidget);
              if (!guardian) expect(find.text('Add one photo'), findsOneWidget);
            } else {
              expect(_key('concept_switch_current'), findsOneWidget);
              expect(_key('concept_switch_missing'), findsOneWidget);
              expect(
                find.descendant(
                  of: _key('concept_switch_current'),
                  matching: find.byType(InkWell),
                ),
                findsNothing,
                reason:
                    'The current profile is informational, not another action',
              );
              expect(find.text('Set up $role profile'), findsOneWidget);
            }
            expect(
              find.text('Setup preview · no profile is created.'),
              findsOneWidget,
            );
            expect(find.byType(TextField), findsNothing);
            expect(tester.takeException(), isNull);
            if (!compact) {
              await _capture(
                tester,
                guardian
                    ? overview
                          ? '04-seeker-setup'
                          : '03-seeker-signup'
                    : overview
                    ? '02-guardian-setup'
                    : '01-guardian-signup',
              );
            }
            for (final key in [
              if (!overview) 'concept_switch_start_setup',
              'concept_switch_return_profile',
            ]) {
              final target = _key(key);
              expect(target, findsOneWidget);
              await Scrollable.ensureVisible(
                tester.element(target),
                alignment: .5,
              );
              await tester.pumpAndSettle();
              expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
              await _tap(tester, key);
            }
            expect(starts, overview ? 0 : 1);
            expect(returns, 1);
          },
        );
      }
    }

    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} covered missing profile finishes setup without repurchase',
      (tester) async {
        final owner = _Owner();
        await owner.mount(tester, guardian: guardian);
        final before = _modelFacts(owner.latest);
        final target = guardian
            ? ZyraWalletRole.seeker
            : ZyraWalletRole.guardian;
        await _missing(tester);
        await _tap(tester, 'switch-account-button');
        expect(_key('wallet_switch_scroll'), findsOneWidget);
        expect(find.textContaining('without buying it again'), findsOneWidget);
        expect(owner.latest.pages, ['switch_account_signup']);
        await _tap(tester, 'wallet_primary_${target.name}');
        expect(_key('concept_switch_setup'), findsOneWidget);
        expect(owner.latest.pages, [
          'switch_account_signup',
          'switch_account_setup',
        ]);
        await returnZyraPreviewPage(tester);
        expect(_key('wallet_switch_scroll'), findsOneWidget);
        await _tap(tester, 'wallet_primary_${target.name}');
        await _tap(tester, 'concept_switch_return_profile');
        expect(find.byType(ZyraConceptProfilePresentation), findsOneWidget);
        expect(owner.latest.pages, isEmpty);
        expect(owner.latest.guardian, guardian);
        expect(owner.roleChanges, isEmpty);
        expect(_modelFacts(owner.latest), before);
      },
    );
  }

  testWidgets(
    'ready covered Switch previews coverage then switches once, without buying',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester);
      await _tap(tester, 'switch-account-button');
      expect(owner.roleChanges, isEmpty);
      expect(_key('wallet_switch_scroll'), findsOneWidget);
      await _tap(tester, 'wallet_primary_guardian');
      expect(owner.roleChanges, [true]);
      expect(owner.latest.guardian, isTrue);
      expect(owner.latest.pages, isEmpty);
      await openZyraDevControls(tester);
      expect(_key('concept_switch_ready'), findsNothing);
      await closeZyraDevControls(tester);
      await _nav(tester, 'Profile');
      await _missing(tester);
      await openZyraDevControls(tester);
      await _tap(tester, 'draft_reset');
      await _nav(tester, 'Profile');
      await _tap(tester, 'switch-account-button');
      await _tap(tester, 'wallet_primary_guardian');
      expect(owner.roleChanges, [true, false, true]);
    },
  );

  testWidgets(
    'saved Switch, wallet and setup callbacks fail under controls, route changes and revocation',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester);
      await _missing(tester);
      final switchAction = tester
          .widget<ZyraConceptProfilePresentation>(
            find.byType(ZyraConceptProfilePresentation),
          )
          .onSwitchRole;
      await openZyraDevControls(tester);
      switchAction();
      await tester.pumpAndSettle();
      expect(owner.latest.pages, isEmpty);
      await closeZyraDevControls(tester);
      await _tap(tester, 'switch-account-button');
      final first = tester.widget<ZyraSubscriptionSwitchPreview>(
        find.byType(ZyraSubscriptionSwitchPreview),
      );
      await openZyraDevControls(tester);
      first.onSetup(ZyraWalletRole.guardian);
      first.onSwitch(ZyraWalletRole.guardian);
      first.onBack?.call();
      await tester.pumpAndSettle();
      expect(owner.latest.pages, ['switch_account_signup']);
      await closeZyraDevControls(tester);
      await _tap(tester, 'wallet_primary_guardian');
      final overview = tester.widget<ZyraSwitchSignupPreview>(
        find.byType(ZyraSwitchSignupPreview),
      );
      first.onSetup(ZyraWalletRole.guardian);
      first.onBack?.call();
      switchAction();
      await tester.pumpAndSettle();
      expect(owner.latest.pages, [
        'switch_account_signup',
        'switch_account_setup',
      ]);
      await _tap(tester, 'concept_switch_return_profile');
      overview.onReturnToProfile();
      first.onSwitch(ZyraWalletRole.guardian);
      await tester.pumpAndSettle();
      expect(owner.latest.pages, isEmpty);
      expect(owner.roleChanges, isEmpty);
      await _tap(tester, 'switch-account-button');
      final denied = tester.widget<ZyraSubscriptionSwitchPreview>(
        find.byType(ZyraSubscriptionSwitchPreview),
      );
      final checkpointCount = owner.checkpoints.length;
      owner.allowed = false;
      denied.onSetup(ZyraWalletRole.guardian);
      denied.onMembership(ZyraWalletRole.guardian);
      denied.onSwitch(ZyraWalletRole.guardian);
      denied.onBack?.call();
      await tester.pump();
      expect(owner.checkpoints.length, checkpointCount);
      expect(owner.roleChanges, isEmpty);
    },
  );

  testWidgets(
    'Profile subscriptions stay local and old callbacks cannot revive after controls close',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester);
      final modelBefore = _modelFacts(owner.latest);
      await _tap(tester, 'concept_subscriptions');
      final wallet = tester.widget<ZyraSubscriptionWalletPreview>(
        find.byType(ZyraSubscriptionWalletPreview),
      );
      final draft = wallet.draft;
      await openZyraDevControls(tester);
      await closeZyraDevControls(tester);
      wallet.onChanged(
        draft.withRole(
          ZyraWalletRole.guardian,
          coverage: ZyraWalletCoverage.none,
        ),
      );
      wallet.onSwitch(ZyraWalletRole.guardian);
      wallet.onBack?.call();
      await tester.pumpAndSettle();
      expect(owner.latest.pages, ['subscriptions']);
      expect(owner.roleChanges, isEmpty);
      expect(
        tester
            .widget<ZyraSubscriptionWalletPreview>(
              find.byType(ZyraSubscriptionWalletPreview),
            )
            .draft,
        same(draft),
      );
      expect(_modelFacts(owner.latest), modelBefore);
      await returnZyraPreviewPage(tester);
      expect(find.byType(ZyraConceptProfilePresentation), findsOneWidget);
    },
  );

  testWidgets(
    'switching a confirmed Basic Guardian keeps the Profile and capability sample coherent',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester);
      await openZyraDevControls(tester);
      await _tap(tester, 'concept_wallet_coverage_basic');
      await closeZyraDevControls(tester);
      await _tap(tester, 'switch-account-button');
      expect(find.text('Guardian Basic'), findsOneWidget);
      await _tap(tester, 'wallet_primary_guardian');
      await _nav(tester, 'Profile');
      expect(
        tester
            .widget<ZyraConceptProfilePresentation>(
              find.byType(ZyraConceptProfilePresentation),
            )
            .data
            .membership,
        'Guardian Basic',
      );
      expect(owner.latest.guardianMembership, 'Guardian Basic');
      expect(owner.roleChanges, [true]);
    },
  );

  testWidgets(
    'uncovered role without a spare opens only that role membership section',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester);
      await openZyraDevControls(tester);
      await _tap(tester, 'concept_wallet_coverage_none');
      await closeZyraDevControls(tester);
      await _tap(tester, 'switch-account-button');
      await _tap(tester, 'wallet_primary_guardian');
      expect(owner.latest.pages, ['switch_account_signup', 'membership']);
      expect(
        tester
            .widget<ZyraMembershipChoices>(find.byType(ZyraMembershipChoices))
            .initialDraft!
            .section,
        ZyraMembershipSection.guardian,
      );
      expect(owner.roleChanges, isEmpty);
    },
  );

  testWidgets(
    'a spare place is confirmed before covered Switch and never starts a purchase',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester);
      await openZyraDevControls(tester);
      await _tap(tester, 'concept_wallet_spare_place');
      await closeZyraDevControls(tester);
      await _tap(tester, 'switch-account-button');
      await _tap(tester, 'wallet_primary_guardian');
      expect(owner.roleChanges, isEmpty);
      await _tap(tester, 'wallet_confirm');
      expect(owner.latest.pages, ['switch_account_signup']);
      expect(find.text('Guardian One · ZYRA Family'), findsOneWidget);
      await _tap(tester, 'wallet_primary_guardian');
      expect(owner.roleChanges, [true]);
      expect(owner.latest.guardianMembership, 'Guardian One');
    },
  );

  testWidgets(
    'current setup views remain readable with compact enlarged text',
    (tester) async {
      _size(tester, compact: true);
      for (final overview in [false, true]) {
        await tester.pumpWidget(
          _app(
            ZyraSwitchSignupPreview(
              guardian: false,
              setupOverview: overview,
              currentMembership: 'Seeker One',
              onStartSetup: () {},
              onReturnToProfile: () {},
            ),
            compact: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _tap(tester, 'concept_switch_return_profile');
      }
    },
  );
}
