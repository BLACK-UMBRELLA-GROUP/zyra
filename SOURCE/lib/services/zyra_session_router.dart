// Decides which screen a signed-in user lands on — used both right
// after sign-in (welcome_screen.dart, Google/Apple OAuth) and on cold
// app start when an existing session is found (auth_gate.dart), so
// both paths agree.
//
// Looks up the `profiles` row for the current session: role='seeker'
// -> HomeShell, role='wali' -> WaliHomeShell. No profile row yet (user
// signed up but never finished onboarding, e.g. closed the app
// mid-flow) -> RoleSelectionScreen, so they resume rather than land on
// a broken/empty Home.

import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/wali/wali_home_shell.dart';
import 'zyra_auth.dart';

class ZyraSessionRouter {
  ZyraSessionRouter._();

  static Future<Widget> resolveHome() async {
    final user = ZyraAuth.currentUser;
    if (user == null) return const RoleSelectionScreen(); // shouldn't be reached without a session; safe fallback

    try {
      final row = await supabase.from('profiles').select('role').eq('id', user.id).maybeSingle();
      if (row == null) return const RoleSelectionScreen(); // signed up, onboarding never finished
      return row['role'] == 'wali' ? const WaliHomeShell() : const HomeShell();
    } catch (_) {
      // Network hiccup looking up the profile — fall back to Seeker
      // Home rather than blocking the user out entirely; ProfileScreen/
      // WaliProfileScreen will still work off AppState in the meantime.
      return const HomeShell();
    }
  }
}
