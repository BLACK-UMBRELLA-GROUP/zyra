/// ZYRA Code input rules for camera capture and manual entry.
abstract final class ZyraCodeFormat {
  static final _scanPattern = RegExp(r'^ZYRA-[0-9A-F]{4}(?:-[0-9A-F]{4}){4}$');
  static final _manualPattern = RegExp(
    r'^ZYRA-([A-Z0-9]{20}|[A-Z0-9]{4}(?:-[A-Z0-9]{4}){4})$',
    caseSensitive: false,
  );

  static String? scanned(String raw) =>
      _scanPattern.firstMatch(raw)?.end == raw.length ? raw : null;

  static String? scanEntry(String raw) =>
      scanned(raw)?.substring(5).replaceAll('-', '');

  static String? manualEntry(String raw) {
    final value = raw.trim();
    final match = _manualPattern.firstMatch(value);
    if (match == null || match.end != value.length) return null;
    return match[1]!.replaceAll('-', '').toUpperCase();
  }

  static String grouped(String entry) =>
      'ZYRA-${List.generate(5, (i) => entry.substring(i * 4, i * 4 + 4)).join('-')}';

  // Older invite tokens are four random bytes encoded as uppercase hex.
  static final _legacyInvitePattern = RegExp(r'^[0-9A-Fa-f]{8}$');

  static String? legacyInvite(String raw) {
    final value = raw.trim();
    return _legacyInvitePattern.hasMatch(value) ? value.toUpperCase() : null;
  }
}

const zyraCodeRateLimitSignal = 'too_many_code_checks';
const zyraCodeRateLimitMessage = 'Too many tries. Try again later.';

class ZyraCodeCheckFailure implements Exception {
  const ZyraCodeCheckFailure(this.message);
  final String message;
}
