import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _dartFiles(Directory directory) sync* {
  for (final entity in directory.listSync(followLinks: false)) {
    final name = entity.uri.pathSegments
        .where((part) => part.isNotEmpty)
        .last
        .toUpperCase();
    if (name.startsWith('PRIVATE') ||
        (name.contains('API') && name.contains('KEY'))) {
      continue;
    }
    if (entity is Directory) {
      yield* _dartFiles(entity);
    } else if (entity is File && entity.path.endsWith('.dart')) {
      yield entity;
    }
  }
}

void main() {
  test('TestFlight developer surfaces use capability, not build mode', () {
    const capabilityGatedScreens = <String>[
      'lib/screens/wali/wali_network_screen.dart',
      'lib/screens/wali/wali_dashboard_screen.dart',
      'lib/screens/wali/wali_seekers_screen.dart',
      'lib/screens/wali/wali_journey_detail_screen.dart',
      'lib/screens/connections/connections_screen.dart',
      'lib/screens/settings/settings_screen.dart',
    ];
    for (final path in capabilityGatedScreens) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('kReleaseMode')), reason: path);
    }
  });

  test('an email domain is absent from the developer authorization gate', () {
    final source = File(
      'lib/services/zyra_developer_access.dart',
    ).readAsStringSync();
    expect(source, contains('ZyraInternalFounderPolicy.allows'));
    expect(source, isNot(contains('allowsSeededPersonaIdentity')));
    expect(source, isNot(contains("endsWith('@zyra.test')")));
  });

  test(
    'legacy live-account Journey jump controls and client helpers are absent',
    () {
      final source = File(
        'lib/screens/journey/journey_flow_screen.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('_isDevAccount')));
      expect(source, isNot(contains('_devJumpStage')));
      expect(source, isNot(contains('devSetStage(')));
      expect(source, isNot(contains("endsWith('@zyra.test')")));
    },
  );

  test('sign-out clears refreshed Founder proof on every path', () {
    final source = File('lib/services/zyra_auth.dart').readAsStringSync();
    final signOut = source.substring(
      source.indexOf('static Future<void> signOut('),
      source.indexOf('static Future<bool> deleteAccount('),
    );
    expect(
      'ZyraDeveloperAccess.clearRefreshedClaims()'.allMatches(signOut),
      hasLength(2),
    );
    expect(
      signOut.indexOf('ZyraDeveloperAccess.clearRefreshedClaims()'),
      lessThan(signOut.indexOf('if (_signingOut) return')),
    );
  });

  test('every onboarding preview leaf fails closed on capability loss', () {
    for (final path in const [
      'lib/screens/onboarding/onboarding_flow.dart',
      'lib/screens/onboarding/chapter2_flow.dart',
      'lib/screens/onboarding/bio_onboarding_flow.dart',
      'lib/screens/onboarding/values_preferences_flow.dart',
      'lib/screens/onboarding/profile_ready_screen.dart',
      'lib/screens/onboarding/account_path_overview_screen.dart',
      'lib/screens/wali/wali_onboarding_flow.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('ZyraDeveloperAccess.canUseDeveloperTools'),
        reason: path,
      );
      expect(source, contains('preview_denied'), reason: path);
      // Requested preview mode must stay latched after revocation. Turning
      // it into ordinary signup would make live account writes reachable.
      if (path == 'lib/screens/onboarding/chapter2_flow.dart') {
        expect(source, contains('bool get _devPreview => _openingDevPreview;'));
        expect(source, contains('_openingDevPreview = widget.devPreview;'));
        expect(source, contains('widget.devPreview != _openingDevPreview'));
        expect(source, contains('_photoOwnerRevoked = true;'));
      } else if (path !=
          'lib/screens/onboarding/account_path_overview_screen.dart') {
        expect(source, contains('bool get _devPreview => widget.devPreview;'));
      }
    }

    final identity = File(
      'lib/screens/onboarding/identity_verification_screen.dart',
    ).readAsStringSync();
    expect(identity, contains('bool get _isDevPreview => _previewMode;'));
    expect(identity, contains('_previewMode = widget.devPreview;'));
    expect(identity, contains('widget.devPreview != _previewMode'));
    expect(identity, contains('_modeRevoked = true;'));
    expect(
      identity,
      contains(
        'if (_isDevPreview && !ZyraDeveloperAccess.canUseDeveloperTools)',
      ),
    );

    expect(File('lib/dev/zyra_dev_signup.dart').existsSync(), isFalse);
  });

  test('app-wide owner refreshes and routes away after authority loss', () {
    final source = File(
      'lib/widgets/zyra_account_session_host.dart',
    ).readAsStringSync();
    expect(source, contains('ZyraDeveloperAccess.authorizationChanges'));
    expect(source, contains('AuthChangeEvent.tokenRefreshed'));
    expect(source, contains('didChangeAppLifecycleState'));
    expect(source, contains('refreshCurrentAuthorization()'));
    expect(source, contains('_redirectAfterAuthorityLoss'));
  });

  test('privileged developer services never trust build mode', () {
    for (final path in const [
      'lib/services/zyra_promotion_engine.dart',
      'lib/services/zyra_unlock_service.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('ZyraDeveloperAccess.canUseDeveloperTools'),
        reason: path,
      );
      expect(source, isNot(contains('kReleaseMode &&')), reason: path);
    }
  });

  test('real release error handling remains a build-mode concern', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('if (kReleaseMode)'));
    expect(source, contains('ErrorWidget.builder'));
  });

  test('Guardian shell removes its developer listener after claim loss', () {
    final source = File(
      'lib/screens/wali/wali_home_shell.dart',
    ).readAsStringSync();
    final start = source.indexOf('void dispose()');
    var cursor = source.indexOf('{', start) + 1;
    var depth = 1;
    for (; cursor < source.length && depth > 0; cursor++) {
      if (source[cursor] == '{') depth++;
      if (source[cursor] == '}') depth--;
    }
    expect(start, greaterThanOrEqualTo(0));
    expect(depth, 0);
    final dispose = source.substring(start, cursor);
    expect(
      dispose,
      contains('ZyraDevScenario.instance.removeListener(_onScenarioChange)'),
    );
    expect(
      dispose,
      isNot(contains('ZyraDeveloperAccess.canUseDeveloperTools')),
    );
  });

  test('ordinary product UI cannot add its own app-variant fork', () {
    const allowed = <String>{
      'lib/config/oauth_config.dart',
      'lib/config/supabase_config.dart',
      'lib/config/zyra_app_variant.dart',
      'lib/config/zyra_native_identity_policy.dart',
      'lib/config/zyra_supabase_config_policy.dart',
      'lib/config/zyra_internal_founder_policy.dart',
      'lib/widgets/zyra_account_session_host.dart',
      'lib/main.dart',
      'lib/services/zyra_developer_access.dart',
      'lib/services/zyra_internal_preview_client.dart',
    };
    final actual = <String>{};
    for (final entity in _dartFiles(Directory('lib'))) {
      final source = entity.readAsStringSync();
      if (!source.contains('ZyraAppVariant') &&
          !source.contains('zyra_app_variant.dart')) {
        continue;
      }
      actual.add(entity.path.replaceFirst('${Directory.current.path}/', ''));
    }

    expect(actual, allowed);
  });

  test('unsupported native identity has no backend or Welcome escape', () {
    final source = File('lib/main.dart').readAsStringSync();
    final gate = source.substring(
      source.indexOf('class _ZyraStartupGateState'),
    );
    expect(gate, contains('_NativeIdentityBlocked'));
    expect(
      gate.indexOf('_NativeIdentityBlocked'),
      lessThan(gate.indexOf('ZyraFullScreenError')),
    );
  });

  test(
    'retired Developer Access entries and destinations have no source route',
    () {
      for (final path in const [
        'lib/dev/dev_scenario_panel_v2.dart',
        'lib/dev/wali_dev_scenario_panel.dart',
        'lib/dev/zyra_global_dev_overlay.dart',
        'lib/screens/dev/developer_access_screen.dart',
      ]) {
        expect(File(path).existsSync(), isFalse, reason: path);
      }
    },
  );

  test(
    'demo ZYRA Codes require both Founder authority and preview isolation',
    () {
      final screen = File(
        'lib/screens/wali/zyra_code_screen.dart',
      ).readAsStringSync();
      expect(screen, contains('ZyraInternalPreviewClient.isActive &&'));
      expect(screen, contains('ZyraDeveloperAccess.isMainAppFounderPreview'));
      expect(screen, contains('ZyraDevPersonalCodeFixtures.forPersona'));

      final fixture = File(
        'lib/dev/zyra_dev_personal_code_fixtures.dart',
      ).readAsStringSync();
      expect(fixture, contains('ZYRA-DEMO-SEEKER-ADAM'));
      expect(fixture, isNot(contains("RegExp(r'^ZYRA-")));

      final policy = File(
        'lib/config/zyra_internal_founder_policy.dart',
      ).readAsStringSync();
      expect(
        policy,
        contains("bool.fromEnvironment('ZYRA_INTERNAL_FOUNDER_ACCESS')"),
      );
    },
  );
}
