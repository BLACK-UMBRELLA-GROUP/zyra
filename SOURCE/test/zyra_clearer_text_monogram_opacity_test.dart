import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/dev/zyra_one_journey_monogram_presentation.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_floating_surface.dart';

Future<void> _mount(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 932);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectOpaque(WidgetTester tester, Finder text) {
  for (final opacity in tester.widgetList<Opacity>(
    find.ancestor(of: text, matching: find.byType(Opacity)),
  )) {
    expect(opacity.opacity, 1);
  }
  for (final fade in tester.widgetList<FadeTransition>(
    find.ancestor(of: text, matching: find.byType(FadeTransition)),
  )) {
    expect(fade.opacity.value, 1);
  }
}

Future<Uint8List> _raster(WidgetTester tester, Widget child) async {
  final previousShadows = debugDisableShadows;
  try {
    debugDisableShadows = false;
    const boundaryKey = ValueKey('monogram-raster');
    await _mount(
      tester,
      Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: ColoredBox(
            color: ZyraColors.ivoryBottom,
            child: SizedBox.square(dimension: 120, child: Center(child: child)),
          ),
        ),
      ),
    );
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    return (await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      try {
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        return Uint8List.fromList(bytes!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    }))!;
  } finally {
    debugDisableShadows = previousShadows;
  }
}

void main() {
  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraText.useTestFontStubs = true;
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
  });

  for (final expired in [false, true]) {
    testWidgets(
      '${expired ? 'Expired' : 'Sent'} Guardian invitation keeps its initial opaque',
      (tester) async {
        await _mount(
          tester,
          ZyraOneJourneyGuardianCards(
            people: [
              ZyraGuardianCardPerson(
                person: WaliLinkedPerson(
                  id: 'linked-guardian',
                  firstName: 'Hassan',
                  relationship: 'father',
                  isMain: true,
                  linkedAt: DateTime(2026, 10, 1),
                ),
                membership: 'Guardian One',
                history: false,
              ),
            ],
            journeysFor: (_) => [],
            capacity: 3,
            basic: false,
            initialPage: 1,
            canAct: () => true,
            interactionEpoch: () => 0,
            contextIdentity: 'seeker',
            renderIdentity: 0,
            unread: 0,
            onPage: (_) {},
            onHistory: (_, _) {},
            onPermission: (_, _, {view, chat}) {},
            makeMain: (_) async => true,
            clearMain: (_) async => true,
            remove: (_) async => null,
            onAdd: () {},
            onCircle: () {},
            previewInvitationNow: expired
                ? ZyraOneJourneyGuardianCards.previewInvitationExpiry
                : ZyraOneJourneyGuardianCards.previewInvitationSent,
          ),
        );
        final card = find.byKey(
          const ValueKey('guardian-card-preview-invited-omar'),
        );
        expect(card, findsOneWidget);
        expect(
          find.text(expired ? 'INVITATION EXPIRED' : 'INVITATION SENT'),
          findsOneWidget,
        );
        final monogram = find.descendant(
          of: card,
          matching: find.byType(ZyraGoldRingMonogram),
        );
        final initial = find.descendant(of: monogram, matching: find.text('O'));
        expect(initial, findsOneWidget);
        final text = tester.widget<Text>(initial);
        expect(text.style!.fontSize, 28);
        expect(text.style!.fontWeight, FontWeight.w200);
        expect(text.style!.color, ZyraColors.secondaryText);
        expect(text.textScaler, TextScaler.noScaling);
        _expectOpaque(tester, initial);
        expect(tester.getSize(monogram), const Size(60, 60));
        final fade = find.descendant(
          of: monogram,
          matching: find.byType(Opacity),
        );
        expect(fade, findsOneWidget);
        expect(tester.widget<Opacity>(fade).opacity, .55);
        expect(find.descendant(of: fade, matching: initial), findsNothing);
        expect(
          find.descendant(of: fade, matching: find.byType(ZyraFloatingSurface)),
          findsOneWidget,
        );
        final fills = tester.widgetList<Container>(
          find.descendant(of: fade, matching: find.byType(Container)),
        );
        expect(
          fills.any((container) {
            final decoration = container.decoration;
            return decoration is BoxDecoration &&
                decoration.shape == BoxShape.circle &&
                decoration.color == ZyraColors.ivoryTop &&
                decoration.border == null;
          }),
          isTrue,
        );
      },
    );
  }

  testWidgets('Default monogram retains its unfaded reading and artwork path', (
    tester,
  ) async {
    await _mount(
      tester,
      const Center(
        child: ZyraGoldRingMonogram(
          name: 'Omar',
          guardianOne: false,
          size: 60,
          fontSize: 28,
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
    final monogram = find.byType(ZyraGoldRingMonogram);
    expect(tester.widget<ZyraGoldRingMonogram>(monogram).artworkOpacity, 1);
    final initial = find.text('O');
    _expectOpaque(tester, initial);
    expect(tester.widget<Text>(initial).style!.fontSize, 28);
    expect(tester.widget<Text>(initial).style!.fontWeight, FontWeight.w200);
    expect(tester.widget<Text>(initial).style!.color, ZyraColors.secondaryText);
    expect(tester.getSize(monogram), const Size(60, 60));
  });

  testWidgets('Artwork fade retains exact fill ring shadow and custom pixels', (
    tester,
  ) async {
    for (final guardianOne in [false, true, null]) {
      for (final custom in [false, true]) {
        final child = custom
            ? const Icon(Icons.lock_outline, color: ZyraColors.journeyGold)
            : const SizedBox.shrink();
        Widget monogram(double opacity) => ZyraGoldRingMonogram(
          name: 'Omar',
          guardianOne: guardianOne,
          size: 60,
          fontSize: 28,
          artworkOpacity: opacity,
          child: child,
        );
        final expected = await _raster(
          tester,
          Opacity(opacity: .55, child: monogram(1)),
        );
        final actual = await _raster(tester, monogram(.55));
        expect(
          actual,
          orderedEquals(expected),
          reason: 'guardianOne=$guardianOne, custom artwork=$custom',
        );
        expect(find.text('O'), findsNothing);
      }
    }
  });
}
