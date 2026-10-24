import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/config/zyra_supabase_config_policy.dart';

void main() {
  const main = ZyraSupabaseEndpoint(
    url: 'https://main.supabase.co',
    publishableKey: 'sb_publishable_unit_test_only',
  );
  test('main configuration is selected unchanged', () {
    expect(
      ZyraSupabaseConfigPolicy.select(
        variant: ZyraAppVariant.production,
        production: main,
      ),
      same(main),
    );
  });
  test('unsupported artifacts have no endpoint or key, never a fallback', () {
    final selected = ZyraSupabaseConfigPolicy.select(
      variant: ZyraAppVariant.unsupported,
      production: main,
    );
    expect(selected.isConfigured, isFalse);
    expect(selected.url, isEmpty);
    expect(selected.publishableKey, isEmpty);
  });
  test('placeholder and missing configurations remain invalid', () {
    for (final endpoint in [
      const ZyraSupabaseEndpoint(url: '', publishableKey: ''),
      const ZyraSupabaseEndpoint(
        url: 'https://YOUR-PROJECT-REF.supabase.co',
        publishableKey: 'YOUR-PUBLISHABLE-KEY',
      ),
      const ZyraSupabaseEndpoint(
        url: 'http://main.supabase.co',
        publishableKey: 'sb_publishable_unit_test_only',
      ),
    ]) {
      expect(endpoint.isConfigured, isFalse);
    }
  });
  test('client configuration rejects privileged and legacy key types', () {
    expect(main.isConfigured, isTrue);
    for (final key in [
      'sb_secret_unit_test_only',
      'eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiJ9.not_a_real_signature',
      'not-a-publishable-key',
      'sb_publishable_',
    ]) {
      expect(
        ZyraSupabaseEndpoint(url: main.url, publishableKey: key).isConfigured,
        isFalse,
      );
    }
  });
}
