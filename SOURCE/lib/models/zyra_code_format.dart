/// Raw code grammar from LOCK 9 V3. The HTTPS handoff needs a separately
/// approved path; a hostname by itself does not authorize parsing a URL.
abstract final class ZyraCodeFormat {
  static final _scanPattern = RegExp(
    r'^ZYRA-([A-Z0-9]{20}|[A-Z0-9]{4}(?:-[A-Z0-9]{4}){4})$',
    caseSensitive: false,
  );

  static String? scanned(String raw) {
    final value = raw.trim();
    final match = _scanPattern.firstMatch(value);
    if (match == null || match.end != value.length) return null;
    return grouped(match[1]!.replaceAll('-', '').toUpperCase());
  }

  static String grouped(String entry) =>
      'ZYRA-${List.generate(5, (i) => entry.substring(i * 4, i * 4 + 4)).join('-')}';

  static String? scanEntry(String raw) =>
      scanned(raw)?.substring(5).replaceAll('-', '');
}

const zyraCodeRateLimitSignal = 'too_many_code_checks';
const zyraCodeRateLimitMessage = 'Too many tries. Try again later.';

class ZyraCodeCheckFailure implements Exception {
  const ZyraCodeCheckFailure(this.message);
  final String message;
}
