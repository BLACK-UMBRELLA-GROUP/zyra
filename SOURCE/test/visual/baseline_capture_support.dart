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
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_guardian_circle_preview.dart';
import 'package:zyra/main.dart' show ZyraApp;
import 'package:zyra/dev/zyra_membership_preview.dart';
import 'package:zyra/dev/zyra_subscription_wallet_draft.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import '../support/received_request_fixture.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_motion.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_swipe_track.dart';

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
// The default line126 CI suite registers existing real route fixtures and
// supplies a read-only raster callback. Ordinary capture behavior stays exact.
bool baselineTextAuditOnly = false;
Future<void> Function(BaselineHarness harness, String state)? baselineTextAudit;
Future<void> Function(
  BaselineHarness harness,
  String state,
  Map<String, Object?> evidence,
  void Function() verifyNonText,
)?
baselineNonTextObservation;
bool _auditingText = false;

class BaselineAuditViewport {
  const BaselineAuditViewport(this.size, this.scale);
  final Size size;
  final double scale;
  String get id =>
      '${size.width.toInt()}x${size.height.toInt()}@${scale.toStringAsFixed(1)}';
  EdgeInsets get safePadding => size.width == 375
      ? const EdgeInsets.only(top: 20)
      : const EdgeInsets.only(top: 59, bottom: 34);
}

final _auditViewport = ValueNotifier<BaselineAuditViewport?>(null);
bool _startedPreview = false;

class _AuditScrollBookmark {
  _AuditScrollBookmark(this.state)
    : offset = state.position.pixels,
      originalAxis = state.position.axisDirection,
      paged = state.position is PageMetrics,
      positionType = state.position.runtimeType.toString() {
    var child = state.context as Element;
    child.visitAncestorElements((parent) {
      if (editableOwner == null && parent.widget is EditableText) {
        editableOwner = parent.widget as EditableText;
        editableWasFocused = editableOwner!.focusNode.hasFocus;
        originalEditingValue = editableOwner!.controller.value;
      }
      if (textFieldOwner == null && parent.widget is TextField) {
        textFieldOwner = parent.widget as TextField;
      }
      final children = <Element>[];
      parent.visitChildren(children.add);
      final index = children.indexWhere((element) => identical(element, child));
      expect(
        index,
        greaterThanOrEqualTo(0),
        reason: 'Capture the exact original scroll Element path',
      );
      path.add((
        parent: parent,
        index: index,
        children: children.length,
        widgetType: child.widget.runtimeType,
        elementType: child.runtimeType,
        key: child.widget.key,
        widget: child.widget,
      ));
      if (ownerKey == null && parent.widget is ScrollView) {
        ownerKey = parent.widget.key;
      }
      child = parent;
      return parent.widget.key != _boundary;
    });
  }
  final ScrollableState state;
  final double offset;
  final AxisDirection originalAxis;
  final bool paged;
  final String positionType;
  String get description =>
      '$originalAxis/$positionType; '
      '${path.take(24).map((step) => step.widgetType).join('/')}';
  Key? ownerKey;
  EditableText? editableOwner;
  TextField? textFieldOwner;
  bool editableWasFocused = false;
  TextEditingValue? originalEditingValue;
  final path =
      <
        ({
          Element parent,
          int index,
          int children,
          Type widgetType,
          Type elementType,
          Key? key,
          Widget widget,
        })
      >[];

