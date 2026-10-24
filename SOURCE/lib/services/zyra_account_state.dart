import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show PaintingBinding;

import '../dev/zyra_dev_scenario.dart';
import '../state/app_state.dart';
import '../theme/zyra_app_gold_style.dart';
import '../theme/zyra_colors.dart';
import '../theme/zyra_interaction_style.dart';
import '../theme/zyra_text.dart';
import 'zyra_app_lock.dart';
import 'zyra_consent_service.dart';
import 'zyra_image_cache.dart';
import 'zyra_hidden_profile_store.dart';
import 'zyra_internal_preview_client.dart';
import 'zyra_local_prefs.dart';
import 'zyra_photo_service.dart';
import 'zyra_promotion_engine.dart';
import 'zyra_unlock_service.dart';

/// Owns the lifetime of member display state independently of developer access.
/// Callers await synchronization before starting account work, then capture the
/// generation and check [isCurrent] before publishing an asynchronous result.
abstract final class ZyraAccountState {
  static String? _userId;
  static int _generation = 0;
  static bool _initialized = false;
  static bool _signingOut = false;
  static Future<void> _cleanup = Future<void>.value();

  static String? get userId => _userId;
  static int get generation => _generation;
  static bool get isSigningOut => _signingOut;

  @visibleForTesting
  static Future<void> Function()? clearImagesForTesting;

  /// Each widget test owns a FakeAsync zone. Do not retain one test's queued
  /// cleanup Future in the next zone. Compiled production calls are no-ops.
  @visibleForTesting
  static void resetForTesting() {
    assert(() {
      _generation++;
      _userId = null;
      _initialized = false;
      _signingOut = false;
      _cleanup = Future<void>.value();
      ZyraInternalPreviewClient.bindAccount(null);
      return true;
    }());
  }

  static bool isCurrent(String expectedUserId, int expectedGeneration) =>
      !_signingOut &&
      _userId == expectedUserId &&
      _generation == expectedGeneration;

  static Future<void> synchronize(String? userId) {
    // A token refresh delivered while logout is pending cannot rehydrate the
    // principal whose display state has already been removed.
    if (_signingOut && userId != null) return _cleanup;
    if (_initialized && _userId == userId) {
      final preferences = ZyraLocalPrefs.bindAccount(userId);
      return Future.wait([_cleanup, preferences]).then((_) {});
    }
    return _changeAccount(userId);
  }

  static Future<void> beginSignOut() {
    _signingOut = true;
    return _changeAccount(null);
  }

  static void endSignOutAttempt() => _signingOut = false;

  static Future<void> _changeAccount(String? userId) {
    final preserveDiskImages =
        !_initialized &&
        userId != null &&
        ZyraLocalPrefs.canRestoreAccount(userId);
    _initialized = true;
    _userId = userId;
    final version = ++_generation;
    ZyraInternalPreviewClient.bindAccount(userId);
    // Binding first makes all following callbacks observe the new owner.
    final preferences = ZyraLocalPrefs.bindAccount(userId);
    AppState.instance.resetForAccountChange();
    ZyraUnlockService.clearForSignOut();
    ZyraConsentService.clearForSignOut();
    ZyraPhotoService.clearUrlMemoForSignOut();
    ZyraHiddenProfileStore.clearForAccountChange();
    ZyraPromotionEngine.instance.resetForAccountChange();
    ZyraAppLock.instance.clearForSignOut();
    ZyraDevScenario.instance.reset();
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraColors.restoreAppPalette(null);
    ZyraText.restoreAppFont(null);
    ZyraInteractionStyle.restoreHapticLevel(null);
    ZyraAppGoldStyle.instance.restore(false);
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();

    // An already-running image eviction must finish before the next account
    // can start fetching. Queued stale evictions are skipped altogether.
    final result = _cleanup.then((_) async {
      await preferences;
      if (version != _generation || preserveDiskImages) return;
      await (clearImagesForTesting ?? ZyraImageCache.clearForSignOut)();
    });
    _cleanup = result.catchError((Object _) {
      debugPrint('ZYRA: account cache cleanup could not be completed.');
    });
    return _cleanup;
  }
}
