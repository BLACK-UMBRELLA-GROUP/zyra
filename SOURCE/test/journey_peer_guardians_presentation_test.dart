import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_journey_peer_guardians_presentation.dart';
import 'package:zyra/services/zyra_guardian_info_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _captureDirectory = String.fromEnvironment(
  'ZYRA_PEER_GUARDIAN_CAPTURE_DIR',
);
const _captureFont = 'PoppinsPeerGuardianPager';
const _captureKey = ValueKey('peer-guardian-pager-capture');
const _subject = 'peer-sara';
const _longCity = 'Birmingham, West Midlands, United Kingdom';

const _ibrahim = GuardianInfo(
  firstName: 'Ibrahim',
  relationship: 'uncle',
  isMain: true,
  city: 'Birmingham',
  gender: 'male',
);
const _maryam = GuardianInfo(firstName: 'Maryam', relationship: 'sister');
const _yusuf = GuardianInfo(firstName: 'Yusuf', relationship: 'grandfather');
const _longGuardian = GuardianInfo(
  firstName: 'Abdul Rahman',
  relationship: 'grandfather',
  city: _longCity,
  gender: 'male',
);

void _noop() {}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Peer Guardian presentation must remain offline.');
  }
}

Finder _key(String value) => find.byKey(ValueKey(value));

void _expectNoException(WidgetTester tester) {
  final exception = tester.takeException();
  expect(
    exception,
    isNull,
    reason: exception is FlutterError
        ? exception.diagnostics.map((node) => node.toStringDeep()).join('\n')
        : null,
  );
}

Finder _pager([String subjectId = _subject]) =>
    _key('peer_guardians_pager_$subjectId');

PageView _pageView(WidgetTester tester, [String subjectId = _subject]) =>
    tester.widget<PageView>(_pager(subjectId));

ScrollableState _reader(
  WidgetTester tester,
  int index, [
  String subjectId = _subject,
]) => tester.state<ScrollableState>(
  find.descendant(
    of: _key('peer_guardian_reader_${subjectId}_$index'),
    matching: find.byType(Scrollable),
  ),
);

Future<void> _swipe(
  WidgetTester tester, {
  bool forward = true,
  String subjectId = _subject,
}) async {
  final bounds = tester.getRect(_pager(subjectId));
  await tester.timedDragFrom(
    Offset(bounds.left + bounds.width * (forward ? .8 : .2), bounds.center.dy),
    Offset(bounds.width * (forward ? -.6 : .6), 0),
    const Duration(milliseconds: 400),
  );
  await tester.pumpAndSettle();
  _expectNoException(tester);
}

void _expectDots(
  WidgetTester tester,
  int selected, {
  int count = 3,
  String subjectId = _subject,
}) {
  final position = tester.widget<Semantics>(
    _key('peer_guardians_position_$subjectId'),
  );
  expect(position.properties.label, 'Guardian ${selected + 1} of $count');
  for (var index = 0; index < count; index++) {
    final dot = _key('peer_guardian_dot_${subjectId}_$index');
    expect(tester.getSize(dot), Size(index == selected ? 30 : 6, 6));
    final decoration =
        tester.widget<AnimatedContainer>(dot).decoration! as BoxDecoration;
    expect(
      decoration.color,
      index == selected ? ZyraColors.journeyGold : ZyraColors.ink(.35),
    );
  }
}

