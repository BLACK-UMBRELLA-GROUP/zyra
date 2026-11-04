// LOCK 14 V5: APP_COLOURS/RECORD/APP_COLOURS_SPEC_CURRENT_VERSION_V5.md;
// masters APP_COLOURS/MASTERS/c11_app_icon_1024.png and c12_splash.png.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/widgets/zyra_moment.dart';
import 'package:zyra/theme/zyra_colors.dart';

void main() {
  tearDown(() {
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
  });

  test('retired dark selections resolve to Ivory quiet fill and gold edge', () {
    for (final palette in ZyraDevPalette.values.where((p) => !p.isLight)) {
      ZyraColors.selectDevPalette(palette);
      for (final style in ZyraAppSurfaceStyle.values) {
        ZyraColors.selectAppSurfaceStyle(style);
        expect(ZyraColors.surfaceEmphasisFill, ZyraColors.surfaceFill);
        expect(ZyraColors.frostSelectedFill, ZyraColors.surfaceFill);
        expect(ZyraColors.accentBg, ZyraColors.surfaceFill);
        expect(ZyraColors.glassFill, ZyraColors.surfaceFill);
        expect(ZyraColors.surfaceFill, const Color(0xD9FAF5EC));
        final edge = ZyraColors.journeyGold.withValues(alpha: .70);
        expect(ZyraColors.surfaceEmphasisBorder, edge);
        expect(ZyraColors.frostSelectedBorder, edge);
        expect(ZyraColors.accentBorder, edge);
        expect(ZyraColors.glassBorder, edge);
        expect(ZyraColors.brandGradient, ZyraDevPalette.ivory.gradient);
        expect(ZyraColors.destructive, const Color(0xFFB84A42));
      }
    }
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('Moment CTA uses dark halo and keeps its action at $scale', (
      tester,
    ) async {
      var actions = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: ZyraMomentScreen(
            pairWith: const SeekerProfile(
              id: 'halo-fixture',
              firstName: 'Amira',
              age: 28,
              city: 'Manchester',
              photos: [],
              gender: 'female',
            ),
            lines: const [ZyraMomentLine.heading('Your Journey')],
            ctaLabel: 'Continue',
            onPrimary: () => actions++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final material = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('Continue'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, ZyraColors.surfaceFill);
      expect(
        (material.shape! as StadiumBorder).side.color,
        ZyraColors.surfaceEmphasisBorder,
      );
      final circles = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (container) =>
                container.decoration is BoxDecoration &&
                (container.decoration! as BoxDecoration).shape ==
                    BoxShape.circle,
          );
      expect(circles, hasLength(2));
      for (final circle in circles) {
        final face = circle.decoration! as BoxDecoration;
        expect(face.color, ZyraColors.surfaceFill);
        expect(
          (face.border! as Border).top.color,
          ZyraColors.surfaceEmphasisBorder,
        );
      }
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(actions, 1);
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'legacy Journey action and current-position chip use shared halo tokens',
    () {
      final flow = File(
        'lib/screens/journey/journey_flow_screen.dart',
      ).readAsStringSync();
      final start = flow.indexOf('class _FrostPill ');
      final end = flow.indexOf('class _JourneyRoundAction ', start);
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final pill = flow.substring(start, end);
      expect(pill, contains('color: ZyraColors.surfaceEmphasisFill'));
      expect(pill, contains('color: ZyraColors.surfaceEmphasisBorder'));
      expect(pill, contains('Opacity(opacity: 0.45'));
      expect(pill, contains('onTap: onTap'));
      final timeline = File(
        'lib/screens/matches/journey_timeline_screen.dart',
      ).readAsStringSync();
      expect(timeline, isNot(contains('0x99CEA2D1')));
      expect(timeline, contains('YOU ARE HERE'));
      expect(
        RegExp(
          r'color:\s*ZyraColors\s*\.surfaceEmphasisBorder',
        ).hasMatch(timeline),
        isTrue,
        reason:
            'Timeline current-position capsule must use the shared gold edge',
      );
    },
  );

  test('every retired stored surface resolves to locked Glass Signals', () {
    for (final style in ZyraAppSurfaceStyle.values) {
      ZyraColors.restoreAppSurfaceStyle(style.name);
      expect(ZyraColors.appSurfaceStyle, ZyraAppSurfaceStyle.glassSignals);
      expect(ZyraColors.surfaceSignal, ZyraColors.journeyGold);
      expect(ZyraColors.surfaceEmphasisFill, ZyraColors.surfaceFill);
      expect(ZyraColors.frostSelectedFill, ZyraColors.surfaceFill);
      expect(
        ZyraColors.surfaceEmphasisBorder,
        ZyraColors.journeyGold.withValues(alpha: .70),
      );
    }
  });

  test('main user-facing surfaces consume the shared app-surface boundary', () {
    // Borderless Profile deliberately consumes the canonical icon-button
    // alias rather than duplicating raw card fill calls in page code.
    expect(ZyraColors.iconButtonBg, ZyraColors.surfaceFill);
    final readers = <String, String>{
      'Connections': 'lib/screens/connections/connections_screen.dart',
      'Guardian': 'lib/screens/wali/seeker_guardian_designs.dart',
      'Profile': 'lib/screens/profile/profile_screen.dart',
      'Browser navigation': 'lib/widgets/floating_nav_bar.dart',
    };

    for (final entry in readers.entries) {
      final source = File(entry.value).readAsStringSync();
      expect(
        source,
        anyOf(
          contains('ZyraColors.surfaceFill'),
          contains('ZyraColors.surfaceEmphasisFill'),
          contains('ZyraColors.glassFill'),
          contains('ZyraColors.iconButtonBg'),
        ),
        reason: '${entry.key} must read the shared global surface tokens',
      );
    }
  });

  test('centred dialogs use the approved opaque modal boundary', () {
    final source = File(
      'lib/widgets/zyra_glass_dialog.dart',
    ).readAsStringSync();
    expect(source, contains('ZyraColors.modalSheetSurface'));
    expect(source, isNot(contains('BackdropFilter(')));
  });
}
