import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/screens/onboarding/traffic_light_question_screen.dart';

void main() {
  testWidgets('records one explicit preference for every answer option', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const firstOption = 'Usually all five prayers';
    const secondOption = 'Some daily prayers';
    var values = <String, TrafficLight>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TrafficLightQuestionScreen(
              yourAnswer: '',
              yourAnswers: const {firstOption},
              options: const [firstOption, secondOption],
              hardRequirementSupported: false,
              onChanged: (updated) => values = updated,
              onHardRequirementChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(values, isEmpty, reason: 'Preferences must not be preselected.');
    expect(find.text('YOUR ANSWER'), findsOneWidget);
    expect(find.text('Prefer this'), findsNWidgets(2));
    expect(find.text('No preference'), findsNWidgets(2));
    expect(find.text('Not for me'), findsNWidgets(2));

    await tester.tap(
      find.byKey(const ValueKey('preference_${firstOption}_green')),
    );
    await tester.pump();

    expect(values, {firstOption: TrafficLight.green});
    expect(values.containsKey(secondOption), isFalse);
    expect(tester.takeException(), isNull);
  });
}
