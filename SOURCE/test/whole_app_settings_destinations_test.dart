import 'package:zyra/dev/dev_discovery_directions.dart';
// OA304: Settings must lead to subject-specific, truthful local destinations.
// No member setting, device security, legal acceptance or submission is faked.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_settings_details.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/settings/account_advanced_screen.dart';
import 'package:zyra/screens/settings/app_lock_screen.dart';
import 'package:zyra/screens/settings/feedback_screen.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/screens/settings/hidden_profiles_screen.dart';
import 'package:zyra/screens/settings/notification_settings_screen.dart';
import 'package:zyra/screens/settings/privacy_and_data_screen.dart';
import 'package:zyra/screens/settings/privacy_settings_screen.dart';
import 'package:zyra/screens/settings/sign_in_security_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _reading = 'PoppinsWholeAppDestinations';
const _wordmark = 'SyneWholeAppDestinations';
const _captures = String.fromEnvironment('ZYRA_DESTINATIONS_CAPTURE_DIR');
const _captureKey = ValueKey('whole-app-settings-capture');

const _overviews = [
  ZyraConceptAccountAction.signInSecurity,
  ZyraConceptAccountAction.appLock,
  ZyraConceptAccountAction.advanced,
  ZyraConceptAccountAction.visibility,
  ZyraConceptAccountAction.hiddenProfiles,
  ZyraConceptAccountAction.guardianPrivacy,
  ZyraConceptAccountAction.notificationSettings,
  ZyraConceptAccountAction.feedback,
  ZyraConceptAccountAction.privacyData,
];

const _nativeBoundaryChannels = [
  'plugins.flutter.io/local_auth',
  'dev.flutter.pigeon.local_auth_darwin.LocalAuthApi.authenticate',
  'dev.flutter.pigeon.local_auth_android.LocalAuthApi.authenticate',
  'plugins.it_nomads.com/flutter_secure_storage',
  'plugins.flutter.io/google_sign_in',
  'dev.flutter.pigeon.google_sign_in_ios.GoogleSignInApi.signIn',
  'plugins.flutter.io/url_launcher',
];

Finder _key(String value) => find.byKey(ValueKey(value));
Finder _overview(ZyraConceptAccountAction action) =>
    _key('concept_settings_overview_${action.name}');
Finder _detail(ZyraConceptSettingsDetail detail) =>
    _key('concept_settings_detail_${detail.name}');
Finder _detailRow(
  ZyraConceptAccountAction action,
  ZyraConceptSettingsDetail detail,
) => _key('concept_settings_open_${action.name}_${detail.name}');

List<ZyraConceptAccountAction> _roleOverviews(bool guardian) => [
  for (final action in _overviews)
    if (guardian
        ? action != ZyraConceptAccountAction.hiddenProfiles
        : action != ZyraConceptAccountAction.guardianPrivacy)
      action,
];

List<ZyraConceptSettingsDetail> _children(
  ZyraConceptAccountAction action,
  bool guardian,
) => switch (action) {
  ZyraConceptAccountAction.signInSecurity => [
    ZyraConceptSettingsDetail.recovery,
  ],
  ZyraConceptAccountAction.appLock => [ZyraConceptSettingsDetail.appLock],
  ZyraConceptAccountAction.advanced => [
    ZyraConceptSettingsDetail.resetProfile,
    ZyraConceptSettingsDetail.deleteAccount,
  ],
  ZyraConceptAccountAction.visibility ||
  ZyraConceptAccountAction.guardianPrivacy => [
    ZyraConceptSettingsDetail.discovery,
  ],
  ZyraConceptAccountAction.hiddenProfiles => const [],
  ZyraConceptAccountAction.notificationSettings => [
    ZyraConceptSettingsDetail.notifications,
  ],
  ZyraConceptAccountAction.feedback => [ZyraConceptSettingsDetail.feedback],
  ZyraConceptAccountAction.privacyData => [
    ZyraConceptSettingsDetail.privacyPolicy,
    ZyraConceptSettingsDetail.terms,
  ],
  _ => const [],
};