  ScrollableState resolve() {
    if (state.mounted) return state;
    final anchor = path.indexWhere((step) => step.parent.mounted);
    expect(
      anchor,
      greaterThanOrEqualTo(0),
      reason: 'Audit scroll restoration requires a surviving ancestor',
    );
    var current = path[anchor].parent;
    var verifiedFrameworkEditable = false;
    var scrollChrome = false, scrollSemantics = false, scrollGesture = false;
    for (var index = anchor; index >= 0; index--) {
      final step = path[index];
      final parentWidget = current.widget;
      final children = <Element>[];
      current.visitChildren(children.add);
      final reason =
          'Audit scroll structural path at '
          '${current.widget.runtimeType}[${step.index}]';
      expect(
        children.length,
        step.children,
        reason: '$reason must retain exact child cardinality',
      );
      expect(
        step.index,
        inInclusiveRange(0, children.length - 1),
        reason: '$reason must retain its original child slot',
      );
      current = children[step.index];
      expect(
        current.widget.runtimeType,
        step.widgetType,
        reason: '$reason must retain widget type',
      );
      expect(
        current.runtimeType,
        step.elementType,
        reason: '$reason must retain Element type',
      );
      if (current.widget is EditableText &&
          editableOwner != null &&
          textFieldOwner != null) {
        _verifyEditableOwner(current);
        verifiedFrameworkEditable = true;
      }
      final editableKey =
          verifiedFrameworkEditable &&
          step.key.runtimeType == current.widget.key.runtimeType &&
          ((current.widget is EditableText &&
                  step.key is GlobalKey<EditableTextState> &&
                  current.widget.key is GlobalKey<EditableTextState>) ||
              // Pinned Flutter EditableTextState declares its private
              // _scrollableKey as an untyped GlobalKey (editable_text.dart
              // 2538, used only on its internal Scrollable at 5814).
              (current.widget.runtimeType == Scrollable &&
                  step.key is GlobalKey &&
                  current.widget.key is GlobalKey));
      final chromeKey =
          scrollChrome &&
          step.key is GlobalKey &&
          current.widget.key is GlobalKey &&
          step.key.runtimeType == current.widget.key.runtimeType &&
          ((current.widget.runtimeType.toString() == '_ScrollSemantics' &&
                  parentWidget
                      is NotificationListener<ScrollMetricsNotification>) ||
              (current.widget is RawGestureDetector &&
                  scrollSemantics &&
                  parentWidget is Listener &&
                  index + 2 < path.length &&
                  path[index + 2].widgetType.toString() ==
                      '_ScrollableScope') ||
              (current.widget is IgnorePointer &&
                  scrollGesture &&
                  parentWidget is Semantics));
      if (!editableKey && !chromeKey) {
        expect(
          current.widget.key,
          step.key,
          reason: '$reason must retain widget key',
        );
      }
      if (chromeKey) {
        scrollSemantics |=
            current.widget.runtimeType.toString() == '_ScrollSemantics';
        scrollGesture |= current.widget is RawGestureDetector;
        // The private IgnorePointer ends Scrollable's own chrome. Its child
        // is the viewportBuilder result: all app keys below remain exact.
        if (current.widget is IgnorePointer) scrollChrome = false;
      }
      if (current.widget is Scrollable && index > 0) {
        final old = step.widget as Scrollable;
        final now = current.widget as Scrollable;
        expect(
          now.controller,
          same(old.controller),
          reason: 'A restored outer Scrollable must retain its controller',
        );
        expect(
          now.axisDirection,
          old.axisDirection,
          reason: 'A restored outer Scrollable must retain its axis',
        );
        scrollChrome = true;
        scrollSemantics = false;
        scrollGesture = false;
      }
      if (current.widget is Viewport ||
          current.widget is ShrinkWrappingViewport ||
          current.widget.runtimeType.toString() == '_SingleChildViewport') {
        scrollChrome = false;
      }
    }
    expect(
      current,
      isA<StatefulElement>(),
      reason: 'The exact restored scroll path must end at a state owner',
    );
    final restored = (current as StatefulElement).state;
    expect(
      restored,
      isA<ScrollableState>(),
      reason: 'The exact restored owner must still be Scrollable',
    );
    return restored as ScrollableState;
  }

