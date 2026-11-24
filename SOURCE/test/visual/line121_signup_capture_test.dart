// Opt-in LOCK 34 captures of real app presenters, never reference-image edits.
// The shell integration captures s30/s31 separately; this file covers the
// remaining 39 masters with the same filenames and phone dimensions.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_sample_photos.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_signup_preferences_preview.dart';
import 'package:zyra/dev/zyra_signup_preview.dart';
import 'package:zyra/dev/zyra_signup_preview_controller.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/models/zyra_error_state.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/zyra_full_screen_error.dart';

import 'baseline_capture_support.dart';

const _output = String.fromEnvironment('ZYRA_LINE121_OUTPUT');
late ZyraOneJourneySamplePhotos _photos;

typedef _Arrange = void Function(ZyraSignupPreviewController controller);

ZyraSignupPreviewController _signed({bool guardian = false}) {
  final c = ZyraSignupPreviewController(now: () => DateTime(2026, 11, 19));
  c.finishSplash();
  c.chooseProvider('Apple');
  c.setGuardian(guardian);
  return c;
}

void _dob(ZyraSignupPreviewController c, String year) {
  c.setDay('14');
  c.setMonth('03');
  c.setYear(year);
  c.setStep(ZyraSignupStep.dateOfBirth);
}

void _verified(ZyraSignupPreviewController c) {
  c.setStep(ZyraSignupStep.verify);
  c.verifyNow();
}

void _ready(ZyraSignupPreviewController c, {required bool verified}) {
  c.addPhoto(_photos.seekerPhoto);
  c.addPhoto(_photos.seekerPhoto);
  c.setStep(ZyraSignupStep.verify);
  if (verified) {
    c.verifyNow();
    if (!c.guardian) {
      c.skip();
    }
  } else {
    c.verifyLater();
    c.advance();
  }
}

ZyraPreviewNavigationCheckpoint _checkpoint(bool guardian) =>
    ZyraPreviewNavigationCheckpoint(
      guardian: guardian,
      model: ViewRequestDraftModel(capacity: 3).snapshot(),
      tab: 2,
      pages: const [],
    );

BaselineHarness _harness(WidgetTester tester) => BaselineHarness(
  tester,
  group: 'line121_signup',
  outputRoot: _output,
  evidenceRoot: _output,
  flatOutput: true,
  logicalSize: const Size(430, 932),
  devicePixelRatio: 3,
);

Future<void> _capture(BaselineHarness h, String name) => h.capture(
  'signup',
  name,
  'lock34',
  'Real LOCK 34 Founder-preview presenter with detached sample data.',
  fileName: '$name.png',
);

