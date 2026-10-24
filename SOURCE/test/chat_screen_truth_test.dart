import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/chat/chat_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_match_service.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';

const _profile = SeekerProfile(
  id: 'member',
  firstName: 'Aaliyah',
  age: 27,
  city: 'London',
  photos: [],
  gender: 'female',
);

void main() {
  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraInternalPreviewClient.finishSignOut();
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraInternalPreviewClient.finishSignOut();
  });

  testWidgets(
    'loading and unavailable chat cannot fabricate a message or send',
    (tester) async {
      final pending = Completer<String?>();
      var sends = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            withProfile: _profile,
            resolveConversation: (_) => pending.future,
            sendMessage: (_, _) async {
              sends++;
              return true;
            },
          ),
        ),
      );
      expect(find.text('Opening conversation…'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);
      expect(find.textContaining('excited to start'), findsNothing);
      pending.complete(null);
      await tester.pump();
      expect(find.text('Conversation unavailable'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);
      expect(sends, 0);
    },
  );

  testWidgets(
    'history failure is unavailable and retry can load a genuinely empty conversation',
    (tester) async {
      var reads = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            withProfile: _profile,
            resolveConversation: (_) async => 'conversation',
            loadMessages: (_) async => ++reads == 1
                ? const ZyraSourceResult.unavailable(
                    ZyraSourceFailure.requestFailed,
                  )
                : const ZyraSourceResult.available([]),
            incomingMessages: (_) => const Stream.empty(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Conversation unavailable'), findsOneWidget);
      expect(find.textContaining('Say Salam'), findsNothing);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(find.textContaining('Say Salam'), findsOneWidget);
      expect(find.textContaining('excited to start'), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, true);
    },
  );

  testWidgets(
    'a failed send preserves its draft and a concurrent incoming message',
    (tester) async {
      final sent = Completer<bool>();
      final incoming = StreamController<ZyraChatMessage>();
      addTearDown(incoming.close);
      var sends = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            withProfile: _profile,
            resolveConversation: (_) async => 'conversation',
            loadMessages: (_) async => const ZyraSourceResult.available([]),
            incomingMessages: (_) => incoming.stream,
            sendMessage: (_, _) {
              sends++;
              return sent.future;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'My draft');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send))
            .onPressed,
        isNull,
      );
      expect(sends, 1);
      incoming.add(
        ZyraChatMessage(
          id: 'received',
          text: 'Incoming while sending',
          fromMe: false,
          createdAt: DateTime.now(),
        ),
      );
      await tester.pump();
      sent.complete(false);
      await tester.pump();
      expect(find.text('Incoming while sending'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'My draft',
      );
      expect(find.textContaining("That didn't send"), findsOneWidget);
      expect(
        find.text('My draft'),
        findsOneWidget,
      ); // Only in the composer, not a fake sent bubble.
    },
  );

  testWidgets('acknowledged send preserves any newer draft typed in flight', (
    tester,
  ) async {
    final sent = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          withProfile: _profile,
          resolveConversation: (_) async => 'conversation',
          loadMessages: (_) async => const ZyraSourceResult.available([]),
          incomingMessages: (_) => const Stream.empty(),
          sendMessage: (_, _) => sent.future,
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'First message');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Next draft');
    sent.complete(true);
    await tester.pump();
    expect(find.text('First message'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Next draft',
    );
  });

  testWidgets(
    'Journey chat labels the sender and shows one truthful latest receipt',
    (tester) async {
      var markedRead = 0;
      final now = DateTime(2026, 9, 27, 12);
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            withProfile: _profile,
            resolveConversation: (_) async => 'conversation',
            loadMessages: (_) async => ZyraSourceResult.available([
              ZyraChatMessage(
                id: 'incoming-unread',
                text: 'Assalaamu alaikum',
                fromMe: false,
                createdAt: now.subtract(const Duration(minutes: 2)),
              ),
              ZyraChatMessage(
                id: 'mine-read',
                text: 'Wa alaikum assalaam',
                fromMe: true,
                createdAt: now.subtract(const Duration(minutes: 1)),
                readAt: now,
              ),
            ]),
            incomingMessages: (_) => const Stream.empty(),
            markMessagesRead: (_) async {
              markedRead++;
              return true;
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Aaliyah · Seeker'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('unread-messages-divider')),
        findsOneWidget,
      );
      expect(find.text('Seen by Aaliyah'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('message-read-receipt')),
        findsOneWidget,
      );
      expect(markedRead, 1);

      await tester.tap(find.byKey(const ValueKey('message-read-receipt')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('message-readers-sheet')),
        findsOneWidget,
      );
      expect(find.text('Aaliyah · Seeker'), findsWidgets);
    },
  );

  testWidgets('thrown read and send errors leave a retryable truthful state', (
    tester,
  ) async {
    var reads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          withProfile: _profile,
          resolveConversation: (_) async {
            if (++reads == 1) throw StateError('offline');
            return 'conversation';
          },
          loadMessages: (_) async => const ZyraSourceResult.available([]),
          incomingMessages: (_) => const Stream.empty(),
          sendMessage: (_, _) async => throw StateError('offline'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Conversation unavailable'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Still mine');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    expect(find.textContaining("That didn't send"), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Still mine',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'authorised local preview performs no conversation read or write',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraInternalPreviewClient.beginPreview();
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            withProfile: _profile,
            resolveConversation: (_) async => throw StateError('must not read'),
            sendMessage: (_, _) async => throw StateError('must not write'),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Local only');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump();
      expect(find.text('Local only'), findsOneWidget);
      expect(find.textContaining("That didn't send"), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'account replacement discards pending history and prevents sends',
    (tester) async {
      final history = Completer<ZyraSourceResult<List<ZyraChatMessage>>>();
      var sends = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            withProfile: _profile,
            resolveConversation: (_) async => 'old-conversation',
            loadMessages: (_) => history.future,
            incomingMessages: (_) => const Stream.empty(),
            sendMessage: (_, _) async {
              sends++;
              return true;
            },
          ),
        ),
      );
      await tester.pump();
      ZyraAccountState.resetForTesting();
      AppState.instance.resetForAccountChange();
      history.complete(
        ZyraSourceResult.available([
          ZyraChatMessage(
            id: 'old',
            text: 'Previous member private message',
            fromMe: false,
            createdAt: DateTime.now(),
          ),
        ]),
      );
      await tester.pump();
      expect(find.text('Previous member private message'), findsNothing);
      expect(find.text('Conversation unavailable'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);
      expect(sends, 0);
    },
  );
}
