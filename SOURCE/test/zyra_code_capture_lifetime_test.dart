// Exercises the real shared capture widget and pinned MobileScanner bridge
// offline. A fake native platform is not proof of physical-camera acceptance.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_known_person_code_content.dart';

const _manualKey = ValueKey('known-person-camera-manual-entry');
const _nativeViewKey = ValueKey('fake-native-code-camera');
const _viewAttributes = MobileScannerViewAttributes(
  cameraDirection: CameraFacing.back,
  currentTorchMode: TorchState.unavailable,
  size: Size(640, 480),
  numberOfCameras: 1,
  initialDeviceOrientation: DeviceOrientation.portraitUp,
);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    ++attempts;
    throw StateError('Native capture tests must remain offline.');
  }
}

class _FakeScannerPlatform extends MobileScannerPlatform {
  final _barcodes = StreamController<BarcodeCapture?>.broadcast(sync: true);
  final _torch = StreamController<TorchState>.broadcast(sync: true);
  final _zoom = StreamController<double>.broadcast(sync: true);
  final operations = <String>[];
  final startOptions = <StartOptions>[];
  Object? startError;
  Completer<MobileScannerViewAttributes>? pendingStart;
  bool running = false;
  int stops = 0;
  int disposals = 0;

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;

  @override
  Stream<TorchState> get torchStateStream => _torch.stream;

  @override
  Stream<double> get zoomScaleStateStream => _zoom.stream;

  @override
  Future<MobileScannerViewAttributes> start(StartOptions options) async {
    operations.add('start');
    startOptions.add(options);
    final gate = pendingStart;
    final attributes = gate == null ? _viewAttributes : await gate.future;
    final error = startError;
    if (error != null) throw error;
    running = true;
    return attributes;
  }

  @override
  Future<void> stop() async {
    operations.add('stop');
    ++stops;
    running = false;
  }

  @override
  Future<void> dispose() async {
    operations.add('dispose');
    ++disposals;
    running = false;
  }

  @override
  Widget buildCameraView() =>
      const ColoredBox(key: _nativeViewKey, color: Colors.black);

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  void emit(Iterable<String?> values) {
    _barcodes.add(
      BarcodeCapture(
        barcodes: [for (final value in values) Barcode(rawValue: value)],
      ),
    );
  }

  void emitError() {
    _barcodes.addError(
      const MobileScannerBarcodeException('Fake frame processing failure.'),
    );
  }

  void releasePendingStart() {
    final gate = pendingStart;
    if (gate != null && !gate.isCompleted) gate.complete(_viewAttributes);
  }

  Future<void> closeStreams() async {
    await Future.wait([_barcodes.close(), _torch.close(), _zoom.close()]);
  }
}

Widget _app(Widget capture, {GlobalKey<NavigatorState>? navigatorKey}) =>
    MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData.dark(),
      home: Scaffold(body: capture),
    );

Future<void> _flush(WidgetTester tester) async {
  for (var frame = 0; frame < 5; ++frame) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _mount(
  WidgetTester tester,
  _FakeScannerPlatform platform, {
  required bool Function() canCapture,
  required ValueChanged<String> onCode,
  required VoidCallback onManualEntry,
  GlobalKey<NavigatorState>? navigatorKey,
}) async {
  addTearDown(() async {
    platform.releasePendingStart();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox.shrink());
    await _flush(tester);
    expect(tester.takeException(), isNull);
  });
  await tester.pumpWidget(
    _app(
      ZyraCodeCapture(
        canCapture: canCapture,
        onCode: onCode,
        onManualEntry: onManualEntry,
      ),
      navigatorKey: navigatorKey,
    ),
  );
  await _flush(tester);
  expect(tester.takeException(), isNull);
}

