// Pure presentation using invented public profiles and an injected offline
// renderer. State, invitation permission and persistence belong to the caller;
// shell tests separately exercise account, route and lifecycle authority.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_sample_photos.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_invitation_label.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';

const _capture = bool.fromEnvironment('ZYRA_INLINE_INVITATION_CAPTURE');
const _font = 'PoppinsInlineInvitation';
const _boundary = ValueKey('inline-invitation-candidate');
const _candidateDirectory = 'visual/candidates/browse_photo_frame_2026_10_10';
const _personId = 'inline-sara';
const _otherId = 'inline-aisha';
const _baseColor = Color(0xFFE8E5ED);
late List<SeekerProfile> _people;

Finder _key(String value) => find.byKey(ValueKey(value));
Finder get _request => _key('draft_profile_$_personId');
Finder get _fullRequest => _key('inline-full-request');
Finder get _label => find.byType(ZyraInvitationLabel);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Inline invitation presentation must remain offline.');
  }
}

class _Actions {
  final sent = <String>{};
  final requests = <String>[];
  int next = 0;
  int previous = 0;
  int opens = 0;
  int dismissals = 0;

  void toggle(SeekerProfile profile) {
    requests.add(profile.id);
    if (!sent.remove(profile.id)) sent.add(profile.id);
  }

  String label(SeekerProfile profile) => sent.contains(profile.id)
      ? 'Journey invitation sent'
      : 'Request a Journey';
}

Widget _photo(
  BuildContext context,
  String photo, {
  required double width,
  required double height,
  required Alignment alignment,
}) => _capture
    ? ZyraProfileImage(
        photo,
        width: width,
        height: height,
        alignment: alignment,
      )
    : ColoredBox(
        color: photo.contains('photo-1') ? Colors.blueGrey : Colors.grey,
      );

Widget _fullPhoto(BuildContext context, String photo) => KeyedSubtree(
  key: ValueKey('inline-full-photo-${_people.first.photos.indexOf(photo)}'),
  child: _photo(
    context,
    photo,
    width: double.infinity,
    height: double.infinity,
    alignment: Alignment.topCenter,
  ),
);

Widget _harness(_Actions actions, {bool full = false}) => StatefulBuilder(
  builder: (context, update) {
    void request(SeekerProfile profile) =>
        update(() => actions.toggle(profile));
    if (full) {
      return ZyraOneJourneyBrowsePresentation(
        profile: _people.first,
        imageBuilder: _fullPhoto,
        onMenu: () {},
        onPreviousProfile: () => actions.previous++,
        onNextProfile: () => actions.next++,
        onDismiss: () => actions.dismissals++,
        onRequest: () => request(_people.first),
        requestLabel: actions.label(_people.first),
        invitationSent: actions.sent.contains(_personId),
        requestKey: const ValueKey('inline-full-request'),
      );
    }
    return ZyraBrowseDesigns(
      profiles: _people,
      selectedIndex: 0,
      design: ZyraOneJourneyBrowseDesign.portraitCard,
      photoBuilder: _photo,
      canRequest: (_) => true,
      requestLabel: actions.label,
      invitationSent: (profile) => actions.sent.contains(profile.id),
      onPrevious: () => actions.previous++,
      onNext: () => actions.next++,
      onFilters: () {},
      onProfile: (_) => actions.opens++,
      onRequest: request,
    );
  },
);

Widget _app(
  Widget body, {
  bool full = false,
  bool disableAnimations = false,
  bool accessibleNavigation = false,
  double scale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.dark(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      padding: const EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
      disableAnimations: disableAnimations,
      accessibleNavigation: accessibleNavigation,
    ),
    child: child!,
  ),
  home: Scaffold(
    body: RepaintBoundary(
      key: _boundary,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            body,
            if (!full)
              FloatingNavBar(
                items: const [
                  FloatingNavItem(icon: Icons.search, label: 'Browse'),
                  FloatingNavItem(icon: Icons.route_outlined, label: 'Journey'),
                  FloatingNavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'My ZYRA',
                  ),
                  FloatingNavItem(
                    icon: Icons.gpp_good_outlined,
                    label: 'Guardian',
                  ),
                  FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
                ],
                currentIndex: 0,
                onTap: (_) {},
              ),
          ],
        ),
      ),
    ),
  ),
);

