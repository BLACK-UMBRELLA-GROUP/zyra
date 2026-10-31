import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_my_zyra_focus.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_focus_dashboard.dart';
import 'package:zyra/widgets/zyra_tap_feedback.dart';

Finder _key(String value) => find.byKey(ValueKey(value));
Finder _title(String value) => find.byWidgetPredicate(
  (widget) => widget is Text && widget.data?.replaceAll('\n', ' ') == value,
);

ZyraFocusItem _item(String id, {VoidCallback? onAction}) => ZyraFocusItem(
  id: id,
  icon: Icons.mail_outline,
  title: 'Journey request from $id',
  detail: '$id would like to begin a Journey with you.',
  actionLabel: 'View request',
  actionKey: 'action-$id',
  onAction: onAction ?? () {},
);

Future<void> _mount(
  WidgetTester tester, {
  List<ZyraFocusItem> items = const [],
  List<ZyraFocusChip> chips = const [],
  List<ZyraFocusTile> tiles = const [],
  ValueChanged<int>? onIndexChanged,
  String? greeting,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          textScaler: TextScaler.linear(textScale),
        ),
        child: ZyraTapFeedback(
          level: () => ZyraHapticLevel.off,
          canAct: () => true,
          child: child!,
        ),
      ),
      home: Scaffold(
        body: ZyraFocusDashboard(
          items: items,
          chips: chips,
          tiles: tiles,
          onIndexChanged: onIndexChanged,
          greeting: greeting,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  late bool previousFontStubs;
  setUp(() {
    previousFontStubs = ZyraText.useTestFontStubs;
    ZyraText.useTestFontStubs = true;
  });
  tearDown(() => ZyraText.useTestFontStubs = previousFontStubs);

  for (final example in [
    (names: ['Amira', 'Sara'], expected: 'Amira and Sara'),
    (names: ['Amira', 'Sara', 'Noor'], expected: 'Amira, Sara and Noor'),
    (
      names: ['Amira', 'Sara', 'Noor', 'Maryam'],
      expected: 'Amira, Sara and 2 others',
    ),
  ]) {
    test('request wording for ${example.names.length} people', () {
      expect(zyraFocusRequestNames(example.names), example.expected);
    });
  }

  testWidgets('a single item has its action without step controls', (
    tester,
  ) async {
    var opened = 0;
    await _mount(tester, items: [_item('Amira', onAction: () => opened++)]);
    expect(find.text('NEEDS YOU'), findsOneWidget);
    expect(_title('Journey request from Amira'), findsOneWidget);
    expect(_key('focus-dot-target-0'), findsNothing);
    expect(_key('focus-dot-target-1'), findsNothing);
    await tester.tap(_key('action-Amira'));
    await tester.pump();
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('top dots select items in the existing order', (tester) async {
    final changed = <int>[];
    await _mount(
      tester,
      items: [_item('Amira'), _item('Sara')],
      onIndexChanged: changed.add,
    );
    expect(find.text('NEEDS YOU · 1 OF 2'), findsOneWidget);
    await tester.tap(_key('focus-dot-target-0'));
    await tester.pumpAndSettle();
    expect(_title('Journey request from Amira'), findsOneWidget);
    expect(changed, isEmpty);
    await tester.tap(_key('focus-dot-target-1'));
    await tester.pumpAndSettle();
    expect(find.text('NEEDS YOU · 2 OF 2'), findsOneWidget);
    expect(_title('Journey request from Sara'), findsOneWidget);
    expect(_title('Journey request from Amira'), findsNothing);
    await tester.tap(_key('focus-dot-target-1'));
    await tester.pumpAndSettle();
    expect(_title('Journey request from Sara'), findsOneWidget);
    expect(changed, [1]);
    await tester.tap(_key('focus-dot-target-0'));
    await tester.pumpAndSettle();
    expect(_title('Journey request from Amira'), findsOneWidget);
    expect(changed, [1, 0]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipes use the same bounded item order without wrapping', (
    tester,
  ) async {
    final changed = <int>[];
    await _mount(
      tester,
      items: [_item('Amira'), _item('Sara')],
      onIndexChanged: changed.add,
    );
    Future<void> swipe(double dx) async {
      await tester.fling(_key('focus-area'), Offset(dx, 0), 1000);
      await tester.pumpAndSettle();
    }

    await swipe(250);
    expect(_title('Journey request from Amira'), findsOneWidget);
    expect(changed, isEmpty);
    await swipe(-250);
    expect(_title('Journey request from Sara'), findsOneWidget);
    await swipe(-250);
    expect(_title('Journey request from Sara'), findsOneWidget);
    expect(changed, [1]);
    await swipe(250);
    expect(_title('Journey request from Amira'), findsOneWidget);
    expect(changed, [1, 0]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no activity shows the all-caught-up state without an action', (
    tester,
  ) async {
    await _mount(tester);
    expect(find.text('ALL CAUGHT UP'), findsOneWidget);
    expect(find.text('Nothing needs you right now.'), findsOneWidget);
    expect(find.text('NEEDS YOU'), findsNothing);
    expect(find.text('View request'), findsNothing);
    expect(_key('focus-dot-target-0'), findsNothing);
    expect(_key('focus-dot-target-1'), findsNothing);
  });

  testWidgets(
    'primary, secondary, status and quick-access actions stay distinct',
    (tester) async {
      final actions = <String>[];
      await _mount(
        tester,
        items: [
          ZyraFocusItem(
            id: 'review',
            icon: Icons.shield_outlined,
            title: 'Family Review for Adam and Sara',
            detail: 'Continue, or pause the move to the next stage.',
            actionLabel: 'Continue',
            actionKey: 'continue-review',
            onAction: () => actions.add('continue'),
            secondaryLabel: 'Pause',
            secondaryKey: 'pause-review',
            onSecondaryAction: () => actions.add('pause'),
          ),
        ],
        chips: [
          ZyraFocusChip(
            id: 'chip-setup',
            label: 'Finish setup',
            icon: Icons.person_outline,
            onTap: () => actions.add('setup'),
          ),
        ],
        tiles: [
          for (final tile in [
            (id: 'requests', label: 'Journey requests', status: '2 new'),
            (
              id: 'connect',
              label: 'Connect with Guardian',
              status: 'Guardian One',
            ),
            (id: 'introductions', label: 'Introductions', status: '1 made'),
            (
              id: 'notifications',
              label: 'Notifications',
              status: 'Nothing new',
            ),
          ])
            ZyraFocusTile(
              id: 'tile-${tile.id}',
              label: tile.label,
              status: tile.status,
              icon: Icons.inbox_outlined,
              isNew: tile.id == 'requests',
              locked: tile.id == 'connect',
              onTap: () => actions.add(tile.id),
            ),
        ],
      );
      for (final key in [
        'continue-review',
        'pause-review',
        'chip-setup',
        'tile-requests',
        'tile-connect',
        'tile-introductions',
        'tile-notifications',
      ]) {
        expect(_key(key), findsOneWidget);
        await tester.ensureVisible(_key(key));
        await tester.tap(_key(key));
        await tester.pumpAndSettle();
      }
      expect(actions, [
        'continue',
        'pause',
        'setup',
        'requests',
        'connect',
        'introductions',
        'notifications',
      ]);
      expect(find.text('Guardian One'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Larger Text scrolls to the last tile without clipping', (
    tester,
  ) async {
    var notificationsOpened = 0;
    await _mount(
      tester,
      textScale: 2,
      greeting: 'Assalamu alaikum, Hassan. You support Adam and Yusuf.',
      items: [
        ZyraFocusItem(
          id: 'review',
          icon: Icons.shield_outlined,
          title: 'Family Review for Adam and Sara',
          detail:
              'Faith & Values is complete. Continue, or pause the move to the '
              'next stage. 41 hours left — if you do nothing, the Journey '
              'continues.',
          actionLabel: 'Continue',
          onAction: () {},
          secondaryLabel: 'Pause',
          onSecondaryAction: () {},
        ),
      ],
      chips: [
        for (final label in [
          'Finish setup',
          'No Guardian yet',
          '1 of 3 places in use',
          'Notifications off',
          'Preferences 0/325',
        ])
          ZyraFocusChip(label: label, icon: Icons.person_outline, onTap: () {}),
      ],
      tiles: [
        for (final tile in [
          (label: 'Journey requests', status: '3 new'),
          (label: 'Introductions', status: '1 new'),
          (label: 'Ended Journeys', status: 'None'),
          (label: 'Notifications', status: 'Nothing new'),
        ])
          ZyraFocusTile(
            id: tile.label == 'Notifications' ? 'last-tile' : null,
            label: tile.label,
            status: tile.status,
            icon: Icons.inbox_outlined,
            onTap: tile.label == 'Notifications'
                ? () => notificationsOpened++
                : () {},
          ),
      ],
    );
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scroll.position.maxScrollExtent, greaterThan(0));
    expect(_key('last-tile'), findsOneWidget);
    await tester.ensureVisible(_key('last-tile'));
    await tester.pumpAndSettle();
    expect(tester.getRect(_key('last-tile')).bottom, lessThanOrEqualTo(932));
    await tester.tap(_key('last-tile'));
    await tester.pumpAndSettle();
    expect(notificationsOpened, 1);
    expect(tester.takeException(), isNull);
  });
}
