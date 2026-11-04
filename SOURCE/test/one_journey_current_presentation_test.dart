import 'support/zyra_hidden_dev_controls_driver.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_stages.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_draft_compatibility_store_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_journey_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_sample_photos.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/connections/connections_section_controller.dart';
import 'package:zyra/screens/wali/wali_seekers_screen.dart';
import 'package:zyra/services/zyra_guardian_seeker_roster_resolver.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/theme/zyra_card_metrics.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_membership_choices.dart';
import 'package:zyra/widgets/zyra_personalisation_content.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';
import 'package:zyra/widgets/zyra_profile_name_block.dart';
import 'package:zyra/widgets/zyra_segmented_toggle.dart';

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Current-style presentation must stay offline.');
  }
}

const _account = ZyraConceptAccountData(
  guardian: false,
  name: 'Adam Khan',
  age: '30',
  gender: 'Male',
  location: 'London',
  membership: 'Seeker One',
  isOne: true,
  relationship: 'Father',
  linkedSeekers: '1',
  guardianCount: '2',
  signedInWith: 'Google',
  backgroundLabel: 'Midnight Plum',
  hapticLabel: 'Subtle',
  gold: false,
);

const _guardian = ZyraConceptAccountData(
  guardian: true,
  name: 'Hassan Rahman',
  age: '54',
  gender: 'Male',
  location: 'London',
  membership: 'Guardian One',
  isOne: true,
  relationship: 'Father',
  linkedSeekers: '1',
  guardianCount: '2',
  signedInWith: 'Google',
  backgroundLabel: 'Midnight Plum',
  hapticLabel: 'Subtle',
  gold: false,
);

ZyraConceptAccountData _namedAccount(
  String name, {
  bool guardian = false,
  int? standardUnlocks,
  int? plusUnlocks,
}) {
  final base = guardian ? _guardian : _account;
  return ZyraConceptAccountData(
    guardian: base.guardian,
    name: name,
    age: base.age,
    gender: base.gender,
    location: base.location,
    membership: base.membership,
    isOne: base.isOne,
    relationship: base.relationship,
    linkedSeekers: base.linkedSeekers,
    guardianCount: base.guardianCount,
    signedInWith: base.signedInWith,
    backgroundLabel: base.backgroundLabel,
    hapticLabel: base.hapticLabel,
    gold: base.gold,
    standardUnlocks: standardUnlocks,
    plusUnlocks: plusUnlocks,
  );
}

const _profile = SeekerProfile(
  id: 'offline-sara',
  firstName: 'Sara',
  surnameLine: 'Ahmed',
  age: 27,
  city: 'Birmingham',
  photos: ['sample-one', 'sample-two', 'sample-three'],
  gender: 'female',
);

Finder _key(String value) => find.byKey(ValueKey(value));

Widget _app(Widget child, {double scale = 1, bool reduce = true}) =>
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduce,
        ),
        child: child!,
      ),
      home: Scaffold(body: child),
    );

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(900, 1800),
  double scale = 1,
  bool reduce = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_app(child, scale: scale, reduce: reduce));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _expectCopy(
  WidgetTester tester,
  String scrollKey,
  Iterable<String> expected,
) async {
  final scroller = find.descendant(
    of: _key(scrollKey),
    matching: find.byType(Scrollable),
  );
  expect(scroller, findsOneWidget);
  for (final copy in expected) {
    final text = find.text(copy);
    await tester.scrollUntilVisible(text.first, 180, scrollable: scroller);
    await tester.pumpAndSettle();
    expect(text, findsWidgets, reason: 'Missing current-app copy: $copy');
  }
  expect(tester.takeException(), isNull);
}

