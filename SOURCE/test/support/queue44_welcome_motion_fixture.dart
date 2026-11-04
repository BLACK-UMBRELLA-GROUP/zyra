// Code-only welcome-motion fixtures; no production selectors or controls.
import 'package:flutter/material.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/dev/dev_onboarding_welcome_motion.dart';
export 'package:zyra/dev/dev_onboarding_welcome_motion.dart';

abstract final class ZyraDevWelcomeTextMotion {
  static const defaultMotion = ZyraWelcomeTextMotion.slowDescent;
  static final ValueNotifier<ZyraWelcomeTextMotion> _selection = ValueNotifier(
    defaultMotion,
  );
  static int _accountGeneration = ZyraAccountState.generation;

  static Listenable get changes => _selection;
  static ZyraWelcomeTextMotion get current =>
      _accountGeneration == ZyraAccountState.generation
      ? _selection.value
      : defaultMotion;

  static bool select(ZyraWelcomeTextMotion motion) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return false;
    final generation = ZyraAccountState.generation;
    if (_accountGeneration != generation) {
      _accountGeneration = generation;
      _selection.value = defaultMotion;
    }
    _selection.value = motion;
    return true;
  }

  @visibleForTesting
  static void resetForTesting() {
    assert(() {
      _accountGeneration = ZyraAccountState.generation;
      _selection.value = defaultMotion;
      return true;
    }());
  }
}

/// A session-local Founder comparison; Balanced is the approved default.
abstract final class ZyraDevWelcomePulseIntensity {
  static const defaultLevel = 3;
  static const minLevel = 1;
  static const maxLevel = 5;
  static const _labels = <String>[
    'Subtle',
    'Soft',
    'Balanced',
    'Strong',
    'Bold',
  ];
  static const _amplitudes = <double>[.08, .14, .20, .27, .35];
  static final ValueNotifier<int> _selection = ValueNotifier(defaultLevel);
  static int _accountGeneration = ZyraAccountState.generation;

  static Listenable get changes => _selection;
  static int get level => _accountGeneration == ZyraAccountState.generation
      ? _selection.value
      : defaultLevel;
  static String labelFor(int level) => _labels[level - 1];
  static String get label => labelFor(level);
  static double get amplitude => _amplitudes[level - 1];

  static bool select(int level) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools ||
        level < minLevel ||
        level > maxLevel) {
      return false;
    }
    final generation = ZyraAccountState.generation;
    if (_accountGeneration != generation) {
      _accountGeneration = generation;
      _selection.value = defaultLevel;
    }
    _selection.value = level;
    return true;
  }

  @visibleForTesting
  static void resetForTesting() {
    assert(() {
      _accountGeneration = ZyraAccountState.generation;
      _selection.value = defaultLevel;
      return true;
    }());
  }
}

abstract final class ZyraDevWelcomePulseDesign {
  static const defaultDesign = ZyraWelcomePulseDesign.softBloom;
  static final ValueNotifier<ZyraWelcomePulseDesign> _selection = ValueNotifier(
    defaultDesign,
  );
  static int _accountGeneration = ZyraAccountState.generation;

  static Listenable get changes => _selection;
  static ZyraWelcomePulseDesign get current =>
      _accountGeneration == ZyraAccountState.generation
      ? _selection.value
      : defaultDesign;

  static bool select(ZyraWelcomePulseDesign design) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return false;
    final generation = ZyraAccountState.generation;
    if (_accountGeneration != generation) {
      _accountGeneration = generation;
      _selection.value = defaultDesign;
    }
    _selection.value = design;
    return true;
  }

  @visibleForTesting
  static void resetForTesting() {
    assert(() {
      _accountGeneration = ZyraAccountState.generation;
      _selection.value = defaultDesign;
      return true;
    }());
  }
}
