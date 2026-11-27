// Q240: current actual Profiles shell and a photos=[] data fixture, with the
// same production card configuration, shell navigation, theme, and palette.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';
import 'package:zyra/widgets/zyra_profile_details_page.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'baseline_capture_support.dart';

const _output = String.fromEnvironment('ZYRA_LINE141_DETAILS_REVIEW_DIR');

SeekerProfile _withoutPhotos(SeekerProfile person) => SeekerProfile(
  id: person.id,
  firstName: person.firstName,
  surnameLine: person.surnameLine,
  age: person.age,
  city: person.city,
  gender: person.gender,
  publicNationality: person.publicNationality,
  publicEthnicity: person.publicEthnicity,
  seekerPlan: person.seekerPlan,
  mainGuardianRelationship: person.mainGuardianRelationship,
  videoPhotoIndex: person.videoPhotoIndex,
  alreadyLikedYou: person.alreadyLikedYou,
  photos: const [],
);

Map<String, double> _rect(Rect rect) => {
  'left': rect.left,
  'top': rect.top,
  'right': rect.right,
  'bottom': rect.bottom,
  'width': rect.width,
  'height': rect.height,
};

Map<String, Object?> _geometry(WidgetTester tester, String state) {
  final page = find.byType(ZyraProfileDetailsPage);
  final details = tester.widget<ZyraProfileDetailsPage>(page);
  final person = details.profile;
  final name = find.descendant(
    of: page,
    matching: find.text(
      '${person.firstName} ${person.surnameLine ?? ''}'.trim(),
    ),
  );
  final firstTile = find.descendant(
    of: page,
    matching: find.byKey(const ValueKey('profile-detail-tile-AGE')),
  );
  final nameRect = tester.getRect(name);
  final tileRect = tester.getRect(firstTile);
  expect(tileRect.top - nameRect.bottom, greaterThanOrEqualTo(12 - .001));
  return {
    'state': state,
    'person_id': person.id,
    'logical_size': [430, 932],
    'device_pixel_ratio': 3,
    'has_photo': details.firstPhoto != null,
    'name_rect': _rect(nameRect),
    'first_tile_rect': _rect(tileRect),
    'visible_name_to_tile_gap': tileRect.top - nameRect.bottom,
    'avatar_rect': _rect(
      tester.getRect(
        find.byKey(ValueKey('concept_browse_details_avatar_${person.id}')),
      ),
    ),
  };
}

void main() {
  if (_output.isNotEmpty) {
    setUpAll(() => baselineSetUp(evidenceRoot: null));
    tearDownAll(baselineTearDown);
  }

  testWidgets(
    'Q240 actual Profiles photo and no-photo master comparison captures',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = BaselineHarness(
        tester,
        group: 'line141_details_master_review',
        outputRoot: _output,
        evidenceRoot: _output,
        flatOutput: true,
        reduceMotion: true,
      );
      await h.mount();
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pumpAndSettle();
      final details = tester.widget<ZyraProfileDetailsPage>(
        find.byType(ZyraProfileDetailsPage),
      );
      expect(details.firstPhoto, isNotNull);
      expect(find.byType(ZyraShellNavigation), findsOneWidget);
      await h.capture(
        'browse_and_requests',
        'profiles_tab',
        'details_card_photo',
        'Actual default Founder preview Profiles details page, prepared local photo and actual shell navigation; Q240 12pt gap',
      );
      final geometry = [_geometry(tester, 'details_card_photo')];

      final source = tester.widget<ZyraBrowseDesigns>(
        find.byType(ZyraBrowseDesigns),
      );
      final nav = tester.widget<ZyraShellNavigation>(
        find.byType(ZyraShellNavigation),
      );
      final shell = tester.widget<Scaffold>(find.byType(Scaffold));
      final background = shell.body! as DecoratedBox;
      final person = source.profiles[source.selectedIndex];
      final checkpoint = h.latest;
      final requestLabel = source.requestLabel?.call(person);
      final requestSemanticLabel = source.requestSemanticLabel?.call(person);
      final sent = source.invitationSent?.call(person);
      final canRequest = source.canRequest?.call(person) ?? true;
      final swipe = source.profileSwipe;
      final fixture = ZyraBrowseDesigns(
        profiles: [_withoutPhotos(person)],
        selectedIndex: 0,
        design: source.design,
        photoBuilder:
            (_, _, {required width, required height, required alignment}) =>
                throw StateError('An absent photo must not invoke a renderer.'),
        readOnlyPreview: source.readOnlyPreview,
        showFeedChrome: source.showFeedChrome,
        bottomPadding: source.bottomPadding,
        fixedTabFooter: source.fixedTabFooter,
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
        onCompatibility: source.onCompatibility == null ? null : (_) {},
        onRequest: source.onRequest == null ? null : (_) {},
        requestLabel: requestLabel == null ? null : (_) => requestLabel,
        requestSemanticLabel: requestSemanticLabel == null
            ? null
            : (_) => requestSemanticLabel,
        invitationSent: sent == null ? null : (_) => sent,
        canRequest: (_) => canRequest,
        requestRowLabels: source.requestRowLabels,
        profileSwipe: swipe == null
            ? null
            : (
                previousIndex: null,
                nextIndex: null,
                onBlockedPrevious: swipe.onBlockedPrevious == null
                    ? null
                    : () {},
                canAct: () => true,
              ),
        verifyPhotosPill: source.verifyPhotosPill,
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
                  lockedTabBar: nav.lockedTabBar,
                  interactionEnabled: nav.interactionEnabled,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ZyraProfileDetailsPage>(find.byType(ZyraProfileDetailsPage))
            .firstPhoto,
        isNull,
      );
      expect(find.byType(ZyraShellNavigation), findsOneWidget);
      await h.capture(
        'browse_and_requests',
        'profiles_tab',
        'details_card_no_photo',
        'Bounded selected-profile photos=[] fixture using the current shared production Profiles caller and captured shell/nav configuration; no product route or layout override',
      );
      geometry.add(_geometry(tester, 'details_card_no_photo'));
      await tester.runAsync(() async {
        final file = File('$_output/details_geometry.json');
        await file.parent.create(recursive: true);
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(geometry),
          flush: true,
        );
      });
    },
    skip: _output.isEmpty,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
