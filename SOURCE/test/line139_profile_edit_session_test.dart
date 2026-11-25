// LOCK 45 local edits must agree across the profile, signup and Bio readers.
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_request_account_session.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';

ZyraRequestAccountSession _session() => ZyraRequestAccountSession(
  canAct: () => true,
  palette: ZyraColors.currentDefaultPalette,
  hapticLevel: ZyraHapticLevel.subtle,
  goldEnabled: false,
);

ZyraCompatibilityDraft _preferences(String gender, {String? about}) {
  final draft = ZyraCompatibilityDraft.fromSnapshot(gender: gender);
  final question = draft.preferenceQuestionBank.firstWhere(
    (question) => question.showIf == null && question.options.isNotEmpty,
  );
  draft.savePreferenceQuestion(question, {
    question.options.first: TrafficLight.green,
  }, {});
  if (about != null) draft.answers['bio_about_me'] = about;
  return draft;
}

bool _signup(
  ZyraRequestAccountSession session, {
  required ZyraCompatibilityDraft preferences,
}) => session.applySignup(
  guardian: false,
  firstName: 'Aisha',
  surname: 'Rahman',
  age: 29,
  gender: preferences.gender!,
  city: 'Leeds',
  nationality: 'British',
  ethnicities: const ['British', 'Pakistani'],
  photos: const [],
  preferences: preferences,
);

void main() {
  test(
    'About edits reach signup and Journey Bio without replacing preferences',
    () async {
      final session = _session();
      addTearDown(session.dispose);
      final preferences = _preferences('male', about: 'Earlier words');
      preferences.answers['bio_fields'] = <String, String>{
        'occupation': 'Teacher',
      };
      preferences.answers['bio_visible_field_ids'] = <String>['occupation'];
      expect(
        await session.compatibility.save('draft-self', preferences),
        isTrue,
      );
      final before = (await session.compatibility.load('draft-self'))!;

      expect(
        session.editProfileDetails(
          guardian: false,
          about: 'A peaceful home and time with family.',
          city: 'Manchester',
          nationality: 'British',
          ethnicity: 'Pakistani',
        ),
        isTrue,
      );

      final saved = (await session.compatibility.load('draft-self'))!;
      expect(
        session.signupAbout(false),
        'A peaceful home and time with family.',
      );
      expect(saved.ch3Answers['bio_about_me'], session.signupAbout(false));
      expect(saved.journeyBio.aboutMe, session.signupAbout(false));
      expect(saved.journeyBio.fieldValues, before.journeyBio.fieldValues);
      expect(
        saved.journeyBio.visibleFieldIds,
        before.journeyBio.visibleFieldIds,
      );
      expect(saved.ch4Preferences, before.ch4Preferences);
      expect(saved.ch4HardRequirements, before.ch4HardRequirements);
    },
  );

  test(
    'Clear restores public profile facts and the previous canonical About',
    () async {
      final session = _session();
      addTearDown(session.dispose);
      final baseline = session.ownProfile(false);
      final original = _preferences('male', about: 'Original sample About');
      expect(await session.compatibility.save('draft-self', original), isTrue);
      final before = (await session.compatibility.load('draft-self'))!;

      expect(
        session.editProfileDetails(
          guardian: false,
          about: 'Temporary edited words',
          city: 'Birmingham',
          nationality: 'Indian',
          ethnicity: 'Indian',
        ),
        isTrue,
      );
      expect(session.ownProfile(false).city, 'Birmingham');
      expect(session.clearSignup(), isTrue);

      final restored = session.ownProfile(false);
      expect(restored.city, baseline.city);
      expect(restored.publicNationality, baseline.publicNationality);
      expect(restored.publicEthnicity, baseline.publicEthnicity);
      expect(session.signupAbout(false), isNull);
      final after = (await session.compatibility.load('draft-self'))!;
      expect(after.journeyBio.aboutMe, before.journeyBio.aboutMe);
      expect(after.ch3Answers['bio_about_me'], 'Original sample About');
      expect(after.ch4Preferences, before.ch4Preferences);
    },
  );

  test(
    'a fresh signup replaces earlier profile edits with its own public facts',
    () async {
      final session = _session();
      addTearDown(session.dispose);
      expect(
        session.editProfileDetails(
          guardian: false,
          about: 'Old local edit',
          city: 'Manchester',
          nationality: 'Indian',
          ethnicity: 'Indian',
        ),
        isTrue,
      );
      final next = _preferences('female', about: 'Fresh signup words');
      expect(_signup(session, preferences: next), isTrue);

      final profile = session.ownProfile(false);
      expect(profile.firstName, 'Aisha');
      expect(profile.surnameLine, 'Rahman');
      expect(profile.gender, 'female');
      expect(profile.age, 29);
      expect(profile.city, 'Leeds');
      expect(profile.publicNationality, 'British');
      expect(profile.publicEthnicity, 'British, Pakistani');
      expect(session.signupAbout(false), 'Fresh signup words');
      expect(
        (await session.compatibility.load('draft-self'))!.journeyBio.aboutMe,
        'Fresh signup words',
      );
    },
  );

  test(
    'female signup and later edits retain her actual partner applicability',
    () async {
      final session = _session();
      addTearDown(session.dispose);
      final female = ZyraCompatibilityDraft.fromSnapshot(gender: 'female');
      final expectedTotal = female.preferenceOptionCount;
      final femalePartnerQuestion = female.preferenceQuestionBank.firstWhere(
        (question) => question.id == 'ch3_q26',
      );
      final male = ZyraCompatibilityDraft.fromSnapshot(gender: 'male');
      final malePartnerQuestion = male.preferenceQuestionBank.firstWhere(
        (question) => question.id == 'ch3_q26',
      );
      expect(femalePartnerQuestion.genderVisibility, GenderVisibility.menOnly);
      expect(malePartnerQuestion.genderVisibility, GenderVisibility.womenOnly);
      expect(_signup(session, preferences: female), isTrue);
      expect(session.seekerGender, 'female');

      expect(
        session.editProfileDetails(
          guardian: false,
          about: 'Words from the female sample',
          city: 'Leeds',
          nationality: 'British',
          ethnicity: 'Pakistani',
        ),
        isTrue,
      );
      final draft = ZyraCompatibilityDraft.fromSnapshot(
        gender: session.seekerGender,
        snapshot: (await session.compatibility.load('draft-self'))!,
      );
      expect(draft.gender, 'female');
      expect(draft.preferenceOptionCount, expectedTotal);
      expect(
        draft.preferenceQuestionBank
            .where((q) => q.id == 'ch3_q26')
            .single
            .options,
        femalePartnerQuestion.options,
      );
      draft.applyConfirmedPreference(
        femalePartnerQuestion,
        femalePartnerQuestion.options.first,
        TrafficLight.green,
      );
      expect(await session.compatibility.save('draft-self', draft), isTrue);
      final reopened = ZyraCompatibilityDraft.fromSnapshot(
        gender: session.seekerGender,
        snapshot: (await session.compatibility.load('draft-self'))!,
      );
      expect(reopened.preferenceOptionCount, expectedTotal);
      expect(reopened.preferenceAnswerCount, 1);
      expect(reopened.valuesFor(femalePartnerQuestion), {
        femalePartnerQuestion.options.first: TrafficLight.green,
      });
      expect(reopened.answers['bio_about_me'], 'Words from the female sample');
    },
  );
}
