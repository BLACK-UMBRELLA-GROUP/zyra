import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/screens/connections/connections_screen.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_confirm_sheet.dart';
import 'package:zyra/widgets/zyra_menu_sheet.dart';

import 'visual/baseline_capture_support.dart';

void main() {
  // Real Poppins metrics are required for description wrapping at 52 pt.
  // Ahem's square test glyphs make these captions wrap into extra lines.
  setUpAll(() => baselineSetUp(evidenceRoot: null, useSystemSymbolFont: false));
  tearDownAll(baselineTearDown);
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  for (final size in [const Size(375, 667), const Size(430, 932)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('menu and confirm metrics match at $size / $scale text', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final safeBottom = size.height > 700 ? 34.0 : 0.0;
        Future<void> mount(Widget child) => tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: EdgeInsets.only(bottom: safeBottom),
                viewPadding: EdgeInsets.only(bottom: safeBottom),
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: Align(alignment: Alignment.bottomCenter, child: child),
            ),
          ),
        );

        var selected = 0;
        var cancelled = 0;
        await mount(
          ZyraMenuSheet(
            surfaceKey: const ValueKey('menu-surface'),
            children: [
              const ZyraMenuHeader(text: 'Hassan · Main Guardian'),
              const SizedBox(height: 6),
              ZyraMenuOption(
                key: const ValueKey('menu-main'),
                label: 'Make Main Guardian',
                onPressed: () => selected++,
              ),
              ZyraMenuOption(
                key: const ValueKey('menu-remove'),
                label: 'Remove Hassan',
                destructive: true,
                onPressed: () => selected++,
              ),
              const SizedBox(height: 8),
              ZyraMenuCancel(
                key: const ValueKey('menu-cancel'),
                onPressed: () => cancelled++,
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        final menuSurface = tester.widget<Material>(
          find.byKey(const ValueKey('menu-surface')),
        );
        final menuBounds = tester.getRect(
          find.byKey(const ValueKey('menu-surface')),
        );
        final menuHandle = tester.getRect(find.byType(ZyraIvorySheetHandle));
        final header = tester.widget<Text>(find.text('Hassan · Main Guardian'));
        final main = tester.widget<Text>(find.text('Make Main Guardian'));
        final remove = tester.widget<Text>(find.text('Remove Hassan'));
        final cancel = tester.widget<Text>(find.text('Cancel'));
        final menuAction = tester.getRect(
          find.byKey(const ValueKey('menu-remove')),
        );
        final menuCancel = tester.getRect(
          find.byKey(const ValueKey('menu-cancel')),
        );
        expect(menuBounds.left, 0);
        expect(menuBounds.right, size.width);
        expect(menuBounds.bottom, size.height);
        expect(menuAction.left, 20);
        expect(menuAction.right, size.width - 20);
        expect(menuAction.height, greaterThanOrEqualTo(52));
        expect(menuCancel.height, greaterThanOrEqualTo(52));
        if (scale == 1) {
          expect(menuAction.height, 52);
          expect(menuCancel.height, 52);
        }
        expect(header.textAlign, TextAlign.center);
        expect(header.style!.fontSize, 12.5);
        expect(header.style!.color, ZyraColors.secondaryText);
        expect(main.style!.fontSize, 15);
        expect(remove.style!.fontSize, 15);
        expect(remove.style!.color, ZyraColors.dangerText);
        expect(cancel.style!.fontSize, 15);
        await tester.tap(find.byKey(const ValueKey('menu-main')));
        await tester.tap(find.byKey(const ValueKey('menu-cancel')));
        expect(selected, 1);
        expect(cancelled, 1);

        await mount(
          ZyraConfirmSheet(
            surfaceKey: const ValueKey('confirm-surface'),
            title: 'Remove Hassan?',
            body: 'Hassan can be invited again later.',
            primaryLabel: 'Remove Hassan',
            secondaryLabel: 'Keep Hassan',
            primaryKey: const ValueKey('confirm-remove'),
            secondaryKey: const ValueKey('confirm-keep'),
            icon: Icons.person_outline,
            personName: 'Hassan',
            onConfirm: () {},
            onKeep: () {},
          ),
        );
        await tester.pumpAndSettle();
        final confirmSurface = tester.widget<Material>(
          find.byKey(const ValueKey('confirm-surface')),
        );
        final confirmBounds = tester.getRect(
          find.byKey(const ValueKey('confirm-surface')),
        );
        final confirmHandle = tester.getRect(find.byType(ZyraIvorySheetHandle));
        expect(menuSurface.color, confirmSurface.color);
        expect(menuSurface.borderRadius, confirmSurface.borderRadius);
        expect(menuBounds.width, confirmBounds.width);
        expect(menuBounds.bottom, confirmBounds.bottom);
        expect(
          menuHandle.top - menuBounds.top,
          confirmHandle.top - confirmBounds.top,
        );
        expect(menuHandle.size, confirmHandle.size);
        expect(
          remove.style,
          tester.widget<Text>(find.text('Remove Hassan')).style,
        );
        expect(
          cancel.style,
          tester.widget<Text>(find.text('Keep Hassan')).style,
        );
        expect(
          header.style,
          tester
              .widget<Text>(find.text('Hassan can be invited again later.'))
              .style,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('ended Journey menu keeps restart enablement and action order', (
    tester,
  ) async {
    final selected = <ZyraEndedJourneyAction?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ZyraEndedJourneyMenu(
              restartEnabled: false,
              onSelect: selected.add,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(ZyraMenuSheet), findsOneWidget);
    final restart = find.text('Request a new Journey');
    final remove = find.text('Remove from my Journeys');
    final cancel = find.text('Cancel');
    expect(
      tester.getTopLeft(restart).dy,
      lessThan(tester.getTopLeft(remove).dy),
    );
    expect(
      tester.getTopLeft(remove).dy,
      lessThan(tester.getTopLeft(cancel).dy),
    );
    await tester.tap(restart);
    expect(selected, isEmpty);
    await tester.tap(remove);
    await tester.tap(cancel);
    expect(selected, [ZyraEndedJourneyAction.remove, null]);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'member active Journey menu returns existing intents at $scale text',
      (tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final results = <String?>[];
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    // Match the live member route's default modal height cap.
                    final result = await showModalBottomSheet<Object>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (_) => buildZyraActiveJourneyOptionsTestSurface(
                        firstName: 'Sara',
                      ),
                    );
                    results.add(result?.toString());
                  },
                  child: const Text('Open member options'),
                ),
              ),
            ),
          ),
        );

        for (final label in ['Request Pause', 'End Journey', 'Cancel']) {
          await tester.tap(find.text('Open member options'));
          await tester.pumpAndSettle();
          expect(find.byType(ZyraMenuSheet), findsOneWidget);
          expect(find.byType(ZyraIvorySheet), findsOneWidget);
          expect(find.text('Manage your Journey with Sara.'), findsOneWidget);
          expect(
            find.text('Sara chooses whether to pause or continue.'),
            findsOneWidget,
          );
          expect(
            find.text('Close this Journey permanently. Your Timeline stays.'),
            findsOneWidget,
          );
          final pause = find.text('Request Pause');
          final end = find.text('End Journey');
          final cancel = find.text('Cancel');
          expect(
            tester.getTopLeft(pause).dy,
            lessThan(tester.getTopLeft(end).dy),
          );
          expect(
            tester.getTopLeft(end).dy,
            lessThan(tester.getTopLeft(cancel).dy),
          );
          expect(tester.widget<Text>(pause).style!.fontSize, 15);
          expect(tester.widget<Text>(end).style!.fontSize, 15);
          expect(tester.widget<Text>(end).style!.color, ZyraColors.dangerText);
          expect(
            tester.widget<Text>(find.text('Journey options')).style!.fontSize,
            12.5,
          );
          for (final row in find.byType(ZyraMenuOption).evaluate()) {
            final bounds = tester.getRect(find.byWidget(row.widget));
            expect(bounds.height, greaterThanOrEqualTo(52));
            if (scale == 1) expect(bounds.height, 52);
            final label = find
                .descendant(
                  of: find.byWidget(row.widget),
                  matching: find.byType(Text),
                )
                .first;
            final textBounds = tester.getRect(label);
            expect(textBounds.top, greaterThanOrEqualTo(bounds.top));
            expect(textBounds.bottom, lessThanOrEqualTo(bounds.bottom));
          }
          final target = find.text(label);
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          expect(target.hitTestable(), findsOneWidget);
          await tester.tap(target);
          await tester.pumpAndSettle();
          expect(find.byType(ZyraMenuSheet), findsNothing);
          expect(tester.takeException(), isNull);
        }
        expect(results[0], endsWith('.pause'));
        expect(results[1], endsWith('.end'));
        expect(results[2], isNull);
      },
    );
  }
}
