// Capture the unchanged local Founder preview; no live account or transport.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/main.dart' show ZyraApp;
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';

import '../support/zyra_hidden_dev_controls_driver.dart';

const baselineRoot =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/PRODUCT/APPROVED/BASELINE/SCREENSHOTS';
const baselineEvidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/OA-ZYRA-316_BASELINE_2026-10-29';
const _font = 'ZYRABaselinePoppins';
const _wordmark = 'ZYRABaselineSyne';
const _symbolFont = 'ZYRABaselineSystemSymbols';
const _symbolPath = '/System/Library/Fonts/SFNS.ttf';
const _compareOnly = bool.fromEnvironment('ZYRA_BASELINE_COMPARE_ONLY');
final _rowsByGroup = <String, List<Map<String, Object?>>>{};
final _matchedBaselinePaths = <String>{};
final _skippedControlPaths = <String>{};
final _mismatchedBaselinePaths = <String>{};
const _boundary = ValueKey('zyra-founder-baseline-boundary');
HttpOverrides? _previousNetwork;
late _NoNetwork _network;

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Baseline capture is local and must not use the network.');
  }
}

Future<void> baselineSetUp({String evidenceRoot = baselineEvidence}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  final reading = FontLoader(_font);
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
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  final wordmark = FontLoader(_wordmark)
    ..addFont(rootBundle.load('assets/fonts/Syne-SemiBold.ttf'));
  final symbolBytes = await File(_symbolPath).readAsBytes();
  final symbols = FontLoader(_symbolFont)
    ..addFont(Future.value(ByteData.sublistView(symbolBytes)));
  await Future.wait([
    reading.load(),
    icons.load(),
    wordmark.load(),
    symbols.load(),
  ]);
  if (!_compareOnly) {
    final environment = File('$evidenceRoot/capture_environment.json');
    await environment.parent.create(recursive: true);
    await environment.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'logical_size': [430, 932],
        'device_pixel_ratio': 3,
        'png_size': [1290, 2796],
        'ios_status_bar': false,
        'target_platform': 'iOS',
        'theme': 'actual ZyraApp MaterialApp.theme + documented glyph fallback',
        'scroll_behavior': 'actual ZyraApp MaterialApp.scrollBehavior',
        'primary_reading_font': 'bundled Poppins',
        'wordmark': 'bundled Syne',
        'missing_glyph_fallback': {
          'family': _symbolFont,
          'source': _symbolPath,
          'bytes': symbolBytes.length,
          'sha256': sha256.convert(symbolBytes).toString(),
          'purpose':
              'San Francisco platform fallback for U+2713; primary fonts unchanged; font not copied',
        },
      }),
      flush: true,
    );
  }
  ZyraText.useTestFontStubs = true;
  ZyraText.testReadingFontFamily = _font;
  ZyraText.testWordmarkFontFamily = _wordmark;
  _previousNetwork = HttpOverrides.current;
  _network = _NoNetwork();
  HttpOverrides.global = _network;
  ZyraAccountState.resetForTesting();
  ZyraAccountState.clearImagesForTesting = () async {};
  ZyraDeveloperAccess.resetAuthorizationForTesting();
  ZyraDeveloperAccess.setAuthorizedForTesting(true);
  AppState.instance.resetForAccountChange();
  ZyraColors.restoreAppPalette(null);
  ZyraDevAppGold.instance.resetForTesting();
  ZyraInteractionStyle.restoreDefaults();
  ZyraText.restoreAppFont(null);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
}

Future<void> baselineTearDown() async {
  expect(_network.attempts, 0);
  if (_compareOnly) {
    debugPrint(
      'ZYRA_BASELINE_COMPARE_ONLY ${jsonEncode({'matched_pngs': _matchedBaselinePaths.length, 'skipped_controls': _skippedControlPaths.length, 'mismatched_pngs': _mismatchedBaselinePaths.length})}',
    );
  }
  HttpOverrides.global = _previousNetwork;
  ZyraText.useTestFontStubs = false;
  ZyraText.testReadingFontFamily = null;
  ZyraText.testWordmarkFontFamily = null;
  ZyraDeveloperAccess.resetAuthorizationForTesting();
  ZyraAccountState.clearImagesForTesting = null;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null);
}

