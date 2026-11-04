import 'support/queue44_activity_fixture_catalog.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_my_zyra_activity_preview.dart';
import 'package:zyra/models/zyra_dashboard_resolution.dart';
import 'package:zyra/models/zyra_supportive_dashboard.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

Finder _key(String id) => find.byKey(ValueKey(id));

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late bool previousStubs;
  setUp(() {
    previousStubs = ZyraText.useTestFontStubs;
    ZyraText.useTestFontStubs = true;
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
  });
  tearDown(() => ZyraText.useTestFontStubs = previousStubs);

  test('catalog has ten immutable local examples and no quiet event', () {
    expect(ZyraMyZyraActivityExample.values, hasLength(13));
    expect(ZyraMyZyraActivityExample.quiet.items, isEmpty);
    for (final example in ZyraMyZyraActivityExample.values) {
      expect(example.label, isNotEmpty);
      expect(example.description, isNotEmpty);
      expect(
        () => example.items.add(
          const ZyraMyZyraActivityItem(
            id: 'not-a-real-item',
            title: 'Not a real item',
            detail: 'No data mutation.',
            actionLabel: 'View',
            owner: ZyraMyZyraActivityOwner.requests,
          ),
        ),
        throwsUnsupportedError,
      );
    }
  });

  test('every fictional item has stable unique identity and a typed owner', () {
    final items = ZyraMyZyraActivityExample.values
        .expand((example) => example.items)
        .toList();
    expect(items, hasLength(14));
    expect(items.map((item) => item.id).toSet(), hasLength(items.length));
    for (final item in items) {
      expect(item.id, startsWith('concept-activity-preview-'));
      expect(item.title, isNotEmpty);
      expect(item.detail, isNotEmpty);
      expect(item.actionLabel, isNotEmpty);
      expect(item.owner.target, isNot(ZyraDashboardTarget.none));
      if (item.personId != null) {
        expect(
          item.personId,
          isIn([
            'draft-amira',
            'draft-sara',
            'draft-aisha',
            'draft-noor',
            'draft-maryam',
          ]),
        );
      }
    }
  });

  test('owner destination is not inferred from a title', () {
    for (final owner in ZyraMyZyraActivityOwner.values) {
      final item = ZyraMyZyraActivityItem(
        id: 'concept-activity-preview-owner-${owner.name}',
        title: 'Any display title',
        detail: 'Fictional display copy.',
        actionLabel: 'Any action label',
        owner: owner,
      );
      expect(item.card.target, switch (owner) {
        ZyraMyZyraActivityOwner.requests ||
        ZyraMyZyraActivityOwner.introductions ||
        ZyraMyZyraActivityOwner.ended =>
          ZyraDashboardTarget.connectionsActivity,
        ZyraMyZyraActivityOwner.journey =>
          ZyraDashboardTarget.connectionsJourneys,
        ZyraMyZyraActivityOwner.guardian ||
        ZyraMyZyraActivityOwner.circle => ZyraDashboardTarget.guardian,
      });
    }
  });

  test(
    'cards preserve fictional data without supplying read or score evidence',
    () {
      for (final item in ZyraMyZyraActivityExample.values.expand(
        (e) => e.items,
      )) {
        final card = item.card;
        expect(card.id, item.id);
        expect(card.title, item.title);
        expect(card.detail, item.detail);
        expect(card.actionLabel, item.actionLabel);
        expect(card.section, SupportiveSection.needsYou);
        expect(card.hasNewActivity, isTrue);
        expect(card.isUnread, isNull);
        expect(card.date, isNull);
        expect(card.evidence, isNull);
      }
    },
  );

  testWidgets('checklist delegates each exact choice and current restore', (
    tester,
  ) async {
    final choices = <ZyraMyZyraActivityExample?>[];
    final catalog = Queue44ActivityCatalog(
      selected: null,
      reviewed: const {},
      onSelected: choices.add,
    );
    await tester.pumpWidget(_app(const SizedBox.shrink()));
    expect(find.text('Activity checklist'), findsNothing);
    for (final example in ZyraMyZyraActivityExample.values) {
      catalog.choices
          .singleWhere((choice) => choice.example == example)
          .select();
      expect(_key('activity-checklist-${example.name}'), findsNothing);
    }
    catalog.choices.singleWhere((choice) => choice.example == null).select();
    expect(choices, [...ZyraMyZyraActivityExample.values, null]);
  });

  testWidgets(
    'reviewed checkmarks and current selection have separate semantics',
    (tester) async {
      final catalog = Queue44ActivityCatalog(
        selected: ZyraMyZyraActivityExample.requestAccepted,
        reviewed: const {
          ZyraMyZyraActivityExample.requestReceived,
          ZyraMyZyraActivityExample.requestAccepted,
        },
        onSelected: (_) {},
      );
      await tester.pumpWidget(_app(const SizedBox.shrink()));
      expect(catalog.choices.where((choice) => choice.reviewed), hasLength(2));
      final received = catalog.choices.singleWhere(
        (choice) => choice.example == ZyraMyZyraActivityExample.requestReceived,
      );
      expect(received.reviewed, isTrue);
      expect(received.selected, isFalse);
      final accepted = catalog.choices.singleWhere(
        (choice) => choice.example == ZyraMyZyraActivityExample.requestAccepted,
      );
      expect(accepted.reviewed, isTrue);
      expect(accepted.selected, isTrue);
      expect(_key('activity-checklist-requestAccepted'), findsNothing);
    },
  );

  testWidgets('bar delegates all four controls without owning state', (
    tester,
  ) async {
    final events = <String>[];
    final catalog = Queue44ActivityCatalog(
      selected: ZyraMyZyraActivityExample.journeyReady,
      reviewed: const {},
      onSelected: (_) {},
      onPrevious: () => events.add('previous'),
      onNext: () => events.add('next'),
      onChecklist: () => events.add('checklist'),
      onCurrent: () => events.add('current'),
    );
    await tester.pumpWidget(_app(const SizedBox.shrink()));
    for (final id in ['previous', 'next', 'checklist', 'current']) {
      catalog.commands[id]!();
      expect(_key('activity-preview-$id'), findsNothing);
    }
    expect(events, ['previous', 'next', 'checklist', 'current']);
    expect(catalog.selected, ZyraMyZyraActivityExample.journeyReady);
  });

  testWidgets(
    'current data can be selected without marking an example viewed',
    (tester) async {
      final catalog = Queue44ActivityCatalog(
        selected: null,
        reviewed: const {ZyraMyZyraActivityExample.quiet},
        onSelected: (_) {},
      );
      await tester.pumpWidget(_app(const SizedBox.shrink()));
      final current = catalog.choices.singleWhere(
        (choice) => choice.example == null,
      );
      expect(current.selected, isTrue);
      expect(current.reviewed, isFalse);
      expect(catalog.choices.where((choice) => choice.reviewed), hasLength(1));
      expect(_key('activity-checklist-current'), findsNothing);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('320px checklist and bar remain reachable at $scale text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final events = <String>[];
      final catalog = Queue44ActivityCatalog(
        selected: ZyraMyZyraActivityExample.introductionReceived,
        reviewed: const {ZyraMyZyraActivityExample.introductionReceived},
        onSelected: (value) => events.add(value?.name ?? 'current'),
        onPrevious: () => events.add('previous'),
        onNext: () => events.add('next'),
        onChecklist: () => events.add('checklist'),
        onCurrent: () => events.add('restore'),
      );
      await tester.pumpWidget(_app(const SizedBox.shrink(), scale: scale));
      for (final example in ZyraMyZyraActivityExample.values) {
        catalog.choices
            .singleWhere((choice) => choice.example == example)
            .select();
        expect(_key('activity-checklist-${example.name}'), findsNothing);
      }
      for (final id in ['previous', 'next', 'checklist', 'current']) {
        catalog.commands[id]!();
        expect(_key('activity-preview-$id'), findsNothing);
      }
      expect(events, [
        ...ZyraMyZyraActivityExample.values.map((example) => example.name),
        'previous',
        'next',
        'checklist',
        'restore',
      ]);
      expect(tester.takeException(), isNull);
    });
  }
}
