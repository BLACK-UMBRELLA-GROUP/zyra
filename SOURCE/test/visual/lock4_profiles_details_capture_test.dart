// LOCK 4 captures use the admitted sample shell and its shared presentation.
// No-photo is a bounded data fixture: the real editor retains the last photo.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_profile_details_page.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'baseline_capture_support.dart';

const _enabled = bool.fromEnvironment('ZYRA_LOCK4_CAPTURE');
const _output =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/PRODUCT/APPROVED/PROFILES_DETAILS_CARD/BUILT';
const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/LOCK4_PROFILES_DETAILS_CARD_2026-10-29';
const _sara = 'draft-sara';

Map<String, double> _rect(Rect value) => {
  'left': value.left,
  'top': value.top,
  'right': value.right,
  'bottom': value.bottom,
  'width': value.width,
  'height': value.height,
};

Future<Map<String, Object?>> _geometry(
  WidgetTester tester,
  String state, {
  required String reached,
  required bool hasPhoto,
}) async {
  final outer = find.byKey(
    const ValueKey('concept_browse_details_avatar_$_sara'),
  );
  final clip = find.byKey(
    const ValueKey('concept_browse_details_avatar_photo_$_sara'),
  );
  expect(outer, findsOneWidget);
  expect(tester.getSize(outer), const Size(56, 56));
  if (hasPhoto) {
    expect(clip, findsOneWidget);
    expect(tester.getSize(clip), const Size(50, 50));
  } else {
    expect(clip, findsNothing);
    expect(
      find.descendant(of: outer, matching: find.byIcon(Icons.person_outline)),
      findsOneWidget,
    );
  }
  final file = File('$_output/profiles_tab__$state.png');
  final bytes = await tester.runAsync(file.readAsBytes);
  expect(bytes, isNotNull);
  return {
    'file': file.path,
    'reached': reached,
    'logical_size': [430, 932],
    'device_pixel_ratio': 3,
    'png_size': [1290, 2796],
    'avatar_outer_rect_logical': _rect(tester.getRect(outer)),
    'photo_clip_rect_logical': hasPhoto ? _rect(tester.getRect(clip)) : null,
    'bytes': bytes!.length,
    'sha256': sha256.convert(bytes).toString(),
  };
}

SeekerProfile _withoutPhotos(SeekerProfile person) => SeekerProfile(
  id: person.id,
  firstName: person.firstName,
  surnameLine: person.surnameLine,
  age: person.age,
  city: person.city,
  gender: person.gender,
  publicNationality: person.publicNationality,
  publicEthnicity: person.publicEthnicity,
  videoPhotoIndex: person.videoPhotoIndex,
  alreadyLikedYou: person.alreadyLikedYou,
  photos: const [],
);

void main() {
  setUpAll(baselineSetUp);
  tearDownAll(baselineTearDown);

  testWidgets(
    'LOCK 4 actual photo and bounded no-photo Profiles states',
    (tester) async {
      final h = BaselineHarness(
        tester,
        group: 'lock4_profiles_details',
        outputRoot: _output,
        evidenceRoot: _evidence,
        flatOutput: true,
      );
      await h.mount();
      expect(h.latest.tab, 0);
      expect(h.latest.pages, isEmpty);
      final details = tester.widget<ZyraProfileDetailsPage>(
        find.byType(ZyraProfileDetailsPage),
      );
      expect(details.profile.id, _sara);
      expect(details.profile.photos, isNotEmpty);
      expect(details.firstPhoto, isNotNull);
      await h.capture(
        'browse_and_requests',
        'profiles_tab',
        'details_card_photo',
        'Actual default Founder preview Profiles tab, Sara details page; caller-prepared first sample photo',
      );
      final evidence = <Map<String, Object?>>[
        await _geometry(
          tester,
          'details_card_photo',
          hasPhoto: true,
          reached: 'Actual default Founder preview shell, unchanged state',
        ),
      ];

      // Snapshot actual product configuration before replacing the owner.
      // The fixture changes only the selected person's available photos.
      final source = tester.widget<ZyraBrowseDesigns>(
        find.byType(ZyraBrowseDesigns),
      );
      final nav = tester.widget<ZyraShellNavigation>(
        find.byType(ZyraShellNavigation),
      );
      final shell = tester.widget<Scaffold>(find.byType(Scaffold));
      final background = shell.body! as DecoratedBox;
      final person = source.profiles[source.selectedIndex];
      expect(person.id, _sara);
      final missing = _withoutPhotos(person);
      final label = source.requestLabel?.call(person);
      final sent = source.invitationSent?.call(person);
      final canRequest = source.canRequest?.call(person) ?? true;
      final checkpoint = h.latest;
      final fixture = ZyraBrowseDesigns(
        profiles: [missing],
        selectedIndex: 0,
        design: source.design,
        photoBuilder:
            (_, _, {required width, required height, required alignment}) =>
                throw StateError('An absent photo must not invoke a renderer.'),
        readOnlyPreview: source.readOnlyPreview,
        showFeedChrome: source.showFeedChrome,
        bottomPadding: source.bottomPadding,
        alignHeaderActions: source.alignHeaderActions,
        nextProfileMotion: source.nextProfileMotion,
        nextProfileMotionEpoch: source.nextProfileMotionEpoch,
        hapticLevel: source.hapticLevel,
        initialPhotoIndices: source.initialPhotoIndices,
        initialGalleryIndices: source.initialGalleryIndices,
        onPrevious: source.onPrevious == null ? null : () {},
        onNext: source.onNext == null ? null : () {},
        onFilters: source.onFilters == null ? null : () {},
        onBrowseMenu: source.onBrowseMenu == null ? null : (_) {},
        onProfile: source.onProfile == null ? null : (_) {},
        onRequest: source.onRequest == null ? null : (_) {},
        requestLabel: label == null ? null : (_) => label,
        invitationSent: sent == null ? null : (_) => sent,
        canRequest: (_) => canRequest,
      );
      await h.mountPresentation(
        checkpoint: checkpoint,
        child: Scaffold(
          backgroundColor: shell.backgroundColor,
          extendBody: shell.extendBody,
          body: DecoratedBox(
            decoration: background.decoration,
            child: Stack(
              fit: StackFit.expand,
              children: [
                fixture,
                ZyraShellNavigation(
                  items: nav.items,
                  currentIndex: nav.currentIndex,
                  onTap: (_) {},
                  commitOnRelease: nav.commitOnRelease,
                  contentEdgeInset: nav.contentEdgeInset,
                  hapticLevel: nav.hapticLevel,
                ),
              ],
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<ZyraProfileDetailsPage>(find.byType(ZyraProfileDetailsPage))
            .firstPhoto,
        isNull,
      );
      await h.capture(
        'browse_and_requests',
        'profiles_tab',
        'details_card_no_photo',
        'Bounded actual shared Profiles presenter with Sara photos=[]; actual mounted shell nav/palette/configuration; production frame; editor cannot remove last photo',
      );
      evidence.add(
        await _geometry(
          tester,
          'details_card_no_photo',
          hasPhoto: false,
          reached:
              'Bounded unavailable-photo data fixture, not a missing-photo shell UI route',
        ),
      );
      await tester.runAsync(() async {
        final file = File('$_evidence/avatar_geometry.json');
        await file.parent.create(recursive: true);
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(evidence),
          flush: true,
        );
      });
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