// Read the app's actual presentation configuration without mounting its
// startup/auth home, lock gate, or invoking main(). Only the local preview
// below is mounted. This keeps every Material theme and scroll setting exact.
class _ProductionPreviewFrame extends StatelessWidget {
  const _ProductionPreviewFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final source = const ZyraApp().build(context) as ListenableBuilder;
    return ListenableBuilder(
      listenable: source.listenable,
      builder: (context, _) {
        final app = source.builder(context, null) as MaterialApp;
        return MaterialApp(
          debugShowCheckedModeBanner: app.debugShowCheckedModeBanner,
          scrollBehavior: app.scrollBehavior,
          theme: app.theme!.copyWith(
            textTheme: app.theme!.textTheme.apply(
              fontFamilyFallback: const [_symbolFont],
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 59, bottom: 34),
              viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
              textScaler: TextScaler.noScaling,
              disableAnimations: false,
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontFamilyFallback: [_symbolFont]),
              child: RepaintBoundary(key: _boundary, child: child!),
            ),
          ),
          home: child,
        );
      },
    );
  }
}

class BaselineHarness {
  BaselineHarness(
    this.tester, {
    required this.group,
    this.outputRoot = baselineRoot,
    this.evidenceRoot = baselineEvidence,
    this.flatOutput = false,
  });
  final WidgetTester tester;
  final String group;
  final String outputRoot, evidenceRoot;
  final bool flatOutput;
  bool guardian = false;
  List<Map<String, Object?>> get rows => _rowsByGroup.putIfAbsent(group, () {
    final file = File('$evidenceRoot/rows_$group.json');
    if (file.existsSync()) {
      return (jsonDecode(file.readAsStringSync()) as List)
          .map((row) => Map<String, Object?>.from(row as Map))
          .toList();
    }
    return [];
  });
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];
  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;
  Finder key(String id) => find.byKey(ValueKey(id));

  Future<void> flush() async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final error = tester.takeException();
    expect(error, isNull);
  }

  /// A bounded data-state fixture in the same production frame. The caller
  /// supplies real presenters; this never adds a route or data seam to the app.
  Future<void> mountPresentation({
    required Widget child,
    required ZyraPreviewNavigationCheckpoint checkpoint,
  }) async {
    guardian = checkpoint.guardian;
    checkpoints
      ..clear()
      ..add(checkpoint);
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    await tester.pumpWidget(_ProductionPreviewFrame(child: child));
    await flush();
  }

  Future<void> mount({
    bool guardian = false,
    int tab = 0,
    List<String> pages = const [],
    String? personId = 'draft-sara',
    ViewRequestDraftModel? model,
    ZyraPreviewNavigationCheckpoint? checkpoint,
    int requestsTab = 0,
    String seekerMembership = 'Seeker One',
    String guardianMembership = 'Guardian One',
    bool initialSeekerBasic = false,
    bool initialGuardianBasic = false,
  }) async {
    this.guardian = guardian;
    ZyraColors.restoreAppPalette(null);
    ZyraDevAppGold.instance.resetForTesting();
    ZyraInteractionStyle.restoreDefaults();
    ZyraText.restoreAppFont(null);
    checkpoints.clear();
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    final ready = Completer<void>();
    await tester.pumpWidget(
      _ProductionPreviewFrame(
        child: ZyraOneJourneyConceptShell(
          key: UniqueKey(),
          canAct: () => true,
          onExit: () => fail('Capture must stay in the local Founder preview.'),
          initialGuardianRole: guardian,
          initialSeekerBasic: initialSeekerBasic,
          initialGuardianBasic: initialGuardianBasic,
          initialCheckpoint:
              checkpoint ??
              ZyraPreviewNavigationCheckpoint(
                guardian: guardian,
                model:
                    (model ??
                            ViewRequestDraftModel(
                              capacity: initialSeekerBasic ? 1 : 3,
                            ))
                        .snapshot(),
                tab: tab,
                pages: pages,
                personId: personId,
                requestsTab: requestsTab,
                seekerMembership: seekerMembership,
                guardianMembership: guardianMembership,
              ),
          previewClock: () => DateTime.utc(2026, 10, 29, 12),
          onCheckpoint: checkpoints.add,
          onPresentationReady: () {
            if (!ready.isCompleted) ready.complete();
          },
        ),
      ),
    );
    for (var frame = 0; frame < 150 && !ready.isCompleted; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(
      ready.isCompleted,
      isTrue,
      reason: 'Bundled local photos must prepare',
    );
    await flush();
    expect(checkpoints, isNotEmpty);
  }

  void assertPage(String page) => expect(
    latest.pages.lastOrNull,
    page,
    reason: 'Capture route must be genuinely open',
  );
  Future<void> controls() => openZyraDevControls(tester);
  Future<void> closeControls() => closeZyraDevControls(tester);

  Future<void> tap(String id) async => tapFinder(key(id));
  Future<void> tapText(String label, {bool contains = false}) async =>
      tapFinder(contains ? find.textContaining(label) : find.text(label));
  Future<void> tapFinder(Finder target) async {
    if (target.evaluate().isEmpty) {
      final containers = [
        key('dev_controls_scroll'),
        key('my-zyra-quiet-scroll-0'),
        key('draft_scroll'),
      ];
      final owners = containers.where((f) => f.evaluate().isNotEmpty).toList();
      if (owners.isNotEmpty) {
        final scroll = find
            .descendant(of: owners.first, matching: find.byType(Scrollable))
            .first;
        if (scroll.evaluate().isNotEmpty) {
          await tester.scrollUntilVisible(
            target,
            160,
            scrollable: scroll,
            maxScrolls: 80,
          );
        }
      }
    }
    expect(target, findsOneWidget);
    final ancestors = find.ancestor(
      of: target,
      matching: find.byType(Scrollable),
    );
    if (ancestors.evaluate().isNotEmpty) {
      await Scrollable.ensureVisible(tester.element(target), alignment: .5);
      await flush();
    }
    expect(target.hitTestable(), findsOneWidget);
    await tester.tap(target);
    await flush();
  }

  Future<void> capture(
    String area,
    String page,
    String state,
    String reached, {
    String? fileName,
  }) async {
    await flush();
    for (final view in tester.widgetList<ZyraOneJourneyBrowsePresentation>(
      find.byType(ZyraOneJourneyBrowsePresentation),
    )) {
      expect(
        view.profile.photos,
        isNotEmpty,
        reason: 'Normal photo captures require real prepared sample photos',
      );
    }
    for (final view in tester.widgetList<ZyraOneJourneyBrowseDesigns>(
      find.byType(ZyraOneJourneyBrowseDesigns),
    )) {
      for (final profile in view.profiles) {
        expect(
          profile.photos,
          isNotEmpty,
          reason: 'Sample deck must be genuinely prepared',
        );
      }
    }
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    await tester.runAsync(() async {
      for (final widget in images) {
        final context = tester.element(find.byWidget(widget).first);
        final stream = widget.image.resolve(
          createLocalImageConfiguration(context),
        );
        final painted = Completer<void>();
        final listener = ImageStreamListener(
          (info, _) {
            info.dispose();
            if (!painted.isCompleted) painted.complete();
          },
          onError: (Object error, StackTrace? stack) {
            if (!painted.isCompleted) painted.completeError(error, stack);
          },
        );
        stream.addListener(listener);
        try {
          await painted.future.timeout(const Duration(seconds: 10));
        } finally {
          stream.removeListener(listener);
        }
      }
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    for (final widget in images) {
      final raw = find.descendant(
        of: find.byWidget(widget).first,
        matching: find.byType(RawImage),
      );
      if (raw.evaluate().isNotEmpty) {
        expect(
          tester.widget<RawImage>(raw.first).image,
          isNotNull,
          reason: 'Mounted image must paint an actual frame',
        );
      }
    }
    final relative = flatOutput
        ? fileName ?? '${page}__$state.png'
        : '${guardian ? 'guardian' : 'seeker'}/$area/${page}__$state.png';
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundary),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      try {
        expect(image.width, 1290);
        expect(image.height, 2796);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('$outputRoot/$relative');
        if (_compareOnly) {
          if (page == 'controls') {
            _skippedControlPaths.add(relative);
            return;
          }
          expect(
            file.existsSync(),
            isTrue,
            reason: 'Baseline must exist: $relative',
          );
          final actual = sha256.convert(bytes!.buffer.asUint8List()).toString();
          final expected = sha256.convert(await file.readAsBytes()).toString();
          if (actual != expected) {
            _mismatchedBaselinePaths.add(relative);
            final mismatch = File(
              '${baselineEvidence.replaceFirst('BASELINE_2026-10-29', 'TIER4_TESTS_2026-10-29')}/PIXEL_PARITY_MISMATCHES/$relative',
            );
            await mismatch.parent.create(recursive: true);
            await mismatch.writeAsBytes(
              bytes.buffer.asUint8List(),
              flush: true,
            );
          }
          expect(
            actual,
            expected,
            reason: 'Current pixels differ from preserved baseline: $relative',
          );
          _matchedBaselinePaths.add(relative);
          return;
        }
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
        rows.removeWhere((row) => row['file'] == relative);
        rows.add({
          'role': guardian ? 'Guardian' : 'Seeker',
          'area': area,
          'page': page,
          'state': state,
          'reached': reached,
          'file': relative,
          'width': 1290,
          'height': 2796,
          'route': latest.pages,
          'tab': latest.tab,
        });
        final output = File('$evidenceRoot/rows_$group.json');
        await output.parent.create(recursive: true);
        await output.writeAsString(
          const JsonEncoder.withIndent('  ').convert(rows),
          flush: true,
        );
      } finally {
        image.dispose();
      }
    });
  }
}
