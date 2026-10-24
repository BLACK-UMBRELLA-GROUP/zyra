import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/help_content.dart';

void main() {
  test(
    'support and data-rights guidance has no invented staffing or restart promise',
    () {
      String answer(String question) => zyraHelpCategories
          .expand((category) => category.entries)
          .singleWhere((entry) => entry.question == question)
          .answer;
      final reporting = answer('How do I report someone?');
      expect(reporting, contains('does not mean someone has reviewed it'));
      expect(reporting, contains('not emergency services'));
      expect(reporting, isNot(contains('a person will read it')));
      expect(
        answer('How do I delete my account?'),
        contains('Profile › Settings › Account › Advanced › Delete account'),
      );
      expect(
        answer('Can I change my date of birth?'),
        contains('request a review'),
      );
      expect(
        answer('What happens when a Journey ends?'),
        contains('not available in this build'),
      );
    },
  );
  test(
    'Guardian help reflects both Seeker surfaces without inventing authority',
    () {
      final answer = zyraHelpCategories
          .expand((c) => c.entries)
          .singleWhere((e) => e.question == 'Who needs a Guardian?')
          .answer;
      expect(answer, contains('Seekers can use the Guardian section'));
      expect(answer, isNot(contains('will not apply to you')));
      expect(answer, contains('never grants relationship authority'));
    },
  );

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
    expect(answer, contains('not available in this build'));
  });
}
