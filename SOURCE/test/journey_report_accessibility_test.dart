import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_card_content.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/models/seeker_profile.dart';

const _profile = SeekerProfile(
  id: 'report-fixture',
  firstName: 'Sara',
  surnameLine: 'Ahmad',
  age: 27,
  city: 'Birmingham',
  photos: [],
  gender: 'female',
);
const _photoKey = ValueKey('report-test-photo');

Widget _subject({
  required ZyraOneJourneyCardDesign design,
  required bool compact,
  required double scale,
  VoidCallback? onReport,
}) {
  final locked = design == ZyraOneJourneyCardDesign.quietMinimal;
  final card = ZyraOneJourneyConnectionsActiveCard(
    profile: _profile,
    imageBuilder: (_, _) =>
        const ColoredBox(key: _photoKey, color: Colors.white),
    actions: const SizedBox(height: 40),
    primaryAction: const SizedBox(height: 40),
    stateLabel: 'Active Journey',
    stageLabel: 'Salam Exchange',
    cardDesign: design,
    compact: compact,
    fillHeight: locked,
    onReport: onReport,
  );
  return MaterialApp(
    theme: ThemeData.dark(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: child!,
    ),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 358,
          // Only the current locked layout has a fixed card envelope. The
          // retained classic presenter keeps its natural-height contract,
          // including real wrapping at enlarged text sizes.
          height: locked ? 320 : null,
          child: locked ? card : IntrinsicHeight(child: card),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('selected Portrait split and still-used legacy presenters remain', () {
    expect(ZyraOneJourneyCardDesign.values, [
      ZyraOneJourneyCardDesign.classic,
      ZyraOneJourneyCardDesign.quietMinimal,
      ZyraOneJourneyCardDesign.portraitSplit,
    ]);
  });

  // These retained consumers still own the historical report-flag geometry.
  // The selected shell layout exposes Report through its ellipsis
  // menu, covered by journey_card_layout_choices_test.dart instead.
  for (final design in [
    ZyraOneJourneyCardDesign.classic,
    ZyraOneJourneyCardDesign.quietMinimal,
  ]) {
    for (final compact in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '${design.name}, compact=$compact, scale=$scale keeps an accessible report target',
          (tester) async {
            final handle = tester.ensureSemantics();
            var reports = 0;
            try {
              await tester.pumpWidget(
                _subject(
                  design: design,
                  compact: compact,
                  scale: scale,
                  onReport: () => reports++,
                ),
              );
              final report = find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    widget.properties.label == 'Report Sara',
              );
              expect(report, findsOneWidget);
              final target = tester.getRect(report);
              expect(target.size, const Size(44, 44));
              final glyph = tester.getRect(find.byIcon(Icons.flag_outlined));
              expect(glyph.size, const Size(15, 15));
              expect(glyph.top, target.top);
              expect(glyph.right, target.right);
              final photo = tester.getRect(find.byKey(_photoKey));
              expect(glyph.top, photo.top);
              if (design == ZyraOneJourneyCardDesign.quietMinimal) {
                expect(photo.size, const Size(104, 104));
                expect(find.text('Active Journey'), findsNothing);
                expect(find.text('Salam Exchange'), findsNothing);
              }
              final node = tester.getSemantics(report);
              expect(node.rect.size, const Size(44, 44));
              expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
              expect(
                node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
                isTrue,
              );
              // Tap the newly enlarged invisible area, not the tiny glyph.
              await tester.tapAt(Offset(target.left + 2, target.bottom - 2));
              await tester.pump();
              expect(reports, 1);
              tester
                  .renderObject<RenderObject>(report)
                  .owner!
                  .semanticsOwner!
                  .performAction(node.id, ui.SemanticsAction.tap);
              await tester.pump();
              expect(reports, 2);
              expect(tester.takeException(), isNull);
            } finally {
              handle.dispose();
            }
          },
        );
      }
    }
  }

  testWidgets(
    'a card without a report callback exposes no fake report action',
    (tester) async {
      await tester.pumpWidget(
        _subject(
          design: ZyraOneJourneyCardDesign.quietMinimal,
          compact: true,
          scale: 1,
        ),
      );
      expect(find.byIcon(Icons.flag_outlined), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == 'Report Sara',
        ),
        findsNothing,
      );
      expect(tester.getSize(find.byKey(_photoKey)), const Size(104, 104));
      expect(tester.takeException(), isNull);
    },
  );
}
