import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_browse_utility_presentation.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_floating_surface.dart';
import 'package:zyra/widgets/zyra_tap_feedback.dart';

const _font = 'PoppinsDraftBrowseUtilities';

const _sara = SeekerProfile(
  id: 'utility-sara',
  firstName: 'Sara',
  surnameLine: 'Ahmed',
  age: 27,
  city: 'Birmingham',
  gender: 'female',
  photos: [],
);
const _other = SeekerProfile(
  id: 'utility-amira',
  firstName: 'Amira',
  surnameLine: 'Rahman',
  age: 28,
  city: 'Manchester',
  gender: 'female',
  photos: ['https://example.invalid/not-a-member-photo.jpg'],
);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    ++attempts;
    throw StateError('Display-only Browse utilities must remain offline.');
  }
}

Finder _key(String id) => find.byKey(ValueKey(id));

Widget _app(Widget child, {double scale = 1, bool reduce = false}) =>
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, content) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          disableAnimations: reduce,
        ),
        child: content!,
      ),
      home: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: ZyraTapFeedback(
                level: () => ZyraHapticLevel.subtle,
                canAct: () => true,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(393, 852),
  double scale = 1,
  bool reduce = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(child, scale: scale, reduce: reduce));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectFit(WidgetTester tester, String viewportId, String actionId) {
  final scrollable = find.descendant(
    of: _key(viewportId),
    matching: find.byType(Scrollable),
  );
  final position = tester.state<ScrollableState>(scrollable).position;
  expect(position.pixels, 0);
  expect(position.maxScrollExtent, closeTo(0, .01));
  final action = tester.getRect(_key(actionId));
  expect(action.left, greaterThanOrEqualTo(20));
  expect(action.right, lessThanOrEqualTo(tester.view.physicalSize.width - 20));
  expect(
    action.bottom,
    lessThanOrEqualTo(tester.view.physicalSize.height - 50),
  );
  expect(action.height, greaterThanOrEqualTo(44));
}

void _expectTitle(WidgetTester tester, String id, String title) {
  final text = tester.widget<Text>(_key(id));
  expect(text.data, title);
  expect(text.textAlign, TextAlign.left);
  expect(text.style!.fontSize, 26);
  expect(text.style!.fontFamily, ZyraText.heading(size: 26).fontFamily);
  final rect = tester.getRect(_key(id));
  expect(rect.left, closeTo(20, .01));
  expect(rect.top, closeTo(75, .01));
}

