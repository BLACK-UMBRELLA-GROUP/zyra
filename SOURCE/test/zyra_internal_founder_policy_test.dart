import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'package:zyra/services/zyra_developer_access.dart';

const _founder = ZyraInternalFounderPolicy.approvedFounderUserId;
const _endpoint = ZyraInternalFounderPolicy.approvedSupabaseUrl;
const _personal = '22222222-2222-4222-8222-222222222222';

bool _allows({
  ZyraAppVariant variant = ZyraAppVariant.production,
  bool enabled = true,
  String pin = _founder,
  String endpoint = _endpoint,
  Object? id = _founder,
  Object? metadata = const <String, dynamic>{'zyra_role': 'founder'},
  bool fresh = true,
}) => ZyraInternalFounderPolicy.allows(
  variant: variant,
  internalBuildEnabled: enabled,
  suppliedFounderUserId: pin,
  supabaseUrl: endpoint,
  userId: id,
  appMetadata: metadata,
  claimsAreFresh: fresh,
);

User _user(String id, Map<String, dynamic> metadata) => User(
  id: id,
  appMetadata: metadata,
  userMetadata: const {
    'email': 'admin@zyraconnect.app',
    'zyra_role': 'founder',
  },
  aud: 'authenticated',
  createdAt: '2026-09-12T00:00:00Z',
);

void main() {
  tearDown(ZyraDeveloperAccess.resetAuthorizationForTesting);

  test('exact internal main Founder with fresh protected role is admitted', () {
    expect(_allows(), isTrue);
  });

  test('ordinary/public builds and different flavours remain closed', () {
    expect(_allows(enabled: false), isFalse);
    expect(_allows(variant: ZyraAppVariant.unsupported), isFalse);
    expect(_allows(pin: ''), isFalse);
    expect(_allows(pin: _personal), isFalse);
    expect(_allows(endpoint: 'https://unapproved.supabase.co'), isFalse);
    expect(_allows(endpoint: '$_endpoint.attacker.test'), isFalse);
    expect(_allows(endpoint: _endpoint.replaceFirst('https', 'http')), isFalse);
  });

  test(
    'personal identity, editable email, malformed and stale claims deny',
    () {
      expect(_allows(id: _personal), isFalse);
      expect(_allows(id: null), isFalse);
      expect(_allows(fresh: false), isFalse);
      for (final metadata in <Object?>[
        null,
        'founder',
        <String, dynamic>{},
        {'email': 'admin@zyraconnect.app'},
        {'zyra_role': 'Founder'},
        {'zyra_role': 'developer'},
        {
          'zyra_role': ['founder'],
        },
      ]) {
        expect(_allows(metadata: metadata), isFalse);
      }
    },
  );

  test(
    'real refresh publishes Founder proof; personal login clears it',
    () async {
      User? current = _user(_founder, {'zyra_role': 'founder'});
      var refreshes = 0;
      ZyraDeveloperAccess.configureAuthorizationForTesting(
        variant: ZyraAppVariant.production,
        currentUser: () => current,
        refreshSession: () async {
          refreshes++;
          return current;
        },
        founderIdentityMatches: (user) =>
            _allows(id: user.id, metadata: user.appMetadata),
      );
      expect(ZyraDeveloperAccess.isAuthorizedOperator, isFalse);
      expect(await ZyraDeveloperAccess.refreshCurrentAuthorization(), isTrue);
      expect(refreshes, 1);
      current = _user(_personal, {'zyra_role': 'founder'});
      expect(ZyraDeveloperAccess.isAuthorizedOperator, isFalse);
      expect(await ZyraDeveloperAccess.refreshCurrentAuthorization(), isFalse);
      expect(ZyraDeveloperAccess.allowsDevPreview(true), isFalse);
    },
  );

  test(
    'revocation and failed refresh immediately remove Founder tools',
    () async {
      User? current = _user(_founder, {'zyra_role': 'founder'});
      var fail = false;
      ZyraDeveloperAccess.configureAuthorizationForTesting(
        variant: ZyraAppVariant.production,
        currentUser: () => current,
        refreshSession: () async {
          if (fail) throw StateError('offline');
          return current;
        },
        founderIdentityMatches: (user) =>
            _allows(id: user.id, metadata: user.appMetadata),
      );
      expect(await ZyraDeveloperAccess.refreshCurrentAuthorization(), isTrue);
      current = _user(_founder, {});
      expect(
        await ZyraDeveloperAccess.refreshAuthorizationAfterUserUpdated().then(
          (s) => s.founderAuthorized,
        ),
        isFalse,
      );
      current = _user(_founder, {'zyra_role': 'founder'});
      expect(await ZyraDeveloperAccess.refreshCurrentAuthorization(), isTrue);
      fail = true;
      final pending = ZyraDeveloperAccess.refreshCurrentAuthorization();
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      expect(await pending, isFalse);
    },
  );

  test(
    'late Founder refresh cannot grant access after a personal switch',
    () async {
      final founder = _user(_founder, {'zyra_role': 'founder'});
      User? current = founder;
      final pending = Completer<User?>();
      ZyraDeveloperAccess.configureAuthorizationForTesting(
        variant: ZyraAppVariant.production,
        currentUser: () => current,
        refreshSession: () => pending.future,
        founderIdentityMatches: (user) =>
            _allows(id: user.id, metadata: user.appMetadata),
      );
      final authorization = ZyraDeveloperAccess.refreshCurrentAuthorization();
      await Future<void>.delayed(Duration.zero);
      ZyraDeveloperAccess.clearRefreshedClaims();
      current = _user(_personal, {});
      pending.complete(founder);
      expect(await authorization, isFalse);
      expect(ZyraDeveloperAccess.isAuthorizedOperator, isFalse);
    },
  );
}
