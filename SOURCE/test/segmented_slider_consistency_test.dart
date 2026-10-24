import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/widgets/zyra_segmented_toggle.dart';

void main() {
  test('Connections motion is the single segmented-slider specification', () {
    expect(
      ZyraSegmentedMotion.selectionDuration,
      const Duration(milliseconds: 260),
    );
    expect(ZyraSegmentedMotion.selectionCurve, Curves.easeOutCubic);

    const pagedSelectors = <String>[
      'lib/screens/connections/connections_screen.dart',
      'lib/widgets/zyra_quiet_dashboard.dart',
      'lib/screens/profile/past_journeys_screen.dart',
      'lib/screens/wali/wali_network_screen.dart',
      'lib/screens/wali/wali_dashboard_screen.dart',
    ];

    for (final path in pagedSelectors) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('ZyraSegmentedMotion.animateToPage'),
        reason: '$path must use the Connections tap motion.',
      );
      expect(
        source,
        contains('physics: ZyraSegmentedMotion.pagePhysics'),
        reason: '$path must use the Connections swipe settling.',
      );
    }
  });

  for (final count in [2, 3, 4]) {
    testWidgets('$count segments retain unseen counts without painted dots', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        final labels = [
          'Received',
          'Sent',
          'Introductions',
          'Ended',
        ].take(count).toList();
        final badges = [1, 3, 0, 2].take(count).toList();
        var position = 0.0;
        final changed = <int>[];
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: Center(
                child: StatefulBuilder(
                  builder: (context, setState) => ZyraSegmentedToggle(
                    labels: labels,
                    position: position,
                    badges: badges,
                    lockedIndexes: {count - 1},
                    segmentKeys: [
                      for (var index = 0; index < count; index++)
                        ValueKey('segment-$index'),
                    ],
                    onChanged: (index) {
                      changed.add(index);
                      setState(() => position = index.toDouble());
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final toggle = find.byType(ZyraSegmentedToggle);
        expect(
          find.descendant(
            of: toggle,
            matching: find.byWidgetPredicate((widget) {
              final decoration = switch (widget) {
                DecoratedBox() => widget.decoration,
                Container() => widget.decoration,
                _ => null,
              };
              return decoration is BoxDecoration &&
                  decoration.shape == BoxShape.circle;
            }),
          ),
          findsNothing,
        );
        for (var index = 0; index < count; index++) {
          final segment = find.byKey(ValueKey('segment-$index'));
          final node = tester.getSemantics(segment).getSemanticsData();
          expect(node.label, contains(labels[index]));
          expect(
            node.value,
            badges[index] == 0 ? isEmpty : '${badges[index]} unseen',
          );
          if (index == count - 1) {
            expect(node.label, contains('locked, upgrade available'));
          }
          await tester.tap(segment);
          await tester.pumpAndSettle();
          expect(position, index.toDouble());
        }
        expect(changed, List.generate(count, (index) => index));
        expect(
          find.byKey(ValueKey('segmented-${labels.last}-lock')),
          findsOneWidget,
        );
        expect(tester.widget<ZyraSegmentedToggle>(toggle).badges, badges);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}
