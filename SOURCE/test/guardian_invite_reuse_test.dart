// Offline reuse of the original Guardian-code composition, not provider or
// relationship-service proof. No credentials, SDK session, or real invitation.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/screens/wali/link_guardian_panel.dart';
import 'package:zyra/screens/wali/zyra_code_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_product_telemetry.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _visualCaptures = String.fromEnvironment(
  'ZYRA_GUARDIAN_INVITE_CAPTURE_DIR',
);
const _visualBoundary = ValueKey('guardian-invite-visual-boundary');
const _visualReading = 'PoppinsGuardianInviteReuse';
const _visualWordmark = 'SyneGuardianInviteReuse';

const _own = ZyraPersonalCode(
  code: 'ZYRA-DEMO-SEEKER-ADAM',
  roleContext: 'seeker',
);
const _other = 'ZYRA-DEMO-GUARDIAN-IBRAHIM';
const _person = ZyraPersonalCodePreview(
  firstName: 'Local Guardian',
  role: 'wali',
);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Guardian reuse tests must not create a network client');
  }
}

Future<void> _recordInviteFrame(
  WidgetTester tester,
  String name,
  List<String> geometryFailures,
) async {
  await tester.pumpAndSettle();
  if (_visualCaptures.isNotEmpty) {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_visualBoundary),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('$_visualCaptures/$name.png');
        await file.create(exclusive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
  }

  // Retain all requested frames before failing qualification on geometry.
  // The captured image itself still requires the root's visual inspection.
  Object? exception;
  while ((exception = tester.takeException()) != null) {
    geometryFailures.add('$name: $exception');
  }
  for (final element
      in find
          .descendant(
            of: find.byKey(_visualBoundary),
            matching: find.byType(RichText),
          )
          .evaluate()) {
    final paragraph = element.renderObject;
    if (paragraph is! RenderParagraph || !paragraph.attached) continue;
    // Single-line input and its hint deliberately scroll horizontally. Check
    // its viewport/action separately, not as a wrapping prose paragraph.
    if (element.findAncestorWidgetOfExactType<TextField>() != null) continue;
    final text = paragraph.text.toPlainText();
    if (paragraph.didExceedMaxLines) {
      geometryFailures.add('$name: truncated text: $text');
    }
    // Reproduce the rendered paragraph's own effective span and layout, not a
    // separate global font/style assumption or selection-box ink bearings.
    final painter =
        TextPainter(
          text: paragraph.text,
          textAlign: paragraph.textAlign,
          textDirection: paragraph.textDirection,
          textScaler: paragraph.textScaler,
          maxLines: paragraph.maxLines,
          ellipsis: paragraph.overflow == TextOverflow.ellipsis
              ? '\u2026'
              : null,
          locale: paragraph.locale,
          strutStyle: paragraph.strutStyle,
          textWidthBasis: paragraph.textWidthBasis,
          textHeightBehavior: paragraph.textHeightBehavior,
        )..layout(
          minWidth: paragraph.constraints.minWidth,
          maxWidth:
              paragraph.softWrap || paragraph.overflow == TextOverflow.ellipsis
              ? paragraph.constraints.maxWidth
              : double.infinity,
        );
    if (painter.width > paragraph.size.width + 1 ||
        painter.height > paragraph.size.height + 1) {
      geometryFailures.add('$name: text outside its layout: $text');
    }
    painter.dispose();
  }
  final back = find.byKey(const ValueKey('zyra_visible_back_button'));
  expect(back, findsNothing);
  expect(find.text('Back'), findsNothing);
  expect(find.byKey(const ValueKey('zyra_back_header_space')), findsNothing);
  expect(find.byKey(const ValueKey('zyra_back_swipe_edge')), findsOneWidget);
  expect(
    find.byKey(const ValueKey('zyra_code_local_preview_denied')),
    findsNothing,
  );
  final title = find.text('Add a Guardian');
  expect(title, findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final nativeCalls = <String>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  int lookupCalls = 0;
  int linked = 0;
  int reads = 0;
  bool owner = true;
  bool interactive = true;
  int interactionEpoch = 0;

  ZyraCodeLocalPreview adapter({
    bool Function()? canAct,
    ZyraPersonalCode personalCode = _own,
    Future<ZyraPersonalCodePreview?> Function(String)? lookup,
  }) => ZyraCodeLocalPreview(
    canAct: canAct ?? () => owner,
    canInteract: () => interactive,
    interactionEpoch: () => interactionEpoch,
    personalCode: personalCode,
    lookupCode:
        lookup ??
        (code) async {
          lookupCalls++;
          return code == _other ? _person : null;
        },
  );

  Future<void> mount(
    WidgetTester tester,
    ZyraCodeLocalPreview? preview, {
    bool wrapper = false,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1000);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: ThemeData.dark(),
        home: wrapper
            ? LinkGuardianScreen(
                onLinked: () => linked++,
                localPreview: preview,
                previewLeading: const Icon(
                  Icons.arrow_back,
                  key: ValueKey('caller-back'),
                ),
              )
            : ZyraCodeScreen(
                key: const ValueKey('stable-code-owner'),
                asGuardian: false,
                localPreview: preview,
                onLinked: () => linked++,
                loadPersonalCode: ({roleContext}) async {
                  reads++;
                  return const ZyraSourceResult.available(
                    ZyraPersonalCode(
                      code: 'ZYRA-0001-0002-0003-0004-0005',
                      roleContext: 'seeker',
                    ),
                  );
                },
                loadGuardianRequests: () async {
                  reads++;
                  return const ZyraSourceResult.available(
                    <ZyraGuardianLinkRequest>[],
                  );
                },
              ),
      ),
    );
    await tester.pumpAndSettle();
  }

  InkWell action(WidgetTester tester, String label) => tester.widget<InkWell>(
    find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first,
  );

  Future<void> press(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String code) async {
    if (find
        .byKey(const ValueKey('inline-zyra-code-field'))
        .evaluate()
        .isEmpty) {
      await press(tester, 'Enter code');
    }
    await tester.enterText(
      find.byKey(const ValueKey('inline-zyra-code-field')),
      code,
    );
    await press(tester, 'Check');
  }

  void offlineTest(
    String name,
    Future<void> Function(WidgetTester) body, {
    bool localBoundary = true,
  }) {
    testWidgets(name, (tester) async {
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() => body(tester), network);
      expect(network.attempts, 0);
      if (localBoundary) expect(nativeCalls, isEmpty);
      expect(ZyraProductTelemetry.instance.snapshot.sessionEventCount, 0);
      expect(linked, 0);
      expect(tester.takeException(), isNull);
    });
  }

  setUpAll(() async {
    if (_visualCaptures.isNotEmpty &&
        (!_visualCaptures.startsWith('/') ||
            FileSystemEntity.typeSync(_visualCaptures, followLinks: false) !=
                FileSystemEntityType.directory ||
            Directory(_visualCaptures).resolveSymbolicLinksSync() !=
                Directory(_visualCaptures).path)) {
      throw StateError(
        'Captures require an existing absolute nonlinked directory.',
      );
    }
    final reading = FontLoader(_visualReading);
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final wordmark = FontLoader(_visualWordmark)
      ..addFont(rootBundle.load('assets/fonts/Syne-SemiBold.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
  });

  setUp(() {
    lookupCalls = 0;
    linked = 0;
    reads = 0;
    owner = true;
    interactive = true;
    interactionEpoch = 0;
    nativeCalls.clear();
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    ZyraProductTelemetry.instance.resetForTest();
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      // Capability booleans used by Flutter's ordinary text-editing menu are
      // not clipboard content access or an external feature action.
      if (call.method == 'LiveText.isLiveTextInputAvailable') {
        return false;
      }
      if (call.method == 'Clipboard.hasStrings') {
        return <String, dynamic>{'value': false};
      }
      if (!call.method.startsWith('SystemChrome.') &&
          call.method != 'SystemNavigator.setFrameworkHandlesBack') {
        nativeCalls.add('platform:${call.method}');
      }
      return null;
    });
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      nativeCalls.add('share:${call.method}');
      return '';
    });
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraAccountState.resetForTesting();
    ZyraProductTelemetry.instance.resetForTest();
    ZyraText.useTestFontStubs = false;
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    messenger.setMockMethodCallHandler(shareChannel, null);
  });

  for (final scenario in const [
    (
      name: 'standard',
      size: Size(393, 852),
      scale: 1.0,
      top: 59.0,
      bottom: 34.0,
    ),
    (
      name: 'compact200',
      size: Size(320, 568),
      scale: 2.0,
      top: 20.0,
      bottom: 0.0,
    ),
  ]) {
    offlineTest('real-font Invite visual geometry ${scenario.name}', (
      tester,
    ) async {
      final oldReading = ZyraText.testReadingFontFamily;
      final oldWordmark = ZyraText.testWordmarkFontFamily;
      addTearDown(() {
        ZyraText.testReadingFontFamily = oldReading;
        ZyraText.testWordmarkFontFamily = oldWordmark;
      });
      addTearDown(tester.view.resetPadding);
      ZyraText.testReadingFontFamily = _visualReading;
      ZyraText.testWordmarkFontFamily = _visualWordmark;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = scenario.size;
      tester.view.padding = FakeViewPadding(
        top: scenario.top,
        bottom: scenario.bottom,
      );
      final preview = adapter();
      final geometryFailures = <String>[];
      int backCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scenario.scale)),
            child: RepaintBoundary(key: _visualBoundary, child: child!),
          ),
          home: ZyraBackNavigationPreview(
            revision: 0,
            child: ZyraPullDownBackScope(
              inlineBackHeader: true,
              onBack: () => backCalls++,
              routeIdentity: 'guardian-invite-visual-${scenario.name}',
              child: LinkGuardianScreen(
                onLinked: () => linked++,
                localPreview: preview,
                previewLeading: const ZyraInlineBackButton(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(_own.code), findsOneWidget);
      expect(find.byType(ZyraInlineBackButton), findsNothing);
      final returnSize = ZyraInlineBackButton.preferredSizeOf(
        tester.element(find.byType(ZyraCodeScreen)),
      );
      expect(returnSize, isNull);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.leading, isNull);
      expect(appBar.leadingWidth, isNull);
      expect(appBar.automaticallyImplyLeading, isFalse);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).extendBodyBehindAppBar,
        isFalse,
      );
      await _recordInviteFrame(
        tester,
        'invite-${scenario.name}-own-code',
        geometryFailures,
      );

      await press(tester, 'Enter code');
      await tester.ensureVisible(
        find.byKey(const ValueKey('inline-zyra-code-field')),
      );
      final fieldRect = tester.getRect(
        find.byKey(const ValueKey('inline-zyra-code-field')),
      );
      expect(fieldRect.width, greaterThan(44));
      expect(fieldRect.overlaps(Offset.zero & scenario.size), isTrue);
      await _recordInviteFrame(
        tester,
        'invite-${scenario.name}-enter',
        geometryFailures,
      );

      await enter(tester, _other);
      expect(find.text('Local Guardian'), findsOneWidget);
      final initial = find.byKey(const ValueKey('zyra_code_person_initial'));
      final glyph = find.descendant(of: initial, matching: find.text('L'));
      final glyphParagraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: glyph, matching: find.byType(RichText)),
      );
      expect(
        tester.getSize(initial).height,
        greaterThanOrEqualTo(
          glyphParagraph.getMaxIntrinsicHeight(
            glyphParagraph.constraints.maxWidth,
          ),
        ),
      );
      await press(tester, 'Confirm');
      final notice = find.byKey(
        const ValueKey('zyra_code_local_confirmation_notice'),
      );
      await tester.ensureVisible(notice);
      await _recordInviteFrame(
        tester,
        'invite-${scenario.name}-local-confirmation',
        geometryFailures,
      );
      expect(notice, findsOneWidget);
      expect(find.text('Request sent'), findsNothing);
      expect(lookupCalls, 1);
      expect(reads, 0);
      expect(backCalls, 0);
      final screen = tester.widget<ZyraCodeScreen>(find.byType(ZyraCodeScreen));
      expect(identical(screen.localPreview, preview), isTrue);
      expect(screen.signupPreview, isFalse);
      expect(
        geometryFailures,
        isEmpty,
        reason: 'Real-font title and scrollable form must not clip.',
      );
      await swipeZyraBack(tester);
      expect(backCalls, 1);
    });
  }

  test('ordinary constructors do not opt into local preview', () {
    expect(const ZyraCodeScreen(asGuardian: false).localPreview, isNull);
    expect(LinkGuardianScreen(onLinked: () {}).localPreview, isNull);
  });

  offlineTest(
    'ordinary composition remains the original code and inline entry',
    (tester) async {
      ZyraInternalPreviewClient.finishSignOut();
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
      await mount(tester, null);
      expect(reads, 2);
      expect(find.text('Add a Guardian'), findsOneWidget);
      expect(find.text('ZYRA-0001-0002-0003-0004-0005'), findsOneWidget);
      expect(find.text('Scan code'), findsOneWidget);
      expect(find.text('Enter code'), findsOneWidget);
      expect(find.text('Change code'), findsOneWidget);
      await press(tester, 'Enter code');
      expect(
        find.byKey(const ValueKey('inline-zyra-code-entry')),
        findsOneWidget,
      );
      expect(find.text('Enter ZYRA Code'), findsNothing);
      expect(find.byKey(const ValueKey('signup_code_preview')), findsNothing);
    },
    localBoundary: false,
  );

  offlineTest('wrapper forwards local adapter and Back without a new layout', (
    tester,
  ) async {
    final preview = adapter();
    await mount(tester, preview, wrapper: true);
    final child = tester.widget<ZyraCodeScreen>(find.byType(ZyraCodeScreen));
    expect(identical(child.localPreview, preview), isTrue);
    expect(child.signupPreview, isFalse);
    expect(find.byKey(const ValueKey('caller-back')), findsOneWidget);
    expect(find.text('Add a Guardian'), findsOneWidget);
    expect(find.text(_own.code), findsOneWidget);
    expect(find.text('Scan code'), findsOneWidget);
    expect(find.text('Enter code'), findsOneWidget);
    expect(find.byKey(const ValueKey('signup_code_preview')), findsNothing);
    expect(reads, 0);
  });

  offlineTest(
    'local external actions are notices and QR is presentation only',
    (tester) async {
      await mount(tester, adapter());
      for (final label in ['Copy', 'Share', 'Scan code']) {
        await press(tester, label);
        expect(
          find.byKey(const ValueKey('zyra_code_local_notice')),
          findsOneWidget,
        );
        expect(find.text('Copied'), findsNothing);
        expect(find.byType(MobileScanner), findsNothing);
      }
      await press(tester, 'QR');
      expect(find.byType(QrImageView), findsOneWidget);
      await press(tester, 'QR');
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Change code'), findsNothing);
      expect(reads, 0);
    },
  );

  offlineTest('lookup uses only supplied fixture and Confirm does not send', (
    tester,
  ) async {
    final beforePlan = AppState.instance.plan;
    final beforeCount = ZyraDevScenario.instance.guardianCount;
    await mount(tester, adapter());
    await enter(tester, _other);
    expect(lookupCalls, 1);
    expect(find.text('Local Guardian'), findsOneWidget);
    await press(tester, 'Confirm');
    expect(
      find.byKey(const ValueKey('zyra_code_local_confirmation_notice')),
      findsOneWidget,
    );
    expect(find.textContaining('No invitation was sent.'), findsOneWidget);
    expect(find.text('Request sent'), findsNothing);
    expect(find.textContaining('can now accept'), findsNothing);
    expect(AppState.instance.plan, beforePlan);
    expect(ZyraDevScenario.instance.guardianCount, beforeCount);
    expect(reads, 0);
  });

  offlineTest('real and legacy code input never reaches lookup or fallback', (
    tester,
  ) async {
    await mount(tester, adapter());
    for (final code in [
      'ZYRA-0001-0002-0003-0004-0005',
      'OLD-INVITE-1234',
      'ZYRA-DEMO-UNKNOWN',
    ]) {
      await enter(tester, code);
      expect(find.text('Invalid code. Please try again.'), findsOneWidget);
      expect(find.text('Check an older invite code'), findsNothing);
      expect(find.text('Request sent'), findsNothing);
    }
    expect(lookupCalls, 1);
    expect(reads, 0);
  });

  offlineTest('denial is terminal even if caller grants again', (tester) async {
    final preview = adapter();
    await mount(tester, preview);
    final saved = action(tester, 'Copy').onTap!;
    owner = false;
    saved();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('zyra_code_local_preview_denied')),
      findsOneWidget,
    );
    owner = true;
    await mount(tester, preview);
    saved();
    await tester.pumpAndSettle();
    expect(find.text(_own.code), findsNothing);
    expect(find.text('Scan code'), findsNothing);
    expect(reads, 0);
  });

  offlineTest('throwing owner guard fails closed before reading or rendering', (
    tester,
  ) async {
    await mount(tester, adapter(canAct: () => throw StateError('revoked')));
    expect(
      find.byKey(const ValueKey('zyra_code_local_preview_denied')),
      findsOneWidget,
    );
    expect(find.text(_own.code), findsNothing);
    expect(reads, 0);
  });

  offlineTest('incorrect own role is denied before any live fallback', (
    tester,
  ) async {
    await mount(
      tester,
      adapter(
        personalCode: const ZyraPersonalCode(
          code: 'ZYRA-DEMO-GUARDIAN-IBRAHIM',
          roleContext: 'wali',
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('zyra_code_local_preview_denied')),
      findsOneWidget,
    );
    expect(find.text('Scan code'), findsNothing);
    expect(reads, 0);
  });

  offlineTest('requested local route without preview latch stays non-live', (
    tester,
  ) async {
    ZyraInternalPreviewClient.finishSignOut();
    await mount(tester, adapter());
    expect(
      find.byKey(const ValueKey('zyra_code_local_preview_denied')),
      findsOneWidget,
    );
    expect(find.text('Scan code'), findsNothing);
    expect(reads, 0);
  });

  offlineTest('malformed or same-role local lookup cannot confirm a person', (
    tester,
  ) async {
    await mount(
      tester,
      adapter(
        lookup: (_) async => const ZyraPersonalCodePreview(
          firstName: 'Wrong role',
          role: 'seeker',
        ),
      ),
    );
    await enter(tester, _other);
    expect(find.text('Wrong role'), findsNothing);
    expect(find.text('Invalid code. Please try again.'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
  });

  offlineTest('saved Confirm cannot acknowledge after a caller cover epoch', (
    tester,
  ) async {
    await mount(tester, adapter());
    await enter(tester, _other);
    final saved = action(tester, 'Confirm').onTap!;
    interactive = false;
    interactionEpoch++;
    saved();
    interactive = true;
    interactionEpoch++;
    saved();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('zyra_code_local_confirmation_notice')),
      findsNothing,
    );
    expect(find.text('Request sent'), findsNothing);
  });

  offlineTest('removing adapter cannot turn the same State into a live route', (
    tester,
  ) async {
    await mount(tester, adapter());
    await mount(tester, null);
    expect(
      find.byKey(const ValueKey('zyra_code_local_preview_denied')),
      findsOneWidget,
    );
    expect(reads, 0);
  });

  offlineTest('replacement adapter cannot reauthorise a captured lifetime', (
    tester,
  ) async {
    await mount(tester, adapter());
    await mount(tester, adapter());
    expect(
      find.byKey(const ValueKey('zyra_code_local_preview_denied')),
      findsOneWidget,
    );
    expect(reads, 0);
  });

  offlineTest('caller overlay epoch defeats covered callback ABA', (
    tester,
  ) async {
    final preview = adapter();
    await mount(tester, preview);
    final saved = action(tester, 'Copy').onTap!;
    interactive = false;
    interactionEpoch++;
    saved();
    interactive = true;
    interactionEpoch++;
    saved();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('zyra_code_local_notice')), findsNothing);
    await mount(tester, preview);
    await press(tester, 'Copy');
    expect(
      find.byKey(const ValueKey('zyra_code_local_notice')),
      findsOneWidget,
    );
  });

  offlineTest('saved text submission cannot launch lookup after caller cover', (
    tester,
  ) async {
    await mount(tester, adapter());
    await press(tester, 'Enter code');
    await tester.enterText(
      find.byKey(const ValueKey('inline-zyra-code-field')),
      _other,
    );
    await tester.pumpAndSettle();
    final saved = tester
        .widget<TextField>(find.byKey(const ValueKey('inline-zyra-code-field')))
        .onSubmitted!;
    interactive = false;
    interactionEpoch++;
    saved(_other);
    interactive = true;
    interactionEpoch++;
    saved(_other);
    await tester.pumpAndSettle();
    expect(lookupCalls, 0);
    expect(find.text('Local Guardian'), findsNothing);
  });

  offlineTest('route cover and return invalidate saved external callbacks', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await mount(tester, adapter(), navigatorKey: navigator);
    final saved = action(tester, 'Copy').onTap!;
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Covered route')),
      ),
    );
    await tester.pumpAndSettle();
    saved();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    saved();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('zyra_code_local_notice')), findsNothing);
  });

  for (final cover in ['caller overlay', 'route', 'background']) {
    offlineTest(
      'delayed lookup is retryable after $cover without stale result',
      (tester) async {
        final first = Completer<ZyraPersonalCodePreview?>();
        int checks = 0;
        final preview = adapter(
          lookup: (_) {
            checks++;
            return checks == 1
                ? first.future
                : Future.value(
                    const ZyraPersonalCodePreview(
                      firstName: 'Fresh Guardian',
                      role: 'wali',
                    ),
                  );
          },
        );
        final navigator = GlobalKey<NavigatorState>();
        await mount(tester, preview, navigatorKey: navigator);
        await enter(tester, _other);
        expect(checks, 1);
        expect(find.text('Checking…'), findsOneWidget);

        switch (cover) {
          case 'caller overlay':
            interactive = false;
            interactionEpoch++;
            await mount(tester, preview, navigatorKey: navigator);
            interactive = true;
            interactionEpoch++;
            await mount(tester, preview, navigatorKey: navigator);
            break;
          case 'route':
            navigator.currentState!.push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Covered lookup')),
              ),
            );
            await tester.pumpAndSettle();
            navigator.currentState!.pop();
            await tester.pumpAndSettle();
            break;
          case 'background':
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.hidden,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.paused,
            );
            await tester.pump();
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.hidden,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
            await tester.pumpAndSettle();
            break;
        }

        final field = tester.widget<TextField>(
          find.byKey(const ValueKey('inline-zyra-code-field')),
        );
        expect(field.controller!.text, _other);
        expect(find.text('Checking…'), findsNothing);
        await press(tester, 'Check');
        expect(checks, 2);
        expect(find.text('Fresh Guardian'), findsOneWidget);

        first.complete(
          const ZyraPersonalCodePreview(
            firstName: 'Stale Guardian',
            role: 'wali',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Fresh Guardian'), findsOneWidget);
        expect(find.text('Stale Guardian'), findsNothing);
        expect(find.text('Request sent'), findsNothing);
        expect(reads, 0);
      },
    );
  }

  offlineTest('background and resume invalidate callbacks and pending lookup', (
    tester,
  ) async {
    final held = Completer<ZyraPersonalCodePreview?>();
    await mount(tester, adapter(lookup: (_) => held.future));
    final saved = action(tester, 'Copy').onTap!;
    await press(tester, 'Enter code');
    await tester.enterText(
      find.byKey(const ValueKey('inline-zyra-code-field')),
      _other,
    );
    await press(tester, 'Check');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    held.complete(_person);
    saved();
    await tester.pumpAndSettle();
    expect(find.text('Local Guardian'), findsNothing);
    expect(find.text('Request sent'), findsNothing);
    expect(find.byKey(const ValueKey('zyra_code_local_notice')), findsNothing);
  });

  offlineTest('account-generation ABA blocks stale lookup and callbacks', (
    tester,
  ) async {
    final held = Completer<ZyraPersonalCodePreview?>();
    await mount(tester, adapter(lookup: (_) => held.future));
    final saved = action(tester, 'Copy').onTap!;
    await press(tester, 'Enter code');
    await tester.enterText(
      find.byKey(const ValueKey('inline-zyra-code-field')),
      _other,
    );
    await press(tester, 'Check');
    ZyraAccountState.resetForTesting(); // Same null owner, new generation.
    held.complete(_person);
    saved();
    await tester.pumpAndSettle();
    expect(find.text('Local Guardian'), findsNothing);
    expect(
      find.byKey(const ValueKey('zyra_code_local_preview_denied')),
      findsOneWidget,
    );
    expect(reads, 0);
  });

  offlineTest('invitation refresh and authority ABA cannot dispatch readers', (
    tester,
  ) async {
    await mount(tester, adapter());
    final saved = action(tester, 'Scan code').onTap!;
    ZyraWaliLinkService.invitationRevision.value++;
    await tester.pumpAndSettle();
    expect(find.text(_own.code), findsOneWidget);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    saved();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('zyra_code_local_preview_denied')),
      findsOneWidget,
    );
    expect(find.byType(MobileScanner), findsNothing);
    expect(reads, 0);
  });
}
