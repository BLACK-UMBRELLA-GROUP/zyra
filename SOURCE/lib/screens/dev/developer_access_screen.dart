// Developer Access — founder testing tool.
//
// Upgraded 2026-07-19 (explicit Founder request, relayed via the
// 2026-07-18 handoff §5) from a plain jump-menu into a test-scenario
// switcher. Two sections:
//
//   1. TEST ACCOUNTS (real backend) — one tap signs into a seeded
//      Supabase test account (real auth session, real RLS, real
//      profiles/subscriptions rows — see supabase/seed_dev_accounts.sql),
//      applies the matching AppState preset, and lands directly on the
//      fully-onboarded Home/WaliHome for that scenario. Hybrid approach
//      per Founder decision 2026-07-19: real rows where realism matters
//      (auth, RLS, backend paths), local AppState for what has no
//      schema yet (plan gating UI, Wali One mock).
//      Presets: Seeker ZYRA Basic (male/female), Seeker ZYRA One
//      (male/female), Wali Basic (male/female), Wali One (male/female —
//      same two accounts as Wali Basic; added 2026-07-25, Founder
//      request, so male AND female Wali presets exist at both tiers,
//      matching the Seeker section's coverage; renamed from "Extended
//      Guardian" 2026-07-26, Founder decision, matching "ZYRA One" naming).
//      2026-07-26 (#19): Guardian+ gating is now real —
//      wali_has_wali_one() reads the `subscriptions` table, not a
//      local flag. Since Basic/One reuse the same real accounts, entry
//      calls mock_set_wali_plan() to deterministically set that
//      account's own row each time (see zyra_entitlement_service.dart).
//
//   2. TEST SIGN UP — new 2026-07-26 (OA-ZYRA-127, DR-ZYRA-108).
//      Simulates a brand-new user going through the REAL onboarding
//      question flow from a blank slate (AppState.applyDevPreset()
//      with no args), rather than jumping straight to Home like the
//      section below. Two tiles only — Seeker and Wali — not the 8
//      account-type options OA-127's source document literally asked
//      for, and there's deliberately no "Skip Payment" screen. Both
//      of those parts of the request describe a subscription-tier
//      choice and a paywall step happening DURING sign-up, but that
//      isn't how production onboarding actually works: no chapter
//      anywhere asks "Basic or One", and a new account is always
//      created on the Basic tier by default (AppState.plan defaults
//      to ZyraPlan.basic; ZyraProfileService.createWaliProfile()
//      likewise always writes gender: 'male', since WALI_ARCHITECTURE's
//      WHO IS A WALI section defines a Wali as a male guardian and
//      lists "female guardian acting in Guardian capacity" under
//      EXCEPTIONAL CASES (DEFERRED) — not a real
//      sign-up path today). Upgrading to One happens afterwards, from
//      the Profile tab (Seeker) or Network tab (Wali), using the
//      existing mocked purchase flow — which already has no real
//      payment to skip (task #20, deferred pending Stripe/store
//      credentials). Building a fake mid-onboarding paywall screen
//      that doesn't exist in the real app would make this LESS
//      faithful to production, not more, so it wasn't built — see
//      DR-ZYRA-108 for the full reasoning.
//
//   3. JUMP TO SCREEN — the original jump-menu, unchanged: straight
//      into any onboarding chapter or Home without an account, on mock
//      state, exactly as before.
//
// Test-account sign-in uses ZyraAuth.signInWithTestAccount (password
// auth, dev-only — NOT a user-facing method; Google + Apple remain the
// only real auth per Founder instruction 2026-07-18).
//
// Script_V1.md's Admin Permission System (role == Admin gate) still
// applies once real admin roles exist — this screen remains reachable
// from Welcome only, pre-auth, as a founder tool in the preview build.

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import '../../main.dart' show supabaseReady;
import '../../services/zyra_auth.dart';
import '../../services/zyra_entitlement_service.dart';
import '../../services/zyra_wali_link_service.dart';
import '../../state/app_state.dart';
import '../../theme/zyra_colors.dart';
import '../../theme/zyra_text.dart';
import '../../widgets/zyra_state_widgets.dart';
// Five onboarding imports went 2026-08-07. chapter2_flow,
// profile_ready_screen and values_preferences_flow left with Jump to
// Screen, which was their only caller; onboarding_flow and
// wali_onboarding_flow left with Test Sign Up, which moved to the dev
// panel. This screen is now only Test Accounts — real backend, real data.
// Neither shell is named here any more — 2026-08-07. This screen used to
// choose between them from a hand-set preset flag; it now pushes AuthGate
// and lets ZyraSessionRouter decide from the profile row. See _enterAs.
import '../../dev/zyra_dev_signup.dart';
import '../auth_gate.dart';