void main() {
  setUpAll(() async {
    if (_output.isEmpty && !baselineTextAuditOnly) {
      return;
    }
    await baselineSetUp(
      evidenceRoot: _output,
      useSystemSymbolFont: Platform.isMacOS,
    );
    _photos = await ZyraOneJourneySamplePhotos.load();
  });
  tearDownAll(() async {
    if (_output.isNotEmpty || baselineTextAuditOnly) {
      await baselineTearDown();
    }
  });

  final samples = <(String, bool, _Arrange)>[
    ('s01_splash', false, (c) => c.start()),
    (
      's02_welcome__iphone_apple_first',
      false,
      (c) => c.setStep(ZyraSignupStep.welcome),
    ),
    (
      's03_welcome__android_google_first',
      false,
      (c) => c.setStep(ZyraSignupStep.welcome),
    ),
    ('s04_role__seeker_card', false, (c) => c.setStep(ZyraSignupStep.role)),
    ('s05_role__guardian_card', true, (c) => c.setStep(ZyraSignupStep.role)),
    (
      's06_name__filled_from_apple',
      false,
      (c) => c.setStep(ZyraSignupStep.name),
    ),
    (
      's07_name__empty_error',
      false,
      (c) {
        c.setFirstName('');
        c.setSurname('');
        c.setStep(ZyraSignupStep.name);
      },
    ),
    ('s08_dob__empty', false, (c) => c.setStep(ZyraSignupStep.dateOfBirth)),
    ('s09_dob__filled', false, (c) => _dob(c, '1997')),
    ('s10_dob__year_error', false, (c) => _dob(c, '343')),
    ('s11_dob__under_18', false, (c) => _dob(c, '2012')),
    ('s12_gender__none', false, (c) => c.setStep(ZyraSignupStep.gender)),
    (
      's13_gender__male_chosen',
      false,
      (c) {
        c.setGender('male');
        c.setStep(ZyraSignupStep.gender);
      },
    ),
    ('s14_location__empty', false, (c) => c.setStep(ZyraSignupStep.location)),
    (
      's15_location__chosen',
      false,
      (c) {
        c.setLocation('London, United Kingdom');
        c.setStep(ZyraSignupStep.location);
      },
    ),
    (
      's16_nationality__chosen',
      false,
      (c) {
        c.setNationality('British');
        c.setStep(ZyraSignupStep.nationality);
      },
    ),
    (
      's17_ethnicity__several',
      false,
      (c) {
        c.toggleEthnicity('Pakistani');
        c.toggleEthnicity('British');
        c.setStep(ZyraSignupStep.ethnicity);
      },
    ),
    ('s18_ethnicity__empty', false, (c) => c.setStep(ZyraSignupStep.ethnicity)),
    ('s19_photos__empty', false, (c) => c.setStep(ZyraSignupStep.photos)),
    (
      's20_photos__two',
      false,
      (c) {
        c.addPhoto(_photos.seekerPhoto);
        c.addPhoto(_photos.seekerPhoto);
        c.setStep(ZyraSignupStep.photos);
      },
    ),
    ('s21_verify', false, (c) => c.setStep(ZyraSignupStep.verify)),
    (
      's21_verify__after_do_this_later',
      false,
      (c) {
        c.setStep(ZyraSignupStep.verify);
        c.verifyLater();
      },
    ),
    ('s22_plan__seeker_one', false, _verified),
    (
      's23_plan__seeker_basic',
      false,
      (c) {
        _verified(c);
        c.setMembershipBasic(true);
      },
    ),
    ('s24_account_ready__verified', false, (c) => _ready(c, verified: true)),
    (
      's25_account_ready__not_verified',
      false,
      (c) => _ready(c, verified: false),
    ),
    (
      's26_setup__partner_preferences_bar',
      false,
      (c) {
        c.seedSetup(guardian: false, verified: true);
        c.resumeSetup();
      },
    ),
    (
      's27_setup__about_you',
      false,
      (c) {
        c.seedSetup(guardian: false, verified: true);
        c.resumeSetup();
        c.advance();
      },
    ),
    (
      's28_setup__add_guardian',
      false,
      (c) {
        c.seedSetup(guardian: false, verified: true);
        c.resumeSetup();
        c.advance();
        c.advance();
      },
    ),
    (
      's29_setup__all_set',
      false,
      (c) {
        c.seedSetup(guardian: false, verified: true);
        c.resumeSetup();
        c.advance();
        c.advance();
        c.advance();
      },
    ),
    ('g01_guardian__name', true, (c) => c.setStep(ZyraSignupStep.name)),
    if (baselineTextAuditOnly)
      ('g01b_guardian__dob', true, (c) => _dob(c, '1997')),
    (
      'g02_guardian__relationship_empty',
      true,
      (c) => c.setStep(ZyraSignupStep.relationship),
    ),
    (
      'g03_guardian__relationship_chosen',
      true,
      (c) {
        c.setRelationship('Father');
        c.setStep(ZyraSignupStep.relationship);
      },
    ),
    (
      'g04_guardian__add_seeker',
      true,
      (c) => c.setStep(ZyraSignupStep.addSeeker),
    ),
    ('g05_guardian__verify', true, (c) => c.setStep(ZyraSignupStep.verify)),
    ('g06_guardian__account_ready', true, _verified),
    (
      'g07_guardian__setup_about_you',
      true,
      (c) {
        c.seedSetup(guardian: true, verified: true, firstName: 'Hassan');
        c.resumeSetup();
      },
    ),
    (
      'g08_guardian__setup_all_set',
      true,
      (c) {
        c.seedSetup(guardian: true, verified: true, firstName: 'Hassan');
        c.resumeSetup();
        c.advance();
      },
    ),
  ];

  for (final (name, guardian, arrange) in samples) {
    testWidgets(
      'line121 real presenter $name',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final c = _signed(guardian: guardian);
        arrange(c);
        final h = _harness(tester);
        final previousShadows = debugDisableShadows;
        debugDisableShadows = false;
        try {
          await h.mountPresentation(
            checkpoint: _checkpoint(guardian),
            child: Material(
              type: MaterialType.transparency,
              child: ZyraSignupPreview(
                controller: c,
                canAct: () => true,
                preferencesBuilder: (_) => ZyraSignupPreferencesPreview(
                  initialDraft: ZyraCompatibilityDraft.fromSnapshot(
                    gender: 'male',
                  ),
                  canAct: () => true,
                  canRetain: () => true,
                  onChanged: (_) {},
                  onNext: c.advance,
                  onLater: () {},
                  onBack: () => c.setStep(ZyraSignupStep.accountReady),
                ),
                onPause: () {},
                onEnter: () {},
                onShareCode: () {},
                samplePhotos: [_photos.seekerPhoto],
                ownCode: 'ZYRA-7Q4M-K2XD-9P3L-W8RT-F6NB',
              ),
            ),
            backdrop: BoxDecoration(gradient: ZyraColors.brandGradient),
          );
          await _capture(h, name);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          c.dispose();
          debugDisableShadows = previousShadows;
        }
      },
      skip: _output.isEmpty && !baselineTextAuditOnly,
      variant: TargetPlatformVariant.only(
        name.startsWith('s03') ? TargetPlatform.android : TargetPlatform.iOS,
      ),
    );
  }

  for (final (name, kind, reference) in [
    ('s91_error__offline', ZyraErrorKind.offline, 'ZY-4Z99'),
    ('s92_error__server', ZyraErrorKind.serviceUnavailable, 'ZY-7K2M'),
  ]) {
    testWidgets(
      'line121 shared presenter $name',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = _harness(tester);
        final previousShadows = debugDisableShadows;
        debugDisableShadows = false;
        try {
          await h.mountPresentation(
            checkpoint: _checkpoint(false),
            child: ZyraFullScreenError(
              kind: kind,
              referenceCode: reference,
              onPrimary: () async {},
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          await _capture(h, name);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          debugDisableShadows = previousShadows;
        }
      },
      skip: _output.isEmpty && !baselineTextAuditOnly,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }
}
