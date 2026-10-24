import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/config/supabase_config.dart';
import 'package:zyra/config/oauth_config.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';

void main() {
  test('compiled app boundary has exactly one backend or is locked', () {
    const flavor = String.fromEnvironment('FLUTTER_APP_FLAVOR');
    final expected = ZyraAppVariantPolicy.fromFlavor(flavor);
    expect(ZyraAppVariantPolicy.current, expected);
    if (expected == ZyraAppVariant.production) {
      expect(SupabaseConfig.url, ZyraInternalFounderPolicy.approvedSupabaseUrl);
      expect(SupabaseConfig.isConfigured, isTrue);
    } else {
      expect(SupabaseConfig.url, isEmpty);
      expect(SupabaseConfig.publishableKey, isEmpty);
      expect(SupabaseConfig.isConfigured, isFalse);
      expect(OAuthConfig.isGoogleConfigured, isFalse);
      expect(ZyraInternalPreviewClient.create(), isNull);
    }
  });
}