class DeveloperAccessScreen extends StatefulWidget {
  const DeveloperAccessScreen({super.key});

  @override
  State<DeveloperAccessScreen> createState() => _DeveloperAccessScreenState();
}

class _DevPreset {
  final String label;
  final String sublabel;
  final String email;
  final bool isWali;
  final ZyraPlan plan;
  final bool isWaliOne;
  final String name;
  final String gender;
  final DateTime dob;
  final String location;

  const _DevPreset({
    required this.label,
    required this.sublabel,
    required this.email,
    required this.isWali,
    required this.plan,
    this.isWaliOne = false,
    required this.name,
    required this.gender,
    required this.dob,
    required this.location,
  });
}

class _DeveloperAccessScreenState extends State<DeveloperAccessScreen> {
  // Seeded by supabase/seed_dev_accounts.sql. Test-only credentials for
  // a dev/preview database containing no real users — not a secret in
  // any meaningful sense, but rotate them if this project ever holds
  // real data.
  static const String _testPassword = 'ZyraTest!2026';

  static final List<_DevPreset> _presets = [
    _DevPreset(
      label: 'Seeker — ZYRA Basic, male',
      sublabel: 'Adam, 29, London',
      email: 'dev.seeker.basic.m@zyra.test',
      isWali: false,
      plan: ZyraPlan.basic,
      name: 'Adam',
      gender: 'male',
      dob: DateTime(1997, 3, 14),
      location: 'London',
    ),
    _DevPreset(
      label: 'Seeker — ZYRA Basic, female',
      sublabel: 'Maryam, 27, Birmingham — has a linked Guardian (Ibrahim)',
      email: 'dev.seeker.basic.f@zyra.test',
      isWali: false,
      plan: ZyraPlan.basic,
      name: 'Maryam',
      gender: 'female',
      dob: DateTime(1998, 7, 22),
      location: 'Birmingham',
    ),
    _DevPreset(
      label: 'Seeker — ZYRA One, male',
      sublabel: 'Yusuf, 31, Manchester',
      email: 'dev.seeker.one.m@zyra.test',
      isWali: false,
      plan: ZyraPlan.one,
      name: 'Yusuf',
      gender: 'male',
      dob: DateTime(1994, 11, 2),
      location: 'Manchester',
    ),
    _DevPreset(
      label: 'Seeker — ZYRA One, female',
      sublabel: 'Aisha, 30, Leeds',
      email: 'dev.seeker.one.f@zyra.test',
      isWali: false,
      plan: ZyraPlan.one,
      name: 'Aisha',
      gender: 'female',
      dob: DateTime(1996, 5, 9),
      location: 'Leeds',
    ),
    _DevPreset(
      label: 'Guardian — Basic, male',
      sublabel: 'Ibrahim — linked to Maryam',
      email: 'dev.wali@zyra.test',
      isWali: true,
      plan: ZyraPlan.basic,
      name: 'Ibrahim',
      gender: 'male',
      dob: DateTime(1968, 1, 15),
      location: 'Birmingham',
    ),
    _DevPreset(
      label: 'Guardian — Basic, female',
      sublabel: 'Khadija — linked to Yusuf (ZYRA One), so she resolves as Guardian+ anyway via free bundling (#19) — this is correct, not a bug',
      email: 'dev.wali.f@zyra.test',
      isWali: true,
      plan: ZyraPlan.basic,
      name: 'Khadija',
      gender: 'female',
      dob: DateTime(1970, 4, 2),
      location: 'Manchester',
    ),
    _DevPreset(
      label: 'Guardian — One, male',
      sublabel: 'Ibrahim, same account — real wali_premium row written on entry (#19)',
      email: 'dev.wali@zyra.test',
      isWali: true,
      plan: ZyraPlan.basic,
      isWaliOne: true,
      name: 'Ibrahim',
      gender: 'male',
      dob: DateTime(1968, 1, 15),
      location: 'Birmingham',
    ),
    _DevPreset(
      label: 'Guardian — One, female',
      sublabel: 'Khadija, same account — already has it for free via Yusuf\'s ZYRA One (#19); this preset also force-writes a real row',
      email: 'dev.guardian.f@zyra.test',
      isWali: true,
      plan: ZyraPlan.basic,
      isWaliOne: true,
      name: 'Khadija',
      gender: 'female',
      dob: DateTime(1970, 4, 2),
      location: 'Manchester',
    ),
  ];

