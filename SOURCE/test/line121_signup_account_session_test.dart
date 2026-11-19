// LOCK 34 local signup adoption. No Auth, AppState, file or network writes.
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_request_account_session.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';

const _original = 'data:image/jpeg;base64,YQ==';
const _chosen = 'data:image/jpeg;base64,Yg==';
const _other = 'data:image/jpeg;base64,Yw==';

ZyraRequestAccountSession _session({
  bool Function()? canAct,
  bool legacy = false,
}) => ZyraRequestAccountSession(
  canAct: canAct ?? () => true,
  palette: ZyraColors.currentDefaultPalette,
  hapticLevel: ZyraHapticLevel.subtle,
  goldEnabled: false,
  legacyAmberQuickCheck: legacy,
);

ZyraCompatibilityDraft _preferences(String gender) =>
    ZyraCompatibilityDraft.fromSnapshot(gender: gender)
      ..preferences['ch3_q33'] = {
        'Usually all five prayers': TrafficLight.green,
      };

bool _apply(
  ZyraRequestAccountSession session, {
  bool guardian = false,
  String gender = 'female',
  List<String> photos = const [_chosen],
  List<String> ethnicities = const ['British', 'Pakistani'],
  ZyraCompatibilityDraft? preferences,
}) => session.applySignup(
  guardian: guardian,
  firstName: 'Aisha',
  surname: 'Rahman',
  age: 29,
  gender: gender,
  city: 'Leeds',
  nationality: 'British',
  ethnicities: ethnicities,
  photos: photos,
  preferences: preferences ?? _preferences(gender),
);

