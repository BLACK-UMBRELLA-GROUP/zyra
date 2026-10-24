import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_initial_signup_draft.dart';
import 'package:zyra/models/zyra_signup_membership_choice.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';

class FakeSignupStore implements ZyraSignupDraftStore {
  final values = <String, String>{};
  int operations = 0;
  bool rejectWrite = false;
  bool discardWrite = false;
  bool rejectDelete = false;
  bool discardDelete = false;
  Completer<void>? readWait;
  Completer<void>? writeWait;
  @override
  Future<String?> read(String key) async {
    operations++;
    await readWait?.future;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    operations++;
    await writeWait?.future;
    if (rejectWrite) throw StateError('Test store unavailable.');
    if (!discardWrite) values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    operations++;
    if (rejectDelete) throw StateError('Test erasure unavailable.');
    if (!discardDelete) values.remove(key);
  }
}

void main() {
  final seeker = ZyraInitialSignupDraft(
    role: ZyraSignupRole.seeker,
    step: 4,
    firstName: 'Test',
    lastName: 'Ahmed',
    gender: 'male',
    dob: DateTime(1990, 1, 2),
    firstPhotoPath: 'account-a/first.jpg',
    membershipChoice: const ZyraSignupMembershipChoice(
      kind: ZyraSignupMembershipKind.basic,
    ),
  );
  final guardian = ZyraInitialSignupDraft(
    role: ZyraSignupRole.guardian,
    step: 5,
    firstName: 'Test',
    lastName: 'Ahmed',
    gender: 'female',
    dob: DateTime(1980, 1, 2),
    relationship: 'Mother',
    firstPhotoPath: 'account-a/first.jpg',
    membershipChoice: const ZyraSignupMembershipChoice(
      kind: ZyraSignupMembershipKind.one,
    ),
  );

  for (final draft in [seeker, guardian]) {
    test(
      '${draft.role.name} verification draft round trips without authority fields',
      () {
        final restored = ZyraInitialSignupDraft.fromJson(draft.toJson());
        expect(restored.toJson(), draft.toJson());
        expect(restored.toJson()['version'], 5);
        expect(restored.lastName, 'Ahmed');
        expect(restored.awaitsVerification, isTrue);
        expect(restored.toJson().keys, isNot(contains('verified')));
        expect(restored.toJson().keys, isNot(contains('access_token')));
      },
    );
  }
  test('all completed-step checkpoints validate for both roles', () {
    for (var step = 0; step <= 4; step++) {
      expect(
        ZyraInitialSignupDraft(
          role: ZyraSignupRole.seeker,
          step: step,
          firstName: step > 0 ? 'Test' : null,
          lastName: step > 0 ? 'Ahmed' : null,
          gender: step > 1 ? 'male' : null,
          dob: step > 2 ? DateTime(1990) : null,
          firstPhotoPath: step > 3 ? 'account-a/first.jpg' : null,
        ).isValid(),
        isTrue,
      );
    }
    for (var step = 0; step <= 5; step++) {
      expect(
        ZyraInitialSignupDraft(
          role: ZyraSignupRole.guardian,
          step: step,
          firstName: step > 0 ? 'Test' : null,
          lastName: step > 0 ? 'Ahmed' : null,
          dob: step > 1 ? DateTime(1990) : null,
          gender: step > 2 ? 'female' : null,
          relationship: step > 3 ? 'Mother' : null,
          firstPhotoPath: step > 4 ? 'account-a/first.jpg' : null,
        ).isValid(),
        isTrue,
      );
    }
  });
  test(
    'malformed, underage, impossible date, version and missing fields refuse',
    () {
      for (final change in <Map<String, Object?>>[
        {'version': 6},
        {'version': 5.0},
        {'version': '5'},
        {'role': 'admin'},
        {'step': 5},
        {'step': -1},
        {'firstName': null},
        {'firstName': ' Test '},
        {'lastName': null},
        {'lastName': ''},
        {'lastName': ' Ahmed '},
        {'lastName': 7},
        {'gender': null},
        {'dob': '2020-01-01'},
        {'dob': '1990-02-31'},
        {'dob': '01/01/1990'},
        {'relationship': 'Father'},
        {'firstPhotoPath': null},
        {'firstPhotoPath': 'https://example.invalid/photo.jpg?token=unsafe'},
        {'firstPhotoPath': 'account-a/../photo.jpg'},
        {'firstPhotoPath': 'account-a/%2e%2e.jpg'},
        {'firstPhotoPath': 'data:image/jpeg;base64,unsafe'},
        {'showIntroduction': true},
      ]) {
        expect(
          () =>
              ZyraInitialSignupDraft.fromJson({...seeker.toJson(), ...change}),
          throwsFormatException,
        );
      }
      expect(
        () => ZyraInitialSignupDraft.fromJson({
          ...guardian.toJson(),
          'relationship': 'Father',
        }),
        throwsFormatException,
      );
    },
  );

  for (final role in ZyraSignupRole.values) {
    test(
      '${role.name} cannot complete the name checkpoint without a valid surname',
      () {
        for (final surname in [
          null,
          '',
          '   ',
          ' Ahmed ',
          List.filled(61, 'A').join(),
        ]) {
          final invalid = ZyraInitialSignupDraft(
            role: role,
            step: 1,
            firstName: 'Amina',
            lastName: surname,
          );
          expect(
            invalid.isValid(),
            isFalse,
            reason: 'Invalid surname: $surname',
          );
          expect(
            () => ZyraInitialSignupDraft.fromJson(invalid.toJson()),
            throwsFormatException,
          );
        }
        final valid = ZyraInitialSignupDraft(
          role: role,
          step: 1,
          firstName: 'Amina',
          lastName: List.filled(60, 'A').join(),
        );
        expect(valid.isValid(), isTrue);
        expect(
          ZyraInitialSignupDraft.fromJson(valid.toJson()).lastName,
          List.filled(60, 'A').join(),
        );
      },
    );
  }

  for (final draft in [seeker, guardian]) {
    test(
      '${draft.role.name} legacy v1 rewinds only the name checkpoint and retains answers',
      () {
        final legacy = <String, dynamic>{
          ...draft.toJson(),
          'version': 1,
          'step': draft.role == ZyraSignupRole.seeker ? 3 : 4,
          'firstPhotoPath': null,
        }..remove('lastName');
        final restored = ZyraInitialSignupDraft.fromJson(legacy);
        expect(restored.step, 0);
        expect(restored.showIntroduction, isFalse);
        expect(restored.firstName, draft.firstName);
        expect(restored.lastName, isNull);
        expect(restored.gender, draft.gender);
        expect(restored.dob, draft.dob);
        expect(restored.relationship, draft.relationship);
        expect(restored.awaitsVerification, isFalse);
        expect(restored.isValid(), isTrue);
        expect(restored.toJson()['version'], 5);
      },
    );
  }

  test('legacy v1 does not guess a surname from a multi-word given name', () {
    final restored = ZyraInitialSignupDraft.fromJson({
      ...seeker.toJson(),
      'version': 1,
      'step': 3,
      'firstName': 'Amina Al-Rahman',
      'lastName': null,
    });
    expect(restored.firstName, 'Amina Al-Rahman');
    expect(restored.lastName, isNull);
    expect(restored.step, 0);
  });

  test(
    'legacy invalid checkpoints are refused before any name-step rewind',
    () {
      final legacy = <String, dynamic>{
        ...seeker.toJson(),
        'version': 1,
        'step': 3,
      }..remove('lastName');
      for (final change in <Map<String, Object?>>[
        {'step': -1},
        {'step': 4},
        {'firstName': null},
        {'firstName': ' Test '},
        {'gender': null},
        {'gender': 'unknown'},
        {'dob': null},
        {'dob': '2020-01-01'},
        {'showIntroduction': true},
        {'lastName': 7},
      ]) {
        expect(
          () => ZyraInitialSignupDraft.fromJson({...legacy, ...change}),
          throwsFormatException,
        );
      }
      final legacyGuardian = <String, dynamic>{
        ...guardian.toJson(),
        'version': 1,
        'step': 4,
        'firstPhotoPath': null,
      }..remove('lastName');
      for (final relationship in [null, 'Father']) {
        expect(
          () => ZyraInitialSignupDraft.fromJson({
            ...legacyGuardian,
            'relationship': relationship,
          }),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'legacy draft with a valid surname does not rewind a complete checkpoint',
    () {
      final restored = ZyraInitialSignupDraft.fromJson({
        ...seeker.toJson(),
        'version': 1,
        'step': 3,
      });
      expect(restored.step, 3);
      expect(restored.lastName, seeker.lastName);
      expect(restored.needsMembershipChoice, isFalse);
      expect(restored.firstPhotoPath, isNull);
    },
  );

  for (final version in [1, 2, 3]) {
    test(
      'v$version Seeker collects its first photo without losing answers',
      () {
        final restored = ZyraInitialSignupDraft.fromJson({
          ...seeker.toJson(),
          'version': version,
          'step': 3,
        });
        expect(restored.step, 3);
        expect(restored.questionCount, 4);
        expect(restored.firstPhotoPath, isNull);
        expect(restored.gender, seeker.gender);
        expect(restored.dob, seeker.dob);
        expect(restored.lastName, seeker.lastName);
        expect(restored.awaitsVerification, isFalse);
        expect(
          restored.membershipChoice?.kind,
          version == 3 ? ZyraSignupMembershipKind.basic : isNull,
        );
      },
    );
  }
  test('Guardian requires one owned photo before membership and identity', () {
    expect(guardian.questionCount, 5);
    expect(guardian.awaitsVerification, isTrue);
    expect(guardian.firstPhotoPath, 'account-a/first.jpg');
    expect(
      ZyraInitialSignupDraft.fromJson(guardian.toJson()).firstPhotoPath,
      guardian.firstPhotoPath,
    );
    expect(
      () => ZyraInitialSignupDraft.fromJson({
        ...guardian.toJson(),
        'firstPhotoPath': null,
      }),
      throwsFormatException,
    );
    final needsPhoto = ZyraInitialSignupDraft.fromJson({
      ...guardian.toJson(),
      'step': 4,
      'firstPhotoPath': null,
    });
    expect(needsPhoto.isValid(), isTrue);
    expect(needsPhoto.awaitsVerification, isFalse);
    expect(needsPhoto.needsMembershipChoice, isFalse);
    expect(needsPhoto.membershipChoice?.kind, ZyraSignupMembershipKind.one);
  });

  for (final version in [1, 2, 3, 4]) {
    test(
      'v$version Guardian returns to photo without losing prior answers',
      () {
        final restored = ZyraInitialSignupDraft.fromJson({
          ...guardian.toJson(),
          'version': version,
          'step': 4,
          'firstPhotoPath': null,
        });
        expect(restored.step, 4);
        expect(restored.questionCount, 5);
        expect(restored.firstPhotoPath, isNull);
        expect(restored.lastName, guardian.lastName);
        expect(restored.gender, guardian.gender);
        expect(restored.dob, guardian.dob);
        expect(restored.relationship, guardian.relationship);
        expect(restored.awaitsVerification, isFalse);
        expect(restored.isValid(), isTrue);
        expect(
          restored.membershipChoice?.kind,
          version >= 3 ? ZyraSignupMembershipKind.one : isNull,
        );
        for (final path in [
          'account-a/first.jpg',
          'account-a/../first.jpg',
          'https://example.invalid/first.jpg',
        ]) {
          expect(
            () => ZyraInitialSignupDraft.fromJson({
              ...guardian.toJson(),
              'version': version,
              'step': 4,
              'firstPhotoPath': path,
            }),
            throwsFormatException,
            reason: 'Old Guardian schemas cannot inject a photo capability.',
          );
        }
        expect(
          () => ZyraInitialSignupDraft.fromJson({
            ...guardian.toJson(),
            'version': version,
            'firstPhotoPath': null,
          }),
          throwsFormatException,
          reason: 'An invalid old checkpoint is refused before migration.',
        );
      },
    );
  }

  test(
    'v4 Seeker preserves its confirmed photo and verification checkpoint',
    () {
      final restored = ZyraInitialSignupDraft.fromJson({
        ...seeker.toJson(),
        'version': 4,
      });
      expect(restored.step, 4);
      expect(restored.questionCount, 4);
      expect(restored.firstPhotoPath, seeker.firstPhotoPath);
      expect(restored.membershipChoice?.kind, ZyraSignupMembershipKind.basic);
      expect(restored.awaitsVerification, isTrue);
      expect(restored.toJson()['version'], 5);
    },
  );

  late FakeSignupStore store;
  late ZyraSignupDraftRepository repository;
  String? owner;
  var preview = false;
  var generation = 0;
  setUp(() {
    owner = 'account-a';
    preview = false;
    generation = 0;
    store = FakeSignupStore();
    repository = ZyraSignupDraftRepository(
      store: store,
      backend: 'https://example.invalid',
      currentUserId: () => owner,
      isPreview: () => preview,
      currentGeneration: () => generation,
    );
  });
  test('durable round trip and confirmed erasure', () async {
    await repository.save(owner!, seeker);
    expect((await repository.read(owner!))!.toJson(), seeker.toJson());
    await repository.clear(owner!);
    expect(await repository.read(owner!), isNull);
  });
  for (final draft in [seeker, guardian]) {
    test(
      '${draft.role.name} draft refuses another owner photo on write and recovery',
      () async {
        final wrongOwner = ZyraInitialSignupDraft.fromJson({
          ...draft.toJson(),
          'firstPhotoPath': 'account-b/first.jpg',
        });
        await expectLater(
          repository.save('account-a', wrongOwner),
          throwsFormatException,
        );
        expect(store.values, isEmpty);
        store.values[repository.keyFor('account-a')] = jsonEncode(
          wrongOwner.toJson(),
        );
        await expectLater(repository.read('account-a'), throwsFormatException);
      },
    );
  }
  test(
    'pending marker is confirmed, opaque and contains no form or photo data',
    () async {
      final key = repository.pendingSeekerFinalizationKeyFor('account-a');
      expect(key, isNot(contains('account-a')));
      expect(
        await repository.readPendingSeekerFinalization('account-a'),
        isFalse,
      );
      await repository.beginPendingSeekerFinalization('account-a');
      expect(jsonDecode(store.values[key]!), {'version': 1, 'pending': true});
      expect(
        await repository.readPendingSeekerFinalization('account-a'),
        isTrue,
      );
      await repository.clearPendingSeekerFinalization('account-a');
      expect(
        await repository.readPendingSeekerFinalization('account-a'),
        isFalse,
      );
    },
  );
  test(
    'Guardian retry marker is opaque, confirmed and role-isolated',
    () async {
      final key = repository.pendingGuardianFinalizationKeyFor('account-a');
      expect(key, isNot(contains('account-a')));
      expect(
        key,
        isNot(repository.pendingSeekerFinalizationKeyFor('account-a')),
      );
      expect(
        key,
        isNot(repository.pendingGuardianFinalizationKeyFor('account-b')),
      );
      expect(
        await repository.readPendingGuardianFinalization('account-a'),
        isFalse,
      );
      await repository.beginPendingGuardianFinalization('account-a');
      expect(jsonDecode(store.values[key]!), {'version': 1, 'pending': true});
      expect(
        await repository.readPendingGuardianFinalization('account-a'),
        isTrue,
      );
      expect(
        await repository.readPendingSeekerFinalization('account-a'),
        isFalse,
      );
      await repository.clearPendingGuardianFinalization('account-a');
      expect(
        await repository.readPendingGuardianFinalization('account-a'),
        isFalse,
      );
    },
  );
  test(
    'Guardian retry marker failures never become missing recovery',
    () async {
      final key = repository.pendingGuardianFinalizationKeyFor('account-a');
      for (final invalid in [
        'broken',
        '[]',
        '{"version":2,"pending":true}',
        '{"version":1,"pending":false}',
        '{"version":1,"pending":true,"photo":"account-a/first.jpg"}',
        List.filled(65, 'x').join(),
      ]) {
        store.values[key] = invalid;
        await expectLater(
          repository.readPendingGuardianFinalization('account-a'),
          throwsFormatException,
        );
      }
      store.values.clear();
      store.discardWrite = true;
      await expectLater(
        repository.beginPendingGuardianFinalization('account-a'),
        throwsStateError,
      );
      store.discardWrite = false;
      await repository.beginPendingGuardianFinalization('account-a');
      store.discardDelete = true;
      await expectLater(
        repository.clearPendingGuardianFinalization('account-a'),
        throwsStateError,
      );
      expect(
        await repository.readPendingGuardianFinalization('account-a'),
        isTrue,
      );
    },
  );
  test('Guardian retry marker denies preview and another account', () async {
    preview = true;
    for (final operation in [
      () => repository.beginPendingGuardianFinalization('account-a'),
      () => repository.readPendingGuardianFinalization('account-a'),
      () => repository.clearPendingGuardianFinalization('account-a'),
    ]) {
      await expectLater(operation(), throwsStateError);
    }
    expect(store.operations, 0);
    preview = false;
    owner = 'account-b';
    await expectLater(
      repository.beginPendingGuardianFinalization('account-a'),
      throwsStateError,
    );
    expect(store.operations, 0);
  });
  test(
    'sign-out erases identity and membership, retaining only retry marker',
    () async {
      await repository.save('account-a', seeker);
      await repository.saveMembershipIntent(
        'account-a',
        ZyraSignupMembershipIntent(
          role: ZyraSignupRole.seeker,
          choice: seeker.membershipChoice!,
        ),
      );
      await repository.beginPendingSeekerFinalization('account-a');
      await repository.signOut('account-a', () async => owner = null);
      expect(store.values.keys, [
        repository.pendingSeekerFinalizationKeyFor('account-a'),
      ]);
      owner = 'account-b';
      generation++;
      expect(
        await repository.readPendingSeekerFinalization('account-b'),
        isFalse,
      );
      owner = 'account-a';
      generation++;
      expect(await repository.read('account-a'), isNull);
      expect(await repository.readMembershipIntent('account-a'), isNull);
      expect(
        await repository.readPendingSeekerFinalization('account-a'),
        isTrue,
      );
    },
  );
  test(
    'silent marker erasure loss refuses completion and retains pending',
    () async {
      await repository.beginPendingSeekerFinalization('account-a');
      store.discardDelete = true;
      await expectLater(
        repository.clearPendingSeekerFinalization('account-a'),
        throwsStateError,
      );
      expect(
        await repository.readPendingSeekerFinalization('account-a'),
        isTrue,
      );
    },
  );
  test(
    'malformed recovery markers fail closed instead of authorizing routing',
    () async {
      final key = repository.pendingSeekerFinalizationKeyFor('account-a');
      for (final invalid in [
        'broken',
        '[]',
        '{"version":2,"pending":true}',
        '{"version":1,"pending":false}',
        '{"version":1,"pending":true,"name":"Test"}',
        List.filled(65, 'x').join(),
      ]) {
        store.values[key] = invalid;
        await expectLater(
          repository.readPendingSeekerFinalization('account-a'),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'pending marker refused preview, wrong owner and unconfirmed writes',
    () async {
      preview = true;
      await expectLater(
        repository.beginPendingSeekerFinalization('account-a'),
        throwsStateError,
      );
      await expectLater(
        repository.readPendingSeekerFinalization('account-a'),
        throwsStateError,
      );
      await expectLater(
        repository.clearPendingSeekerFinalization('account-a'),
        throwsStateError,
      );
      expect(store.operations, 0);
      preview = false;
      owner = 'account-b';
      await expectLater(
        repository.beginPendingSeekerFinalization('account-a'),
        throwsStateError,
      );
      expect(store.operations, 0);
      owner = 'account-a';
      store.discardWrite = true;
      await expectLater(
        repository.beginPendingSeekerFinalization('account-a'),
        throwsStateError,
      );
    },
  );
  for (final operation in ['begin', 'read', 'clear']) {
    test(
      'pending $operation refuses same-owner ABA at async boundary',
      () async {
        await repository.beginPendingSeekerFinalization('account-a');
        store.readWait = Completer<void>();
        final pending = switch (operation) {
          'begin' => repository.beginPendingSeekerFinalization('account-a'),
          'clear' => repository.clearPendingSeekerFinalization('account-a'),
          _ =>
            repository
                .readPendingSeekerFinalization('account-a')
                .then<void>((_) {}),
        };
        final expectation = expectLater(pending, throwsStateError);
        await Future<void>.delayed(Duration.zero);
        generation++;
        store.readWait!.complete();
        await expectation;
      },
    );
  }
  for (final operation in ['begin', 'read', 'clear']) {
    test('Guardian pending $operation refuses same-owner ABA', () async {
      await repository.beginPendingGuardianFinalization('account-a');
      store.readWait = Completer<void>();
      final pending = switch (operation) {
        'begin' => repository.beginPendingGuardianFinalization('account-a'),
        'clear' => repository.clearPendingGuardianFinalization('account-a'),
        _ =>
          repository
              .readPendingGuardianFinalization('account-a')
              .then<void>((_) {}),
      };
      final expectation = expectLater(pending, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      generation++;
      store.readWait!.complete();
      await expectation;
    });
  }
  test(
    'v2 writes reuse the existing secure v1 key and recover legacy answers',
    () async {
      final oldKey =
          'zyra.initial_signup.v1.${sha256.convert(utf8.encode('https://example.invalid\naccount-a'))}';
      expect(repository.keyFor('account-a'), oldKey);
      final legacy = <String, dynamic>{
        ...guardian.toJson(),
        'version': 1,
        'step': 4,
        'firstPhotoPath': null,
      }..remove('lastName');
      store.values[oldKey] = jsonEncode(legacy);
      final recovered = await repository.read('account-a');
      expect(recovered?.step, 0);
      expect(recovered?.lastName, isNull);
      expect(recovered?.gender, guardian.gender);
      expect(recovered?.dob, guardian.dob);
      expect(recovered?.relationship, guardian.relationship);
      await repository.save('account-a', guardian);
      expect(store.values.keys, [oldKey]);
      final saved = jsonDecode(store.values[oldKey]!) as Map<String, dynamic>;
      expect(saved['version'], 5);
      expect(saved['lastName'], 'Ahmed');
      expect((await repository.read('account-a'))?.lastName, 'Ahmed');
    },
  );
  test(
    'accounts and backend endpoints have disjoint opaque storage keys',
    () async {
      await repository.save('account-a', seeker);
      owner = 'account-b';
      expect(await repository.read(owner!), isNull);
      final other = ZyraSignupDraftRepository(
        store: store,
        backend: 'https://other.invalid',
        currentUserId: () => owner,
        isPreview: () => false,
        currentGeneration: () => generation,
      );
      expect(repository.keyFor(owner!), isNot(other.keyFor(owner!)));
      expect(repository.keyFor(owner!), isNot(contains(owner!)));
    },
  );
  test('preview refuses all draft I/O', () async {
    preview = true;
    await expectLater(repository.read('account-a'), throwsStateError);
    await expectLater(repository.save('account-a', seeker), throwsStateError);
    await expectLater(repository.clear('account-a'), throwsStateError);
    expect(store.operations, 0);
  });
  test('null or changed owner refuses all draft I/O', () async {
    owner = null;
    await expectLater(repository.read('account-a'), throwsStateError);
    await expectLater(repository.save('account-a', seeker), throwsStateError);
    expect(store.operations, 0);
  });
  test('failed write and silent write loss both refuse advancement', () async {
    store.rejectWrite = true;
    await expectLater(repository.save('account-a', seeker), throwsStateError);
    store.rejectWrite = false;
    store.discardWrite = true;
    await expectLater(repository.save('account-a', seeker), throwsStateError);
  });
  test(
    'invalid persisted value is failure, never an empty new signup',
    () async {
      store.values[repository.keyFor('account-a')] = '{broken';
      await expectLater(repository.read('account-a'), throwsFormatException);
      store.values[repository.keyFor('account-a')] = jsonEncode({
        'version': 900,
      });
      await expectLater(repository.read('account-a'), throwsFormatException);
    },
  );
  test(
    'owner changes during read do not reveal draft to new account',
    () async {
      await repository.save('account-a', seeker);
      store.readWait = Completer<void>();
      final result = repository.read('account-a');
      final expectation = expectLater(result, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      owner = 'account-b';
      store.readWait!.complete();
      await expectation;
    },
  );
  test(
    'owner changes during write cannot authorize new-account continuation',
    () async {
      store.writeWait = Completer<void>();
      final result = repository.save('account-a', seeker);
      final expectation = expectLater(result, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      owner = 'account-b';
      store.writeWait!.complete();
      await expectation;
      expect(store.values.containsKey(repository.keyFor('account-b')), isFalse);
    },
  );
  for (final operation in ['read', 'save', 'clear', 'signOut']) {
    test(
      'queued $operation refuses same-ID ABA before any storage or logout',
      () async {
        await repository.save('account-a', seeker);
        final key = repository.keyFor('account-a');
        final original = store.values[key];
        final operationsBefore = store.operations;
        store.readWait = Completer<void>();
        final blockingRead = repository.read('account-a');
        final blockingExpectation = expectLater(blockingRead, throwsStateError);
        await Future<void>.delayed(Duration.zero);
        expect(store.operations, operationsBefore + 1);
        var loggedOut = false;
        final Future<void> queued;
        switch (operation) {
          case 'read':
            queued = repository.read('account-a').then<void>((_) {});
          case 'save':
            queued = repository.save('account-a', guardian);
          case 'clear':
            queued = repository.clear('account-a');
          case 'signOut':
            queued = repository.signOut('account-a', () async {
              loggedOut = true;
              owner = null;
            });
          default:
            throw StateError('Unexpected test operation.');
        }
        final queuedExpectation = expectLater(queued, throwsStateError);
        owner = 'account-b';
        generation++;
        owner = 'account-a';
        generation++;
        store.readWait!.complete();
        await blockingExpectation;
        await queuedExpectation;

        // In particular, the queued clear must leave the recovery draft intact.
        expect(store.operations, operationsBefore + 1);
        expect(store.values[key], original);
        expect(loggedOut, isFalse);
        store.readWait = null;
        // A rejected old sign-out must also release its dedicated latch.
        expect((await repository.read('account-a'))?.toJson(), seeker.toJson());
      },
    );
  }
  test(
    'in-flight legacy read cannot return migrated answers after same-ID ABA',
    () async {
      final key = repository.keyFor('account-a');
      final legacy = <String, dynamic>{
        ...guardian.toJson(),
        'version': 1,
        'step': 4,
        'firstPhotoPath': null,
      }..remove('lastName');
      final original = jsonEncode(legacy);
      store.values[key] = original;
      store.readWait = Completer<void>();
      final pending = repository.read('account-a');
      final expectation = expectLater(pending, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      owner = 'account-b';
      generation++;
      owner = 'account-a';
      generation++;
      store.readWait!.complete();
      await expectation;
      expect(store.values[key], original);
      expect(store.operations, 1);
      store.readWait = null;
      final fresh = await repository.read('account-a');
      expect(fresh?.step, 0);
      expect(fresh?.gender, guardian.gender);
      expect(fresh?.dob, guardian.dob);
      expect(fresh?.relationship, guardian.relationship);
      expect(fresh?.lastName, isNull);
      expect(store.values[key], original);
    },
  );
  test(
    'same-ID epoch change during write refuses confirmation and continuation',
    () async {
      store.writeWait = Completer<void>();
      final pending = repository.save('account-a', seeker);
      final expectation = expectLater(pending, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      owner = 'account-b';
      generation++;
      owner = 'account-a';
      generation++;
      store.writeWait!.complete();
      await expectation;
      // A native write already dispatched cannot be rolled back, but its
      // result cannot authorize progression or begin another stale store read.
      expect(store.values[repository.keyFor('account-a')], isNotNull);
      expect(store.operations, 1);
    },
  );
  test(
    'same-ID epoch change during save confirmation cannot authorize continuation',
    () async {
      store.readWait = Completer<void>();
      final pending = repository.save('account-a', seeker);
      final expectation = expectLater(pending, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      expect(store.operations, 2);
      owner = 'account-b';
      generation++;
      owner = 'account-a';
      generation++;
      store.readWait!.complete();
      await expectation;
      expect(store.operations, 2);
    },
  );
  test(
    'signout latches before queued writes and erases after in-flight write',
    () async {
      store.writeWait = Completer<void>();
      final saving = repository.save('account-a', seeker);
      final saveExpectation = expectLater(saving, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      var loggedOut = false;
      final logout = repository.signOut('account-a', () async {
        loggedOut = true;
        owner = null;
      });
      final lateSave = expectLater(
        repository.save('account-a', seeker),
        throwsStateError,
      );
      store.writeWait!.complete();
      await saveExpectation;
      await logout;
      await lateSave;
      expect(loggedOut, isTrue);
      expect(store.values, isEmpty);
    },
  );
  test(
    'failed erasure blocks signout, retains owner and permits explicit retry',
    () async {
      await repository.save('account-a', seeker);
      store.rejectDelete = true;
      var loggedOut = false;
      await expectLater(
        repository.signOut('account-a', () async {
          loggedOut = true;
        }),
        throwsStateError,
      );
      expect(loggedOut, isFalse);
      expect(owner, 'account-a');
      store.rejectDelete = false;
      await repository.signOut('account-a', () async {
        loggedOut = true;
        owner = null;
      });
      expect(loggedOut, isTrue);
      expect(store.values, isEmpty);
    },
  );
}
