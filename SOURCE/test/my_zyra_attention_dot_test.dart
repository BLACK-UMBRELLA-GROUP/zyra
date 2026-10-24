import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_supportive_dashboard_preview.dart';
import 'package:zyra/models/zyra_supportive_dashboard.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';

enum _TitleCase { prominent, compact, regular, summary, expanded }

const _longTitle =
    'Maryam-Alexandria and Abdurrahman-Muhammad have a Journey request to review together';

SupportiveCard _card(
  _TitleCase variant, {
  String title = 'A new Journey update',
  bool hasNewActivity = true,
  bool? isUnread,
}) => SupportiveCard(
  id: 'attention-${variant.name}',
  section: switch (variant) {
    _TitleCase.prominent || _TitleCase.compact => SupportiveSection.needsYou,
    _TitleCase.regular => SupportiveSection.stand,
    _TitleCase.summary || _TitleCase.expanded => SupportiveSection.changed,
  },
  title: title,
  hasNewActivity: hasNewActivity,
  isUnread: isUnread,
);

List<SupportiveCard> _cards(_TitleCase variant, SupportiveCard card) => [
  if (variant == _TitleCase.compact)
    const SupportiveCard(
      id: 'leading-action',
      section: SupportiveSection.needsYou,
      title: 'Your first action',
    ),
  card,
];

Matcher _activitySemantics(_TitleCase variant, SupportiveCard card) =>
    matchesSemantics(
      label: [
        if (variant == _TitleCase.compact) 'Your first action',
        card.title,
        'New activity',
      ].join('\n'),
      hasExpandedState:
          variant == _TitleCase.summary || variant == _TitleCase.expanded,
      isExpanded: variant == _TitleCase.expanded,
    );

Widget _app(List<SupportiveCard> cards, {double scale = 1}) {
  final fixture = SupportiveDashboardFixtures.build(
    SupportivePreviewScenario.allClear,
  );
  return MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: child!,
    ),
    home: ZyraQuietDashboard(
      resolution: fixture.resolution,
      fixtureCards: cards,
      fixtureMode: true,
      singlePage: true,
      comparisonClock: SupportiveDashboardFixtures.clock,
    ),
  );
}

Finder get _scrollable => find.descendant(
  of: find.byKey(const ValueKey('my-zyra-quiet-scroll-0')),
  matching: find.byType(Scrollable),
);

Future<void> _reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    120,
    scrollable: _scrollable,
    maxScrolls: 40,
  );
  await tester.pumpAndSettle();
}

