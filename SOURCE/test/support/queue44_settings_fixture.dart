// Test-only presentation selection. No application picker is provided.
import 'package:flutter/foundation.dart';

enum ZyraSettingsDesign { current, smoothCards }

abstract final class ZyraDevSettingsDesign {
  static final ValueNotifier<ZyraSettingsDesign> changes = ValueNotifier(
    ZyraSettingsDesign.current,
  );
  static ZyraSettingsDesign get current => changes.value;
  static void select(ZyraSettingsDesign design) => changes.value = design;
}
