import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart' as sample;
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart' as shared;
import 'package:zyra/widgets/zyra_profile_image.dart';
import 'package:zyra/widgets/zyra_profile_name_block.dart';

// Synthetic references, not production URLs or proof of authorisation. These
// tests prove the explicit rendering seam only, without fetching any photo.
const _member = SeekerProfile(
  id: '6f4411b5-351f-4ceb-815a-886f84a3f15d',
  firstName: 'Nadia',
  surnameLine: 'Yusuf',
  age: 29,
  city: 'Leeds',
  gender: 'female',
  photos: [
    'https://member.example.invalid/photos/one.jpg?token=synthetic',
    'https://member.example.invalid/photos/two.jpg?token=synthetic',
    'https://member.example.invalid/photos/three.jpg?token=synthetic',
  ],
);

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Injected photo renderer tests must remain offline.');
  }
}

class _PhotoCall {
  const _PhotoCall(this.photo, this.width, this.height, this.alignment);

  final String photo;
  final double width;
  final double height;
  final Alignment alignment;
}

class _InjectedRenderer {
  final calls = <_PhotoCall>[];

  Widget build(
    BuildContext context,
    String photo, {
    required double width,
    required double height,
    required Alignment alignment,
  }) {
    calls.add(_PhotoCall(photo, width, height, alignment));
    return const ColoredBox(color: Colors.blueGrey);
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));

void _expectSelectedDot(WidgetTester tester, int index) {
  final dot = tester.widget<AnimatedContainer>(
    _key('concept_browse_photo_dot_${_member.id}_$index'),
  );
  expect(dot.constraints!.maxWidth, 20);
  expect(dot.constraints!.maxHeight, 5);
  expect((dot.decoration! as BoxDecoration).color, ZyraColors.journeyGold);
}

Future<void> _mount(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(find.text('View profiles at your pace.'), findsNothing);
  expect(
    find.text('Next moves on without sending a request or removing anyone.'),
    findsNothing,
  );
}