ZyraConceptAccountData _data(bool guardian) => ZyraConceptAccountData(
  guardian: guardian,
  name: guardian ? 'Hassan Rahman' : 'Adam Khan',
  age: guardian ? '54' : '30',
  gender: 'Male',
  location: 'London',
  membership: guardian ? 'Guardian One' : 'Seeker One',
  isOne: true,
  relationship: 'Father',
  linkedSeekers: '1',
  guardianCount: '2',
  signedInWith: 'Apple',
  backgroundLabel: 'Midnight Plum',
  hapticLabel: 'Subtle',
  gold: false,
);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Settings destination evidence must remain offline.');
  }
}

Widget _app(Widget child, {bool compact = false}) => MaterialApp(
  navigatorObservers: [ZyraPreviewRouteObserver()],
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

Future<void> _reveal(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    final scrollables = find.byType(Scrollable);
    expect(scrollables, findsWidgets);
    tester.state<ScrollableState>(scrollables.last).position.jumpTo(0);
    await tester.pumpAndSettle();
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        150,
        scrollable: scrollables.last,
        maxScrolls: 40,
      );
    }
  }
  expect(target, findsOneWidget);
  final ancestors = find.ancestor(
    of: target,
    matching: find.byType(Scrollable),
  );
  if (ancestors.evaluate().isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await _reveal(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<Set<String>> _actualSettingsRows(WidgetTester tester) async {
  final scroll = find.descendant(
    of: _key('concept-current-settings-scroll'),
    matching: find.byType(Scrollable),
  );
  expect(scroll, findsOneWidget);
  final position = tester.state<ScrollableState>(scroll).position;
  final rows = <String>{};
  for (var step = 0; step < 40; step++) {
    for (final element
        in find
            .byWidgetPredicate(
              (widget) => widget.runtimeType.toString() == '_SettingsRow',
            )
            .evaluate()) {
      final key = element.widget.key! as ValueKey<String>;
      rows.add(key.value);
    }
    if (position.pixels >= position.maxScrollExtent) break;
    position.jumpTo((position.pixels + 240).clamp(0, position.maxScrollExtent));
    await tester.pumpAndSettle();
  }
  position.jumpTo(0);
  await tester.pumpAndSettle();
  return rows;
}

Future<void> _back(WidgetTester tester) async {
  final scope = _key('concept_pull_down_back_scope');
  expect(scope, findsOneWidget);
  tester.widget<ZyraPullDownBackScope>(scope).onBack();
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, String label) async {
  await expandZyraPreviewTabBarIfIdle(tester);
  final navigation = find.byType(ZyraShellNavigation);
  expect(navigation, findsOneWidget);
  final item = tester
      .widget<ZyraShellNavigation>(navigation)
      .items
      .singleWhere((item) => item.label == label);
  final icon = find.descendant(
    of: navigation,
    matching: find.byIcon(item.icon),
  );
  expect(icon, findsOneWidget);
  final action = find
      .ancestor(
        of: icon,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTapDown != null,
        ),
      )
      .first;
  expect(action.hitTestable(), findsOneWidget);
  await tester.tapAt(tester.getCenter(icon));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _noLiveActionWidgets({bool helpSearchAllowed = false}) {
  expect(find.byType(SignInSecurityScreen), findsNothing);
  expect(find.byType(RecoveryEmailSetupScreen), findsNothing);
  expect(find.byType(AppLockScreen), findsNothing);
  expect(find.byType(AccountAdvancedScreen), findsNothing);
  expect(find.byType(PrivacySettingsScreen), findsNothing);
  expect(find.byType(HiddenProfilesScreen), findsNothing);
  expect(find.byType(NotificationSettingsScreen), findsNothing);
  expect(find.byType(FeedbackScreen), findsNothing);
  expect(find.byType(PrivacyAndDataScreen), findsNothing);
  expect(find.byType(Switch), findsNothing);
  expect(find.byType(Form), findsNothing);
  if (!helpSearchAllowed) {
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(EditableText), findsNothing);
  }
}

void _visibleTextFits(WidgetTester tester) {
  for (final element in find.byType(Text).evaluate()) {
    final text = element.widget as Text;
    expect(text.maxLines, isNull);
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    final object = element.findRenderObject();
    if (object is RenderParagraph && object.hasSize) {
      expect(object.didExceedMaxLines, isFalse);
      expect(
        object.size.width,
        lessThanOrEqualTo(tester.view.physicalSize.width),
      );
    }
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captures.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final output = File('$_captures/$name.png');
    await output.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      await output.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

class _ShellOwner {
  bool allowed = true;
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];

  bool canAct() => allowed;

  Future<void> mount(
    WidgetTester tester, {
    bool guardian = false,
    bool guardedRouteOwner = false,
  }) async {
    _size(tester);
    final ready = Completer<void>();
    await tester.pumpWidget(
      _app(
        guardedRouteOwner
            ? ViewRequestDraftScreen(
                fixture: ZyraShellTestFixture().fixture,
                key: UniqueKey(),
                ownerGeneration: ZyraAccountState.generation,
                ownerId: ZyraAccountState.userId,
                onExit: () =>
                    fail('A Settings child must return within its owner.'),
                initialGuardianRole: guardian,
                initialCheckpoint: ZyraPreviewNavigationCheckpoint(
                  guardian: guardian,
                  model: ViewRequestDraftModel(capacity: 3).snapshot(),
                  tab: guardian ? 3 : 4,
                  pages: const [],
                ),
                onCheckpoint: checkpoints.add,
                onPresentationReady: () {
                  if (!ready.isCompleted) ready.complete();
                },
              )
            : ZyraOneJourneyConceptShell(
                fixture: ZyraShellTestFixture().fixture,
                key: UniqueKey(),
                canAct: canAct,
                onExit: () =>
                    fail('A Settings child must return within its owner.'),
                initialGuardianRole: guardian,
                initialCheckpoint: ZyraPreviewNavigationCheckpoint(
                  guardian: guardian,
                  model: ViewRequestDraftModel(capacity: 3).snapshot(),
                  tab: guardian ? 3 : 4,
                  pages: const [],
                ),
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
    expect(ready.isCompleted, isTrue);
    await tester.pumpAndSettle();
    expect(checkpoints, isNotEmpty);
    expect(tester.takeException(), isNull);
  }

  Future<void> settings(WidgetTester tester) async {
    await _tap(tester, _key('concept_settings'));
    expect(find.byType(ZyraConceptSettingsPresentation), findsOneWidget);
  }

  Future<void> overview(
    WidgetTester tester,
    ZyraConceptAccountAction action,
  ) async {
    await _tap(tester, _key('concept_settings_${action.name}'));
    expect(_overview(action), findsOneWidget);
    expect(
      tester
          .widget<ZyraConceptSettingsOverview>(
            find.byType(ZyraConceptSettingsOverview),
          )
          .action,
      action,
    );
    expect(find.text('PREVIEW ONLY'), findsNothing);
    _noLiveActionWidgets();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final oldHttp = HttpOverrides.current;
  final oldStubs = ZyraText.useTestFontStubs;
  final oldReading = ZyraText.testReadingFontFamily;
  final oldWordmark = ZyraText.testWordmarkFontFamily;
  late _NoNetwork network;
  late SharedPreferences preferences;
  late Map<String, Object?> beforePreferences;
  late List<Object?> beforeMember;
  late List<Object?> beforeGlobal;
  final nativeCalls = <String>[];

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
    ZyraAccountState.userId,
    ZyraAccountState.generation,
    ZyraLocalPrefs.accountOwner,
    ZyraLocalPrefs.bindingGeneration,
    ZyraLocalPrefs.cachedAppPaletteName,
    ZyraLocalPrefs.cachedHapticLevelName,
    ZyraLocalPrefs.cachedAppGoldEnabled,
  ];
  List<Object?> globalState() => [
    ZyraColors.devPalette,
    ZyraInteractionStyle.hapticLevel,
    ZyraText.appFont,
    ZyraAppGoldStyle.instance.enabled,
    ZyraAppGoldRenderer.instance.renderingEnabled,
  ];

  setUpAll(() async {
    if (_captures.isNotEmpty) {
      if (!_captures.startsWith('/')) {
        throw StateError('Capture output must be absolute.');
      }
      var current = '';
      for (final part
          in _captures.split('/').where((part) => part.isNotEmpty)) {
        if (part == '.' || part == '..') {
          throw StateError('Capture aliases are not accepted.');
        }
        current += '/$part';
        if (FileSystemEntity.typeSync(current, followLinks: false) !=
            FileSystemEntityType.directory) {
          throw StateError(
            'Capture output requires existing nonlinked directories.',
          );
        }
      }
    }
    final reading = FontLoader(_reading);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final wordmark = FontLoader(_wordmark)
      ..addFont(rootBundle.load('assets/fonts/Syne-SemiBold.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'destinations-sentinel': 'keep'});
    await ZyraLocalPrefs.init();
    preferences = await SharedPreferences.getInstance();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await ZyraAccountState.synchronize('destinations-member');
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraAppGoldStyle.instance.restore(false);
    ZyraAppGoldRenderer.instance.resetForTesting();
    ZyraColors.restoreAppPalette(null);
    ZyraInteractionStyle.restoreHapticLevel(null);
    ZyraText.restoreAppFont(null);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _reading;
    ZyraText.testWordmarkFontFamily = _wordmark;
    beforePreferences = preferenceState();
    beforeMember = memberState();
    beforeGlobal = globalState();
    network = _NoNetwork();
    HttpOverrides.global = network;
    nativeCalls.clear();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in _nativeBoundaryChannels) {
      messenger.setMockMessageHandler(channel, (message) async {
        nativeCalls.add(channel);
        return null;
      });
    }
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    final fatal = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = fatal);
  });

  tearDown(() {
    try {
      expect(network.attempts, 0);
      expect(nativeCalls, isEmpty);
      expect(preferenceState(), beforePreferences);
      expect(memberState(), beforeMember);
      expect(globalState(), beforeGlobal);
    } finally {
      HttpOverrides.global = oldHttp;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      ZyraDeveloperAccess.resetAuthorizationForTesting();
      ZyraAccountState.clearImagesForTesting = null;
      ZyraText.useTestFontStubs = oldStubs;
      ZyraText.testReadingFontFamily = oldReading;
      ZyraText.testWordmarkFontFamily = oldWordmark;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      for (final channel in _nativeBoundaryChannels) {
        messenger.setMockMessageHandler(channel, null);
      }
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    }
  });

  for (final compact in [false, true]) {
    final layout = compact ? '320px200%' : '393pxnormal';
    for (final action in _overviews) {
      testWidgets('$layout ${action.name} overview is specific and passive', (
        tester,
      ) async {
        _size(tester, compact: compact);
        final guardian = action == ZyraConceptAccountAction.guardianPrivacy;
        final opened = <ZyraConceptSettingsDetail>[];
        var help = 0;
        await tester.pumpWidget(
          _app(
            ZyraConceptSettingsOverview(
              action: action,
              data: _data(guardian),
              onOpenDetail: opened.add,
              onHelp: () => help++,
            ),
            compact: compact,
          ),
        );
        await tester.pumpAndSettle();
        expect(_overview(action), findsOneWidget);
        final title = tester.widget<Text>(
          _key('concept_settings_title_overview_${action.name}'),
        );
        expect(title.style!.fontFamily, _reading);
        expect(title.style!.fontSize, ZyraText.pageTitleSize);
        final scope = _key(
          'concept_settings_preview_scope_overview_${action.name}',
        );
        if (action == ZyraConceptAccountAction.hiddenProfiles) {
          expect(title.data, 'Hidden profiles');
          expect(scope, findsNothing);
          expect(find.text('A private list, controlled by you.'), findsNothing);
          expect(find.text('Managing hidden profiles'), findsNothing);
          expect(find.text('No hidden profiles'), findsNothing);
          expect(
            _detailRow(action, ZyraConceptSettingsDetail.hiddenProfiles),
            findsNothing,
          );
        } else {
          await _reveal(tester, scope);
          expect(scope, findsOneWidget);
        }
        _noLiveActionWidgets();
        _visibleTextFits(tester);
        if (compact && action == ZyraConceptAccountAction.privacyData) {
          await _capture(tester, '05-compact');
        }
        final expected = _children(action, guardian);
        for (final detail in expected) {
          final target = _detailRow(action, detail);
          await _reveal(tester, target);
          expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
          await _tap(tester, target);
          _visibleTextFits(tester);
        }
        expect(opened, expected);
        final helpAction = _key(
          'concept_settings_help_overview_${action.name}',
        );
        await _reveal(tester, helpAction);
        expect(tester.getSize(helpAction).height, greaterThanOrEqualTo(44));
        await _tap(tester, helpAction);
        expect(help, 1);
        _noLiveActionWidgets();
        expect(tester.takeException(), isNull);
      });
    }

    for (final detail in ZyraConceptSettingsDetail.values) {
      testWidgets('$layout ${detail.name} detail is truthful for both roles', (
        tester,
      ) async {
        _size(tester, compact: compact);
        for (final guardian in [false, true]) {
          var help = 0;
          await tester.pumpWidget(
            _app(
              ZyraConceptSettingsDetailPresentation(
                key: ValueKey((detail, guardian)),
                detail: detail,
                guardian: guardian,
                onHelp: () => help++,
              ),
              compact: compact,
            ),
          );
          await tester.pumpAndSettle();
          expect(_detail(detail), findsOneWidget);
          final scope = _key(
            'concept_settings_preview_scope_detail_${detail.name}',
          );
          if (detail == ZyraConceptSettingsDetail.hiddenProfiles) {
            expect(scope, findsNothing);
            expect(find.text('Hidden profiles'), findsOneWidget);
            expect(find.text('Managing hidden profiles'), findsNothing);
            expect(find.text('A choice for your view only'), findsNothing);
          } else {
            await _reveal(tester, scope);
            expect(scope, findsOneWidget);
          }
          final title = tester.widget<Text>(
            _key('concept_settings_title_detail_${detail.name}'),
          );
          expect(title.style!.fontFamily, _reading);
          if (detail == ZyraConceptSettingsDetail.privacyPolicy ||
              detail == ZyraConceptSettingsDetail.terms) {
            await _reveal(
              tester,
              find.textContaining('not available here yet'),
            );
            expect(
              find.textContaining('not available here yet'),
              findsOneWidget,
            );
            await _reveal(tester, find.text('A separate formal document'));
          }
          _noLiveActionWidgets();
          _visibleTextFits(tester);
          final helpAction = _key(
            'concept_settings_help_detail_${detail.name}',
          );
          await _reveal(tester, helpAction);
          expect(tester.getSize(helpAction).height, greaterThanOrEqualTo(44));
          await _tap(tester, helpAction);
          expect(help, 1);
          _visibleTextFits(tester);
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  for (final guardian in [false, true]) {
    testWidgets('${guardian ? 'Guardian' : 'Seeker'} actual Settings rows and '
        'every subpage keep their own return destination', (tester) async {
      final owner = _ShellOwner();
      await owner.mount(tester, guardian: guardian);
      await owner.settings(tester);
      final actions = _roleOverviews(guardian);
      final expectedRows = {
        for (final action in [
          ...actions,
          ZyraConceptAccountAction.phoneAccess,
          ZyraConceptAccountAction.helpSupport,
        ])
          'concept_settings_${action.name}',
      };
      final actualRows = await _actualSettingsRows(tester);
      expect(actualRows, expectedRows);
      expect(actualRows.length, 10);
      if (!guardian) await _capture(tester, '01-settings');
      for (final action in actions) {
        await owner.overview(tester, action);
        if (!guardian && action == ZyraConceptAccountAction.signInSecurity) {
          await _capture(tester, '02-security');
        }
        if (!guardian && action == ZyraConceptAccountAction.privacyData) {
          await _capture(tester, '03-privacy');
        }
        for (final detail in _children(action, guardian)) {
          await _tap(tester, _detailRow(action, detail));
          expect(_detail(detail), findsOneWidget);
          expect(
            tester
                .widget<ZyraConceptSettingsDetailPresentation>(
                  find.byType(ZyraConceptSettingsDetailPresentation),
                )
                .guardian,
            guardian,
          );
          _noLiveActionWidgets();
          if (!guardian && detail == ZyraConceptSettingsDetail.privacyPolicy) {
            await _capture(tester, '04-policy');
          }
          await _tap(
            tester,
            _key('concept_settings_help_detail_${detail.name}'),
          );
          expect(find.byType(HelpSupportScreen), findsOneWidget);
          _noLiveActionWidgets(helpSearchAllowed: true);
          await _back(tester);
          expect(_detail(detail), findsOneWidget);
          await _back(tester);
          expect(_overview(action), findsOneWidget);
        }
        await _tap(
          tester,
          _key('concept_settings_help_overview_${action.name}'),
        );
        expect(find.byType(HelpSupportScreen), findsOneWidget);
        await _back(tester);
        expect(_overview(action), findsOneWidget);
        await _back(tester);
        expect(find.byType(ZyraConceptSettingsPresentation), findsOneWidget);
        expect(owner.checkpoints.last.pages.last, 'settings');
      }
      for (final action in [ZyraConceptAccountAction.helpSupport]) {
        await _tap(tester, _key('concept_settings_${action.name}'));
        expect(find.byType(HelpSupportScreen), findsOneWidget);
        await _back(tester);
        expect(find.byType(ZyraConceptSettingsPresentation), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'actual hold cover denies saved Settings overview and detail actions',
    (tester) async {
      final owner = _ShellOwner();
      await owner.mount(tester, guardedRouteOwner: true);
      await owner.settings(tester);
      await owner.overview(tester, ZyraConceptAccountAction.signInSecurity);
      final overview = tester.widget<ZyraConceptSettingsOverview>(
        find.byType(ZyraConceptSettingsOverview),
      );
      final beforeElement = tester.element(
        find.byType(ZyraConceptSettingsOverview),
      );
      final back = tester
          .widget<ZyraPullDownBackScope>(_key('concept_pull_down_back_scope'))
          .onBack;
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      Future<void> cover() async {
        navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Member Settings cover')),
          ),
        );
        await tester.pumpAndSettle();
        expect(_key('dev_controls_page'), findsNothing);
        expect(_key('concept_page_options_context'), findsNothing);
      }

      await cover();
      final checkpoint = owner.checkpoints.last;
      overview.onOpenDetail(ZyraConceptSettingsDetail.recovery);
      overview.onHelp();
      back();
      await tester.pump();
      expect(_key('dev_controls_page'), findsNothing);
      expect(find.text('Member Settings cover'), findsOneWidget);
      expect(owner.checkpoints.last, same(checkpoint));
      navigator.pop();
      await tester.pumpAndSettle();
      expect(
        tester.element(find.byType(ZyraConceptSettingsOverview)),
        same(beforeElement),
      );
      await _tap(
        tester,
        _detailRow(
          ZyraConceptAccountAction.signInSecurity,
          ZyraConceptSettingsDetail.recovery,
        ),
      );
      final detail = tester.widget<ZyraConceptSettingsDetailPresentation>(
        find.byType(ZyraConceptSettingsDetailPresentation),
      );
      await cover();
      final detailCheckpoint = owner.checkpoints.last;
      detail.onHelp();
      await tester.pump();
      expect(owner.checkpoints.last, same(detailCheckpoint));
      navigator.pop();
      await tester.pumpAndSettle();
      expect(_detail(ZyraConceptSettingsDetail.recovery), findsOneWidget);
      await _tap(tester, _key('concept_settings_help_detail_recovery'));
      expect(find.byType(HelpSupportScreen), findsOneWidget);
    },
  );

  testWidgets(
    'saved Settings callbacks deny after page, role and owner changes',
    (tester) async {
      final owner = _ShellOwner();
      await owner.mount(tester);
      await owner.settings(tester);
      await owner.overview(tester, ZyraConceptAccountAction.privacyData);
      final saved = tester.widget<ZyraConceptSettingsOverview>(
        find.byType(ZyraConceptSettingsOverview),
      );
      await _tap(
        tester,
        _detailRow(
          ZyraConceptAccountAction.privacyData,
          ZyraConceptSettingsDetail.terms,
        ),
      );
      final checkpoint = owner.checkpoints.last;
      saved.onOpenDetail(ZyraConceptSettingsDetail.privacyPolicy);
      saved.onHelp();
      await tester.pump();
      expect(_detail(ZyraConceptSettingsDetail.terms), findsOneWidget);
      expect(owner.checkpoints.last, same(checkpoint));
      final savedDetail = tester.widget<ZyraConceptSettingsDetailPresentation>(
        find.byType(ZyraConceptSettingsDetailPresentation),
      );
      await _back(tester);
      savedDetail.onHelp();
      await tester.pump();
      expect(_overview(ZyraConceptAccountAction.privacyData), findsOneWidget);
      await _back(tester);
      await _back(tester);
      expect(find.byType(ZyraConceptProfilePresentation), findsOneWidget);
      expect(
        await pressZyraDevControlKey(tester, 'draft_role_guardian'),
        isTrue,
      );
      final switched = owner.checkpoints.last;
      saved.onOpenDetail(ZyraConceptSettingsDetail.privacyPolicy);
      saved.onHelp();
      savedDetail.onHelp();
      await tester.pump();
      expect(owner.checkpoints.last, same(switched));
      expect(owner.checkpoints.last.guardian, isTrue);
      expect(find.byType(ZyraConceptSettingsOverview), findsNothing);
      await _nav(tester, 'Profile');
      expect(await pressZyraDevControlKey(tester, 'draft_role_seeker'), isTrue);
      await _nav(tester, 'Profile');
      await owner.settings(tester);
      await owner.overview(tester, ZyraConceptAccountAction.signInSecurity);
      final current = tester.widget<ZyraConceptSettingsOverview>(
        find.byType(ZyraConceptSettingsOverview),
      );
      owner.allowed = false;
      final denied = owner.checkpoints.last;
      current.onOpenDetail(ZyraConceptSettingsDetail.recovery);
      current.onHelp();
      saved.onHelp();
      savedDetail.onHelp();
      await tester.pump();
      expect(owner.checkpoints.last, same(denied));
      expect(find.byType(HelpSupportScreen), findsNothing);
      expect(find.byType(ZyraConceptSettingsDetailPresentation), findsNothing);
    },
  );

  testWidgets('current policy availability and Help remain genuinely passive', (
    tester,
  ) async {
    _size(tester);
    var help = 0;
    await tester.pumpWidget(
      _app(
        ZyraConceptSettingsDetailPresentation(
          detail: ZyraConceptSettingsDetail.privacyPolicy,
          guardian: false,
          onHelp: () => help++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_detail(ZyraConceptSettingsDetail.privacyPolicy), findsOneWidget);
    expect(find.textContaining('not available here yet'), findsOneWidget);
    _noLiveActionWidgets();
    _visibleTextFits(tester);
    await _capture(tester, '06-current-policy');
    await _tap(tester, _key('concept_settings_help_detail_privacyPolicy'));
    expect(help, 1);
    expect(tester.takeException(), isNull);
  });
}
