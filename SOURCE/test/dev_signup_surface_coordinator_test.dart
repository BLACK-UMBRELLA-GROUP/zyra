import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/widgets/zyra_onboarding_study.dart';

// HomeShell/WaliHomeShell attach their State owner on mount and detach it on
// dispose. Exercise that exact registration lifecycle without backend clients.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final coordinator = ZyraDevSurfaceCoordinator.instance;

  setUp(coordinator.resetForTesting);
  tearDown(coordinator.resetForTesting);

  test('onboarding restart targets only the latest attached owner', () {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    addTearDown(ZyraDeveloperAccess.resetAuthorizationForTesting);
    final original = Object();
    final nested = Object();
    final events = <String>[];
    coordinator.attachOnboarding(
      original,
      (d) => events.add('original:${d.name}'),
    );
    coordinator.attachOnboarding(nested, (d) => events.add('nested:${d.name}'));
    expect(coordinator.restartOnboarding(ZyraOnboardingDirection.luma), isTrue);
    coordinator.detachOnboarding(nested);
    expect(coordinator.restartOnboarding(ZyraOnboardingDirection.luma), isTrue);
    coordinator.detachOnboarding(original);
    expect(
      coordinator.restartOnboarding(ZyraOnboardingDirection.luma),
      isFalse,
    );
    expect(events, ['nested:luma', 'original:luma']);
  });

  test('revoked onboarding restart and removed owners cannot be reused', () {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    addTearDown(ZyraDeveloperAccess.resetAuthorizationForTesting);
    final owner = Object();
    var calls = 0;
    coordinator.attachOnboarding(owner, (_) => calls++);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    expect(
      coordinator.restartOnboarding(ZyraOnboardingDirection.luma),
      isFalse,
    );
    coordinator.detachOnboarding(owner);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    expect(
      coordinator.restartOnboarding(ZyraOnboardingDirection.luma),
      isFalse,
    );
    expect(calls, 0);
  });

  test('Home Exit closes only the current top onboarding owner', () {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    addTearDown(ZyraDeveloperAccess.resetAuthorizationForTesting);
    final original = Object();
    final nested = Object();
    final events = <String>[];
    coordinator.attachOnboarding(
      original,
      (_) {},
      onClose: () => events.add('original'),
      isCurrent: () => true,
    );
    coordinator.attachOnboarding(
      nested,
      (_) {},
      onClose: () => events.add('nested'),
      isCurrent: () => true,
    );
    expect(coordinator.canCloseOnboarding, isTrue);
    expect(coordinator.closeOnboarding(), isTrue);
    expect(events, ['nested']);
    coordinator.detachOnboarding(nested);
    expect(coordinator.closeOnboarding(), isTrue);
    expect(events, ['nested', 'original']);
    coordinator.detachOnboarding(original);
    expect(coordinator.canCloseOnboarding, isFalse);
    expect(coordinator.closeOnboarding(), isFalse);
  });

  test('Home Exit never falls through a covered or non-closable top owner', () {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    addTearDown(ZyraDeveloperAccess.resetAuthorizationForTesting);
    final original = Object();
    final top = Object();
    var calls = 0;
    var current = false;
    coordinator.attachOnboarding(
      original,
      (_) {},
      onClose: () => calls++,
      isCurrent: () => true,
    );
    coordinator.attachOnboarding(
      top,
      (_) {},
      onClose: () => calls++,
      isCurrent: () => current,
    );
    expect(coordinator.canCloseOnboarding, isFalse);
    expect(coordinator.closeOnboarding(), isFalse);
    expect(calls, 0);
    current = true;
    expect(coordinator.closeOnboarding(), isTrue);
    expect(calls, 1);
    coordinator.attachOnboarding(top, (_) {});
    expect(coordinator.canCloseOnboarding, isFalse);
    expect(coordinator.closeOnboarding(), isFalse);
    expect(calls, 1);
  });

  test('revocation and detached onboarding owners deny Home Exit', () {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    addTearDown(ZyraDeveloperAccess.resetAuthorizationForTesting);
    final owner = Object();
    var calls = 0;
    coordinator.attachOnboarding(
      owner,
      (_) {},
      onClose: () => calls++,
      isCurrent: () => true,
    );
    final retained = coordinator.closeOnboarding;
    expect(coordinator.canCloseOnboarding, isTrue);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    expect(coordinator.canCloseOnboarding, isFalse);
    expect(retained(), isFalse);
    coordinator.detachOnboarding(owner);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    expect(coordinator.canCloseOnboarding, isFalse);
    expect(retained(), isFalse);
    expect(calls, 0);
  });

  test('a bound Home Exit cannot close a replacement or reattached owner', () {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    addTearDown(ZyraDeveloperAccess.resetAuthorizationForTesting);
    final original = Object();
    final replacement = Object();
    var originalCalls = 0;
    var replacementCalls = 0;
    coordinator.attachOnboarding(
      original,
      (_) {},
      onClose: () => originalCalls++,
      isCurrent: () => true,
    );
    final oldExit = coordinator.onboardingExit!;
    coordinator.attachOnboarding(
      replacement,
      (_) {},
      onClose: () => replacementCalls++,
      isCurrent: () => true,
    );
    expect(oldExit(), isFalse);
    expect([originalCalls, replacementCalls], [0, 0]);
    final newExit = coordinator.onboardingExit!;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    expect(newExit(), isFalse);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    coordinator.attachOnboarding(
      replacement,
      (_) {},
      onClose: () => replacementCalls++,
      isCurrent: () => true,
    );
    expect(newExit(), isFalse);
    expect(oldExit(), isFalse);
    expect([originalCalls, replacementCalls], [0, 0]);
    expect(coordinator.onboardingExit!(), isTrue);
    expect(replacementCalls, 1);
  });

  test('nested Seeker shell restores every invoking shell callback', () {
    final original = Object();
    final preview = Object();
    final events = <String>[];
    coordinator.attachSeeker(
      original,
      (page) => events.add('original:$page'),
      onOpenConnectionsSection: (section) => events.add('original:$section'),
      onOpenIntroductions: () => events.add('original:introductions'),
    );
    coordinator.beginEntryFlow('Sign up');
    coordinator.attachSeeker(
      preview,
      (page) => events.add('preview:$page'),
      onOpenConnectionsSection: (section) => events.add('preview:$section'),
      onOpenIntroductions: () => events.add('preview:introductions'),
    );
    expect(coordinator.surface, ZyraDevSurface.entry);
    expect(coordinator.entryLabel, 'Sign up');
    coordinator.openSeeker(DevPage.profile);
    coordinator.openSeekerConnectionsSection(1);
    coordinator.openSeekerIntroductions();
    expect(events, [
      'preview:${DevPage.profile}',
      'preview:1',
      'preview:introductions',
    ]);
    events.clear();
    coordinator.detachSeeker(preview);
    expect(coordinator.surface, ZyraDevSurface.entry);
    coordinator.endEntryFlow();
    expect(coordinator.surface, ZyraDevSurface.seeker);
    coordinator.openSeeker(DevPage.guardian);
    coordinator.openSeekerConnectionsSection(2);
    coordinator.openSeekerIntroductions();
    expect(events, [
      'original:${DevPage.guardian}',
      'original:2',
      'original:introductions',
    ]);
  });

  test('nested Guardian shell restores the invoking Guardian callback', () {
    final original = Object();
    final preview = Object();
    final events = <String>[];
    coordinator.attachGuardian(
      original,
      (page) => events.add('original:$page'),
    );
    coordinator.beginEntryFlow('Sign up');
    coordinator.attachGuardian(preview, (page) => events.add('preview:$page'));
    expect(coordinator.surface, ZyraDevSurface.entry);
    coordinator.openGuardian(WaliPage.network);
    expect(events, ['preview:${WaliPage.network}']);
    events.clear();
    coordinator.detachGuardian(preview);
    coordinator.endEntryFlow();
    expect(coordinator.surface, ZyraDevSurface.guardian);
    coordinator.openGuardian(WaliPage.seekers);
    expect(events, ['original:${WaliPage.seekers}']);
  });

  test('a Seeker disposed while covered is never resurrected after signup', () {
    final original = Object();
    final preview = Object();
    var originalCalls = 0;
    var previewCalls = 0;
    coordinator.attachSeeker(
      original,
      (_) => originalCalls++,
      onOpenConnectionsSection: (_) => originalCalls++,
      onOpenIntroductions: () => originalCalls++,
    );
    coordinator.beginEntryFlow('Sign up');
    coordinator.attachSeeker(preview, (_) => previewCalls++);
    coordinator.detachSeeker(original);
    coordinator.openSeeker(DevPage.profile);
    expect(previewCalls, 1);
    coordinator.detachSeeker(preview);
    coordinator.endEntryFlow();
    coordinator.openSeeker(DevPage.profile);
    coordinator.openSeekerConnectionsSection(1);
    coordinator.openSeekerIntroductions();
    expect(originalCalls, 0);
    expect(previewCalls, 1);
    expect(coordinator.surface, ZyraDevSurface.entry);
  });

  test(
    'a Guardian disposed while covered is never resurrected after signup',
    () {
      final original = Object();
      final preview = Object();
      var originalCalls = 0;
      var previewCalls = 0;
      coordinator.attachGuardian(original, (_) => originalCalls++);
      coordinator.beginEntryFlow('Sign up');
      coordinator.attachGuardian(preview, (_) => previewCalls++);
      coordinator.detachGuardian(original);
      coordinator.openGuardian(WaliPage.profile);
      expect(previewCalls, 1);
      coordinator.detachGuardian(preview);
      coordinator.endEntryFlow();
      coordinator.openGuardian(WaliPage.profile);
      expect(originalCalls, 0);
      expect(previewCalls, 1);
      expect(coordinator.surface, ZyraDevSurface.entry);
    },
  );

  test('out-of-order disposal restores the latest still-mounted Seeker', () {
    final original = Object();
    final middle = Object();
    final newest = Object();
    final events = <String>[];
    coordinator.attachSeeker(original, (_) => events.add('original'));
    coordinator.attachSeeker(middle, (_) => events.add('middle'));
    coordinator.attachSeeker(newest, (_) => events.add('newest'));
    coordinator.detachSeeker(middle);
    coordinator.openSeeker(DevPage.dashboard);
    coordinator.detachSeeker(newest);
    coordinator.openSeeker(DevPage.dashboard);
    expect(events, ['newest', 'original']);
    coordinator.detachSeeker(original);
    expect(coordinator.surface, ZyraDevSurface.entry);
  });

  test(
    'reattaching an owner updates recency without duplicate registrations',
    () {
      final original = Object();
      final preview = Object();
      final events = <String>[];
      coordinator.attachGuardian(original, (_) => events.add('original-old'));
      coordinator.attachGuardian(preview, (_) => events.add('preview'));
      coordinator.attachGuardian(original, (_) => events.add('original-new'));
      coordinator.openGuardian(WaliPage.dashboard);
      coordinator.detachGuardian(original);
      coordinator.openGuardian(WaliPage.dashboard);
      coordinator.detachGuardian(preview);
      coordinator.openGuardian(WaliPage.dashboard);
      expect(events, ['original-new', 'preview']);
      expect(coordinator.surface, ZyraDevSurface.entry);
    },
  );

  test(
    'signup entry override and existing cross-role precedence stay intact',
    () {
      final originalGuardian = Object();
      final previewSeeker = Object();
      final events = <String>[];
      coordinator.attachGuardian(
        originalGuardian,
        (_) => events.add('guardian'),
      );
      coordinator.beginEntryFlow('Sign up');
      coordinator.attachSeeker(previewSeeker, (_) => events.add('seeker'));
      expect(coordinator.surface, ZyraDevSurface.entry);
      expect(coordinator.entryLabel, 'Sign up');
      coordinator.endEntryFlow();
      expect(coordinator.surface, ZyraDevSurface.guardian);
      coordinator.detachSeeker(previewSeeker);
      coordinator.openGuardian(WaliPage.dashboard);
      expect(events, ['guardian']);
      coordinator.detachGuardian(originalGuardian);
      expect(coordinator.surface, ZyraDevSurface.entry);
    },
  );
}
