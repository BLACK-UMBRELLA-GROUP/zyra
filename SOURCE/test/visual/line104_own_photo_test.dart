import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_journey_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_monogram_presentation.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/widgets/zyra_seeker_avatar.dart';

import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const _evidence = '../REPORTS/EVIDENCE/LINE104_2026-11-12';
const _capture = bool.fromEnvironment('ZYRA_LINE104_CAPTURE');
const _profileHeader = 'concept_profile_avatar';
const _seekerRow = 'circle_topics_member_draft-self';
const _guardianRow = 'circle_topics_member_draft-guardian-hassan';

Future<String> _bundledPhoto(String file) async {
  final data = await rootBundle.load('assets/dev/one_journey_photos/$file.jpg');
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  return 'data:image/jpeg;base64,${base64Encode(bytes)}';
}

class _OwnerSurfaces {
  _OwnerSurfaces(this.t)
    : h = BaselineHarness(
        t,
        group: 'line104_after',
        outputRoot: _evidence,
        evidenceRoot: _evidence,
        flatOutput: true,
      ) {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  final WidgetTester t;
  final BaselineHarness h;

  Future<void> mount({required List<String> photos}) async {
    final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(1);
    await h.mount(
      seekerPhotos: photos,
      checkpoint: ZyraPreviewNavigationCheckpoint(
        guardian: false,
        model: model.snapshot(),
        tab: 4,
        pages: const [],
        guardianHistory: const {'draft-guardian-hassan': true},
      ),
    );
  }

  Finder avatarUnder(Finder parent) =>
      find.descendant(of: parent, matching: find.byType(ZyraSeekerAvatar));

  void expectAvatar(Finder avatar, String? photo) {
    expect(avatar, findsOneWidget);
    final widget = t.widget<ZyraSeekerAvatar>(avatar);
    expect(widget.photo ?? '', photo ?? '');
    expect(t.getSize(avatar).width, t.getSize(avatar).height);
    if (photo == null) {
      expect(
        find.descendant(of: avatar, matching: find.byIcon(Icons.person)),
        findsOneWidget,
      );
    }
  }

  Future<void> save(String name, String route) async {
    if (!_capture) return;
    await h.capture(
      'avatar',
      name,
      'after',
      route,
      fileName: 'after_$name.png',
    );
  }

  Future<void> back() async {
    await returnZyraPreviewPage(t);
    await h.flush();
  }

  Future<void> tab(int index) => h.tap('floating-nav-item-$index');

  Future<void> profile(String? photo, {String? capture}) async {
    await tab(4);
    expectAvatar(avatarUnder(h.key(_profileHeader)), photo);
    if (capture != null) await save(capture, 'Seeker Profile tab');
  }

  Future<void> ownPreview(String? photo) async {
    await h.tap('concept_preview_profile');
    h.assertPage('own_profile_preview');
    expectAvatar(avatarUnder(h.key('my-profile-browse-preview')), photo);
    await back();
  }

  Future<void> circle(
    String? photo, {
    bool guardian = false,
    String? capture,
  }) async {
    await tab(3);
    if (guardian) await h.tap('guardian_seeker_0');
    await h.tap(guardian ? 'guardian_circle' : 'guardian-family-messages-top');
    h.assertPage('guardian_circle');
    await h.tap('circle_topics_menu');
    final seeker = h.key(_seekerRow);
    final guardianMember = h.key(_guardianRow);
    expect(
      find.descendant(
        of: seeker,
        matching: find.text(guardian ? 'Adam' : 'You'),
      ),
      findsOneWidget,
    );
    expectAvatar(avatarUnder(seeker), photo);
    expect(avatarUnder(guardianMember), findsNothing);
    final monogram = find.descendant(
      of: guardianMember,
      matching: find.byType(ZyraGoldRingMonogram),
    );
    expect(monogram, findsOneWidget);
    expect(t.widget<ZyraGoldRingMonogram>(monogram).guardianOne, isTrue);
    if (capture != null) await save(capture, 'Guardian Circle menu');
    await h.tap('circle_topics_done');
    await back();
    if (guardian) await back();
  }

  Future<void> journey(String? photo) async {
    await tab(1);
    await h.tap('journey_tab_continue');
    final arrival = h.key('concept_journey_arrival_continue');
    if (arrival.evaluate().isNotEmpty) await h.tapFinder(arrival);
    final threshold = find.byType(ZyraConceptJourneyThresholdBody);
    expect(threshold, findsOneWidget);
    final own = find.descendant(
      of: threshold,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label?.startsWith('You, ') == true,
      ),
    );
    expectAvatar(avatarUnder(own), photo);
    await back();
  }