  void _verifyEditableOwner(Element candidate) {
    final current = candidate.widget as EditableText;
    TextField? currentField;
    candidate.visitAncestorElements((element) {
      if (element.widget is TextField) {
        currentField = element.widget as TextField;
        return false;
      }
      return true;
    });
    expect(
      currentField,
      isNotNull,
      reason: 'Framework editable must retain its owning TextField',
    );
    expect(
      currentField!.key,
      textFieldOwner!.key,
      reason: 'All app-supplied TextField keys remain exact',
    );
    expect(
      currentField!.controller,
      same(textFieldOwner!.controller),
      reason: 'The owning field controller must remain exact',
    );
    expect(
      currentField!.focusNode,
      same(textFieldOwner!.focusNode),
      reason: 'The owning field explicit FocusNode configuration is exact',
    );
    final oldField = textFieldOwner!;
    final emptyReadOnlyDisplay =
        oldField.readOnly &&
        currentField!.readOnly &&
        oldField.controller == null &&
        currentField!.controller == null &&
        oldField.focusNode == null &&
        currentField!.focusNode == null &&
        oldField.key != null &&
        !editableWasFocused &&
        !current.focusNode.hasFocus &&
        originalEditingValue!.text.isEmpty &&
        current.controller.value == originalEditingValue &&
        oldField.maxLines == currentField!.maxLines &&
        oldField.minLines == currentField!.minLines &&
        oldField.maxLength == currentField!.maxLength &&
        oldField.enabled == currentField!.enabled &&
        oldField.expands == currentField!.expands &&
        oldField.obscureText == currentField!.obscureText &&
        oldField.style == currentField!.style &&
        oldField.decoration?.hintText == currentField!.decoration?.hintText &&
        oldField.decoration?.hintStyle == currentField!.decoration?.hintStyle &&
        oldField.decoration?.labelText == currentField!.decoration?.labelText &&
        oldField.decoration?.label == currentField!.decoration?.label &&
        oldField.decoration?.labelStyle ==
            currentField!.decoration?.labelStyle &&
        oldField.decoration?.helperText ==
            currentField!.decoration?.helperText &&
        oldField.decoration?.errorText == currentField!.decoration?.errorText;
    if (emptyReadOnlyDisplay) {
      final fields = find
          .byType(TextField)
          .evaluate()
          .where((element) => element.widget.key == oldField.key)
          .toList();
      expect(
        fields,
        hasLength(1),
        reason: 'An empty read-only display requires a unique current app key',
      );
      final editables = find
          .descendant(
            of: find.byWidget(currentField!),
            matching: find.byType(EditableText),
          )
          .evaluate()
          .toList();
      expect(editables, hasLength(1));
      expect(
        editables.single,
        same(candidate),
        reason: 'The exact keyed read-only owner must contain this editable',
      );
      return;
    }
    expect(
      current.controller,
      same(editableOwner!.controller),
      reason: 'Recreated editable must retain its original controller',
    );
    final sameFocus = identical(current.focusNode, editableOwner!.focusNode);
    final generatedUnfocused =
        textFieldOwner!.focusNode == null &&
        currentField!.focusNode == null &&
        !editableWasFocused &&
        !current.focusNode.hasFocus;
    expect(
      sameFocus || generatedUnfocused,
      isTrue,
      reason: 'Explicit FocusNodes and originally focused inputs remain exact',
    );
    expect(
      current.focusNode.hasFocus,
      editableWasFocused,
      reason: 'Reflow must preserve the original input focus state',
    );
    final matches = find.byType(EditableText).evaluate().where((element) {
      final editable = element.widget as EditableText;
      return identical(editable.controller, editableOwner!.controller) &&
          (generatedUnfocused ||
              identical(editable.focusNode, editableOwner!.focusNode));
    }).toList();
    expect(
      matches,
      hasLength(1),
      reason: 'Exactly one current editable may own the restored identity',
    );
    expect(
      matches.single,
      same(candidate),
      reason: 'The exact structural path must reach that same editable',
    );
  }
}