Future<void> _mount(
  WidgetTester tester,
  Widget body, {
  Size size = const Size(393, 852),
  bool full = false,
  bool disableAnimations = false,
  bool accessibleNavigation = false,
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _app(
      body,
      full: full,
      disableAnimations: disableAnimations,
      accessibleNavigation: accessibleNavigation,
      scale: scale,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _tap(
  WidgetTester tester,
  Finder target, {
  bool settle = true,
}) async {
  expect(target, findsOneWidget);
  if (find
      .ancestor(of: target, matching: find.byType(Scrollable))
      .evaluate()
      .isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .45);
    await tester.pumpAndSettle();
  }
  final screen =
      Offset.zero & (tester.view.physicalSize / tester.view.devicePixelRatio);
  final nav = find.byType(FloatingNavBar);
  final reading = nav.evaluate().isEmpty
      ? screen
      : Rect.fromLTRB(0, 59, screen.width, tester.getRect(nav).top);
  final visible = tester.getRect(target).intersect(reading);
  expect(visible.width, greaterThan(0));
  expect(visible.height, greaterThan(0));
  final box = tester.renderObject<RenderBox>(target);
  final local = box.globalToLocal(visible.center);
  expect(
    target.hitTestable(
      at: Alignment(
        2 * local.dx / box.size.width - 1,
        2 * local.dy / box.size.height - 1,
      ),
    ),
    findsOneWidget,
  );
  await tester.tapAt(visible.center);
  await tester.pump();
  if (settle) await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectFooterSafe(WidgetTester tester) {
  final request = tester.getRect(_request);
  final back = tester.getRect(_key('concept_previous_profile'));
  final next = tester.getRect(_key('concept_next_profile'));
  final footer = tester.getRect(_key('concept_browse_footer'));
  final nav = tester.getRect(find.byType(FloatingNavBar));
  expect(request.height, greaterThanOrEqualTo(48));
  expect(next.width, greaterThan(back.width));
  expect(request.width, greaterThan(next.width));
  expect(back.right, lessThan(request.left));
  expect(request.right, lessThan(next.left));
  expect(footer.bottom, lessThanOrEqualTo(nav.top - 12));
  for (final text
      in find
          .descendant(of: _request, matching: find.byType(Text))
          .evaluate()) {
    final rect = tester.getRect(find.byWidget(text.widget));
    expect(rect.left, greaterThanOrEqualTo(request.left));
    expect(rect.right, lessThanOrEqualTo(request.right));
    expect(rect.top, greaterThanOrEqualTo(request.top));
    expect(rect.bottom, lessThanOrEqualTo(request.bottom));
  }
  expect(tester.takeException(), isNull);
}

void _expectCardOutline(WidgetTester tester, String id, {required bool sent}) {
  final outline = _key('browse_invitation_outline_$id');
  final decoration = tester.widget<DecoratedBox>(
    find.descendant(of: outline, matching: find.byType(DecoratedBox)).first,
  );
  expect(
    (decoration.decoration as BoxDecoration).border!.top.color,
    ZyraColors.journeyGold.withValues(alpha: sent ? .65 : 0),
  );
}

void _expectDots(WidgetTester tester, {int selected = 0}) {
  final pager = tester.getRect(_key('concept_browse_photo_swipe_$_personId'));
  final pagination = tester.getRect(_key('concept_browse_photo_pagination'));
  expect(pagination.height, 16);
  expect(pagination.bottom, closeTo(pager.top, .01));
  final dots = <Rect>[];
  for (var index = 0; index <= _people.first.photos.length; index++) {
    final finder = _key('concept_browse_photo_dot_${_personId}_$index');
    final container = tester.widget<AnimatedContainer>(finder);
    final width = index == selected ? 20.0 : 5.0;
    expect(container.constraints!.maxWidth, width);
    expect(container.constraints!.maxHeight, 5);
    expect(container.margin, const EdgeInsets.symmetric(horizontal: 3));
    expect(
      container.duration,
      MediaQuery.disableAnimationsOf(tester.element(finder))
          ? Duration.zero
          : const Duration(milliseconds: 180),
    );
    expect(
      (container.decoration! as BoxDecoration).borderRadius,
      BorderRadius.circular(20),
    );
    expect(
      (container.decoration! as BoxDecoration).color,
      index == selected ? ZyraColors.journeyGold : ZyraColors.ink(.25),
    );
    final rect = tester.getRect(
      find.descendant(of: finder, matching: find.byType(DecoratedBox)),
    );
    expect(rect.size, Size(width, 5));
    expect(rect.center.dy, closeTo(pagination.center.dy - 4, .01));
    if (dots.isNotEmpty) {
      expect(rect.left - dots.last.right, closeTo(6, .01));
    }
    dots.add(rect);
  }
  expect(
    (dots.first.left + dots.last.right) / 2,
    closeTo(pager.center.dx, .01),
  );
  final nextIcon = tester.widget<Icon>(
    find.descendant(
      of: _key('concept_next_profile'),
      matching: find.byType(Icon),
    ),
  );
  expect(nextIcon.size, 24);
}

Future<void> _snapshot(WidgetTester tester, String name) async {
  if (!_capture) return;
  expect(autoUpdateGoldenFiles, isTrue);
  for (final image in tester.widgetList<Image>(find.byType(Image))) {
    expect(image.image, isA<MemoryImage>());
    await tester.runAsync(() async {
      final ready = Completer<void>();
      final stream = image.image.resolve(const ImageConfiguration());
      final listener = ImageStreamListener(
        (_, _) {
          if (!ready.isCompleted) ready.complete();
        },
        onError: (Object error, StackTrace? stack) {
          if (!ready.isCompleted) ready.completeError(error, stack);
        },
      );
      stream.addListener(listener);
      try {
        await ready.future.timeout(const Duration(seconds: 10));
      } finally {
        stream.removeListener(listener);
      }
    });
  }
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await expectLater(
        data!.buffer.asUint8List(),
        matchesGoldenFile('$_candidateDirectory/$name.png'),
      );
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousOverrides = HttpOverrides.current;
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
    final photos = _capture ? await ZyraOneJourneySamplePhotos.load() : null;
    _people = [
      SeekerProfile(
        id: _personId,
        firstName: 'Sara',
        surnameLine: 'Ahmed',
        age: 27,
        city: 'Birmingham',
        gender: 'female',
        publicNationality: 'British',
        publicEthnicity: 'South Asian',
        photos:
            photos?.forIndex(0) ??
            ['sara-photo-0', 'sara-photo-1', 'sara-photo-2'],
      ),
      SeekerProfile(
        id: _otherId,
        firstName: 'Aisha',
        surnameLine: 'Khan',
        age: 29,
        city: 'London',
        gender: 'female',
        photos: photos?.forIndex(2) ?? ['aisha-photo-0', 'aisha-photo-1'],
      ),
    ];
  });
  setUp(() {
    network = _NoNetwork();
    HttpOverrides.global = network;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousOverrides;
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  testWidgets('label uses a short feedback-only gold fade and small slide', (
    tester,
  ) async {
    var sent = false;
    var presses = 0;
    await _mount(
      tester,
      Center(
        child: StatefulBuilder(
          builder: (context, update) => TextButton(
            key: const ValueKey('label-toggle'),
            onPressed: () => update(() {
              presses++;
              sent = !sent;
            }),
            child: ZyraInvitationLabel(
              label: sent ? 'Journey invitation sent' : 'Request a Journey',
              sent: sent,
              style: const TextStyle(color: _baseColor, fontSize: 14),
            ),
          ),
        ),
      ),
      full: true,
    );
    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, const Duration(milliseconds: 220));
    expect(switcher.reverseDuration, const Duration(milliseconds: 180));
    expect(switcher.switchInCurve, Curves.easeOutCubic);
    expect(switcher.switchOutCurve, Curves.easeInCubic);
    await _tap(tester, _key('label-toggle'), settle: false);
    final sentText = find.text('Journey invitation sent');
    expect(tester.widget<Text>(sentText).style!.color, ZyraColors.journeyGold);
    final fade = find
        .ancestor(of: sentText, matching: find.byType(FadeTransition))
        .first;
    final slide = find
        .ancestor(of: sentText, matching: find.byType(Transform))
        .first;
    expect(tester.widget<Transform>(slide).transform.getTranslation().y, 3);
    await tester.pump(const Duration(milliseconds: 110));
    expect(tester.widget<FadeTransition>(fade).opacity.value, greaterThan(0));
    expect(tester.widget<FadeTransition>(fade).opacity.value, lessThan(1));
    expect(
      tester.widget<Transform>(slide).transform.getTranslation().y,
      inExclusiveRange(0, 3),
    );
    expect(presses, 1);
    await tester.pumpAndSettle();
    expect(find.text('Request a Journey'), findsNothing);
    expect(tester.widget<Transform>(slide).transform.getTranslation().y, 0);
    await _tap(tester, _key('label-toggle'));
    expect(
      tester.widget<Text>(find.text('Request a Journey')).style!.color,
      _baseColor,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(presses, 2, reason: 'Animation completion has no action authority.');
  });

  for (final quiet in const [
    (disable: true, accessible: false),
    (disable: false, accessible: true),
  ]) {
    testWidgets(
      'quiet motion ${quiet.disable}/${quiet.accessible} is instantaneous',
      (tester) async {
        final actions = _Actions();
        await _mount(
          tester,
          _harness(actions),
          disableAnimations: quiet.disable,
          accessibleNavigation: quiet.accessible,
        );
        await _tap(tester, _request);
        final switcher = tester.widget<AnimatedSwitcher>(
          find.descendant(of: _label, matching: find.byType(AnimatedSwitcher)),
        );
        expect(switcher.duration, Duration.zero);
        expect(switcher.reverseDuration, Duration.zero);
        expect(find.text('Request a Journey'), findsNothing);
        final current = find.text('Journey invitation sent');
        expect(
          tester
              .widget<FadeTransition>(
                find
                    .ancestor(
                      of: current,
                      matching: find.byType(FadeTransition),
                    )
                    .first,
              )
              .opacity
              .value,
          1,
        );
        expect(
          tester
              .widget<Transform>(
                find
                    .ancestor(of: current, matching: find.byType(Transform))
                    .first,
              )
              .transform
              .getTranslation()
              .y,
          0,
        );
        await _tap(tester, _request);
        expect(find.text('Journey invitation sent'), findsNothing);
        expect(actions.requests, [_personId, _personId]);
      },
    );
  }

  for (final full in [false, true]) {
    testWidgets(
      'current action semantics exclude both animated label children (full=$full)',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final actions = _Actions();
          await _mount(tester, _harness(actions, full: full), full: full);
          final target = full ? _fullRequest : _request;
          expect(tester.getSemantics(target).label, 'Request a Journey');
          await _tap(tester, target, settle: false);
          await tester.pump(const Duration(milliseconds: 80));
          expect(find.text('Request a Journey'), findsOneWidget);
          expect(find.text('Journey invitation sent'), findsOneWidget);
          expect(
            tester.getSemantics(target).label,
            'Journey invitation sent. Tap to cancel invitation',
          );
          expect(find.bySemanticsLabel('Request a Journey'), findsNothing);
          expect(
            find.bySemanticsLabel(
              'Journey invitation sent. Tap to cancel invitation',
            ),
            findsOneWidget,
          );
          await tester.pumpAndSettle();
          await _tap(tester, target);
          expect(tester.getSemantics(target).label, 'Request a Journey');
          expect(actions.sent, isEmpty);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  for (final viewport in const [
    (size: Size(320, 852), scale: 1.0),
    (size: Size(393, 852), scale: 1.0),
    (size: Size(430, 932), scale: 1.0),
    (size: Size(320, 852), scale: 2.0),
    (size: Size(393, 852), scale: 2.0),
    (size: Size(430, 932), scale: 2.0),
  ]) {
    testWidgets(
      'Current inline labels stay bounded throughout transition ${viewport.size.width}/${viewport.scale}',
      (tester) async {
        final actions = _Actions();
        await _mount(
          tester,
          _harness(actions),
          size: viewport.size,
          scale: viewport.scale,
        );
        await Scrollable.ensureVisible(
          tester.element(_request),
          alignment: .45,
        );
        await tester.pumpAndSettle();
        _expectFooterSafe(tester);
        _expectDots(tester);
        final photoBounds = tester.getRect(
          _key('concept_browse_photo_swipe_$_personId'),
        );
        final footerBounds = tester.getRect(_key('concept_browse_footer'));
        await _tap(tester, _request, settle: false);
        await tester.pump(const Duration(milliseconds: 110));
        _expectFooterSafe(tester);
        _expectDots(tester);
        expect(
          tester.getRect(_key('concept_browse_photo_swipe_$_personId')),
          photoBounds,
        );
        expect(tester.getRect(_key('concept_browse_footer')), footerBounds);
        expect(find.byType(ZyraBrowseDesigns), findsOneWidget);
        expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
        await tester.pumpAndSettle();
        _expectFooterSafe(tester);
        await _tap(tester, _request, settle: false);
        await tester.pump(const Duration(milliseconds: 90));
        _expectFooterSafe(tester);
        await tester.pumpAndSettle();
        _expectDots(tester);
        expect(actions.sent, isEmpty);
        expect(actions.requests, [_personId, _personId]);
        expect((actions.next, actions.previous, actions.opens), (0, 0, 0));
      },
    );
  }

  testWidgets(
    'Current photo selection and footer styling survive send/cancel',
    (tester) async {
      final actions = _Actions();
      await _mount(tester, _harness(actions));
      final pager = _key('concept_browse_photo_swipe_$_personId');
      // Details is page zero; keep this check on the original second photo.
      for (var page = 1; page <= 2; page++) {
        await tester.drag(pager, const Offset(-300, 0));
        await tester.pumpAndSettle();
        expect(
          tester.widget<PageView>(pager).controller!.page,
          closeTo(page, .01),
        );
      }
      final selectedPhoto = _key('concept_browse_photo_${_personId}_1');
      expect(selectedPhoto, findsOneWidget);
      _expectDots(tester, selected: 2);
      await _tap(tester, _request);
      expect(tester.widget<PageView>(pager).controller!.page, closeTo(2, .01));
      expect(selectedPhoto, findsOneWidget);
      _expectDots(tester, selected: 2);
      expect(
        tester.widget<Text>(find.text('Journey invitation sent')).style!.color,
        ZyraColors.journeyGold,
      );
      await _tap(tester, _request);
      expect(tester.widget<PageView>(pager).controller!.page, closeTo(2, .01));
      expect(selectedPhoto, findsOneWidget);
      _expectDots(tester, selected: 2);
      expect(
        tester.widget<Text>(find.text('Request a Journey')).style!.fontSize,
        14,
      );
      expect(actions.requests, [_personId, _personId]);
      expect((actions.next, actions.previous, actions.opens), (0, 0, 0));
    },
  );

  testWidgets('only sent person has a gold outline in portraitCard', (
    tester,
  ) async {
    final actions = _Actions();
    await _mount(tester, _harness(actions));
    _expectCardOutline(tester, _personId, sent: false);
    final card = _key('concept_browse_portrait_card');
    final before = tester.getSize(card);
    await _tap(tester, _request);
    _expectCardOutline(tester, _personId, sent: true);
    expect(tester.getSize(card), before);
    await _tap(tester, _request);
    _expectCardOutline(tester, _personId, sent: false);
    expect(tester.getSize(card), before);
    expect(actions.sent, isEmpty);
    expect(actions.requests, [_personId, _personId]);
    expect((actions.next, actions.previous, actions.opens), (0, 0, 0));
  });

  for (final width in [320.0, 393.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Current photo fills its card at $width/$scale', (
        tester,
      ) async {
        final actions = _Actions();
        await _mount(
          tester,
          _harness(actions),
          size: Size(width, 852),
          scale: scale,
        );
        final card = _key('concept_browse_portrait_card');
        final photo = _key('concept_browse_photo_swipe_$_personId');
        await tester.drag(photo, const Offset(-300, 0));
        await tester.pumpAndSettle();
        expect(
          tester.widget<PageView>(photo).controller!.page,
          closeTo(1, .01),
        );
        final renderedPhoto = _key('concept_browse_photo_${_personId}_0');
        expect(renderedPhoto, findsOneWidget);
        final open = _key('concept_browse_open_$_personId');
        final surface = tester.widget<Material>(
          find.ancestor(of: open, matching: find.byType(Material)).first,
        );
        expect(surface.color, Colors.transparent);
        expect(surface.clipBehavior, Clip.antiAlias);
        expect(tester.getRect(photo), tester.getRect(card));
        expect(tester.getRect(renderedPhoto), tester.getRect(card));
        final bounds = (
          tester.getRect(card),
          tester.getRect(_key('concept_browse_footer')),
          tester.getRect(find.text('Profiles')),
          tester.getRect(find.byType(FloatingNavBar)),
        );
        await _tap(tester, _request);
        _expectCardOutline(tester, _personId, sent: true);
        expect(tester.getRect(photo), tester.getRect(card));
        expect(tester.getRect(renderedPhoto), tester.getRect(card));
        expect((
          tester.getRect(card),
          tester.getRect(_key('concept_browse_footer')),
          tester.getRect(find.text('Profiles')),
          tester.getRect(find.byType(FloatingNavBar)),
        ), bounds);
        await _tap(tester, _request);
        expect(tester.getRect(photo), tester.getRect(card));
        expect(tester.getRect(renderedPhoto), tester.getRect(card));
        _expectCardOutline(tester, _personId, sent: false);
        expect(actions.requests, [_personId, _personId]);
        expect((actions.next, actions.previous, actions.opens), (0, 0, 0));
      });
    }
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'full photo remains on the selected image after send/cancel at $scale',
      (tester) async {
        final actions = _Actions();
        await _mount(
          tester,
          _harness(actions, full: true),
          full: true,
          scale: scale,
        );
        await tester.tapAt(const Offset(330, 240));
        await tester.pumpAndSettle();
        expect(_key('inline-full-photo-1'), findsOneWidget);
        await _tap(tester, _fullRequest);
        expect(_key('inline-full-photo-1'), findsOneWidget);
        expect(find.byType(ZyraOneJourneyBrowsePresentation), findsOneWidget);
        expect(find.byType(ZyraBrowseDesigns), findsNothing);
        final sentActionBounds = tester.getRect(_fullRequest);
        final sentLabel = find.descendant(
          of: _fullRequest,
          matching: find.text('Journey invitation sent'),
        );
        expect(sentLabel, findsOneWidget);
        final sentLabelBounds = tester.getRect(sentLabel);
        expect(
          sentLabelBounds.left,
          greaterThanOrEqualTo(sentActionBounds.left),
        );
        expect(
          sentLabelBounds.right,
          lessThanOrEqualTo(sentActionBounds.right),
        );
        expect(sentLabelBounds.top, greaterThanOrEqualTo(sentActionBounds.top));
        expect(
          sentLabelBounds.bottom,
          lessThanOrEqualTo(sentActionBounds.bottom),
        );
        await _tap(tester, _fullRequest);
        expect(_key('inline-full-photo-1'), findsOneWidget);
        expect(actions.sent, isEmpty);
        expect(actions.requests, [_personId, _personId]);
        expect(
          (actions.next, actions.previous, actions.opens, actions.dismissals),
          (0, 0, 0, 0),
        );
        final bounds = tester.getRect(_fullRequest);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(393));
        expect(bounds.bottom, lessThanOrEqualTo(852));
      },
    );
  }

  testWidgets('fresh offline real-font candidates preserve the same profile', (
    tester,
  ) async {
    if (!_capture) return;
    final actions = _Actions();
    await _mount(tester, _harness(actions));
    await _snapshot(tester, 'browse_ready');
    await _tap(tester, _request);
    await _snapshot(tester, 'browse_sent');
    await _tap(tester, _request);
    await _snapshot(tester, 'browse_cancelled');
    await _mount(tester, _harness(actions, full: true), full: true);
    await _tap(tester, _fullRequest);
    await _snapshot(tester, 'full_sent');
    expect(actions.requests, [_personId, _personId, _personId]);
    expect((actions.next, actions.previous, actions.opens), (0, 0, 0));
  });
}