VoidCallback _manualCallback(WidgetTester tester) =>
    tester.widget<ZyraKnownPersonCodePill>(find.byKey(_manualKey)).onTap!;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final priorPlatform = MobileScannerPlatform.instance;
  final priorHttp = HttpOverrides.current;
  final priorStubs = ZyraText.useTestFontStubs;
  final priorFatal = WidgetController.hitTestWarningShouldBeFatal;
  late _FakeScannerPlatform platform;
  late _NoNetwork network;

  setUp(() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    MobileScannerController.resetPlatformSessionOwner();
    platform = _FakeScannerPlatform();
    MobileScannerPlatform.instance = platform;
    network = _NoNetwork();
    HttpOverrides.global = network;
    ZyraText.useTestFontStubs = true;
    WidgetController.hitTestWarningShouldBeFatal = true;
  });

  tearDown(() async {
    platform.releasePendingStart();
    await platform.closeStreams();
    expect(network.attempts, 0);
    MobileScannerController.resetPlatformSessionOwner();
    MobileScannerPlatform.instance = priorPlatform;
    HttpOverrides.global = priorHttp;
    ZyraText.useTestFontStubs = priorStubs;
    WidgetController.hitTestWarningShouldBeFatal = priorFatal;
  });

  testWidgets('real capture starts native bridge and disposes its session', (
    tester,
  ) async {
    await _mount(
      tester,
      platform,
      canCapture: () => true,
      onCode: (_) {},
      onManualEntry: () {},
    );
    expect(find.byType(MobileScanner), findsOneWidget);
    expect(find.byKey(_nativeViewKey), findsOneWidget);
    expect(platform.startOptions, hasLength(1));
    expect(platform.startOptions.single.cameraDirection, CameraFacing.back);
    expect(platform.running, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await _flush(tester);
    expect(platform.operations, ['start', 'stop', 'dispose']);
    expect(platform.disposals, 1);
    expect(platform.running, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'native stream ignores unrelated values and captures trimmed code',
    (tester) async {
      final captured = <String>[];
      await _mount(
        tester,
        platform,
        canCapture: () => true,
        onCode: captured.add,
        onManualEntry: () {},
      );
      platform.emit([
        null,
        '',
        '   ',
        'not-a-code',
        'https://example.invalid/ZYRA-X',
      ]);
      await _flush(tester);
      expect(captured, isEmpty);
      expect(platform.stops, 0);
      platform.emit(['  zyra-draft-sara  ']);
      await _flush(tester);
      expect(captured, ['zyra-draft-sara']);
      expect(platform.stops, 1);
      expect(platform.running, isFalse);
    },
  );

  testWidgets(
    'native duplicate frames and duplicate codes produce one result',
    (tester) async {
      final captured = <String>[];
      await _mount(
        tester,
        platform,
        canCapture: () => true,
        onCode: captured.add,
        onManualEntry: () {},
      );
      platform.emit(['ZYRA-DRAFT-SARA', 'ZYRA-DRAFT-SARA', 'ZYRA-DRAFT-AMIRA']);
      platform.emit(['ZYRA-DRAFT-SARA']);
      await _flush(tester);
      platform.emit(['ZYRA-DRAFT-AMIRA']);
      await _flush(tester);
      expect(captured, ['ZYRA-DRAFT-SARA']);
      expect(platform.stops, 1);
      expect(platform.startOptions, hasLength(1));
    },
  );

  testWidgets(
    'capture rejects overlong input while forwarding bounded prefix',
    (tester) async {
      final captured = <String>[];
      await _mount(
        tester,
        platform,
        canCapture: () => true,
        onCode: captured.add,
        onManualEntry: () {},
      );
      final longest = 'ZYRA-${List.filled(195, 'A').join()}';
      expect(longest.length, 200);
      platform.emit(['${longest}A']);
      await _flush(tester);
      expect(captured, isEmpty);
      platform.emit([longest]);
      await _flush(tester);
      expect(captured, [longest]);
      expect(platform.stops, 1);
    },
  );

  testWidgets('permission denial offers manual entry without code acceptance', (
    tester,
  ) async {
    platform.startError = const MobileScannerException(
      errorCode: MobileScannerErrorCode.permissionDenied,
    );
    final captured = <String>[];
    var manual = 0;
    await _mount(
      tester,
      platform,
      canCapture: () => true,
      onCode: captured.add,
      onManualEntry: () => ++manual,
    );
    expect(
      find.text('Camera unavailable. Enter the code instead.'),
      findsOneWidget,
    );
    expect(find.text('Enter code instead'), findsOneWidget);
    platform.emit(['ZYRA-DRAFT-SARA']);
    await _flush(tester);
    expect(captured, isEmpty);
    await tester.tap(find.byKey(_manualKey));
    await _flush(tester);
    expect(manual, 1);
    expect(platform.startOptions, hasLength(1));
    expect(platform.running, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('native initialization error also has manual-entry fallback', (
    tester,
  ) async {
    platform.startError = MissingPluginException('Offline fake unavailable.');
    var manual = 0;
    await _mount(
      tester,
      platform,
      canCapture: () => true,
      onCode: (_) => fail('A failed camera must not capture a code.'),
      onManualEntry: () => ++manual,
    );
    expect(
      find.text('Camera unavailable. Enter the code instead.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(_manualKey));
    await _flush(tester);
    expect(manual, 1);
    expect(platform.startOptions, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'native barcode error stops capture and preserves manual fallback',
    (tester) async {
      var manual = 0;
      final captured = <String>[];
      await _mount(
        tester,
        platform,
        canCapture: () => true,
        onCode: captured.add,
        onManualEntry: () => ++manual,
      );
      platform.emitError();
      await _flush(tester);
      expect(
        find.text('Camera unavailable. Enter the code instead.'),
        findsOneWidget,
      );
      expect(platform.stops, 1);
      platform.emit(['ZYRA-DRAFT-SARA']);
      await _flush(tester);
      expect(captured, isEmpty);
      await tester.tap(find.byKey(_manualKey));
      await _flush(tester);
      expect(manual, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('initial caller denial never starts the native camera', (
    tester,
  ) async {
    await _mount(
      tester,
      platform,
      canCapture: () => false,
      onCode: (_) => fail('Denied capture cannot emit a result.'),
      onManualEntry: () => fail('Denied capture cannot call manual entry.'),
    );
    expect(platform.startOptions, isEmpty);
    expect(
      tester.widget<ZyraKnownPersonCodePill>(find.byKey(_manualKey)).onTap,
      isNull,
    );
    platform.emit(['ZYRA-DRAFT-SARA']);
    await _flush(tester);
    expect(platform.stops, 0);
  });

  testWidgets('caller revocation rejects stale capture and manual callbacks', (
    tester,
  ) async {
    var allowed = true;
    var manual = 0;
    final captured = <String>[];
    await _mount(
      tester,
      platform,
      canCapture: () => allowed,
      onCode: captured.add,
      onManualEntry: () => ++manual,
    );
    final staleDetect = tester
        .widget<MobileScanner>(find.byType(MobileScanner))
        .onDetect!;
    final staleManual = _manualCallback(tester);
    allowed = false;
    platform.emit(['ZYRA-DRAFT-SARA']);
    staleDetect(
      const BarcodeCapture(barcodes: [Barcode(rawValue: 'ZYRA-DRAFT-AMIRA')]),
    );
    staleManual();
    await _flush(tester);
    expect(captured, isEmpty);
    expect(manual, 0);
    await tester.pumpWidget(
      _app(
        ZyraCodeCapture(
          canCapture: () => allowed,
          onCode: captured.add,
          onManualEntry: () => ++manual,
        ),
      ),
    );
    await _flush(tester);
    expect(platform.stops, 1);
    expect(platform.running, isFalse);
    // Restoring the same owner predicate must not resurrect a capture that
    // has already observed admission denial. A new session needs a new State.
    allowed = true;
    await tester.pumpWidget(
      _app(
        ZyraCodeCapture(
          canCapture: () => allowed,
          onCode: captured.add,
          onManualEntry: () => ++manual,
        ),
      ),
    );
    await _flush(tester);
    platform.emit(['ZYRA-DRAFT-AMIRA']);
    await _flush(tester);
    expect(captured, isEmpty);
    expect(manual, 0);
    expect(platform.startOptions, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('throwing capture guard is denied without a native start', (
    tester,
  ) async {
    await _mount(
      tester,
      platform,
      canCapture: () => throw StateError('The owner is unavailable.'),
      onCode: (_) => fail('A throwing guard must deny capture.'),
      onManualEntry: () => fail('A throwing guard must deny manual entry.'),
    );
    expect(platform.startOptions, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guard exception after start cannot recover a revoked session', (
    tester,
  ) async {
    var throws = false;
    final captured = <String>[];
    bool guard() {
      if (throws) throw StateError('The owner was revoked.');
      return true;
    }

    await _mount(
      tester,
      platform,
      canCapture: guard,
      onCode: captured.add,
      onManualEntry: () {},
    );
    throws = true;
    platform.emit(['ZYRA-DRAFT-SARA']);
    await _flush(tester);
    expect(captured, isEmpty);
    expect(tester.takeException(), isNull);
    throws = false;
    platform.emit(['ZYRA-DRAFT-AMIRA']);
    await _flush(tester);
    expect(captured, isEmpty);
    await tester.pumpWidget(
      _app(
        ZyraCodeCapture(
          canCapture: guard,
          onCode: captured.add,
          onManualEntry: () {},
        ),
      ),
    );
    await _flush(tester);
    expect(platform.stops, 1);
    expect(platform.startOptions, hasLength(1));
  });

  testWidgets(
    'inactive camera stops, rejects stale events and resumes cleanly',
    (tester) async {
      var manual = 0;
      final captured = <String>[];
      await _mount(
        tester,
        platform,
        canCapture: () => true,
        onCode: captured.add,
        onManualEntry: () => ++manual,
      );
      final staleManual = _manualCallback(tester);
      final staleDetect = tester
          .widget<MobileScanner>(find.byType(MobileScanner))
          .onDetect!;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await _flush(tester);
      expect(platform.stops, 1);
      expect(platform.running, isFalse);
      platform.emit(['ZYRA-DRAFT-SARA']);
      staleDetect(
        const BarcodeCapture(barcodes: [Barcode(rawValue: 'ZYRA-DRAFT-SARA')]),
      );
      staleManual();
      await _flush(tester);
      expect(captured, isEmpty);
      expect(manual, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _flush(tester);
      expect(platform.startOptions, hasLength(2));
      expect(platform.running, isTrue);
      platform.emit(['ZYRA-DRAFT-AMIRA']);
      await _flush(tester);
      expect(captured, ['ZYRA-DRAFT-AMIRA']);
      expect(platform.stops, 2);
    },
  );

  testWidgets('covered modal route stops capture until it is current again', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    final captured = <String>[];
    var manual = 0;
    await _mount(
      tester,
      platform,
      navigatorKey: navigator,
      canCapture: () => true,
      onCode: captured.add,
      onManualEntry: () => ++manual,
    );
    final staleManual = _manualCallback(tester);
    final staleDetect = tester
        .widget<MobileScanner>(find.byType(MobileScanner))
        .onDetect!;
    unawaited(
      navigator.currentState!.push<void>(
        PageRouteBuilder<void>(
          opaque: false,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, _, _) =>
              const Material(child: Center(child: Text('Another page'))),
        ),
      ),
    );
    await _flush(tester);
    expect(platform.stops, 1);
    platform.emit(['ZYRA-DRAFT-SARA']);
    staleDetect(
      const BarcodeCapture(barcodes: [Barcode(rawValue: 'ZYRA-DRAFT-SARA')]),
    );
    staleManual();
    await _flush(tester);
    expect(captured, isEmpty);
    expect(manual, 0);
    navigator.currentState!.pop();
    await _flush(tester);
    expect(platform.startOptions, hasLength(2));
    platform.emit(['ZYRA-DRAFT-AMIRA']);
    await _flush(tester);
    expect(captured, ['ZYRA-DRAFT-AMIRA']);
  });

  testWidgets(
    'disposing while native start is pending releases it afterwards',
    (tester) async {
      platform.pendingStart = Completer<MobileScannerViewAttributes>();
      final captured = <String>[];
      var manual = 0;
      await _mount(
        tester,
        platform,
        canCapture: () => true,
        onCode: captured.add,
        onManualEntry: () => ++manual,
      );
      expect(platform.startOptions, hasLength(1));
      final staleManual = _manualCallback(tester);
      final staleDetect = tester
          .widget<MobileScanner>(find.byType(MobileScanner))
          .onDetect!;
      await tester.pumpWidget(const SizedBox.shrink());
      staleDetect(
        const BarcodeCapture(barcodes: [Barcode(rawValue: 'ZYRA-DRAFT-SARA')]),
      );
      staleManual();
      platform.releasePendingStart();
      await _flush(tester);
      expect(captured, isEmpty);
      expect(manual, 0);
      expect(platform.operations, ['start', 'stop', 'dispose']);
      expect(platform.running, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'revocation during pending native start is rechecked after await',
    (tester) async {
      platform.pendingStart = Completer<MobileScannerViewAttributes>();
      var allowed = true;
      final captured = <String>[];
      await _mount(
        tester,
        platform,
        canCapture: () => allowed,
        onCode: captured.add,
        onManualEntry: () {},
      );
      allowed = false;
      platform.releasePendingStart();
      await _flush(tester);
      expect(platform.stops, 1);
      expect(platform.running, isFalse);
      platform.emit(['ZYRA-DRAFT-SARA']);
      await _flush(tester);
      expect(captured, isEmpty);
    },
  );

  testWidgets('inactive pending start stops then resumes without overlap', (
    tester,
  ) async {
    platform.pendingStart = Completer<MobileScannerViewAttributes>();
    await _mount(
      tester,
      platform,
      canCapture: () => true,
      onCode: (_) {},
      onManualEntry: () {},
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    platform.releasePendingStart();
    await _flush(tester);
    expect(platform.operations, ['start', 'stop']);
    expect(platform.running, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _flush(tester);
    expect(platform.operations, ['start', 'stop', 'start']);
    expect(platform.running, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual entry is one-shot and suppresses later native results', (
    tester,
  ) async {
    var manual = 0;
    final captured = <String>[];
    await _mount(
      tester,
      platform,
      canCapture: () => true,
      onCode: captured.add,
      onManualEntry: () => ++manual,
    );
    final staleManual = _manualCallback(tester);
    await tester.tap(find.byKey(_manualKey));
    staleManual();
    platform.emit(['ZYRA-DRAFT-SARA']);
    await _flush(tester);
    expect(manual, 1);
    expect(captured, isEmpty);
    expect(platform.stops, 1);
    expect(platform.running, isFalse);
  });

  testWidgets('no ModalRoute means no native capture authority', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await _flush(tester);
      expect(tester.takeException(), isNull);
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        builder: (_, _) => Scaffold(
          body: ZyraCodeCapture(
            canCapture: () => true,
            onCode: (_) => fail('A detached camera has no result authority.'),
            onManualEntry: () =>
                fail('A detached camera has no action authority.'),
          ),
        ),
      ),
    );
    await _flush(tester);
    expect(platform.startOptions, isEmpty);
    expect(
      tester.widget<ZyraKnownPersonCodePill>(find.byKey(_manualKey)).onTap,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
