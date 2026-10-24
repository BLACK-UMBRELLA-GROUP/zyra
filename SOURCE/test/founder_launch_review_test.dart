// OA304/305: explicit internal launch attention is not a global theme,
// approval, document publication, permission grant or member-facing control.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_founder_launch_review.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_settings_details.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/settings/help_support_screen.dart';
import 'package:zyra/screens/settings/legal_document_screen.dart';
import 'package:zyra/screens/settings/privacy_and_data_screen.dart';
import 'package:zyra/screens/settings/safety_case_status_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _reading = 'PoppinsFounderLaunchReview';
const _wordmark = 'SyneFounderLaunchReview';
const _captures = String.fromEnvironment('ZYRA_FOUNDER_WHITE_CAPTURE_DIR');
const _captureKey = ValueKey('founder-launch-review-capture');
const _pages = ['overview_privacyData', 'detail_privacyPolicy', 'detail_terms'];
const _nativeChannels = [
  'plugins.flutter.io/local_auth',
  'dev.flutter.pigeon.local_auth_darwin.LocalAuthApi.authenticate',
  'dev.flutter.pigeon.local_auth_android.LocalAuthApi.authenticate',
  'plugins.it_nomads.com/flutter_secure_storage',
  'plugins.flutter.io/google_sign_in',
  'dev.flutter.pigeon.google_sign_in_ios.GoogleSignInApi.signIn',
  'plugins.flutter.io/url_launcher',
];

Finder _key(String id) => find.byKey(ValueKey(id));

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

Widget _page(
  String id, {
  bool guardian = false,
  VoidCallback? onHelp,
  ValueChanged<ZyraConceptSettingsDetail>? onDetail,
}) {
  if (id.startsWith('overview_')) {
    final action = ZyraConceptAccountAction.values.singleWhere(
      (value) => 'overview_${value.name}' == id,
    );
    return ZyraConceptSettingsOverview(
      action: action,
      data: _data(guardian),
      onOpenDetail: onDetail ?? (_) {},
      onHelp: onHelp ?? () {},
    );
  }
  return ZyraConceptSettingsDetailPresentation(
    detail: ZyraConceptSettingsDetail.values.singleWhere(
      (value) => 'detail_${value.name}' == id,
    ),
    guardian: guardian,
    onHelp: onHelp ?? () {},
  );
}

