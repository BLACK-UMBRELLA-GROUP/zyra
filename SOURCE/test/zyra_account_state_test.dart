import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/models/journey_bio.dart';
import 'package:zyra/models/journey_match.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const member = '11111111-1111-4111-8111-111111111111';
  const other = '22222222-2222-4222-8222-222222222222';
  const founder = 'dfcbd00d-bc22-4d6e-999b-3a9264cf3510';
  const profile = SeekerProfile(
    id: 'sample',
    firstName: 'Example',
    age: 30,
    city: 'London',
    photos: ['sample-photo'],
    gender: 'female',
  );

  void fillMemberState() {
    final state = AppState.instance;
    state.name = 'Old member';
    state.surnameLine = 'Surname';
    state.gender = 'female';
    state.dob = DateTime(1990);
    state.photos = ['private-photo'];
    state.location = 'Old location';
    state.sect = 'Old sect';
    state.plan = ZyraPlan.one;
    state.journeyBio = const JourneyBio(aboutMe: 'Private biography');
    state.age = 36;
    state.hydrated = true;
    state.notifyNewMatches = false;
    state.notifyNewMessages = false;
    state.notifyWaliRequests = false;
    state.waliName = 'Old guardian';
    state.waliRelationship = 'Mother';
    state.waliHasWaliOne = true;
    state.waliLinkedSeekers.add(profile);
    state.saved.add(profile);
    state.outgoingLikes.add(profile);
    state.declined.add(profile);
    state.potentialJourneys.add(
      const JourneyMatch(
        matchId: 'old-potential',
        profile: profile,
        status: 'potential',
      ),
    );
    state.activeJourneys.add(
      const JourneyMatch(
        matchId: 'old-active',
        profile: profile,
        status: 'active',
      ),
    );
    state.pendingBrowseProfile = profile;
    state.guardianSuggestedBy = {'sample': 'Old guardian'};
  }

  void expectEmptyMemberState() {
    final state = AppState.instance;
    expect([
      state.name,
      state.surnameLine,
      state.gender,
      state.dob,
      state.location,
      state.sect,
      state.age,
      state.waliName,
      state.waliRelationship,
      state.pendingBrowseProfile,
    ], everyElement(isNull));
    expect([
      state.photos,
      state.waliLinkedSeekers,
      state.waliRealLinkedSeekers,
      state.saved,
      state.outgoingLikes,
      state.declined,
      state.potentialJourneys,
      state.activeJourneys,
    ], everyElement(isEmpty));
    expect(state.journeyBio.isEmpty, isTrue);
    expect(state.plan, ZyraPlan.basic);
    expect(state.hydrated, isFalse);
    expect(state.waliHasWaliOne, isFalse);
    expect(state.guardianSuggestedBy, isEmpty);
    expect([
      state.notifyNewMatches,
      state.notifyNewMessages,
      state.notifyWaliRequests,
    ], everyElement(isTrue));
  }

  setUp(() async {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraAccountState.endSignOutAttempt();
    ZyraInternalPreviewClient.finishSignOut();
    await ZyraAccountState.synchronize(null);
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
  });

  tearDown(() async {
    ZyraAccountState.endSignOutAttempt();
    ZyraInternalPreviewClient.finishSignOut();
    await ZyraAccountState.synchronize(null);
    ZyraAccountState.clearImagesForTesting = null;
  });

  test(
    'ordinary A to B and signed-out transitions reset synchronously',
    () async {
      await ZyraAccountState.synchronize(member);
      fillMemberState();
      final version = ZyraAccountState.generation;
      final switching = ZyraAccountState.synchronize(other);
      expectEmptyMemberState();
      expect(ZyraAccountState.isCurrent(member, version), isFalse);
      await switching;
      fillMemberState();
      final leaving = ZyraAccountState.synchronize(null);
      expectEmptyMemberState();
      await leaving;
    },
  );

  test('Founder landing starts empty before any sample is selected', () async {
    await ZyraAccountState.synchronize(member);
    fillMemberState();
    await ZyraAccountState.synchronize(founder);
    ZyraInternalPreviewClient.beginPreview();
    expectEmptyMemberState();
    expect(ZyraInternalPreviewClient.isActive, isTrue);
  });

  test('same owner preserves live member state and generation', () async {
    await ZyraAccountState.synchronize(member);
    fillMemberState();
    final version = ZyraAccountState.generation;
    await ZyraAccountState.synchronize(member);
    expect(AppState.instance.name, 'Old member');
    expect(AppState.instance.activeJourneys, hasLength(1));
    expect(ZyraAccountState.generation, version);
  });

  test(
    'unowned legacy preferences cannot be claimed by a new principal',
    () async {
      SharedPreferences.setMockInitialValues({
        'zyra.cached_first_name': 'Previous person',
        'zyra.cached_gender': 'female',
        'zyra.cached_role': 'wali',
        'zyra.app_lock_enabled': true,
        'zyra.cache_schema_version': 9,
      });
      await ZyraLocalPrefs.init();
      expect(ZyraLocalPrefs.cachedFirstName, isNull);
      await ZyraLocalPrefs.bindAccount(member);
      expect(ZyraLocalPrefs.cachedFirstName, isNull);
      expect(ZyraLocalPrefs.cachedGender, isNull);
      expect(ZyraLocalPrefs.cachedRole, isNull);
      expect(ZyraLocalPrefs.appLockEnabled, isFalse);
      expect(ZyraLocalPrefs.cacheSchemaVersion, 9);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('zyra.cached_first_name'), isNull);
    },
  );

  test(
    'same persisted owner restores preferences only after binding',
    () async {
      await ZyraLocalPrefs.bindAccount(member);
      ZyraLocalPrefs.setCachedFirstName('Returning member');
      ZyraLocalPrefs.setCachedGender('male');
      await ZyraLocalPrefs.setCachedAppPaletteName('deepEmerald');
      await ZyraLocalPrefs.setAppLockEnabled(true);
      await ZyraLocalPrefs.init();
      expect(ZyraLocalPrefs.cachedFirstName, isNull);
      await ZyraLocalPrefs.bindAccount(member);
      expect(ZyraLocalPrefs.cachedFirstName, 'Returning member');
      expect(ZyraLocalPrefs.cachedAppPaletteName, 'deepEmerald');
      expect(ZyraLocalPrefs.appLockEnabled, isTrue);
      await ZyraLocalPrefs.bindAccount(other);
      expect(ZyraLocalPrefs.cachedFirstName, isNull);
      expect(ZyraLocalPrefs.appLockEnabled, isFalse);
    },
  );

  test(
    'rapid switches and queued old writes cannot erase new owner values',
    () async {
      await ZyraLocalPrefs.bindAccount(member);
      ZyraLocalPrefs.setCachedFirstName('Old member');
      final leaving = ZyraLocalPrefs.bindAccount(null);
      final entering = ZyraLocalPrefs.bindAccount(other);
      ZyraLocalPrefs.setCachedFirstName('New member');
      await Future.wait([leaving, entering]);
      await ZyraLocalPrefs.bindAccount(other);
      await ZyraLocalPrefs.init();
      await ZyraLocalPrefs.bindAccount(other);
      expect(ZyraLocalPrefs.cachedFirstName, 'New member');
    },
  );

  test(
    'new principal waits for any already-running previous cleanup',
    () async {
      final imageCleanup = Completer<void>();
      final started = Completer<void>();
      var calls = 0;
      ZyraAccountState.clearImagesForTesting = () async {
        calls++;
        if (calls == 1) {
          started.complete();
          await imageCleanup.future;
        }
      };
      final first = ZyraAccountState.synchronize(member);
      await started.future;
      var secondFinished = false;
      final second = ZyraAccountState.synchronize(other).then((_) {
        secondFinished = true;
      });
      await Future<void>.delayed(Duration.zero);
      expect(secondFinished, isFalse);
      imageCleanup.complete();
      await Future.wait([first, second]);
      expect(secondFinished, isTrue);
      expect(ZyraAccountState.userId, other);
    },
  );

  test(
    'logout starts reset before awaits and cannot release preview latch',
    () async {
      await ZyraAccountState.synchronize(founder);
      ZyraInternalPreviewClient.beginPreview();
      fillMemberState();
      final cleanup = ZyraAccountState.beginSignOut();
      expectEmptyMemberState();
      expect(ZyraAccountState.userId, isNull);
      await ZyraAccountState.synchronize(founder);
      expect(ZyraAccountState.userId, isNull);
      await cleanup;
      ZyraAccountState.endSignOutAttempt();
      expect(ZyraInternalPreviewClient.isActive, isTrue);
    },
  );

  test('missing hydrated fields replace previous values', () async {
    await ZyraAccountState.synchronize(member);
    fillMemberState();
    AppState.instance.hydrateFrom(name: 'Current');
    expect(AppState.instance.name, 'Current');
    expect(AppState.instance.surnameLine, isNull);
    expect(AppState.instance.location, isNull);
    expect(AppState.instance.age, isNull);
    expect(AppState.instance.plan, ZyraPlan.basic);
  });
}
