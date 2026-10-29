import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zyra/models/zyra_error_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_full_screen_error.dart';

const _captureDirectory = String.fromEnvironment(
  'ZYRA_QUIET_ACCESS_CAPTURE_DIR',
);
const _captureKey = ValueKey('quiet-access-capture');
const _font = 'PoppinsQuietAccess';

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captureDirectory/$name.png');
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (_captureDirectory.isEmpty) return;
    if (!_captureDirectory.startsWith('/') ||
        !Directory(_captureDirectory).existsSync()) {
      throw StateError(
        'Quiet-access captures require an existing absolute directory.',
      );
    }
    final reading = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await reading.load();
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _captureDirectory.isEmpty ? null : _font;
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  test('classifies the four failure families without exposing exceptions', () {
    expect(
      zyraErrorKindFor(TimeoutException('hidden timeout detail')),
      ZyraErrorKind.serviceUnavailable,
    );
    expect(
      zyraErrorKindFor(Exception('refresh token has expired')),
      ZyraErrorKind.sessionExpired,
    );
    expect(
      zyraErrorKindFor(Exception('Invalid refresh token: token not found')),
      ZyraErrorKind.sessionExpired,
    );
    expect(
      zyraErrorKindFor(
        http.ClientException('Refresh token request: SocketException'),
      ),
      ZyraErrorKind.offline,
    );
    expect(
      zyraErrorKindFor(
        http.ClientException('Refresh token request failed: statusCode: 503'),
      ),
      ZyraErrorKind.serviceUnavailable,
    );
    expect(
      zyraErrorKindFor(Exception('503 service unavailable')),
      ZyraErrorKind.serviceUnavailable,
    );
    expect(
      zyraErrorKindFor(Exception('unexpected render failure')),
      ZyraErrorKind.page,
    );
    expect(
      zyraErrorKindFor(http.ClientException('Unexpected response format')),
      ZyraErrorKind.page,
    );
    expect(
      zyraErrorKindFor(
        http.ClientException('SocketException: connection reset'),
      ),
      ZyraErrorKind.offline,
    );
    expect(
      zyraErrorKindFor(
        http.ClientException('statusCode: 503 connection closed'),
      ),
      ZyraErrorKind.serviceUnavailable,
    );
    expect(
      zyraErrorKindFor(http.ClientException('statusCode: 500')),
      ZyraErrorKind.serviceUnavailable,
    );
    expect(ZyraErrorKind.offline.content.secondaryLabel, 'Return to welcome');

    final reference = zyraErrorReference(Exception('private backend detail'));
    expect(reference, matches(RegExp(r'^ZY-[0-9A-Z]{4}$')));
    expect(reference, isNot(contains('private')));
  });

  for (final kind in ZyraErrorKind.values) {
    testWidgets('${kind.name} is a complete branded recovery screen', (
      tester,
    ) async {
      var primaryTaps = 0;
      var secondaryTaps = 0;
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ZyraFullScreenError(
            kind: kind,
            referenceCode: 'ZY-TEST',
            onPrimary: () => primaryTaps++,
            onSecondary: () => secondaryTaps++,
          ),
        ),
      );

      expect(
        find.byKey(ValueKey('zyra_error_screen_${kind.name}')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('zyra_error_connection_mark')),
        kind == ZyraErrorKind.previewAccess ? findsNothing : findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('zyra_error_compact_notice')),
        kind == ZyraErrorKind.previewAccess ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('ZYRA'),
        kind == ZyraErrorKind.previewAccess ? findsNothing : findsOneWidget,
      );
      expect(find.text(kind.content.title), findsOneWidget);
      expect(find.text(kind.content.message), findsOneWidget);
      expect(find.text('REFERENCE: ZY-TEST'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('zyra_error_primary')));
      await tester.tap(find.byKey(const ValueKey('zyra_error_secondary')));
      expect(primaryTaps, 1);
      expect(secondaryTaps, 1);
    });
  }

  for (final scenario in [
    ('standard', const Size(390, 844), 1.0),
    ('short', const Size(320, 480), 1.0),
    ('compact200', const Size(320, 568), 2.0),
  ]) {
    for (final palette in [ZyraDevPalette.midnightPlum]) {
      testWidgets(
        'compact access recovery ${scenario.$1} ${palette.name} remains truthful and reachable',
        (tester) async {
          final previousPalette = ZyraColors.devPalette;
          ZyraColors.selectDevPalette(palette);
          addTearDown(() => ZyraColors.selectDevPalette(previousPalette));
          tester.view.physicalSize = scenario.$2;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          try {
            var primary = 0;
            var secondary = 0;
            await tester.pumpWidget(
              MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scenario.$3)),
                  child: child!,
                ),
                home: RepaintBoundary(
                  key: _captureKey,
                  child: ZyraFullScreenError(
                    kind: ZyraErrorKind.previewAccess,
                    referenceCode: 'ZY-TEST',
                    onPrimary: () => primary++,
                    onSecondary: () => secondary++,
                  ),
                ),
              ),
            );
            expect(find.text('Preview access needs checking.'), findsNothing);
            expect(find.textContaining('Live data'), findsNothing);
            expect(find.text('ZYRA'), findsNothing);
            expect(find.text('Couldn’t open this page.'), findsOneWidget);
            expect(find.text('Sign out'), findsOneWidget);
            final surface = tester
                .widget<Material>(
                  find.byKey(const ValueKey('zyra_error_compact_notice')),
                )
                .color!;
            expect(surface.a, 1);
            for (final label in [
              'Couldn’t open this page.',
              ZyraErrorKind.previewAccess.content.message,
              'REFERENCE: ZY-TEST',
            ]) {
              final ink = tester.widget<Text>(find.text(label)).style!.color!;
              final foreground = Color.alphaBlend(
                ink,
                surface,
              ).computeLuminance();
              final background = surface.computeLuminance();
              final ratio = foreground > background
                  ? (foreground + 0.05) / (background + 0.05)
                  : (background + 0.05) / (foreground + 0.05);
              expect(ratio, greaterThanOrEqualTo(4.5), reason: label);
            }
            final primaryStyle = tester
                .widget<OutlinedButton>(
                  find.byKey(const ValueKey('zyra_error_primary')),
                )
                .style!;
            final accent = primaryStyle.foregroundColor!.resolve({})!;
            final foreground = accent.computeLuminance();
            final background = surface.computeLuminance();
            expect(
              foreground > background
                  ? (foreground + 0.05) / (background + 0.05)
                  : (background + 0.05) / (foreground + 0.05),
              greaterThanOrEqualTo(4.5),
            );
            expect(
              tester
                  .widgetList<Semantics>(find.byType(Semantics))
                  .any((widget) => widget.properties.liveRegion == true),
              isTrue,
            );
            if (scenario.$1 == 'standard') {
              final notice = tester.getRect(
                find.byKey(const ValueKey('zyra_error_compact_notice')),
              );
              expect(notice.top, greaterThan(scenario.$2.height / 2));
              expect(notice.bottom, lessThanOrEqualTo(scenario.$2.height - 20));
            }
            await _capture(
              tester,
              'quiet_access_failure_${scenario.$1}_${palette.name}_top',
            );
            for (final key in ['zyra_error_primary', 'zyra_error_secondary']) {
              final action = find.byKey(ValueKey(key));
              await tester.ensureVisible(action);
              await tester.pump();
              expect(action.hitTestable(), findsOneWidget);
              final rect = tester.getRect(action);
              expect(rect.width, greaterThanOrEqualTo(44));
              expect(rect.height, greaterThanOrEqualTo(44));
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(scenario.$2.width));
              expect(rect.top, greaterThanOrEqualTo(0));
              expect(rect.bottom, lessThanOrEqualTo(scenario.$2.height));
              await tester.tap(action);
            }
            expect(primary, 1);
            expect(secondary, 1);
            expect(tester.takeException(), isNull);
            if (scenario.$3 == 2) {
              await _capture(
                tester,
                'quiet_access_failure_${scenario.$1}_${palette.name}_actions',
              );
            }
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}