HttpOverrides? _previousNetwork;
late _NoNetwork _network;

String _capturePath(String path) {
  if (Platform.isMacOS || !path.startsWith('/Users/')) return path;
  return 'build/test_capture$path';
}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Baseline capture is local and must not use the network.');
  }
}

Future<void> baselineSetUp({
  String? evidenceRoot = baselineEvidence,
  bool? useSystemSymbolFont,
}) async {
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
  final symbolBytes = (useSystemSymbolFont ?? Platform.isMacOS)
      ? await File(_symbolPath).readAsBytes()
      : null;
  final symbols = symbolBytes == null
      ? null
      : (FontLoader(_symbolFont)
          ..addFont(Future.value(ByteData.sublistView(symbolBytes))));
  await Future.wait([
    reading.load(),
    icons.load(),
    wordmark.load(),
    if (symbols != null) symbols.load(),
  ]);
  if (!baselineTextAuditOnly &&
      !_compareOnly &&
      evidenceRoot != null &&
      symbolBytes != null) {
    final environment = File(
      _capturePath('$evidenceRoot/capture_environment.json'),
    );
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
  _startedPreview = !ZyraInternalPreviewClient.isActive;
  if (_startedPreview) ZyraInternalPreviewClient.beginPreview();
  AppState.instance.resetForAccountChange();
  ZyraColors.restoreAppPalette(null);
  ZyraAppGoldRenderer.instance.resetForTesting();
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
  if (_startedPreview) ZyraInternalPreviewClient.finishSignOut();
  _startedPreview = false;
  ZyraAccountState.clearImagesForTesting = null;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null);
}

