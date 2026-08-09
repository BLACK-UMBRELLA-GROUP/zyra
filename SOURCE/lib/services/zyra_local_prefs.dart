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
      await _prefs!.remove(_kAppLock);
    } catch (_) {}
  }
}
