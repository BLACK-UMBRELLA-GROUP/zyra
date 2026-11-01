// Canonical, offline Soft-card presentation. Not member/service authority.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/connections/connections_section_controller.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

const _captures = String.fromEnvironment('ZYRA_REQUEST_ACTIVITY_CAPTURE_DIR');
const _font = 'PoppinsRequestActivity';
const _boundaryKey = ValueKey('request-activity-capture');
const _header = ValueKey('request_header');
const _primary = ValueKey('request_primary');
const _accept = ValueKey('request_accept');
const _decline = ValueKey('request_decline');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    ++attempts;
    throw StateError('Request presentation must remain offline.');
  }
}

class _Harness extends StatefulWidget {
  const _Harness({
    required this.profile,
    required this.controller,
    required this.initialIndex,
    required this.introductions,
    this.emptyReceived = false,
    this.emptyMessage,
    this.onPrimary,
    this.onAccept,
    this.onReport,
    this.onChanged,
    this.canInteract,
  });
  final SeekerProfile profile;
  final ZyraConnectionsExpansionController controller;
  final int initialIndex;
  final bool introductions;
  final bool emptyReceived;
  final String? emptyMessage;
  final VoidCallback? onPrimary;
  final VoidCallback? onAccept;
  final VoidCallback? onReport;
  final ValueChanged<int>? onChanged;
  final bool Function()? canInteract;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late int selected = widget.initialIndex;

  @override
  Widget build(BuildContext context) => ZyraRequestActivityPresentation(
    title: widget.introductions ? 'Introductions' : 'Journey requests',
    labels: widget.introductions
        ? const ['Introductions']
        : const ['Received', 'Sent'],
    segmentKeys: widget.introductions
        ? const []
        : const [ValueKey('request_tab_0'), ValueKey('request_tab_1')],
    selectedIndex: selected,
    canInteract: widget.canInteract,
    onChanged: (index) {
      widget.controller.collapseAll();
      setState(() => selected = index);
      widget.onChanged?.call(index);
    },
    pages: widget.introductions
        ? [
            [
              ZyraRequestActivityEmpty(
                title: 'No introductions yet',
                message:
                    widget.emptyMessage ??
                    'People your Guardians put forward will appear here.',
                icon: Icons.groups_outlined,
              ),
            ],
          ]
        : [
            [
              if (widget.emptyReceived)
                ZyraRequestActivityEmpty(
                  title: 'No received requests yet.',
                  message:
                      widget.emptyMessage ??
                      'Your Journey requests will appear here.',
                  icon: Icons.mail_outline_rounded,
                )
              else
                ZyraRequestActivityCard(
                  profile: widget.profile,
                  subtitle: 'Journey request',
                  cardId: 'request',
                  controller: widget.controller,
                  canInteract: widget.canInteract,
                  headerKey: _header,
                  onToggle: () {
                    if (widget.controller.value == 'request') {
                      widget.controller.close('request');
                    } else {
                      widget.controller.open('request');
                    }
                  },
                  onReport: widget.onReport,
                  primary: ZyraOneJourneyConnectionsAction(
                    key: _primary,
                    label: 'View profile',
                    icon: Icons.visibility_outlined,
                    onTap: widget.onPrimary,
                  ),
                  actions: [
                    ZyraOneJourneyConnectionsAction(
                      key: _accept,
                      label: 'Accept request',
                      icon: Icons.check_rounded,
                      onTap: widget.onAccept,
                    ),
                    const ZyraOneJourneyConnectionsAction(
                      key: _decline,
                      label: 'Decline',
                      icon: Icons.close_rounded,
                      onTap: null,
                    ),
                  ],
                ),
            ],
            [
              ZyraRequestActivityEmpty(
                title: 'No sent requests yet.',
                message:
                    widget.emptyMessage ??
                    'Your sent requests will appear here.',
                icon: Icons.north_east_rounded,
              ),
            ],
          ],
  );
}

Finder _key(Key key) => find.byKey(key);

