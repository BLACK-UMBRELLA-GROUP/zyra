import 'package:flutter/services.dart' show appFlavor;

/// One active app identity; unsupported is a locked artifact, not another app.
enum ZyraAppVariant { production, unsupported }

/// Converts Flutter's compile-time flavor into ZYRA's security boundary.
///
/// Default and explicit production builds select ZYRA. Any other named flavor
/// is locked before backend startup; retired configuration cannot fall back.
abstract final class ZyraAppVariantPolicy {
  static ZyraAppVariant fromFlavor(String? flavor) {
    return flavor == null || flavor.isEmpty || flavor == 'production'
        ? ZyraAppVariant.production
        : ZyraAppVariant.unsupported;
  }

  static ZyraAppVariant get current => fromFlavor(appFlavor);
}
