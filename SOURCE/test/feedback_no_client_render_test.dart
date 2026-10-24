import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/settings/feedback_screen.dart';

// Deliberately no Supabase.initialize(): startup/offline retained routes cannot
// manufacture a member owner or crash just because the client is unavailable.
void main() {
  testWidgets(
    'Feedback safely withdraws with no configured client',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: FeedbackScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Send'), findsNothing);
      expect(find.text('Thank you'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );
}