Future<void> _mount(
  WidgetTester tester,
  _TitleCase variant,
  SupportiveCard card, {
  double scale = 1,
}) async {
  await tester.pumpWidget(_app(_cards(variant, card), scale: scale));
  await tester.pumpAndSettle();
  if (variant == _TitleCase.expanded) {
    final disclosure = find.byKey(
      ValueKey('quiet-index-disclosure-${card.id}'),
    );
    await _reveal(tester, disclosure);
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('quiet-index-details-${card.id}')),
      findsOneWidget,
    );
  }
  await _reveal(tester, find.text(card.title));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => ZyraText.useTestFontStubs = true);
  tearDownAll(() => ZyraText.useTestFontStubs = false);
  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
  });
  tearDown(() => ZyraDeveloperAccess.setAuthorizedForTesting(false));

  test(
    'activity defaults false independently of notification unread state',
    () {
      const plain = SupportiveCard(
        id: 'plain',
        section: SupportiveSection.changed,
        title: 'An existing update',
      );
      const unread = SupportiveCard(
        id: 'unread',
        section: SupportiveSection.changed,
        title: 'An unread notification',
        isUnread: true,
      );
      const activity = SupportiveCard(
        id: 'activity',
        section: SupportiveSection.changed,
        title: 'New local activity',
        hasNewActivity: true,
      );
      expect(plain.hasNewActivity, isFalse);
      expect(plain.isUnread, isNull);
      expect(unread.hasNewActivity, isFalse);
      expect(unread.isUnread, isTrue);
      expect(activity.hasNewActivity, isTrue);
      expect(activity.isUnread, isNull);
    },
  );

  for (final variant in _TitleCase.values) {
    testWidgets('${variant.name} keeps activity semantics without a dot', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final card = _card(variant);
        await _mount(tester, variant, card);
        final activity = find.byKey(ValueKey('my-zyra-activity-${card.id}'));
        final title = find.text(card.title);
        expect(activity, findsOneWidget);
        expect(find.byKey(ValueKey('my-zyra-new-${card.id}')), findsNothing);
        expect(tester.getSize(activity), tester.getSize(title));
        expect(
          tester.getSemantics(activity),
          _activitySemantics(variant, card),
        );
        expect(
          find.descendant(of: activity, matching: find.byType(DecoratedBox)),
          findsNothing,
        );
        expect(find.text('Unread'), findsNothing);
        expect(find.byKey(ValueKey('my-zyra-route-${card.id}')), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('${variant.name} false preserves the unwrapped title branch', (
      tester,
    ) async {
      final card = _card(variant, hasNewActivity: false, isUnread: true);
      await _mount(tester, variant, card);
      final title = find.text(card.title);
      expect(find.byKey(ValueKey('my-zyra-new-${card.id}')), findsNothing);
      expect(
        find.ancestor(of: title, matching: find.byType(Row)),
        findsNothing,
      );
      final text = tester.widget<Text>(title);
      final expectedStyle = switch (variant) {
        _TitleCase.prominent => ZyraText.heading(
          size: 29,
          color: const Color(0xFFF6F0F8),
        ).copyWith(height: 1.22),
        _TitleCase.summary => ZyraText.heading(
          size: 18,
          color: const Color(0xFFF6F0F8),
        ).copyWith(height: 1.22),
        _ => ZyraText.body(
          size: variant == _TitleCase.compact ? 14 : 17,
          color: const Color(0xFFF6F0F8),
        ).copyWith(height: 1.45),
      };
      expect(text.style, expectedStyle);
      expect(find.text('Unread'), findsOneWidget);
      expect(card.isUnread, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${variant.name} activity wraps fully at 320px and 2x', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        final card = _card(variant, title: _longTitle);
        await _mount(tester, variant, card, scale: 2);
        final title = find.text(card.title);
        final text = tester.widget<Text>(title);
        final paragraph = tester.renderObject<RenderParagraph>(title);
        final activity = find.byKey(ValueKey('my-zyra-activity-${card.id}'));
        expect(text.maxLines, isNull);
        expect(text.overflow, isNot(TextOverflow.ellipsis));
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(tester.getSize(title).height, greaterThan(60));
        expect(tester.getTopLeft(title).dx, greaterThanOrEqualTo(24));
        expect(tester.getBottomRight(title).dx, lessThanOrEqualTo(296));
        expect(tester.getSize(activity), tester.getSize(title));
        expect(find.byKey(ValueKey('my-zyra-new-${card.id}')), findsNothing);
        expect(
          tester.getSemantics(activity),
          _activitySemantics(variant, card),
        );
        expect(
          tester.getSemantics(title).id,
          tester.getSemantics(activity).id,
          reason: 'The complete title and activity share one announcement.',
        );
        final lastCharacter = paragraph.getBoxesForSelection(
          TextSelection(
            baseOffset: card.title.length - 1,
            extentOffset: card.title.length,
          ),
        );
        expect(lastCharacter, isNotEmpty);
        expect(
          lastCharacter.single.right,
          lessThanOrEqualTo(paragraph.size.width),
        );
        final position = tester.state<ScrollableState>(_scrollable).position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pump();
        final lastTop = paragraph.localToGlobal(
          Offset(lastCharacter.single.left, lastCharacter.single.top),
        );
        final lastBottom = paragraph.localToGlobal(
          Offset(lastCharacter.single.right, lastCharacter.single.bottom),
        );
        expect(lastTop.dy, greaterThanOrEqualTo(0));
        expect(lastBottom.dy, lessThanOrEqualTo(568));
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  for (final isUnread in <bool?>[null, false, true]) {
    testWidgets('activity does not change explicit unread value $isUnread', (
      tester,
    ) async {
      final card = _card(_TitleCase.summary, isUnread: isUnread);
      await _mount(tester, _TitleCase.summary, card);
      expect(find.byKey(ValueKey('my-zyra-new-${card.id}')), findsNothing);
      expect(
        find.byKey(ValueKey('my-zyra-activity-${card.id}')),
        findsOneWidget,
      );
      expect(
        find.text('Unread'),
        isUnread == true ? findsOneWidget : findsNothing,
      );
      await tester.tap(
        find.byKey(ValueKey('quiet-index-disclosure-${card.id}')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('my-zyra-new-${card.id}')), findsNothing);
      expect(
        find.byKey(ValueKey('my-zyra-activity-${card.id}')),
        findsOneWidget,
      );
      expect(card.isUnread, isUnread);
      expect(
        find.text('Unread'),
        isUnread == true ? findsOneWidget : findsNothing,
      );
      expect(find.byKey(const ValueKey('quiet-index-mark-read')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
