import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/help_content.dart';

void main() {
  String answer(String question) => zyraHelpCategories
      .expand((category) => category.entries)
      .singleWhere((entry) => entry.question == question)
      .answer;

  test('LOCK43 report answer follows Q224 authority', () {
    expect(
      answer('How do I report someone?'),
      'Open their profile, tap ••• and choose Report. A person on the ZYRA team looks at every report within 24 hours. They are never told who reported them.',
    );
  });
  test('LOCK43 delete answer follows Q224 authority', () {
    expect(
      answer('How do I delete my account?'),
      'Settings → Advanced → Delete my account. Your profile disappears straight away, and you have 30 days to change your mind by signing in again.',
    );
    expect(
      answer('Can I change my date of birth?'),
      contains('request a review'),
    );
  });
  test('LOCK43 Journey end answer follows Q224 authority', () {
    expect(
      answer('What happens when a Journey ends?'),
      'The Journey moves to Ended Journeys with its Timeline, read only. The other person sees “Journey ended”, never a reason.',
    );
  });
  test('LOCK43 Guardian answer follows Q224 authority', () {
    expect(
      answer('Who needs a Guardian?'),
      'Every Seeker chooses a Main Guardian, usually a parent or family member, who is part of every Journey. You can add more Guardians and choose what each one sees.',
    );
  });

  test('Compatibility Unlock help explains one held product truthfully', () {
    final answer = zyraHelpCategories
        .expand((category) => category.entries)
        .singleWhere(
          (entry) => entry.question == 'What is Compatibility Unlock?',
        )
        .answer;

    expect(answer, contains('overall compatibility and a deeper breakdown'));
    expect(answer, contains('never shows either person’s private answers'));
    expect(answer, contains('authorised Guardian information'));
    expect(
      answer,
      contains('Earlier overall-only results and credits remain separate'),
    );
    expect(
      answer,
      contains('£2.99 for one, £6.99 for three or £9.99 for five'),
    );
    expect(answer, isNot(contains('Unlock+')));
    expect(answer, isNot(contains('£1.99')));
    expect(answer, contains('Purchasing unlocks is not available'));
  });
}
