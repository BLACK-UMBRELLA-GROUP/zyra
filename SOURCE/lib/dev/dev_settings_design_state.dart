import 'package:flutter/foundation.dart';

/// Local Founder comparison only. Ordinary builds always render the current
/// Settings design; changing this value never changes an account preference.
enum ZyraSettingsDesign { current, smoothCards }

abstract final class ZyraDevSettingsDesign {
  static final ValueNotifier<ZyraSettingsDesign> selection = ValueNotifier(
    ZyraSettingsDesign.current,
  );

  static ZyraSettingsDesign get current => selection.value;

  static void select(ZyraSettingsDesign design) => selection.value = design;
}
