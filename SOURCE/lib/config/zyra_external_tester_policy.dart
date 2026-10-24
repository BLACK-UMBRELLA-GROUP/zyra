import 'package:flutter/foundation.dart' show visibleForTesting;

/// Compile-time gate for a small, private TestFlight tester cohort.
///
/// This is deliberately separate from Founder access. A tester code can only
/// open the local preview fixtures in a build that was explicitly compiled
/// for the tester cohort; ordinary and public builds do not expose the entry.
abstract final class ZyraExternalTesterPolicy {
  static const _compiledEnabled = bool.fromEnvironment(
    'ZYRA_EXTERNAL_TESTER_ACCESS',
  );
  static const _compiledUsername = String.fromEnvironment(
    'ZYRA_EXTERNAL_TESTER_USERNAME',
    defaultValue: 'apple-review',
  );
  static const _compiledPassword = String.fromEnvironment(
    'ZYRA_EXTERNAL_TESTER_PASSWORD',
    defaultValue: 'ZYRA-TEST-01',
  );

  static bool? _enabledForTesting;
  static String? _usernameForTesting;
  static String? _passwordForTesting;

  static bool get enabled => _enabledForTesting ?? _compiledEnabled;
  static String get username => _usernameForTesting ?? _compiledUsername;
  static String get password => _passwordForTesting ?? _compiledPassword;

  @visibleForTesting
  static void setForTesting({
    bool? enabled,
    String? username,
    String? password,
  }) {
    _enabledForTesting = enabled;
    _usernameForTesting = username;
    _passwordForTesting = password;
  }
}