void _expectReadOnly() {
  final content = find.byType(ZyraJourneyPeerGuardiansPresentation);
  expect(content, findsOneWidget);
  for (final type in [
    Switch,
    TextButton,
    ElevatedButton,
    OutlinedButton,
    IconButton,
    TextField,
    FittedBox,
  ]) {
    expect(
      find.descendant(of: content, matching: find.byType(type)),
      findsNothing,
    );
  }
  expect(
    find.descendant(
      of: content,
      matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
    ),
    findsNothing,
  );
  expect(find.byType(Image), findsNothing);
  for (final label in [
    'Hassan',
    'Remove Guardian',
    'Remove as Main Guardian',
    'Make Main Guardian',
    'Active Journey access',
    'Share past Journey summaries',
    'Active',
    'Linked',
    'View',
    'Chat',
    'Add Guardian',
    'Relationship not recorded',
    'Linked date not recorded',
  ]) {
    expect(find.text(label), findsNothing);
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captureDirectory/$name.png');
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

Future<void> _mount(
  WidgetTester tester, {
  List<GuardianInfo>? guardians = const [_maryam, _ibrahim, _yusuf],
  String subjectId = 'peer-sara',
  String firstName = 'Sara',
  Size size = const Size(393, 852),
  double scale = 1,
  bool wrapPull = false,
  VoidCallback onBack = _noop,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final top = size.height < 700 ? 44.0 : 59.0;
  final page = ZyraJourneyPeerGuardiansPresentation(
    subjectId: subjectId,
    firstName: firstName,
    guardians: guardians,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: EdgeInsets.only(top: top, bottom: 34),
          viewPadding: EdgeInsets.only(top: top, bottom: 34),
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _captureKey, child: child!),
      ),
      home: Scaffold(
        backgroundColor: ZyraColors.luxuryDarkPurple,
        body: wrapPull
            ? ZyraPullDownBackScope(
                routeIdentity: ('peer-guardian-test', subjectId),
                onBack: onBack,
                child: page,
              )
            : page,
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  _expectNoException(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late bool oldFontStubs;
  late String? oldFont;
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  setUpAll(() async {
    if (_captureDirectory.isNotEmpty) {
      if (!_captureDirectory.startsWith('/') ||
          FileSystemEntity.typeSync(_captureDirectory, followLinks: false) !=
              FileSystemEntityType.notFound) {
        throw StateError(
          'Peer Guardian captures require a fresh nonexistent absolute directory.',
        );
      }
      Directory(_captureDirectory).createSync(recursive: true);
    }
    final font = FontLoader(_captureFont);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
  });
  setUp(() {
    oldFontStubs = ZyraText.useTestFontStubs;
    oldFont = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _captureFont;
    oldNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = oldNetwork;
    ZyraText.useTestFontStubs = oldFontStubs;
    ZyraText.testReadingFontFamily = oldFont;
  });

  test('copies input into an immutable Main-first stable roster', () {
    const otherMain = GuardianInfo(firstName: 'Amina', isMain: true);
    final input = [_maryam, _ibrahim, _yusuf, otherMain];
    final page = ZyraJourneyPeerGuardiansPresentation(
      subjectId: 'peer-sara',
      firstName: 'Sara',
      guardians: input,
    );
    expect(page.guardians, [_ibrahim, otherMain, _maryam, _yusuf]);
    input.clear();
    expect(page.guardians, [_ibrahim, otherMain, _maryam, _yusuf]);
    expect(() => page.guardians!.add(_yusuf), throwsUnsupportedError);
    expect(() => page.guardians![0] = _yusuf, throwsUnsupportedError);
    expect(page.subjectId, 'peer-sara');
    expect(page.firstName, 'Sara');
  });

  testWidgets('shows the addressed peer and canonical left-aligned title', (
    tester,
  ) async {
    await _mount(tester, wrapPull: true);
    expect(find.text('Journey with Sara'), findsOneWidget);
    final title = tester.widget<Text>(_key('peer_guardians_title'));
    expect(title.data, 'Guardians');
    expect(title.textAlign, TextAlign.left);
    expect(title.style, ZyraText.pageTitle());
    expect(_key('peer_guardians_peer-sara'), findsOneWidget);
    expect(find.text('Ibrahim').hitTestable(), findsOneWidget);
    expect(find.text('Maryam').hitTestable(), findsNothing);
    expect(find.text('Yusuf').hitTestable(), findsNothing);
    expect(find.text('Main Guardian'), findsOneWidget);
    expect(find.text(_ibrahim.relationshipLabel!), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Birmingham'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    _expectDots(tester, 0);
    await _capture(tester, 'main_guardian');
    await _swipe(tester);
    expect(find.text('Maryam').hitTestable(), findsOneWidget);
    expect(find.text('Ibrahim').hitTestable(), findsNothing);
    expect(find.text('Yusuf').hitTestable(), findsNothing);
    expect(find.text('Additional Guardian').hitTestable(), findsOneWidget);
    _expectDots(tester, 1);
    await _capture(tester, 'additional_guardian');
    await _swipe(tester);
    expect(find.text('Yusuf').hitTestable(), findsOneWidget);
    expect(find.text('Maryam').hitTestable(), findsNothing);
    expect(find.text('Additional Guardian').hitTestable(), findsOneWidget);
    _expectDots(tester, 2);
    await _capture(tester, 'third_guardian');
    await _swipe(tester, forward: false);
    expect(find.text('Maryam').hitTestable(), findsOneWidget);
    _expectDots(tester, 1);
    await _swipe(tester, forward: false);
    expect(find.text('Ibrahim').hitTestable(), findsOneWidget);
    _expectDots(tester, 0);
    expect(find.text('Hassan'), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    expect(find.text('Remove Guardian'), findsNothing);
    expect(find.text('Active Journey access'), findsNothing);
    _expectReadOnly();
  });

  testWidgets('does not invent missing relationship or optional metadata', (
    tester,
  ) async {
    await _mount(
      tester,
      guardians: const [
        GuardianInfo(firstName: 'Amina', gender: 'unknown', city: '  '),
      ],
    );
    expect(find.text('Amina'), findsOneWidget);
    expect(find.text('Additional Guardian'), findsOneWidget);
    expect(find.text('Male'), findsNothing);
    expect(find.text('Female'), findsNothing);
    expect(find.text('Relationship not recorded'), findsNothing);
    expect(find.text('unknown'), findsNothing);
    expect(find.text('City'), findsNothing);
    expect(find.text('Gender'), findsNothing);
    expect(_key('peer_guardians_position_$_subject'), findsNothing);
    expect(_key('peer_guardian_dot_${_subject}_0'), findsNothing);
    expect(_pageView(tester).childrenDelegate.estimatedChildCount, 1);
    _expectReadOnly();
  });

  testWidgets('null stays unavailable and never claims there are none', (
    tester,
  ) async {
    await _mount(tester, guardians: null, wrapPull: true);
    expect(_key('peer_guardians_unavailable'), findsOneWidget);
    expect(find.text('Guardian details are unavailable.'), findsOneWidget);
    expect(_key('peer_guardians_empty'), findsNothing);
    expect(find.text('No Guardians linked.'), findsNothing);
    expect(find.text('Ibrahim'), findsNothing);
    expect(find.byType(PageView), findsNothing);
    expect(_key('peer_guardians_position_$_subject'), findsNothing);
    await _capture(tester, 'unavailable');
  });

  testWidgets('confirmed empty roster says none without a sample fallback', (
    tester,
  ) async {
    await _mount(tester, guardians: const [], wrapPull: true);
    expect(_key('peer_guardians_empty'), findsOneWidget);
    expect(find.text('No Guardians linked.'), findsOneWidget);
    expect(_key('peer_guardians_unavailable'), findsNothing);
    expect(find.text('Ibrahim'), findsNothing);
    expect(find.byType(PageView), findsNothing);
    expect(_key('peer_guardians_position_$_subject'), findsNothing);
    await _capture(tester, 'empty');
  });

  testWidgets('changing subjects replaces both context and supplied roster', (
    tester,
  ) async {
    await _mount(tester);
    await _swipe(tester);
    await _swipe(tester);
    final oldController = _pageView(tester).controller!;
    final stalePageChanged = _pageView(tester).onPageChanged!;
    await _mount(
      tester,
      subjectId: 'peer-aisha',
      firstName: 'Aisha',
      guardians: const [GuardianInfo(firstName: 'Amina', isMain: true)],
      settle: false,
    );
    expect(find.text('Journey with Aisha'), findsOneWidget);
    expect(_key('peer_guardians_peer-aisha'), findsOneWidget);
    expect(_key('peer_guardians_peer-sara'), findsNothing);
    expect(find.text('Journey with Sara'), findsNothing);
    expect(find.text('Amina'), findsOneWidget);
    expect(find.text('Ibrahim'), findsNothing);
    final freshController = _pageView(tester, 'peer-aisha').controller!;
    expect(freshController, isNot(same(oldController)));
    expect(freshController.page, closeTo(0, .01));
    stalePageChanged(2);
    await tester.pumpAndSettle();
    _expectNoException(tester);
    expect(freshController.page, closeTo(0, .01));
  });

  testWidgets('one Guardian page fills the normal horizontal viewport', (
    tester,
  ) async {
    await _mount(tester);
    final viewport = tester.getRect(_pager());
    expect(_pageView(tester).scrollDirection, Axis.horizontal);
    expect(_pageView(tester).controller!.keepPage, isFalse);
    for (var index = 0; index < 3; index++) {
      final card = tester.getRect(_key('peer_guardian_${_subject}_$index'));
      expect(card.left, closeTo(20, .1));
      expect(card.right, closeTo(373, .1));
      expect(card.top, closeTo(viewport.top, .1));
      expect(card.bottom, closeTo(viewport.bottom, .1));
      expect(card.height, greaterThan(450));
      expect(_reader(tester, index).position.maxScrollExtent, closeTo(0, .1));
      _expectDots(tester, index);
      if (index < 2) await _swipe(tester);
    }
    final dots = tester.getRect(_key('peer_guardians_position_$_subject'));
    expect(viewport.top - dots.bottom, closeTo(12, .1));
    expect(
      dots.top,
      greaterThan(tester.getRect(_key('peer_guardians_title')).bottom),
    );
    _expectNoException(tester);
  });

  testWidgets('small screen at double text scale scrolls without overflow', (
    tester,
  ) async {
    await _mount(
      tester,
      guardians: const [_longGuardian],
      size: const Size(320, 568),
      scale: 2,
      wrapPull: true,
    );
    final scrollable = _reader(tester, 0);
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(find.byType(FittedBox), findsNothing);
    final avatar = _key('peer_guardian_avatar_${_subject}_0');
    expect(tester.getSize(avatar), const Size(64, 64));
    final monogram = tester.widget<Text>(
      find.descendant(of: avatar, matching: find.byType(Text)),
    );
    expect(monogram.data, 'A');
    expect(monogram.textScaler, TextScaler.noScaling);
    final reader = _key('peer_guardian_reader_${_subject}_0');
    final fullName = find.text(_longGuardian.firstName);
    expect(tester.widget<Text>(fullName).style!.fontSize, 27);
    expect(tester.widget<Text>(fullName).maxLines, isNull);
    expect(tester.widget<Text>(fullName).textScaler, isNull);
    expect(MediaQuery.textScalerOf(tester.element(fullName)).scale(27), 54);
    await Scrollable.ensureVisible(tester.element(fullName), alignment: 0);
    await tester.pumpAndSettle();
    final viewport = tester.getRect(reader);
    final nameRect = tester.getRect(fullName);
    expect(fullName.hitTestable(), findsOneWidget);
    expect(nameRect.left, closeTo(viewport.left, .1));
    expect(nameRect.right, lessThanOrEqualTo(viewport.right));
    expect(nameRect.top, greaterThanOrEqualTo(viewport.top));
    expect(nameRect.bottom, lessThanOrEqualTo(viewport.bottom));
    await _capture(tester, 'compact_top');
    final role = _key('peer_guardian_role_${_subject}_0');
    await Scrollable.ensureVisible(tester.element(role), alignment: .5);
    await tester.pumpAndSettle();
    expect(find.text('Additional Guardian').hitTestable(), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Additional Guardian')).textScaler,
      isNull,
    );
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.text('Additional Guardian')),
      ).scale(12.25),
      24.5,
    );
    final roleRect = tester.getRect(role);
    expect(roleRect.top, greaterThanOrEqualTo(viewport.top));
    expect(roleRect.bottom, lessThanOrEqualTo(viewport.bottom));
    await Scrollable.ensureVisible(
      tester.element(find.text('Male')),
      alignment: 1,
    );
    await tester.pumpAndSettle();
    expect(find.text('Male').hitTestable(), findsOneWidget);
    expect(scrollable.position.pixels, greaterThan(0));
    expect(find.text(_longCity), findsOneWidget);
    await _capture(tester, 'compact_details');
    _expectReadOnly();
    _expectNoException(tester);
  });

  testWidgets(
    'equivalent fresh DTOs preserve exact controller and selected page',
    (tester) async {
      await _mount(tester);
      await _swipe(tester);
      final oldController = _pageView(tester).controller!;
      expect(oldController.page, closeTo(1, .01));
      await _mount(
        tester,
        guardians: [
          for (final guardian in [_ibrahim, _maryam, _yusuf])
            GuardianInfo(
              firstName: guardian.firstName,
              relationship: guardian.relationship,
              isMain: guardian.isMain,
              city: guardian.city,
              gender: guardian.gender,
            ),
        ],
        settle: false,
      );
      final retained = _pageView(tester).controller!;
      expect(retained, same(oldController));
      expect(retained.page, closeTo(1, .01));
      expect(find.text('Maryam').hitTestable(), findsOneWidget);
      _expectDots(tester, 1);
      await tester.pumpAndSettle();
      _expectNoException(tester);
      expect(_pageView(tester).controller, same(oldController));
      expect(retained.page, closeTo(1, .01));
    },
  );

  for (final change in [
    'firstName',
    'relationship',
    'isMain',
    'city',
    'gender',
    'order',
    'shrink',
  ]) {
    testWidgets(
      '$change disclosure change resets before first paint and old page callback is inert',
      (tester) async {
        await _mount(tester);
        await _swipe(tester);
        await _swipe(tester);
        final old = _pageView(tester);
        expect(old.controller!.page, closeTo(2, .01));
        final replacement = GuardianInfo(
          firstName: change == 'firstName' ? 'Ibraheem' : _ibrahim.firstName,
          relationship: change == 'relationship'
              ? 'father'
              : _ibrahim.relationship,
          isMain: change == 'isMain' ? false : _ibrahim.isMain,
          city: change == 'city' ? 'Leeds' : _ibrahim.city,
          gender: change == 'gender' ? 'female' : _ibrahim.gender,
        );
        final next = change == 'order'
            ? [_ibrahim, _yusuf, _maryam]
            : change == 'shrink'
            ? [_ibrahim]
            : [replacement, _maryam, _yusuf];
        await _mount(tester, guardians: next, settle: false);
        final fresh = _pageView(tester);
        expect(fresh.controller, isNot(same(old.controller)));
        expect(fresh.controller!.page, closeTo(0, .01));
        expect(fresh.controller!.keepPage, isFalse);
        expect(find.text(next.first.firstName).hitTestable(), findsOneWidget);
        old.onPageChanged!(2);
        await tester.pumpAndSettle();
        _expectNoException(tester);
        expect(_pageView(tester).controller, same(fresh.controller));
        expect(fresh.controller!.page, closeTo(0, .01));
        if (next.length > 1) {
          _expectDots(tester, 0);
        } else {
          expect(_key('peer_guardians_position_$_subject'), findsNothing);
        }
        _expectReadOnly();
      },
    );
  }

  for (final revoked in [null, const <GuardianInfo>[]]) {
    testWidgets(
      '${revoked == null ? 'protected' : 'empty'} revocation drops pager and regrant starts fresh',
      (tester) async {
        await _mount(tester);
        await _swipe(tester);
        final old = _pageView(tester);
        await _mount(tester, guardians: revoked, settle: false);
        expect(find.byType(PageView), findsNothing);
        expect(_key('peer_guardians_position_$_subject'), findsNothing);
        expect(
          _key(
            revoked == null
                ? 'peer_guardians_unavailable'
                : 'peer_guardians_empty',
          ),
          findsOneWidget,
        );
        old.onPageChanged!(2);
        await tester.pumpAndSettle();
        _expectNoException(tester);
        expect(find.byType(PageView), findsNothing);
        await _mount(tester, settle: false);
        final fresh = _pageView(tester);
        expect(fresh.controller, isNot(same(old.controller)));
        expect(fresh.controller!.page, closeTo(0, .01));
        old.onPageChanged!(1);
        await tester.pumpAndSettle();
        _expectNoException(tester);
        expect(fresh.controller!.page, closeTo(0, .01));
        _expectDots(tester, 0);
      },
    );
  }

  testWidgets('disposed pager ignores its retained page-changed callback', (
    tester,
  ) async {
    await _mount(tester);
    final old = _pageView(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    old.onPageChanged!(2);
    old.onPageChanged!(-1);
    await tester.pumpAndSettle();
    _expectNoException(tester);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets(
    'out-of-range page callbacks cannot alter a current pager indicator',
    (tester) async {
      await _mount(tester);
      final current = _pageView(tester);
      current.onPageChanged!(-1);
      current.onPageChanged!(3);
      current.onPageChanged!(999);
      await tester.pumpAndSettle();
      _expectNoException(tester);
      expect(current.controller!.page, closeTo(0, .01));
      _expectDots(tester, 0);
    },
  );

  testWidgets(
    'shared return preserves horizontal paging and interior reading, then closes once from left edge',
    (tester) async {
      var returns = 0;
      void onBack() => returns++;
      await _mount(
        tester,
        guardians: const [_longGuardian, _ibrahim, _yusuf],
        size: const Size(320, 568),
        scale: 2,
        wrapPull: true,
        onBack: onBack,
      );
      final pager = _pageView(tester).controller!;
      await _swipe(tester);
      expect(pager.page, closeTo(1, .01));
      expect(returns, 0);
      _expectDots(tester, 1);
      final back = _key('zyra_visible_back_button');
      expect(back, findsNothing);
      expect(_key('zyra_back_swipe_edge'), findsOneWidget);
      expect(_key('zyra_pull_down_bottom_cue'), findsNothing);
      final dots = tester.getRect(_key('peer_guardians_position_$_subject'));
      expect(dots.top, greaterThanOrEqualTo(0));
      final reader = _reader(tester, 1);
      expect(reader.position.maxScrollExtent, greaterThan(120));
      reader.position.jumpTo(100);
      await tester.pumpAndSettle();
      final bounds = tester.getRect(_key('peer_guardian_reader_${_subject}_1'));
      await tester.timedDragFrom(
        Offset(bounds.left + 20, bounds.center.dy),
        const Offset(0, 60),
        const Duration(milliseconds: 400),
      );
      await tester.pumpAndSettle();
      _expectNoException(tester);
      expect(returns, 0);
      expect(pager.page, closeTo(1, .01));
      expect(reader.position.pixels, lessThan(100));
      final retainedBack = captureZyraAccessibleBack(tester);
      await swipeZyraBack(tester);
      _expectNoException(tester);
      expect(returns, 1);
      retainedBack();
      await tester.pumpAndSettle();
      _expectNoException(tester);
      expect(returns, 1);
      expect(pager.page, closeTo(1, .01));
      _expectReadOnly();
    },
  );
}
