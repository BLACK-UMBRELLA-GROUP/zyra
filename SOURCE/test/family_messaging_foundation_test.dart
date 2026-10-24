import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_release_gates.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/services/zyra_family_messaging_service.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevScenario.instance.reset();
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDevScenario.instance.reset();
  });

  test(
    'production family messaging remains closed until migration cutover',
    () {
      expect(ZyraReleaseGates.familyMessagingEnabled, isFalse);
    },
  );

  test('circle access rejects malformed authority rows', () {
    expect(
      ZyraGuardianCircleAccess.fromRow({
        'thread_id': 'thread-1',
        'seeker_id': 'seeker-1',
        'seeker_first_name': 'Aaliyah',
        'participant_count': 3,
        'can_send': true,
        'muted': false,
        'access_reason': 'ready',
      }),
      isNotNull,
    );
    expect(
      ZyraGuardianCircleAccess.fromRow({
        'thread_id': 'thread-1',
        'seeker_id': 'seeker-1',
        'seeker_first_name': 'Aaliyah',
        'participant_count': 3,
        'can_send': 'yes',
        'muted': false,
        'access_reason': 'ready',
      }),
      isNull,
    );
  });

  test('circle participant rows preserve role and current-user truth', () {
    final participant = ZyraFamilyCircleParticipant.fromRow({
      'user_id': 'guardian-1',
      'first_name': 'Abdul',
      'member_role': 'guardian',
      'is_main_guardian': true,
      'is_current_user': true,
    });
    expect(participant?.roleLabel, 'Main Guardian');
    expect(participant?.isCurrentUser, isTrue);
    expect(
      ZyraFamilyCircleParticipant.fromRow({
        'user_id': 'guardian-1',
        'first_name': 'Abdul',
        'member_role': 'admin',
        'is_main_guardian': true,
        'is_current_user': true,
      }),
      isNull,
    );
  });

  test('message rows preserve the sender relationship and Circle role', () {
    final message = ZyraFamilyMessage.fromRow({
      'message_id': 'message-1',
      'sender_id': 'guardian-1',
      'sender_first_name': 'Abdul',
      'sender_relationship': 'father',
      'sender_role_label': 'Main Guardian',
      'kind': 'message',
      'body': 'Wa alaikum assalaam.',
      'created_at': '2026-09-26T14:00:00Z',
      'read_by': [
        {
          'user_id': 'seeker-1',
          'first_name': 'Aaliyah',
          'role_label': 'Seeker',
          'read_at': '2026-09-26T14:01:00Z',
        },
      ],
      'unread_for_me': true,
    });

    expect(message, isNotNull);
    expect(message?.senderIdentityLabel, 'Abdul · Father · Main Guardian');
    expect(message?.readBy.single.firstName, 'Aaliyah');
    expect(message?.unreadForMe, isTrue);
  });

  testWidgets('developer preview sends locally with optional person context', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraFamilyMessageContext? openedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: ZyraGuardianCircleScreen(
          seekerId: 'dev-seeker-aaliyah',
          seekerFirstName: 'Aaliyah',
          preview: true,
          onOpenContext: (value) => openedContext = value,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Guardian Circle'), findsOneWidget);
    expect(find.text('3 members'), findsOneWidget);
    expect(find.textContaining('Private circle'), findsNothing);
    expect(find.text('Aaliyah · Seeker'), findsOneWidget);
    expect(find.text('Abdul · Father · Main Guardian'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('unread-messages-divider')),
      findsOneWidget,
    );
    expect(find.text('Seen by everyone'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('message-read-receipt')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('message-readers-sheet')), findsOneWidget);
    expect(find.text('Read by'), findsOneWidget);
    await tester.tapAt(const Offset(6, 6));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsNothing);
    expect(find.byKey(const ValueKey('circle_header_members')), findsOneWidget);
    expect(find.byTooltip('Mute circle notifications'), findsNothing);
    expect(find.byIcon(Icons.groups_2_outlined), findsNothing);

    await tester.tap(find.byKey(const ValueKey('circle_header_members')));
    await tester.pumpAndSettle();
    expect(find.text('Circle members'), findsOneWidget);
    expect(find.text('Seeker'), findsOneWidget);
    expect(find.text('Main Guardian'), findsOneWidget);
    expect(find.text('Additional Guardian'), findsOneWidget);
    await tester.tapAt(const Offset(6, 6));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Unmute circle notifications'), findsNothing);
    expect(find.text('Circle notifications muted.'), findsNothing);
    expect(find.text('Circle notifications on.'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('open-message-context-dev-active-h')),
    );
    await tester.pump();
    expect(openedContext?.referenceId, 'dev-active-h');

    await tester.tap(find.byTooltip('Discuss someone'));
    await tester.pumpAndSettle();
    expect(find.text('Discuss someone'), findsOneWidget);
    expect(find.text('ACTIVE JOURNEYS'), findsOneWidget);
    expect(find.text('POTENTIAL'), findsOneWidget);
    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('ENDED'), findsOneWidget);
    expect(
      find.text('Archived history is never available here.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Potential'));
    await tester.pumpAndSettle();
    expect(find.text('M.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'A local family message');
    await tester.ensureVisible(find.byTooltip('Send message'));
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('A local family message'), findsOneWidget);
    expect(find.text('M.'), findsOneWidget);
    expect(find.text('Sent'), findsOneWidget);
    expect(find.text('Seen by everyone'), findsNothing);
  });

  test('migration exposes reads but keeps all writes behind RPCs', () {
    final sql = File(
      'supabase/migrations/'
      '20260919185927_oa298_family_messaging_foundation.sql',
    ).readAsStringSync().toLowerCase();
    expect(sql, contains('enable row level security'));
    expect(sql, contains('family_message_threads_active_member_read'));
    expect(sql, contains('family_messages_active_epoch_read'));
    expect(sql, contains('zyra_family_message_circle_can_send'));
    expect(sql, contains('family_message_memberships'));
    expect(sql, contains('readable_from'));
    expect(sql, contains('left_at is null'));
    expect(sql, isNot(contains('guardian_id uuid not null')));
    expect(sql, contains("interval '1 minute'"));
    expect(sql, contains("interval '1 hour'"));
    expect(sql, contains('revoke all on public.family_messages'));
    expect(sql, isNot(contains('grant insert on public.family_messages')));
    expect(sql, isNot(contains('grant update on public.family_messages')));
    expect(sql, isNot(contains('grant delete on public.family_messages')));
  });

  test('participant-list RPC is scoped to the caller membership', () {
    final sql = File(
      'supabase/migrations/'
      '20260925215350_family_circle_participant_list.sql',
    ).readAsStringSync().toLowerCase();
    expect(sql, contains('zyra_family_message_participants'));
    expect(sql, contains('caller.user_id = (select auth.uid())'));
    expect(sql, contains('caller.left_at is null'));
    expect(sql, contains('member.left_at is null'));
    expect(sql, contains('from public, anon'));
    expect(sql, contains('to authenticated'));
  });

  test('message identity RPC keeps the existing Circle read boundary', () {
    final sql = File(
      'supabase/migrations/'
      '20260926144532_family_message_sender_identity.sql',
    ).readAsStringSync().toLowerCase();
    expect(sql, contains('zyra_family_messages_v2'));
    expect(sql, contains('sender_relationship'));
    expect(sql, contains('sender_role_label'));
    expect(sql, contains("link.status = 'active'"));
    expect(sql, contains('membership.user_id = (select auth.uid())'));
    expect(sql, contains('message.created_at >= membership.readable_from'));
    expect(sql, contains('from public, anon'));
    expect(sql, contains('to authenticated'));
  });

  test('message receipt RPCs preserve participant authority boundaries', () {
    final sql = File(
      'supabase/migrations/20260926233533_message_read_receipts.sql',
    ).readAsStringSync().toLowerCase();
    expect(sql, contains('zyra_mark_journey_messages_read'));
    expect(sql, contains('v_caller in (match.seeker_a_id, match.seeker_b_id)'));
    expect(sql, contains('message.sender_id <> v_caller'));
    expect(sql, contains('zyra_family_messages_v3'));
    expect(sql, contains('read_by jsonb'));
    expect(sql, contains('unread_for_me boolean'));
    expect(sql, contains('membership.user_id = (select auth.uid())'));
    expect(sql, contains('message.created_at >= membership.readable_from'));
    expect(sql, contains('message.sender_id = (select auth.uid())'));
    expect(sql, contains('from public, anon'));
    expect(sql, contains('to authenticated'));
  });

  test(
    'Circle message attribution permits the declared deletion behaviour',
    () {
      final sql = File(
        'supabase/migrations/'
        '20260919185927_oa298_family_messaging_foundation.sql',
      ).readAsStringSync().toLowerCase();
      expect(
        sql,
        contains(
          'sender_id uuid references public.profiles(id) on delete set null',
        ),
      );
      expect(
        sql,
        isNot(contains("kind = 'message' and sender_id is not null")),
      );
      expect(sql, contains("kind = 'lifecycle' and sender_id is null"));
      expect(
        sql,
        contains("if v_me is null then raise exception 'not_signed_in'"),
      );
      expect(sql, contains('values (p_thread, v_me, v_body)'));
    },
  );

  test('Circle send budget serialises by sender before locking the thread', () {
    final sql = File(
      'supabase/migrations/'
      '20260919185927_oa298_family_messaging_foundation.sql',
    ).readAsStringSync().toLowerCase();
    final send = sql.split(
      'create function public.zyra_send_family_message',
    )[1];
    final lock = send.indexOf('pg_catalog.pg_advisory_xact_lock');
    expect(lock, greaterThanOrEqualTo(0));
    expect(send, contains('pg_catalog.hashtextextended(v_me::text, 298)'));
    expect(lock, lessThan(send.indexOf('for update')));
    expect(lock, lessThan(send.indexOf("interval '1 minute'")));
  });

  test(
    'Circle open uses a constraint name distinct from its output variable',
    () {
      final sql = File(
        'supabase/migrations/'
        '20260919185927_oa298_family_messaging_foundation.sql',
      ).readAsStringSync().toLowerCase();
      expect(
        sql,
        contains(
          'on conflict on constraint '
          'family_message_threads_one_circle_per_seeker',
        ),
      );
      expect(sql, contains('returning circle.id into v_thread'));
      expect(sql, isNot(contains('on conflict (seeker_id)')));
    },
  );
}