Future<void> _tap(WidgetTester tester, String id) async {
  await tester.ensureVisible(_key(id));
  await tester.pumpAndSettle();
  expect(_key(id).hitTestable(), findsOneWidget);
  await tester.tap(_key(id));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectSelection(WidgetTester tester, ZyraDraftReportReason selected) {
  expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
  expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(6));
  for (final reason in ZyraDraftReportReason.values) {
    final row = _key('draft_report_reason_${reason.name}');
    expect(
      find.descendant(
        of: row,
        matching: find.byIcon(
          reason == selected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
        ),
      ),
      findsOneWidget,
    );
  }
  final icon = tester.widget<Icon>(find.byIcon(Icons.radio_button_checked));
  expect(icon.color, ZyraColors.journeyGold);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final priorHttp = HttpOverrides.current;
  final priorFatal = WidgetController.hitTestWarningShouldBeFatal;
  final priorReadingFont = ZyraText.testReadingFontFamily;
  final priorFontStubs = ZyraText.useTestFontStubs;
  late _NoNetwork network;
  final haptics = <Object?>[];
  setUpAll(() async {
    final font = FontLoader(_font);
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      font.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    network = _NoNetwork();
    HttpOverrides.global = network;
    WidgetController.hitTestWarningShouldBeFatal = true;
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        });
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = priorHttp;
    ZyraText.useTestFontStubs = priorFontStubs;
    ZyraText.testReadingFontFamily = priorReadingFont;
    WidgetController.hitTestWarningShouldBeFatal = priorFatal;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final size in const [Size(390, 844), Size(393, 852), Size(430, 932)]) {
    testWidgets('Scan fits $size with a truthful disabled camera action', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(tester, const ZyraDraftScanPresentation(), size: size);
      _expectTitle(tester, 'draft_scan_title', 'Scan');
      _expectFit(tester, 'draft_scan_viewport', 'draft_scan_action');
      final frame = tester.getRect(_key('draft_scan_frame'));
      expect(frame.width, closeTo(frame.height, .01));
      expect(frame.width, greaterThan(200));
      expect(frame.left, greaterThanOrEqualTo(20));
      expect(frame.right, lessThanOrEqualTo(size.width - 20));
      expect(
        tester.widget<OutlinedButton>(_key('draft_scan_action')).onPressed,
        isNull,
      );
      expect(find.text('Scanning isn’t available yet.'), findsOneWidget);
      expect(find.text('PREVIEW ONLY'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Report fits $size with all reasons and no submission', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(
        tester,
        ZyraDraftReportPresentation(
          profile: _sara,
          onHide: () {},
          onBlock: () {},
        ),
        size: size,
      );
      _expectTitle(tester, 'draft_report_title', 'Report profile');
      _expectFit(tester, 'draft_report_viewport', 'draft_report_submit');
      expect(_key('draft_report_target'), findsOneWidget);
      expect(find.text('Sara Ahmed'), findsOneWidget);
      final name = tester.widget<Text>(find.text('Sara Ahmed'));
      expect(name.style!.fontSize, 22);
      expect(name.style!.fontWeight, FontWeight.w300);
      expect(find.text('CHOOSE THE REASON'), findsOneWidget);
      expect(find.text('Select the reason for your concern.'), findsNothing);
      expect(tester.getSize(_key('draft_report_photo')), const Size.square(72));
      final photo = tester.widget<Container>(_key('draft_report_photo'));
      final photoDecoration = photo.decoration! as BoxDecoration;
      expect(photoDecoration.shape, BoxShape.circle);
      expect(
        (photoDecoration.border! as Border).top.color,
        const Color(0xFFA9792E).withValues(alpha: .7),
      );
      expect(
        find.descendant(
          of: _key('draft_report_photo'),
          matching: find.byType(ClipOval),
        ),
        findsOneWidget,
      );
      final card = _key('draft_report_reason_card');
      final cardRect = tester.getRect(card);
      expect(tester.widget<ZyraFloatingSurface>(card).radius, 20);
      expect(cardRect.left, closeTo(20, .01));
      expect(cardRect.right, closeTo(size.width - 20, .01));
      expect(
        find.descendant(of: card, matching: find.byType(OutlinedButton)),
        findsNWidgets(7),
      );
      expect(ZyraDraftReportReason.values.map((reason) => reason.label), [
        'Impersonation or fake profile',
        'Nudity or sexual content',
        'Harassment or abusive behaviour',
        'Minor or underage',
        'Violence or disturbing content',
        'Privacy or personal information',
        'Something else',
      ]);
      var previousBottom = cardRect.top;
      for (final reason in ZyraDraftReportReason.values) {
        final row = _key('draft_report_reason_${reason.name}');
        final rect = tester.getRect(row);
        expect(rect.left, greaterThan(cardRect.left));
        expect(rect.right, lessThan(cardRect.right));
        expect(rect.top, greaterThanOrEqualTo(previousBottom));
        expect(rect.height, greaterThanOrEqualTo(44));
        expect(find.text(reason.label), findsOneWidget);
        final surfaces = find.ancestor(
          of: row,
          matching: find.byType(ZyraFloatingSurface),
        );
        expect(surfaces, findsOneWidget);
        expect(
          tester.widget(surfaces).key,
          const ValueKey('draft_report_reason_card'),
        );
        final style = tester.widget<OutlinedButton>(row).style!;
        expect(style.backgroundColor!.resolve({}), Colors.transparent);
        expect(style.side!.resolve({}), BorderSide.none);
        previousBottom = rect.bottom;
      }
      expect(previousBottom, lessThanOrEqualTo(cardRect.bottom));
      _expectSelection(tester, ZyraDraftReportReason.fakeProfile);
      expect(
        tester.widget<OutlinedButton>(_key('draft_report_submit')).onPressed,
        isNull,
      );
      expect(
        find.text('Reporting isn’t available for this profile.'),
        findsNothing,
      );
      expect(find.text('Safety, always.'), findsNothing);
      expect(find.text('Report · sample only'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('seven mandatory radio reasons stay local with Submit disabled', (
    tester,
  ) async {
    var hidden = 0, blocked = 0;
    await _mount(
      tester,
      ZyraDraftReportPresentation(
        profile: _sara,
        onHide: () => hidden++,
        onBlock: () => blocked++,
      ),
    );
    _expectSelection(tester, ZyraDraftReportReason.fakeProfile);
    for (final reason in ZyraDraftReportReason.values) {
      await _tap(tester, 'draft_report_reason_${reason.name}');
      _expectSelection(tester, reason);
      expect(
        tester.widget<OutlinedButton>(_key('draft_report_submit')).onPressed,
        isNull,
      );
      expect((hidden, blocked), (0, 0));
    }
    await _tap(tester, 'draft_report_reason_other');
    _expectSelection(tester, ZyraDraftReportReason.other);
    expect(find.textContaining('submitted'), findsNothing);
  });

  testWidgets('target-free account Safety does not choose a previous person', (
    tester,
  ) async {
    await _mount(tester, const ZyraDraftReportPresentation());
    _expectTitle(tester, 'draft_report_title', 'Safety');
    expect(find.text('Choose a profile to report'), findsOneWidget);
    expect(_key('draft_report_target'), findsNothing);
    expect(find.text('Sara Ahmed'), findsNothing);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
    expect(_key('draft_safety_hide'), findsNothing);
    expect(_key('draft_safety_block'), findsNothing);
    expect(_key('draft_report_submit'), findsNothing);
  });

  for (final scan in [false, true]) {
    testWidgets('large-text ${scan ? 'Scan' : 'Report'} remains readable', (
      tester,
    ) async {
      await _mount(
        tester,
        scan
            ? const ZyraDraftScanPresentation()
            : ZyraDraftReportPresentation(
                profile: _sara,
                onHide: () {},
                onBlock: () {},
              ),
        size: const Size(320, 568),
        scale: 2,
        reduce: true,
      );
      if (!scan) {
        _expectSelection(tester, ZyraDraftReportReason.fakeProfile);
        for (final reason in ZyraDraftReportReason.values) {
          final row = _key('draft_report_reason_${reason.name}');
          await _tap(tester, 'draft_report_reason_${reason.name}');
          final rowBounds = tester.getRect(row);
          final labelBounds = tester.getRect(find.text(reason.label));
          expect(rowBounds.left, greaterThanOrEqualTo(20));
          expect(rowBounds.right, lessThanOrEqualTo(300));
          expect(labelBounds.left, greaterThanOrEqualTo(rowBounds.left));
          expect(labelBounds.right, lessThanOrEqualTo(rowBounds.right));
          _expectSelection(tester, reason);
        }
      }
      final action = scan ? 'draft_scan_action' : 'draft_report_submit';
      await tester.ensureVisible(_key(action));
      await tester.pumpAndSettle();
      final bounds = tester.getRect(_key(action));
      expect(bounds.left, greaterThanOrEqualTo(20));
      expect(bounds.right, lessThanOrEqualTo(300));
      expect(bounds.height, greaterThanOrEqualTo(48));
      if (!scan) {
        expect(tester.widget<OutlinedButton>(_key(action)).onPressed, isNull);
        for (final id in ['draft_safety_hide', 'draft_safety_block']) {
          await tester.ensureVisible(_key(id));
          await tester.pumpAndSettle();
          expect(_key(id).hitTestable(), findsOneWidget);
          final actionBounds = tester.getRect(_key(id));
          expect(actionBounds.left, greaterThanOrEqualTo(20));
          expect(actionBounds.right, lessThanOrEqualTo(300));
          expect(actionBounds.height, greaterThanOrEqualTo(44));
        }
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'guard revocation rejects retained reason and secondary actions',
    (tester) async {
      var allowed = true;
      var hidden = 0, blocked = 0;
      await _mount(
        tester,
        ZyraDraftReportPresentation(
          profile: _sara,
          canSelect: () => allowed,
          onHide: () => hidden++,
          onBlock: () => blocked++,
        ),
      );
      await _tap(tester, 'draft_report_reason_other');
      final reason = tester
          .widget<OutlinedButton>(_key('draft_report_reason_fakeProfile'))
          .onPressed!;
      final hide = tester
          .widget<TextButton>(_key('draft_safety_hide'))
          .onPressed!;
      final block = tester
          .widget<TextButton>(_key('draft_safety_block'))
          .onPressed!;
      haptics.clear();
      allowed = false;
      reason();
      hide();
      block();
      await tester.pumpAndSettle();
      _expectSelection(tester, ZyraDraftReportReason.other);
      expect((hidden, blocked), (0, 0));
      expect(haptics, isEmpty);
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      allowed = true;
      reason();
      hide();
      block();
      await tester.pump();
      expect((hidden, blocked), (0, 0));
      expect(haptics, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('target replacement resets radio and revokes old delegates', (
    tester,
  ) async {
    var hidden = 0, blocked = 0;
    await _mount(
      tester,
      ZyraDraftReportPresentation(
        profile: _sara,
        onHide: () => hidden++,
        onBlock: () => blocked++,
      ),
    );
    await _tap(tester, 'draft_report_reason_privacy');
    final retainedReason = tester
        .widget<OutlinedButton>(_key('draft_report_reason_other'))
        .onPressed!;
    final retainedHide = tester
        .widget<TextButton>(_key('draft_safety_hide'))
        .onPressed!;
    final retainedBlock = tester
        .widget<TextButton>(_key('draft_safety_block'))
        .onPressed!;
    await tester.pumpWidget(
      _app(
        ZyraDraftReportPresentation(
          profile: _other,
          onHide: () => hidden++,
          onBlock: () => blocked++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    haptics.clear();
    retainedReason();
    retainedHide();
    retainedBlock();
    await tester.pumpAndSettle();
    expect(find.text('Amira Rahman'), findsOneWidget);
    expect(find.text('Sara Ahmed'), findsNothing);
    _expectSelection(tester, ZyraDraftReportReason.fakeProfile);
    expect((hidden, blocked), (0, 0));
    expect(haptics, isEmpty);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets(
    'same-owner rebuild preserves radio and revokes prior callbacks',
    (tester) async {
      final owner = Object();
      var hidden = 0, blocked = 0;
      Widget report() => ZyraDraftReportPresentation(
        profile: _sara,
        ownerIdentity: owner,
        onHide: () => hidden++,
        onBlock: () => blocked++,
      );
      await _mount(tester, report());
      await _tap(tester, 'draft_report_reason_privacy');
      final retainedReason = tester
          .widget<OutlinedButton>(_key('draft_report_reason_other'))
          .onPressed!;
      final retainedHide = tester
          .widget<TextButton>(_key('draft_safety_hide'))
          .onPressed!;
      final retainedBlock = tester
          .widget<TextButton>(_key('draft_safety_block'))
          .onPressed!;
      await tester.pumpWidget(_app(report()));
      await tester.pumpAndSettle();
      haptics.clear();
      retainedReason();
      retainedHide();
      retainedBlock();
      await tester.pumpAndSettle();
      _expectSelection(tester, ZyraDraftReportReason.privacy);
      expect((hidden, blocked), (0, 0));
      expect(haptics, isEmpty);
      await _tap(tester, 'draft_report_reason_other');
      _expectSelection(tester, ZyraDraftReportReason.other);
      expect(haptics, ['HapticFeedbackType.selectionClick']);
    },
  );

  testWidgets('same-subject owner replacement resets radio before feedback', (
    tester,
  ) async {
    var hidden = 0, blocked = 0;
    Widget report(Object owner) => ZyraDraftReportPresentation(
      profile: _sara,
      ownerIdentity: owner,
      onHide: () => hidden++,
      onBlock: () => blocked++,
    );
    await _mount(tester, report(Object()));
    await _tap(tester, 'draft_report_reason_other');
    final retainedReason = tester
        .widget<OutlinedButton>(_key('draft_report_reason_privacy'))
        .onPressed!;
    final retainedHide = tester
        .widget<TextButton>(_key('draft_safety_hide'))
        .onPressed!;
    final retainedBlock = tester
        .widget<TextButton>(_key('draft_safety_block'))
        .onPressed!;
    await tester.pumpWidget(_app(report(Object())));
    await tester.pumpAndSettle();
    haptics.clear();
    retainedReason();
    retainedHide();
    retainedBlock();
    await tester.pumpAndSettle();
    _expectSelection(tester, ZyraDraftReportReason.fakeProfile);
    expect((hidden, blocked), (0, 0));
    expect(haptics, isEmpty);
    await _tap(tester, 'draft_safety_hide');
    await _tap(tester, 'draft_safety_block');
    expect((hidden, blocked), (1, 1));
    expect(haptics, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.selectionClick',
    ]);
  });

  testWidgets('subject removal keeps Safety free of retained report actions', (
    tester,
  ) async {
    var hidden = 0, blocked = 0;
    await _mount(
      tester,
      ZyraDraftReportPresentation(
        profile: _sara,
        onHide: () => hidden++,
        onBlock: () => blocked++,
      ),
    );
    await _tap(tester, 'draft_report_reason_other');
    final retainedReason = tester
        .widget<OutlinedButton>(_key('draft_report_reason_privacy'))
        .onPressed!;
    final retainedHide = tester
        .widget<TextButton>(_key('draft_safety_hide'))
        .onPressed!;
    final retainedBlock = tester
        .widget<TextButton>(_key('draft_safety_block'))
        .onPressed!;
    await tester.pumpWidget(_app(const ZyraDraftReportPresentation()));
    await tester.pumpAndSettle();
    haptics.clear();
    retainedReason();
    retainedHide();
    retainedBlock();
    await tester.pumpAndSettle();
    _expectTitle(tester, 'draft_report_title', 'Safety');
    expect(_key('draft_report_target'), findsNothing);
    expect(_key('draft_report_reason_card'), findsNothing);
    expect(_key('draft_report_submit'), findsNothing);
    expect((hidden, blocked), (0, 0));
    expect(haptics, isEmpty);
    await tester.pumpWidget(
      _app(const ZyraDraftReportPresentation(profile: _sara)),
    );
    await tester.pumpAndSettle();
    _expectSelection(tester, ZyraDraftReportReason.fakeProfile);
  });

  testWidgets('secondary actions remain explicit caller-owned actions', (
    tester,
  ) async {
    var hidden = 0, blocked = 0;
    await _mount(
      tester,
      ZyraDraftReportPresentation(
        profile: _sara,
        onHide: () => hidden++,
        onBlock: () => blocked++,
      ),
    );
    await _tap(tester, 'draft_safety_hide');
    await _tap(tester, 'draft_safety_block');
    expect((hidden, blocked), (1, 1));
    expect(
      tester.widget<OutlinedButton>(_key('draft_report_submit')).onPressed,
      isNull,
    );
  });

  for (final reducedMotion in [false, true]) {
    testWidgets('utility display settles with reduced motion $reducedMotion', (
      tester,
    ) async {
      await _mount(
        tester,
        const ZyraDraftScanPresentation(),
        reduce: reducedMotion,
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(
        _app(
          const ZyraDraftReportPresentation(profile: _sara),
          reduce: reducedMotion,
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, 'draft_report_reason_fakeProfile');
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}
