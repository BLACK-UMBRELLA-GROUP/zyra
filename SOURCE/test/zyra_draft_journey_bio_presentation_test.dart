import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_journey_bio_presentation.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/models/journey_bio.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

// Optional evidence only: pass a fresh, absolute directory using --dart-define.
// Geometry and privacy assertions still run when the variable is absent.
const _capture = String.fromEnvironment('ZYRA_JOURNEY_BIO_CAPTURE_DIR');
const _boundary = ValueKey('journey-bio-presentation-capture');
MemoryImage? _capturePortrait;

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Journey Bio presentation fixtures must remain offline.');
  }
}

Finder _key(String value) => find.byKey(ValueKey(value));

ZyraDraftJourneyBioProjection _shared() =>
    ZyraDraftJourneyBioProjection.fixtureFor(
      'draft-sara',
      useLegacyFixture: true,
    )!;

ZyraDraftJourneyBioProjection _empty() =>
    ZyraDraftJourneyBioProjection.fromJourneyBio(
      subjectId: 'draft-sara',
      bio: const JourneyBio(reviewed: true),
    );

Future<void> _mount(
  WidgetTester tester, {
  required ZyraDraftJourneyBioProjection? projection,
  String subjectId = 'draft-sara',
  String firstName = 'Sara',
  Widget? portrait,
  bool owned = true,
  bool showTitle = true,
  bool showProfileHeader = true,
  Size size = const Size(393, 852),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final presenter = ZyraDraftJourneyBioPresentation(
    subjectId: subjectId,
    firstName: firstName,
    projection: projection,
    portrait: portrait,
    ownedViewport: owned,
    showTitle: showTitle,
    showProfileHeader: showProfileHeader,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: EdgeInsets.only(
            top: size.height < 700 ? 44 : 59,
            bottom: 34,
          ),
          viewPadding: EdgeInsets.only(
            top: size.height < 700 ? 44 : 59,
            bottom: 34,
          ),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: RepaintBoundary(
        key: _boundary,
        child: Scaffold(
          backgroundColor: ZyraColors.luxuryDarkPurple,
          body: owned
              ? presenter
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: presenter,
                  ),
                ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _preparePortrait(WidgetTester tester) async {
  final provider = _capturePortrait;
  if (provider == null) return;
  await tester.runAsync(() async {
    final ready = Completer<void>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, _) {
        stream.removeListener(listener);
        if (!ready.isCompleted) ready.complete();
      },
      onError: (Object error, StackTrace? stack) {
        stream.removeListener(listener);
        if (!ready.isCompleted) ready.completeError(error, stack);
      },
    );
    stream.addListener(listener);
    await ready.future;
  });
}

Future<void> _captureFrame(WidgetTester tester, String name) async {
  if (_capture.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final output = File('$_capture/$name.png');
    expect(output.existsSync(), isFalse);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await output.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  late bool oldFontStubs;
  late String? oldFontFamily;

  setUpAll(() async {
    if (_capture.isEmpty) return;
    expect(
      _capture.startsWith('/'),
      isTrue,
      reason: 'Evidence requires an explicit absolute output directory.',
    );
    final directory = Directory(_capture);
    expect(
      directory.existsSync(),
      isFalse,
      reason: 'Visual evidence uses a fresh immutable destination.',
    );
    directory.createSync(recursive: true);
    final font = FontLoader('PoppinsJourneyBioEvidence');
    for (final weight in ['ExtraLight', 'Light', 'Regular']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final photo = await rootBundle.load(
      'assets/dev/one_journey_photos/zyra2a.jpg',
    );
    _capturePortrait = MemoryImage(
      photo.buffer.asUint8List(photo.offsetInBytes, photo.lengthInBytes),
    );
  });
  setUp(() {
    oldFontStubs = ZyraText.useTestFontStubs;
    oldFontFamily = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    if (_capture.isNotEmpty) {
      ZyraText.testReadingFontFamily = 'PoppinsJourneyBioEvidence';
    }
    oldNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = oldNetwork;
    ZyraText.useTestFontStubs = oldFontStubs;
    ZyraText.testReadingFontFamily = oldFontFamily;
  });

  test('projects only explicitly shared nonempty canonical fields', () {
    final projection = ZyraDraftJourneyBioProjection.fromJourneyBio(
      subjectId: 'draft-sara',
      bio: const JourneyBio(
        aboutMe: 'My hidden biography',
        showAboutMe: false,
        reviewed: true,
        fieldValues: {
          'home': '  Living with family  ',
          'income': 'Hidden income',
          'occupation': '  Product designer  ',
          'education': '   ',
          'secret_future_field': 'Unknown value',
        },
        visibleFieldIds: {
          'home',
          'occupation',
          'education',
          'secret_future_field',
          'children',
        },
      ),
    );
    expect(projection.subjectId, 'draft-sara');
    expect(projection.aboutMe, isNull);
    expect(projection.fields.map((field) => field.id), ['occupation', 'home']);
    expect(projection.fields.map((field) => field.value), [
      'Product designer',
      'Living with family',
    ]);
    expect(projection.fields.first.label, 'Occupation');
    expect(projection.fields.first.section, 'Work & education');
    expect(projection.isEmpty, isFalse);
  });

  test(
    'projection owns an immutable snapshot, not source collection aliases',
    () {
      final fields = <String, String>{'home': 'Living with family'};
      final visible = <String>{'home'};
      final projection = ZyraDraftJourneyBioProjection.fromJourneyBio(
        subjectId: 'draft-sara',
        bio: JourneyBio(
          aboutMe: '  Chosen biography.  ',
          showAboutMe: true,
          fieldValues: fields,
          visibleFieldIds: visible,
        ),
      );
      fields['home'] = 'Unshared replacement';
      fields.clear();
      visible.clear();
      expect(projection.aboutMe, 'Chosen biography.');
      expect(projection.fields.single.value, 'Living with family');
      expect(() => projection.fields.clear(), throwsUnsupportedError);
      expect(
        () => projection.fields[0] = projection.fields.first,
        throwsUnsupportedError,
      );
    },
  );

  test(
    'blank selected values are honestly empty; blank subject is rejected',
    () {
      final projection = ZyraDraftJourneyBioProjection.fromJourneyBio(
        subjectId: 'draft-sara',
        bio: const JourneyBio(
          aboutMe: '  ',
          showAboutMe: true,
          reviewed: true,
          fieldValues: {'home': '  '},
          visibleFieldIds: {'home'},
        ),
      );
      expect(projection.isEmpty, isTrue);
      expect(projection.aboutMe, isNull);
      expect(projection.fields, isEmpty);
      expect(
        () => ZyraDraftJourneyBioProjection.fromJourneyBio(
          subjectId: '  ',
          bio: const JourneyBio(),
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'offline fixture is exact-subject opt-in and follows real 400 limit',
    () {
      expect(JourneyBio.characterLimit, 400);
      for (final profile in draftProfiles) {
        expect(ZyraDraftJourneyBioProjection.fixtureFor(profile.id), isNull);
        final projection = ZyraDraftJourneyBioProjection.fixtureFor(
          profile.id,
          useLegacyFixture: true,
        )!;
        expect(projection.subjectId, profile.id);
        expect(projection.aboutMe!.length, lessThanOrEqualTo(400));
        expect(projection.fields.map((field) => field.id), [
          'occupation',
          'education',
          'future_children',
          'home',
        ]);
        expect(projection.fields, hasLength(4));
      }
      for (final id in [
        '',
        'sara',
        'draft-sar',
        'draft-sara ',
        'real-member',
      ]) {
        expect(
          ZyraDraftJourneyBioProjection.fixtureFor(id, useLegacyFixture: true),
          isNull,
        );
      }
    },
  );

  testWidgets('uses standard title and supplied portrait, with no actions', (
    tester,
  ) async {
    await _mount(
      tester,
      projection: _shared(),
      portrait: const ColoredBox(
        key: ValueKey('admitted-portrait'),
        color: Colors.pink,
      ),
    );
    final title = tester.widget<Text>(_key('draft_journey_bio_title'));
    expect(title.data, 'Journey Bio');
    expect(title.style, ZyraText.pageTitle());
    expect(title.style!.fontSize, 26);
    expect(title.textAlign, TextAlign.left);
    expect(tester.getTopLeft(_key('draft_journey_bio_title')).dx, 20);
    expect(tester.getTopLeft(_key('draft_journey_bio_title')).dy, 75);
    expect(find.text('Sara'), findsOneWidget);
    expect(_key('admitted-portrait'), findsOneWidget);
    expect(_key('draft_journey_bio_portrait_draft-sara'), findsOneWidget);
    expect(find.text('About me'), findsOneWidget);
    expect(find.text('Work & education'), findsOneWidget);
    expect(find.text('Family & marriage'), findsOneWidget);
    expect(find.text('Practical life'), findsOneWidget);
    expect(find.text('Product designer'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    expect(find.text('Reveal'), findsNothing);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('unavailable and confirmed empty remain different states', (
    tester,
  ) async {
    await _mount(tester, projection: null);
    expect(find.text('Journey Bio is unavailable.'), findsOneWidget);
    expect(_key('draft_journey_bio_empty'), findsNothing);
    expect(
      find.ancestor(
        of: _key('draft_journey_bio_unavailable'),
        matching: find.byWidgetPredicate(
          (widget) => widget is Container && widget.decoration is BoxDecoration,
        ),
      ),
      findsWidgets,
    );
    await _mount(tester, projection: _empty());
    expect(find.text('No details shared yet.'), findsOneWidget);
    expect(
      tester.widget(_key('draft_journey_bio_empty')),
      isA<ZyraEmptyState>(),
    );
    expect(_key('draft_journey_bio_unavailable'), findsNothing);
    expect(_key('draft_journey_bio_about'), findsNothing);
    expect(find.text('Work & education'), findsNothing);
  });

  for (final owned in [false, true]) {
    for (final enlarged in [false, true]) {
      testWidgets(
        'admitted empty Bio uses the LOCK 22 gold-ring state beneath its profile in ${owned ? 'owned' : 'embedded'} ${enlarged ? 'compact200' : 'normal'} reading',
        (tester) async {
          await _mount(
            tester,
            projection: _empty(),
            owned: owned,
            size: enlarged ? const Size(320, 568) : const Size(393, 852),
            scale: enlarged ? 2 : 1,
          );
          final empty = _key('draft_journey_bio_empty');
          expect(tester.widget(empty), isA<ZyraEmptyState>());
          // LOCK 22 V3, UNITY_PASS/MASTERS/e01–e02: shared 96 pt gold ring.
          final ring = tester.widget<Container>(
            find.descendant(of: empty, matching: find.byType(Container)),
          );
          expect(ring.constraints?.maxWidth, 96);
          expect(ring.constraints?.maxHeight, 96);
          expect((ring.decoration! as BoxDecoration).shape, BoxShape.circle);
          final icon = tester.widget<Icon>(
            find.descendant(of: empty, matching: find.byType(Icon)),
          );
          expect(icon.size, 34);
          expect(icon.color, ZyraColors.journeyGold);
          expect(_key('draft_journey_bio_name'), findsOneWidget);
          expect(find.text('Sara'), findsOneWidget);
          expect(_key('draft_journey_bio_title'), findsOneWidget);
          final message = find.text('No details shared yet.');
          await tester.ensureVisible(message);
          await tester.pumpAndSettle();
          expect(message.hitTestable(), findsOneWidget);
          expect(tester.widget<Text>(message).style!.fontSize, 21);
          expect(
            find.descendant(of: empty, matching: find.byType(FittedBox)),
            findsNothing,
          );
          expect(_key('draft_journey_bio_unavailable'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('wrong-subject projection and its portrait never paint', (
    tester,
  ) async {
    await _mount(
      tester,
      projection: _shared(),
      subjectId: 'draft-aisha',
      firstName: 'Aisha',
      portrait: const Text('Wrong person portrait'),
    );
    expect(find.text('Aisha'), findsOneWidget);
    expect(find.text('Sara'), findsNothing);
    expect(find.text('Wrong person portrait'), findsNothing);
    expect(find.text('Product designer'), findsNothing);
    expect(_key('draft_journey_bio_about'), findsNothing);
    expect(_key('draft_journey_bio_unavailable'), findsOneWidget);
  });

  testWidgets('hidden, unknown and unpopulated values never reach the page', (
    tester,
  ) async {
    await _mount(
      tester,
      projection: ZyraDraftJourneyBioProjection.fromJourneyBio(
        subjectId: 'draft-sara',
        bio: const JourneyBio(
          aboutMe: 'Private biography',
          reviewed: true,
          fieldValues: {
            'home': 'Shared home',
            'income': 'Private income',
            'unknown': 'Unknown secret',
            'education': '  ',
          },
          visibleFieldIds: {'home', 'unknown', 'education'},
        ),
      ),
    );
    expect(find.text('Shared home'), findsOneWidget);
    expect(find.text('Private biography'), findsNothing);
    expect(find.text('Private income'), findsNothing);
    expect(find.text('Unknown secret'), findsNothing);
    expect(find.text('Income range'), findsNothing);
    expect(find.text('Education'), findsNothing);
    expect(find.text('About me'), findsNothing);
  });

  testWidgets('all canonical groups scroll safely at 320 and double text', (
    tester,
  ) async {
    final projection = ZyraDraftJourneyBioProjection.fromJourneyBio(
      subjectId: 'draft-sara',
      bio: JourneyBio(
        aboutMe: 'A chosen biography that remains readable without clipping.',
        showAboutMe: true,
        fieldValues: {
          for (final definition in journeyBioFieldDefinitions)
            definition.id: 'Shared ${definition.label.toLowerCase()}',
        },
        visibleFieldIds: {
          for (final definition in journeyBioFieldDefinitions) definition.id,
        },
      ),
    );
    await _mount(
      tester,
      projection: projection,
      size: const Size(320, 568),
      scale: 2,
    );
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.overflow == TextOverflow.ellipsis,
      ),
      findsNothing,
    );
    await tester.ensureVisible(_key('draft_journey_bio_field_relocation'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final bottom = tester.getRect(_key('draft_journey_bio_field_relocation'));
    expect(bottom.left, greaterThanOrEqualTo(20));
    expect(bottom.right, lessThanOrEqualTo(300));
    expect(find.text('Shared relocation'), findsOneWidget);
  });

  testWidgets(
    'embeds under a caller scroll without duplicate title or header',
    (tester) async {
      await _mount(
        tester,
        projection: _shared(),
        owned: false,
        showTitle: false,
        showProfileHeader: false,
        size: const Size(320, 568),
        scale: 2,
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(_key('draft_journey_bio_title'), findsNothing);
      expect(_key('draft_journey_bio_name'), findsNothing);
      expect(find.text('About me'), findsOneWidget);
      expect(find.text('Product designer'), findsOneWidget);
      await tester.ensureVisible(_key('draft_journey_bio_field_home'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('real portrait and typography evidence with safe geometry', (
    tester,
  ) async {
    await _preparePortrait(tester);
    final portrait = _capturePortrait == null
        ? null
        : Image(image: _capturePortrait!, fit: BoxFit.cover);
    for (final scenario in [
      (name: 'shared', view: _shared()),
      (name: 'unavailable', view: null),
      (name: 'empty', view: _empty()),
      (
        name: 'selected_field',
        view: ZyraDraftJourneyBioProjection.fromJourneyBio(
          subjectId: 'draft-sara',
          bio: const JourneyBio(
            fieldValues: {'home': 'Living with family'},
            visibleFieldIds: {'home'},
          ),
        ),
      ),
    ]) {
      await _mount(tester, projection: scenario.view, portrait: portrait);
      expect(
        tester.getRect(_key('draft_journey_bio_title')).right,
        lessThanOrEqualTo(373),
      );
      await _captureFrame(tester, scenario.name);
    }
    await _mount(
      tester,
      projection: _shared(),
      portrait: portrait,
      size: const Size(320, 568),
      scale: 2,
    );
    await _captureFrame(tester, 'compact_double_text_top');
    await tester.ensureVisible(_key('draft_journey_bio_field_home'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _captureFrame(tester, 'compact_double_text_bottom');
  });
}