// Read the app's actual presentation configuration without mounting its
// startup/auth home, lock gate, or invoking main(). Only the local preview
// below is mounted. This keeps every Material theme and scroll setting exact.
class _ProductionPreviewFrame extends StatelessWidget {
  const _ProductionPreviewFrame({
    required this.child,
    this.textScale = 1,
    this.highContrast = false,
    this.safePadding = const EdgeInsets.only(top: 59, bottom: 34),
    this.reduceMotion = false,
    this.navigatorObservers = const [],
    this.backdrop,
  });
  final double textScale;
  final bool highContrast;
  final EdgeInsets safePadding;
  final bool reduceMotion;
  final List<NavigatorObserver> navigatorObservers;
  final Widget child;
  final Decoration? backdrop;

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
          navigatorObservers: navigatorObservers,
          theme: app.theme!.copyWith(
            textTheme: app.theme!.textTheme.apply(
              fontFamilyFallback: const [_symbolFont],
            ),
          ),
          builder: (context, child) =>
              ValueListenableBuilder<BaselineAuditViewport?>(
                valueListenable: _auditViewport,
                builder: (context, viewport, auditChild) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: viewport?.safePadding ?? safePadding,
                    viewPadding: viewport?.safePadding ?? safePadding,
                    textScaler: TextScaler.linear(viewport?.scale ?? textScale),
                    highContrast: highContrast,
                    // Measured viewports force Reduced Motion. Between
                    // probes the fixture retains its original gesture mode.
                    disableAnimations: viewport != null || reduceMotion,
                  ),
                  child: auditChild!,
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamilyFallback: [_symbolFont]),
                  child: RepaintBoundary(
                    key: _boundary,
                    // The production MaterialApp.builder paints this outside
                    // its route. Keep it inside the raster boundary so raw
                    // RGBA contains the actual screen behind translucent UI.
                    child: baselineTextAuditOnly
                        ? DecoratedBox(
                            decoration: ZyraAppGoldDecoration(
                              gradient: ZyraColors.genderGradient(
                                AppState.instance.gender,
                              ),
                            ),
                            child: backdrop == null
                                ? child!
                                : DecoratedBox(
                                    decoration: backdrop!,
                                    child: child!,
                                  ),
                          )
                        : backdrop == null
                        ? child!
                        : DecoratedBox(decoration: backdrop!, child: child!),
                  ),
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
    this.textScale = 1,
    this.highContrast = false,
    this.logicalSize = const Size(430, 932),
    this.devicePixelRatio = 3,
    this.safePadding = const EdgeInsets.only(top: 59, bottom: 34),
    this.reduceMotion = false,
    this.circleArrivalsFor,
  });
  final WidgetTester tester;
  final String group;
  final String outputRoot, evidenceRoot;
  final bool flatOutput;
  final double textScale;
  final bool highContrast;
  final Size logicalSize;
  final double devicePixelRatio;
  final EdgeInsets safePadding;
  final bool reduceMotion;
  final ZyraCirclePreviewArrivals? circleArrivalsFor;
  late ZyraShellTestFixture shellFixture;
  bool guardian = false;
  List<Map<String, Object?>> get rows => _rowsByGroup.putIfAbsent(group, () {
    if (baselineTextAuditOnly) return [];
    final file = File(_capturePath('$evidenceRoot/rows_$group.json'));
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

  /// A negative fixture can deliberately prove that a guarded presenter has
  /// no content. This records that assertion without granting raster/route
  /// coverage or weakening the default text-bearing-frame requirement.
  Future<void> recordNonTextObservation(
    String state,
    Map<String, Object?> evidence, {
    required void Function() verifyNonText,
  }) async {
    await baselineNonTextObservation?.call(
      this,
      state,
      evidence,
      verifyNonText,
    );
  }

  /// Wait for the actual mounted image's first frame before taking a retained
  /// paint snapshot. In particular, the closed photo-action tray is covered
  /// by its own photo; the backing fill alone is not its settled appearance.
  /// The real event turn also completes already-pending platform/notifier
  /// replies before layout or scroll bookmarks are inspected.
  Future<void> prepareRasterFrame() async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    for (var pass = 0; pass < 4; pass++) {
      final pending = <(Image, BuildContext)>[];
      for (final element
          in find.byType(Image, skipOffstage: false).evaluate()) {
        final image = element.widget as Image;
        final raw = find.descendant(
          of: find.byElementPredicate(
            (candidate) => identical(candidate, element),
            skipOffstage: false,
          ),
          matching: find.byType(RawImage, skipOffstage: false),
          skipOffstage: false,
        );
        if (raw.evaluate().isEmpty ||
            tester
                .widgetList<RawImage>(raw)
                .every((raw) => raw.image == null)) {
          pending.add((image, element));
        }
      }
      if (pending.isEmpty) return;
      Object? imageFailure;
      StackTrace? imageFailureStack;
      await tester.runAsync(() async {
        try {
          for (final (widget, context) in pending) {
            if (!context.mounted) continue;
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
        } catch (error, stack) {
          // runAsync reports an escaping exception to the test binding and
          // returns null. Re-throw outside it so readiness cannot continue.
          imageFailure = error;
          imageFailureStack = stack;
        }
      });
      if (imageFailure != null) {
        Error.throwWithStackTrace(imageFailure!, imageFailureStack!);
      }
      await tester.pump();
    }
    throw TestFailure(
      'Mounted image first frames did not stabilize in four passes',
    );
  }

  Future<void> auditText(String state) async {
    final callback = baselineTextAudit;
    if (callback == null || _auditingText) return;
    _auditingText = true;
    try {
      await callback(this, state);
    } finally {
      _auditingText = false;
    }
  }

  /// Reject fixture-local MediaQuery overrides before granting tuple credit.
  /// The shell/signup context is below any nested fixture MediaQuery; the
  /// boundary alone cannot detect a child that forces 200 percent text.
  String? auditViewportMismatch(BaselineAuditViewport viewport) {
    final boundary = key('zyra-founder-baseline-boundary');
    if (boundary.evaluate().length != 1) {
      return 'Expected one production audit boundary';
    }
    final size = tester.getSize(boundary);
    if ((size.width - viewport.size.width).abs() > .001 ||
        (size.height - viewport.size.height).abs() > .001) {
      return 'Actual boundary $size differs from assigned ${viewport.id}';
    }
    final presenters = find
        .byWidgetPredicate(
          (widget) =>
              widget is ZyraOneJourneyConceptShell ||
              widget.runtimeType.toString() == 'ZyraSignupPreview',
        )
        .evaluate()
        .toList();
    final contexts = presenters.isEmpty ? boundary.evaluate() : presenters;
    for (final context in contexts) {
      final media = MediaQuery.of(context);
      if ((media.size.width - viewport.size.width).abs() > .001 ||
          (media.size.height - viewport.size.height).abs() > .001 ||
          (media.textScaler.scale(10) - 10 * viewport.scale).abs() > .0001 ||
          (media.textScaler.scale(24) - 24 * viewport.scale).abs() > .0001) {
        return 'Actual ${context.widget.runtimeType} MediaQuery '
            '${media.size}, scaler10=${media.textScaler.scale(10)} '
            'differs from assigned ${viewport.id}';
      }
    }
    return null;
  }

  /// Reflows the retained route rather than remounting a substitute screen.
  /// Geometry and every existing scroll offset are restored before the
  /// fixture's ordinary navigation and exact-size assertions continue.
  Future<void> withAuditViewport(
    BaselineAuditViewport viewport,
    Future<void> Function() action,
  ) async {
    if (tester.binding.transientCallbackCount > 0) {
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump();
    }
    for (var frame = 0; frame < 3; frame++) {
      final moving = tester
          .widgetList<ZyraSwipeTrack>(find.byType(ZyraSwipeTrack))
          .any((track) => track.controller?.isMoving ?? false);
      if (!moving) break;
      await tester.pump(ZyraMotion.duration + const Duration(milliseconds: 1));
      await tester.pump();
    }
    final tracks = <Key, int>{
      for (final track in tester.widgetList<ZyraSwipeTrack>(
        find.byType(ZyraSwipeTrack),
      ))
        if (track.key != null) track.key!: track.index,
    };
    Future<void> restoreTracks() async {
      // Some real presenters move the same pager between a fitted Expanded
      // branch and a natural-height branch. Reflow can remount its private
      // state; drive its actual public controller back to the captured page.
      for (final entry in tracks.entries) {
        final finder = find.byKey(entry.key);
        if (finder.evaluate().isEmpty) continue;
        final widget = tester.widget(finder);
        if (widget is! ZyraSwipeTrack || widget.index == entry.value) continue;
        expect(
          widget.controller,
          isNotNull,
          reason: 'A remounted audit pager requires its public controller',
        );
        widget.controller!.animateTo(entry.value);
        await tester.pump(
          ZyraMotion.duration + const Duration(milliseconds: 1),
        );
        await tester.pump();
        expect(
          tester.widget<ZyraSwipeTrack>(finder).index,
          entry.value,
          reason: 'Reflow must preserve the actual presenter page',
        );
      }
    }

    final oldSize = tester.view.physicalSize;
    final oldViewport = _auditViewport.value;
    final offsets = <_AuditScrollBookmark>[
      for (final state in tester.stateList<ScrollableState>(
        find.byType(Scrollable),
      ))
        _AuditScrollBookmark(state),
    ];
    try {
      tester.view.physicalSize = viewport.size * tester.view.devicePixelRatio;
      _auditViewport.value = viewport;
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump();
      }
      await restoreTracks();
      await action();
    } finally {
      tester.view.physicalSize = oldSize;
      _auditViewport.value = oldViewport;
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump();
      }
      await restoreTracks();
      if (tester.binding.transientCallbackCount > 0) {
        await tester.pump(const Duration(milliseconds: 650));
        await tester.pump();
      }
      for (final bookmark in offsets) {
        // A lazy sliver can correct its estimated leading extent on the next
        // layout after reflow. One jump plus two pumps therefore does not
        // restore its offset. Reapply the captured offset until layout stays
        // stable, resolving a remounted state through its real keyed owner.
        Future<void> restoreOffset(double target) async {
          var restored = false;
          for (var attempt = 0; attempt < 8; attempt++) {
            final position = bookmark.resolve().position;
            expect(position.hasContentDimensions, isTrue);
            position.jumpTo(target);
            await tester.pump();
            await tester.pump();
            final current = bookmark.resolve().position;
            if ((current.pixels - target).abs() < .01) {
              await tester.pump();
              if ((current.pixels - target).abs() < .01) {
                restored = true;
                break;
              }
            }
          }
          expect(
            restored,
            isTrue,
            reason:
                'Audit reflow must restore scroll offset '
                '$target under ${bookmark.ownerKey}; '
                'actual=${bookmark.resolve().position.pixels}, '
                'min=${bookmark.resolve().position.minScrollExtent}, '
                'max=${bookmark.resolve().position.maxScrollExtent}; '
                '${bookmark.description}',
          );
        }

        // Returning through the actual leading child rebuilds SliverList's
        // cached layout anchor using the restored text metrics. A matching
        // pixel offset alone can still point at a stale child layout offset.
        if (!bookmark.paged) {
          await restoreOffset(bookmark.resolve().position.minScrollExtent);
        }
        await restoreOffset(bookmark.offset);
      }
      await tester.pump();
      await tester.pump();
    }
  }

  Future<void> flush({bool auditText = true}) async {
    await tester.pump();
    await tester.pump(ZyraMotion.duration + const Duration(milliseconds: 1));
    await tester.pump();
    final error = tester.takeException();
    expect(error, isNull);
    if (auditText) await this.auditText('settled');
  }

  /// A bounded data-state fixture in the same production frame. The caller
  /// supplies real presenters; this never adds a route or data seam to the app.
  Future<void> mountPresentation({
    required Widget child,
    required ZyraPreviewNavigationCheckpoint checkpoint,
    Decoration? backdrop,
    Future<void> Function()? waitForPresentation,
  }) async {
    guardian = checkpoint.guardian;
    checkpoints
      ..clear()
      ..add(checkpoint);
    tester.view.physicalSize = logicalSize * devicePixelRatio;
    tester.view.devicePixelRatio = devicePixelRatio;
    await tester.pumpWidget(
      _ProductionPreviewFrame(
        textScale: textScale,
        highContrast: highContrast,
        safePadding: safePadding,
        reduceMotion: reduceMotion,
        backdrop: backdrop,
        child: child,
      ),
    );
    // Readiness-owned fixtures supply their existing bounded public wait.
    // The initial audit always follows it; no frame/key mismatch is retried.
    if (waitForPresentation != null) await waitForPresentation();
    await flush();
  }

  Future<void> mount({
    bool guardian = false,
    int tab = 0,
    List<String> pages = const [],
    String? personId = 'draft-sara',
    ViewRequestDraftModel? model,
    ZyraPreviewNavigationCheckpoint? checkpoint,
    bool receivedRequest = true,
    int requestsTab = 0,
    String seekerMembership = 'Seeker One',
    String guardianMembership = 'Guardian One',
    bool initialSeekerBasic = false,
    bool initialGuardianBasic = false,
    bool restoreLocation = true,
    DateTime Function()? previewClock,
    List<String>? seekerPhotos,
    Future<bool> Function()? confirmSensitiveAction,
    Map<ZyraWalletRole, ZyraMembershipPreviewRecord?>? membershipRecords,
    List<NavigatorObserver> navigatorObservers = const [],
  }) async {
    this.guardian = guardian;
    ZyraColors.restoreAppPalette(null);
    ZyraAppGoldRenderer.instance.resetForTesting();
    ZyraInteractionStyle.restoreDefaults();
    ZyraText.restoreAppFont(null);
    checkpoints.clear();
    tester.view.physicalSize = logicalSize * devicePixelRatio;
    tester.view.devicePixelRatio = devicePixelRatio;
    final ready = Completer<void>();
    shellFixture = ZyraShellTestFixture(
      circleArrivalsFor: circleArrivalsFor,
      seekerPhotos: seekerPhotos,
      confirmSensitiveAction: confirmSensitiveAction,
      membershipRecords: membershipRecords,
    );
    final capacity = initialSeekerBasic ? 1 : 3;
    final defaultModel = receivedRequest
        ? ReceivedRequestFixture(capacity: capacity)
        : ViewRequestDraftModel(capacity: capacity);
    await tester.pumpWidget(
      _ProductionPreviewFrame(
        textScale: textScale,
        highContrast: highContrast,
        safePadding: safePadding,
        reduceMotion: reduceMotion,
        navigatorObservers: navigatorObservers,
        child: ZyraOneJourneyConceptShell(
          fixture: shellFixture.fixture,
          key: UniqueKey(),
          canAct: () => true,
          onExit: () => fail('Capture must stay in the local Founder preview.'),
          initialGuardianRole: guardian,
          initialSeekerBasic: initialSeekerBasic,
          initialGuardianBasic: initialGuardianBasic,
          restoreLocation: restoreLocation,
          initialCheckpoint:
              checkpoint ??
              ZyraPreviewNavigationCheckpoint(
                guardian: guardian,
                model: (model ?? defaultModel).snapshot(),
                guardianTabs: guardian && receivedRequest && model == null
                    ? const ZyraGuardianTabsSnapshot(
                        connection: ZyraGuardianConnection.pending,
                      )
                    : const ZyraGuardianTabsSnapshot.quiet(),
                tab: tab,
                pages: pages,
                personId: personId,
                requestsTab: requestsTab,
                seekerMembership: seekerMembership,
                guardianMembership: guardianMembership,
              ),
          previewClock: previewClock ?? () => DateTime.utc(2026, 10, 29, 12),
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

  Future<void> tap(String id) async {
    if (await pressZyraDevControlKey(tester, id)) return;
    await tapFinder(key(id));
  }

  Future<void> tapText(String label, {bool contains = false}) async =>
      tapFinder(contains ? find.textContaining(label) : find.text(label));
  Future<void> tapFinder(Finder target) async {
    if (await pressZyraFixtureFinder(tester, target)) return;
    if (target.evaluate().isEmpty) {
      final containers = [
        key('dev_controls_scroll'),
        key('my-zyra-quiet-scroll-0'),
        key('draft_scroll'),
        key('concept-current-profile-scroll'),
        key('personalisation-scroll'),
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
    await flush(auditText: false);
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
    if (baselineTextAuditOnly) {
      await auditText('$area/$page/$state');
      rows.add({
        'area': area,
        'page': page,
        'state': state,
        'reached': reached,
      });
      return;
    }
    final relative = flatOutput
        ? fileName ?? '${page}__$state.png'
        : '${guardian ? 'guardian' : 'seeker'}/$area/${page}__$state.png';
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundary),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: devicePixelRatio);
      try {
        expect(image.width, (logicalSize.width * devicePixelRatio).round());
        expect(image.height, (logicalSize.height * devicePixelRatio).round());
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(_capturePath('$outputRoot/$relative'));
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
              _capturePath(
                '${baselineEvidence.replaceFirst('BASELINE_2026-10-29', 'TIER4_TESTS_2026-10-29')}/PIXEL_PARITY_MISMATCHES/$relative',
              ),
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
          'width': image.width,
          'height': image.height,
          'route': latest.pages,
          'tab': latest.tab,
        });
        final output = File(_capturePath('$evidenceRoot/rows_$group.json'));
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
