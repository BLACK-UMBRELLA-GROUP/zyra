// Passive presenter tests only; ending/accepting a Journey belongs to the
// caller's authority and confirmation tests, not this viewport.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_request_capacity_choice.dart';
import 'package:zyra/theme/zyra_card_metrics.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

const _bounds = ValueKey('capacity-choice-bounds');
const _font = 'PoppinsRequestCapacity';
const _items = [
  ZyraRequestCapacityItem(
    id: 'journey-sara',
    name: 'Sara Ahmed',
    subtitle: '27 · Birmingham',
    portrait: ColoredBox(
      key: ValueKey('prepared-sara-portrait'),
      color: Colors.white,
    ),
  ),
  ZyraRequestCapacityItem(
    id: 'journey-aisha',
    name: 'Aisha Khan',
    subtitle: '29 · London',
  ),
  ZyraRequestCapacityItem(
    id: 'journey-maryam',
    name: 'Maryam Hussain',
    subtitle: '26 · Leeds',
  ),
];

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('The capacity choice must remain a passive presenter.');
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));
Finder _row(String id) => _key('request_capacity_journey_$id');

Widget _choice({
  String firstName = 'Zara',
  int capacity = 3,
  List<ZyraRequestCapacityItem> items = _items,
  String? selectedId,
  ValueChanged<String>? onSelected,
  VoidCallback? onContinue,
  VoidCallback? onCancel,
}) => ZyraRequestCapacityChoice(
  firstName: firstName,
  capacity: capacity,
  items: items,
  selectedId: selectedId,
  onSelected: onSelected ?? (_) {},
  onContinue: onContinue,
  onCancel: onCancel ?? () {},
);

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(393, 852),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        backgroundColor: ZyraColors.luxuryDarkPurple,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox.expand(key: _bounds, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

OutlinedButton _continue(WidgetTester tester) =>
    tester.widget<OutlinedButton>(_key('request_capacity_continue'));

ScrollableState _scroll(WidgetTester tester) => tester.state<ScrollableState>(
  find.descendant(
    of: _key('request_capacity_choice'),
    matching: find.byType(Scrollable),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousOverrides;
  late _NoNetwork network;
  late bool previousFontStubs;
  late String? previousReadingFont;

  setUpAll(() async {
    final loader = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular']) {
      loader.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await loader.load();
  });

  setUp(() {
    previousOverrides = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    previousFontStubs = ZyraText.useTestFontStubs;
    previousReadingFont = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
  });

  tearDown(() {
    HttpOverrides.global = previousOverrides;
    ZyraText.useTestFontStubs = previousFontStubs;
    ZyraText.testReadingFontFamily = previousReadingFont;
    expect(network.attempts, 0);
  });

  testWidgets('selection is required before the caller can continue', (
    tester,
  ) async {
    String? selectedId;
    final selected = <String>[];
    var continued = 0;
    var cancelled = 0;
    await _mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) => _choice(
          selectedId: selectedId,
          onSelected: (id) => setState(() {
            selected.add(id);
            selectedId = id;
          }),
          onContinue: () => continued++,
          onCancel: () => cancelled++,
        ),
      ),
    );
    expect(_continue(tester).onPressed, isNull);
    await tester.tap(_key('request_capacity_continue'));
    await tester.pump();
    expect(continued, 0);
    await tester.tap(_row('journey-aisha'));
    await tester.pumpAndSettle();
    expect(selected, ['journey-aisha']);
    expect(selectedId, 'journey-aisha');
    expect(_continue(tester).onPressed, isNotNull);
    expect(continued, 0);
    expect(cancelled, 0);
    await tester.tap(_key('request_capacity_continue'));
    await tester.pump();
    expect(continued, 1);
    expect(selected, ['journey-aisha']);
    await tester.tap(_key('request_capacity_cancel'));
    await tester.pump();
    expect(cancelled, 1);
    expect(continued, 1);
  });

  testWidgets(
    'row callbacks preserve IDs and never select or mutate internally',
    (tester) async {
      final selected = <String>[];
      var continued = 0;
      await _mount(
        tester,
        _choice(onSelected: selected.add, onContinue: () => continued++),
      );
      for (final item in _items) {
        expect(_row(item.id), findsOneWidget);
        await tester.tap(_row(item.id));
        await tester.pump();
        expect(selected.last, item.id);
        expect(_continue(tester).onPressed, isNull);
      }
      expect(selected, _items.map((item) => item.id).toList());
      expect(continued, 0);
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    },
  );

  testWidgets(
    'stale selection and a missing callback keep continuation disabled',
    (tester) async {
      var continued = 0;
      await _mount(
        tester,
        _choice(selectedId: 'removed-journey', onContinue: () => continued++),
      );
      expect(_continue(tester).onPressed, isNull);
      await tester.tap(_key('request_capacity_continue'));
      await tester.pump();
      expect(continued, 0);
      await _mount(tester, _choice(selectedId: 'journey-sara'));
      expect(_continue(tester).onPressed, isNull);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    },
  );

  testWidgets('radio semantics announce selection and dispatch one action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final selected = <String>[];
      await _mount(
        tester,
        _choice(selectedId: 'journey-aisha', onSelected: selected.add),
      );
      for (final item in _items) {
        final data = tester.getSemantics(_row(item.id)).getSemanticsData();
        expect(data.label, item.name);
        expect(data.value, item.subtitle);
        expect(data.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
        expect(
          data.flagsCollection.isChecked,
          item.id == 'journey-aisha'
              ? ui.CheckedState.isTrue
              : ui.CheckedState.isFalse,
        );
        expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
      }
      final target = _row('journey-sara');
      final node = tester.getSemantics(target);
      tester
          .element(target)
          .renderObject!
          .owner!
          .semanticsOwner!
          .performAction(node.id, ui.SemanticsAction.tap);
      await tester.pump();
      expect(selected, ['journey-sara']);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('normal phone fits one page with aligned edges and even spacing', (
    tester,
  ) async {
    await _mount(tester, _choice());
    expect(_key('request_capacity_choice'), findsOneWidget);
    expect(_scroll(tester).position.maxScrollExtent, 0);
    final viewport = tester.getRect(find.byKey(_bounds));
    final title = find.text('Your Journey places are full.');
    final titleRect = tester.getRect(title);
    final titleText = tester.widget<Text>(title);
    expect(titleText.style!.fontSize, 26);
    expect(titleRect.left, closeTo(viewport.left, .01));
    expect(titleRect.top, closeTo(viewport.top, .01));
    expect(
      find.text(
        'Choose a Journey to end before beginning with Zara, or keep your Journeys and leave the request for now.',
      ),
      findsOneWidget,
    );
    final body = tester.getRect(
      find.text(
        'Choose a Journey to end before beginning with Zara, or keep your Journeys and leave the request for now.',
      ),
    );
    final rows = [for (final item in _items) tester.getRect(_row(item.id))];
    final action = tester.getRect(_key('request_capacity_continue'));
    final cancel = tester.getRect(_key('request_capacity_cancel'));
    for (final row in rows) {
      expect(row.height, greaterThanOrEqualTo(48));
      expect(row.left, closeTo(viewport.left, .01));
      expect(row.right, closeTo(viewport.right, .01));
      expect(row.top, greaterThanOrEqualTo(viewport.top));
      expect(row.bottom, lessThanOrEqualTo(viewport.bottom));
    }
    expect(rows[1].top - rows[0].bottom, closeTo(ZyraCardMetrics.spacing, .01));
    expect(rows[2].top - rows[1].bottom, closeTo(ZyraCardMetrics.spacing, .01));
    expect(rows.first.top - body.bottom, greaterThanOrEqualTo(24));
    expect(
      action.top - rows.last.bottom,
      closeTo(rows.first.top - body.bottom, .01),
    );
    expect(action.left, closeTo(viewport.left, .01));
    expect(action.right, closeTo(viewport.right, .01));
    expect(action.height, greaterThanOrEqualTo(48));
    expect(cancel.height, greaterThanOrEqualTo(44));
    expect(cancel.bottom, closeTo(viewport.bottom, .01));
    expect(find.text('End & accept request'), findsOneWidget);
    expect(find.text('Keep my Journeys'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection uses the existing gold card framing', (tester) async {
    await _mount(tester, _choice(selectedId: 'journey-sara'));
    for (final item in _items) {
      final material = tester.widget<Material>(
        find.descendant(of: _row(item.id), matching: find.byType(Material)),
      );
      expect(material.color, ZyraColors.surfaceFill);
      final shape = material.shape! as RoundedRectangleBorder;
      expect(
        shape.borderRadius,
        BorderRadius.circular(ZyraCardMetrics.cardRadius),
      );
      expect(
        shape.side.color,
        item.id == 'journey-sara'
            ? ZyraColors.journeyGold
            : ZyraColors.surfaceBorder,
      );
    }
    expect(
      find.byKey(const ValueKey('prepared-sara-portrait')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.person_outline), findsNWidgets(2));
  });

  testWidgets(
    '200 percent text on a short phone scrolls without font shrinking',
    (tester) async {
      final selected = <String>[];
      var cancelled = 0;
      await _mount(
        tester,
        _choice(onSelected: selected.add, onCancel: () => cancelled++),
        size: const Size(320, 568),
        scale: 2,
      );
      expect(_scroll(tester).position.maxScrollExtent, greaterThan(0));
      final title = tester.widget<Text>(
        find.text('Your Journey places are full.'),
      );
      expect(title.style!.fontSize, 26);
      expect(title.maxLines, isNull);
      expect(title.overflow, isNull);
      for (final item in _items) {
        await tester.ensureVisible(_row(item.id));
        await tester.pumpAndSettle();
        final row = tester.getRect(_row(item.id));
        final label = tester.getRect(find.text(item.name));
        expect(row.height, greaterThanOrEqualTo(48));
        expect(label.left, greaterThanOrEqualTo(row.left));
        expect(label.right, lessThanOrEqualTo(row.right));
        expect(label.top, greaterThanOrEqualTo(row.top));
        expect(label.bottom, lessThanOrEqualTo(row.bottom));
        expect(_row(item.id).hitTestable(), findsOneWidget);
        await tester.tap(_row(item.id));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      expect(selected, _items.map((item) => item.id).toList());
      await tester.ensureVisible(_key('request_capacity_cancel'));
      await tester.pumpAndSettle();
      await tester.tap(_key('request_capacity_cancel'));
      await tester.pump();
      expect(cancelled, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty items cannot continue and neutral redacted rows need no portrait',
    (tester) async {
      var continued = 0;
      await _mount(
        tester,
        _choice(
          items: [],
          selectedId: 'not-present',
          onContinue: () => continued++,
        ),
      );
      expect(_continue(tester).onPressed, isNull);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
      expect(continued, 0);
      await _mount(
        tester,
        _choice(
          capacity: 1,
          items: const [
            ZyraRequestCapacityItem(id: 'redacted', name: 'User not found'),
          ],
        ),
      );
      expect(_row('redacted'), findsOneWidget);
      expect(find.text('User not found'), findsOneWidget);
      expect(find.text('Sara Ahmed'), findsNothing);
      expect(
        find.byKey(const ValueKey('prepared-sara-portrait')),
        findsNothing,
      );
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(_continue(tester).onPressed, isNull);
    },
  );
}