  Future<void> promoteSecondPhoto() async {
    await tab(4);
    await h.tapText('Manage photos');
    h.assertPage('manage_photos');
    await h.tap('photos-compact-toggle');
    await h.tap('compact-photo-1');
    await h.tapText('Make main photo');
    await back();
  }

  Future<void> guardianRoster(String? photo) async {
    await tab(3);
    expectAvatar(avatarUnder(h.key('guardian_seeker_0')), photo);
    expectAvatar(avatarUnder(h.key('guardian_seeker_1')), null);
    await h.tap('guardian_seeker_0');
    h.assertPage('guardian_seeker');
    expectAvatar(find.byType(ZyraSeekerAvatar), photo);
    await back();
  }

  Future<void> switchRole({required bool guardian}) async {
    await tab(4);
    await h.tap('switch-account-button');
    await h.tap(guardian ? 'wallet_primary_guardian' : 'wallet_primary_seeker');
    expect(h.latest.guardian, guardian);
  }

  Future<void> guardianHeader({String? capture}) async {
    await tab(4);
    final header = h.key(_profileHeader);
    expect(header, findsOneWidget);
    expect(avatarUnder(header), findsNothing);
    expect(
      find.descendant(of: header, matching: find.text('H')),
      findsOneWidget,
    );
    if (capture != null) await save(capture, 'Guardian Profile tab');
  }
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _capture ? _evidence : null));
  tearDownAll(baselineTearDown);

  testWidgets(
    'empty photo one uses the shared placeholder on Seeker and Guardian routes',
    (t) async {
      final owner = _OwnerSurfaces(t);
      await owner.mount(photos: []);
      await owner.profile(null, capture: 'seeker_profile_empty');
      await owner.ownPreview(null);
      await owner.journey(null);
      await owner.circle(null, capture: 'seeker_circle_menu_empty');
      await owner.switchRole(guardian: true);
      await owner.guardianHeader();
      await owner.guardianRoster(null);
      await owner.circle(
        null,
        guardian: true,
        capture: 'guardian_circle_menu_empty',
      );
    },
  );

  testWidgets(
    'promoting photo two updates photo one across the same Founder session',
    (t) async {
      final photos = (await t.runAsync(
        () async => [
          await _bundledPhoto('seeker_self'),
          await _bundledPhoto('zyra1a'),
        ],
      ))!;
      final owner = _OwnerSurfaces(t);
      await owner.mount(photos: photos);
      await owner.profile(photos.first);
      await owner.ownPreview(photos.first);
      await owner.journey(photos.first);
      await owner.circle(photos.first);
      await owner.switchRole(guardian: true);
      await owner.guardianRoster(photos.first);
      await owner.circle(photos.first, guardian: true);
      await owner.switchRole(guardian: false);
      await owner.promoteSecondPhoto();
      await owner.profile(photos.last);
      await owner.ownPreview(photos.last);
      await owner.journey(photos.last);
      await owner.circle(photos.last);
      await owner.switchRole(guardian: true);
      await owner.guardianHeader();
      await owner.guardianRoster(photos.last);
      await owner.circle(
        photos.last,
        guardian: true,
        capture: 'guardian_circle_menu_updated',
      );
    },
  );

  if (_capture) {
    testWidgets('captures the same four states as the pre-change tree', (
      t,
    ) async {
      final owner = _OwnerSurfaces(t);
      final h = owner.h;
      final sample = await t.runAsync(() => _bundledPhoto('seeker_self'));
      await h.mount(tab: 4);
      await owner.profile(sample, capture: 'seeker_profile');
      await h.mount(tab: 4, guardian: true);
      await owner.guardianHeader(capture: 'guardian_profile');
      for (final guardian in [false, true]) {
        await h.mount(
          guardian: guardian,
          checkpoint: ZyraPreviewNavigationCheckpoint(
            guardian: guardian,
            model: ViewRequestDraftModel(capacity: 3).snapshot(),
            tab: 3,
            pages: const ['guardian_circle'],
            guardianHistory: const {'draft-guardian-hassan': true},
          ),
        );
        await h.tap('circle_topics_menu');
        owner.expectAvatar(owner.avatarUnder(h.key(_seekerRow)), sample);
        final role = guardian ? 'guardian' : 'seeker';
        await owner.save('${role}_circle_menu', 'Guardian Circle menu');
      }
    });
  }
}