Future<void> _press(WidgetTester tester, String key) async {
  final button = _key(key);
  expect(button, findsOneWidget);
  if (button.hitTestable().evaluate().isEmpty) {
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
  }
  expect(button.hitTestable(), findsOneWidget);
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousFatalHitTests = WidgetController.hitTestWarningShouldBeFatal;
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDownAll(
    () => WidgetController.hitTestWarningShouldBeFatal = previousFatalHitTests,
  );
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  test('developer import shares only the retained Portrait identity', () {
    expect(sample.ZyraOneJourneyBrowseDesign.values.map((d) => d.name), [
      'portraitCard',
    ]);
    expect(shared.ZyraOneJourneyBrowseDesign.values.map((d) => d.name), [
      'portraitCard',
    ]);
    expect(
      sample.ZyraOneJourneyBrowseDesign.portraitCard,
      same(shared.ZyraOneJourneyBrowseDesign.portraitCard),
    );
  });

  for (final design in shared.ZyraOneJourneyBrowseDesign.values) {
    testWidgets('${design.name} accepts an explicit member photo renderer', (
      tester,
    ) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        final renderer = _InjectedRenderer();
        final requested = <String>[];
        var previous = 0, next = 0, filters = 0;
        await _mount(
          tester,
          shared.ZyraBrowseDesigns(
            profiles: const [_member],
            selectedIndex: 0,
            design: design,
            galleryMode: shared.ZyraBrowseGalleryMode.originalPhotos,
            photoBuilder: renderer.build,
            onPrevious: () => previous++,
            onNext: () => next++,
            onFilters: () => filters++,
            onRequest: (profile) => requested.add(profile.id),
          ),
        );
        final identity = tester.widget<ZyraProfileNameBlock>(
          find.descendant(
            of: _key('concept_browse_identity_${_member.id}'),
            matching: find.byType(ZyraProfileNameBlock),
          ),
        );
        expect(identity.profile, same(_member));
        expect(identity.profile.firstName, 'Nadia');
        expect(identity.profile.surnameLine, 'Yusuf');
        expect(identity.onPhoto, isTrue);
        expect(renderer.calls, isNotEmpty);
        expect(
          renderer.calls.any((call) => call.photo == _member.photos.first),
          isTrue,
        );
        for (final call in renderer.calls) {
          expect(_member.photos, contains(call.photo));
          // Current's photo now occupies the former 26px card inset too;
          // its bounded outer card and footer budget have not grown.
          expect(call.height, inInclusiveRange(48, 646));
          expect(call.alignment, Alignment.topCenter);
        }
        // The shared presenter creates no image provider behind the callback.
        expect(find.byType(ZyraProfileImage), findsNothing);
        expect(find.byType(Image), findsNothing);
        await _press(tester, 'concept_next_profile');
        await _press(tester, 'concept_previous_profile');
        await _press(tester, 'concept_filters');
        expect([next, previous, filters], [1, 1, 1]);
        expect(requested, isEmpty);
        await _press(tester, 'draft_profile_${_member.id}');
        expect(requested, [_member.id]);
      }, network);
      expect(network.attempts, 0);
    });

    testWidgets('${design.name} sample wrapper still rejects signed URLs', (
      tester,
    ) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(
          tester,
          sample.ZyraOneJourneyBrowseDesigns(
            profiles: const [_member],
            selectedIndex: 0,
            design: design,
            galleryMode: sample.ZyraBrowseGalleryMode.originalPhotos,
          ),
        );
        final images = tester
            .widgetList<ZyraProfileImage>(find.byType(ZyraProfileImage))
            .toList();
        expect(images, isNotEmpty);
        expect(images.every((photo) => photo.photo.isEmpty), isTrue);
        expect(
          tester.widget<InkWell>(_key('draft_profile_${_member.id}')).onTap,
          isNull,
        );
      }, network);
      expect(network.attempts, 0);
    });
  }

  testWidgets(
    'portrait gallery keeps its photo selection with injected images',
    (tester) async {
      final renderer = _InjectedRenderer();
      await _mount(
        tester,
        shared.ZyraBrowseDesigns(
          profiles: const [_member],
          selectedIndex: 0,
          design: shared.ZyraOneJourneyBrowseDesign.portraitCard,
          galleryMode: shared.ZyraBrowseGalleryMode.originalPhotos,
          photoBuilder: renderer.build,
        ),
      );
      renderer.calls.clear();
      await tester.drag(
        _key('concept_browse_photo_swipe_${_member.id}'),
        const Offset(-750, 0),
      );
      await tester.pumpAndSettle();
      _expectSelectedDot(tester, 1);
      expect(
        renderer.calls.any((call) => call.photo == _member.photos[1]),
        isTrue,
      );
      renderer.calls.clear();
      await tester.drag(
        _key('concept_browse_photo_swipe_${_member.id}'),
        const Offset(750, 0),
      );
      await tester.pumpAndSettle();
      _expectSelectedDot(tester, 0);
      expect(
        renderer.calls.any((call) => call.photo == _member.photos.first),
        isTrue,
      );
    },
  );

  testWidgets('missing photo stays empty for the caller-owned placeholder', (
    tester,
  ) async {
    const noPhoto = SeekerProfile(
      id: 'no-photo',
      firstName: 'Nadia',
      surnameLine: 'Yusuf',
      age: 29,
      city: 'Leeds',
      gender: 'female',
      photos: [],
    );
    final renderer = _InjectedRenderer();
    await _mount(
      tester,
      shared.ZyraBrowseDesigns(
        profiles: const [noPhoto],
        selectedIndex: 0,
        design: shared.ZyraOneJourneyBrowseDesign.portraitCard,
        galleryMode: shared.ZyraBrowseGalleryMode.originalPhotos,
        photoBuilder: renderer.build,
      ),
    );
    expect(renderer.calls, isNotEmpty);
    expect(renderer.calls.every((call) => call.photo.isEmpty), isTrue);
    expect(find.byType(ZyraProfileImage), findsNothing);
    expect(_key('concept_browse_photo_next_${noPhoto.id}'), findsNothing);
  });

  testWidgets('request availability remains caller-owned', (tester) async {
    final renderer = _InjectedRenderer();
    var requests = 0;
    await _mount(
      tester,
      shared.ZyraBrowseDesigns(
        profiles: const [_member],
        selectedIndex: 0,
        design: shared.ZyraOneJourneyBrowseDesign.portraitCard,
        photoBuilder: renderer.build,
        requestLabel: (_) => 'Unavailable',
        canRequest: (_) => false,
        onRequest: (_) => requests++,
      ),
    );
    expect(find.text('Unavailable'), findsOneWidget);
    expect(
      tester.widget<InkWell>(_key('draft_profile_${_member.id}')).onTap,
      isNull,
    );
    expect(requests, 0);
  });
}