  String? _busyEmailLabel;
  String? _error;

  // Guards against overlapping switches — checked and set synchronously,
  // before any `await`, so a second tap landing while the first switch
  // is still in flight (e.g. two taps registered in the same frame,
  // before the tiles visually disable) can't start a second, overlapping
  // signOut()+signIn() call. Found 2026-07-19: tapping between test
  // profiles quickly caused several concurrent sign-out/sign-in calls to
  // race each other and crash the app at the native session-storage
  // level (no Dart exception, so it looked unexplained from the logs
  // alone) — `_busyEmailLabel != null` alone wasn't enough of a guard
  // because it's only enforced once the rebuild from setState() has
  // actually run, which isn't necessarily before the next tap lands.
  bool _switching = false;

  Future<void> _enterAs(_DevPreset preset) async {
    if (_switching) return;
    _switching = true;
    setState(() {
      _busyEmailLabel = preset.label;
      _error = null;
    });

    final result = await ZyraAuth.signInWithTestAccount(preset.email, _testPassword);
    _switching = false;
    if (!mounted) return;

    if (result.outcome != ZyraAuthOutcome.success) {
      setState(() {
        _busyEmailLabel = null;
        _error = result.errorMessage ?? 'Test sign-in failed.';
      });
      return;
    }

    final app = AppState.instance;
    if (preset.isWali) {
      app.applyDevPreset(
        // 2026-07-25 fix: gender was never passed here, so
        // AppState.gender stayed null for Wali dev presets and every
        // Wali screen fell back to the neutral brand gradient instead
        // of ZyraColors.brandGradientMale via genderGradient() — the
        // other half of the gap DR-ZYRA-101's audit caught (Seeker
        // dev presets were already correct).
        gender: preset.gender,
        waliName: preset.name,
        waliRelationship: 'Father',
        // 2026-07-26 (#19): this local flag is no longer what gates
        // Guardian+ UI — wali_network_screen.dart/wali_profile_
        // screen.dart now read the real wali_has_wali_one() RPC.
        // Kept set here only so `AppState.waliHasWaliOne` doesn't
        // silently go stale for any other reader that might exist;
        // the actual entitlement below is written for real.
        waliHasWaliOne: preset.isWaliOne,
      );
      // Real linked Seekers from the live wali_links table, so the
      // Dashboard/Seekers tabs show genuine backend data immediately.
      final linked = await ZyraWaliLinkService.fetchLinkedPeople(asWali: true);
      app.setWaliRealLinkedSeekers(linked);
      // #19 — deterministically set this account's OWN subscription
      // row to match the preset (wali_basic for "Basic", wali_premium
      // for "One"). Necessary because Ibrahim/Khadija are the SAME
      // real accounts shared between the Basic and One presets — since
      // gating is now real and persistent, switching presets must
      // actually flip the row each time, not just a local flag. Note:
      // Khadija's "Basic" preset will still resolve as Wali One
      // in the UI regardless, because she's genuinely, correctly
      // entitled for free via Yusuf's real ZYRA One subscription
      // (wali_has_wali_one()'s bundling branch) — that's the
      // bundling feature working as intended, not a leftover mock.
      await ZyraEntitlementService.mockSetWaliPlan(premium: preset.isWaliOne);
    } else {
      app.applyDevPreset(
        name: preset.name,
        gender: preset.gender,
        dob: preset.dob,
        plan: preset.plan,
        location: preset.location,
      );
    }

    if (!mounted) return;
    // THROUGH AuthGate, not straight to a shell — changed 2026-08-07
    // (Founder: "I want the app to open from the splash screen, right now
    // it's opening on the Browse page").
    //
    // This was `pushAndRemoveUntil(preset.isWali ? WaliHomeShell : HomeShell)`,
    // which skipped AuthGate entirely and therefore skipped the splash. Two
    // separate problems, one line:
    //
    //   1. NO SPLASH. Signing in here is the way this account is usually
    //      entered, so the splash was never seen despite being wired up.
    //   2. ROUTING DECIDED TWICE. `preset.isWali ? ... : ...` restates what
    //      ZyraSessionRouter.resolveHome() already decides from the profile
    //      row — the same "rule in two places" this codebase has spent the
    //      day removing. A preset whose isWali flag disagreed with its
    //      seeded row would land in the wrong shell, and the flag is set by
    //      hand in this file.
    //
    // AuthGate reads the session that was just established and routes from
    // the database, so the preset flag no longer decides anything.
    //
    // ── playSplash: false — 2026-08-08. Founder: "on dev button I pick
    // user, I see the splash screen, I don't want that."
    //
    // Only HALF of the 2026-08-07 change above was wrong. Routing through
    // the gate is right and stays — it is what deleted
    // `preset.isWali ? WaliHomeShell : HomeShell` and made
    // ZyraSessionRouter the single decider. Playing the brand animation
    // every time you switch test accounts is what was wrong: the splash is
    // for opening the app, and this is not opening the app.
    //
    // The gate shows ZyraLoading instead, which lasts exactly as long as
    // the profile read and no longer.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate(playSplash: false)),
      (route) => false,
    );
  }

  // _testSignUp MOVED to dev_scenario_panel.dart as _startSignUp,
  // 2026-08-07 (Founder: "in toggle, move them pages there"). Deleted here
  // rather than left behind unused — two copies of a dev entry point is how
  // one of them quietly stops matching the flow it launches.

  Future<void> _signOutTestAccount() async {
    if (_switching) return;
    _switching = true;
    setState(() => _error = null);
    await ZyraAuth.signOut();
    _switching = false;
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // BACKSTOP 2026-08-01 (audit finding C1 — Critical). The two entry
    // points that reach this screen (welcome_screen.dart,
    // wali_home_shell.dart) are now each gated on !kReleaseMode — but
    // C1 happened precisely BECAUSE a guard was applied to one file and
    // not to the others that mattered. Guarding at the destination means
    // any future entry point is safe by default, and someone adding one
    // cannot reintroduce this by forgetting.
    //
    // Non-negotiable: this screen holds a hardcoded password for six real
    // seeded accounts, switches subscription tiers, and calls the mock
    // purchase RPCs. It must never be reachable by a real user.
    if (kReleaseMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }

    // 2026-08-01: was `SupabaseConfig.isConfigured`, which only reports
    // that a URL/key are filled in — not that Supabase.initialize()
    // actually succeeded. If init failed, this screen would advertise the
    // backend as available and then throw the moment a test sign-in
    // touched Supabase.instance. `supabaseReady` is the real signal.
    final backendAvailable = supabaseReady;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ZyraColors.brandGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text('Developer Access', style: ZyraText.heading(size: 22)),
                const SizedBox(height: 6),
                Text(
                  'Enter the app as a preset test account (real backend), or jump straight to a screen (mock state).',
                  style: ZyraText.subtext(),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      if (_error != null) ...[
                        ZyraErrorBanner(message: _error!, onDismiss: () => setState(() => _error = null)),
                        const SizedBox(height: 14),
                      ],
                      Text('TEST ACCOUNTS — REAL BACKEND', style: ZyraText.chapterLabel(color: Colors.white54)),
                      const SizedBox(height: 10),
                      if (!backendAvailable)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Supabase isn\'t configured in this build — test accounts unavailable. The jump-menu below still works on mock state.',
                            style: ZyraText.subtext(size: 12, color: Colors.white38),
                          ),
                        )
                      else ...[
                        ..._presets.map(
                          (p) => _DevTile(
                            label: _busyEmailLabel == p.label ? 'Signing in…' : p.label,
                            sublabel: p.sublabel,
                            icon: p.isWali ? Icons.family_restroom_outlined : Icons.person_outline,
                            onTap: _busyEmailLabel != null ? null : () => _enterAs(p),
                          ),
                        ),
                        if (ZyraAuth.isSignedIn)
                          _DevTile(
                            label: 'Sign out current test account',
                            sublabel: ZyraAuth.currentUser?.email ?? '',
                            icon: Icons.logout,
                            onTap: _busyEmailLabel != null ? null : _signOutTestAccount,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Test accounts are seeded rows in the dev database (no photos yet, so they don\'t appear in each other\'s Browse — Browse falls back to mock profiles). Sign-ins here are real Supabase sessions and exercise real RLS.',
                          style: ZyraText.subtext(size: 11, color: Colors.white38),
                        ),
                      ],
                      // ── TEST SIGN UP — RESTORED 2026-08-07 ───────────
                      //
                      // Moved to the toggle panel earlier the same day, at
                      // the Founder's request, and the originals deleted.
                      // That was wrong: DevScenarioPanel is mounted ONLY in
                      // HomeShell (home_shell.dart:210), so the action
                      // "test signing up as a brand new user" became
                      // reachable only from inside the signed-in Seeker
                      // home — the one state you cannot be in when you want
                      // to test signing up.
                      //
                      // Both places now, because they are two different
                      // moments: here, signed out, starting from scratch;
                      // in the panel, signed in, jumping into onboarding
                      // from wherever you are.
                      //
                      // The original worry — "two copies of a dev entry
                      // point is how one of them quietly stops matching the
                      // flow it launches" — is answered by both calling
                      // ZyraDevSignUp.start() rather than by picking one
                      // location.
                      const SizedBox(height: 24),
                      Text('TEST SIGN UP — MOCK STATE',
                          style: ZyraText.chapterLabel(color: Colors.white54)),
                      const SizedBox(height: 4),
                      Text(
                        'Real onboarding questions from a blank slate — answer them yourself, '
                        'exactly like a first-time user. No tier picker: every account starts '
                        'on Basic; upgrade afterwards from Profile/Network, same as production.',
                        style: ZyraText.subtext(size: 11, color: Colors.white38),
                      ),
                      const SizedBox(height: 10),
                      _DevTile(
                        label: 'Seeker — Test Sign Up',
                        sublabel: 'Chapter 1 through Profile Ready, in your own answers',
                        icon: Icons.person_add_alt_outlined,
                        onTap: () => ZyraDevSignUp.start(context, isWali: false),
                      ),
                      _DevTile(
                        label: 'Guardian — Test Sign Up',
                        sublabel: 'Name, date of birth, relationship, then Invite a Seeker',
                        icon: Icons.person_add_alt_outlined,
                        onTap: () => ZyraDevSignUp.start(context, isWali: true),
                      ),

                      // ── JUMP TO SCREEN — REMOVED 2026-08-07 ───────────
                      //
                      // Founder: "in the home button for developer we have
                      // jump to screen section — remove that for now."
                      //
                      // Nine tiles that pushed a screen onto whatever state
                      // happened to be loaded. That was the right tool in
                      // July, when most screens read from AppState and a
                      // cold jump showed you something real. It is the wrong
                      // one now: Chapter 2, Values and Profile Ready all
                      // read the database, so jumping into them mid-session
                      // showed a half-populated screen that matched no
                      // actual user — and every bug found that way had to be
                      // re-tested properly anyway.
                      //
                      // The two that were genuinely useful, Home and
                      // Guardian Home, are what TEST ACCOUNTS above already
                      // gives you with real data behind them.
                      //
                      // ── TEST SIGN UP — MOVED 2026-08-07 ───────────────
                      //
                      // Founder: "in toggle, move them pages there."
                      //
                      // Both entry points now live in the dev panel's ANY
                      // PAGE group, so everything scenario-shaped is in one
                      // pull-out instead of split between a panel and a
                      // screen you reach by signing out. See
                      // dev_scenario_panel.dart.
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // _push REMOVED 2026-08-07 — Jump to Screen was its only caller.
}

class _DevTile extends StatelessWidget {
  final String label;
  final String? sublabel;
  final IconData? icon;
  final VoidCallback? onTap;
  const _DevTile({required this.label, this.sublabel, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ZyraColors.iconButtonBg,
          border: Border.all(color: ZyraColors.iconButtonBorder, width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white54, size: 18),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: ZyraText.body(size: 14)),
                        if (sublabel != null && sublabel!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(sublabel!, style: ZyraText.subtext(size: 11, color: Colors.white38)),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