Future<void> _purePress(WidgetTester tester, String key) async {
  if (await pressZyraDevControlKey(tester, key)) return;
  final target = _key(key);
  expect(target, findsOneWidget);
  if (target.hitTestable().evaluate().isEmpty) {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

bool _hasNamedTap(SemanticsNode node, String label) {
  final data = node.getSemanticsData();
  if (data.label.contains(label) && data.hasAction(ui.SemanticsAction.tap)) {
    return true;
  }
  var found = false;
  node.visitChildren((child) {
    found = _hasNamedTap(child, label);
    return !found;
  });
  return found;
}

int _tapActions(SemanticsNode node) {
  var count = node.getSemanticsData().hasAction(ui.SemanticsAction.tap) ? 1 : 0;
  node.visitChildren((child) {
    count += _tapActions(child);
    return true;
  });
  return count;
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

  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0),
    (size: Size(320, 568), scale: 1.4),
    (size: Size(320, 568), scale: 2.0),
  ]) {
    for (final design in ZyraOneJourneyBrowseDesign.values) {
      testWidgets(
        '${design.name} bounded Browse at ${viewport.scale} is local and deliberate',
        (tester) async {
          final network = _NoNetwork();
          await HttpOverrides.runWithHttpOverrides(() async {
            final photos = await tester.runAsync(
              ZyraOneJourneySamplePhotos.load,
            );
            final profile = SeekerProfile(
              id: 'design-sara',
              firstName: 'Sara',
              surnameLine: 'Ahmed',
              age: 27,
              city: 'Birmingham',
              gender: 'female',
              photos: photos!.sets.first,
            );
            final other = SeekerProfile(
              id: 'design-amira',
              firstName: 'Amira',
              surnameLine: 'Rahman',
              age: 28,
              city: 'Manchester',
              gender: 'female',
              photos: photos.sets[1],
            );
            final requests = <String>[];
            final opened = <String>[];
            var previous = 0, next = 0, filters = 0;
            await _mount(
              tester,
              ZyraOneJourneyBrowseDesigns(
                profiles: [profile, other],
                selectedIndex: 0,
                design: design,
                onRequest: (p) => requests.add(p.id),
                onProfile: (p) => opened.add(p.id),
                onPrevious: () => previous++,
                onNext: () => next++,
                onFilters: () => filters++,
              ),
              size: viewport.size,
              scale: viewport.scale,
            );
            final details = _key('concept_browse_details_${profile.id}');
            expect(details, findsOneWidget);
            expect(
              find.descendant(of: details, matching: find.text('Sara')),
              findsOneWidget,
            );
            expect(
              find.descendant(of: details, matching: find.text('Ahmed')),
              findsOneWidget,
            );
            final avatar = tester.widget<ZyraProfileImage>(
              find.byType(ZyraProfileImage),
            );
            expect(avatar.photo, profile.photos.first);
            expect(avatar.photo, startsWith('data:image/'));
            expect((avatar.width, avatar.height), (50, 50));
            expect(find.byType(ZyraProfileNameBlock), findsNothing);
            expect(find.text('Pass'), findsNothing);
            expect(find.text('Dislike'), findsNothing);
            await _purePress(tester, 'concept_next_profile');
            await _purePress(tester, 'concept_previous_profile');
            await _purePress(tester, 'concept_filters');
            expect(next, 1);
            expect(previous, 1);
            expect(filters, 1);
            expect(requests, isEmpty);
            expect(opened, isEmpty);
            final photoPager = _key('concept_browse_photo_swipe_${profile.id}');
            expect(photoPager, findsOneWidget);
            {
              await tester.ensureVisible(photoPager);
              await tester.pumpAndSettle();
              final pager = tester.widget<PageView>(photoPager);
              expect(
                (pager.childrenDelegate as SliverChildBuilderDelegate)
                    .childCount,
                profile.photos.length + 1,
              );
              expect(pager.controller!.page, closeTo(0, .01));
              final photoRect = tester.getRect(photoPager);
              final cardRect = tester.getRect(
                _key('concept_browse_portrait_card'),
              );
              final footerRect = tester.getRect(_key('concept_browse_footer'));
              // This slow, within-panel gesture crosses only one photo's
              // snap midpoint without a multi-page fling.
              await tester.timedDragFrom(
                Offset(
                  photoRect.left + photoRect.width * .95,
                  photoRect.center.dy,
                ),
                Offset(-photoRect.width * .9, 0),
                const Duration(milliseconds: 600),
              );
              await tester.pumpAndSettle();
              expect(
                tester.widget<PageView>(photoPager).controller!.page,
                closeTo(1, .01),
              );
              final activeDot = tester.widget<AnimatedContainer>(
                _key('concept_browse_photo_dot_${profile.id}_1'),
              );
              expect(activeDot.constraints?.maxWidth, 20);
              expect(activeDot.constraints?.maxHeight, 5);
              expect(
                (activeDot.decoration! as BoxDecoration).color,
                ZyraColors.journeyGold,
              );
              expect(find.byType(ZyraProfileNameBlock), findsNothing);
              expect(
                _key('concept_browse_identity_${profile.id}'),
                findsNothing,
                reason: 'Details-first photos have no duplicate identity.',
              );
              final visiblePhoto = _key('concept_browse_photo_${profile.id}_0');
              expect(visiblePhoto, findsOneWidget);
              expect(tester.getRect(visiblePhoto), photoRect);
              expect(tester.getRect(photoPager), photoRect);
              expect(
                tester.getRect(_key('concept_browse_portrait_card')),
                cardRect,
              );
              expect(tester.getRect(_key('concept_browse_footer')), footerRect);
              expect(find.byType(ZyraProfileImage), findsWidgets);
              for (final photo in tester.widgetList<ZyraProfileImage>(
                find.byType(ZyraProfileImage),
              )) {
                expect(photo.photo.startsWith('data:image/'), isTrue);
              }
              for (final element in find.byType(ZyraProfileImage).evaluate()) {
                final size = tester.getSize(find.byWidget(element.widget));
                expect(size.height, lessThanOrEqualTo(photoRect.height));
                expect(size.width, lessThanOrEqualTo(photoRect.width));
                expect(size.height, lessThan(viewport.size.height));
                expect(size.width, lessThan(viewport.size.width));
              }
              expect(photoRect.bottom, lessThanOrEqualTo(footerRect.top));
              // A gesture changes only the current person's photo. Navigation
              // and request delegates still require deliberate presses.
              expect(previous, 1);
              expect(next, 1);
              expect(filters, 1);
              final browse = tester.widget<ZyraOneJourneyBrowseDesigns>(
                find.byType(ZyraOneJourneyBrowseDesigns),
              );
              expect(browse.profiles[browse.selectedIndex], same(profile));
            }
            expect(requests, isEmpty);
            expect(opened, isEmpty);
            await _purePress(tester, 'draft_profile_${profile.id}');
            expect(requests, [profile.id]);
            expect(tester.takeException(), isNull);
          }, network);
          expect(network.attempts, 0);
        },
      );
    }
  }

  testWidgets('current Portrait rejects network photo input', (tester) async {
    final network = _NoNetwork();
    await HttpOverrides.runWithHttpOverrides(() async {
      const profile = SeekerProfile(
        id: 'untrusted-photo',
        firstName: 'Sara',
        surnameLine: 'Ahmed',
        age: 27,
        city: 'Birmingham',
        gender: 'female',
        photos: ['https://invalid.example/never-load.jpg'],
      );
      for (final design in ZyraOneJourneyBrowseDesign.values) {
        await _mount(
          tester,
          ZyraOneJourneyBrowseDesigns(
            profiles: const [profile],
            selectedIndex: 0,
            design: design,
          ),
        );
        await tester.tap(_key('concept_browse_photo_tap_${profile.id}'));
        await tester.pumpAndSettle();
        expect(find.byType(ZyraProfileImage), findsOneWidget);
        expect(
          tester
              .widgetList<ZyraProfileImage>(find.byType(ZyraProfileImage))
              .every((photo) => photo.photo.isEmpty),
          isTrue,
        );
        expect(
          tester.widget<InkWell>(_key('draft_profile_${profile.id}')).onTap,
          isNull,
        );
        expect(tester.takeException(), isNull);
      }
    }, network);
    expect(network.attempts, 0);
  });

  testWidgets(
    'ordinary Guardian roster decoration is unchanged; isolated canvas is explicit',
    (tester) async {
      Widget roster({Decoration? decoration}) => GuardianSeekerRosterView(
        resolution: const GuardianSeekerRosterResolution(
          mainSections: [],
          additionalGuardianships: [],
        ),
        decoration: decoration,
        onRetry: () {},
        onInvite: () {},
        onOpenSeeker: (_) {},
      );
      Decoration? canvas() => tester
          .widget<Container>(
            find
                .descendant(
                  of: find.byType(GuardianSeekerRosterView),
                  matching: find.byType(Container),
                )
                .first,
          )
          .decoration;
      await _mount(tester, roster());
      expect(canvas(), isA<ZyraAppGoldDecoration>());
      const explicitCanvas = BoxDecoration();
      await tester.pumpWidget(_app(roster(decoration: explicitCanvas)));
      await tester.pumpAndSettle();
      expect(canvas(), same(explicitCanvas));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all sixteen original local stock portraits load offline', (
    tester,
  ) async {
    final network = _NoNetwork();
    await HttpOverrides.runWithHttpOverrides(() async {
      expect(
        ZyraOneJourneySamplePhotos.seeds.map((set) => set.length).toList(),
        [3, 2, 3, 1, 2, 1, 1, 1],
      );
      final photos = await tester.runAsync(ZyraOneJourneySamplePhotos.load);
      expect(photos, isNotNull);
      expect(photos!.sets.length, 8);
      expect(photos.sets.map((set) => set.length).toList(), [
        3,
        2,
        3,
        1,
        2,
        1,
        1,
        1,
      ]);
      expect(photos.sets.expand((set) => set).length, 14);
      expect(photos.sets.map((set) => set.first).toSet().length, 8);
      expect(photos.seekerPhoto.startsWith('data:image/jpeg;base64,'), isTrue);
      expect(
        photos.guardianPhoto.startsWith('data:image/jpeg;base64,'),
        isTrue,
      );
      expect(photos.seekerPhoto == photos.guardianPhoto, isFalse);
      expect(
        photos.sets.expand((set) => set).contains(photos.seekerPhoto),
        isFalse,
      );
      expect(
        photos.sets.expand((set) => set).contains(photos.guardianPhoto),
        isFalse,
      );
      expect(() => photos.sets.add([]), throwsUnsupportedError);
      expect(
        () => photos.sets.first.add('not-a-photo'),
        throwsUnsupportedError,
      );
      expect(ZyraOneJourneySamplePhotos.seeds, [
        ['zyra1a', 'zyra1b', 'zyra1c'],
        ['zyra2a', 'zyra2b'],
        ['zyra3a', 'zyra3b', 'zyra3c'],
        ['zyra4a'],
        ['zyra5a', 'zyra5b'],
        ['zyra6a'],
        ['zyra7a'],
        ['zyra8a'],
      ]);
      final allPhotos = [
        ...photos.sets.expand((set) => set),
        photos.seekerPhoto,
        photos.guardianPhoto,
      ];
      final allSeeds = [
        ...ZyraOneJourneySamplePhotos.seeds.expand((set) => set),
        'seeker_self',
        'guardian_self',
      ];
      expect(allPhotos.length, 16);
      for (var index = 0; index < allPhotos.length; index++) {
        final photo = allPhotos[index];
        expect(photo.startsWith('data:image/jpeg;base64,'), isTrue);
        final bytes = base64Decode(photo.split(',').last);
        final seed = allSeeds[index];
        final original = await tester.runAsync(
          () => rootBundle.load('assets/dev/one_journey_photos/$seed.jpg'),
        );
        expect(
          listEquals(
            bytes,
            original!.buffer.asUint8List(
              original.offsetInBytes,
              original.lengthInBytes,
            ),
          ),
          isTrue,
          reason:
              '$seed must be the exact bundled image, not a remote replacement.',
        );
        final dimensions = await tester.runAsync(() async {
          final codec = await ui.instantiateImageCodec(bytes);
          try {
            final frame = await codec.getNextFrame();
            try {
              return Size(
                frame.image.width.toDouble(),
                frame.image.height.toDouble(),
              );
            } finally {
              frame.image.dispose();
            }
          } finally {
            codec.dispose();
          }
        });
        expect(dimensions, const Size(1400, 1400));
      }
      final profile = SeekerProfile(
        id: _profile.id,
        firstName: _profile.firstName,
        surnameLine: _profile.surnameLine,
        age: _profile.age,
        city: _profile.city,
        gender: _profile.gender,
        photos: photos.forIndex(0),
      );
      await _mount(
        tester,
        ZyraOneJourneyBrowsePresentation(profile: profile, onMenu: () {}),
        size: const Size(390, 844),
      );
      expect(find.byType(ZyraProfileImage), findsOneWidget);
      expect(
        tester.widget<ZyraProfileImage>(find.byType(ZyraProfileImage)).photo,
        photos.forIndex(0).first,
      );
      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<MemoryImage>(),
      );
      final mountedPhoto = tester.widget<Image>(find.byType(Image));
      await tester.runAsync(
        () => precacheImage(
          mountedPhoto.image,
          tester.element(find.byWidget(mountedPhoto)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RawImage), findsOneWidget);
      expect(
        tester.widget<RawImage>(find.byType(RawImage)).image,
        isNotNull,
        reason: 'The actual current shared photo widget must paint its asset.',
      );
      expect(find.text('Sara'), findsOneWidget);
      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.text('27 · Birmingham'), findsOneWidget);
    }, network);
    expect(network.attempts, 0);
  });

  testWidgets('current Browse gallery does not invoke Journey actions', (
    tester,
  ) async {
    var request = 0;
    var previous = 0;
    var next = 0;
    var menu = 0;
    Widget body(SeekerProfile profile) => ZyraOneJourneyBrowsePresentation(
      profile: profile,
      onMenu: () => menu++,
      onRequest: () => request++,
      onPreviousProfile: () => previous++,
      onNextProfile: () => next++,
      previousKey: const ValueKey('previous-person'),
      nextKey: const ValueKey('next-person'),
      requestKey: const ValueKey('request-person'),
      menuKey: const ValueKey('menu-person'),
      imageBuilder: (_, photo) =>
          ColoredBox(key: ValueKey(photo), color: Colors.black),
    );
    await _mount(tester, body(_profile), size: const Size(390, 844));
    final name = tester.widget<ZyraProfileNameBlock>(
      find.byType(ZyraProfileNameBlock),
    );
    expect(name.profile, same(_profile));
    expect(name.nameSize, 30);
    expect(name.onPhoto, isTrue);
    expect(name.showSurname, isTrue);
    expect(_key('sample-one'), findsOneWidget);
    expect(_key('concept_browse_photo_dot_0'), findsOneWidget);
    expect(_key('concept_browse_photo_dot_1'), findsOneWidget);
    expect(_key('concept_browse_photo_dot_2'), findsOneWidget);
    await tester.tapAt(const Offset(350, 350));
    await tester.pumpAndSettle();
    expect(_key('sample-two'), findsOneWidget);
    expect((request, previous, next, menu), (0, 0, 0, 0));
    await tester.tapAt(const Offset(35, 350));
    await tester.pumpAndSettle();
    expect(_key('sample-one'), findsOneWidget);
    await tester.tapAt(const Offset(350, 350));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _app(
        body(
          const SeekerProfile(
            id: 'another-local-person',
            firstName: 'Amira',
            age: 28,
            city: 'Manchester',
            photos: ['other-one', 'other-two'],
            gender: 'female',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      _key('other-one'),
      findsOneWidget,
      reason: 'A new person resets the gallery, not the methodology.',
    );
    for (final key in [
      'previous-person',
      'next-person',
      'menu-person',
      'request-person',
    ]) {
      await tester.tap(_key(key));
      await tester.pumpAndSettle();
    }
    expect((request, previous, next, menu), (1, 1, 1, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Connections uses current linked PageView and segmented motion', (
    tester,
  ) async {
    var selected = 0;
    await _mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) => ZyraOneJourneyConnectionsPresentation(
          labels: const ['Journeys', 'Requests', 'Saved'],
          pages: const [
            [Text('Journey page')],
            [Text('Request page')],
            [Text('Saved page')],
          ],
          selectedIndex: selected,
          segmentKeys: const [
            ValueKey('segment-0'),
            ValueKey('segment-1'),
            ValueKey('segment-2'),
          ],
          onChanged: (index) => setState(() => selected = index),
        ),
      ),
      size: const Size(390, 844),
    );
    expect(find.byType(PageView), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Connections')).style,
      ZyraText.heading(size: 26),
    );
    await tester.tap(_key('segment-1'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(
      tester
          .widget<ZyraSegmentedToggle>(find.byType(ZyraSegmentedToggle))
          .position,
      1,
    );
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(
      tester
          .widget<ZyraSegmentedToggle>(find.byType(ZyraSegmentedToggle))
          .position,
      2,
    );
    await tester.drag(find.byType(PageView), const Offset(350, 0));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(tester.takeException(), isNull);
  });

  for (final reduce in [true, false]) {
    testWidgets(
      'current Connections cards share one expansion and photo metrics (reduced $reduce)',
      (tester) async {
        final expansion = ZyraConnectionsExpansionController();
        addTearDown(expansion.dispose);
        await _mount(
          tester,
          ListView(
            children: [
              for (final id in ['one', 'two'])
                ZyraOneJourneyConnectionsPersonCard(
                  profile: _profile,
                  subtitle: 'Journey request',
                  actions: Text('Actions for $id'),
                  cardId: id,
                  controller: expansion,
                  headerKey: ValueKey('header-$id'),
                  imageBuilder: (_, _) => const ColoredBox(color: Colors.black),
                ),
            ],
          ),
          reduce: reduce,
        );
        for (final header in ['header-one', 'header-two']) {
          final thumbs = find.descendant(
            of: _key(header),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is SizedBox &&
                  widget.width == ZyraCardMetrics.thumb &&
                  widget.height == ZyraCardMetrics.thumb,
            ),
          );
          expect(thumbs, findsOneWidget);
          expect(tester.getSize(thumbs), const Size(52, 52));
        }
        await tester.tap(_key('header-one'));
        await tester.pumpAndSettle();
        expect(expansion.value, 'one');
        await tester.tap(_key('header-two'));
        await tester.pumpAndSettle();
        expect(expansion.value, 'two');
        final surfaces = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((widget) => widget.decoration)
            .whereType<BoxDecoration>()
            .where(
              (decoration) =>
                  decoration.borderRadius == BorderRadius.circular(14),
            )
            .toList();
        expect(surfaces.map((surface) => surface.color), [
          ZyraColors.surfaceFill,
          ZyraColors.surfaceEmphasisFill,
        ]);
        if (reduce) {
          expect(find.byType(AnimatedCrossFade), findsNothing);
          expect(find.text('Actions for one'), findsNothing);
          expect(find.text('Actions for two'), findsOneWidget);
        } else {
          final fades = tester
              .widgetList<AnimatedCrossFade>(find.byType(AnimatedCrossFade))
              .toList();
          expect(fades.map((fade) => fade.crossFadeState), [
            CrossFadeState.showFirst,
            CrossFadeState.showSecond,
          ]);
          expect(
            fades.every(
              (fade) => fade.duration == const Duration(milliseconds: 200),
            ),
            isTrue,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final guardian in [false, true]) {
    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} Profile preserves LOCK 21 copy and callbacks',
      (tester) async {
        final actions = <ZyraConceptAccountAction>[];
        var switches = 0;
        await _mount(
          tester,
          ZyraConceptProfilePresentation(
            data: guardian ? _guardian : _account,
            onAction: actions.add,
            onSwitchRole: () => switches++,
          ),
        );
        expect(_key('concept_membership'), findsOneWidget);
        expect(_key('switch-account-button'), findsOneWidget);
        final title = tester.widget<Text>(_key('concept_profile_title'));
        expect(title.data, 'Profile');
        expect(title.style?.fontSize, 26);
        expect(title.textAlign, TextAlign.left);
        await _expectCopy(tester, 'concept-current-profile-scroll', [
          guardian ? 'Hassan Rahman' : 'Adam Khan',
          if (!guardian) ...[
            'Compatibility Unlocks',
            'Preview',
            'Edit',
            'Manage photos',
          ],
          if (guardian) 'Your Seekers',
          'Profiles & Family places',
          'Safety & advice',
          'Invite someone to ZYRA',
          'Appearance & haptics',
          'Settings',
          'Sign out',
        ]);
        for (final hint in [
          'See exactly what another Seeker sees',
          'About you, preferences and compatibility answers',
          'Add, arrange and choose your main photo',
        ]) {
          expect(find.text(hint), findsNothing);
        }
        expect(find.text('Journey Bio'), findsNothing);
        expect(
          find.textContaining('Your answers remain private; no fake score'),
          findsNothing,
        );
        if (guardian) {
          for (final copy in [
            'COMPATIBILITY',
            'YOUR PROFILE',
            'JOURNEY HISTORY',
            'Age',
            'Gender',
            'Location',
            'Preview my profile',
            'Edit profile',
            'Manage photos',
          ]) {
            expect(find.text(copy), findsNothing);
          }
        }
        final keyToAction = <String, ZyraConceptAccountAction>{
          if (!guardian) ...{
            'concept_compatibility_buy_more':
                ZyraConceptAccountAction.compatibilityStore,
            'concept_preview_profile': ZyraConceptAccountAction.previewProfile,
            'concept_edit_profile': ZyraConceptAccountAction.editProfile,
            'concept_manage_photos': ZyraConceptAccountAction.managePhotos,
          },
          if (guardian)
            'concept_your_seekers': ZyraConceptAccountAction.yourSeekers,
          'concept_safety_advice': ZyraConceptAccountAction.safetyAdvice,
          'concept_invite': ZyraConceptAccountAction.invite,
          'concept_personalisation': ZyraConceptAccountAction.personalisation,
          'concept_settings': ZyraConceptAccountAction.settings,
          'concept_sign_out': ZyraConceptAccountAction.signOut,
        };
        for (final entry in keyToAction.entries) {
          await tester.scrollUntilVisible(
            _key(entry.key),
            -180,
            scrollable: find.descendant(
              of: _key('concept-current-profile-scroll'),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.ensureVisible(_key(entry.key));
          await tester.pumpAndSettle();
          await tester.tap(_key(entry.key));
          await tester.pumpAndSettle();
          expect(actions.last, entry.value);
        }
        expect(actions, keyToAction.values);
        await tester.ensureVisible(_key('switch-account-button'));
        await tester.pumpAndSettle();
        await tester.tap(_key('switch-account-button'));
        expect(switches, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final viewport in const [
    (size: Size(393, 852), scale: 1.0),
    (size: Size(320, 568), scale: 2.0),
  ]) {
    testWidgets(
      'Profile Unlocks word, row and chevron share one action and retain balances at ${viewport.size.width}/${viewport.scale}',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final actions = <ZyraConceptAccountAction>[];
          await _mount(
            tester,
            ZyraConceptProfilePresentation(
              data: _namedAccount(
                'Adam Khan',
                standardUnlocks: 2,
                plusUnlocks: 3,
              ),
              onAction: actions.add,
              onSwitchRole: () {},
            ),
            size: viewport.size,
            scale: viewport.scale,
          );
          final control = _key('concept_compatibility_buy_more');
          final scrollable = find.descendant(
            of: _key('concept-current-profile-scroll'),
            matching: find.byType(Scrollable),
          );
          await tester.scrollUntilVisible(
            _key('concept_manage_photos'),
            180,
            scrollable: scrollable,
          );
          await tester.pumpAndSettle();
          final profileArrow = tester.widget<Icon>(
            find.descendant(
              of: _key('concept_manage_photos'),
              matching: find.byIcon(Icons.chevron_right_rounded),
            ),
          );
          final profileArrowRight = tester
              .getRect(
                find.descendant(
                  of: _key('concept_manage_photos'),
                  matching: find.byIcon(Icons.chevron_right_rounded),
                ),
              )
              .right;
          await tester.scrollUntilVisible(
            control,
            -180,
            scrollable: scrollable,
          );
          await tester.ensureVisible(control);
          await tester.pumpAndSettle();
          expect(control.hitTestable(), findsOneWidget);
          final arrowFinder = find.descendant(
            of: control,
            matching: find.byIcon(Icons.chevron_right_rounded),
          );
          final arrow = tester.widget<Icon>(arrowFinder);
          expect(arrow.icon, profileArrow.icon);
          expect(arrow.size, profileArrow.size);
          expect(arrow.color, profileArrow.color);
          expect(
            tester.getRect(arrowFinder).right,
            closeTo(profileArrowRight, 0.01),
          );
          final targetSize = tester.getSize(control);
          expect(targetSize.width, greaterThanOrEqualTo(44));
          expect(targetSize.height, greaterThanOrEqualTo(44));
          expect(find.text('Buy more'), findsNothing);
          expect(find.text('3 left · 3 more each month'), findsOneWidget);
          expect(find.textContaining('Earlier overall credits'), findsNothing);
          expect(
            _hasNamedTap(tester.getSemantics(control), 'Compatibility Unlocks'),
            isTrue,
            reason:
                'The merged row must expose its action label and current balance.',
          );
          final accessible = tester.getSemantics(control);
          expect(_tapActions(accessible), 1);
          expect(
            accessible.getSemanticsData().label,
            contains('3 left · 3 more each month'),
          );
          expect(actions, isEmpty);
          final label = find.descendant(
            of: control,
            matching: find.text('Compatibility Unlocks'),
          );
          await tester.tap(label);
          await tester.pumpAndSettle();
          expect(actions, [ZyraConceptAccountAction.compatibilityStore]);
          await tester.tap(arrowFinder);
          await tester.pumpAndSettle();
          expect(actions, [
            ZyraConceptAccountAction.compatibilityStore,
            ZyraConceptAccountAction.compatibilityStore,
          ]);
          final rowRect = tester.getRect(control);
          await tester.tapAt(rowRect.topLeft + const Offset(2, 2));
          await tester.pumpAndSettle();
          expect(
            actions,
            List.filled(3, ZyraConceptAccountAction.compatibilityStore),
            reason: 'Each physical word, arrow or padding tap dispatches once.',
          );
          expect(find.text('3 left · 3 more each month'), findsOneWidget);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  for (final guardian in [false, true]) {
    for (final viewport in const [
      (size: Size(393, 852), scale: 1.0),
      (size: Size(320, 568), scale: 2.0),
    ]) {
      testWidgets(
        '${guardian ? 'Guardian' : 'Seeker'} Profile chevrons use one size and tone at ${viewport.size.width}/${viewport.scale}',
        (tester) async {
          final originalPalette = ZyraColors.devPalette;
          addTearDown(() => ZyraColors.selectDevPalette(originalPalette));
          for (final palette in [ZyraDevPalette.midnightPlum]) {
            ZyraColors.selectDevPalette(palette);
            await _mount(
              tester,
              ZyraConceptProfilePresentation(
                data: guardian ? _guardian : _account,
                onAction: (_) => fail('Style inspection is not navigation.'),
                onSwitchRole: () => fail('Style inspection is not switching.'),
              ),
              size: viewport.size,
              scale: viewport.scale,
            );
            final scrollable = find.descendant(
              of: _key('concept-current-profile-scroll'),
              matching: find.byType(Scrollable),
            );
            tester.state<ScrollableState>(scrollable).position.jumpTo(0);
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              _key('concept_subscriptions'),
              180,
              scrollable: scrollable,
            );
            await tester.pumpAndSettle();
            final reference = find.descendant(
              of: _key('concept_subscriptions'),
              matching: find.byIcon(Icons.chevron_right_rounded),
            );
            final expected = tester.widget<Icon>(reference);
            final expectedRight = tester.getRect(reference).right;
            expect(expected.size, 18);
            expect(expected.color, ZyraColors.ink(.28));
            for (final row in [
              'concept_membership',
              'concept_subscriptions',
              if (!guardian) ...[
                'concept_compatibility_buy_more',
                'concept_manage_photos',
              ],
            ]) {
              await tester.scrollUntilVisible(
                _key(row),
                row == 'concept_membership' ? -180 : 180,
                scrollable: scrollable,
              );
              await tester.ensureVisible(_key(row));
              await tester.pumpAndSettle();
              final arrow = find.descendant(
                of: _key(row),
                matching: find.byIcon(Icons.chevron_right_rounded),
              );
              expect(arrow, findsOneWidget);
              final icon = tester.widget<Icon>(arrow);
              expect(icon.size, expected.size, reason: row);
              expect(icon.color, expected.color, reason: row);
              expect(
                tester.getRect(arrow).right,
                closeTo(expectedRight, .01),
                reason: row,
              );
            }
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets(
    'Profile Unlocks unknown and zero balances stay distinct and accessible',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final actions = <ZyraConceptAccountAction>[];
      try {
        for (final balance in <int?>[null, 0]) {
          await _mount(
            tester,
            ZyraConceptProfilePresentation(
              data: _namedAccount('Adam Khan', plusUnlocks: balance),
              onAction: actions.add,
              onSwitchRole: () {},
            ),
            size: const Size(393, 852),
          );
          final control = _key('concept_compatibility_buy_more');
          await tester.ensureVisible(control);
          await tester.pumpAndSettle();
          final copy = '${balance?.toString() ?? '—'} left · 3 more each month';
          expect(find.text(copy, findRichText: true), findsOneWidget);
          expect(find.textContaining('Earlier overall credits'), findsNothing);
          final node = tester.getSemantics(control);
          expect(_hasNamedTap(node, 'Compatibility Unlocks'), isTrue);
          expect(node.getSemanticsData().label, contains(copy));
          expect(_tapActions(node), 1);
          await tester.tap(find.text('Compatibility Unlocks'));
          await tester.pumpAndSettle();
          expect(actions.length, balance == null ? 1 : 2);
          expect(actions.last, ZyraConceptAccountAction.compatibilityStore);
          expect(find.text(copy, findRichText: true), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final guardian in [false, true]) {
    for (final sample in const [
      (name: 'Adam Khan', size: Size(440, 932), scale: 1.0, inline: true),
      (
        name: 'Muhammad Ibrahim',
        size: Size(430, 932),
        scale: 1.0,
        inline: true,
      ),
      (
        name: 'Abdulrahman Muhammad Khan',
        size: Size(393, 852),
        scale: 1.0,
        inline: false,
      ),
      (
        name: 'Abdulrahman Muhammad Khan',
        size: Size(320, 568),
        scale: 2.0,
        inline: false,
      ),
      (
        name: 'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ',
        size: Size(320, 568),
        scale: 2.0,
        inline: false,
      ),
    ]) {
      testWidgets(
        '${guardian ? 'Guardian' : 'Seeker'} Profile full name stays clear of Switch at ${sample.size.width}/${sample.scale}/${sample.name}',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            final oldFamily = ZyraText.testReadingFontFamily;
            ZyraText.testReadingFontFamily = 'Ahem';
            addTearDown(() => ZyraText.testReadingFontFamily = oldFamily);
            var switches = 0;
            await _mount(
              tester,
              ZyraConceptProfilePresentation(
                data: _namedAccount(sample.name, guardian: guardian),
                onAction: (_) =>
                    fail('A name or Switch cannot open an account action.'),
                onSwitchRole: () => switches++,
              ),
              size: sample.size,
              scale: sample.scale,
            );
            final name = _key('concept_profile_name');
            final switchButton = _key('switch-account-button');
            final text = tester.widget<Text>(name);
            expect(text.data, sample.name);
            expect(text.style?.fontSize, 28);
            expect(text.textAlign, TextAlign.center);
            expect(text.softWrap, isNot(false));
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(of: name, matching: find.byType(RichText)),
            );
            expect(paragraph.didExceedMaxLines, isFalse);
            final nameRect = tester.getRect(name);
            final switchRect = tester.getRect(switchButton);
            expect(nameRect.overlaps(switchRect), isFalse);
            expect(nameRect.left, greaterThanOrEqualTo(22));
            expect(nameRect.right, lessThanOrEqualTo(sample.size.width - 22));
            expect(switchRect.width, greaterThanOrEqualTo(44));
            expect(switchRect.height, greaterThanOrEqualTo(44));
            expect(text.maxLines, isNull);
            expect(nameRect.bottom, lessThanOrEqualTo(switchRect.top));
            final accessible = tester.getSemantics(name).getSemanticsData();
            expect(accessible.label, contains(sample.name));
            await _purePress(tester, 'switch-account-button');
            expect(switches, 1);
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  for (final guardian in [false, true]) {
    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} Settings keeps the actual category and row wording',
      (tester) async {
        final network = _NoNetwork();
        await HttpOverrides.runWithHttpOverrides(() async {
          final actions = <ZyraConceptAccountAction>[];
          await _mount(
            tester,
            ZyraConceptSettingsPresentation(
              data: guardian ? _guardian : _account,
              onAction: actions.add,
              onBack: () {},
            ),
          );
          await _expectCopy(tester, 'concept-current-settings-scroll', [
            'ACCOUNT',
            'Sign-in & security',
            'App lock',
            'Advanced',
            'PRIVACY',
            'Pause My Profile',
            if (!guardian) 'Hidden Profiles',
            'NOTIFICATIONS',
            'Notifications & emails',
            'MEMBERSHIP',
            'SUPPORT',
            'Help & support',
            'Send feedback',
            'LEGAL',
            'Privacy & data',
          ]);
          expect(find.text('CONCEPT'), findsNothing);
          expect(
            find.text('Familiar controls, safely local to this concept.'),
            findsNothing,
          );
          expect(find.text('Personalisation'), findsNothing);
          await tester.ensureVisible(
            _key('concept_settings_notificationSettings'),
          );
          await tester.pumpAndSettle();
          await tester.tap(_key('concept_settings_notificationSettings'));
          expect(actions, [ZyraConceptAccountAction.notificationSettings]);
          expect(tester.takeException(), isNull);
        }, network);
        expect(network.attempts, 0);
      },
    );
  }

  testWidgets('Personalisation keeps exact current pretexts, Poppins and Syne', (
    tester,
  ) async {
    final actions = <ZyraConceptAccountAction>[];
    final goldChanges = <bool>[];
    const snapshot = ZyraPersonalisationSnapshot(
      palette: ZyraDevPalette.ivory,
      hapticLevel: ZyraHapticLevel.subtle,
      goldEnabled: false,
    );
    await _mount(
      tester,
      ZyraPersonalisationContent(
        snapshot: snapshot,
        onChooseHaptic: () => actions.add(ZyraConceptAccountAction.haptics),
        onGoldChanged: goldChanges.add,
      ),
    );
    await _expectCopy(tester, 'personalisation-scroll', [
      'MAKE IT YOURS',
      'Choose how ZYRA looks and responds.',
      'Your choices apply across the app on this device. They never change your profile or account.',
      'LIVE PREVIEW',
      'ZYRA',
      'Connecting Through Trust',
      'Your background changes appear immediately.',
      'YOUR EXPERIENCE',
      'Gold accents',
      'Subtle gold details; motion follows your device settings.',
      'App text',
      'Poppins',
      'ZYRA uses a separate wordmark font.',
      'Haptic feel',
      'Subtle',
      'Choose how taps feel on this device.',
    ]);
    expect(tester.widget<Text>(find.text('ZYRA')).style!.fontFamily, 'Syne');
    expect(
      tester
          .widget<Text>(find.text('Connecting Through Trust'))
          .style!
          .fontFamily,
      'Poppins',
    );
    expect(
      tester
          .widget<Text>(find.text('Choose how ZYRA looks and responds.'))
          .style,
      ZyraText.heading(size: 23),
    );
    expect(find.text('LIVE PREVIEW · CONCEPT'), findsNothing);
    expect(
      find.text('Your current app’s saved choices are untouched.'),
      findsNothing,
    );
    for (final key in [
      'personalisation_haptic',
      'personalisation_gold_toggle',
    ]) {
      await tester.ensureVisible(_key(key));
      await tester.pumpAndSettle();
      await tester.tap(_key(key));
      await tester.pumpAndSettle();
    }
    expect(_key('personalisation_background'), findsNothing);
    expect(find.text('Background'), findsNothing);
    expect(actions, [ZyraConceptAccountAction.haptics]);
    expect(goldChanges, [true]);
    expect(
      snapshot.goldEnabled,
      isFalse,
      reason: 'Callbacks never mutate their supplied snapshot.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Membership has Current controls, inline Unlocks and separate Peek plan sections',
    (tester) async {
      final network = _NoNetwork();
      await HttpOverrides.runWithHttpOverrides(() async {
        await _mount(
          tester,
          ZyraConceptMembershipPresentation(
            data: _account,
            initialDraft: ZyraMembershipDraft(
              section: ZyraMembershipSection.current,
            ),
            unlocksContent: const ZyraDraftCompatibilityStorePresentation(
              balance: 1,
            ),
            onAction: (_) {},
            onDraftChanged: (_) {},
            onReview: (_) {},
            onBack: () {},
          ),
        );
        expect(find.byType(ZyraMembershipChoices), findsOneWidget);
        expect(find.text('Membership'), findsOneWidget);
        expect(_key('membership-current'), findsOneWidget);
        expect(_key('concept_cancel_membership').hitTestable(), findsOneWidget);
        expect(_key('membership-halo-seekerOne'), findsNothing);
        expect(_key('membership-review-selection'), findsNothing);
        expect(find.byIcon(Icons.shopping_bag_outlined), findsNothing);
        expect(_key('membership-section-slider'), findsOneWidget);
        await tester.ensureVisible(_key('membership-section-seeker'));
        await tester.pumpAndSettle();
        expect(_key('membership-section-seeker').hitTestable(), findsOneWidget);
        await tester.tap(_key('membership-section-seeker'));
        await tester.pumpAndSettle();
        expect(_key('membership-halo-seekerOne'), findsOneWidget);
        expect(find.text('1 / 2'), findsOneWidget);
        expect(_key('membership-current'), findsNothing);
        expect(_key('concept_cancel_membership'), findsNothing);
        final familyPill = _key('membership-section-family');
        await Scrollable.ensureVisible(tester.element(familyPill));
        await tester.pumpAndSettle();
        await tester.tap(familyPill);
        await tester.pumpAndSettle();
        expect(find.byType(PageView), findsNothing);
        expect(_key('membership-family-total'), findsOneWidget);
        expect(find.text('Monthly total'), findsOneWidget);
        expect(find.text('0% saving'), findsOneWidget);
        expect(find.text('Review selection'), findsOneWidget);
        await tester.ensureVisible(_key('membership-section-unlocks'));
        await tester.pumpAndSettle();
        await tester.tap(_key('membership-section-unlocks'));
        await tester.pumpAndSettle();
        expect(
          find.byType(ZyraDraftCompatibilityStorePresentation),
          findsOneWidget,
        );
        expect(_key('membership-current'), findsNothing);
        expect(_key('membership-review-selection'), findsNothing);
        expect(_key('concept_cancel_membership'), findsNothing);
        expect(_key('concept_compatibility'), findsNothing);
        await tester.ensureVisible(_key('membership-terms'));
        await tester.pumpAndSettle();
        await tester.tap(_key('membership-terms'));
        await tester.pumpAndSettle();
        expect(find.byType(ZyraMembershipTermsSheet), findsOneWidget);
        expect(find.text('Membership terms'), findsOneWidget);
        expect(find.textContaining('Blocking, reporting'), findsOneWidget);
        final close = find.widgetWithText(TextButton, 'Close');
        await tester.ensureVisible(close);
        await tester.pumpAndSettle();
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(find.text('CONCEPT SELECTION'), findsNothing);
        expect(tester.takeException(), isNull);
      }, network);
      expect(network.attempts, 0);
    },
  );

  for (final stage in ZyraJourneyStages.all) {
    testWidgets('current ${stage.value} arrival keeps canonical copy', (
      tester,
    ) async {
      await _mount(
        tester,
        ZyraConceptJourneyArrival(stage: stage, onContinue: () {}),
      );
      expect(
        find.text('STAGE ${stage.order} OF ${ZyraJourneyStages.count}'),
        findsOneWidget,
      );
      expect(find.text(stage.arrivalTitle ?? stage.label), findsOneWidget);
      expect(find.text(stage.introduction), findsOneWidget);
      final secondary = stage.guidingQuestion ?? stage.supportingLine;
      if (secondary != null) expect(find.text(secondary), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(stage.arrivalTitle ?? stage.label)).style,
        ZyraText.heading(size: 25),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('current Journey frame pages without completing a stage', (
    tester,
  ) async {
    final stage = ValueNotifier(ZyraJourneyStages.all.first);
    addTearDown(stage.dispose);
    final visible = <bool>[];
    var commits = 0;
    await _mount(
      tester,
      ValueListenableBuilder<ZyraJourneyStage>(
        valueListenable: stage,
        builder: (context, current, _) => ZyraConceptJourneyPresentation(
          firstName: 'Sara',
          stage: current,
          localActionBody: Center(
            child: TextButton(
              key: const ValueKey('local-stage-action'),
              onPressed: () => commits++,
              child: const Text('Deliberate local action'),
            ),
          ),
          onBack: () {},
          onTimeline: () {},
          onActionVisibilityChanged: visible.add,
        ),
      ),
      size: const Size(390, 844),
    );
    expect(find.text('Journey with Sara'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Journey with Sara')).style,
      ZyraText.heading(size: 16),
    );
    final pages = tester.widget<PageView>(
      _key('concept_current_journey_pages'),
    );
    expect(pages.scrollDirection, Axis.vertical);
    expect(
      tester
          .widget<InkResponse>(
            _key('concept_journey_stage_compatibility_reveal'),
          )
          .onTap,
      isNull,
    );
    await tester.tap(_key('concept_journey_arrival_continue'));
    await tester.pumpAndSettle();
    expect(visible.last, isTrue);
    expect(_key('local-stage-action').hitTestable(), findsOneWidget);
    expect(commits, 0);
    expect(stage.value.value, 'salam_exchange');
    await tester.drag(
      _key('concept_current_journey_pages'),
      const Offset(0, 600),
    );
    await tester.pumpAndSettle();
    expect(visible.last, isFalse);
    expect(commits, 0);
    expect(stage.value.value, 'salam_exchange');
    // Repeated actual gesture handoff must not leave a committed pull latch.
    for (var repeat = 0; repeat < 2; repeat++) {
      await tester.drag(
        _key('concept_current_journey_pages'),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      expect(visible.last, isTrue);
      expect(_key('local-stage-action').hitTestable(), findsOneWidget);
      await tester.drag(
        _key('concept_current_journey_pages'),
        const Offset(0, 600),
      );
      await tester.pumpAndSettle();
      expect(visible.last, isFalse);
      expect(commits, 0);
      expect(stage.value.value, 'salam_exchange');
    }
    // A caller-supplied genuine local transition must replace the frame
    // without borrowing the outgoing stage's GlobalKey.
    stage.value = ZyraJourneyStages.all[1];
    await tester.pumpAndSettle();
    expect(find.text('2 · Compatibility Reveal'), findsOneWidget);
    expect(
      find.text('Now, choose whether to reveal your compatibility.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