Widget _app(
  Widget child, {
  bool compact = false,
  Set<ZyraFounderLaunchRequirement>? pending,
}) => MaterialApp(
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
      child: SizedBox.expand(
        child: pending == null
            ? child
            : ZyraFounderLaunchPageStyle(pending: pending, child: child),
      ),
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

void _readable(WidgetTester tester, {required bool white}) {
  for (final element in find.byType(Text).evaluate()) {
    final text = element.widget as Text;
    expect(text.maxLines, isNull);
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    if (white) {
      expect(
        text.style?.color,
        isIn(const [
          ZyraFounderLaunchPageStyle.darkInk,
          ZyraFounderLaunchPageStyle.darkSecondaryInk,
          ZyraFounderLaunchPageStyle.darkGoldInk,
        ]),
      );
    }
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

Future<void> _reveal(WidgetTester tester, Finder target) async {
  final scrollables = find.byType(Scrollable);
  expect(scrollables, findsWidgets);
  final scrollable = scrollables.last;
  if (target.evaluate().isEmpty) {
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      target,
      150,
      scrollable: scrollable,
      maxScrolls: 60,
    );
  }
  expect(target, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await _reveal(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captures.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    _key(_captureKey.value),
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

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Internal launch review must remain offline.');
  }
}

class _Owner {
  bool allowed = true;
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];

  bool canAct() => allowed;

  Future<void> mount(WidgetTester tester, {bool guardian = false}) async {
    final ready = Completer<void>();
    await tester.pumpWidget(
      _app(
        ZyraOneJourneyConceptShell(
          key: UniqueKey(),
          canAct: canAct,
          onExit: () => fail('A review leaf must return within its owner.'),
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
    expect(tester.takeException(), isNull);
  }

  Future<void> privacy(WidgetTester tester) async {
    await _tap(tester, _key('concept_settings'));
    await _tap(tester, _key('concept_settings_privacyData'));
    expect(_key('concept_settings_overview_privacyData'), findsOneWidget);
  }
}

void _shellCanvas(WidgetTester tester, {required bool white}) {
  final shell = find.byType(ZyraOneJourneyConceptShell);
  final scaffold = find
      .descendant(of: shell, matching: find.byType(Scaffold))
      .first;
  expect(
    tester.widget<Scaffold>(scaffold).backgroundColor,
    white ? Colors.white : ZyraColors.luxuryDarkPurple,
  );
  final region = find
      .descendant(
        of: shell,
        matching: find.byWidgetPredicate(
          (widget) => widget is AnnotatedRegion<SystemUiOverlayStyle>,
        ),
      )
      .first;
  expect(
    tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(region).value,
    white ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
  );
  final scope = tester.widget<ZyraPullDownBackScope>(
    _key('concept_pull_down_back_scope'),
  );
  expect(
    scope.returnForegroundColor,
    white ? ZyraFounderLaunchPageStyle.darkGoldInk : null,
  );
  if (white) {
    expect(scope.paintBackground, isFalse);
    final canvas = find
        .descendant(
          of: shell,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color == Colors.white &&
                (widget.decoration as BoxDecoration).gradient == null,
          ),
        )
        .first;
    expect(tester.getSize(canvas), tester.view.physicalSize);
    expect(_key('zyra_pull_down_bottom_cue_arrow'), findsNothing);
    final back = _key('zyra_visible_back_button');
    expect(back, findsNothing);
    expect(find.text('Back'), findsNothing);
    expect(_key('zyra_back_swipe_edge'), findsOneWidget);
  }
}

Future<void> _back(WidgetTester tester, {bool edge = false}) async {
  if (!edge) {
    await returnZyraPreviewPage(tester);
    return;
  }
  final sensor = _key('zyra_back_swipe_edge');
  expect(sensor, findsOneWidget);
  final rect = tester.getRect(sensor);
  await tester.timedDragFrom(
    Offset(rect.left + 8, rect.top + rect.height * .35),
    const Offset(180, 0),
    const Duration(milliseconds: 450),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
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
  late List<Object?> beforeGlobals;
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
  ];
  List<Object?> globalState() => [
    ZyraColors.devPalette,
    ZyraColors.devLightAccent,
    ZyraColors.appSurfaceStyle,
    ZyraColors.foreground,
    ZyraInteractionStyle.hapticLevel,
    ZyraText.appFont,
    ZyraAppGoldStyle.instance.enabled,
    ZyraDevAppGold.instance.renderingEnabled,
  ];

  setUpAll(() async {
    if (_captures.isNotEmpty) {
      if (!_captures.startsWith('/')) {
        throw StateError('Capture path must be absolute.');
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
          throw StateError('Capture requires existing nonlinked directories.');
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
    SharedPreferences.setMockInitialValues({'founder-review-sentinel': 'keep'});
    await ZyraLocalPrefs.init();
    preferences = await SharedPreferences.getInstance();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await ZyraAccountState.synchronize('founder-review-member');
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraAppGoldStyle.instance.restore(false);
    ZyraDevAppGold.instance.resetForTesting();
    ZyraColors.restoreAppPalette(null);
    ZyraInteractionStyle.restoreHapticLevel(null);
    ZyraText.restoreAppFont(null);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _reading;
    ZyraText.testWordmarkFontFamily = _wordmark;
    beforePreferences = preferenceState();
    beforeMember = memberState();
    beforeGlobals = globalState();
    network = _NoNetwork();
    HttpOverrides.global = network;
    nativeCalls.clear();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in _nativeChannels) {
      messenger.setMockMessageHandler(channel, (message) async {
        nativeCalls.add(channel);
        return null;
      });
    }
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
  });

  tearDown(() {
    try {
      expect(network.attempts, 0);
      expect(nativeCalls, isEmpty);
      expect(preferenceState(), beforePreferences);
      expect(memberState(), beforeMember);
      expect(globalState(), beforeGlobals);
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
      for (final channel in _nativeChannels) {
        messenger.setMockMessageHandler(channel, null);
      }
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    }
  });

  test(
    'only explicit internally admitted metadata receives launch attention',
    () {
      const review = ZyraFounderLaunchReview();
      expect(review.pendingFor(_pages[0], internalReview: true), {
        ZyraFounderLaunchRequirement.privacyPolicy,
        ZyraFounderLaunchRequirement.terms,
      });
      expect(review.pendingFor(_pages[1], internalReview: true), {
        ZyraFounderLaunchRequirement.privacyPolicy,
      });
      expect(review.pendingFor(_pages[2], internalReview: true), {
        ZyraFounderLaunchRequirement.terms,
      });
      for (final id in [
        null,
        'Privacy Policy',
        'Required before launch',
        'Founder input needed before launch',
        'detail_terms_suffix',
        'detail_notifications',
        'checkout unavailable',
        'overview_appLock',
      ]) {
        expect(
          review.pendingFor(id, internalReview: true),
          isEmpty,
          reason: '$id is not registered metadata',
        );
      }
      for (final id in _pages) {
        expect(review.pendingFor(id, internalReview: false), isEmpty);
      }
      expect(
        () => review.pendingFor(_pages[0], internalReview: true).clear(),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'resolving one requirement leaves only its explicit remaining dependencies',
    () {
      for (final remaining in [
        ZyraFounderLaunchRequirement.privacyPolicy,
        ZyraFounderLaunchRequirement.terms,
      ]) {
        final review = ZyraFounderLaunchReview(outstanding: {remaining});
        expect(review.pendingFor(_pages[0], internalReview: true), {remaining});
        expect(
          review.pendingFor('detail_${remaining.name}', internalReview: true),
          {remaining},
        );
        final other = [
          ZyraFounderLaunchRequirement.privacyPolicy,
          ZyraFounderLaunchRequirement.terms,
        ].singleWhere((value) => value != remaining);
        expect(
          review.pendingFor('detail_${other.name}', internalReview: true),
          isEmpty,
        );
      }
      const resolved = ZyraFounderLaunchReview(outstanding: {});
      for (final id in _pages) {
        expect(resolved.pendingFor(id, internalReview: true), isEmpty);
      }
    },
  );

  test(
    'destructive specifications have explicit internal-only requirements',
    () {
      const review = ZyraFounderLaunchReview();
      const mappings = {
        'detail_resetProfile': ZyraFounderLaunchRequirement.resetSpecification,
        'detail_deleteAccount':
            ZyraFounderLaunchRequirement.deletionSpecification,
      };
      expect(
        review.pendingFor('overview_advanced', internalReview: true),
        mappings.values.toSet(),
      );
      for (final entry in mappings.entries) {
        expect(review.pendingFor(entry.key, internalReview: true), {
          entry.value,
        });
        expect(review.pendingFor(entry.key, internalReview: false), isEmpty);
        expect(
          ZyraFounderLaunchPageStyle.noteFor({entry.value}),
          contains('Execution remains on hold.'),
        );
        expect(
          const ZyraFounderLaunchReview(
            outstanding: {},
          ).pendingFor(entry.key, internalReview: true),
          isEmpty,
        );
      }
      expect(
        review.pendingFor('overview_visibility', internalReview: true),
        isEmpty,
      );
    },
  );

  for (final guardian in [false, true]) {
    for (final id in [
      'overview_advanced',
      'detail_resetProfile',
      'detail_deleteAccount',
    ]) {
      for (final compact in [false, true]) {
        testWidgets(
          '$id ${guardian ? 'Guardian' : 'Seeker'} ${compact ? 'compact200' : 'normal'} is an internal-only non-executing specification hold',
          (tester) async {
            _size(tester, compact: compact);
            final pending = const ZyraFounderLaunchReview().pendingFor(
              id,
              internalReview: true,
            );
            await tester.pumpWidget(
              _app(
                _page(id, guardian: guardian),
                compact: compact,
                pending: pending,
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.widget<Material>(_key('concept_settings_$id')).color,
              Colors.white,
            );
            expect(
              find.text('Founder input needed before launch'),
              findsOneWidget,
            );
            expect(find.byType(FilledButton), findsNothing);
            _readable(tester, white: true);
            await tester.pumpWidget(
              _app(_page(id, guardian: guardian), compact: compact),
            );
            await tester.pumpAndSettle();
            expect(
              find.text('Founder input needed before launch'),
              findsNothing,
            );
            expect(
              tester.widget<Material>(_key('concept_settings_$id')).color,
              Colors.transparent,
            );
            expect(find.byType(FilledButton), findsNothing);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final guardian in [false, true]) {
    for (final id in _pages) {
      for (final compact in [false, true]) {
        testWidgets(
          '${guardian ? 'Guardian' : 'Seeker'} $id ${compact ? '320px200%' : '393pxnormal'} is white readable and accessible',
          (tester) async {
            _size(tester, compact: compact);
            final semantics = tester.ensureSemantics();
            try {
              var helpCalls = 0;
              final opened = <ZyraConceptSettingsDetail>[];
              await tester.pumpWidget(
                _app(
                  _page(
                    id,
                    guardian: guardian,
                    onHelp: () => helpCalls++,
                    onDetail: opened.add,
                  ),
                  compact: compact,
                  pending: const ZyraFounderLaunchReview().pendingFor(
                    id,
                    internalReview: true,
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(
                tester.widget<Material>(_key('concept_settings_$id')).color,
                Colors.white,
              );
              final title = tester.widget<Text>(
                _key('concept_settings_title_$id'),
              );
              expect(title.style!.fontFamily, _reading);
              expect(title.style!.color, ZyraFounderLaunchPageStyle.darkInk);
              await _reveal(tester, _key('founder_launch_note_$id'));
              expect(
                find.text('Founder input needed before launch'),
                findsOneWidget,
              );
              _readable(tester, white: true);
              if ((!guardian && !compact) ||
                  (guardian && compact && id == 'overview_privacyData')) {
                await _capture(
                  tester,
                  '${guardian ? 'guardian' : 'seeker'}-$id-${compact ? 'compact' : 'normal'}',
                );
              }
              await _reveal(tester, _key('concept_settings_preview_scope_$id'));
              _readable(tester, white: true);
              if (id.startsWith('overview_')) {
                for (final detail in [
                  ZyraConceptSettingsDetail.privacyPolicy,
                  ZyraConceptSettingsDetail.terms,
                ]) {
                  final destination = _key(
                    'concept_settings_open_privacyData_${detail.name}',
                  );
                  await _reveal(tester, destination);
                  expect(
                    tester.getSize(destination).height,
                    greaterThanOrEqualTo(48),
                  );
                  _readable(tester, white: true);
                  await _tap(tester, destination);
                }
                expect(opened, [
                  ZyraConceptSettingsDetail.privacyPolicy,
                  ZyraConceptSettingsDetail.terms,
                ]);
              } else {
                await _reveal(tester, find.text('A separate formal document'));
                _readable(tester, white: true);
              }
              final help = _key('concept_settings_help_$id');
              await _reveal(tester, help);
              expect(tester.getSize(help).height, greaterThanOrEqualTo(48));
              expect(tester.getSize(help).width, greaterThanOrEqualTo(44));
              expect(
                find.bySemanticsLabel('Open Help & support'),
                findsOneWidget,
              );
              _readable(tester, white: true);
              await _tap(tester, help);
              expect(helpCalls, 1);
              expect(find.byType(HelpSupportScreen), findsNothing);
              expect(find.byType(SafetyCaseStatusScreen), findsNothing);
              expect(find.byType(Switch), findsNothing);
              expect(find.byType(Checkbox), findsNothing);
              expect(find.byType(TextField), findsNothing);
              expect(tester.takeException(), isNull);
            } finally {
              semantics.dispose();
            }
          },
        );
      }
    }
  }

  testWidgets(
    'resolving metadata removes only the internal note and restores local normal colours',
    (tester) async {
      _size(tester);
      for (final id in _pages) {
        await tester.pumpWidget(
          _app(
            _page(id),
            pending: const ZyraFounderLaunchReview().pendingFor(
              id,
              internalReview: true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(_key('founder_launch_note_$id'), findsOneWidget);
        await tester.pumpWidget(_app(_page(id), pending: const {}));
        await tester.pumpAndSettle();
        expect(_key('founder_launch_note_$id'), findsNothing);
        expect(find.text('Founder input needed before launch'), findsNothing);
        expect(
          tester.widget<Material>(_key('concept_settings_$id')).color,
          Colors.transparent,
        );
        expect(
          tester.widget<Text>(_key('concept_settings_title_$id')).style!.color,
          ZyraColors.foreground,
        );
        if (id == 'overview_privacyData') {
          await _capture(tester, 'resolved-overview_privacyData-normal');
        }
        // Clearing attention metadata cannot manufacture a published document.
        if (id.startsWith('detail_')) {
          expect(find.textContaining('not available here yet'), findsOneWidget);
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'absent scope and generic unavailable pages never infer white attention',
    (tester) async {
      _size(tester);
      for (final id in [
        ..._pages,
        'overview_appLock',
        'overview_notificationSettings',
        'detail_feedback',
        'detail_notifications',
      ]) {
        final pending = const ZyraFounderLaunchReview().pendingFor(
          id,
          internalReview: true,
        );
        await tester.pumpWidget(
          _app(_page(id), pending: _pages.contains(id) ? null : pending),
        );
        await tester.pumpAndSettle();
        expect(find.text('Founder input needed before launch'), findsNothing);
        expect(
          tester.widget<Material>(_key('concept_settings_$id')).color,
          Colors.transparent,
        );
        expect(
          tester.widget<Text>(_key('concept_settings_title_$id')).style!.color,
          ZyraColors.foreground,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ordinary legal pages remain unscoped despite developer authorisation',
    (tester) async {
      _size(tester);
      for (final guardian in [false, true]) {
        for (final document in ZyraLegalDocument.values) {
          await tester.pumpWidget(
            _app(LegalDocumentScreen(document: document, guardian: guardian)),
          );
          await tester.pumpAndSettle();
          expect(find.byType(ZyraFounderLaunchPageStyle), findsNothing);
          expect(find.text('Founder input needed before launch'), findsNothing);
          expect(find.text('Not available yet'), findsOneWidget);
          expect(find.byType(HelpSupportScreen), findsNothing);
        }
        await tester.pumpWidget(_app(PrivacyAndDataScreen(guardian: guardian)));
        await tester.pumpAndSettle();
        expect(find.byType(ZyraFounderLaunchPageStyle), findsNothing);
        expect(find.text('Founder input needed before launch'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final (guardian, method) in [
    for (final guardian in [false, true])
      for (final method in ['button', 'edge']) (guardian, method),
  ]) {
    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} $method actual shell white canvas status return and theme restoration',
      (tester) async {
        _size(tester);
        final owner = _Owner();
        await owner.mount(tester, guardian: guardian);
        await owner.privacy(tester);
        _shellCanvas(tester, white: true);
        await _capture(
          tester,
          'shell-${guardian ? 'guardian' : 'seeker'}-$method-privacy',
        );
        for (final detail in [
          ZyraConceptSettingsDetail.privacyPolicy,
          ZyraConceptSettingsDetail.terms,
        ]) {
          await _tap(
            tester,
            _key('concept_settings_open_privacyData_${detail.name}'),
          );
          _shellCanvas(tester, white: true);
          final help = _key('concept_settings_help_detail_${detail.name}');
          await _tap(tester, help);
          expect(find.byType(HelpSupportScreen), findsOneWidget);
          expect(_key('help-support-preview-title'), findsOneWidget);
          expect(_key('support-safety-case-status'), findsNothing);
          expect(_key('help-support-email-action'), findsNothing);
          _shellCanvas(tester, white: false);
          await _back(tester, edge: method == 'edge');
          expect(
            _key('concept_settings_detail_${detail.name}'),
            findsOneWidget,
          );
          _shellCanvas(tester, white: true);
          await _back(tester, edge: method == 'edge');
          expect(_key('concept_settings_overview_privacyData'), findsOneWidget);
        }
        await _back(tester, edge: method == 'edge');
        expect(find.byType(ZyraConceptSettingsPresentation), findsOneWidget);
        expect(find.text('Founder input needed before launch'), findsNothing);
        _shellCanvas(tester, white: false);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets(
    'old white-page Help callback cannot act after owner loss or fresh mount',
    (tester) async {
      _size(tester);
      final oldOwner = _Owner();
      await oldOwner.mount(tester);
      await oldOwner.privacy(tester);
      final help = _key('concept_settings_help_overview_privacyData');
      await _reveal(tester, help);
      final saved = tester.widget<OutlinedButton>(help).onPressed!;
      oldOwner.allowed = false;
      saved();
      await tester.pumpAndSettle();
      expect(find.byType(HelpSupportScreen), findsNothing);
      final freshOwner = _Owner();
      await freshOwner.mount(tester, guardian: true);
      saved();
      await tester.pumpAndSettle();
      expect(find.byType(HelpSupportScreen), findsNothing);
      expect(find.byType(ZyraConceptProfilePresentation), findsOneWidget);
      expect(find.text('Founder input needed before launch'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
