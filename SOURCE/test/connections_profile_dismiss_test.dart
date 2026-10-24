import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/connections/connections_screen.dart';

void main() {
  const profile = SeekerProfile(
    id: 'connections-profile-test',
    firstName: 'Maryam',
    surnameLine: 'Hussain',
    age: 27,
    city: 'London',
    photos: [],
    gender: 'female',
  );

  Future<void> openProfile(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () =>
                    pushZyraConnectionsProfile(context, profile: profile),
                child: const Text('Open profile'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open profile'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Connections profile has no X or handle and dismisses only from the left edge',
    (tester) async {
      await openProfile(tester);

      expect(
        find.byKey(const ValueKey('connections-profile-swipe-handle')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('seeker-profile-close')), findsNothing);

      await tester.drag(
        find.byKey(const ValueKey('connections-profile-swipe-surface')),
        const Offset(0, 240),
      );
      await tester.pumpAndSettle();

      // Downward drags do not close the current swipe-only viewer.
      expect(find.text('Maryam'), findsOneWidget);
      final surface = tester.getRect(
        find.byKey(const ValueKey('connections-profile-swipe-surface')),
      );
      await tester.timedDragFrom(
        Offset(surface.left + 8, surface.top + surface.height * .4),
        const Offset(200, 0),
        const Duration(milliseconds: 450),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open profile'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('connections-profile-swipe-surface')),
        findsNothing,
      );
    },
  );

  testWidgets('short downward movement returns to the open profile', (
    tester,
  ) async {
    await openProfile(tester);

    await tester.drag(
      find.byKey(const ValueKey('connections-profile-swipe-surface')),
      const Offset(0, 28),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('connections-profile-swipe-surface')),
      findsOneWidget,
    );
    expect(find.text('Maryam'), findsOneWidget);
  });
}
