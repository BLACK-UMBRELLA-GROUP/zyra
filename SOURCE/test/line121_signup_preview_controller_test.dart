import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_local_code_aliases.dart';
import 'package:zyra/dev/zyra_signup_preview_controller.dart';

ZyraSignupPreviewController _controller() =>
    ZyraSignupPreviewController(now: () => DateTime(2026, 11, 19));

void _birthday(
  ZyraSignupPreviewController c,
  String day,
  String month,
  String year,
) {
  c.setDay(day);
  c.setMonth(month);
  c.setYear(year);
}

void main() {
  test(
    'Seeker follows all signup and setup steps without activating a plan',
    () {
      final c = _controller();
      addTearDown(c.dispose);
      c.finishSplash();
      c.chooseProvider('Apple');
      expect(c.step, ZyraSignupStep.role);
      c.advance();
      expect(c.firstName, 'Adam');
      c.advance();
      expect(c.step, ZyraSignupStep.dateOfBirth);
      c.advance();
      expect(c.step, ZyraSignupStep.dateOfBirth);
      _birthday(c, '14', '03', '1997');
      c.advance();
      c.setGender('male');
      c.advance();
      c.setLocation('London, United Kingdom');
      c.advance();
      c.setNationality('British');
      c.advance();
      c.toggleEthnicity('British');
      c.toggleEthnicity('Pakistani');
      c.advance();
      c.addPhoto('data:image/png;base64,sample');
      c.advance();
      expect(c.step, ZyraSignupStep.verify);
      c.verifyNow();
      expect(c.verified, isTrue);
      expect(c.step, ZyraSignupStep.membership);
      c.advance();
      expect(c.step, ZyraSignupStep.membership);
      expect(c.hasAccount, isFalse);
      c.skip();
      expect(c.hasAccount, isTrue);
      expect(c.step, ZyraSignupStep.accountReady);
      c.resumeSetup();
      expect(c.step, ZyraSignupStep.preferences);
      c.advance();
      expect(c.step, ZyraSignupStep.aboutYou);
      c.advance();
      expect(c.step, ZyraSignupStep.addGuardian);
      expect(c.setupComplete, isFalse);
      c.advance();
      expect(c.step, ZyraSignupStep.allSet);
      expect(c.setupComplete, isTrue);
      expect(c.enterZyra(), isTrue);
    },
  );

  test(
    'Guardian uses only the existing local Seeker fixture and has no plan step',
    () {
      final c = _controller();
      addTearDown(c.dispose);
      c.finishSplash();
      c.chooseProvider('Google');
      c.setGuardian(true);
      c.advance();
      c.advance();
      _birthday(c, '01', '01', '1970');
      c.advance();
      expect(c.step, ZyraSignupStep.relationship);
      c.setRelationship('Father');
      c.advance();
      expect(c.step, ZyraSignupStep.addSeeker);
      c.setSeekerCode('ZYRA-FFFF-FFFF-FFFF-FFFF-FFFF');
      expect(c.linkedSeekerName, isNull);
      expect(c.canContinue, isFalse);
      c.setSeekerCode(ZyraLocalCodeAliases.master);
      expect(c.pendingSeekerName, 'Adam');
      expect(c.linkedSeekerName, isNull);
      c.advance();
      c.verifyNow();
      expect(c.linkedSeekerName, 'Adam');
      expect(c.step, ZyraSignupStep.accountReady);
      c.resumeSetup();
      expect(c.step, ZyraSignupStep.aboutYou);
      c.advance();
      expect(c.step, ZyraSignupStep.allSet);
      expect(c.setupComplete, isTrue);
    },
  );

  test(
    'Verify later skips plans; later verification keeps completed setup usable',
    () {
      final c = _controller();
      addTearDown(c.dispose);
      c.seedSetup(guardian: false, verified: false);
      c.setStep(ZyraSignupStep.verify);
      c.verifyLater();
      expect(c.step, ZyraSignupStep.verify);
      expect(c.verificationDeferred, isTrue);
      c.advance();
      expect(c.step, ZyraSignupStep.accountReady);
      expect(c.verified, isFalse);
      c.setStep(ZyraSignupStep.membership);
      expect(c.step, ZyraSignupStep.accountReady);
      c.resumeSetup();
      c.advance();
      c.advance();
      c.advance();
      expect(c.setupComplete, isTrue);
      expect(c.verified, isFalse);
      c.setStep(ZyraSignupStep.verify);
      c.verifyNow();
      c.skip();
      expect(c.step, ZyraSignupStep.accountReady);
      c.resumeSetup();
      expect(c.step, ZyraSignupStep.allSet);
      expect(c.setupComplete, isTrue);
      expect(c.enterZyra(), isTrue);
    },
  );

  test('Deferring verification waits for Continue and resets on return', () {
    for (final guardian in [false, true]) {
      final c = _controller();
      c.setGuardian(guardian);
      c.setStep(ZyraSignupStep.verify);
      c.verifyLater();
      expect(c.verificationDeferred, isTrue);
      expect(c.hasAccount, isFalse);
      expect(c.verified, isFalse);
      c.back();
      c.setStep(ZyraSignupStep.verify);
      expect(c.verificationDeferred, isFalse);
      c.verifyLater();
      c.advance();
      expect(c.step, ZyraSignupStep.accountReady);
      expect(c.hasAccount, isTrue);
      expect(c.verified, isFalse);
      c.start();
      expect(c.verificationDeferred, isFalse);
      c.dispose();
    }
  });

  test('Finish later resumes each exact setup step for either role', () {
    for (final guardian in [false, true]) {
      final c = _controller();
      c.seedSetup(guardian: guardian, verified: true);
      final steps = guardian
          ? [ZyraSignupStep.aboutYou]
          : [
              ZyraSignupStep.preferences,
              ZyraSignupStep.aboutYou,
              ZyraSignupStep.addGuardian,
            ];
      for (final step in steps) {
        c.setStep(step);
        c.pauseSetup();
        c.setStep(ZyraSignupStep.accountReady);
        c.resumeSetup();
        expect(c.step, step);
        expect(c.setupComplete, isFalse);
      }
      c.dispose();
    }
  });

  test('DOB validates the exact eighteenth birthday and calendar dates', () {
    final c = _controller();
    addTearDown(c.dispose);
    c.setStep(ZyraSignupStep.dateOfBirth);
    _birthday(c, '19', '11', '2008');
    expect(c.canContinue, isTrue);
    _birthday(c, '20', '11', '2008');
    expect(c.under18, isTrue);
    expect(c.dateError, 'You need to be 18 or over to join ZYRA.');
    _birthday(c, '31', '02', '1997');
    expect(c.dateOfBirth, isNull);
    expect(c.invalidCalendarDate, isTrue);
    expect(c.canContinue, isFalse);
    c.setYear('343');
    expect(c.yearError, 'Enter your year of birth in full, for example 1997.');
    c.setYear('1925');
    expect(c.yearError, isNotNull);
    c.setYear('2027');
    expect(c.yearError, isNotNull);
    c.setDay('32');
    expect(c.dayError, isNotNull);
    c.setMonth('13');
    expect(c.monthError, isNotNull);
  });

  test('existing names survive setup loading until that field is edited', () {
    final c = _controller();
    addTearDown(c.dispose);
    final firstName = 'A' * 35;
    final surname = 'B' * 45;
    c.seedSetup(
      guardian: false,
      verified: true,
      firstName: firstName,
      surname: surname,
    );
    c.resumeSetup();
    c.pauseSetup();
    expect(c.firstName, firstName);
    expect(c.surname, surname);
    c.setFirstName('C' * 31);
    expect(c.firstName, 'C' * 30);
    expect(c.surname, surname);
    c.setSurname('D' * 41);
    expect(c.surname, 'D' * 40);
  });

  test('Name and biography limits count displayed characters', () {
    final c = _controller();
    addTearDown(c.dispose);
    c.setFirstName(List.filled(31, 'é').join());
    c.setSurname(List.filled(41, 'a').join());
    c.setAboutYou(List.filled(301, 'b').join());
    expect(c.firstName.length, 30);
    expect(c.surname.length, 40);
    expect(c.aboutYou.length, 300);
    c.setStep(ZyraSignupStep.name);
    c.setFirstName('  ');
    expect(c.canContinue, isFalse);
  });

  test(
    'Screen positioning alone cannot complete setup; restart clears drafts',
    () {
      final c = _controller();
      addTearDown(c.dispose);
      c.seedSetup(guardian: false, verified: true);
      c.setStep(ZyraSignupStep.allSet);
      expect(c.setupComplete, isFalse);
      expect(c.enterZyra(), isFalse);
      c.addPhoto('https://example.org/member.jpg');
      expect(c.photos, isEmpty);
      c.start();
      expect(c.step, ZyraSignupStep.splash);
      expect(c.hasAccount, isFalse);
      expect(c.verified, isFalse);
      expect(c.firstName, isEmpty);
    },
  );
}
