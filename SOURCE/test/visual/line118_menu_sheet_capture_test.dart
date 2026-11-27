// Line 118 evidence uses actual presenters and the offline Founder shell.
// No approved baseline is replaced; output is enabled explicitly by the owner.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

import '../support/guardian_card_driver.dart';
import 'baseline_capture_support.dart';

const _output = String.fromEnvironment('ZYRA_LINE118_CAPTURE');
final _ios = TargetPlatformVariant({TargetPlatform.iOS});

void main() {
  setUpAll(
    () => baselineSetUp(
      evidenceRoot: null,
      useSystemSymbolFont: Platform.isMacOS,
    ),
  );
  tearDownAll(baselineTearDown);

  for (final size in [const Size(430, 932), const Size(375, 667)]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    BaselineHarness harness(WidgetTester tester, String group) {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      return BaselineHarness(
        tester,
        group: 'line118_${group}_$label',
        outputRoot: _output,
        evidenceRoot: _output,
        flatOutput: true,
        logicalSize: size,
        safePadding: EdgeInsets.only(
          top: size.height > 700 ? 59 : 20,
          bottom: size.height > 700 ? 34 : 0,
        ),
      );
    }

    Future<void> capture(BaselineHarness h, String name, String reached) async {
      if (_output.isEmpty && !baselineTextAuditOnly) return;
      await h.capture(
        'menu_sizing',
        name,
        label,
        reached,
        fileName: '${name}_$label.png',
      );
    }

    testWidgets('line118 actual Guardian menu and Make Main $label', (t) async {
      final h = harness(t, 'guardian');
      await h.mount(
        tab: 3,
        seekerPhotos: const [],
        model: ViewRequestDraftModel(capacity: 3)..seedJourneys(2),
      );
      final initial = h.latest.model.states;
      await swipeGuardianCard(t);
      await h.flush();
      await h.tap('guardian-card-menu');
      expect(find.text('Make Main Guardian'), findsOneWidget);
      expect(find.text('Remove Yusuf'), findsOneWidget);
      await capture(h, 'guardian_menu', 'Guardian additional card → •••');
      await h.tap('guardian-make-main');
      expect(find.text('Yusuf will be your Main Guardian'), findsOneWidget);
      expect(h.latest.mainGuardianId, 'draft-guardian-hassan');
      expect(h.latest.model.states, initial);
      await capture(h, 'guardian_confirm', '••• → Make Main Guardian');
      await h.tap('guardian-make-main-confirmation-keep');
      expect(h.latest.mainGuardianId, 'draft-guardian-hassan');
      expect(h.latest.model.states, initial);
      expect(find.text('Yusuf will be your Main Guardian'), findsNothing);
      expect(t.takeException(), isNull);
    }, variant: _ios);

    testWidgets('line118 shared Journey menu presenters $label', (t) async {
      final h = harness(t, 'journey');
      await h.mount(tab: 3, seekerPhotos: const []);
      final context = t.element(find.byType(ZyraOneJourneyGuardianCards));
      ZyraConceptJourneyOption? choice;
      unawaited(
        showModalBottomSheet<ZyraConceptJourneyOption>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => ConstrainedBox(
            constraints: BoxConstraints(maxHeight: size.height * .85),
            child: ZyraConceptJourneyOptions(
              id: 'line118-sara',
              firstName: 'Sara',
              canEnd: true,
              canViewBio: true,
              canViewCompatibility: true,
              onSelected: (value) {
                choice = value;
                Navigator.of(sheetContext).pop(value);
              },
              onCancel: () => Navigator.of(sheetContext).pop(),
            ),
          ),
        ),
      );
      await h.flush();
      expect(find.text('Journey options'), findsOneWidget);
      await capture(
        h,
        'journey_menu',
        'Production Journey menu in modal route',
      );
      final end = find.byKey(const ValueKey('draft_options_end_line118-sara'));
      await t.ensureVisible(end);
      await h.flush();
      await t.tap(end);
      await h.flush();
      expect(choice, ZyraConceptJourneyOption.end);

      ZyraEndedJourneyAction? endedChoice;
      unawaited(
        showModalBottomSheet<ZyraEndedJourneyAction>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => ZyraEndedJourneyMenu(
            onSelect: (value) {
              endedChoice = value;
              Navigator.of(sheetContext).pop(value);
            },
          ),
        ),
      );
      await h.flush();
      expect(find.text('Request a new Journey'), findsOneWidget);
      expect(find.text('Remove from my Journeys'), findsOneWidget);
      await capture(h, 'ended_menu', 'Shared ended Journey modal presenter');
      await t.tap(find.text('Remove from my Journeys'));
      await h.flush();
      expect(endedChoice, ZyraEndedJourneyAction.remove);
      expect(t.takeException(), isNull);
    }, variant: _ios);
  }
}
