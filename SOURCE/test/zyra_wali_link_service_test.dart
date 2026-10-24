import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';

void main() {
  group('ZyraSourceResult', () {
    test('successful empty remains distinct from unavailable', () {
      const empty = ZyraSourceResult<List<String>>.available([]);
      const unavailable = ZyraSourceResult<List<String>>.unavailable(
        ZyraSourceFailure.requestFailed,
      );

      expect(empty.isAvailable, isTrue);
      expect(empty.valueOrNull, isEmpty);
      expect(unavailable.isUnavailable, isTrue);
      expect(unavailable.valueOrNull, isNull);
      expect(unavailable.valueOr(const ['fallback']), ['fallback']);
    });
  });

  group('WaliLinkedPerson', () {
    test('renders the current active-period date without relative drift', () {
      final person = WaliLinkedPerson(
        id: 'guardian-1',
        firstName: 'Abdul',
        linkedAt: DateTime.utc(2026, 8, 30),
      );

      expect(person.linkedDateLabel, '30 Aug 2026');
    });
  });

  group('permanent ZYRA Code models', () {
    test('accepts only the governed 80-bit display shape', () {
      final code = ZyraPersonalCode.fromRow({
        'code': 'ZYRA-1A2B-3C4D-5E6F-7788-9900',
        'role_context': 'seeker',
      });

      expect(code?.roleContext, 'seeker');
      expect(
        ZyraPersonalCode.fromRow({
          'code': 'ZYRA-1234',
          'role_context': 'seeker',
        }),
        isNull,
      );
    });

    test('preview contains first name and role only', () {
      final preview = ZyraPersonalCodePreview.fromRow({
        'owner_first_name': 'Adam',
        'owner_role': 'wali',
        'photo_url': 'must-be-ignored',
        'verified': true,
      });

      expect(preview?.firstName, 'Adam');
      expect(preview?.role, 'wali');
    });
  });

  group('GuardianHistoryConsentState', () {
    test('accepts the authoritative Main-bound result shape', () {
      final state = GuardianHistoryConsentState.fromRow({
        'enabled': true,
        'active_main_link_id': 'link-1',
        'main_guardian_id': 'guardian-1',
      });

      expect(state?.enabled, isTrue);
      expect(state?.activeGuardianLinkId, 'link-1');
      expect(state?.guardianId, 'guardian-1');
      expect(state?.guardianIsMain, isTrue);
    });

    test('accepts the authoritative per-Guardian result shape', () {
      final state = GuardianHistoryConsentState.fromRow({
        'enabled': true,
        'active_guardian_link_id': 'link-2',
        'guardian_id': 'guardian-2',
        'guardian_is_main': false,
      });

      expect(state?.enabled, isTrue);
      expect(state?.activeGuardianLinkId, 'link-2');
      expect(state?.guardianId, 'guardian-2');
      expect(state?.guardianIsMain, isFalse);
    });

    test('accepts authoritative no-Main OFF and rejects contradictions', () {
      expect(
        GuardianHistoryConsentState.fromRow({
          'enabled': false,
          'active_main_link_id': null,
          'main_guardian_id': null,
        }),
        isNotNull,
      );
      expect(
        GuardianHistoryConsentState.fromRow({
          'enabled': true,
          'active_main_link_id': null,
          'main_guardian_id': null,
        }),
        isNull,
      );
      expect(
        GuardianHistoryConsentState.fromRow({
          'enabled': false,
          'active_main_link_id': 'link-1',
          'main_guardian_id': null,
        }),
        isNull,
      );
    });
  });

  group('GuardianJourneyAccessState', () {
    for (final main in [false, true]) {
      test(
        'Basic or unproven ${main ? 'Main' : 'Additional'} retains View, not Chat',
        () {
          for (final entitlement in [null, false]) {
            final state = GuardianJourneyAccessState.fromRow({
              'attempt_id': 'attempt-1',
              'match_id': 'match-1',
              'counterpart_first_name': 'Maryam',
              'included': true,
              'can_change': !main,
              'guardian_is_main': main,
              'chat_available': true,
              'chat_enabled': true,
              'guardian_chat_entitled': ?entitlement,
            });
            expect(state?.included, isTrue);
            expect(state?.chatAvailable, isFalse);
            expect(state?.chatEnabled, isFalse);
          }
        },
      );
    }

    test(
      'confirmed One chat still requires View and current chat availability',
      () {
        Map<String, dynamic> row(bool available) => {
          'attempt_id': 'attempt-1',
          'match_id': 'match-1',
          'counterpart_first_name': 'Maryam',
          'included': true,
          'can_change': true,
          'guardian_is_main': false,
          'chat_available': available,
          'chat_enabled': true,
          'guardian_chat_entitled': true,
        };
        expect(
          GuardianJourneyAccessState.fromRow(row(true))?.chatEnabled,
          isTrue,
        );
        expect(
          GuardianJourneyAccessState.fromRow(row(false))?.chatEnabled,
          isFalse,
        );
        expect(
          GuardianJourneyAccessState.fromRow({...row(true), 'included': false}),
          isNull,
        );
        expect(
          GuardianJourneyAccessState.fromRow({
            ...row(true),
            'guardian_chat_entitled': 'One',
          }),
          isNull,
        );
      },
    );

    test('accepts a server-confirmed Additional Guardian assignment', () {
      final state = GuardianJourneyAccessState.fromRow({
        'attempt_id': 'attempt-1',
        'match_id': 'match-1',
        'counterpart_first_name': 'Maryam',
        'included': true,
        'can_change': true,
        'guardian_is_main': false,
      });

      expect(state?.counterpartFirstName, 'Maryam');
      expect(state?.included, isTrue);
      expect(state?.canChange, isTrue);
    });

    test('rejects a changeable or excluded Main Guardian', () {
      Map<String, dynamic> row({
        required bool included,
        required bool change,
      }) => {
        'attempt_id': 'attempt-1',
        'match_id': 'match-1',
        'counterpart_first_name': 'Maryam',
        'included': included,
        'can_change': change,
        'guardian_is_main': true,
      };

      expect(
        GuardianJourneyAccessState.fromRow(row(included: true, change: false)),
        isNotNull,
      );
      expect(
        GuardianJourneyAccessState.fromRow(row(included: false, change: false)),
        isNull,
      );
      expect(
        GuardianJourneyAccessState.fromRow(row(included: true, change: true)),
        isNull,
      );
    });
  });

  group('GuardianActivity', () {
    final occurredAt = DateTime.utc(2026, 8, 28, 12);

    GuardianActivity activity(String type, {String? detail}) =>
        GuardianActivity(
          waliId: 'guardian-1',
          type: type,
          occurredAt: occurredAt,
          detail: detail,
        );

    test('uses the agreed privacy-safe wording for all four types', () {
      expect(activity('linked').line, 'Guardian link active');
      expect(
        activity('suggested', detail: 'Third Party').line,
        'Shared a profile suggestion',
      );
      expect(
        activity('review_answered', detail: 'pause').line,
        'Family Review completed',
      );
      expect(activity('review_waiting').line, 'Family Review is open');
    });

    test('summary never exposes suggestion name or raw review decision', () {
      final suggestion = activity('suggested', detail: 'Third Party');
      final review = activity('review_answered', detail: 'pause');

      expect(suggestion.line, isNot(contains('Third Party')));
      expect(review.line, isNot(contains('pause')));
    });

    test('unknown type is retained safely without exposing its raw code', () {
      final unknown = GuardianActivity.fromRow({
        'wali_id': 'guardian-1',
        'activity_type': 'future_private_event',
        'occurred_at': '2026-08-28T12:00:00Z',
        'detail': 'must not render',
      });

      expect(unknown, isNotNull);
      expect(unknown!.line, isNull);
      expect(unknown.timingLabel, isNull);
    });

    test('malformed identity, type and timestamp rows are rejected', () {
      expect(
        GuardianActivity.fromRow({
          'wali_id': null,
          'activity_type': 'linked',
          'occurred_at': '2026-08-28T12:00:00Z',
        }),
        isNull,
      );
      expect(
        GuardianActivity.fromRow({
          'wali_id': 'guardian-1',
          'activity_type': 7,
          'occurred_at': '2026-08-28T12:00:00Z',
        }),
        isNull,
      );
      expect(
        GuardianActivity.fromRow({
          'wali_id': 'guardian-1',
          'activity_type': 'linked',
          'occurred_at': 'not-a-date',
        }),
        isNull,
      );
    });

    test('timestamp labels preserve linked and review-open meaning', () {
      expect(activity('linked').timingLabel, startsWith('Linked '));
      expect(activity('review_waiting').timingLabel, startsWith('Opened '));
      expect(
        activity('review_answered').timingLabel,
        isNot(startsWith('Opened ')),
      );
    });
  });

  group('PendingInvite', () {
    test('malformed dates cannot become apparently valid invitations', () {
      expect(
        PendingInvite.fromRow({
          'token': 'ZYRA1234',
          'created_at': 'not-a-date',
          'expires_at': null,
        }),
        isNull,
      );
    });

    test('uses an injected comparison clock for expiry labels', () {
      final invite = PendingInvite(
        token: 'ZYRA1234',
        createdAt: DateTime.utc(2026, 8, 28),
        expiresAt: DateTime.utc(2026, 9, 2),
      );

      expect(invite.daysLeftAt(DateTime.utc(2026, 8, 30)), 3);
    });
  });
}
