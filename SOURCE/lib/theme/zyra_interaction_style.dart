import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../services/zyra_local_prefs.dart';

/// Session-only navigation comparisons available through Developer Style.
/// The existing floating glass treatment remains the production default.
enum ZyraNavStyle {
  floatingGlass(
    'Floating Glass · Current',
    'Breathing glass with a moving circular highlight',
  ),
  labelledDock('Labelled Dock', 'Dark dock with a white active label pill'),
  accentRing('Accent Ring', 'A clean ring follows the selected icon'),
  softTiles('Soft Tiles', 'Rounded translucent tiles with an accent selection'),
  goldUnderline('Gold Underline', 'Minimal icons with a fine moving underline'),
  raisedCapsule('Raised Capsule', 'A softly raised accent capsule'),
  quietDot('Quiet Dot', 'Low-chrome icons with one small position marker');

  final String label;
  final String detail;
  const ZyraNavStyle(this.label, this.detail);
}

/// Native feedback strengths exposed only for Founder device comparison.
/// Flutter does not provide an arbitrary motor-amplitude API, so each step
/// deliberately maps to an operating-system semantic haptic.
enum ZyraHapticLevel {
  off('Off'),
  subtle('Subtle'),
  light('Light'),
  medium('Medium'),
  strong('Strong');

  final String label;
  const ZyraHapticLevel(this.label);
}

class _SelectionTap {
  bool cancelled = false;
}

class ZyraInteractionStyle {
  ZyraInteractionStyle._();

  static final _selectionTap = Object();

  /// A physical or semantic activation owns feedback once, even when shared
  /// components delegate to another feedback-aware callback asynchronously.
  static void performSelectionTap(
    VoidCallback action, {
    ZyraHapticLevel? level,
  }) {
    if (Zone.current[_selectionTap] != null) {
      action();
      return;
    }
    final tap = _SelectionTap();
    runZoned(action, zoneValues: {_selectionTap: tap});
    if (!tap.cancelled) unawaited(emitSelectionHaptic(level: level));
  }

  /// A retained callback rejected by its owner is no longer an enabled tap.
  static void cancelSelectionTap() {
    final tap = Zone.current[_selectionTap];
    if (tap is _SelectionTap) tap.cancelled = true;
  }

  static const ZyraNavStyle currentDefaultNavStyle = ZyraNavStyle.floatingGlass;
  static const ZyraHapticLevel currentDefaultHapticLevel =
      ZyraHapticLevel.subtle;

  static final ValueNotifier<ZyraNavStyle> navStyleSelection =
      ValueNotifier<ZyraNavStyle>(currentDefaultNavStyle);
  static final ValueNotifier<ZyraHapticLevel> hapticLevelSelection =
      ValueNotifier<ZyraHapticLevel>(currentDefaultHapticLevel);

  static ZyraNavStyle get navStyle => navStyleSelection.value;
  static ZyraHapticLevel get hapticLevel => hapticLevelSelection.value;

  static void selectNavStyle(ZyraNavStyle style) {
    if (navStyleSelection.value != style) navStyleSelection.value = style;
  }

  static bool selectHapticLevel(ZyraHapticLevel level) {
    if (hapticLevelSelection.value == level) return false;
    hapticLevelSelection.value = level;
    return true;
  }

  /// Member-facing haptic choice. Selection remains a native semantic rather
  /// than a fabricated amplitude; persistence only remembers which semantic
  /// the member chose.
  static bool selectPersonalisationHapticLevel(ZyraHapticLevel level) {
    final changed = selectHapticLevel(level);
    ZyraLocalPrefs.setCachedHapticLevelName(level.name);
    return changed;
  }

  /// Hydrates before the first frame. Unknown values resolve to Subtle.
  static void restoreHapticLevel(String? storedName) {
    final restored = ZyraHapticLevel.values.where(
      (level) => level.name == storedName,
    );
    hapticLevelSelection.value = restored.isEmpty
        ? currentDefaultHapticLevel
        : restored.first;
  }

  static Future<void> emitSelectionHaptic({ZyraHapticLevel? level}) async {
    if (Zone.current[_selectionTap] != null) return;
    switch (level ?? hapticLevel) {
      case ZyraHapticLevel.off:
        return;
      case ZyraHapticLevel.subtle:
        await HapticFeedback.selectionClick();
      case ZyraHapticLevel.light:
        await HapticFeedback.lightImpact();
      case ZyraHapticLevel.medium:
        await HapticFeedback.mediumImpact();
      case ZyraHapticLevel.strong:
        await HapticFeedback.heavyImpact();
    }
  }

  static void restoreDefaults() {
    selectNavStyle(currentDefaultNavStyle);
    selectHapticLevel(currentDefaultHapticLevel);
  }
}
