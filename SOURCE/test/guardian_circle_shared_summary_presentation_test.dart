import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_circle_discussion_archive.dart';
import 'package:zyra/dev/zyra_guardian_circle_topic_options.dart';
import 'package:zyra/theme/zyra_text.dart';

const _label = 'Adam & Hafsa · 1–10 Sep 2026';

ZyraCircleDiscussionTopic _topic({String? label}) => ZyraCircleDiscussionTopic(
  id: 'draft-circle-past-shared',
  firstName: 'Hafsa',
  kind: ZyraCircleTopicKind.past,
  endedOn: DateTime.utc(2026, 9, 10),
  sharedSummaryLabel: label,
);

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  Future<void> mount(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shared tag and bubble use only the supplied summary and action',
    (tester) async {
      var opened = 0;
      final topic = _topic(label: _label);
      await mount(
        tester,
        Column(
          children: [
            ZyraCircleTopicTag(topic: topic),
            ZyraCircleDiscussionBubble(
              topic: topic,
              onViewJourney: () => opened++,
            ),
          ],
        ),
      );
    expect(find.text(_label), findsNWidgets(2));
      expect(find.text('Journey with Hafsa'), findsNothing);
      expect(find.text('Past Journey · Ended 10 Sep 2026'), findsNothing);
      expect(find.text('View profile'), findsNothing);
      await tester.tap(find.text('View Journey'));
      expect(opened, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shared picker searches the displayed summary and matches label',
    (tester) async {
      final topic = _topic(label: _label);
      await mount(
        tester,
        ZyraCircleTopicPicker(
          currentTopics: const [],
          pastTopics: [topic],
          // A previous label is a different choice even with the same ID.
          selected: _topic(label: 'Adam & Noor · 1–10 Sep 2026'),
          onSelected: (_) {},
          canSelect: () => true,
          bubbleDesign: ZyraCircleBubbleDesign.current,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('circle_topic_tab_1')));
      await tester.pumpAndSettle();
      expect(find.text(_label), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(find.text('Hafsa'), findsNothing);
      expect(find.text('10 Sep 2026'), findsNothing);
      await tester.enterText(find.byType(TextField), 'adam');
      await tester.pumpAndSettle();
      expect(find.text(_label), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shared archive has only the supplied identity and date content',
    (tester) async {
      await mount(
        tester,
        ZyraCircleDiscussionArchiveView(
          archive: ZyraCircleDiscussionArchive(
            topicId: 'draft-circle-past-shared',
            firstName: 'Hafsa',
            startedOn: DateTime.utc(2026, 9, 1),
            endedOn: DateTime.utc(2026, 9, 10),
            sharedSummaryLabel: _label,
          ),
          canAct: () => true,
          onClose: () {},
        ),
      );
    expect(find.text(_label), findsOneWidget);
      expect(find.text('Journey with Hafsa'), findsNothing);
      expect(find.text('Journey started'), findsNothing);
      expect(find.text('Journey ended'), findsNothing);
      expect(find.text('This Journey is archived.'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ordinary Seeker topic presentation stays unchanged', (
    tester,
  ) async {
    final topic = _topic();
    await mount(
      tester,
      Column(
        children: [
          ZyraCircleTopicTag(topic: topic),
          ZyraCircleDiscussionBubble(topic: topic),
        ],
      ),
    );
    expect(find.text('Past Journey · Hafsa'), findsOneWidget);
    expect(find.text('Journey with Hafsa'), findsOneWidget);
    expect(find.text('Past Journey · Ended 10 Sep 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
