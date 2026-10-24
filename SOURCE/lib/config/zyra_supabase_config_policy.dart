import 'zyra_app_variant.dart';

class ZyraSupabaseEndpoint {
  const ZyraSupabaseEndpoint({required this.url, required this.publishableKey});

  final String url;
  final String publishableKey;

  bool get isConfigured {
    final cleanUrl = url.trim();
    final cleanKey = publishableKey.trim();
    if (cleanUrl.isEmpty || cleanKey.isEmpty) return false;

    final lowerUrl = cleanUrl.toLowerCase();
    final lowerKey = cleanKey.toLowerCase();
    const placeholderMarkers = <String>{
      'your-project-ref',
      'your_project_ref',
      'your-anon-public-key',
      'your_anon_public_key',
      'your-publishable-key',
      'your_publishable_key',
      'placeholder',
    };
    if (placeholderMarkers.any(lowerUrl.contains) ||
        placeholderMarkers.any(lowerKey.contains)) {
      return false;
    }

    // Client builds must never accept a privileged key or fall back to a
    // legacy JWT API key. This validates key type, not server authenticity.
    if (!RegExp(r'^sb_publishable_[A-Za-z0-9_-]+$').hasMatch(cleanKey)) {
      return false;
    }

    final parsedUrl = Uri.tryParse(cleanUrl);
    return parsedUrl != null &&
        parsedUrl.scheme == 'https' &&
        parsedUrl.host.isNotEmpty;
  }
}

/// Pure build-time selection policy used by production code and unit tests.
abstract final class ZyraSupabaseConfigPolicy {
  static ZyraSupabaseEndpoint select({
    required ZyraAppVariant variant,
    required ZyraSupabaseEndpoint production,
  }) {
    return switch (variant) {
      ZyraAppVariant.production => production,
      ZyraAppVariant.unsupported => const ZyraSupabaseEndpoint(
        url: '',
        publishableKey: '',
      ),
    };
  }
}
