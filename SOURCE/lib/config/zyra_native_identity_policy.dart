import 'zyra_app_variant.dart';

/// Cross-checks the compiled Dart flavor against the installed iOS identity.
///
/// Flutter's `appFlavor` is injected by the Flutter build command. A direct
/// Xcode archive can still select an iOS scheme without supplying that Dart
/// value, so the bundle identifier and display name are verified before any
/// backend connection is attempted.
abstract final class ZyraNativeIdentityPolicy {
  static const String productionBundleId = 'app.zyraconnect.zyra';
  static String expectedBundleId(ZyraAppVariant variant) => productionBundleId;

  static String expectedDisplayName(ZyraAppVariant variant) => 'ZYRA';

  static bool matches({
    required ZyraAppVariant variant,
    required Object? bundleId,
    required Object? displayName,
  }) =>
      variant == ZyraAppVariant.production &&
      bundleId == expectedBundleId(variant) &&
      displayName == expectedDisplayName(variant);
}
