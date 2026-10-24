import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_journey_presentation.dart';

void main() {
  test('requests remain requests and require explicit actor attribution', () {
    const verbs = {
      JourneyPresentationKind.startRequest: 'start',
      JourneyPresentationKind.continueRequest: 'continue',
      JourneyPresentationKind.resumeRequest: 'resume',
      JourneyPresentationKind.endRequest: 'end',
    };
    for (final entry in verbs.entries) {
      final starting = entry.key == JourneyPresentationKind.startRequest;
      expect(
        journeyPresentationTitle(
          entry.key,
          counterpartFirstName: 'Adam',
          actor: JourneyRequestActor.counterpart,
        ),
        starting
            ? 'Adam would like to start a Journey with you'
            : 'Adam would like to ${entry.value} your Journey',
      );
      expect(
        journeyPresentationTitle(entry.key, counterpartFirstName: 'Adam'),
        starting
            ? 'A request to start a Journey with Adam is ready to review'
            : 'A request to ${entry.value} your Journey with Adam is ready to review',
      );
      expect(
        journeyPresentationTitle(
          entry.key,
          counterpartFirstName: 'Adam',
          actor: JourneyRequestActor.viewer,
        ),
        starting
            ? 'You have asked to start a Journey with Adam'
            : 'You have asked to ${entry.value} your Journey with Adam',
      );
    }
  });

  test('confirmed changes do not claim who initiated them', () {
    const outcomes = {
      JourneyPresentationKind.started: 'has started',
      JourneyPresentationKind.resumed: 'has resumed',
      JourneyPresentationKind.paused: 'is paused',
      JourneyPresentationKind.ended: 'has ended',
    };
    for (final entry in outcomes.entries) {
      for (final actor in JourneyRequestActor.values) {
        expect(
          journeyPresentationTitle(
            entry.key,
            counterpartFirstName: 'Adam',
            actor: actor,
          ),
          'Your Journey with Adam ${entry.value}',
        );
      }
      expect(
        journeyPresentationTitle(entry.key),
        'Your Journey ${entry.value}',
      );
    }
  });

  test('missing names and placeholders use neutral copy', () {
    for (final name in <String?>[
      null,
      '',
      '   ',
      'Unknown',
      'Member',
      'Hidden profile',
      'Deleted account',
      '—',
    ]) {
      expect(journeyCounterpartFirstName(name), isNull);
      expect(
        journeyPresentationTitle(
          JourneyPresentationKind.endRequest,
          counterpartFirstName: name,
          actor: JourneyRequestActor.counterpart,
        ),
        'A request to end your Journey is ready to review',
      );
      expect(
        journeyPresentationTitle(
          JourneyPresentationKind.ended,
          counterpartFirstName: name,
        ),
        'Your Journey has ended',
      );
    }
  });

  test('first names preserve compounds and non-Latin scripts', () {
    expect(journeyCounterpartFirstName('  Mary Jane  '), 'Mary Jane');
    expect(journeyCounterpartFirstName('عائشة'), 'عائشة');
    expect(journeyCounterpartFirstName('Jo-Anne'), 'Jo-Anne');
  });
}
