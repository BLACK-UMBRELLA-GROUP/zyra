import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_browse_utility_presentation.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

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
              child: child,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final priorHttp = HttpOverrides.current;
  final priorFatal = WidgetController.hitTestWarningShouldBeFatal;
  final priorReadingFont = ZyraText.testReadingFontFamily;
  final priorFontStubs = ZyraText.useTestFontStubs;
  late _NoNetwork network;
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
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = priorHttp;
    ZyraText.useTestFontStubs = priorFontStubs;
    ZyraText.testReadingFontFamily = priorReadingFont;
    WidgetController.hitTestWarningShouldBeFatal = priorFatal;
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
      for (final reason in ZyraDraftReportReason.values) {
        final rect = tester.getRect(_key('draft_report_reason_${reason.name}'));
        expect(rect.left, closeTo(20, .01));
        expect(rect.right, closeTo(size.width - 20, .01));
        expect(rect.height, greaterThanOrEqualTo(44));
        expect(find.text(reason.label), findsOneWidget);
      }
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

  testWidgets('reasons only select locally and never enable submission', (
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
    expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    for (final reason in ZyraDraftReportReason.values) {
      await _tap(tester, 'draft_report_reason_${reason.name}');
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(
        tester.widget<OutlinedButton>(_key('draft_report_submit')).onPressed,
        isNull,
      );
      expect((hidden, blocked), (0, 0));
    }
    await _tap(tester, 'draft_report_reason_other');
    expect(find.byIcon(Icons.radio_button_checked), findsNothing);
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
      final action = scan ? 'draft_scan_action' : 'draft_report_submit';
      await tester.ensureVisible(_key(action));
      await tester.pumpAndSettle();
      final bounds = tester.getRect(_key(action));
      expect(bounds.left, greaterThanOrEqualTo(20));
      expect(bounds.right, lessThanOrEqualTo(300));
      expect(bounds.height, greaterThanOrEqualTo(48));
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
      final reason = tester
          .widget<OutlinedButton>(_key('draft_report_reason_fakeProfile'))
          .onPressed!;
      final hide = tester
          .widget<TextButton>(_key('draft_safety_hide'))
          .onPressed!;
      final block = tester
          .widget<TextButton>(_key('draft_safety_block'))
          .onPressed!;
      allowed = false;
      reason();
      hide();
      block();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
      expect((hidden, blocked), (0, 0));
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      reason();
      hide();
      block();
      expect((hidden, blocked), (0, 0));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('target replacement clears selection and revokes old delegates', (
    tester,
  ) async {
    var hidden = 0;
    await _mount(
      tester,
      ZyraDraftReportPresentation(profile: _sara, onHide: () => hidden++),
    );
    await _tap(tester, 'draft_report_reason_fakeProfile');
    final retainedReason = tester
        .widget<OutlinedButton>(_key('draft_report_reason_other'))
        .onPressed!;
    final retainedHide = tester
        .widget<TextButton>(_key('draft_safety_hide'))
        .onPressed!;
    await tester.pumpWidget(
      _app(
        ZyraDraftReportPresentation(profile: _other, onHide: () => hidden++),
      ),
    );
    await tester.pumpAndSettle();
    retainedReason();
    retainedHide();
    await tester.pumpAndSettle();
    expect(find.text('Amira Rahman'), findsOneWidget);
    expect(find.text('Sara Ahmed'), findsNothing);
    expect(find.byIcon(Icons.radio_button_checked), findsNothing);
    expect(hidden, 0);
    expect(find.byType(Image), findsNothing);
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
