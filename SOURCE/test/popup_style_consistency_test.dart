import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_glass_dialog.dart';

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraColors.restoreAppPalette(null);
  });
  tearDown(() => ZyraText.useTestFontStubs = false);

  test('centred app popups use the shared ZYRA modal API', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains('AlertDialog(') || source.contains('SimpleDialog(')) {
        offenders.add(entity.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use showZyraGlassChoice/showZyraGlassNotice so centred popups do '
          'not regress to an unrelated platform dialog.',
    );
  });

  testWidgets('all centred modal chrome is opaque plum with one gold edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraGlassCard(
            child: Text('A shared notice', style: ZyraText.body()),
          ),
        ),
      ),
    );
    final surface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('zyra_modal_surface')),
    );
    final decoration = surface.decoration as BoxDecoration;
    expect(decoration.color, ZyraColors.modalSheetSurface);
    expect(decoration.color!.a, 1);
    expect(
      (decoration.border! as Border).top.color,
      ZyraColors.journeyGold.withValues(alpha: 0.28),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final primary in [true, false]) {
    testWidgets('choice returns $primary without changing its action meaning', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showZyraGlassChoice(
                    context: context,
                    icon: Icons.visibility_outlined,
                    title: 'Keep your choice',
                    body: 'The same confirmation, in the current app style.',
                    primaryLabel: 'Confirm',
                    secondaryLabel: 'Cancel',
                    primaryKey: const ValueKey('modal_confirm'),
                    secondaryKey: const ValueKey('modal_cancel'),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey(primary ? 'modal_confirm' : 'modal_cancel')),
      );
      await tester.pumpAndSettle();
      expect(result, primary);
      expect(find.byKey(const ValueKey('zyra_modal_surface')), findsNothing);
    });
  }

  for (final keyboard in [false, true]) {
    testWidgets('long modal stays readable and actionable at 320px 2x text '
        '${keyboard ? 'with keyboard' : ''}', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 24, bottom: 34),
              viewInsets: EdgeInsets.only(bottom: keyboard ? 200 : 0),
              textScaler: TextScaler.linear(2),
            ),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showZyraGlassChoice(
                    context: context,
                    icon: Icons.delete_outline,
                    title: 'A long confirmation title',
                    body: List.filled(
                      5,
                      'Read the information before deciding. Your current '
                      'choice remains unchanged until you confirm.',
                    ).join(' '),
                    primaryLabel: 'Confirm',
                    secondaryLabel: 'Keep current choice',
                    destructivePrimary: true,
                    primaryKey: const ValueKey('modal_confirm'),
                    secondaryKey: const ValueKey('modal_cancel'),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final scroll = find.descendant(
        of: find.byKey(const ValueKey('zyra_modal_surface')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('modal_cancel')),
        180,
        scrollable: scroll,
      );
      await tester.tap(find.byKey(const ValueKey('modal_cancel')));
      await tester.pumpAndSettle();
      expect(result, false);
      expect(tester.takeException(), isNull);
    });
  }
}
