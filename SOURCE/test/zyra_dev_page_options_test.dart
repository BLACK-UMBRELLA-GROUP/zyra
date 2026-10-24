import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_page_options.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

Widget _host(
  List<ZyraDevPageOption> options, {
  String contextKey = 'page-a',
  bool busy = false,
  double textScale = 1,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Center(
            child: SizedBox(
              width: 258,
              child: SingleChildScrollView(
                child: ZyraDevPageOptions(
                  options: options,
                  contextKey: contextKey,
                  busy: busy,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Finder get _dropdown => find.byWidgetPredicate(
  (widget) =>
      widget is InkWell &&
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith(
        'dev_page_options_dropdown_',
      ),
);

Future<void> _open(WidgetTester tester, {String? group}) async {
  final dropdown = group == null
      ? _dropdown.first
      : find.byKey(ValueKey('dev_page_options_dropdown_$group'));
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
    ZyraText.useTestFontStubs = true;
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('developer dropdown uses shared app surfaces', (tester) async {
    await tester.pumpWidget(
      _host([
        const ZyraDevPageOption(
          id: 'one',
          label: 'First state',
          group: 'Status',
        ),
      ]),
    );
    final trigger = tester.widget<DecoratedBox>(
      find.descendant(of: _dropdown, matching: find.byType(DecoratedBox)).first,
    );
    final triggerDecoration = trigger.decoration as BoxDecoration;
    expect(triggerDecoration.color, ZyraColors.surfaceEmphasisFill);
    expect(
      (triggerDecoration.border! as Border).top.color,
      ZyraColors.surfaceEmphasisBorder,
    );
    await _open(tester);
    final menu = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('dev_page_options_inline_menu')),
    );
    final menuDecoration = menu.decoration as BoxDecoration;
    expect(menuDecoration.color, ZyraColors.modalSheetSurface);
    expect(
      (menuDecoration.border! as Border).top.color,
      ZyraColors.surfaceBorder,
    );
  });

  testWidgets(
    'current state replaces the last choice after an external change',
    (tester) async {
      String selected = 'first';
      Widget host() => _host([
        ZyraDevPageOption(
          id: 'first',
          label: 'First state',
          group: 'Status',
          selected: selected == 'first',
          onSelected: () {
            selected = 'first';
          },
        ),
        ZyraDevPageOption(
          id: 'second',
          label: 'Second state',
          group: 'Status',
          selected: selected == 'second',
          onSelected: () {
            selected = 'second';
          },
        ),
      ]);
      await tester.pumpWidget(host());
      await _open(tester);
      await tester.tap(find.text('Second state').last);
      await tester.pumpAndSettle();
      await tester.pumpWidget(host());
      expect(find.text('Second state'), findsOneWidget);
      selected = 'first';
      await tester.pumpWidget(host());
      expect(find.text('First state'), findsOneWidget);
    },
  );

  testWidgets('leaving a page and returning cannot revive its old menu', (
    tester,
  ) async {
    var calls = 0;
    final options = [
      ZyraDevPageOption(
        id: 'one',
        label: 'First state',
        group: 'Status',
        onSelected: () {
          calls++;
        },
      ),
    ];
    await tester.pumpWidget(_host(options));
    await _open(tester);
    await tester.pumpWidget(_host(options, contextKey: 'page-b'));
    await tester.pumpWidget(_host(options));
    expect(
      find.byKey(const ValueKey('dev_page_options_inline_menu')),
      findsNothing,
    );
    expect(calls, 0);
  });

  testWidgets('losing and restoring authority cannot revive an old menu', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      _host([
        ZyraDevPageOption(
          id: 'one',
          label: 'First state',
          group: 'Status',
          onSelected: () {
            calls++;
          },
        ),
      ]),
    );
    await _open(tester);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('dev_page_options_inline_menu')),
      findsNothing,
    );
    expect(calls, 0);
  });

  testWidgets(
    'a fully restricted catalog can still explain its denied states',
    (tester) async {
      await tester.pumpWidget(
        _host([
          const ZyraDevPageOption(
            id: 'denied',
            label: 'Journey details',
            group: 'Role',
            unavailableReason: 'Main Guardian only',
          ),
        ]),
      );
      await _open(tester);
      expect(find.text('Main Guardian only'), findsOneWidget);
      expect(
        tester.widget<InkWell>(find.byKey(const ValueKey('denied'))).onTap,
        isNull,
      );
    },
  );

  testWidgets(
    'separate category menus delegate only their own selected choice',
    (tester) async {
      var first = 0;
      var second = 0;
      await tester.pumpWidget(
        _host([
          ZyraDevPageOption(
            id: 'one',
            label: 'First state',
            group: 'Status',
            onSelected: () {
              first++;
            },
          ),
          ZyraDevPageOption(
            id: 'two',
            label: 'Second state',
            group: 'Content',
            onSelected: () {
              second++;
            },
          ),
        ]),
      );
      expect(find.byType(DropdownButton<String>), findsNothing);
      expect(find.text('Page options'), findsOneWidget);
      expect([first, second], [0, 0]);
      await _open(tester, group: 'Content');
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      expect(find.text('First state'), findsNothing);
      await tester.tap(find.text('Second state').last);
      await tester.pumpAndSettle();
      expect([first, second], [0, 1]);
      expect(find.text('Second state'), findsOneWidget);
      await _open(tester, group: 'Status');
      expect(find.byKey(const ValueKey('two')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('one')));
      await tester.pumpAndSettle();
      expect([first, second], [1, 1]);
      expect(find.text('First state'), findsOneWidget);
      expect(find.text('Second state'), findsOneWidget);
    },
  );

  testWidgets('unavailable entries retain a truthful reason and no callback', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host([
        ZyraDevPageOption(
          id: 'allowed',
          label: 'Available',
          group: 'Role',
          onSelected: () {},
        ),
        const ZyraDevPageOption(
          id: 'denied',
          label: 'Journey details',
          group: 'Role',
          unavailableReason: 'Main Guardian only',
        ),
      ]),
    );
    await _open(tester);
    expect(find.text('Main Guardian only'), findsOneWidget);
    expect(
      tester.widget<InkWell>(find.byKey(const ValueKey('denied'))).onTap,
      isNull,
    );
    await tester.tap(find.text('Journey details').last);
    await tester.pump();
    expect(find.text('Choose a page option'), findsOneWidget);
  });

  testWidgets('non-contiguous categories merge without mixing their options', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host([
        ZyraDevPageOption(
          id: 'scene-one',
          label: 'Standard',
          group: 'Network scene',
          onSelected: () {},
        ),
        ZyraDevPageOption(
          id: 'design',
          label: 'Cinematic',
          group: 'Network design',
          onSelected: () {},
        ),
        ZyraDevPageOption(
          id: 'scene-reset',
          label: 'Reset scene',
          group: 'Network scene',
          onSelected: () {},
        ),
      ]),
    );
    expect(
      find.byKey(const ValueKey('dev_page_options_dropdown_Network scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dev_page_options_dropdown_Network design')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dev_page_options_dropdown')),
      findsNothing,
    );
    await _open(tester, group: 'Network scene');
    expect(find.byKey(const ValueKey('scene-one')), findsOneWidget);
    expect(find.byKey(const ValueKey('scene-reset')), findsOneWidget);
    expect(find.byKey(const ValueKey('design')), findsNothing);
    await _open(tester, group: 'Network design');
    expect(find.byKey(const ValueKey('scene-one')), findsNothing);
    expect(find.byKey(const ValueKey('scene-reset')), findsNothing);
    expect(find.byKey(const ValueKey('design')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dev_page_options_inline_menu')),
      findsOneWidget,
    );
  });

  testWidgets('each category displays its own current state simultaneously', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host([
        ZyraDevPageOption(
          id: 'state',
          label: 'Recommendations loading',
          group: 'Network scene',
          selected: true,
          onSelected: () {},
        ),
        ZyraDevPageOption(
          id: 'design',
          label: 'Cinematic overlay',
          group: 'Network design',
          selected: true,
          onSelected: () {},
        ),
        ZyraDevPageOption(
          id: 'count',
          label: '3 profiles',
          group: 'Profiles',
          selected: true,
          onSelected: () {},
        ),
      ]),
    );
    expect(find.text('Recommendations loading'), findsOneWidget);
    expect(find.text('Cinematic overlay'), findsOneWidget);
    expect(find.text('3 profiles'), findsOneWidget);
    for (final group in ['Network scene', 'Network design', 'Profiles']) {
      expect(
        find.byKey(ValueKey('dev_page_options_group_$group')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('category change invalidates a captured old option callback', (
    tester,
  ) async {
    var calls = 0;
    final option = ZyraDevPageOption(
      id: 'same',
      label: 'Shared label',
      group: 'Old category',
      onSelected: () => calls++,
    );
    await tester.pumpWidget(_host([option]));
    await _open(tester);
    final staleTap = tester
        .widget<InkWell>(find.byKey(const ValueKey('same')))
        .onTap!;
    await tester.pumpWidget(
      _host([
        ZyraDevPageOption(
          id: 'same',
          label: 'Shared label',
          group: 'New category',
          onSelected: () => calls++,
        ),
      ]),
    );
    staleTap();
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(
      find.byKey(const ValueKey('dev_page_options_inline_menu')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('dev_page_options_group_Old category')),
      findsNothing,
    );
  });

  testWidgets('empty catalog is honest and busy catalog cannot act', (
    tester,
  ) async {
    await tester.pumpWidget(_host([]));
    expect(find.text('No page-specific options'), findsOneWidget);
    expect(_dropdown, findsNothing);
    expect(
      find.byKey(const ValueKey('dev_page_options_inline_menu')),
      findsNothing,
    );
    await tester.pumpWidget(
      _host([
        ZyraDevPageOption(
          id: 'one',
          label: 'First state',
          group: 'Status',
          onSelected: () {},
        ),
      ], busy: true),
    );
    expect(find.text('Applying…'), findsOneWidget);
  });

  testWidgets('ordinary accounts cannot see the dropdown', (tester) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpWidget(
      _host([
        ZyraDevPageOption(
          id: 'one',
          label: 'First state',
          group: 'Status',
          onSelected: () {},
        ),
      ]),
    );
    expect(_dropdown, findsNothing);
  });

  testWidgets('authorization loss refuses an already-open selection', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      _host([
        ZyraDevPageOption(
          id: 'one',
          label: 'First state',
          group: 'Status',
          onSelected: () {
            calls++;
          },
        ),
      ]),
    );
    await _open(tester);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('dev_page_options_inline_menu')),
      findsNothing,
    );
    expect(calls, 0);
    expect(_dropdown, findsNothing);
  });

  testWidgets('page change refuses a stale menu even with reused option IDs', (
    tester,
  ) async {
    var first = 0;
    var second = 0;
    await tester.pumpWidget(
      _host([
        ZyraDevPageOption(
          id: 'same',
          label: 'First state',
          group: 'Status',
          onSelected: () {
            first++;
          },
        ),
      ]),
    );
    await _open(tester);
    await tester.pumpWidget(
      _host([
        ZyraDevPageOption(
          id: 'same',
          label: 'Second state',
          group: 'Status',
          onSelected: () {
            second++;
          },
        ),
      ], contextKey: 'page-b'),
    );
    expect(
      find.byKey(const ValueKey('dev_page_options_inline_menu')),
      findsNothing,
    );
    expect([first, second], [0, 0]);
  });

  testWidgets('removing an option while open prevents its stale callback', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      _host([
        ZyraDevPageOption(
          id: 'old',
          label: 'Old state',
          group: 'Status',
          onSelected: () {
            calls++;
          },
        ),
      ]),
    );
    await _open(tester);
    await tester.pumpWidget(
      _host([
        ZyraDevPageOption(
          id: 'new',
          label: 'New state',
          group: 'Status',
          onSelected: () {
            calls++;
          },
        ),
      ]),
    );
    expect(
      find.byKey(const ValueKey('dev_page_options_inline_menu')),
      findsNothing,
    );
    expect(calls, 0);
  });

  testWidgets('failed callback is visible and is not promoted to selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host([
        ZyraDevPageOption(
          id: 'failure',
          label: 'Unavailable action',
          group: 'Status',
          onSelected: () {
            throw StateError('fixture failure');
          },
        ),
      ]),
    );
    await _open(tester);
    await tester.tap(find.text('Unavailable action').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dev_page_option_error')), findsOneWidget);
    expect(find.text('Choose a page option'), findsOneWidget);
  });

  testWidgets('late async completion cannot mark a different page selected', (
    tester,
  ) async {
    final completion = Completer<void>();
    await tester.pumpWidget(
      _host([
        ZyraDevPageOption(
          id: 'old',
          label: 'Old action',
          group: 'Status',
          onSelected: () => completion.future,
        ),
      ]),
    );
    await _open(tester);
    await tester.tap(find.text('Old action').last);
    await tester.pumpAndSettle();
    expect(find.text('Applying…'), findsOneWidget);
    await tester.pumpWidget(
      _host([
        ZyraDevPageOption(
          id: 'new',
          label: 'New state',
          group: 'Status',
          onSelected: () {},
        ),
      ], contextKey: 'page-b'),
    );
    completion.complete();
    await tester.pumpAndSettle();
    expect(find.text('Choose a page option'), findsOneWidget);
    expect(find.byKey(const ValueKey('dev_page_option_error')), findsNothing);
  });

  testWidgets(
    'long names and disabled explanations fit a narrow large-text menu',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _host([
          ZyraDevPageOption(
            id: 'long',
            label: 'A longer page option that wraps',
            group: 'Available content',
            selected: true,
            onSelected: () {},
          ),
          const ZyraDevPageOption(
            id: 'denied',
            label: 'Unavailable role-aware content',
            group: 'Restricted content',
            unavailableReason: 'Requires a Main Guardian role',
          ),
        ], textScale: 2),
      );
      expect(tester.takeException(), isNull);
      await _open(tester);
      expect(tester.takeException(), isNull);
    },
  );
}