Future<void> _mount(
  WidgetTester tester, {
  required SeekerProfile profile,
  Size size = const Size(393, 852),
  double scale = 1,
  int initialIndex = 0,
  bool introductions = false,
  bool emptyReceived = false,
  String? emptyMessage,
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = true,
  bool accessibleNavigation = false,
  ZyraConnectionsExpansionController? controller,
  VoidCallback? onPrimary,
  VoidCallback? onAccept,
  VoidCallback? onReport,
  ValueChanged<int>? onChanged,
  bool Function()? canInteract,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final expansion = controller ?? ZyraConnectionsExpansionController();
  if (controller == null) addTearDown(expansion.dispose);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) => Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduceMotion,
            accessibleNavigation: accessibleNavigation,
          ),
          child: child!,
        ),
      ),
      home: RepaintBoundary(
        key: _boundaryKey,
        child: Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
            child: SizedBox.expand(
              child: _Harness(
                profile: profile,
                controller: expansion,
                initialIndex: initialIndex,
                introductions: introductions,
                emptyReceived: emptyReceived,
                emptyMessage: emptyMessage,
                onPrimary: onPrimary,
                onAccept: onAccept,
                onReport: onReport,
                onChanged: onChanged,
                canInteract: canInteract,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _press(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _capture(WidgetTester tester, String filename) async {
  if (_captures.isEmpty) return;
  final portraits = find.descendant(
    of: find.byType(ZyraRequestActivityCard),
    matching: find.byType(Image),
  );
  // Capture readiness only: wait for the exact mounted local image provider,
  // without changing runtime selection, storage or photo-rendering logic.
  for (final element in portraits.evaluate().toList()) {
    final image = element.widget as Image;
    Object? failure;
    await tester.runAsync(() async {
      await precacheImage(
        image.image,
        element,
        onError: (error, _) => failure = error,
      ).timeout(const Duration(seconds: 3));
    });
    expect(failure, isNull);
  }
  await tester.pumpAndSettle();
  for (final frame in tester.widgetList<RawImage>(
    find.descendant(
      of: find.byType(ZyraRequestActivityCard),
      matching: find.byType(RawImage),
    ),
  )) {
    expect(frame.image, isNotNull);
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    _key(_boundaryKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captures/$filename.png');
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(data, isNotNull);
      await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void _expectNaturalText(WidgetTester tester) {
  final content = find.byType(ZyraRequestActivityPresentation);
  expect(
    find.descendant(of: content, matching: find.byType(FittedBox)),
    findsNothing,
  );
  for (final element
      in find.descendant(of: content, matching: find.byType(Text)).evaluate()) {
    final text = element.widget as Text;
    expect(text.maxLines, isNull);
    expect(text.overflow, isNull);
    final paragraph = element.renderObject;
    if (paragraph is RenderParagraph) {
      expect(paragraph.didExceedMaxLines, isFalse);
    }
  }
}

void _expectWholeWordsFit(WidgetTester tester, Finder textFinder) {
  expect(textFinder, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(textFinder);
  final text = paragraph.text.toPlainText();
  for (final word
      in text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty)) {
    final painter = TextPainter(
      text: TextSpan(text: word, style: paragraph.text.style),
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
      locale: paragraph.locale,
    )..layout();
    expect(
      painter.width,
      lessThanOrEqualTo(paragraph.size.width + .01),
      reason: 'Whole word "$word" must fit its actual rendered text width.',
    );
    painter.dispose();
  }
}

void _expectPlainEmpty(
  WidgetTester tester, {
  required int page,
  required String title,
  required IconData icon,
  bool centered = true,
}) {
  final viewport = _key(ValueKey('request_activity_empty_viewport_$page'));
  final empty = find.descendant(
    of: viewport,
    matching: find.byType(ZyraRequestActivityEmpty),
  );
  final shared = find.descendant(
    of: empty,
    matching: find.byType(ZyraEmptyState),
  );
  expect(viewport, findsOneWidget);
  expect(empty, findsOneWidget);
  expect(shared, findsOneWidget);
  for (final type in [Material, FilledButton, OutlinedButton]) {
    expect(
      find.descendant(of: empty, matching: find.byType(type)),
      findsNothing,
    );
  }
  expect(find.byType(ZyraRequestActivityCard), findsNothing);
  final artwork = tester.widget<Icon>(
    find.descendant(of: empty, matching: find.byIcon(icon)),
  );
  expect(artwork.size, 34);
  expect(artwork.color, ZyraColors.journeyGold);
  expect(tester.widget<Text>(find.text(title)).style!.fontSize, 21);
  final emptyState = tester.widget<ZyraEmptyState>(shared);
  expect(emptyState.ctaLabel, isNull);
  expect(emptyState.onCta, isNull);
  if (centered) {
    final group = find.descendant(of: shared, matching: find.byType(Column));
    expect(
      tester.getRect(group).center.dy,
      closeTo(tester.getRect(viewport).center.dy, .01),
    );
    final scrolling = find.descendant(
      of: viewport,
      matching: find.byType(Scrollable),
    );
    expect(
      tester.state<ScrollableState>(scrolling).position.maxScrollExtent,
      0,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousHttp = HttpOverrides.current;
  final previousFatal = WidgetController.hitTestWarningShouldBeFatal;
  final previousFont = ZyraText.testReadingFontFamily;
  final previousStubs = ZyraText.useTestFontStubs;
  final previousPalette = ZyraColors.devPalette;
  late _NoNetwork network;
  late SeekerProfile profile;

  setUpAll(() async {
    if (_captures.isNotEmpty) {
      if (!_captures.startsWith('/')) {
        throw StateError('Capture path must be absolute.');
      }
      var current = '';
      for (final part
          in _captures.split('/').where((part) => part.isNotEmpty)) {
        if (part == '.' ||
            part == '..' ||
            part == '.git' ||
            part.startsWith('PRIVATE')) {
          throw StateError('Unsafe capture path.');
        }
        current += '/$part';
        if (FileSystemEntity.typeSync(current, followLinks: false) !=
            FileSystemEntityType.directory) {
          throw StateError(
            'Capture path requires existing nonlinked directories.',
          );
        }
      }
    }
    final fonts = FontLoader(_font);
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      fonts.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([fonts.load(), icons.load()]);
    final bytes = File(
      'assets/dev/one_journey_photos/zyra1a.jpg',
    ).readAsBytesSync();
    profile = SeekerProfile(
      id: 'local-sara',
      firstName: 'Sara',
      surnameLine: 'Ahmed',
      age: 27,
      city: 'Birmingham',
      gender: 'female',
      photos: ['data:image/jpeg;base64,${base64Encode(bytes)}'],
    );
  });

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    ZyraColors.selectDevPalette(ZyraDevPalette.midnightPlum);
    network = _NoNetwork();
    HttpOverrides.global = network;
    WidgetController.hitTestWarningShouldBeFatal = true;
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousHttp;
    WidgetController.hitTestWarningShouldBeFatal = previousFatal;
    ZyraText.useTestFontStubs = previousStubs;
    ZyraText.testReadingFontFamily = previousFont;
    ZyraColors.selectDevPalette(previousPalette);
  });

  test(
    'only the selected canonical renderer remains with no enum or alternate design readers',
    () {
      final source = File(
        'lib/dev/zyra_request_activity_presentation.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('enum ')));
      for (final forbidden in [
        'ZyraRequestActivityDesign',
        'portraitCards',
        'quietList',
        'goldFrames',
        'editorial',
        'required this.design',
        'ZyraOneJourneyConnectionsPresentation(',
        'ZyraOneJourneyConnectionsPersonCard(',
        'Supabase',
        'SharedPreferences',
        'Image.network',
        'CachedNetworkImageProvider',
      ]) {
        expect(source, isNot(contains(forbidden)));
      }
    },
  );

  for (final size in [
    const Size(375, 812),
    const Size(393, 852),
    const Size(430, 932),
  ]) {
    testWidgets(
      'Soft cards retain full request identity and natural controls at ${size.width}',
      (tester) async {
        var actions = 0;
        await _mount(
          tester,
          profile: profile,
          size: size,
          onPrimary: () => actions++,
          onAccept: () => actions++,
        );
        expect(find.text('Sara Ahmed'), findsOneWidget);
        expect(find.text('27 · Birmingham'), findsOneWidget);
        _expectWholeWordsFit(tester, find.text('Sara Ahmed'));
        final portrait = find.descendant(
          of: find.byType(ZyraRequestActivityCard),
          matching: find.byType(ClipOval),
        );
        expect(
          tester.getRect(portrait).right,
          lessThan(tester.getRect(find.text('Sara Ahmed')).left),
        );
        expect(_key(_primary), findsNothing);
        _expectNaturalText(tester);
        await _capture(tester, 'requests-${size.width.toInt()}');
        await _press(tester, _key(_header));
        final card = tester.widget<Container>(
          find.byKey(const ValueKey('request_activity_card_request')),
        );
        final decoration = card.decoration! as BoxDecoration;
        expect(decoration.color, ZyraColors.surfaceFill);
        expect(
          (decoration.border! as Border).top.color,
          ZyraColors.journeyGold.withValues(alpha: .70),
        );
        final primaryMaterial = tester.widget<Material>(
          find
              .ancestor(of: _key(_primary), matching: find.byType(Material))
              .first,
        );
        expect(primaryMaterial.color, Colors.transparent);
        for (final key in [_primary, _accept, _decline]) {
          expect(tester.getSize(_key(key)).height, greaterThanOrEqualTo(44));
        }
        await _press(tester, _key(_primary));
        expect(actions, 1);
        _expectNaturalText(tester);
        if (size.width == 393) await _capture(tester, 'requests-expanded');
      },
    );

    testWidgets(
      'standalone Introductions uses the centered Journey empty style without a card at ${size.width}',
      (tester) async {
        final changes = <int>[];
        await _mount(
          tester,
          profile: profile,
          size: size,
          introductions: true,
          onChanged: changes.add,
        );
        expect(find.byType(PageView), findsNothing);
        expect(_key(const ValueKey('request_tab_0')), findsNothing);
        expect(find.text('Received'), findsNothing);
        expect(find.text('Sent'), findsNothing);
        expect(find.text('No introductions yet'), findsOneWidget);
        expect(
          find.text('People your Guardians put forward will appear here.'),
          findsOneWidget,
        );
        expect(find.byType(ZyraRequestActivityCard), findsNothing);
        _expectPlainEmpty(
          tester,
          page: 0,
          title: 'No introductions yet',
          icon: Icons.groups_outlined,
        );
        _expectWholeWordsFit(tester, find.text('No introductions yet'));
        expect(
          tester
              .widget<Text>(find.text('No introductions yet'))
              .style!
              .fontSize,
          21,
        );
        _expectNaturalText(tester);
        await tester.drag(
          _key(const ValueKey('request_activity_empty_viewport_0')),
          const Offset(250, 0),
        );
        await tester.pumpAndSettle();
        expect(changes, isEmpty);
        await _capture(tester, 'introductions-${size.width.toInt()}');
      },
    );

    for (final sent in [false, true]) {
      testWidgets(
        'empty ${sent ? 'Sent' : 'Received'} centers the shared plain state without scrolling at ${size.width}',
        (tester) async {
          await _mount(
            tester,
            profile: profile,
            size: size,
            emptyReceived: true,
            initialIndex: sent ? 1 : 0,
          );
          final title = sent
              ? 'No sent requests yet.'
              : 'No received requests yet.';
          _expectPlainEmpty(
            tester,
            page: sent ? 1 : 0,
            title: title,
            icon: sent ? Icons.north_east_rounded : Icons.mail_outline_rounded,
          );
          _expectWholeWordsFit(tester, find.text(title));
          _expectNaturalText(tester);
          await _capture(
            tester,
            '${sent ? 'sent' : 'received'}-empty-${size.width.toInt()}',
          );
        },
      );
    }
  }

  testWidgets('Request helper ink is opaque and clears AA on the plum card', (
    tester,
  ) async {
    await _mount(tester, profile: profile);
    final ink = tester.widget<Text>(find.text('Journey request')).style!.color!;
    final surface = Color.alphaBlend(
      ZyraColors.surfaceEmphasisFill,
      ZyraColors.royalPurple,
    );
    final a = ink.computeLuminance(), b = surface.computeLuminance();
    final contrast = (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
    expect(ink.a, 1);
    expect(contrast, greaterThanOrEqualTo(4.5));
  });

  for (final introductions in [false, true]) {
    testWidgets(
      'compact 200 percent ${introductions ? 'Introductions' : 'requests'} retains whole title words and scrolling',
      (tester) async {
        var accepts = 0;
        await _mount(
          tester,
          profile: profile,
          size: const Size(320, 568),
          scale: 2,
          introductions: introductions,
          onAccept: () => accepts++,
        );
        _expectNaturalText(tester);
        _expectWholeWordsFit(
          tester,
          _key(const ValueKey('concept_connections_title')),
        );
        if (!introductions) {
          _expectWholeWordsFit(tester, find.text('Sara Ahmed'));
          final portrait = find.descendant(
            of: find.byType(ZyraRequestActivityCard),
            matching: find.byType(ClipOval),
          );
          expect(
            tester.getRect(portrait).bottom,
            lessThan(tester.getRect(find.text('Sara Ahmed')).top),
          );
          final nameContext = tester.element(find.text('Sara Ahmed'));
          expect(MediaQuery.textScalerOf(nameContext).scale(21), 42);
          await _press(tester, _key(_header));
          await _press(tester, _key(_accept));
          expect(accepts, 1);
          expect(
            tester.getSize(_key(_accept)).height,
            greaterThanOrEqualTo(44),
          );
        } else {
          expect(find.byType(PageView), findsNothing);
          _expectWholeWordsFit(tester, find.text('No introductions yet'));
          final heading = tester.widget<Text>(
            find.text('No introductions yet'),
          );
          expect(heading.style!.fontSize, 21);
          final headingContext = tester.element(
            find.text('No introductions yet'),
          );
          expect(
            MediaQuery.textScalerOf(
              headingContext,
            ).scale(heading.style!.fontSize!),
            heading.style!.fontSize! * 2,
          );
          await Scrollable.ensureVisible(
            tester.element(
              find.text('People your Guardians put forward will appear here.'),
            ),
            alignment: .5,
          );
          await tester.pumpAndSettle();
          expect(
            find
                .text('People your Guardians put forward will appear here.')
                .hitTestable(),
            findsOneWidget,
          );
        }
        _expectNaturalText(tester);
        await _capture(
          tester,
          introductions ? 'introductions-compact200' : 'requests-compact200',
        );
      },
    );
  }

  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    for (final section in ['received', 'sent', 'introductions']) {
      testWidgets(
        'plain empty $section preserves 200 percent type and reading in ${direction.name}',
        (tester) async {
          final introductions = section == 'introductions';
          final sent = section == 'sent';
          await _mount(
            tester,
            profile: profile,
            size: const Size(320, 568),
            scale: 2,
            introductions: introductions,
            emptyReceived: true,
            initialIndex: sent ? 1 : 0,
            direction: direction,
            reduceMotion: direction == TextDirection.ltr,
            accessibleNavigation: direction == TextDirection.rtl,
          );
          final title = introductions
              ? 'No introductions yet'
              : sent
              ? 'No sent requests yet.'
              : 'No received requests yet.';
          _expectPlainEmpty(
            tester,
            page: sent ? 1 : 0,
            title: title,
            icon: introductions
                ? Icons.groups_outlined
                : sent
                ? Icons.north_east_rounded
                : Icons.mail_outline_rounded,
            centered: false,
          );
          _expectNaturalText(tester);
          _expectWholeWordsFit(tester, find.text(title));
          final heading = tester.widget<Text>(find.text(title));
          expect(
            MediaQuery.textScalerOf(
              tester.element(find.text(title)),
            ).scale(heading.style!.fontSize!),
            42,
          );
          final empty = tester.widget<ZyraEmptyState>(
            find.descendant(
              of: _key(
                ValueKey('request_activity_empty_viewport_${sent ? 1 : 0}'),
              ),
              matching: find.byType(ZyraEmptyState),
            ),
          );
          final message = find.text(empty.message);
          await Scrollable.ensureVisible(
            tester.element(message),
            alignment: .5,
          );
          await tester.pumpAndSettle();
          expect(message.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
          await _capture(tester, '$section-empty-compact200-${direction.name}');
        },
      );
    }
  }

  testWidgets('long empty copy scrolls naturally without shrinking or a card', (
    tester,
  ) async {
    final message = List.filled(
      8,
      'Your Journey requests will appear here.',
    ).join(' ');
    await _mount(
      tester,
      profile: profile,
      size: const Size(320, 568),
      scale: 2,
      emptyReceived: true,
      emptyMessage: message,
    );
    _expectPlainEmpty(
      tester,
      page: 0,
      title: 'No received requests yet.',
      icon: Icons.mail_outline_rounded,
      centered: false,
    );
    final viewport = _key(const ValueKey('request_activity_empty_viewport_0'));
    final scrolling = find.descendant(
      of: viewport,
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrolling).position;
    expect(position.maxScrollExtent, greaterThan(0));
    expect(position.pixels, 0);
    await tester.drag(viewport, const Offset(0, -220));
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
    expect(find.text(message), findsOneWidget);
    _expectNaturalText(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a wide surname uses full card width before the large-type threshold',
    (tester) async {
      const wideName = SeekerProfile(
        id: 'local-wide-name',
        firstName: 'Sara',
        surnameLine: 'Rahmanullah',
        age: 27,
        city: 'Birmingham',
        gender: 'female',
        photos: [],
      );
      await _mount(
        tester,
        profile: wideName,
        size: const Size(320, 568),
        scale: 1.2,
      );
      _expectWholeWordsFit(tester, find.text('Sara Rahmanullah'));
      final portrait = find.descendant(
        of: find.byType(ZyraRequestActivityCard),
        matching: find.byType(ClipOval),
      );
      expect(
        tester.getRect(portrait).bottom,
        lessThan(tester.getRect(find.text('Sara Rahmanullah')).top),
      );
      expect(
        tester.widget<Text>(find.text('Sara Rahmanullah')).style!.fontSize,
        21,
      );
      _expectNaturalText(tester);
    },
  );

  for (final reduce in [false, true]) {
    testWidgets(
      '${reduce ? 'reduced' : 'normal'} motion expands and collapses repeatedly without layout state failure',
      (tester) async {
        await _mount(
          tester,
          profile: profile,
          reduceMotion: reduce,
          onPrimary: () {},
        );
        final animation = find.descendant(
          of: find.byType(ZyraRequestActivityCard),
          matching: find.byType(AnimatedSize),
        );
        expect(animation, reduce ? findsNothing : findsOneWidget);
        for (var index = 0; index < 4; index++) {
          await _press(tester, _key(_header));
          expect(_key(_primary), findsOneWidget);
          await _press(tester, _key(_header));
          expect(_key(_primary), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'accessible navigation bypasses AnimatedSize even when animations are otherwise enabled',
    (tester) async {
      await _mount(
        tester,
        profile: profile,
        reduceMotion: false,
        accessibleNavigation: true,
        onPrimary: () {},
      );
      await _press(tester, _key(_header));
      expect(
        find.descendant(
          of: find.byType(ZyraRequestActivityCard),
          matching: find.byType(AnimatedSize),
        ),
        findsNothing,
      );
      expect(_key(_primary), findsOneWidget);
      await _press(tester, _key(_header));
      expect(_key(_primary), findsNothing);
    },
  );

  testWidgets(
    'Received and Sent support keyed selection and centre swiping without a third tab or Back owner',
    (tester) async {
      final changes = <int>[];
      await _mount(tester, profile: profile, onChanged: changes.add);
      await tester.tap(_key(const ValueKey('request_tab_1')));
      await tester.pumpAndSettle();
      expect(changes, [1]);
      expect(find.text('No sent requests yet.'), findsOneWidget);
      await tester.drag(
        _key(const ValueKey('request_activity_pager')),
        const Offset(300, 0),
      );
      await tester.pumpAndSettle();
      expect(changes.last, 0);
      expect(find.text('Sara Ahmed'), findsOneWidget);
      expect(find.text('Introductions'), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    },
  );

  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    testWidgets(
      'two empty request pages retain selection and horizontal swiping in ${direction.name}',
      (tester) async {
        final changes = <int>[];
        await _mount(
          tester,
          profile: profile,
          emptyReceived: true,
          direction: direction,
          onChanged: changes.add,
        );
        expect(
          find.text('No received requests yet.').hitTestable(),
          findsOneWidget,
        );
        await tester.tap(_key(const ValueKey('request_tab_1')));
        await tester.pumpAndSettle();
        expect(changes, [1]);
        expect(
          find.text('No sent requests yet.').hitTestable(),
          findsOneWidget,
        );
        await tester.drag(
          _key(const ValueKey('request_activity_pager')),
          Offset(direction == TextDirection.ltr ? 300 : -300, 0),
        );
        await tester.pumpAndSettle();
        expect(changes.last, 0);
        expect(
          find.text('No received requests yet.').hitTestable(),
          findsOneWidget,
        );
        expect(find.byType(ZyraRequestActivityCard), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'tabs and enabled actions expose semantic activation while disabled actions do not',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        var activated = 0;
        await _mount(tester, profile: profile, onPrimary: () => activated++);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Sent'))
              .getSemanticsData()
              .hasAction(ui.SemanticsAction.tap),
          isTrue,
        );
        await _press(tester, _key(_header));
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('View profile'))
              .getSemanticsData()
              .hasAction(ui.SemanticsAction.tap),
          isTrue,
        );
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Decline'))
              .getSemanticsData()
              .hasAction(ui.SemanticsAction.tap),
          isFalse,
        );
        final activate = tester
            .widget<Semantics>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    widget.properties.label == 'View profile',
              ),
            )
            .properties
            .onTap;
        expect(activate, isNotNull);
        activate!();
        await tester.pumpAndSettle();
        expect(activated, 1);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'retained tab header and action callbacks refuse withdrawn caller access',
    (tester) async {
      var allowed = true;
      var acts = 0;
      final changes = <int>[];
      await _mount(
        tester,
        profile: profile,
        onPrimary: () => acts++,
        onChanged: changes.add,
        canInteract: () => allowed,
      );
      final tab = tester
          .widget<InkWell>(_key(const ValueKey('request_tab_1')))
          .onTap!;
      final header = tester.widget<InkWell>(_key(_header)).onTap!;
      await _press(tester, _key(_header));
      final action = tester.widget<InkWell>(_key(_primary)).onTap!;
      allowed = false;
      tab();
      header();
      action();
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      expect(acts, 0);
      expect(_key(_primary), findsOneWidget);
      expect(
        tester
            .widget<ZyraRequestActivityPresentation>(
              find.byType(ZyraRequestActivityPresentation),
            )
            .selectedIndex,
        0,
      );
    },
  );

  testWidgets(
    'disabled actions stay disabled and Report calls only its supplied callback',
    (tester) async {
      var reports = 0;
      await _mount(tester, profile: profile, onReport: () => reports++);
      await _press(tester, _key(_header));
      expect(tester.widget<InkWell>(_key(_decline)).onTap, isNull);
      await _press(tester, find.byTooltip('Report Sara'));
      expect(reports, 1);
    },
  );

  testWidgets('retained nonlocal portrait URL cannot initiate a network read', (
    tester,
  ) async {
    const remote = SeekerProfile(
      id: 'no-remote-read',
      firstName: 'Aisha',
      surnameLine: 'Rahman',
      age: 28,
      city: 'Leeds',
      gender: 'female',
      photos: ['https://invalid.example/photo.jpg'],
    );
    await _mount(tester, profile: remote);
    expect(find.text('Aisha Rahman'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(network.attempts, 0);
  });
}
