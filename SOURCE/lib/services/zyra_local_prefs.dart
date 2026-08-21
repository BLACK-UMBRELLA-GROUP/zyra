// On-device cache of the few values the FIRST FRAME needs.
//
// Founder, 2026-08-01: "when the app loads there's a second where it shows
// purple UI then the actual colour... I don't want to see that quick
// colour change at all."
//
// THE PROBLEM, precisely: main.dart paints the neutral brand gradient
// behind everything on frame one. The gender-matched gradient can only
// replace it once the app knows the gender, and the gender lives in
// Postgres. So the sequence was: paint purple, wait for a network round
// trip, repaint pink.
//
// That gap is latency, not build mode. A release build does not shorten a
// round trip — and a real user on mobile data will see it for LONGER than
// the Founder does on home wifi. It was never going to fix itself at
// launch.
//
// THE FIX: cache the gender the moment it is known, read it back before
// runApp(), and paint the right gradient on frame one with no network at
// all. Launch one after install still flashes, because there is genuinely
// nothing cached yet. Every launch after that does not.
//
// WHY shared_preferences IS NOT A NEW DEPENDENCY: it was already in
// pubspec.lock as a transitive dependency of supabase_flutter, which uses
// it to persist the auth session. Promoting it to a direct dependency
// downloads nothing and adds no native code — it stops us depending on
// another package's transitive tree by accident, which would break
// silently on a Supabase version bump.
//
// SCOPE RULE FOR THIS FILE: only values needed to paint correctly BEFORE
// the network answers. It is not a general local database and it is not a
// cache of the profile. Anything that can wait for a round trip should
// wait for one — a second source of truth for profile data is how the two
// drift apart.
//
// NOT A SECURE STORE. SharedPreferences is plain text on disk. Never put a
// token, a date of birth or anything else sensitive here. Gender is
// already public on every profile card.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZyraLocalPrefs {
  ZyraLocalPrefs._();

  static const _kGender = 'zyra.cached_gender';
  static const _kAppLock = 'zyra.app_lock_enabled';

  /// The last role this device resolved — 'seeker' or 'wali'.
  ///
  /// ADDED 2026-08-14 (DR-ZYRA-166). Cached for exactly one purpose:
  /// zyra_session_router's failure path. When the profile lookup fails it
  /// used to send EVERY account to the Seeker shell, so a Guardian on a
  /// bad connection was handed someone else's app. A remembered role is
  /// a better guess than a hardcoded one.
  static const _kRole = 'zyra.cached_role';

  /// ADDED 2026-08-15 (DR-ZYRA-169 Phase 2). Same contract as gender:
  /// the Profile tab paints the real first name on frame one instead of
  /// "Your Profile" while hydration is still in flight. A first name is
  /// already on every card the person shows other Seekers; caching your
  /// own, on your own device, is within this file's sensitivity rule.
  static const _kFirstName = 'zyra.cached_first_name';

  /// ADDED 2026-08-15 (DR-ZYRA-169). The image cache's generation
  /// number — plumbing, not profile data, and the ONE key clear() leaves
  /// alone: it describes the app's cache format on this device, not the
  /// person who signed out. See zyra_image_cache.dart, which wipes the
  /// cache once when this doesn't match its compiled-in version.
  static const _kCacheSchema = 'zyra.cache_schema_version';

  static SharedPreferences? _prefs;

  /// Read once in main(), before runApp(). Local disk, no network —
  /// single-digit milliseconds, unlike the round trip it replaces.
  ///
  /// Never throws: a failure here must degrade to the old flash, not stop
  /// the app booting. That is the same rule main.dart's Supabase guard
  /// follows, and for the same reason.
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      // Logged rather than swallowed — silent catches are why launch
      // problems stayed invisible in this codebase for a month.
      debugPrint('ZYRA: SharedPreferences unavailable — first paint will '
          'fall back to the neutral gradient.\n$e');
    }
  }

  /// 'male' | 'female' | null. Null means genuine first launch, a signed
  /// out user, or storage being unavailable — all three correctly fall
  /// back to the neutral gradient.
  static String? get cachedGender {
    final v = _prefs?.getString(_kGender);
    return (v == 'male' || v == 'female') ? v : null;
  }

  /// Written whenever the profile is hydrated. Fire-and-forget: the value
  /// is for the NEXT launch, so nothing this session depends on it
  /// landing.
  static void setCachedGender(String? gender) {
    if (_prefs == null) return;
    try {
      if (gender == 'male' || gender == 'female') {
        _prefs!.setString(_kGender, gender!);
      } else {
        _prefs!.remove(_kGender);
      }
    } catch (_) {
      // See init() — a cache miss costs a flash, nothing more.
    }
  }

  /// First name for frame one, or null (first launch / signed out /
  /// storage unavailable) — all of which correctly fall back to the
  /// generic heading until hydration lands.
  static String? get cachedFirstName {
    final v = _prefs?.getString(_kFirstName);
    return (v == null || v.trim().isEmpty) ? null : v;
  }

  static void setCachedFirstName(String? name) {
    if (_prefs == null) return;
    try {
      final v = name?.trim();
      if (v != null && v.isNotEmpty) {
        _prefs!.setString(_kFirstName, v);
      } else {
        _prefs!.remove(_kFirstName);
      }
    } catch (_) {
      // Same cost as a gender miss: one generic heading, once.
    }
  }

  /// See [_kCacheSchema]. 0 = never stamped, which always mismatches and
  /// triggers the one-time wipe — correct for a device upgrading from a
  /// build that had no image cache at all.
  static int get cacheSchemaVersion => _prefs?.getInt(_kCacheSchema) ?? 0;

  static Future<void> setCacheSchemaVersion(int version) async {
    if (_prefs == null) return;
    try {
      await _prefs!.setInt(_kCacheSchema, version);
    } catch (e) {
      debugPrint('ZYRA: could not stamp the cache schema version.\n$e');
    }
  }

  // ── App lock ─────────────────────────────────────────────────────────
  //
  // ADDED 2026-08-07 (Founder: treat App Lock as a flagship privacy
  // feature, not another setting).
  //
  // WHY THIS BELONGS IN A FILE WITH A DELIBERATELY NARROW SCOPE. The rule
  // above is "only values needed to paint correctly BEFORE the network
  // answers". This is the purest example of one: the lock screen has to be
  // the first thing drawn, and asking Postgres whether to draw it would
  // mean showing the app for a round trip first — which is the entire
  // thing the lock exists to prevent.
  //
  // AND WHY PLAIN TEXT IS FINE HERE. The file's other rule is "never put a
  // token, a date of birth or anything else sensitive here". A boolean
  // preference is none of those. There is no PIN and no secret stored —
  // see zyra_app_lock.dart, which deliberately delegates ALL authentication
  // to the OS and keeps no credential of its own. Someone who can edit this
  // file's contents on disk is not the threat this feature addresses.

  /// Defaults to false — off until deliberately turned on. A lock the user
  /// did not ask for, on an app they may be opening in a hurry, is a way to
  /// lose them.
  /// The last resolved role, or null on a device that has never signed
  /// in. See [_kRole].
  static String? get cachedRole {
    final v = _prefs?.getString(_kRole);
    return (v == null || v.isEmpty) ? null : v;
  }

  static void setCachedRole(String? role) {
    if (_prefs == null) return;
    if (role != null && role.isNotEmpty) {
      _prefs!.setString(_kRole, role);
    } else {
      _prefs!.remove(_kRole);
    }
  }

  static bool get appLockEnabled => _prefs?.getBool(_kAppLock) ?? false;

  static Future<void> setAppLockEnabled(bool value) async {
    if (_prefs == null) return;
    try {
      await _prefs!.setBool(_kAppLock, value);
    } catch (e) {
      debugPrint('ZYRA: could not persist the app lock preference.\n$e');
    }
  }

  /// Called on sign-out. Without this the next person to sign in on the
  /// same device gets the previous user's gradient for one frame — a
  /// small leak of someone else's data, and visibly wrong.
  ///
  /// The app lock preference is REMOVED here for the same reason: it is a
  /// setting belonging to the person who signed out, and leaving it behind
  /// would put the next user behind a lock they never enabled — and, worse,
  /// one they can pass, which would look like an endorsement.
  static Future<void> clear() async {
    if (_prefs == null) return;
    try {
      await _prefs!.remove(_kGender);
      await _prefs!.remove(_kRole);
      await _prefs!.remove(_kAppLock);
      // Same reasoning as gender: the next person's Profile must not
      // greet them by the previous person's name, even for one frame.
      await _prefs!.remove(_kFirstName);
      // _kCacheSchema deliberately survives — it describes this DEVICE's
      // cache format, not the account. The cache CONTENTS are emptied by
      // ZyraImageCache.clearForSignOut() in the same sign-out block.
    } catch (_) {}
  }
}
