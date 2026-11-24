import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_help_safety_preview.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    ZyraHelpSafetyScreen screen, {
    bool guardian = false,
    DateTime? requested,
    VoidCallback? sent,
    VoidCallback? delete,
    VoidCallback? keep,
    VoidCallback? reportDone,
    VoidCallback? block,
  }) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraHelpSafetyPreview(
            screen: screen,
            guardian: guardian,
            firstName: 'Adam',
            reportedName: 'Sara',
            dataRequestedAt: requested,
            onContactSent: sent ?? () {},
            onReportDone: reportDone ?? () {},
            onBlockReported: block ?? () {},
            onOpenData: () {},
            onOpenDelete: () {},
            onRequestData: () {},
            onDelete: delete ?? () {},
            onClose: () {},
            onDone: keep ?? () {},
            onLegal: (_) {},
            onSubscriptions: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('Contact support requires topic and ten message characters', (
    tester,
  ) async {
    var sends = 0;
    await show(tester, ZyraHelpSafetyScreen.contact, sent: () => sends++);
    FilledButton send() => tester.widget<FilledButton>(
      find.byKey(const ValueKey('help_action_Send message')),
    );
    expect(send().onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('help_topic_Journeys')));
    await tester.enterText(
      find.byKey(const ValueKey('help_contact_message')),
      'too short',
    );
    await tester.pump();
    expect(send().onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('help_contact_message')),
      'A longer message',
    );
    await tester.pump();
    expect(send().onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('help_action_Send message')));
    expect(sends, 1);
  });

  testWidgets('Screenshot row and Guardian export have their LOCK37 states', (
    tester,
  ) async {
    await show(tester, ZyraHelpSafetyScreen.contact);
    await tester.tap(find.byKey(const ValueKey('help_row_Add a screenshot')));
    await tester.pump();
    expect(find.text('Screenshot added'), findsOneWidget);
    expect(find.text('1 of 1'), findsOneWidget);
    await show(tester, ZyraHelpSafetyScreen.data, guardian: true);
    expect(find.text('Your Seeker links'), findsOneWidget);
    expect(find.text('Your Partner preferences answers'), findsNothing);
    await show(
      tester,
      ZyraHelpSafetyScreen.data,
      guardian: true,
      requested: DateTime(2026, 11, 24),
    );
    expect(find.byKey(const ValueKey('help_data_requested')), findsOneWidget);
    expect(find.textContaining('Requested on 24 Nov'), findsOneWidget);
  });

  testWidgets('Delete confirmation keeps or closes only after chosen', (
    tester,
  ) async {
    var deletes = 0;
    await show(tester, ZyraHelpSafetyScreen.delete, delete: () => deletes++);
    expect(find.text('Your Journeys end'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('help_delete_open_confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('help_delete_keep')));
    await tester.pumpAndSettle();
    expect(deletes, 0);
    await tester.tap(find.byKey(const ValueKey('help_delete_open_confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('help_delete_confirm')));
    await tester.pumpAndSettle();
    expect(deletes, 1);
    await show(tester, ZyraHelpSafetyScreen.delete, guardian: true);
    expect(find.text('Your Seekers are unlinked'), findsOneWidget);
    expect(find.text('Your Journeys end'), findsNothing);
  });

  testWidgets('Report sent Done and Block use distinct callbacks', (
    tester,
  ) async {
    var done = 0;
    var blocks = 0;
    await show(
      tester,
      ZyraHelpSafetyScreen.reportSent,
      reportDone: () => done++,
      block: () => blocks++,
    );
    expect(
      find.textContaining('Your report about Sara has been sent'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('help_report_block_too')));
    expect(blocks, 1);
    expect(done, 0);
    await tester.tap(find.byKey(const ValueKey('help_action_Done')));
    expect(done, 1);
  });
}