void main() {
  test(
    'signup identity, photos and preferences are detached and role-local',
    () async {
      final session = _session();
      addTearDown(session.dispose);
      session.seedPhotos(false, [_original]);
      final photos = [_chosen, _other];
      final ethnicities = ['British', 'Pakistani'];
      final preferences = _preferences('female');
      expect(
        _apply(
          session,
          photos: photos,
          ethnicities: ethnicities,
          preferences: preferences,
        ),
        isTrue,
      );
      photos.clear();
      ethnicities.clear();
      preferences.preferences.clear();
      final profile = session.ownProfile(false);
      expect(profile.firstName, 'Aisha');
      expect(profile.surnameLine, 'Rahman');
      expect(profile.age, 29);
      expect(profile.city, 'Leeds');
      expect(profile.gender, 'female');
      expect(profile.publicNationality, 'British');
      expect(profile.publicEthnicity, 'British, Pakistani');
      expect(profile.photos, [_chosen, _other]);
      expect(profile.profilePhotoOne, _chosen);
      expect(session.ownProfile(true).firstName, 'Hassan');
      expect(session.seekerGender, 'female');
      final stored = await session.compatibility.load('draft-self');
      expect(stored!.ch4Preferences['ch3_q33'], {
        'Usually all five prayers': TrafficLight.green,
      });
      stored.ch4Preferences.clear();
      expect(
        (await session.compatibility.load('draft-self'))!.ch4Preferences,
        isNotEmpty,
      );
      expect(
        await session.compatibility.save('draft-self', _preferences('male')),
        isFalse,
      );
      expect(
        await session.compatibility.save('draft-self', _preferences('female')),
        isTrue,
      );
    },
  );

  test(
    'Guardian signup preserves Seeker preferences and its sample photo',
    () async {
      final session = _session();
      addTearDown(session.dispose);
      session.seedPhotos(true, [_original]);
      await session.compatibility.save('draft-self', _preferences('male'));
      final before = await session.compatibility.load('draft-self');
      expect(_apply(session, guardian: true, photos: const []), isTrue);
      expect(session.ownProfile(true).firstName, 'Aisha');
      expect(session.ownProfile(true).gender, 'female');
      expect(session.ownProfile(true).profilePhotoOne, _original);
      expect(session.ownProfile(false).firstName, 'Adam');
      expect(session.seekerGender, 'male');
      expect(
        (await session.compatibility.load('draft-self'))!.ch4Preferences,
        before!.ch4Preferences,
      );
    },
  );

  test(
    'Clear restores original photos, identity and legacy preference state',
    () async {
      final session = _session(legacy: true);
      addTearDown(session.dispose);
      session.seedPhotos(false, [_original]);
      session.seedPhotos(true, [_other]);
      final before = (await session.compatibility.load('draft-self'))!;
      expect(session.compatibility.hasPreferencesToCheck, isTrue);
      expect(_apply(session), isTrue);
      expect(session.compatibility.hasPreferencesToCheck, isFalse);
      expect(_apply(session, photos: const [_other]), isTrue);
      expect(_apply(session, guardian: true, photos: const []), isTrue);
      expect(session.clearSignup(), isTrue);
      expect(session.ownProfile(false).firstName, 'Adam');
      expect(session.ownProfile(true).firstName, 'Hassan');
      expect(session.seekerGender, 'male');
      expect(session.photos(false), [_original]);
      expect(session.photos(true), [_other]);
      expect(session.compatibility.hasPreferencesToCheck, isTrue);
      expect(
        (await session.compatibility.load('draft-self'))!.ch4Preferences,
        before.ch4Preferences,
      );
      final check = await session.compatibility.visiblePreferenceChecks(
        'draft-self',
      );
      expect(check.legacyAmber, hasLength(5));
      final setup = await session.compatibility.loadSetupPreferenceLights(
        'draft-self',
      );
      expect(setup!.lights, hasLength(3));
      expect(session.clearSignup(), isTrue);
    },
  );

  test('late sample photo preparation remains the Clear baseline', () {
    final session = _session();
    addTearDown(session.dispose);
    expect(_apply(session), isTrue);
    expect(session.seedPhotos(false, [_original]), isFalse);
    expect(session.photos(false), [_chosen]);
    expect(session.clearSignup(), isTrue);
    expect(session.photos(false), [_original]);
  });

  test(
    'Seeker and Guardian About text remains detached and independent',
    () async {
      final session = _session();
      addTearDown(session.dispose);
      final seeker = _preferences('male')
        ..answers['bio_about_me'] = 'Seeker setup words';
      final guardian = _preferences('female')
        ..answers['bio_about_me'] = 'Guardian setup words';
      expect(_apply(session, gender: 'male', preferences: seeker), isTrue);
      expect(
        _apply(
          session,
          guardian: true,
          photos: const [],
          preferences: guardian,
        ),
        isTrue,
      );
      seeker.answers['bio_about_me'] = 'Changed caller Seeker words';
      guardian.answers['bio_about_me'] = 'Changed caller Guardian words';
      expect(session.signupAbout(false), 'Seeker setup words');
      expect(session.signupAbout(true), 'Guardian setup words');
      expect(
        (await session.compatibility.load('draft-self'))!.journeyBio.aboutMe,
        'Seeker setup words',
      );
      expect(session.clearSignup(), isTrue);
      expect(session.signupAbout(false), isNull);
      expect(session.signupAbout(true), isNull);
      expect(await session.compatibility.load('draft-self'), isNull);
    },
  );

  test('invalid photo or gender drafts cannot replace the sample', () async {
    final session = _session();
    addTearDown(session.dispose);
    session.seedPhotos(false, [_original]);
    expect(
      _apply(session, photos: const ['https://example.invalid/p']),
      isFalse,
    );
    expect(
      _apply(session, photos: const ['data:image/png;base64,YQ==']),
      isFalse,
    );
    expect(_apply(session, preferences: _preferences('male')), isFalse);
    expect(session.ownProfile(false).firstName, 'Adam');
    expect(session.photos(false), [_original]);
    expect(await session.compatibility.load('draft-self'), isNull);
  });

  test('caller revocation is terminal for apply and Clear', () {
    var allowed = true;
    final session = _session(canAct: () => allowed);
    addTearDown(session.dispose);
    expect(_apply(session), isTrue);
    allowed = false;
    expect(session.clearSignup(), isFalse);
    allowed = true;
    expect(_apply(session, gender: 'male'), isFalse);
    expect(session.clearSignup(), isFalse);
    expect(session.current, isFalse);
    expect(session.signupAbout(false), isNull);
  });
}
