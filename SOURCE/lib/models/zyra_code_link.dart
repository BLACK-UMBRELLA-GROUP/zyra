import 'zyra_code_format.dart';

const _codeLinkAddress = 'https://zyraconnect.app/c';

// Match the original address so URI normalization cannot hide extra syntax.
final _codeLinkPattern = RegExp(
  '^${RegExp.escape(_codeLinkAddress)}'
  r'/?#([A-Za-z0-9-]+)$',
);

/// Reads a shared ZYRA Code without loading the page or retaining the link.
String? parseZyraCodeLink(String rawLink) {
  final match = _codeLinkPattern.firstMatch(rawLink);
  if (match == null || match.end != rawLink.length) return null;
  return ZyraCodeFormat.scanned(match[1]!.toUpperCase());
}

/// Builds the canonical share address for a server-issued ZYRA Code.
String? zyraCodeLinkFor(String code) {
  final validatedCode = ZyraCodeFormat.scanned(code);
  if (validatedCode == null) return null;
  return '$_codeLinkAddress/#$validatedCode';
}
