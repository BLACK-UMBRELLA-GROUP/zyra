import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
// OA-ZYRA-151: protected Founder presentation launch and resume integration.
// Sessions, refreshed users and member rows are synthetic. Every backend
// request is intercepted; this is not deployed Auth/RLS/provider acceptance.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
// The real picker flow uses only generated, in-memory bytes in these tests.
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_concept_preview_boundary.dart';
import 'package:zyra/dev/zyra_dev_local_preview.dart';
import 'package:zyra/dev/zyra_founder_launch_screen.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/widgets/zyra_account_session_host.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_sample_photos.dart';
import 'package:zyra/dev/zyra_preview_resume_transition.dart';
import 'package:zyra/main.dart';
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/screens/profile/edit_photos_screen.dart';
import 'package:zyra/screens/profile/my_profile_preview_screen.dart';
import 'package:zyra/screens/profile/photo_crop_review_screen.dart';
import 'package:zyra/screens/wali/wali_home_shell.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_app_lock.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_session_router.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/zyra_loading.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _founder = ZyraInternalFounderPolicy.approvedFounderUserId;
const _member = '00000000-0000-4000-8000-000000000941';
const _roleKey = 'zyra.founder_preview_role';
const _quietCaptureDirectory = String.fromEnvironment(
  'ZYRA_QUIET_LAUNCH_CAPTURE_DIR',
);
const _accessCaptureDirectory = String.fromEnvironment(
  'ZYRA_QUIET_ACCESS_CAPTURE_DIR',
);
const _quietFont = 'PoppinsQuietFounderLaunch';
const _quietCaptureKey = ValueKey('quiet-founder-launch-capture');
Completer<void>? _heldBrowsePhotoGate;

/// Delays the platform picker without opening a device library or a file.
/// Unlike photoBatchRunner, this exercises selection, sanitization and crop.
class _PendingLocalPhotoPicker extends ImagePickerPlatform {
  _PendingLocalPhotoPicker({this.red = 16});

  final int red;
  final release = Completer<void>();
  int calls = 0;
  bool selectionReturned = false;

  void releaseSelection() {
    if (!release.isCompleted) release.complete();
  }

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    calls++;
    await release.future;
    final source = img.Image(width: 60, height: 80);
    img.fill(source, color: img.ColorRgb8(red, 165, 91));
    source.textData = {'Comment': 'synthetic-local-import-only'};
    selectionReturned = true;
    return [XFile.fromData(img.encodePng(source), mimeType: 'image/png')];
  }
}

Future<void> _waitForLocalImport(
  WidgetTester tester,
  bool Function() complete,
  String reason,
) async {
  for (var turn = 0; turn < 200 && !complete(); turn++) {
    await tester.pump(const Duration(milliseconds: 10));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
  }
  expect(complete(), isTrue, reason: reason);
}

Future<void> _session(String id, {bool founderClaim = false}) async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': id, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': id,
        'app_metadata': founderClaim ? {'zyra_role': 'founder'} : {},
        // Deliberately spoofed display metadata must never confer authority.
        'user_metadata': {
          'zyra_role': 'founder',
          'email': 'founder@example.invalid',
        },
        'aud': 'authenticated',
        'created_at': '2026-10-09T00:00:00Z',
      },
    }),
  );
}

class _LockscreenOpening {
  const _LockscreenOpening({
    required this.shell,
    required this.editor,
    required this.toggle,
    required this.preferences,
    required this.memberPhotos,
  });

  final ZyraOneJourneyConceptShell shell;
  final State<EditPhotosScreen> editor;
  final VoidCallback toggle;
  final Map<String, Object?> preferences;
  final List<String> memberPhotos;
}

Future<void> _pauseForLockscreen(WidgetTester tester) async {
  // Paint every real departure state. A single batched resume sequence misses
  // the case in which a background auth refresh withdraws proof before resume.
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }
}

void _expectNoLockscreenLoading(
  WidgetTester tester, {
  bool allowCoveredPreparation = false,
}) {
  expect(_key('zyra_loading_golden_thread'), findsNothing);
  final loading = find.byType(ZyraLoading);
  final cover = find.byWidgetPredicate(
    (widget) =>
        widget.key == const ValueKey('founder_resume_continuity') ||
        widget.key == const ValueKey('founder_resume_quiet_background'),
  );
  if (!allowCoveredPreparation || cover.evaluate().isEmpty) {
    expect(loading, findsNothing);
  } else if (loading.evaluate().isNotEmpty) {
    expect(cover, findsOneWidget);
    final root = find.byType(ZyraFounderReviewSurface);
    expect(root, findsOneWidget);
    final rootRect = tester.getRect(root);
    final coverRect = tester.getRect(cover);
    expect(coverRect.left, closeTo(rootRect.left, .001));
    expect(coverRect.top, closeTo(rootRect.top, .001));
    expect(coverRect.right, closeTo(rootRect.right, .001));
    expect(coverRect.bottom, closeTo(rootRect.bottom, .001));
    final blockers = find.ancestor(
      of: cover,
      matching: find.byType(AbsorbPointer),
    );
    expect(
      tester
          .widgetList<AbsorbPointer>(blockers)
          .any((widget) => widget.absorbing),
      isTrue,
    );
    final semanticsBlocks = find.ancestor(
      of: cover,
      matching: find.byType(BlockSemantics),
    );
    expect(
      tester
          .widgetList<BlockSemantics>(semanticsBlocks)
          .any((widget) => widget.blocking),
      isTrue,
    );
    final background =
        _key('founder_resume_quiet_background').evaluate().isNotEmpty
        ? _key('founder_resume_quiet_background')
        : find
              .ancestor(
                of: cover,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is DecoratedBox &&
                      widget.decoration is BoxDecoration &&
                      (widget.decoration as BoxDecoration).gradient ==
                          ZyraColors.brandGradient,
                ),
              )
              .first;
    final decoration =
        tester.widget<DecoratedBox>(background).decoration as BoxDecoration;
    expect(decoration.gradient, ZyraColors.brandGradient);
    expect(decoration.gradient!.colors.every((color) => color.a == 1), isTrue);
    final backgroundRect = tester.getRect(background);
    expect(backgroundRect.contains(rootRect.topLeft), isTrue);
    expect(backgroundRect.right, greaterThanOrEqualTo(rootRect.right - .001));
    expect(backgroundRect.bottom, greaterThanOrEqualTo(rootRect.bottom - .001));
    final capture = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_FounderPreviewCapture',
    );
    expect(capture, findsOneWidget);
    final capturedLoading = find.descendant(of: capture, matching: loading);
    expect(capturedLoading.evaluate().length, loading.evaluate().length);
    for (final loader in tester.widgetList<ZyraLoading>(loading)) {
      expect(loader.fullScreen, isFalse);
    }
    // Prove paint order: the entire opaque/inert cover is a later sibling of
    // the fresh capture, not simply another rectangle somewhere in the tree.
    final stacks = tester
        .widgetList<Stack>(
          find.ancestor(of: capture, matching: find.byType(Stack)),
        )
        .where(
          (stack) => stack.children.any(
            (child) => child.runtimeType.toString() == '_FounderPreviewCapture',
          ),
        )
        .toList();
    expect(stacks, hasLength(1));
    final stack = stacks.single;
    expect(
      stack.children.first.runtimeType.toString(),
      '_FounderPreviewCapture',
    );
    expect(stack.children.length, greaterThan(1));
    expect(
      find.descendant(of: find.byWidget(stack.children.last), matching: cover),
      findsOneWidget,
    );
    expect(loading.hitTestable(), findsNothing);
    expect(
      find.semantics.byLabel(RegExp(r'\bLoading(?: ZYRA)?\b')),
      findsNothing,
    );
  }
  expect(find.byType(HomeShell), findsNothing);
  expect(find.byType(WaliHomeShell), findsNothing);
}

void _expectLockscreenCover(WidgetTester tester, {bool proofPending = true}) {
  _expectNoLockscreenLoading(tester, allowCoveredPreparation: !proofPending);
  expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
  expect(
    _key('founder_resume_continuity').evaluate().length +
        _key('founder_resume_quiet_background').evaluate().length,
    1,
    reason: 'A background proof handoff may show only its passive cover.',
  );
  if (proofPending) {
    expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
    expect(find.byType(EditPhotosScreen), findsNothing);
    expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
  }
  expect(ZyraInternalPreviewClient.isActive, isTrue);
  expect(ZyraConceptPreviewIsolation.active, isTrue);
}

Future<void> _waitForLockscreenBarrier(
  WidgetTester tester,
  bool Function() reached,
  String reason, {
  Duration advance = Duration.zero,
}) async {
  for (var turn = 0; turn < 40 && !reached(); turn++) {
    await tester.pump(advance);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(reached(), isTrue, reason: reason);
}

bool _matchesFreshFounder(User user) => ZyraInternalFounderPolicy.allows(
  variant: ZyraAppVariant.production,
  internalBuildEnabled: true,
  suppliedFounderUserId: _founder,
  supabaseUrl: ZyraInternalFounderPolicy.approvedSupabaseUrl,
  userId: user.id,
  appMetadata: user.appMetadata,
  claimsAreFresh: true,
);

Finder _key(String id) => find.byKey(ValueKey(id));

void _expectQuietLoading(WidgetTester tester) {
  final target = find.byType(ZyraQuietLoading);
  expect(target, findsOneWidget);
  expect(find.byType(ZyraLoading), findsNothing);
  expect(_key('zyra_loading_golden_thread'), findsNothing);
  expect(find.text('Opening ZYRA…'), findsNothing);
  expect(find.text('Checking preview access…'), findsNothing);
  expect(find.text('ZYRA'), findsNothing);
  final box = find.descendant(of: target, matching: find.byType(DecoratedBox));
  expect(box, findsOneWidget);
  final decoration =
      tester.widget<DecoratedBox>(box).decoration as BoxDecoration;
  expect(decoration.gradient, ZyraColors.brandGradient);
  expect(decoration.gradient!.colors.every((color) => color.a == 1), isTrue);
  expect(
    tester.getSize(box),
    tester.view.physicalSize / tester.view.devicePixelRatio,
  );
  expect(
    tester
        .widgetList<AbsorbPointer>(
          find.descendant(of: target, matching: find.byType(AbsorbPointer)),
        )
        .every((widget) => widget.absorbing),
    isTrue,
  );
  expect(
    find.descendant(of: target, matching: find.byType(BlockSemantics)),
    findsOneWidget,
  );
  expect(
    tester
        .widgetList<Text>(
          find.descendant(of: target, matching: find.byType(Text)),
        )
        .every((widget) => widget.data == 'Updating…'),
    isTrue,
    reason: 'Runtime waits have only optional delayed stationary feedback.',
  );
}

void _expectResumeContinuity(WidgetTester tester) {
  expect(_key('founder_resume_continuity'), findsOneWidget);
  expect(find.byType(ZyraLoading), findsNothing);
  expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is Semantics && widget.properties.label == 'Checking access',
    ),
    findsOneWidget,
  );
  final image = tester.widget<RawImage>(_key('founder_resume_continuity'));
  expect(image.image, isNotNull);
  expect(image.image!.width, lessThanOrEqualTo(2048));
  expect(image.image!.height, lessThanOrEqualTo(2048));
  expect(
    find.ancestor(
      of: _key('founder_resume_continuity'),
      matching: find.byType(AbsorbPointer),
    ),
    findsWidgets,
  );
}

void _expectLongResumeQuiet(WidgetTester tester) {
  final canvas = _key('founder_resume_quiet_background');
  expect(canvas, findsOneWidget);
  expect(_key('founder_resume_continuity'), findsNothing);
  expect(_key('zyra_loading_golden_thread'), findsNothing);
  expect(find.byType(ZyraLoading), findsNothing);
  expect(
    find.descendant(of: canvas, matching: find.byType(Text)),
    findsNothing,
  );
  final decoration = tester.widget<DecoratedBox>(canvas).decoration;
  expect(decoration, isA<BoxDecoration>());
  expect((decoration as BoxDecoration).gradient, ZyraColors.brandGradient);
  expect(
    find.ancestor(of: canvas, matching: find.byType(AbsorbPointer)),
    findsWidgets,
  );
}

Future<void> _withHeldBrowsePhotos(
  WidgetTester tester,
  Future<void> Function(Completer<void> photos) body,
) async {
  final assets = <String, ByteData>{};
  await tester.runAsync(() async {
    for (final name in [
      ...ZyraOneJourneySamplePhotos.seeds.expand((group) => group),
      'seeker_self',
      'guardian_self',
    ]) {
      final key = 'assets/dev/one_journey_photos/$name.jpg';
      assets[key] = await rootBundle.load(key);
    }
  });
  final photos = Completer<void>();
  final previousGate = _heldBrowsePhotoGate;
  _heldBrowsePhotoGate = photos;
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMessageHandler('flutter/assets', (message) async {
    final name = utf8.decode(
      message!.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
    );
    if (!assets.containsKey(name)) return null;
    await photos.future;
    return assets[name];
  });
  try {
    await body(photos);
  } finally {
    if (!photos.isCompleted) photos.complete();
    messenger.setMockMessageHandler('flutter/assets', null);
    try {
      await _settle(tester);
    } finally {
      _heldBrowsePhotoGate = previousGate;
    }
  }
}

void _resume(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void _returnFromBackground(WidgetTester tester) {
  if (tester.binding.lifecycleState == AppLifecycleState.paused) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  }
  if (tester.binding.lifecycleState == AppLifecycleState.hidden) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  }
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

Future<void> _captureQuiet(
  WidgetTester tester,
  String name, {
  String? directory,
}) async {
  final targetDirectory = directory ?? _quietCaptureDirectory;
  if (targetDirectory.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_quietCaptureKey),
  );
  await tester.runAsync(() async {
    final file = File('$targetDirectory/$name.png');
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

Future<void> _settle(WidgetTester tester) async {
  // Launch crosses the real preference queue and Flutter's fake frame clock.
  // Drain both on every bounded step; a loading spinner must not turn a
  // missing destination into pumpAndSettle's ten-minute wait.
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
  }
  await _waitForLocalPhotoReadiness(tester);
}

bool _hasUnheldFreshPreparation() {
  if (_heldBrowsePhotoGate?.isCompleted == false ||
      !ZyraLocalPreviewPreparation.foreground) {
    return false;
  }
  for (final element in find.byType(ZyraOneJourneyConceptShell).evaluate()) {
    final shell = element.widget as ZyraOneJourneyConceptShell;
    if (!shell.canAct() || !(ModalRoute.of(element)?.isCurrent ?? false)) {
      continue;
    }
    final surface = element
        .findAncestorWidgetOfExactType<ZyraFounderReviewSurface>();
    if (surface == null) continue;
    final admission = ZyraPreviewResumeTransition.admissionFor(
      ownerId: surface.ownerId,
      accountGeneration: surface.ownerGeneration,
      preferenceGeneration: ZyraLocalPrefs.bindingGeneration,
    );
    // Browse can still be decoding without an inline loader. The existing
    // presentation admission proves its preparation and actual paint finished.
    if (admission == null ||
        find
            .descendant(
              of: find.byWidget(shell),
              matching: find.byType(ZyraLoading),
            )
            .evaluate()
            .isNotEmpty ||
        _key('founder_resume_continuity').evaluate().isNotEmpty ||
        _key('founder_resume_quiet_background').evaluate().isNotEmpty) {
      return true;
    }
  }
  return false;
}

Future<void> _waitForLocalPhotoReadiness(WidgetTester tester) async {
  // Native image decoding needs real event-loop turns, not more fake time.
  // Wait only for a fresh local shell; intentional held assets and pending
  // authorization must retain their exact feedback/recovery test clocks.
  for (var turn = 0; turn < 200 && _hasUnheldFreshPreparation(); turn++) {
    await tester.pump(const Duration(milliseconds: 1));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
  }
  expect(
    _hasUnheldFreshPreparation(),
    isFalse,
    reason: 'Unheld local photos and their fresh-paint cover finish boundedly',
  );
}

// This wait is used only after a test explicitly releases its photo gate
// and expects the blocked recovery/continuity surface to leave. canAct() is
// deliberately false behind that surface, so the generic fresh-shell wait
// cannot observe its pending decode. Keep the final semantic assertions.
Future<void> _waitForReleasedPhotoSurface(
  WidgetTester tester,
  String surfaceKey,
) async {
  expect(_heldBrowsePhotoGate?.isCompleted, isTrue);
  for (
    var turn = 0;
    turn < 200 && _key(surfaceKey).evaluate().isNotEmpty;
    turn++
  ) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
  }
}

