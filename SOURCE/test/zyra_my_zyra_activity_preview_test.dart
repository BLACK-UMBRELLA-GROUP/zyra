import 'dart:ui' as ui;

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

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = _key(key);
  expect(finder, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

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
    expect(ZyraMyZyraActivityExample.values, hasLength(10));
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
    expect(items, hasLength(11));
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
    await tester.pumpWidget(
      _app(
        ZyraMyZyraActivityChecklist(
          selected: null,
          reviewed: const {},
          onSelected: choices.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Activity checklist'), findsOneWidget);
    expect(find.textContaining('Fictional examples.'), findsOneWidget);
    for (final example in ZyraMyZyraActivityExample.values) {
      await _tap(tester, 'activity-checklist-${example.name}');
    }
    await _tap(tester, 'activity-checklist-current');
    expect(choices, [...ZyraMyZyraActivityExample.values, null]);
  });

  testWidgets(
    'reviewed checkmarks and current selection have separate semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _app(
            ZyraMyZyraActivityChecklist(
              selected: ZyraMyZyraActivityExample.requestAccepted,
              reviewed: const {
                ZyraMyZyraActivityExample.requestReceived,
                ZyraMyZyraActivityExample.requestAccepted,
              },
              onSelected: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('2 of 10 viewed'), findsOneWidget);
        final received = tester.getSemantics(
          _key('activity-checklist-requestReceived'),
        );
        expect(received.flagsCollection.isChecked, ui.CheckedState.isTrue);
        expect(received.flagsCollection.isSelected, ui.Tristate.isFalse);
        await Scrollable.ensureVisible(
          tester.element(_key('activity-checklist-requestAccepted')),
        );
        await tester.pumpAndSettle();
        final accepted = tester.getSemantics(
          _key('activity-checklist-requestAccepted'),
        );
        expect(accepted.flagsCollection.isChecked, ui.CheckedState.isTrue);
        expect(accepted.flagsCollection.isSelected, ui.Tristate.isTrue);
        expect(
          accepted.getSemanticsData().hasAction(ui.SemanticsAction.tap),
          isTrue,
        );
        expect(find.byIcon(Icons.check_box_rounded), findsNWidgets(2));
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('bar delegates all four controls without owning state', (
    tester,
  ) async {
    final events = <String>[];
    await tester.pumpWidget(
      _app(
        ZyraMyZyraActivityPreviewBar(
          example: ZyraMyZyraActivityExample.journeyReady,
          onPrevious: () => events.add('previous'),
          onNext: () => events.add('next'),
          onChecklist: () => events.add('checklist'),
          onCurrent: () => events.add('current'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('7 / 10 · Journey ready'), findsOneWidget);
    for (final id in ['previous', 'next', 'checklist', 'current']) {
      await _tap(tester, 'activity-preview-$id');
      expect(
        tester.getSize(_key('activity-preview-$id')).height,
        greaterThanOrEqualTo(44),
      );
    }
    expect(events, ['previous', 'next', 'checklist', 'current']);
    expect(find.text('7 / 10 · Journey ready'), findsOneWidget);
  });

  testWidgets(
    'current data can be selected without marking an example viewed',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _app(
            ZyraMyZyraActivityChecklist(
              selected: null,
              reviewed: const {ZyraMyZyraActivityExample.quiet},
              onSelected: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final current = tester.getSemantics(_key('activity-checklist-current'));
        expect(current.flagsCollection.isSelected, ui.Tristate.isTrue);
        expect(current.flagsCollection.isChecked, ui.CheckedState.none);
        expect(find.text('1 of 10 viewed'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
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
      await tester.pumpWidget(
        _app(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ZyraMyZyraActivityChecklist(
                selected: ZyraMyZyraActivityExample.introductionReceived,
                reviewed: const {
                  ZyraMyZyraActivityExample.introductionReceived,
                },
                onSelected: (value) => events.add(value?.name ?? 'current'),
              ),
              const SizedBox(height: 16),
              ZyraMyZyraActivityPreviewBar(
                example: ZyraMyZyraActivityExample.introductionReceived,
                onPrevious: () => events.add('previous'),
                onNext: () => events.add('next'),
                onChecklist: () => events.add('checklist'),
                onCurrent: () => events.add('restore'),
              ),
            ],
          ),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final example in ZyraMyZyraActivityExample.values) {
        await _tap(tester, 'activity-checklist-${example.name}');
        expect(
          tester.getSize(_key('activity-checklist-${example.name}')).height,
          greaterThanOrEqualTo(44),
        );
      }
      for (final id in ['previous', 'next', 'checklist', 'current']) {
        await _tap(tester, 'activity-preview-$id');
      }
      expect(events, [
        ...ZyraMyZyraActivityExample.values.map((e) => e.name),
        'previous',
        'next',
        'checklist',
        'restore',
      ]);
      expect(tester.takeException(), isNull);
    });
  }
}