Future<void> _writePreference(
  WidgetTester tester,
  Future<void> Function() write,
) async {
  var completed = false;
  Object? failure;
  StackTrace? failureStack;
  // Checkpoint writes may already be queued in FakeAsync. Start the next
  // write in the real zone without waiting there for that fake-zone tail.
  await tester.runAsync(() async {
    unawaited(
      write().then(
        (_) => completed = true,
        onError: (Object error, StackTrace stack) {
          failure = error;
          failureStack = stack;
          completed = true;
        },
      ),
    );
  });
  for (var turn = 0; turn < 40 && !completed; turn++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(completed, isTrue, reason: 'Preference write leaves both clock zones');
  if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
}

Future<void> _expectPhotosPainted(WidgetTester tester) async {
  final editor = find.byType(EditPhotosScreen);
  expect(editor, findsOneWidget);
  expect(_key('photos-title'), findsOneWidget);
  for (final element
      in find
          .descendant(of: editor, matching: find.byType(Image))
          .evaluate()
          .toList()) {
    Object? error;
    await tester.runAsync(
      () => precacheImage(
        (element.widget as Image).image,
        element,
        onError: (failure, _) => error = failure,
      ).timeout(const Duration(seconds: 5)),
    );
    expect(error, isNull);
  }
  await _settle(tester);
  final image = find.descendant(
    of: _key('photo-large-0'),
    matching: find.byType(RawImage),
  );
  expect(image, findsOneWidget);
  expect(tester.widget<RawImage>(image).image, isNotNull);
  expect(tester.widget<RawImage>(image).image!.width, greaterThan(0));
}

Future<void> _press(WidgetTester tester, String id) async {
  if (id.startsWith('dev_rail_')) {
    if (_key('dev_controls_close').evaluate().isEmpty) {
      await openZyraDevControls(tester);
    }
    id = id.replaceFirst('dev_rail_', 'dev_controls_tab_');
  }
  final target = _key(id);
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pump();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await _settle(tester);
}

Future<void> _dispose(WidgetTester tester) async {
  try {
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester);
  } finally {
    // Queue the next preference tail in the real zone, then drain the old fake
    // zone while it still exists. A later widget test cannot flush this zone.
    await tester.runAsync(() async {
      unawaited(ZyraLocalPrefs.bindAccount(null));
    });
    var drained = false;
    ZyraLocalPrefs.bindAccount(null).then((_) {
      drained = true;
    });
    for (var frame = 0; frame < 20 && !drained; frame++) {
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    expect(
      drained,
      isTrue,
      reason: 'Preference tail leaves its FakeAsync zone',
    );
    expect(ZyraConceptPreviewIsolation.active, isFalse);
    expect(tester.takeException(), isNull);
  }
}

void _enableLockscreenCleanupFrames(WidgetTester tester) {
  if (tester.binding.lifecycleState == AppLifecycleState.paused) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  }
  if (tester.binding.lifecycleState != AppLifecycleState.resumed &&
      tester.binding.lifecycleState != AppLifecycleState.inactive) {
    // inactive enables frames without dispatching another resume refresh.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  }
}

Future<void> _disposeLockscreen(WidgetTester tester) async {
  _enableLockscreenCleanupFrames(tester);
  await _dispose(tester);
  // Dispose the host and retain the real isolation assertion before resumed
  // can dispatch an unwanted second SDK refresh during fixture cleanup.
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pump();
  expect(ZyraConceptPreviewIsolation.active, isFalse);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var forwarded = 0;
  final forwardedPaths = <String>[];
  String? ordinaryRole;
  late Future<User?> Function() refresh;
  Future<http.Response> Function(http.Request)? sdkTokenResponse;
  var sdkTokenRequests = 0;

  setUpAll(() async {
    if (_quietCaptureDirectory.isNotEmpty ||
        _accessCaptureDirectory.isNotEmpty) {
      for (final directory in [
        _quietCaptureDirectory,
        _accessCaptureDirectory,
      ].where((directory) => directory.isNotEmpty)) {
        if (!directory.startsWith('/') || !Directory(directory).existsSync()) {
          throw StateError(
            'Quiet-launch captures require an existing absolute directory.',
          );
        }
      }
      final reading = FontLoader(_quietFont);
      for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
        reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await Future.wait([reading.load(), icons.load()]);
    }
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.app_links/messages'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.app_links/events'),
      (_) async => null,
    );
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: ZyraInternalFounderPolicy.approvedSupabaseUrl,
      publishableKey: 'synthetic-launch-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: ZyraInternalPreviewClient(
        MockClient((request) async {
          final sdkResponse = sdkTokenResponse;
          if (request.url.path == '/auth/v1/token' && sdkResponse != null) {
            sdkTokenRequests++;
            return sdkResponse(request);
          }
          forwarded++;
          forwardedPaths.add(request.url.path);
          Object? value = <Object?>[];
          var status = 200;
          if (ordinaryRole == null) {
            status = 403;
            value = {
              'code': 'SYNTHETIC_DENIAL',
              'message': 'No fixture enabled',
            };
          } else if (request.url.path == '/rest/v1/profiles') {
            value = [
              {
                'role': ordinaryRole,
                'first_name': 'Ordinary member',
                'surname_line': 'Synthetic surname',
                'gender': 'male',
                'location_text': 'Synthetic city',
              },
            ];
          } else if (request.url.path == '/rest/v1/rpc/ages_for_one') {
            value = 30;
          }
          return http.Response(
            jsonEncode(value),
            status,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  setUp(() async {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraAccountState.endSignOutAttempt();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    SharedPreferences.setMockInitialValues({'ordinary-setting': 'preserved'});
    await ZyraLocalPrefs.init();
    await _session(_founder, founderClaim: true);
    await ZyraAccountState.synchronize(_founder);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily =
        _quietCaptureDirectory.isEmpty && _accessCaptureDirectory.isEmpty
        ? null
        : _quietFont;
    ZyraAppGoldRenderer.instance.resetForTesting();
    refresh = () async => supabase.auth.currentUser;
    ZyraDeveloperAccess.configureAuthorizationForTesting(
      variant: ZyraAppVariant.production,
      currentUser: () => supabase.auth.currentUser,
      refreshSession: () => refresh(),
      founderIdentityMatches: _matchesFreshFounder,
    );
    // Enables only the compile-time preview presentation in this fixture.
    // Fresh pinned identity + app_metadata still decide developer authority.
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ordinaryRole = null;
    forwarded = 0;
    forwardedPaths.clear();
    sdkTokenResponse = null;
    sdkTokenRequests = 0;
  });

  tearDown(() {
    ZyraAppLock.instance.clearForSignOut();
    ZyraPreviewResumeTransition.end(ZyraPreviewResumeTransition.changes.value);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  Future<void> mount(
    WidgetTester tester,
    Widget home, {
    bool settle = true,
    bool disableAnimations = true,
    Size viewport = const Size(390, 844),
    double textScale = 1,
    Future<bool> Function()? resumeRefresh,
    Stream<AuthState>? authStates = const Stream<AuthState>.empty(),
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final navigator = GlobalKey<NavigatorState>();
    final routes = ZyraPreviewRouteObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [routes],
        theme: ThemeData.dark(),
        builder: (context, child) => ZyraAccountSessionHost(
          navigatorKey: navigator,
          authStateChangesOverride: authStates,
          resumeAuthorizationRefreshOverride:
              resumeRefresh ??
              () => ZyraDeveloperAccess.refreshCurrentAuthorization(),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: disableAnimations,
              textScaler: TextScaler.linear(textScale),
            ),
            child: RepaintBoundary(key: _quietCaptureKey, child: child!),
          ),
        ),
        home: home,
      ),
    );
    if (settle) await _settle(tester);
  }

  Future<void> launch(WidgetTester tester) async {
    final destination = await tester.runAsync(ZyraSessionRouter.resolveHome);
    expect(destination, isA<ZyraFounderLaunchScreen>());
    await mount(tester, destination!);
  }

  Future<Map<String, Object?>> preferenceSnapshot(WidgetTester tester) async {
    final preferences = await tester.runAsync(SharedPreferences.getInstance);
    return {
      for (final key in preferences!.getKeys()) key: preferences.get(key),
    };
  }

  Future<VoidCallback> openPhotos(WidgetTester tester) async {
    tester.widget<FloatingNavBar>(find.byType(FloatingNavBar)).onTap(4);
    await _settle(tester);
    final manage = find.text('Manage photos');
    expect(manage, findsOneWidget);
    await tester.ensureVisible(manage);
    await tester.pump();
    await tester.tap(manage);
    await _settle(tester);
    await _expectPhotosPainted(tester);
    return tester.widget<IconButton>(_key('photos-compact-toggle')).onPressed!;
  }

  Future<_LockscreenOpening> openLockscreenPhotos(
    WidgetTester tester, {
    bool sdkStream = false,
    Stream<AuthState>? authStates = const Stream<AuthState>.empty(),
    Duration refreshTimeout = const Duration(seconds: 10),
  }) async {
    ZyraAppLock.instance.clearForSignOut();
    ZyraDeveloperAccess.configureAuthorizationForTesting(
      variant: ZyraAppVariant.production,
      currentUser: () => supabase.auth.currentUser,
      refreshSession: () => refresh(),
      founderIdentityMatches: _matchesFreshFounder,
      refreshTimeout: refreshTimeout,
    );
    await tester.runAsync(ZyraDeveloperAccess.refreshCurrentAuthorization);
    ZyraInternalPreviewClient.beginPreview();
    await mount(
      tester,
      ZyraFounderReviewSurface(
        ownerId: _founder,
        ownerGeneration: ZyraAccountState.generation,
      ),
      // null is the genuine SDK subscription/currentUser production branch.
      // Drain its initialSession replay before arming the held refresh below.
      authStates: sdkStream ? null : authStates,
    );
    final toggle = await openPhotos(tester);
    expect(ZyraAppLock.instance.enabled, isFalse);
    expect(ZyraAppLock.instance.isLocked, isFalse);
    expect(ZyraAppLock.instance.isObscured, isFalse);
    expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
    expect(forwarded, 0);
    final preferences = await preferenceSnapshot(tester);
    return _LockscreenOpening(
      shell: tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      ),
      editor: tester.state<State<EditPhotosScreen>>(
        find.byType(EditPhotosScreen),
      ),
      toggle: toggle,
      preferences: preferences,
      memberPhotos: List<String>.of(AppState.instance.photos),
    );
  }

  void denyOldLockscreenActions(_LockscreenOpening old) {
    expect(old.shell.canAct(), isFalse);
    old.toggle();
    old.shell.onPresentationReady?.call();
    old.shell.onRoleChanged?.call(true);
  }

  Future<void> expectFreshLockscreenPhotos(
    WidgetTester tester,
    _LockscreenOpening old,
  ) async {
    await _expectPhotosPainted(tester);
    _expectNoLockscreenLoading(tester);
    expect(_key('founder_resume_continuity'), findsNothing);
    expect(_key('founder_resume_quiet_background'), findsNothing);
    expect(_key('founder_resume_status'), findsNothing);
    expect(_key('founder_resume_recovery'), findsNothing);
    expect(old.editor.mounted, isFalse);
    expect(
      tester.state(find.byType(EditPhotosScreen)),
      isNot(same(old.editor)),
    );
    final fresh = tester.widget<ZyraOneJourneyConceptShell>(
      find.byType(ZyraOneJourneyConceptShell),
    );
    expect(fresh, isNot(same(old.shell)));
    expect(fresh.canAct(), isTrue);
    denyOldLockscreenActions(old);
    await tester.pump();
    expect(_key('photos-title'), findsOneWidget);
    expect(_key('photos-compact-view'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == 'DeveloperAccessScreen',
      ),
      findsNothing,
    );
    expect(AppState.instance.photos, old.memberPhotos);
    expect(forwarded, 0);
  }

  void neverAuthorizesTransition(VoidCallback exercise) {
    ZyraPreviewResumeTransition.cancel();
    expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
    final accountGeneration = ZyraAccountState.generation;
    final preferenceGeneration = ZyraLocalPrefs.bindingGeneration;
    var everAuthorized = false;
    void observe() {
      everAuthorized =
          everAuthorized || ZyraDeveloperAccess.canUseDeveloperTools;
    }

    ZyraDeveloperAccess.authorizationChanges.addListener(observe);
    try {
      exercise();
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      expect(everAuthorized, isFalse);
      expect(ZyraAccountState.generation, accountGeneration);
      expect(ZyraLocalPrefs.bindingGeneration, preferenceGeneration);
      expect(forwarded, 0);
    } finally {
      ZyraPreviewResumeTransition.cancel();
      ZyraDeveloperAccess.authorizationChanges.removeListener(observe);
    }
  }

  test(
    'lockscreen transition joins participants and releases idempotently',
    () {
      neverAuthorizesTransition(() {
        final owner = Object();
        var notifications = 0;
        void changed() => notifications++;
        ZyraPreviewResumeTransition.changes.addListener(changed);
        try {
          final first = ZyraPreviewResumeTransition.acquire(
            ownerId: _founder,
            accountGeneration: 1,
            preferenceGeneration: 2,
            presentationOwner: owner,
          );
          final second = ZyraPreviewResumeTransition.acquire(
            ownerId: _founder,
            accountGeneration: 1,
            preferenceGeneration: 2,
            presentationOwner: owner,
          );
          expect(second.ticket, same(first.ticket));
          expect(notifications, 1);
          ZyraPreviewResumeTransition.release(first);
          ZyraPreviewResumeTransition.release(first);
          expect(
            ZyraPreviewResumeTransition.changes.value,
            same(second.ticket),
          );
          expect(notifications, 1);
          ZyraPreviewResumeTransition.release(second);
          ZyraPreviewResumeTransition.release(second);
          expect(ZyraPreviewResumeTransition.changes.value, isNull);
          expect(notifications, 2);
        } finally {
          ZyraPreviewResumeTransition.changes.removeListener(changed);
        }
      });
    },
  );

  test('lockscreen transition cancellation makes old handles inert', () {
    neverAuthorizesTransition(() {
      final owner = Object();
      final old = ZyraPreviewResumeTransition.acquire(
        ownerId: _founder,
        accountGeneration: 1,
        preferenceGeneration: 2,
        presentationOwner: owner,
      );
      ZyraPreviewResumeTransition.cancel();
      expect(ZyraPreviewResumeTransition.changes.value, isNull);
      final fresh = ZyraPreviewResumeTransition.acquire(
        ownerId: _founder,
        accountGeneration: 1,
        preferenceGeneration: 2,
        presentationOwner: owner,
      );
      expect(fresh.ticket, isNot(same(old.ticket)));
      ZyraPreviewResumeTransition.release(old);
      ZyraPreviewResumeTransition.end(old.ticket);
      expect(ZyraPreviewResumeTransition.changes.value, same(fresh.ticket));
      ZyraPreviewResumeTransition.release(fresh);
      expect(ZyraPreviewResumeTransition.changes.value, isNull);
    });
  });

  test(
    'lockscreen transition admission failure is terminal and stale revoke is inert',
    () {
      neverAuthorizesTransition(() {
        var current = true;
        final owner = Object();
        final old = ZyraPreviewResumeTransition.admit(
          presentationOwner: owner,
          ownerId: _founder,
          accountGeneration: 1,
          preferenceGeneration: 2,
          isCurrent: () => current,
        );
        expect(old.isCurrent, isTrue);
        current = false;
        expect(old.isCurrent, isFalse);
        current = true;
        expect(old.isCurrent, isFalse);
        expect(
          ZyraPreviewResumeTransition.admissionFor(
            ownerId: _founder,
            accountGeneration: 1,
            preferenceGeneration: 2,
          ),
          isNull,
        );
        final fresh = ZyraPreviewResumeTransition.admit(
          presentationOwner: owner,
          ownerId: _founder,
          accountGeneration: 1,
          preferenceGeneration: 2,
          isCurrent: () => current,
        );
        ZyraPreviewResumeTransition.revokeAdmission(old);
        expect(fresh.isCurrent, isTrue);
        expect(
          ZyraPreviewResumeTransition.admissionFor(
            ownerId: _founder,
            accountGeneration: 1,
            preferenceGeneration: 2,
          ),
          same(fresh),
        );
        ZyraPreviewResumeTransition.cancel();
        expect(fresh.isCurrent, isFalse);
      });
    },
  );

  test('lockscreen transition refuses owner and lifetime mismatches', () {
    neverAuthorizesTransition(() {
      final owner = Object();
      var throws = false;
      final admission = ZyraPreviewResumeTransition.admit(
        presentationOwner: owner,
        ownerId: _founder,
        accountGeneration: 1,
        preferenceGeneration: 2,
        isCurrent: () {
          if (throws) throw StateError('Synthetic withdrawn presentation');
          return true;
        },
      );
      for (final identity in [
        (owner: _member, account: 1, preferences: 2),
        (owner: _founder, account: 3, preferences: 2),
        (owner: _founder, account: 1, preferences: 3),
      ]) {
        expect(
          ZyraPreviewResumeTransition.admissionFor(
            ownerId: identity.owner,
            accountGeneration: identity.account,
            preferenceGeneration: identity.preferences,
          ),
          isNull,
        );
      }
      expect(admission.isCurrent, isTrue);
      var previous = ZyraPreviewResumeTransition.acquire(
        ownerId: _founder,
        accountGeneration: 1,
        preferenceGeneration: 2,
        presentationOwner: owner,
      );
      for (final identity in [
        (owner: _member, account: 1, preferences: 2, presentation: owner),
        (owner: _founder, account: 3, preferences: 2, presentation: owner),
        (owner: _founder, account: 3, preferences: 4, presentation: owner),
        (owner: _founder, account: 3, preferences: 4, presentation: Object()),
      ]) {
        final fresh = ZyraPreviewResumeTransition.acquire(
          ownerId: identity.owner,
          accountGeneration: identity.account,
          preferenceGeneration: identity.preferences,
          presentationOwner: identity.presentation,
        );
        expect(fresh.ticket, isNot(same(previous.ticket)));
        ZyraPreviewResumeTransition.release(previous);
        expect(ZyraPreviewResumeTransition.changes.value, same(fresh.ticket));
        previous = fresh;
      }
      throws = true;
      expect(admission.isCurrent, isFalse);
      throws = false;
      expect(admission.isCurrent, isFalse);
      ZyraPreviewResumeTransition.release(previous);
      expect(ZyraPreviewResumeTransition.changes.value, isNull);
    });
  });

  test(
    'lockscreen transition legacy begin remains held until its exact end',
    () {
      neverAuthorizesTransition(() {
        final legacy = ZyraPreviewResumeTransition.begin(
          ownerId: _founder,
          accountGeneration: 1,
          preferenceGeneration: 2,
        );
        final participant = ZyraPreviewResumeTransition.acquire(
          ownerId: _founder,
          accountGeneration: 1,
          preferenceGeneration: 2,
        );
        expect(participant.ticket, same(legacy));
        ZyraPreviewResumeTransition.release(participant);
        expect(ZyraPreviewResumeTransition.changes.value, same(legacy));
        final fresh = ZyraPreviewResumeTransition.begin(
          ownerId: _founder,
          accountGeneration: 1,
          preferenceGeneration: 2,
        );
        ZyraPreviewResumeTransition.end(legacy);
        ZyraPreviewResumeTransition.release(participant);
        expect(ZyraPreviewResumeTransition.changes.value, same(fresh));
        ZyraPreviewResumeTransition.end(fresh);
        ZyraPreviewResumeTransition.end(fresh);
        expect(ZyraPreviewResumeTransition.changes.value, isNull);
      });
    },
  );

  testWidgets(
    'runtime inactive proof withdrawal paints neutral before background',
    (tester) async {
      final old = await openLockscreenPhotos(tester);
      final surface = tester.state(find.byType(ZyraFounderReviewSurface));
      final user = supabase.auth.currentUser;
      final accountGeneration = ZyraAccountState.generation;
      final preferenceGeneration = ZyraLocalPrefs.bindingGeneration;
      final admission = ZyraPreviewResumeTransition.admissionFor(
        ownerId: _founder,
        accountGeneration: accountGeneration,
        preferenceGeneration: preferenceGeneration,
      );
      expect(admission, isNotNull);
      final pending = Completer<User?>();
      var calls = 0;
      refresh = () {
        calls++;
        return pending.future;
      };
      try {
        // Unlike a fully paused scene, inactive still permits a real frame.
        // Withdraw proof before hidden/paused can suspend that painted frame.
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
        expect(tester.binding.framesEnabled, isTrue);
        unawaited(ZyraDeveloperAccess.refreshCurrentAuthorization());
        await _waitForLockscreenBarrier(
          tester,
          () => calls == 1,
          'The proof flight starts during frame-enabled inactive.',
        );
        await tester.pump();
        expect(tester.binding.lifecycleState, AppLifecycleState.inactive);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(ZyraPreviewResumeTransition.changes.value, isNull);
        expect(admission!.isCurrent, isTrue);
        expect(old.editor.mounted, isFalse);
        denyOldLockscreenActions(old);
        expect(
          tester.state(find.byType(ZyraFounderReviewSurface)),
          same(surface),
        );
        expect(ZyraAccountState.userId, _founder);
        expect(ZyraAccountState.generation, accountGeneration);
        expect(ZyraLocalPrefs.bindingGeneration, preferenceGeneration);
        expect(ZyraAppLock.instance.enabled, isFalse);
        expect(ZyraInternalPreviewClient.isActive, isTrue);
        expect(ZyraConceptPreviewIsolation.active, isTrue);
        expect(await preferenceSnapshot(tester), old.preferences);
        expect(AppState.instance.photos, old.memberPhotos);
        expect(forwarded, 0);
        // Preserve the painted inactive source before the intended RED.
        await _captureQuiet(tester, 'runtime-inactive-first-frame');
        _expectLockscreenCover(tester);
        expect(_key('founder_resume_continuity'), findsNothing);

        for (final state in [
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
          await tester.pump();
        }
        _returnFromBackground(tester);
        await tester.pump();
        _expectLockscreenCover(tester);
        expect(calls, 1, reason: 'Resume joins the existing inactive flight.');
        denyOldLockscreenActions(old);
        pending.complete(user);
        await _settle(tester);
        await expectFreshLockscreenPhotos(tester, old);
        expect(calls, 1);
        expect(await preferenceSnapshot(tester), old.preferences);
        expect(AppState.instance.photos, old.memberPhotos);
        expect(forwarded, 0);
      } finally {
        if (!pending.isCompleted) pending.complete(user);
        _enableLockscreenCleanupFrames(tester);
        await _settle(tester);
        await _disposeLockscreen(tester);
      }
    },
  );

  testWidgets(
    'runtime redeparture before covered-return preparation is ready stays neutral',
    (tester) async {
      final old = await openLockscreenPhotos(tester);
      final surface = tester.state(find.byType(ZyraFounderReviewSurface));
      final user = supabase.auth.currentUser;
      final accountGeneration = ZyraAccountState.generation;
      final preferenceGeneration = ZyraLocalPrefs.bindingGeneration;
      final firstPending = Completer<User?>();
      final secondPending = Completer<User?>();
      var calls = 0;
      NavigatorState? navigator;
      var covered = false;
      refresh = () {
        calls++;
        return firstPending.future;
      };
      try {
        await _withHeldBrowsePhotos(tester, (photos) async {
          await _pauseForLockscreen(tester);
          unawaited(ZyraDeveloperAccess.refreshCurrentAuthorization());
          await _waitForLockscreenBarrier(
            tester,
            () => calls == 1,
            'The first proof flight starts while paused.',
          );
          _returnFromBackground(tester);
          await tester.pump();
          _expectLockscreenCover(tester);
          denyOldLockscreenActions(old);

          final active = Navigator.of(
            tester.element(find.byType(ZyraFounderReviewSurface)),
          );
          navigator = active;
          unawaited(
            active.push<void>(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const Scaffold(body: Text('Re-departure covering route')),
              ),
            ),
          );
          covered = true;
          await _settle(tester);
          expect(find.text('Re-departure covering route'), findsOneWidget);
          firstPending.complete(user);
          await _settle(tester);
          expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
          expect(ZyraPreviewResumeTransition.changes.value, isNull);
          expect(
            find.byType(ZyraOneJourneyConceptShell, skipOffstage: false),
            findsNothing,
          );
          active.pop();
          covered = false;
          await tester.pump();
          _expectLockscreenCover(tester, proofPending: false);
          expect(_key('founder_resume_quiet_background'), findsOneWidget);
          expect(_key('founder_resume_continuity'), findsNothing);
          final preparing = tester.widget<ZyraOneJourneyConceptShell>(
            find.byType(ZyraOneJourneyConceptShell),
          );
          expect(preparing.canAct(), isTrue);
          expect(ZyraPreviewResumeTransition.changes.value, isNull);
          expect(
            ZyraPreviewResumeTransition.admissionFor(
              ownerId: _founder,
              accountGeneration: accountGeneration,
              preferenceGeneration: preferenceGeneration,
            ),
            isNull,
            reason:
                'Held local photos have not earned a new painted admission.',
          );
          expect(calls, 1, reason: 'Popping the cover starts local work only.');
          expect(photos.isCompleted, isFalse);
          denyOldLockscreenActions(old);

          refresh = () {
            calls++;
            return secondPending.future;
          };
          await _pauseForLockscreen(tester);
          unawaited(ZyraDeveloperAccess.refreshCurrentAuthorization());
          await _waitForLockscreenBarrier(
            tester,
            () => calls == 2,
            'A second proof flight starts before covered-return photos finish.',
          );
          expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
          expect(preparing.canAct(), isFalse);
          preparing.onPresentationReady?.call();
          preparing.onRoleChanged?.call(true);
          _returnFromBackground(tester);
          await tester.pump();
          expect(
            tester.state(find.byType(ZyraFounderReviewSurface)),
            same(surface),
          );
          expect(ZyraAccountState.userId, _founder);
          expect(ZyraAccountState.generation, accountGeneration);
          expect(ZyraLocalPrefs.bindingGeneration, preferenceGeneration);
          expect(ZyraAppLock.instance.enabled, isFalse);
          expect(ZyraInternalPreviewClient.isActive, isTrue);
          expect(ZyraConceptPreviewIsolation.active, isTrue);
          expect(calls, 2, reason: 'Resume must join the second proof flight.');
          expect(photos.isCompleted, isFalse);
          denyOldLockscreenActions(old);
          expect(await preferenceSnapshot(tester), old.preferences);
          expect(AppState.instance.photos, old.memberPhotos);
          expect(forwarded, 0);
          // Preserve the first resumed frame before the intended RED.
          await _captureQuiet(tester, 'runtime-redeparture-first-frame');
          _expectLockscreenCover(tester);
          expect(_key('founder_resume_continuity'), findsNothing);

          secondPending.complete(user);
          await _settle(tester);
          expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
          _expectLockscreenCover(tester, proofPending: false);
          preparing.onPresentationReady?.call();
          await tester.pump();
          _expectLockscreenCover(tester, proofPending: false);
          expect(photos.isCompleted, isFalse);
          photos.complete();
          await _settle(tester);
          _expectNoLockscreenLoading(tester);
          expect(_key('founder_resume_continuity'), findsNothing);
          expect(_key('founder_resume_quiet_background'), findsNothing);
          expect(_key('founder_resume_status'), findsNothing);
          expect(_key('founder_resume_recovery'), findsNothing);
          final fresh = tester.widget<ZyraOneJourneyConceptShell>(
            find.byType(ZyraOneJourneyConceptShell),
          );
          expect(fresh, isNot(same(old.shell)));
          expect(fresh, isNot(same(preparing)));
          expect(fresh.canAct(), isTrue);
          final admission = ZyraPreviewResumeTransition.admissionFor(
            ownerId: _founder,
            accountGeneration: accountGeneration,
            preferenceGeneration: preferenceGeneration,
          );
          expect(admission, isNotNull);
          expect(admission!.isCurrent, isTrue);
          denyOldLockscreenActions(old);
          expect(old.editor.mounted, isFalse);
          expect(
            find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == 'DeveloperAccessScreen',
            ),
            findsNothing,
          );
          expect(find.byType(HomeShell), findsNothing);
          expect(find.byType(WaliHomeShell), findsNothing);
          expect(calls, 2);
          expect(await preferenceSnapshot(tester), old.preferences);
          expect(AppState.instance.photos, old.memberPhotos);
          expect(forwarded, 0);
        });
      } finally {
        if (!firstPending.isCompleted) firstPending.complete(user);
        if (!secondPending.isCompleted) secondPending.complete(user);
        _enableLockscreenCleanupFrames(tester);
        final active = navigator;
        if (covered && active != null && active.mounted && active.canPop()) {
          active.pop();
        }
        await _settle(tester);
        await _disposeLockscreen(tester);
      }
    },
  );

  testWidgets(
    'lockscreen handoff route cover pop renews admission before paused proof loss',
    (tester) async {
      final original = await openLockscreenPhotos(tester);
      final first = ZyraPreviewResumeTransition.admissionFor(
        ownerId: _founder,
        accountGeneration: ZyraAccountState.generation,
        preferenceGeneration: ZyraLocalPrefs.bindingGeneration,
      );
      expect(first, isNotNull);
      final pending = Completer<User?>();
      final user = supabase.auth.currentUser;
      NavigatorState? navigator;
      var covered = false;
      var calls = 0;
      try {
        final active = Navigator.of(
          tester.element(find.byType(ZyraFounderReviewSurface)),
        );
        navigator = active;
        unawaited(
          active.push<void>(
            MaterialPageRoute(
              builder: (_) =>
                  const Scaffold(body: Text('Renewal covering route')),
            ),
          ),
        );
        covered = true;
        await _settle(tester);
        expect(find.text('Renewal covering route'), findsOneWidget);
        expect(first!.isCurrent, isFalse);
        active.pop();
        covered = false;
        await _settle(tester);
        await _expectPhotosPainted(tester);
        _expectNoLockscreenLoading(tester);
        final renewed = ZyraPreviewResumeTransition.admissionFor(
          ownerId: _founder,
          accountGeneration: ZyraAccountState.generation,
          preferenceGeneration: ZyraLocalPrefs.bindingGeneration,
        );
        expect(renewed, isNotNull);
        expect(renewed, isNot(same(first)));
        expect(first.isCurrent, isFalse);
        expect(renewed!.isCurrent, isTrue);
        final old = _LockscreenOpening(
          shell: tester.widget<ZyraOneJourneyConceptShell>(
            find.byType(ZyraOneJourneyConceptShell),
          ),
          editor: tester.state<State<EditPhotosScreen>>(
            find.byType(EditPhotosScreen),
          ),
          toggle: tester
              .widget<IconButton>(_key('photos-compact-toggle'))
              .onPressed!,
          preferences: await preferenceSnapshot(tester),
          memberPhotos: List<String>.of(AppState.instance.photos),
        );
        refresh = () {
          calls++;
          return pending.future;
        };
        await _pauseForLockscreen(tester);
        unawaited(ZyraDeveloperAccess.refreshCurrentAuthorization());
        await _waitForLockscreenBarrier(
          tester,
          () => calls == 1,
          'Paused refreshed admission',
        );
        _returnFromBackground(tester);
        await tester.pump();
        _expectLockscreenCover(tester);
        denyOldLockscreenActions(old);
        pending.complete(user);
        await _settle(tester);
        await expectFreshLockscreenPhotos(tester, old);
        expect(first.isCurrent, isFalse);
        expect(calls, 1);
        expect(await preferenceSnapshot(tester), original.preferences);
        expect(forwarded, 0);
      } finally {
        if (!pending.isCompleted) pending.complete(user);
        _enableLockscreenCleanupFrames(tester);
        await _settle(tester);
        final active = navigator;
        if (covered && active != null && active.mounted && active.canPop()) {
          active.pop();
        }
        await _disposeLockscreen(tester);
      }
    },
  );

  testWidgets(
    'lockscreen handoff proof completed while covered prepares locally behind neutral return cover',
    (tester) async {
      final old = await openLockscreenPhotos(tester);
      final user = supabase.auth.currentUser;
      final pending = Completer<User?>();
      var calls = 0;
      NavigatorState? navigator;
      var covered = false;
      refresh = () {
        calls++;
        return pending.future;
      };
      try {
        await _withHeldBrowsePhotos(tester, (photos) async {
          await _pauseForLockscreen(tester);
          unawaited(ZyraDeveloperAccess.refreshCurrentAuthorization());
          await _waitForLockscreenBarrier(
            tester,
            () => calls == 1,
            'The paused proof flight starts before the route is covered.',
          );
          _returnFromBackground(tester);
          await tester.pump();
          _expectLockscreenCover(tester);
          expect(old.editor.mounted, isFalse);
          denyOldLockscreenActions(old);

          final active = Navigator.of(
            tester.element(find.byType(ZyraFounderReviewSurface)),
          );
          navigator = active;
          unawaited(
            active.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(
                  body: Text('Proof-completion covering route'),
                ),
              ),
            ),
          );
          covered = true;
          await _settle(tester);
          expect(find.text('Proof-completion covering route'), findsOneWidget);
          expect(calls, 1);
          pending.complete(user);
          await _settle(tester);
          expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
          expect(find.text('Proof-completion covering route'), findsOneWidget);
          expect(
            find.byType(ZyraOneJourneyConceptShell, skipOffstage: false),
            findsNothing,
            reason: 'A new unready photo owner must not start while covered.',
          );
          expect(
            find.byType(EditPhotosScreen, skipOffstage: false),
            findsNothing,
          );
          expect(
            ZyraPreviewResumeTransition.admissionFor(
              ownerId: _founder,
              accountGeneration: ZyraAccountState.generation,
              preferenceGeneration: ZyraLocalPrefs.bindingGeneration,
            ),
            isNull,
          );
          denyOldLockscreenActions(old);
          expect(calls, 1);
          expect(await preferenceSnapshot(tester), old.preferences);
          expect(AppState.instance.photos, old.memberPhotos);
          expect(forwarded, 0);

          active.pop();
          covered = false;
          await tester.pump();
          _expectLockscreenCover(tester, proofPending: false);
          expect(_key('founder_resume_quiet_background'), findsOneWidget);
          expect(_key('founder_resume_continuity'), findsNothing);
          expect(_key('founder_resume_status'), findsNothing);
          expect(calls, 1, reason: 'Returning prepares locally, not via Auth.');
          denyOldLockscreenActions(old);
          await tester.pump(const Duration(milliseconds: 799));
          _expectLockscreenCover(tester, proofPending: false);
          expect(_key('founder_resume_status'), findsNothing);
          await tester.pump(const Duration(milliseconds: 1));
          _expectLockscreenCover(tester, proofPending: false);
          expect(_key('founder_resume_status'), findsOneWidget);
          expect(_key('founder_resume_recovery'), findsNothing);
          expect(calls, 1);

          photos.complete();
          await _settle(tester);
          _expectNoLockscreenLoading(tester);
          expect(_key('founder_resume_continuity'), findsNothing);
          expect(_key('founder_resume_quiet_background'), findsNothing);
          expect(_key('founder_resume_status'), findsNothing);
          expect(_key('founder_resume_recovery'), findsNothing);
          final fresh = tester.widget<ZyraOneJourneyConceptShell>(
            find.byType(ZyraOneJourneyConceptShell),
          );
          expect(fresh, isNot(same(old.shell)));
          expect(fresh.canAct(), isTrue);
          final surface = tester.widget<ZyraFounderReviewSurface>(
            find.byType(ZyraFounderReviewSurface),
          );
          final admission = ZyraPreviewResumeTransition.admissionFor(
            ownerId: surface.ownerId,
            accountGeneration: surface.ownerGeneration,
            preferenceGeneration: ZyraLocalPrefs.bindingGeneration,
          );
          expect(admission, isNotNull);
          expect(admission!.isCurrent, isTrue);
          denyOldLockscreenActions(old);
          await tester.pump();
          _expectNoLockscreenLoading(tester);
          expect(_key('founder_resume_continuity'), findsNothing);
          expect(_key('founder_resume_quiet_background'), findsNothing);
          expect(old.editor.mounted, isFalse);
          expect(
            find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == 'DeveloperAccessScreen',
            ),
            findsNothing,
          );
          expect(calls, 1);
          expect(await preferenceSnapshot(tester), old.preferences);
          expect(AppState.instance.photos, old.memberPhotos);
          expect(forwarded, 0);
        });
      } finally {
        if (!pending.isCompleted) pending.complete(user);
        _enableLockscreenCleanupFrames(tester);
        final active = navigator;
        if (covered && active != null && active.mounted && active.canPop()) {
          active.pop();
        }
        await _disposeLockscreen(tester);
      }
    },
  );

  testWidgets(
    'lockscreen handoff paused auth stream error withdraws admission and old actions',
    (tester) async {
      final states = StreamController<AuthState>();
      final old = await openLockscreenPhotos(tester, authStates: states.stream);
      final admission = ZyraPreviewResumeTransition.admissionFor(
        ownerId: _founder,
        accountGeneration: ZyraAccountState.generation,
        preferenceGeneration: ZyraLocalPrefs.bindingGeneration,
      );
      expect(admission, isNotNull);
      final pending = Completer<User?>();
      var calls = 0;
      refresh = () {
        calls++;
        return pending.future;
      };
      try {
        await _pauseForLockscreen(tester);
        unawaited(ZyraDeveloperAccess.refreshCurrentAuthorization());
        await _waitForLockscreenBarrier(
          tester,
          () => calls == 1,
          'Paused refresh before stream error',
        );
        states.addError(StateError('Synthetic paused SDK stream failure'));
        await tester.pump();
        expect(admission!.isCurrent, isFalse);
        expect(ZyraPreviewResumeTransition.changes.value, isNull);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        denyOldLockscreenActions(old);
        _returnFromBackground(tester);
        await tester.pump();
        pending.complete(null);
        await _settle(tester);
        expect(_key('founder_resume_continuity'), findsNothing);
        expect(_key('founder_resume_quiet_background'), findsNothing);
        expect(_key('founder_resume_recovery'), findsNothing);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(find.byType(ZyraFounderReviewSurface), findsNothing);
        expect(find.byType(EditPhotosScreen), findsNothing);
        denyOldLockscreenActions(old);
        await tester.pump();
        expect(find.byType(HomeShell), findsNothing);
        expect(find.byType(WaliHomeShell), findsNothing);
        expect(await preferenceSnapshot(tester), old.preferences);
        expect(forwarded, 0);
      } finally {
        if (!pending.isCompleted) pending.complete(null);
        _enableLockscreenCleanupFrames(tester);
        await _settle(tester);
        unawaited(states.close());
        await _disposeLockscreen(tester);
      }
    },
  );

  testWidgets(
    'lockscreen handoff paused proof withdrawal restores Photos only after fresh paint',
    (tester) async {
      final old = await openLockscreenPhotos(tester);
      final user = supabase.auth.currentUser;
      final accountGeneration = ZyraAccountState.generation;
      final preferenceGeneration = ZyraLocalPrefs.bindingGeneration;
      final pending = Completer<User?>();
      final secondPending = Completer<User?>();
      var calls = 0;
      refresh = () {
        calls++;
        return pending.future;
      };
      try {
        await _withHeldBrowsePhotos(tester, (photos) async {
          await _pauseForLockscreen(tester);
          unawaited(ZyraDeveloperAccess.refreshCurrentAuthorization());
          await _waitForLockscreenBarrier(
            tester,
            () => calls == 1,
            'The same-owner proof refresh really starts while paused.',
          );
          expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
          // Paused frames may retain a mounted editor, but never its actions.
          expect(old.shell.canAct(), isFalse);
          expect(_key('founder_resume_continuity'), findsNothing);
          denyOldLockscreenActions(old);
          _returnFromBackground(tester);
          await tester.pump();
          // Preserve genuine RED evidence before the old Golden branch fails.
          await _captureQuiet(tester, 'lockscreen-configured-first-resumed');
          expect(old.editor.mounted, isFalse);
          _expectLockscreenCover(tester);
          expect(calls, 1);
          expect(ZyraAccountState.generation, accountGeneration);
          expect(ZyraLocalPrefs.bindingGeneration, preferenceGeneration);
          expect(ZyraAccountState.userId, _founder);
          denyOldLockscreenActions(old);
          await tester.pump(const Duration(milliseconds: 500));
          _expectLockscreenCover(tester);
          expect(_key('founder_resume_status'), findsNothing);
          expect(await preferenceSnapshot(tester), old.preferences);
          expect(forwarded, 0);

          pending.complete(user);
          await _settle(tester);
          expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
          _expectLockscreenCover(tester, proofPending: false);
          final fresh = tester.widget<ZyraOneJourneyConceptShell>(
            find.byType(ZyraOneJourneyConceptShell),
          );
          expect(fresh, isNot(same(old.shell)));
          denyOldLockscreenActions(old);
          await tester.pump();
          _expectLockscreenCover(tester, proofPending: false);
          await _captureQuiet(tester, 'lockscreen-configured-awaiting-photos');
          // This fresh epoch is authorized but not presented: its inline
          // preparation must never become the raster for another handoff.
          expect(_key('founder_resume_continuity'), findsNothing);
          expect(_key('founder_resume_quiet_background'), findsOneWidget);
          expect(_key('founder_resume_status'), findsOneWidget);
          refresh = () {
            calls++;
            return secondPending.future;
          };
          await _pauseForLockscreen(tester);
          unawaited(ZyraDeveloperAccess.refreshCurrentAuthorization());
          await _waitForLockscreenBarrier(
            tester,
            () => calls == 2,
            'Unpresented epoch handoff',
          );
          _returnFromBackground(tester);
          await tester.pump();
          _expectLockscreenCover(tester);
          expect(_key('founder_resume_continuity'), findsNothing);
          expect(_key('founder_resume_quiet_background'), findsOneWidget);
          // The first flight finished before this genuine new departure.
          // Its replacement gets a fresh foreground feedback window, unlike
          // duplicate resumes that merely join the same unfinished ticket.
          expect(_key('founder_resume_status'), findsNothing);
          expect(fresh.canAct(), isFalse);
          fresh.onPresentationReady?.call();
          await tester.pump(const Duration(milliseconds: 799));
          _expectLockscreenCover(tester);
          expect(_key('founder_resume_continuity'), findsNothing);
          expect(_key('founder_resume_status'), findsNothing);
          await tester.pump(const Duration(milliseconds: 1));
          _expectLockscreenCover(tester);
          expect(_key('founder_resume_continuity'), findsNothing);
          expect(_key('founder_resume_status'), findsOneWidget);
          expect(calls, 2);
          secondPending.complete(user);
          await _settle(tester);
          _expectLockscreenCover(tester, proofPending: false);
          fresh.onPresentationReady?.call();
          await tester.pump();
          _expectLockscreenCover(tester, proofPending: false);
          expect(_key('founder_resume_continuity'), findsNothing);
          photos.complete();
          await _settle(tester);
          await expectFreshLockscreenPhotos(tester, old);
          expect(await preferenceSnapshot(tester), old.preferences);
          expect(calls, 2);
          await _captureQuiet(tester, 'lockscreen-configured-restored-photos');
        });
      } finally {
        if (!pending.isCompleted) pending.complete(user);
        if (!secondPending.isCompleted) secondPending.complete(user);
        _enableLockscreenCleanupFrames(tester);
        await _settle(tester);
        await _disposeLockscreen(tester);
      }
    },
  );

  testWidgets(
    'lockscreen handoff actual SDK refresh joins held token flight and restores Photos',
    (tester) async {
      final old = await openLockscreenPhotos(tester, sdkStream: true);
      final original = supabase.auth.currentSession!;
      final accountGeneration = ZyraAccountState.generation;
      final preferenceGeneration = ZyraLocalPrefs.bindingGeneration;
      final response = Completer<http.Response>();
      http.Request? tokenRequest;
      final observed = <AuthState>[];
      final streamErrors = <Object>[];
      final subscription = supabase.auth.onAuthStateChange.listen((state) {
        if (state.event == AuthChangeEvent.tokenRefreshed) observed.add(state);
      }, onError: (Object error, StackTrace stack) => streamErrors.add(error));
      String part(Object value) =>
          base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
      final rotated = <String, dynamic>{
        ...original.toJson(),
        'access_token':
            '${part({'alg': 'none'})}.${part({'sub': _founder, 'exp': 4102444800, 'fixture': 'lockscreen-rotated'})}.synthetic',
        'refresh_token': 'synthetic-rotated-refresh',
        // Preserve exactly the SDK user's id/email/app_metadata identity key.
        'user': original.user.toJson(),
      };
      var calls = 0;
      sdkTokenResponse = (request) {
        tokenRequest = request;
        return response.future;
      };
      refresh = () async {
        calls++;
        return (await supabase.auth.refreshSession()).user;
      };
      try {
        await _withHeldBrowsePhotos(tester, (photos) async {
          await _pauseForLockscreen(tester);
          // Keep the widget owner and SDK completion in the same FakeAsync
          // lifetime; bounded dual-zone pumps drain the intercepted HTTP body.
          unawaited(ZyraDeveloperAccess.refreshCurrentAuthorization());
          await _waitForLockscreenBarrier(
            tester,
            () => tokenRequest != null,
            'The actual GoTrue SDK must dispatch its intercepted token POST.',
            advance: const Duration(milliseconds: 1),
          );
          // Assert outside GoTrueFetch's catch/retry boundary so a fixture
          // failure stays visible instead of becoming a fetch retry.
          expect(tokenRequest!.url.path, '/auth/v1/token');
          expect(tokenRequest!.method, 'POST');
          expect(
            tokenRequest!.url.queryParameters['grant_type'],
            'refresh_token',
          );
          expect(
            (jsonDecode(tokenRequest!.body)
                as Map<String, dynamic>)['refresh_token'],
            'synthetic-refresh',
          );
          expect(sdkTokenRequests, 1);
          expect(calls, 1);
          expect(observed, isEmpty);
          expect(
            supabase.auth.currentSession!.accessToken,
            original.accessToken,
          );
          expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
          expect(old.shell.canAct(), isFalse);
          _returnFromBackground(tester);
          await tester.pump();
          await _captureQuiet(tester, 'lockscreen-sdk-first-resumed');
          expect(old.editor.mounted, isFalse);
          _expectLockscreenCover(tester);
          denyOldLockscreenActions(old);
          await tester.pump(const Duration(milliseconds: 500));
          _expectLockscreenCover(tester);
          expect(_key('founder_resume_status'), findsNothing);
          expect(sdkTokenRequests, 1);
          expect(calls, 1);
          expect(forwarded, 0);

          response.complete(
            http.Response(
              jsonEncode(rotated),
              200,
              request: tokenRequest,
              headers: {'content-type': 'application/json'},
            ),
          );
          await _waitForLockscreenBarrier(
            tester,
            () =>
                observed.length == 1 &&
                ZyraDeveloperAccess.canUseDeveloperTools,
            'SDK save + real tokenRefreshed must complete the same proof flight.',
          );
          expect(streamErrors, isEmpty);
          expect(observed.single.session!.accessToken, rotated['access_token']);
          expect(
            supabase.auth.currentSession!.accessToken,
            rotated['access_token'],
          );
          expect(supabase.auth.currentUser!.id, _founder);
          expect(ZyraAccountState.generation, accountGeneration);
          expect(ZyraLocalPrefs.bindingGeneration, preferenceGeneration);
          expect(sdkTokenRequests, 1);
          expect(calls, 1);
          await _settle(tester);
          _expectLockscreenCover(tester, proofPending: false);
          denyOldLockscreenActions(old);
          await tester.pump();
          _expectLockscreenCover(tester, proofPending: false);
          await _captureQuiet(tester, 'lockscreen-sdk-awaiting-photos');
          photos.complete();
          await _settle(tester);
          await expectFreshLockscreenPhotos(tester, old);
          expect(observed, hasLength(1));
          expect(sdkTokenRequests, 1);
          expect(calls, 1);
          // SDK rotation may update exactly its own persisted synthetic session.
          final authKey =
              'sb-${Uri.parse(ZyraInternalFounderPolicy.approvedSupabaseUrl).host.split('.').first}-auth-token';
          final before = Map<String, Object?>.of(old.preferences)
            ..remove(authKey);
          final after = await preferenceSnapshot(tester);
          final persisted = after.remove(authKey);
          expect(after, before);
          if (persisted != null) {
            final stored =
                jsonDecode(persisted as String) as Map<String, dynamic>;
            expect(stored['access_token'], rotated['access_token']);
            expect((stored['user'] as Map<String, dynamic>)['id'], _founder);
          }
          expect(forwarded, 0);
          await _captureQuiet(tester, 'lockscreen-sdk-restored-photos');
        });
      } finally {
        if (!response.isCompleted) {
          response.complete(
            http.Response(
              jsonEncode(rotated),
              200,
              request: tokenRequest,
              headers: {'content-type': 'application/json'},
            ),
          );
        }
        _enableLockscreenCleanupFrames(tester);
        await _settle(tester);
        // GoTrue's observer was created outside this widget FakeAsync zone.
        // Track cancellation in the real boundary, then drain both clocks;
        // a bare await strands later test pumps despite completed disposal.
        var cancelled = false;
        Object? cancelError;
        await tester.runAsync(() async {
          unawaited(
            subscription.cancel().then(
              (_) => cancelled = true,
              onError: (Object error) {
                cancelError = error;
                cancelled = true;
              },
            ),
          );
        });
        await _waitForLockscreenBarrier(
          tester,
          () => cancelled,
          'SDK observer cancellation drains both async zones.',
        );
        expect(cancelError, isNull);
        refresh = () async => supabase.auth.currentUser;
        sdkTokenResponse = null;
        await _disposeLockscreen(tester);
      }
    },
  );

  testWidgets(
    'lockscreen handoff fast completion has no loading flash or minimum dwell',
    (tester) async {
      final old = await openLockscreenPhotos(tester);
      final user = supabase.auth.currentUser;
      final pending = Completer<User?>();
      var calls = 0;
      refresh = () {
        calls++;
        return pending.future;
      };
      try {
        await _pauseForLockscreen(tester);
        unawaited(ZyraDeveloperAccess.refreshCurrentAuthorization());
        await _waitForLockscreenBarrier(
          tester,
          () => calls == 1,
          'Paused refresh',
        );
        _returnFromBackground(tester);
        await tester.pump();
        await _captureQuiet(tester, 'lockscreen-fast-first-resumed');
        _expectLockscreenCover(tester);
        pending.complete(user);
        for (var frame = 0; frame < 60; frame++) {
          await tester.pump(const Duration(milliseconds: 8));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          _expectNoLockscreenLoading(tester, allowCoveredPreparation: true);
          expect(_key('founder_resume_status'), findsNothing);
          expect(_key('founder_resume_recovery'), findsNothing);
          expect(old.shell.canAct(), isFalse);
          if (_key('founder_resume_continuity').evaluate().isEmpty &&
              _key('founder_resume_quiet_background').evaluate().isEmpty &&
              _key('photos-title').evaluate().isNotEmpty) {
            break;
          }
        }
        expect(_key('founder_resume_continuity'), findsNothing);
        expect(_key('founder_resume_quiet_background'), findsNothing);
        expect(_key('photos-title'), findsOneWidget);
        expect(calls, 1);
        await expectFreshLockscreenPhotos(tester, old);
        expect(await preferenceSnapshot(tester), old.preferences);
      } finally {
        if (!pending.isCompleted) pending.complete(user);
        _enableLockscreenCleanupFrames(tester);
        await _settle(tester);
        await _disposeLockscreen(tester);
      }
    },
  );

  testWidgets(
    'lockscreen handoff preserves 799-800ms feedback and joined ten-second deadline',
    (tester) async {
      // Keep the independent authorization timeout out of the presentation's
      // exact ten-second boundary; this never grants proof or skips refresh.
      final old = await openLockscreenPhotos(
        tester,
        refreshTimeout: const Duration(minutes: 1),
      );
      final pending = Completer<User?>();
      var calls = 0;
      refresh = () {
        calls++;
        return pending.future;
      };
      try {
        await _pauseForLockscreen(tester);
        unawaited(ZyraDeveloperAccess.refreshCurrentAuthorization());
        await _waitForLockscreenBarrier(
          tester,
          () => calls == 1,
          'Paused refresh',
        );
        _returnFromBackground(tester);
        await tester.pump();
        _expectLockscreenCover(tester);
        final ticket = ZyraPreviewResumeTransition.changes.value;
        expect(ticket, isNotNull);
        await tester.pump(const Duration(milliseconds: 799));
        _expectLockscreenCover(tester);
        expect(_key('founder_resume_status'), findsNothing);
        await tester.pump(const Duration(milliseconds: 1));
        _expectLockscreenCover(tester);
        expect(_key('founder_resume_status'), findsOneWidget);
        expect(find.text('Updating…'), findsOneWidget);
        final status = tester.getRect(_key('founder_resume_status'));
        expect(status.height, lessThan(160));
        expect(status.width, lessThan(390));
        await _captureQuiet(tester, 'lockscreen-updating-800ms');
        await tester.pump(const Duration(milliseconds: 8200));
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(ZyraPreviewResumeTransition.changes.value, same(ticket));
        expect(calls, 1);
        await tester.pump(const Duration(seconds: 1));
        _expectNoLockscreenLoading(tester);
        expect(_key('founder_resume_recovery'), findsOneWidget);
        expect(_key('founder_resume_continuity'), findsNothing);
        expect(_key('founder_resume_quiet_background'), findsNothing);
        expect(
          tester
              .widget<ButtonStyleButton>(_key('founder_resume_retry'))
              .onPressed,
          isNull,
        );
        expect(_key('founder_resume_home'), findsNothing);
        denyOldLockscreenActions(old);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(calls, 1);
        expect(await preferenceSnapshot(tester), old.preferences);
        expect(forwarded, 0);
        await _captureQuiet(tester, 'lockscreen-recovery-ten-seconds');
        await _captureQuiet(
          tester,
          'quiet_access_waiting_unproven',
          directory: _accessCaptureDirectory,
        );
      } finally {
        if (!pending.isCompleted) pending.complete(null);
        _enableLockscreenCleanupFrames(tester);
        await _settle(tester);
        await _disposeLockscreen(tester);
      }
    },
  );

  for (final failure in ['denied', 'error']) {
    testWidgets('lockscreen handoff $failure cannot retain preview admission', (
      tester,
    ) async {
      final old = await openLockscreenPhotos(tester);
      final pending = Completer<User?>();
      var calls = 0;
      refresh = () {
        calls++;
        return pending.future;
      };
      try {
        await _pauseForLockscreen(tester);
        unawaited(ZyraDeveloperAccess.refreshCurrentAuthorization());
        await _waitForLockscreenBarrier(
          tester,
          () => calls == 1,
          'Paused refresh',
        );
        _returnFromBackground(tester);
        await tester.pump();
        _expectLockscreenCover(tester);
        if (failure == 'denied') {
          pending.complete(null);
        } else {
          pending.completeError(
            StateError('Synthetic background refresh failure'),
          );
        }
        await _settle(tester);
        expect(_key('founder_resume_continuity'), findsNothing);
        expect(_key('founder_resume_quiet_background'), findsNothing);
        expect(_key('founder_resume_status'), findsNothing);
        expect(_key('founder_resume_recovery'), findsNothing);
        expect(ZyraPreviewResumeTransition.changes.value, isNull);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        denyOldLockscreenActions(old);
        await tester.pump();
        expect(find.byType(EditPhotosScreen), findsNothing);
        expect(find.byType(HomeShell), findsNothing);
        expect(find.byType(WaliHomeShell), findsNothing);
        expect(await preferenceSnapshot(tester), old.preferences);
        expect(forwarded, 0);
        await tester.pump(const Duration(seconds: 10));
        expect(_key('founder_resume_recovery'), findsNothing);
        expect(_key('founder_resume_status'), findsNothing);
      } finally {
        if (!pending.isCompleted) pending.complete(null);
        _enableLockscreenCleanupFrames(tester);
        await _settle(tester);
        await _disposeLockscreen(tester);
      }
    });
  }

  for (final invalidation in [
    'account ABA',
    'preference ABA',
    'preview isolation',
    'covered route',
    'app lock',
    'dispose',
  ]) {
    testWidgets(
      'lockscreen handoff cannot revive pixels or actions after $invalidation',
      (tester) async {
        final old = await openLockscreenPhotos(tester);
        final user = supabase.auth.currentUser;
        final pending = Completer<User?>();
        var calls = 0;
        refresh = () {
          calls++;
          return pending.future;
        };
        NavigatorState? cover;
        try {
          await _pauseForLockscreen(tester);
          unawaited(ZyraDeveloperAccess.refreshCurrentAuthorization());
          await _waitForLockscreenBarrier(
            tester,
            () => calls == 1,
            'Paused refresh',
          );
          _returnFromBackground(tester);
          await tester.pump();
          _expectLockscreenCover(tester);
          switch (invalidation) {
            case 'account ABA':
              await tester.runAsync(() async {
                await ZyraAccountState.synchronize(_member);
                await ZyraAccountState.synchronize(_founder);
              });
            case 'preference ABA':
              await tester.runAsync(() async {
                await ZyraLocalPrefs.bindAccount(_member);
                await ZyraLocalPrefs.bindAccount(_founder);
              });
            case 'preview isolation':
              ZyraInternalPreviewClient.finishSignOut();
            case 'covered route':
              final navigator = Navigator.of(
                tester.element(find.byType(ZyraFounderReviewSurface)),
              );
              cover = navigator;
              unawaited(
                navigator.push<void>(
                  MaterialPageRoute(
                    builder: (_) =>
                        const Scaffold(body: Text('Lockscreen covering route')),
                  ),
                ),
              );
            case 'app lock':
              await _writePreference(
                tester,
                () => ZyraLocalPrefs.setAppLockEnabled(true),
              );
              ZyraAppLock.instance.hydrate();
            case 'dispose':
              await tester.pumpWidget(const SizedBox.shrink());
          }
          await _settle(tester);
          expect(_key('founder_resume_continuity'), findsNothing);
          expect(_key('founder_resume_quiet_background'), findsNothing);
          expect(_key('founder_resume_status'), findsNothing);
          expect(_key('founder_resume_recovery'), findsNothing);
          expect(old.editor.mounted, isFalse);
          final afterInvalidation = await preferenceSnapshot(tester);
          denyOldLockscreenActions(old);
          await tester.pump();
          expect(await preferenceSnapshot(tester), afterInvalidation);
          expect(forwarded, 0);
          pending.complete(user);
          await _settle(tester);
          expect(_key('founder_resume_continuity'), findsNothing);
          expect(_key('founder_resume_quiet_background'), findsNothing);
          denyOldLockscreenActions(old);
          await tester.pump();
          expect(
            find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == 'DeveloperAccessScreen',
            ),
            findsNothing,
          );
          expect(find.byType(HomeShell), findsNothing);
          expect(find.byType(WaliHomeShell), findsNothing);
          if (invalidation == 'covered route') {
            expect(find.text('Lockscreen covering route'), findsOneWidget);
          }
          if (invalidation == 'account ABA' ||
              invalidation == 'preference ABA') {
            expect(find.byType(EditPhotosScreen), findsNothing);
          }
          expect(forwarded, 0);
        } finally {
          if (!pending.isCompleted) pending.complete(null);
          _enableLockscreenCleanupFrames(tester);
          await _settle(tester);
          final navigator = cover;
          if (navigator != null && navigator.mounted && navigator.canPop()) {
            navigator.pop();
          }
          ZyraAppLock.instance.clearForSignOut();
          await _settle(tester);
          await _disposeLockscreen(tester);
        }
      },
    );
  }

  for (final termination in ['denied refresh', 'root disposal']) {
    testWidgets(
      'pending local photo selection is discarded after $termination',
      (tester) async {
        final platform = ImagePickerPlatform.instance;
        final picker = _PendingLocalPhotoPicker();
        final authorization = Completer<User?>();
        ImagePickerPlatform.instance = picker;
        try {
          final old = await openLockscreenPhotos(tester);
          final user = supabase.auth.currentUser;
          final imports = old.shell.localPhotoImport;
          expect(imports, isNotNull);
          tester
              .widget<PageView>(_key('photos-page-view'))
              .controller!
              .jumpToPage(1);
          await tester.pump(const Duration(milliseconds: 350));
          await tester.tap(_key('photos-add-page-action'));
          await _waitForLocalImport(
            tester,
            () => picker.calls == 1,
            'The generated selection remains pending in the native picker.',
          );
          expect(imports!.pending, isNotNull);

          if (termination == 'denied refresh') {
            refresh = () => authorization.future;
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
            await tester.pump();
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
            await tester.pump();
            expect(old.editor.mounted, isFalse);
            expect(old.shell.canAct(), isFalse);
            authorization.complete(null);
            await _settle(tester);
            expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
          } else {
            await tester.pumpWidget(const SizedBox.shrink());
            await _settle(tester);
            expect(old.editor.mounted, isFalse);
          }
          expect(imports.pending, isNull);
          expect(find.byType(PhotoCropReviewScreen), findsNothing);
          picker.releaseSelection();
          await _waitForLocalImport(
            tester,
            () => picker.selectionReturned,
            'The late synthetic picker result returns after withdrawal.',
          );
          await _settle(tester);
          expect(imports.pending, isNull);
          expect(find.byType(PhotoCropReviewScreen), findsNothing);
          expect(AppState.instance.photos, old.memberPhotos);
          expect(await preferenceSnapshot(tester), old.preferences);
          expect(forwarded, 0);

          // A new correctly authorized root must not inherit the abandoned
          // request or silently start a crop for its late native completion.
          await tester.pumpWidget(const SizedBox.shrink());
          await _settle(tester);
          refresh = () async => user;
          await launch(tester);
          // A deliberate cold launch records its normal remembered role;
          // importing/discarding the photo itself wrote no preferences above.
          final reopenedPreferences = await preferenceSnapshot(tester);
          expect(reopenedPreferences, {...old.preferences, _roleKey: 'seeker'});
          await openPhotos(tester);
          expect(find.byType(PhotoCropReviewScreen), findsNothing);
          expect(
            tester
                .widget<ZyraOneJourneyConceptShell>(
                  find.byType(ZyraOneJourneyConceptShell),
                )
                .localPhotoImport!
                .pending,
            isNull,
          );
          expect(
            tester
                .widget<PageView>(_key('photos-page-view'))
                .childrenDelegate
                .estimatedChildCount,
            2,
          );
          expect(picker.calls, 1);
          expect(AppState.instance.photos, old.memberPhotos);
          expect(await preferenceSnapshot(tester), reopenedPreferences);
          expect(forwarded, 0);
          expect(tester.takeException(), isNull);
        } finally {
          picker.releaseSelection();
          if (!authorization.isCompleted) authorization.complete(null);
          try {
            await _settle(tester);
            await _disposeLockscreen(tester);
          } finally {
            ImagePickerPlatform.instance = platform;
          }
        }
      },
    );
  }

  testWidgets(
    'second pending photo selection preserves previously confirmed local gallery',
    (tester) async {
      final platform = ImagePickerPlatform.instance;
      final firstPicker = _PendingLocalPhotoPicker();
      final secondPicker = _PendingLocalPhotoPicker(red: 204);
      final authorization = Completer<User?>();
      try {
        final old = await openLockscreenPhotos(tester);
        final user = supabase.auth.currentUser;
        String photoAt(int index) => tester
            .widget<ZyraProfileImage>(
              find.descendant(
                of: _key('photo-large-$index'),
                matching: find.byType(ZyraProfileImage),
              ),
            )
            .photo;
        final fixture = photoAt(0);

        Future<void> startImport(
          _PendingLocalPhotoPicker picker,
          int addPage,
        ) async {
          ImagePickerPlatform.instance = picker;
          tester
              .widget<PageView>(_key('photos-page-view'))
              .controller!
              .jumpToPage(addPage);
          await tester.pump(const Duration(milliseconds: 350));
          await tester.tap(_key('photos-add-page-action'));
          await _waitForLocalImport(
            tester,
            () => picker.calls == 1,
            'Each add uses one generated native picker selection.',
          );
        }

        Future<void> confirmImport(int addedIndex) async {
          await _waitForLocalImport(
            tester,
            () => find.byType(PhotoCropReviewScreen).evaluate().length == 1,
            'The selected photo opens one current crop review.',
          );
          await _waitForLocalImport(tester, () {
            final confirm = _key('photo-crop-confirm');
            return confirm.evaluate().length == 1 &&
                tester.widget<FilledButton>(confirm).onPressed != null;
          }, 'The generated photo is ready for crop confirmation.');
          await tester.tap(_key('photo-crop-confirm'));
          await _waitForLocalImport(
            tester,
            () =>
                find.byType(PhotoCropReviewScreen).evaluate().isEmpty &&
                _key('photo-large-$addedIndex').evaluate().isNotEmpty,
            'The confirmed photo is added after the existing local gallery.',
          );
          await _settle(tester);
        }

        await startImport(firstPicker, 1);
        firstPicker.releaseSelection();
        await confirmImport(1);
        final first = photoAt(1);
        expect(first, startsWith('data:image/jpeg;base64,'));
        expect(old.shell.localPhotoImport!.pending, isNull);
        expect(
          tester
              .widget<PageView>(_key('photos-page-view'))
              .childrenDelegate
              .estimatedChildCount,
          3,
        );
        expect(AppState.instance.photos, old.memberPhotos);
        expect(await preferenceSnapshot(tester), old.preferences);
        expect(forwarded, 0);

        refresh = () => authorization.future;
        await startImport(secondPicker, 2);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(old.editor.mounted, isFalse);
        expect(old.shell.canAct(), isFalse);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        secondPicker.releaseSelection();
        await _waitForLocalImport(
          tester,
          () => secondPicker.selectionReturned,
          'The second selection returns during the fresh access check.',
        );
        await _settle(tester);
        expect(find.byType(PhotoCropReviewScreen), findsNothing);
        expect(AppState.instance.photos, old.memberPhotos);
        expect(await preferenceSnapshot(tester), old.preferences);
        expect(forwarded, 0);

        authorization.complete(user);
        await _settle(tester);
        await confirmImport(2);
        final second = photoAt(2);
        expect(second, startsWith('data:image/jpeg;base64,'));
        expect(second, isNot(first));
        expect(firstPicker.calls, 1);
        expect(secondPicker.calls, 1);
        expect(old.shell.canAct(), isFalse);
        expect(
          tester
              .widget<PageView>(_key('photos-page-view'))
              .childrenDelegate
              .estimatedChildCount,
          4,
        );
        await swipeZyraBack(tester);
        await _press(tester, 'concept_preview_profile');
        final profile = tester
            .widget<ZyraBrowseDesigns>(find.byType(ZyraBrowseDesigns))
            .profiles
            .single;
        expect(profile.photos, [fixture, first, second]);
        expect(profile.photos.toSet(), hasLength(3));
        expect(AppState.instance.photos, old.memberPhotos);
        expect(await preferenceSnapshot(tester), old.preferences);
        expect(forwarded, 0);
        expect(tester.takeException(), isNull);
      } finally {
        firstPicker.releaseSelection();
        secondPicker.releaseSelection();
        if (!authorization.isCompleted) authorization.complete(null);
        try {
          await _settle(tester);
          await _disposeLockscreen(tester);
        } finally {
          ImagePickerPlatform.instance = platform;
        }
      }
    },
  );

  for (final away in [
    const Duration(seconds: 5),
    const Duration(minutes: 14, seconds: 59, milliseconds: 999),
    const Duration(minutes: 15),
  ]) {
    testWidgets(
      'Photos returns to its exact page only below fifteen minutes: $away',
      (tester) async {
        var elapsed = Duration.zero;
        await tester.runAsync(ZyraDeveloperAccess.refreshCurrentAuthorization);
        ZyraInternalPreviewClient.beginPreview();
        await mount(
          tester,
          ZyraFounderReviewSurface(
            ownerId: _founder,
            ownerGeneration: ZyraAccountState.generation,
            resumeElapsedForTesting: () => elapsed,
          ),
        );
        final staleToggle = await openPhotos(tester);
        final old = tester.widget<ZyraOneJourneyConceptShell>(
          find.byType(ZyraOneJourneyConceptShell),
        );
        final oldEditor = tester.state<State<EditPhotosScreen>>(
          find.byType(EditPhotosScreen),
        );
        final memberPhotos = List<String>.of(AppState.instance.photos);
        final preferencesBefore = await preferenceSnapshot(tester);
        final pending = Completer<User?>();
        var refreshCalls = 0;
        refresh = () {
          refreshCalls++;
          return pending.future;
        };
        try {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.hidden,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          elapsed = away;
          _returnFromBackground(tester);
          await tester.pump();
          expect(refreshCalls, 1);
          expect(old.canAct(), isFalse);
          expect(oldEditor.mounted, isFalse);
          expect(find.byType(EditPhotosScreen), findsNothing);
          expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
          staleToggle();
          old.onRoleChanged?.call(true);
          await tester.pump();
          if (away < const Duration(minutes: 15)) {
            _expectResumeContinuity(tester);
            if (away == const Duration(seconds: 5)) {
              await _captureQuiet(tester, 'photos_short_pending');
            }
          } else {
            _expectLongResumeQuiet(tester);
            expect(_key('founder_resume_continuity'), findsNothing);
          }
          expect(await preferenceSnapshot(tester), preferencesBefore);
          pending.complete(supabase.auth.currentUser);
          await _settle(tester);
          final fresh = tester.widget<ZyraOneJourneyConceptShell>(
            find.byType(ZyraOneJourneyConceptShell),
          );
          expect(identical(old, fresh), isFalse);
          expect(fresh.canAct(), isTrue);
          expect(old.canAct(), isFalse);
          staleToggle();
          await tester.pump();
          if (away < const Duration(minutes: 15)) {
            await _expectPhotosPainted(tester);
            expect(
              identical(oldEditor, tester.state(find.byType(EditPhotosScreen))),
              isFalse,
            );
            expect(_key('photos-compact-view'), findsNothing);
            expect(_key('founder_resume_continuity'), findsNothing);
            if (away == const Duration(seconds: 5)) {
              await _captureQuiet(tester, 'photos_short_restored');
            }
          } else {
            expect(find.byType(EditPhotosScreen), findsNothing);
            expect(_key('founder_resume_continuity'), findsNothing);
            expect(_key('founder_resume_quiet_background'), findsNothing);
            expect(find.text('My ZYRA'), findsOneWidget);
            expect(
              tester
                  .widget<FloatingNavBar>(find.byType(FloatingNavBar))
                  .currentIndex,
              2,
            );
          }
          expect(find.byType(ZyraLoading), findsNothing);
          expect(AppState.instance.photos, memberPhotos);
          expect(await preferenceSnapshot(tester), preferencesBefore);
          expect(forwarded, 0);
        } finally {
          if (!pending.isCompleted) pending.complete(null);
          await _settle(tester);
          await _dispose(tester);
        }
      },
    );
  }

  testWidgets(
    'Photos stays at the same location after inactive-only fresh proof',
    (tester) async {
      await launch(tester);
      await openPhotos(tester);
      final state = tester.state<State<EditPhotosScreen>>(
        find.byType(EditPhotosScreen),
      );
      final old = tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      var refreshCalls = 0;
      refresh = () async {
        refreshCalls++;
        return supabase.auth.currentUser;
      };
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(seconds: 2));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _settle(tester);
      expect(refreshCalls, 1);
      expect(state.mounted, isFalse);
      expect(
        identical(state, tester.state(find.byType(EditPhotosScreen))),
        isFalse,
      );
      expect(old.canAct(), isFalse);
      expect(
        tester
            .widget<ZyraOneJourneyConceptShell>(
              find.byType(ZyraOneJourneyConceptShell),
            )
            .canAct(),
        isTrue,
      );
      await _expectPhotosPainted(tester);
      expect(_key('founder_resume_continuity'), findsNothing);
      expect(_key('founder_resume_quiet_background'), findsNothing);
      expect(forwarded, 0);
      await _dispose(tester);
    },
  );

  for (final selectionBeforeProof in [true, false]) {
    testWidgets(
      'pending local photo selection survives fresh proof when selection arrives '
      '${selectionBeforeProof ? 'before' : 'after'} authorization',
      (tester) async {
        final platform = ImagePickerPlatform.instance;
        final picker = _PendingLocalPhotoPicker();
        final authorization = Completer<User?>();
        ImagePickerPlatform.instance = picker;
        try {
          final old = await openLockscreenPhotos(tester);
          final user = supabase.auth.currentUser;
          var refreshCalls = 0;
          refresh = () {
            refreshCalls++;
            return authorization.future;
          };
          final pager = tester.widget<PageView>(_key('photos-page-view'));
          expect(pager.childrenDelegate.estimatedChildCount, 2);
          pager.controller!.jumpToPage(1);
          await tester.pump(const Duration(milliseconds: 350));
          expect(_key('photos-add-page-action').hitTestable(), findsOneWidget);
          final staleAdd = tester
              .widget<InkWell>(_key('photos-add-page-action'))
              .onTap!;
          await tester.tap(_key('photos-add-page-action'));
          await _waitForLocalImport(
            tester,
            () => picker.calls == 1,
            'The actual platform picker starts once from Add a new photo.',
          );
          expect(find.byType(PhotoCropReviewScreen), findsNothing);

          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          await tester.pump();
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();
          expect(refreshCalls, 1);
          expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
          expect(old.editor.mounted, isFalse);
          expect(old.shell.canAct(), isFalse);
          expect(find.byType(EditPhotosScreen), findsNothing);
          expect(find.byType(PhotoCropReviewScreen), findsNothing);
          staleAdd();
          old.toggle();
          await tester.pump();
          expect(picker.calls, 1);
          expect(AppState.instance.photos, old.memberPhotos);
          expect(await preferenceSnapshot(tester), old.preferences);
          expect(forwarded, 0);

          if (selectionBeforeProof) {
            picker.releaseSelection();
            await _waitForLocalImport(
              tester,
              () => picker.selectionReturned,
              'The synthetic native selection returns while proof is pending.',
            );
            await _settle(tester);
            expect(find.byType(PhotoCropReviewScreen), findsNothing);
            expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
            expect(AppState.instance.photos, old.memberPhotos);
            expect(await preferenceSnapshot(tester), old.preferences);
            expect(forwarded, 0);
          }

          authorization.complete(user);
          await _settle(tester);
          expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
          expect(old.editor.mounted, isFalse);
          expect(old.shell.canAct(), isFalse);
          if (!selectionBeforeProof) {
            expect(find.byType(PhotoCropReviewScreen), findsNothing);
            picker.releaseSelection();
          }
          await _waitForLocalImport(
            tester,
            () => find.byType(PhotoCropReviewScreen).evaluate().length == 1,
            'Fresh same-owner proof resumes exactly one new crop review.',
          );
          final crop = tester.state<State<PhotoCropReviewScreen>>(
            find.byType(PhotoCropReviewScreen),
          );
          await _waitForLocalImport(
            tester,
            () {
              final confirm = _key('photo-crop-confirm');
              return confirm.evaluate().length == 1 &&
                  tester.widget<FilledButton>(confirm).onPressed != null;
            },
            'The generated photo decodes and becomes ready for confirmation.',
          );
          expect(picker.calls, 1);
          expect(refreshCalls, 1);
          expect(find.byType(PhotoCropReviewScreen), findsOneWidget);
          staleAdd();
          old.toggle();
          await tester.pump();
          expect(tester.state(find.byType(PhotoCropReviewScreen)), same(crop));
          expect(AppState.instance.photos, old.memberPhotos);
          expect(await preferenceSnapshot(tester), old.preferences);
          expect(forwarded, 0);

          await tester.tap(_key('photo-crop-confirm'));
          await _waitForLocalImport(
            tester,
            () =>
                find.byType(PhotoCropReviewScreen).evaluate().isEmpty &&
                _key('photo-large-1').evaluate().isNotEmpty,
            'Confirming the fresh crop adds one photo to the current local editor.',
          );
          await _settle(tester);
          expect(crop.mounted, isFalse);
          expect(find.byType(EditPhotosScreen), findsOneWidget);
          expect(
            tester.state(find.byType(EditPhotosScreen)),
            isNot(same(old.editor)),
          );
          final imported = tester
              .widget<ZyraProfileImage>(
                find.descendant(
                  of: _key('photo-large-1'),
                  matching: find.byType(ZyraProfileImage),
                ),
              )
              .photo;
          expect(imported, startsWith('data:image/jpeg;base64,'));
          final decoded = img.decodeJpg(
            base64Decode(imported.substring(imported.indexOf(',') + 1)),
          );
          expect(decoded, isNotNull);
          expect(decoded!.exif.isEmpty, isTrue);
          expect(decoded.textData ?? const <String, String>{}, isEmpty);
          expect(decoded.width, lessThanOrEqualTo(1440));
          expect(decoded.height, lessThanOrEqualTo(1440));
          expect(
            tester
                .widget<PageView>(_key('photos-page-view'))
                .childrenDelegate
                .estimatedChildCount,
            3,
          );

          await swipeZyraBack(tester);
          await _press(tester, 'concept_preview_profile');
          expect(find.byType(MyProfilePreviewScreen), findsOneWidget);
          final profile = tester
              .widget<ZyraBrowseDesigns>(find.byType(ZyraBrowseDesigns))
              .profiles
              .single;
          expect(profile.id, 'draft-self');
          expect(profile.photos, hasLength(2));
          expect(
            profile.photos.where((photo) => photo == imported),
            hasLength(1),
          );
          expect(find.byType(PhotoCropReviewScreen), findsNothing);
          expect(picker.calls, 1);
          expect(old.shell.canAct(), isFalse);
          expect(AppState.instance.photos, old.memberPhotos);
          expect(await preferenceSnapshot(tester), old.preferences);
          expect(forwarded, 0);
          expect(tester.takeException(), isNull);
        } finally {
          picker.releaseSelection();
          if (!authorization.isCompleted) authorization.complete(null);
          try {
            await _settle(tester);
            await _disposeLockscreen(tester);
          } finally {
            ImagePickerPlatform.instance = platform;
          }
        }
      },
    );
  }

  for (final away in [
    const Duration(seconds: 5),
    const Duration(minutes: 14, seconds: 59, milliseconds: 999),
    const Duration(minutes: 15),
    const Duration(minutes: 20),
  ]) {
    testWidgets(
      'fresh proof restores location only below fifteen minutes: $away',
      (tester) async {
        var elapsed = Duration.zero;
        await tester.runAsync(ZyraDeveloperAccess.refreshCurrentAuthorization);
        ZyraInternalPreviewClient.beginPreview();
        await mount(
          tester,
          ZyraFounderReviewSurface(
            ownerId: _founder,
            ownerGeneration: ZyraAccountState.generation,
            resumeElapsedForTesting: () => elapsed,
          ),
        );
        expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
        tester.widget<FloatingNavBar>(find.byType(FloatingNavBar)).onTap(1);
        await _settle(tester);
        expect(find.text('Journey'), findsOneWidget);
        final old = tester.widget<ZyraOneJourneyConceptShell>(
          find.byType(ZyraOneJourneyConceptShell),
        );
        for (final state in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        elapsed = away;
        final pending = Completer<User?>();
        refresh = () => pending.future;
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump(const Duration(milliseconds: 16));
        expect(old.canAct(), isFalse);
        expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
        if (away < const Duration(minutes: 15)) {
          _expectResumeContinuity(tester);
          expect(_key('founder_resume_quiet_background'), findsNothing);
        } else {
          _expectLongResumeQuiet(tester);
        }
        pending.complete(supabase.auth.currentUser);
        await _settle(tester);
        final restored = tester.widget<ZyraOneJourneyConceptShell>(
          find.byType(ZyraOneJourneyConceptShell),
        );
        expect(identical(old, restored), isFalse);
        expect(restored.canAct(), isTrue);
        expect(
          tester
              .widget<FloatingNavBar>(find.byType(FloatingNavBar))
              .currentIndex,
          away < const Duration(minutes: 15) ? 1 : 2,
        );
        expect(find.byType(ZyraLoading), findsNothing);
        expect(forwarded, 0);
        await _dispose(tester);
      },
    );
  }

  for (final away in [
    const Duration(minutes: 15),
    const Duration(minutes: 20),
    const Duration(hours: 8),
  ]) {
    testWidgets(
      'long return $away is quiet from first frame through new My ZYRA paint',
      (tester) async {
        var elapsed = Duration.zero;
        await tester.runAsync(ZyraDeveloperAccess.refreshCurrentAuthorization);
        ZyraInternalPreviewClient.beginPreview();
        await mount(
          tester,
          ZyraFounderReviewSurface(
            ownerId: _founder,
            ownerGeneration: ZyraAccountState.generation,
            resumeElapsedForTesting: () => elapsed,
          ),
        );
        tester.widget<FloatingNavBar>(find.byType(FloatingNavBar)).onTap(1);
        await _settle(tester);
        final old = tester.widget<ZyraOneJourneyConceptShell>(
          find.byType(ZyraOneJourneyConceptShell),
        );
        final authorization = Completer<User?>();
        refresh = () => authorization.future;
        try {
          await _withHeldBrowsePhotos(tester, (photos) async {
            for (final state in [
              AppLifecycleState.inactive,
              AppLifecycleState.hidden,
              AppLifecycleState.paused,
            ]) {
              tester.binding.handleAppLifecycleStateChanged(state);
            }
            elapsed = away;
            _returnFromBackground(tester);
            await tester.pump();
            _expectLongResumeQuiet(tester);
            expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
            expect(old.canAct(), isFalse);
            if (away.inMinutes == 15) {
              await _captureQuiet(tester, 'long_resume_pending');
            }
            // Saved callbacks cannot paint or switch the old owner back in.
            old.onPresentationReady?.call();
            old.onRoleChanged?.call(true);
            await tester.pump(const Duration(milliseconds: 500));
            _expectLongResumeQuiet(tester);
            expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
            authorization.complete(supabase.auth.currentUser);
            await _settle(tester);
            _expectLongResumeQuiet(tester);
            final fresh = tester.widget<ZyraOneJourneyConceptShell>(
              find.byType(ZyraOneJourneyConceptShell),
            );
            expect(identical(old, fresh), isFalse);
            expect(fresh.canAct(), isTrue);
            expect(fresh.initialGuardianRole, isFalse);
            expect(
              tester
                  .widget<FloatingNavBar>(find.byType(FloatingNavBar))
                  .currentIndex,
              2,
            );
            old.onPresentationReady?.call();
            await tester.pump();
            _expectLongResumeQuiet(tester);
            if (away.inMinutes == 15) {
              await _captureQuiet(tester, 'long_resume_waiting_photos');
            }
            photos.complete();
            await _settle(tester);
            expect(_key('founder_resume_quiet_background'), findsNothing);
            expect(_key('founder_resume_continuity'), findsNothing);
            expect(find.byType(ZyraLoading), findsNothing);
            expect(find.text('My ZYRA'), findsOneWidget);
            expect(old.canAct(), isFalse);
            expect(forwarded, 0);
            if (away.inMinutes == 15) {
              await _captureQuiet(tester, 'long_resume_ready_my_zyra');
            }
          });
        } finally {
          if (!authorization.isCompleted) authorization.complete(null);
          await _settle(tester);
          await _dispose(tester);
        }
      },
    );
  }

  testWidgets(
    'long quiet cover expires without resurrection and a completed reset permits short restoration',
    (tester) async {
      var elapsed = Duration.zero;
      await tester.runAsync(ZyraDeveloperAccess.refreshCurrentAuthorization);
      ZyraInternalPreviewClient.beginPreview();
      await mount(
        tester,
        ZyraFounderReviewSurface(
          ownerId: _founder,
          ownerGeneration: ZyraAccountState.generation,
          resumeElapsedForTesting: () => elapsed,
        ),
      );
      await _withHeldBrowsePhotos(tester, (photos) async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        elapsed = const Duration(minutes: 20);
        _returnFromBackground(tester);
        await _settle(tester);
        _expectLongResumeQuiet(tester);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
        await tester.pump(const Duration(seconds: 10));
        expect(_key('founder_resume_quiet_background'), findsNothing);
        expect(_key('founder_resume_continuity'), findsNothing);
        expect(_key('founder_resume_recovery'), findsOneWidget);
        // A repeated resumed notification is not another background departure.
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump(const Duration(milliseconds: 32));
        expect(_key('founder_resume_quiet_background'), findsNothing);
        expect(_key('founder_resume_recovery'), findsOneWidget);
        expect(forwarded, 0);
        photos.complete();
        await _settle(tester);
        expect(find.text('My ZYRA'), findsOneWidget);
      });
      tester.widget<FloatingNavBar>(find.byType(FloatingNavBar)).onTap(1);
      await _settle(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      elapsed += const Duration(seconds: 5);
      _returnFromBackground(tester);
      await _settle(tester);
      expect(
        tester.widget<FloatingNavBar>(find.byType(FloatingNavBar)).currentIndex,
        1,
      );
      expect(_key('founder_resume_quiet_background'), findsNothing);
      expect(forwarded, 0);
      await _dispose(tester);
    },
  );

  for (final interruption in [
    'metrics',
    'covered route',
    'app lock',
    'repeated background',
  ]) {
    testWidgets('pending long handover remains safe after $interruption', (
      tester,
    ) async {
      var elapsed = Duration.zero;
      await tester.runAsync(ZyraDeveloperAccess.refreshCurrentAuthorization);
      ZyraInternalPreviewClient.beginPreview();
      await mount(
        tester,
        ZyraFounderReviewSurface(
          ownerId: _founder,
          ownerGeneration: ZyraAccountState.generation,
          resumeElapsedForTesting: () => elapsed,
        ),
      );
      await _withHeldBrowsePhotos(tester, (photos) async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        elapsed = const Duration(minutes: 20);
        _returnFromBackground(tester);
        await _settle(tester);
        _expectLongResumeQuiet(tester);
        switch (interruption) {
          case 'metrics':
            tester.view.physicalSize = const Size(430, 932);
            await tester.pump();
          case 'covered route':
            final context = tester.element(
              find.byType(ZyraFounderReviewSurface),
            );
            final navigator = Navigator.of(context);
            unawaited(
              navigator.push<void>(
                MaterialPageRoute(builder: (_) => const Scaffold()),
              ),
            );
            await tester.pump(const Duration(milliseconds: 300));
            expect(_key('founder_resume_quiet_background'), findsNothing);
            navigator.pop();
            await tester.pump(const Duration(milliseconds: 300));
            await tester.pump();
          case 'app lock':
            await tester.runAsync(() => ZyraLocalPrefs.setAppLockEnabled(true));
            ZyraAppLock.instance.hydrate();
            await tester.pump();
            expect(_key('founder_resume_quiet_background'), findsNothing);
            ZyraAppLock.instance.clearForSignOut();
            await tester.pump();
          case 'repeated background':
            final pending = Completer<User?>();
            refresh = () => pending.future;
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.hidden,
            );
            elapsed += const Duration(seconds: 5);
            _returnFromBackground(tester);
            await tester.pump();
            _expectLongResumeQuiet(tester);
            pending.complete(supabase.auth.currentUser);
            await _settle(tester);
        }
        _expectLongResumeQuiet(tester);
        photos.complete();
        await _settle(tester);
        expect(_key('founder_resume_quiet_background'), findsNothing);
        expect(find.text('My ZYRA'), findsOneWidget);
        expect(
          tester
              .widget<FloatingNavBar>(find.byType(FloatingNavBar))
              .currentIndex,
          2,
        );
        expect(forwarded, 0);
      });
      await _dispose(tester);
    });
  }

  testWidgets(
    'another real background departure replaces a suspended quiet deadline',
    (tester) async {
      var elapsed = Duration.zero;
      await tester.runAsync(ZyraDeveloperAccess.refreshCurrentAuthorization);
      ZyraInternalPreviewClient.beginPreview();
      await mount(
        tester,
        ZyraFounderReviewSurface(
          ownerId: _founder,
          ownerGeneration: ZyraAccountState.generation,
          resumeElapsedForTesting: () => elapsed,
        ),
      );
      await _withHeldBrowsePhotos(tester, (photos) async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        elapsed = const Duration(minutes: 20);
        _returnFromBackground(tester);
        await _settle(tester);
        _expectLongResumeQuiet(tester);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        // Flutter may deliver old timers after a suspended app returns. That
        // old deadline must not consume the next handover's foreground window.
        await tester.pump(const Duration(seconds: 11));
        elapsed += const Duration(minutes: 20);
        final pending = Completer<User?>();
        refresh = () => pending.future;
        try {
          _returnFromBackground(tester);
          await tester.pump();
          _expectLongResumeQuiet(tester);
          expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
          pending.complete(supabase.auth.currentUser);
          await _settle(tester);
          _expectLongResumeQuiet(tester);
          photos.complete();
          await _settle(tester);
          expect(_key('founder_resume_quiet_background'), findsNothing);
          expect(find.text('My ZYRA'), findsOneWidget);
          expect(forwarded, 0);
        } finally {
          if (!pending.isCompleted) pending.complete(null);
        }
      });
      await _dispose(tester);
    },
  );

  testWidgets(
    'short warm resume keeps only an inert continuity frame until fresh proof',
    (tester) async {
      await launch(tester);
      final old = tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      final pending = Completer<User?>();
      refresh = () => pending.future;
      try {
        _resume(tester);
        await tester.pump(const Duration(milliseconds: 16));
        expect(_key('zyra_loading_golden_thread'), findsNothing);
        expect(_key('founder_resume_continuity'), findsOneWidget);
        expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
        expect(old.canAct(), isFalse);
        expect(ZyraConceptPreviewIsolation.active, isTrue);
        expect(ZyraInternalPreviewClient.isActive, isTrue);
        expect(forwarded, 0);
        pending.complete(supabase.auth.currentUser);
        await _settle(tester);
        // Native image decoding is not driven by Flutter's fake frame clock.
        // Wait only for this fresh owner's real ready/paint signal, bounded
        // well below the ten-second visual deadline (never pass by expiry).
        for (
          var frame = 0;
          frame < 60 && _key('founder_resume_continuity').evaluate().isNotEmpty;
          frame++
        ) {
          expect(old.canAct(), isFalse);
          expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
          expect(find.byType(ZyraLoading), findsNothing);
          await tester.pump(const Duration(milliseconds: 16));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
        }
        expect(_key('founder_resume_continuity'), findsNothing);
        expect(_key('zyra_loading_golden_thread'), findsNothing);
        expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
        expect(old.canAct(), isFalse);
      } finally {
        if (!pending.isCompleted) pending.complete(supabase.auth.currentUser);
        await _settle(tester);
        await _dispose(tester);
      }
    },
  );

  for (final failure in ['denied', 'error', 'auth stream error']) {
    testWidgets('warm continuity is discarded on $failure', (tester) async {
      final states = StreamController<AuthState>();
      final destination = await tester.runAsync(ZyraSessionRouter.resolveHome);
      await mount(tester, destination!, authStates: states.stream);
      final old = tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      final pending = Completer<User?>();
      refresh = () => pending.future;
      try {
        _resume(tester);
        await tester.pump(const Duration(milliseconds: 800));
        _expectResumeContinuity(tester);
        expect(_key('founder_resume_status'), findsOneWidget);
        if (failure == 'denied') {
          pending.complete(null);
        } else if (failure == 'error') {
          pending.completeError(StateError('Synthetic resume rejection'));
        } else {
          states.addError(StateError('Synthetic auth stream failure'));
        }
        await _settle(tester);
        expect(_key('founder_resume_continuity'), findsNothing);
        expect(_key('founder_resume_status'), findsNothing);
        expect(_key('founder_resume_recovery'), findsNothing);
        expect(ZyraPreviewResumeTransition.changes.value, isNull);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(old.canAct(), isFalse);
        expect(find.byType(HomeShell), findsNothing);
        expect(find.byType(WaliHomeShell), findsNothing);
        expect(forwarded, 0);
        await tester.pump(const Duration(seconds: 10));
        expect(_key('founder_resume_status'), findsNothing);
        expect(_key('founder_resume_recovery'), findsNothing);
      } finally {
        if (!pending.isCompleted) pending.complete(null);
        await _settle(tester);
        unawaited(states.close());
        await _settle(tester);
        await _dispose(tester);
      }
    });
  }

  for (final invalidation in [
    'account',
    'account ABA',
    'preference ABA',
    'preview isolation',
    'background',
    'covered route',
    'app lock',
    'dispose',
  ]) {
    testWidgets('warm continuity cannot survive $invalidation', (tester) async {
      await launch(tester);
      final old = tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      final user = supabase.auth.currentUser;
      final pending = Completer<User?>();
      refresh = () => pending.future;
      try {
        _resume(tester);
        await tester.pump(const Duration(milliseconds: 16));
        _expectResumeContinuity(tester);
        switch (invalidation) {
          case 'account':
          case 'account ABA':
            await tester.runAsync(() async {
              await ZyraAccountState.synchronize(_member);
              if (invalidation == 'account ABA') {
                await ZyraAccountState.synchronize(_founder);
              }
            });
          case 'preference ABA':
            await tester.runAsync(() async {
              await ZyraLocalPrefs.bindAccount(_member);
              await ZyraLocalPrefs.bindAccount(_founder);
            });
          case 'preview isolation':
            ZyraInternalPreviewClient.finishSignOut();
          case 'background':
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
          case 'covered route':
            final context = tester.element(
              find.byType(ZyraFounderReviewSurface),
            );
            unawaited(
              Navigator.of(
                context,
              ).push<void>(MaterialPageRoute(builder: (_) => const Scaffold())),
            );
          case 'app lock':
            await tester.runAsync(() => ZyraLocalPrefs.setAppLockEnabled(true));
            ZyraAppLock.instance.hydrate();
          case 'dispose':
            await tester.pumpWidget(const SizedBox.shrink());
        }
        await tester.pump(const Duration(milliseconds: 32));
        expect(_key('founder_resume_continuity'), findsNothing);
        expect(old.canAct(), isFalse);
        expect(forwarded, 0);
        pending.complete(user);
        await _settle(tester);
        expect(_key('founder_resume_continuity'), findsNothing);
        expect(old.canAct(), isFalse);
        expect(forwarded, 0);
      } finally {
        if (!pending.isCompleted) pending.complete(null);
        ZyraAppLock.instance.clearForSignOut();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await _settle(tester);
        await _dispose(tester);
      }
    });
  }

  for (final dirty in ['paint', 'layout']) {
    testWidgets(
      'quiet refresh uses the last completed paint when current $dirty is dirty',
      (tester) async {
        await launch(tester);
        final old = tester.widget<ZyraOneJourneyConceptShell>(
          find.byType(ZyraOneJourneyConceptShell),
        );
        final capture = find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_FounderPreviewCapture',
        );
        final render = tester.renderObject<RenderRepaintBoundary>(capture);
        if (dirty == 'paint') {
          render.markNeedsPaint();
        } else {
          render.markNeedsLayout();
        }
        final pending = Completer<User?>();
        refresh = () => pending.future;
        try {
          _resume(tester);
          await tester.pump(const Duration(milliseconds: 16));
          _expectResumeContinuity(tester);
          expect(_key('founder_resume_status'), findsNothing);
          expect(_key('zyra_loading_golden_thread'), findsNothing);
          expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
          expect(ZyraConceptPreviewIsolation.active, isTrue);
          expect(ZyraInternalPreviewClient.isActive, isTrue);
          expect(old.canAct(), isFalse);
          old.onRoleChanged?.call(true);
          await tester.pump();
          _expectResumeContinuity(tester);
          expect(forwarded, 0);
          if (dirty == 'paint') {
            await _captureQuiet(tester, 'quiet_refresh_dirty_paint');
          }
        } finally {
          pending.complete(supabase.auth.currentUser);
          await _settle(tester);
          await _dispose(tester);
        }
      },
    );
  }

  testWidgets(
    'quiet refresh detached previous layer uses a quiet canvas and retires after fresh readiness',
    (tester) async {
      await launch(tester);
      tester.widget<FloatingNavBar>(find.byType(FloatingNavBar)).onTap(1);
      await _settle(tester);
      final old = tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      final capture = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_FounderPreviewCapture',
      );
      final render = tester.renderObject<RenderRepaintBoundary>(capture);
      // A removed completed layer is no longer owned by the visible scene.
      // The following lifecycle turn disposes this old candidate; it must not
      // reuse that detached layer merely because a size was recorded earlier.
      render.debugLayer!.remove();
      final pending = Completer<User?>();
      refresh = () => pending.future;
      try {
        _resume(tester);
        await tester.pump(const Duration(milliseconds: 100));
        _expectLongResumeQuiet(tester);
        expect(_key('founder_resume_status'), findsNothing);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(old.canAct(), isFalse);
        old.onRoleChanged?.call(true);
        expect(forwarded, 0);
        await _captureQuiet(tester, 'quiet_refresh_no_previous_layer');
        pending.complete(supabase.auth.currentUser);
        for (
          var frame = 0;
          frame < 30 &&
              _key('founder_resume_quiet_background').evaluate().isNotEmpty;
          frame++
        ) {
          await tester.pump(const Duration(milliseconds: 16));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          expect(_key('founder_resume_status'), findsNothing);
          expect(find.byType(ZyraLoading), findsNothing);
          expect(old.canAct(), isFalse);
        }
        expect(_key('founder_resume_quiet_background'), findsNothing);
        expect(_key('founder_resume_recovery'), findsNothing);
        expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
        expect(
          tester
              .widget<FloatingNavBar>(find.byType(FloatingNavBar))
              .currentIndex,
          1,
        );
        expect(old.canAct(), isFalse);
        expect(forwarded, 0);
      } finally {
        if (!pending.isCompleted) pending.complete(null);
        await _settle(tester);
        await _dispose(tester);
      }
    },
  );

  testWidgets(
    'quiet refresh repeated resumes join one exact ticket and retain only its passive frame',
    (tester) async {
      await launch(tester);
      final pending = Completer<User?>();
      var calls = 0;
      refresh = () {
        calls++;
        return pending.future;
      };
      try {
        _resume(tester);
        await tester.pump(const Duration(milliseconds: 16));
        _expectResumeContinuity(tester);
        final image = tester
            .widget<RawImage>(_key('founder_resume_continuity'))
            .image;
        final ticket = ZyraPreviewResumeTransition.changes.value;
        expect(ticket, isNotNull);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump(const Duration(milliseconds: 16));
        expect(_key('founder_resume_continuity'), findsNothing);
        expect(_key('founder_resume_status'), findsNothing);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump(const Duration(milliseconds: 16));
        expect(_key('founder_resume_continuity'), findsNothing);
        expect(_key('founder_resume_status'), findsNothing);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump(const Duration(milliseconds: 16));
        expect(calls, 1);
        _expectResumeContinuity(tester);
        expect(
          tester.widget<RawImage>(_key('founder_resume_continuity')).image,
          same(image),
        );
        expect(ZyraPreviewResumeTransition.changes.value, same(ticket));
        expect(_key('founder_resume_status'), findsNothing);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(forwarded, 0);
      } finally {
        pending.complete(supabase.auth.currentUser);
        await _settle(tester);
        await _dispose(tester);
      }
    },
  );

  testWidgets(
    'quiet refresh metrics change letterboxes the same passive image without a loading page',
    (tester) async {
      await launch(tester);
      final old = tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      final pending = Completer<User?>();
      refresh = () => pending.future;
      try {
        _resume(tester);
        await tester.pump(const Duration(milliseconds: 16));
        _expectResumeContinuity(tester);
        final image = tester
            .widget<RawImage>(_key('founder_resume_continuity'))
            .image;
        tester.view.physicalSize = const Size(844, 390);
        await tester.pump(const Duration(milliseconds: 16));
        _expectResumeContinuity(tester);
        final fitted = tester.widget<RawImage>(
          _key('founder_resume_continuity'),
        );
        expect(fitted.image, same(image));
        expect(fitted.fit, BoxFit.contain);
        expect(_key('founder_resume_status'), findsNothing);
        expect(_key('zyra_loading_golden_thread'), findsNothing);
        expect(old.canAct(), isFalse);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(forwarded, 0);
        expect(tester.takeException(), isNull);
      } finally {
        pending.complete(supabase.auth.currentUser);
        await _settle(tester);
        await _dispose(tester);
      }
    },
  );

  testWidgets(
    'quiet refresh shows no status before800ms and then only a compact Updating message',
    (tester) async {
      await launch(tester);
      final old = tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      final before = await preferenceSnapshot(tester);
      final pending = Completer<User?>();
      var calls = 0;
      refresh = () {
        calls++;
        return pending.future;
      };
      try {
        _resume(tester);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 799));
        _expectResumeContinuity(tester);
        expect(_key('founder_resume_status'), findsNothing);
        expect(find.text('Updating…'), findsNothing);
        await tester.pump(const Duration(milliseconds: 1));
        expect(_key('founder_resume_status'), findsOneWidget);
        expect(find.text('Updating…'), findsOneWidget);
        _expectResumeContinuity(tester);
        expect(_key('founder_resume_recovery'), findsNothing);
        final status = tester.getRect(_key('founder_resume_status'));
        expect(status.height, lessThan(140));
        expect(status.width, lessThanOrEqualTo(390));
        expect(old.canAct(), isFalse);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(ZyraInternalPreviewClient.isActive, isTrue);
        expect(calls, 1);
        expect(await preferenceSnapshot(tester), before);
        expect(forwarded, 0);
        await _captureQuiet(tester, 'quiet_refresh_updating');
      } finally {
        pending.complete(supabase.auth.currentUser);
        await _settle(tester);
        await _dispose(tester);
      }
    },
  );

  testWidgets(
    'quiet refresh completion before800ms has no status or artificial minimum dwell',
    (tester) async {
      await launch(tester);
      final old = tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      final pending = Completer<User?>();
      refresh = () => pending.future;
      try {
        _resume(tester);
        await tester.pump(const Duration(milliseconds: 100));
        _expectResumeContinuity(tester);
        expect(_key('founder_resume_status'), findsNothing);
        pending.complete(supabase.auth.currentUser);
        for (
          var frame = 0;
          frame < 30 && _key('founder_resume_continuity').evaluate().isNotEmpty;
          frame++
        ) {
          await tester.pump(const Duration(milliseconds: 16));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          expect(_key('founder_resume_status'), findsNothing);
          expect(find.byType(ZyraLoading), findsNothing);
          expect(old.canAct(), isFalse);
        }
        expect(_key('founder_resume_continuity'), findsNothing);
        expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
        expect(_key('founder_resume_status'), findsNothing);
        expect(_key('founder_resume_recovery'), findsNothing);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
        expect(old.canAct(), isFalse);
        expect(forwarded, 0);
      } finally {
        if (!pending.isCompleted) pending.complete(null);
        await _settle(tester);
        await _dispose(tester);
      }
    },
  );

  testWidgets(
    'quiet refresh unresolved proof recovery never starts parallel auth or exposes actions',
    (tester) async {
      await launch(tester);
      final old = tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      var calls = 0;
      refresh = () async {
        calls++;
        return supabase.auth.currentUser;
      };
      // This deliberately drives only the presentation ticket. A real refresh
      // already owns its own timeout and error navigation; this isolates the
      // recovery UI's refusal to dispatch a second authorization operation.
      final ticket = ZyraPreviewResumeTransition.begin(
        ownerId: _founder,
        accountGeneration: ZyraAccountState.generation,
        preferenceGeneration: ZyraLocalPrefs.bindingGeneration,
      );
      ZyraDeveloperAccess.clearRefreshedClaims();
      try {
        await tester.pump(const Duration(milliseconds: 800));
        expect(_key('founder_resume_status'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 9200));
        expect(_key('founder_resume_recovery'), findsOneWidget);
        expect(_key('founder_resume_continuity'), findsNothing);
        expect(_key('zyra_loading_golden_thread'), findsNothing);
        expect(find.byType(ZyraLoading), findsNothing);
        expect(
          tester
              .widget<ButtonStyleButton>(_key('founder_resume_retry'))
              .onPressed,
          isNull,
        );
        expect(_key('founder_resume_home'), findsNothing);
        expect(ZyraPreviewResumeTransition.changes.value, same(ticket));
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(old.canAct(), isFalse);
        expect(calls, 0);
        expect(forwarded, 0);
      } finally {
        ZyraPreviewResumeTransition.end(ticket);
        await _settle(tester);
        await _dispose(tester);
      }
    },
  );

  testWidgets(
    'quiet refresh joined resumes cannot restart the same ticket ten-second presentation deadline',
    (tester) async {
      await tester.runAsync(ZyraDeveloperAccess.refreshCurrentAuthorization);
      ZyraInternalPreviewClient.beginPreview();
      final pending = Completer<bool>();
      var calls = 0;
      await mount(
        tester,
        ZyraFounderReviewSurface(
          ownerId: _founder,
          ownerGeneration: ZyraAccountState.generation,
        ),
        resumeRefresh: () {
          calls++;
          // Isolate presentation's deadline from the real Auth operation's
          // separate timeout. The mock retracts proof and never grants it.
          ZyraDeveloperAccess.clearRefreshedClaims();
          return pending.future;
        },
      );
      final old = tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      try {
        _resume(tester);
        await tester.pump(const Duration(seconds: 9));
        _expectResumeContinuity(tester);
        final ticket = ZyraPreviewResumeTransition.changes.value;
        expect(ticket, isNotNull);
        expect(_key('founder_resume_status'), findsOneWidget);
        _resume(tester);
        await tester.pump(const Duration(seconds: 1));
        expect(ZyraPreviewResumeTransition.changes.value, same(ticket));
        expect(calls, 1);
        expect(_key('founder_resume_recovery'), findsOneWidget);
        expect(_key('founder_resume_continuity'), findsNothing);
        expect(_key('zyra_loading_golden_thread'), findsNothing);
        expect(
          tester
              .widget<ButtonStyleButton>(_key('founder_resume_retry'))
              .onPressed,
          isNull,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump(const Duration(milliseconds: 16));
        expect(_key('founder_resume_recovery'), findsNothing);
        expect(_key('founder_resume_status'), findsNothing);
        expect(_key('founder_resume_continuity'), findsNothing);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump(const Duration(milliseconds: 16));
        expect(calls, 1);
        expect(_key('founder_resume_recovery'), findsOneWidget);
        expect(_key('founder_resume_continuity'), findsNothing);
        expect(old.canAct(), isFalse);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(forwarded, 0);
      } finally {
        pending.complete(false);
        await _settle(tester);
        await _dispose(tester);
      }
    },
  );

  testWidgets(
    'quiet refresh photo-stall recovery retries only local preparation and revokes old delegates',
    (tester) async {
      await launch(tester);
      tester.widget<FloatingNavBar>(find.byType(FloatingNavBar)).onTap(1);
      await _settle(tester);
      final initial = tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      final before = await preferenceSnapshot(tester);
      var calls = 0;
      refresh = () async {
        calls++;
        return supabase.auth.currentUser;
      };
      await _withHeldBrowsePhotos(tester, (photos) async {
        _resume(tester);
        await _settle(tester);
        final first = tester.widget<ZyraOneJourneyConceptShell>(
          find.byType(ZyraOneJourneyConceptShell),
        );
        expect(initial.canAct(), isFalse);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
        expect(ZyraPreviewResumeTransition.changes.value, isNull);
        await tester.pump(const Duration(seconds: 10));
        expect(_key('founder_resume_recovery'), findsOneWidget);
        expect(_key('founder_resume_continuity'), findsNothing);
        expect(find.byType(ZyraLoading), findsNothing);
        await _captureQuiet(tester, 'quiet_refresh_recovery_standard');
        expect(find.textContaining('checking access'), findsNothing);
        expect(find.text('Preview access needs checking.'), findsNothing);
        final notice = tester.getRect(_key('founder_resume_recovery'));
        expect(notice.top, greaterThan(390));
        await _captureQuiet(
          tester,
          'quiet_access_waiting_ready',
          directory: _accessCaptureDirectory,
        );
        final retry = tester
            .widget<ButtonStyleButton>(_key('founder_resume_retry'))
            .onPressed;
        expect(_key('founder_resume_home'), findsNothing);
        expect(retry, isNotNull);
        retry!();
        await tester.pump();
        expect(_key('founder_resume_recovery'), findsNothing);
        expect(find.byType(ZyraLoading), findsNothing);
        final replacement = tester.widget<ZyraOneJourneyConceptShell>(
          find.byType(ZyraOneJourneyConceptShell),
        );
        expect(identical(first, replacement), isFalse);
        expect(first.canAct(), isFalse);
        first.onPresentationReady?.call();
        retry();
        await tester.pump();
        expect(
          tester.widget<ZyraOneJourneyConceptShell>(
            find.byType(ZyraOneJourneyConceptShell),
          ),
          same(replacement),
        );
        expect(
          find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == 'DeveloperAccessScreen',
          ),
          findsNothing,
        );
        expect(find.byType(HomeShell), findsNothing);
        expect(calls, 1);
        expect(await preferenceSnapshot(tester), before);
        expect(forwarded, 0);
        photos.complete();
        await _settle(tester);
        expect(_key('founder_resume_recovery'), findsNothing);
        expect(_key('founder_resume_status'), findsNothing);
        expect(_key('founder_resume_quiet_background'), findsNothing);
        expect(
          tester
              .widget<FloatingNavBar>(find.byType(FloatingNavBar))
              .currentIndex,
          1,
        );
        expect(initial.canAct(), isFalse);
        expect(first.canAct(), isFalse);
        expect(forwarded, 0);
      });
      await _dispose(tester);
    },
  );

  testWidgets(
    'quiet refresh photo-stall recovery has no Developer Home and retains guarded retry',
    (tester) async {
      await launch(tester);
      await _withHeldBrowsePhotos(tester, (photos) async {
        _resume(tester);
        await _settle(tester);
        await tester.pump(const Duration(seconds: 10));
        expect(_key('founder_resume_recovery'), findsOneWidget);
        expect(_key('founder_resume_home'), findsNothing);
        expect(_key('founder_resume_retry'), findsOneWidget);
        expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
        expect(ZyraConceptPreviewIsolation.active, isTrue);
        expect(ZyraInternalPreviewClient.isActive, isTrue);
        expect(forwarded, 0);
        photos.complete();
      });
      await _dispose(tester);
    },
  );

  for (final invalidation in [
    'account ABA',
    'preference ABA',
    'covered route',
    'app lock',
    'dispose',
  ]) {
    testWidgets(
      'quiet refresh retained recovery actions cannot survive $invalidation',
      (tester) async {
        await launch(tester);
        await _withHeldBrowsePhotos(tester, (photos) async {
          _resume(tester);
          await _settle(tester);
          final stalled = tester.element(find.byType(ViewRequestDraftScreen));
          await tester.pump(const Duration(seconds: 10));
          expect(_key('founder_resume_recovery'), findsOneWidget);
          final retry = tester
              .widget<ButtonStyleButton>(_key('founder_resume_retry'))
              .onPressed!;
          expect(_key('founder_resume_home'), findsNothing);
          final before = await preferenceSnapshot(tester);
          NavigatorState? cover;
          switch (invalidation) {
            case 'account ABA':
              await tester.runAsync(() async {
                await ZyraAccountState.synchronize(_member);
                await ZyraAccountState.synchronize(_founder);
              });
            case 'preference ABA':
              await tester.runAsync(() async {
                await ZyraLocalPrefs.bindAccount(_member);
                await ZyraLocalPrefs.bindAccount(_founder);
              });
            case 'covered route':
              cover = Navigator.of(
                tester.element(find.byType(ZyraFounderReviewSurface)),
              );
              unawaited(
                cover.push<void>(
                  MaterialPageRoute(
                    builder: (_) =>
                        const Scaffold(body: Text('Synthetic covering route')),
                  ),
                ),
              );
            case 'app lock':
              await _writePreference(
                tester,
                () => ZyraLocalPrefs.setAppLockEnabled(true),
              );
              ZyraAppLock.instance.hydrate();
            case 'dispose':
              await tester.pumpWidget(const SizedBox.shrink());
          }
          await tester.pump(const Duration(milliseconds: 300));
          retry();
          await tester.pump();
          expect(
            find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == 'DeveloperAccessScreen',
            ),
            findsNothing,
          );
          expect(find.byType(HomeShell), findsNothing);
          expect(find.byType(WaliHomeShell), findsNothing);
          expect(forwarded, 0);
          if (invalidation == 'covered route') {
            expect(find.text('Synthetic covering route'), findsOneWidget);
            cover!.pop();
            await tester.pump(const Duration(milliseconds: 300));
            expect(stalled.mounted, isFalse);
            final returned = tester.element(
              find.byType(ViewRequestDraftScreen),
            );
            expect(returned.mounted, isTrue);
            expect(returned, isNot(same(stalled)));
            // A→cover→A cannot authorize the delegate captured before cover.
            // The legitimate return replaces an unready owner; stale actions
            // must not replace that fresh owner a second time.
            retry();
            await tester.pump();
            expect(
              tester.element(find.byType(ViewRequestDraftScreen)),
              same(returned),
            );
            expect(
              find.byWidgetPredicate(
                (w) => w.runtimeType.toString() == 'DeveloperAccessScreen',
              ),
              findsNothing,
            );
            expect(await preferenceSnapshot(tester), before);
          }
          photos.complete();
          ZyraAppLock.instance.clearForSignOut();
          await _settle(tester);
          retry();
          await tester.pump();
          expect(
            find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == 'DeveloperAccessScreen',
            ),
            findsNothing,
          );
          expect(forwarded, 0);
        });
        await _dispose(tester);
      },
    );
  }

  testWidgets(
    'quiet refresh compact200percent status and recovery stay readable with guarded reachable actions',
    (tester) async {
      final destination = await tester.runAsync(ZyraSessionRouter.resolveHome);
      await mount(
        tester,
        destination!,
        viewport: const Size(320, 568),
        textScale: 2,
      );
      final old = tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      // Always drain this fixture's preference queue, including when a
      // readiness assertion fails, before the next FakeAsync test starts.
      try {
        await _withHeldBrowsePhotos(tester, (photos) async {
          _resume(tester);
          await _settle(tester);
          expect(_key('founder_resume_status'), findsOneWidget);
          expect(find.text('Updating…'), findsOneWidget);
          final status = tester.getRect(_key('founder_resume_status'));
          expect(status.left, greaterThanOrEqualTo(0));
          expect(status.right, lessThanOrEqualTo(320));
          expect(status.top, greaterThanOrEqualTo(0));
          expect(status.bottom, lessThanOrEqualTo(568));
          expect(_key('zyra_loading_golden_thread'), findsNothing);
          expect(tester.takeException(), isNull);
          await _captureQuiet(tester, 'quiet_refresh_updating_compact200');
          await tester.pump(const Duration(seconds: 10));
          expect(_key('founder_resume_recovery'), findsOneWidget);
          expect(_key('founder_resume_continuity'), findsNothing);
          expect(find.byType(ZyraLoading), findsNothing);
          await _captureQuiet(tester, 'quiet_refresh_recovery_compact200_top');
          await _captureQuiet(
            tester,
            'quiet_access_waiting_compact200_top',
            directory: _accessCaptureDirectory,
          );
          for (final action in ['founder_resume_retry']) {
            await tester.ensureVisible(_key(action));
            await tester.pump();
            expect(_key(action).hitTestable(), findsOneWidget);
            expect(
              tester.widget<ButtonStyleButton>(_key(action)).onPressed,
              isNotNull,
            );
            final rect = tester.getRect(_key(action));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(320));
            expect(rect.top, greaterThanOrEqualTo(0));
            expect(rect.bottom, lessThanOrEqualTo(568));
          }
          expect(old.canAct(), isFalse);
          expect(forwarded, 0);
          expect(tester.takeException(), isNull);
          await _captureQuiet(tester, 'quiet_refresh_recovery_compact200');
          await _captureQuiet(
            tester,
            'quiet_access_waiting_compact200_actions',
            directory: _accessCaptureDirectory,
          );
          photos.complete();
          await _settle(tester);
          await _waitForReleasedPhotoSurface(tester, 'founder_resume_recovery');
          expect(_key('founder_resume_recovery'), findsNothing);
          expect(_key('founder_resume_status'), findsNothing);
          expect(old.canAct(), isFalse);
          expect(forwarded, 0);
        });
      } finally {
        await _dispose(tester);
      }
    },
  );

  testWidgets('warm handover waits for prepared photos and their fresh paint', (
    tester,
  ) async {
    await launch(tester);
    final old = tester.widget<ZyraOneJourneyConceptShell>(
      find.byType(ZyraOneJourneyConceptShell),
    );
    final assets = <String, ByteData>{};
    await tester.runAsync(() async {
      for (final name in [
        ...ZyraOneJourneySamplePhotos.seeds.expand((group) => group),
        'seeker_self',
        'guardian_self',
      ]) {
        final key = 'assets/dev/one_journey_photos/$name.jpg';
        assets[key] = await rootBundle.load(key);
      }
    });
    final photos = Completer<void>();
    final previousGate = _heldBrowsePhotoGate;
    _heldBrowsePhotoGate = photos;
    final authorization = Completer<User?>();
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final name = utf8.decode(
        message!.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        ),
      );
      if (!assets.containsKey(name)) return null;
      await photos.future;
      return assets[name];
    });
    refresh = () => authorization.future;
    try {
      _resume(tester);
      await tester.pump(const Duration(milliseconds: 16));
      _expectResumeContinuity(tester);
      authorization.complete(supabase.auth.currentUser);
      await _settle(tester);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
      expect(_key('founder_resume_continuity'), findsOneWidget);
      expect(old.canAct(), isFalse);
      expect(find.byType(ZyraLoading), findsNothing);
      photos.complete();
      await _settle(tester);
      await _waitForReleasedPhotoSurface(tester, 'founder_resume_continuity');
      expect(_key('founder_resume_continuity'), findsNothing);
      expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
      expect(old.canAct(), isFalse);
      expect(forwarded, 0);
    } finally {
      if (!authorization.isCompleted) authorization.complete(null);
      if (!photos.isCompleted) photos.complete();
      messenger.setMockMessageHandler('flutter/assets', null);
      try {
        await _settle(tester);
      } finally {
        try {
          await _dispose(tester);
        } finally {
          _heldBrowsePhotoGate = previousGate;
        }
      }
    }
  });

  for (final wait in [
    const Duration(milliseconds: 500),
    const Duration(seconds: 3),
  ]) {
    for (final reducedMotion in [false, true]) {
      final description =
          '${wait.inMilliseconds}ms ${reducedMotion ? 'still' : 'moving'}';
      testWidgets(
        'pending first-open $description stays quietly loading without proof, forwarding or preference writes',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            ZyraDeveloperAccess.clearRefreshedClaims();
            final preferencesBefore = await preferenceSnapshot(tester);
            final pending = Completer<User?>();
            var refreshCalls = 0;
            refresh = () {
              refreshCalls++;
              return pending.future;
            };
            await mount(
              tester,
              ZyraFounderLaunchScreen(
                ownerId: _founder,
                ownerGeneration: ZyraAccountState.generation,
              ),
              settle: false,
              disableAnimations: reducedMotion,
            );
            await tester.pump(wait);
            _expectQuietLoading(tester);
            expect(find.bySemanticsLabel('Loading ZYRA'), findsNothing);
            expect(
              find.bySemanticsLabel('Updating ZYRA'),
              wait.inMilliseconds >= 800 ? findsOneWidget : findsNothing,
            );
            expect(refreshCalls, 1);
            expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
            expect(ZyraInternalPreviewClient.isActive, isFalse);
            expect(ZyraConceptPreviewIsolation.active, isFalse);
            expect(find.byType(ZyraFounderReviewSurface), findsNothing);
            expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
            expect(find.byType(HomeShell), findsNothing);
            expect(find.byType(WaliHomeShell), findsNothing);
            expect(_key('founder_launch_retry'), findsNothing);
            expect(await preferenceSnapshot(tester), preferencesBefore);
            expect(forwarded, 0);
            await _captureQuiet(tester, 'first-open-$description');

            pending.complete(supabase.auth.currentUser);
            await _settle(tester);
            expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
            expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
            expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
            expect(ZyraInternalPreviewClient.isActive, isTrue);
            expect(ZyraConceptPreviewIsolation.active, isTrue);
            expect(forwarded, 0);
            await _dispose(tester);
          } finally {
            semantics.dispose();
          }
        },
      );

      testWidgets(
        'pending resume $description holds isolation and passive continuity until fresh proof replaces the owner',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            final destination = await tester.runAsync(
              ZyraSessionRouter.resolveHome,
            );
            expect(destination, isA<ZyraFounderLaunchScreen>());
            await mount(tester, destination!, disableAnimations: reducedMotion);
            final old = tester.widget<ZyraOneJourneyConceptShell>(
              find.byType(ZyraOneJourneyConceptShell),
            );
            final preferencesBefore = await preferenceSnapshot(tester);
            final pending = Completer<User?>();
            var refreshCalls = 0;
            refresh = () {
              refreshCalls++;
              return pending.future;
            };
            _resume(tester);
            await tester.pump(wait);
            _expectResumeContinuity(tester);
            expect(find.bySemanticsLabel('Checking access'), findsOneWidget);
            expect(refreshCalls, 1);
            expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
            expect(ZyraConceptPreviewIsolation.active, isTrue);
            expect(ZyraInternalPreviewClient.isActive, isTrue);
            expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
            expect(find.byType(HomeShell), findsNothing);
            expect(find.byType(WaliHomeShell), findsNothing);
            expect(old.canAct(), isFalse);
            old.onRoleChanged!(true);
            await tester.pump();
            _expectResumeContinuity(tester);
            expect(await preferenceSnapshot(tester), preferencesBefore);
            expect(forwarded, 0);
            await _captureQuiet(tester, 'resume-$description');

            pending.complete(supabase.auth.currentUser);
            await _settle(tester);
            final replacement = tester.widget<ZyraOneJourneyConceptShell>(
              find.byType(ZyraOneJourneyConceptShell),
            );
            expect(identical(old, replacement), isFalse);
            expect(replacement.canAct(), isTrue);
            expect(old.canAct(), isFalse);
            expect(ZyraConceptPreviewIsolation.active, isTrue);
            expect(ZyraInternalPreviewClient.isActive, isTrue);
            expect(ZyraLocalPrefs.cachedFounderPreviewRole, 'seeker');
            expect(await preferenceSnapshot(tester), preferencesBefore);
            expect(forwarded, 0);
            await _dispose(tester);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  for (final failure in ['denied', 'failed refresh']) {
    testWidgets(
      'quiet first-open $failure preserves the truthful retry without member fallback',
      (tester) async {
        ZyraDeveloperAccess.clearRefreshedClaims();
        final preferencesBefore = await preferenceSnapshot(tester);
        final pending = Completer<User?>();
        refresh = () => pending.future;
        await mount(
          tester,
          ZyraFounderLaunchScreen(
            ownerId: _founder,
            ownerGeneration: ZyraAccountState.generation,
          ),
          settle: false,
        );
        await tester.pump(const Duration(seconds: 3));
        _expectQuietLoading(tester);
        if (failure == 'denied') {
          pending.complete(null);
        } else {
          pending.completeError(
            StateError('Synthetic pending refresh failure'),
          );
        }
        await _settle(tester);
        expect(find.text('Couldn’t open this page.'), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(_key('founder_launch_retry'), findsOneWidget);
        expect(find.byType(ZyraFounderReviewSurface), findsNothing);
        expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
        expect(find.byType(HomeShell), findsNothing);
        expect(find.byType(WaliHomeShell), findsNothing);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(ZyraInternalPreviewClient.isActive, isFalse);
        expect(ZyraConceptPreviewIsolation.active, isFalse);
        expect(await preferenceSnapshot(tester), preferencesBefore);
        expect(forwarded, 0);

        refresh = () async => supabase.auth.currentUser;
        await _press(tester, 'founder_launch_retry');
        expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
        expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
        expect(find.byType(HomeShell), findsNothing);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
        expect(ZyraInternalPreviewClient.isActive, isTrue);
        expect(forwarded, 0);
        await _dispose(tester);
      },
    );
  }

  for (final stale in ['identity', 'generation']) {
    testWidgets(
      'a stale launch $stale stays denied even with a quiet loading presentation',
      (tester) async {
        final preferencesBefore = await preferenceSnapshot(tester);
        var refreshCalls = 0;
        refresh = () async {
          refreshCalls++;
          return supabase.auth.currentUser;
        };
        await mount(
          tester,
          ZyraFounderLaunchScreen(
            ownerId: stale == 'identity' ? _member : _founder,
            ownerGeneration:
                ZyraAccountState.generation - (stale == 'generation' ? 1 : 0),
          ),
          settle: false,
        );
        await tester.pump(const Duration(seconds: 3));
        _expectQuietLoading(tester);
        expect(refreshCalls, 0);
        expect(find.byType(ZyraFounderReviewSurface), findsNothing);
        expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
        expect(find.byType(HomeShell), findsNothing);
        expect(find.byType(WaliHomeShell), findsNothing);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(ZyraInternalPreviewClient.isActive, isFalse);
        expect(ZyraConceptPreviewIsolation.active, isFalse);
        expect(await preferenceSnapshot(tester), preferencesBefore);
        expect(forwarded, 0);
        await _dispose(tester);
      },
    );
  }

  testWidgets(
    'fresh Founder launch opens Default without member data or identity persistence',
    (tester) async {
      await tester.runAsync(() async {
        ZyraLocalPrefs.setCachedFirstName('Account name stays on disk');
        await ZyraLocalPrefs.bindAccount(_founder);
      });
      await launch(tester);

      expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
      expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
      expect(find.byType(EditPhotosScreen), findsNothing);
      expect(
        tester.widget<FloatingNavBar>(find.byType(FloatingNavBar)).currentIndex,
        0,
        reason: 'A fresh process keeps the normal Browse entry point.',
      );
      expect(ZyraInternalPreviewClient.isActive, isTrue);
      expect(ZyraConceptPreviewIsolation.active, isTrue);
      final prefs = await tester.runAsync(SharedPreferences.getInstance);
      expect(
        prefs!.getString('zyra.cached_first_name'),
        'Account name stays on disk',
      );
      expect(prefs.getString('ordinary-setting'), 'preserved');
      expect(forwarded, 0);
      await _dispose(tester);
    },
  );

  for (final guardian in [false, true]) {
    testWidgets(
      'cold launch opens Seeker after the former ${guardian ? 'Guardian' : 'Seeker'} selection',
      (tester) async {
        await tester.runAsync(() async {
          await ZyraLocalPrefs.setFounderPreviewRole(
            guardian ? 'guardian' : 'seeker',
            expectedOwner: _founder,
            expectedBindingGeneration: ZyraLocalPrefs.bindingGeneration,
          );
          // Cold preference rebind must not reuse the visible owner cache.
          ZyraDeveloperAccess.clearRefreshedClaims();
          ZyraAccountState.resetForTesting();
          await ZyraLocalPrefs.init();
          await ZyraAccountState.synchronize(_founder);
        });

        await launch(tester);

        expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
        expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
        expect(find.byType(HomeShell), findsNothing);
        expect(find.byType(WaliHomeShell), findsNothing);
        expect(
          tester
              .widget<ZyraOneJourneyConceptShell>(
                find.byType(ZyraOneJourneyConceptShell),
              )
              .initialGuardianRole,
          isFalse,
        );
        expect(ZyraLocalPrefs.cachedFounderPreviewRole, 'seeker');
        final prefs = await tester.runAsync(SharedPreferences.getInstance);
        expect(prefs!.getString(_roleKey), 'seeker');
        expect(ZyraInternalPreviewClient.isActive, isTrue);
        expect(forwarded, 0);
        await _dispose(tester);
      },
    );
  }

  for (final guardian in [false, true]) {
    testWidgets(
      'Seeker presentation remains default across cold relaunch after former ${guardian ? 'Guardian' : 'Seeker'} input',
      (tester) async {
        await tester.runAsync(
          () => ZyraLocalPrefs.setFounderPreviewRole(
            guardian ? 'guardian' : 'seeker',
            expectedOwner: _founder,
            expectedBindingGeneration: ZyraLocalPrefs.bindingGeneration,
          ),
        );
        for (var launchIndex = 0; launchIndex < 2; launchIndex++) {
          await launch(tester);
          expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
          expect(
            tester
                .widget<ZyraOneJourneyConceptShell>(
                  find.byType(ZyraOneJourneyConceptShell),
                )
                .initialGuardianRole,
            isFalse,
          );
          expect(find.byType(HomeShell), findsNothing);
          expect(find.byType(WaliHomeShell), findsNothing);
          expect(ZyraLocalPrefs.cachedFounderPreviewRole, 'seeker');

          if (launchIndex == 0) {
            // Dispose the process-local presentation, then rebind the same
            // synthetic authenticated owner from disk as cold startup does.
            // The next launch receives a fresh owner and keeps the default
            // Seeker presentation after the retired role-selector input.
            await tester.pumpWidget(const SizedBox.shrink());
            await _settle(tester);
            expect(ZyraConceptPreviewIsolation.active, isFalse);
            var rebound = false;
            Object? rebindError;
            await tester.runAsync(() async {
              // The last presentation write may have a completed Future
              // whose callback still belongs to this widget's FakeAsync
              // zone. Start real-zone restoration without blocking the
              // pumps that drain that old queue, then bound the wait below.
              unawaited(
                (() async {
                  ZyraDeveloperAccess.clearRefreshedClaims();
                  ZyraAccountState.resetForTesting();
                  await ZyraLocalPrefs.init();
                  await ZyraAccountState.synchronize(_founder);
                })().then<void>(
                  (_) {
                    rebound = true;
                  },
                  onError: (Object error) {
                    rebindError = error;
                  },
                ),
              );
            });
            for (
              var frame = 0;
              frame < 20 && !rebound && rebindError == null;
              frame++
            ) {
              await tester.pump();
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 1)),
              );
            }
            expect(rebindError, isNull);
            expect(rebound, isTrue, reason: 'Cold rebind drains both zones');
            expect(ZyraLocalPrefs.cachedFounderPreviewRole, 'seeker');
          }
        }
        expect(forwarded, 0);
        await _dispose(tester);
      },
    );
  }

  testWidgets(
    'former Guardian preview selection cannot change the default Seeker presentation',
    (tester) async {
      await tester.runAsync(
        () => ZyraLocalPrefs.setFounderPreviewRole(
          'guardian',
          expectedOwner: _founder,
          expectedBindingGeneration: ZyraLocalPrefs.bindingGeneration,
        ),
      );
      await launch(tester);
      final shell = tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      expect(shell.initialGuardianRole, isFalse);
      expect(shell.initialSeekerBasic, isFalse);
      expect(find.byKey(const ValueKey('draft_reset')), findsNothing);
      expect(ZyraLocalPrefs.cachedFounderPreviewRole, 'seeker');
      expect(find.byType(HomeShell), findsNothing);
      expect(find.byType(WaliHomeShell), findsNothing);
      expect(forwarded, 0);
      await _dispose(tester);
    },
  );

  testWidgets(
    'Developer Home is absent while the current presentation role is preserved',
    (tester) async {
      await launch(tester);
      final before = ZyraLocalPrefs.cachedFounderPreviewRole;
      expect(find.byKey(const ValueKey('draft_close')), findsNothing);
      final finger = await tester.startGesture(const Offset(215, 70));
      await tester.pump(const Duration(seconds: 4));
      await finger.up();
      await tester.pump();
      expect(find.byKey(const ValueKey('dev_controls_page')), findsNothing);
      expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
      expect(ZyraLocalPrefs.cachedFounderPreviewRole, before);
      expect(ZyraInternalPreviewClient.isActive, isTrue);
      expect(forwarded, 0);
      await _dispose(tester);
    },
  );

  testWidgets(
    'resume keeps isolation and replaces authority owner without reviving old callbacks',
    (tester) async {
      await launch(tester);
      final old = tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      final oldRole = old.onRoleChanged!;
      final pending = Completer<User?>();
      refresh = () => pending.future;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      _expectResumeContinuity(tester);
      expect(ZyraConceptPreviewIsolation.active, isTrue);
      expect(ZyraInternalPreviewClient.isActive, isTrue);
      expect(old.canAct(), isFalse);
      oldRole(true);
      pending.complete(supabase.auth.currentUser);
      await _settle(tester);

      final replacement = tester.widget<ZyraOneJourneyConceptShell>(
        find.byType(ZyraOneJourneyConceptShell),
      );
      expect(identical(old, replacement), isFalse);
      expect(replacement.canAct(), isTrue);
      expect(old.canAct(), isFalse);
      oldRole(true);
      await _settle(tester);
      expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == 'DeveloperAccessScreen',
        ),
        findsNothing,
      );
      expect(ZyraLocalPrefs.cachedFounderPreviewRole, 'seeker');
      expect(forwarded, 0);
      await _dispose(tester);
    },
  );

  testWidgets(
    'failed launch refresh holds locally without member fallback or preference change',
    (tester) async {
      await tester.runAsync(() async {
        await ZyraDeveloperAccess.refreshCurrentAuthorizationSnapshot();
      });
      refresh = () async => throw StateError('Synthetic refresh failure');
      await mount(
        tester,
        ZyraFounderLaunchScreen(
          ownerId: _founder,
          ownerGeneration: ZyraAccountState.generation,
        ),
      );

      expect(find.text('Couldn’t open this page.'), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
      expect(find.byType(WaliHomeShell), findsNothing);
      expect(find.byType(ZyraOneJourneyConceptShell), findsNothing);
      expect(ZyraInternalPreviewClient.isActive, isFalse);
      expect(forwarded, 0);
      await _dispose(tester);
    },
  );

  for (final role in ['seeker', 'wali']) {
    test(
      'ordinary $role routing ignores copied presentation role and spoofed Founder display metadata',
      () async {
        ZyraInternalPreviewClient.finishSignOut();
        await _session(_member);
        await ZyraAccountState.synchronize(_member);
        await ZyraLocalPrefs.setFounderPreviewRole(
          'guardian',
          expectedOwner: _member,
          expectedBindingGeneration: ZyraLocalPrefs.bindingGeneration,
        );
        ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(false);
        ordinaryRole = role;

        final destination = await ZyraSessionRouter.resolveHome();

        expect(
          destination,
          role == 'wali' ? isA<WaliHomeShell>() : isA<HomeShell>(),
        );
        expect(destination, isNot(isA<ZyraFounderLaunchScreen>()));
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(ZyraInternalPreviewClient.isActive, isFalse);
        expect(forwardedPaths, contains('/rest/v1/profiles'));
        // Drain the ordinary router's existing non-blocking decision hydration.
        await Future<void>.delayed(Duration.zero);
      },
    );
  }

  test(
    'stale preference owner and A-B-A binding cannot persist a presentation role',
    () async {
      final oldBinding = ZyraLocalPrefs.bindingGeneration;
      await ZyraLocalPrefs.bindAccount(_member);
      await ZyraLocalPrefs.bindAccount(_founder);
      await ZyraLocalPrefs.setFounderPreviewRole(
        'guardian',
        expectedOwner: _founder,
        expectedBindingGeneration: oldBinding,
      );
      expect(ZyraLocalPrefs.cachedFounderPreviewRole, 'seeker');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_roleKey), isNull);
      expect(forwarded, 0);
      expect(AppState.instance.activeJourneys, isEmpty);
    },
  );
}
